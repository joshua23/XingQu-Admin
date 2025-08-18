import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_membership.dart';
import '../models/subscription_plan.dart';
import 'supabase_service.dart';
import 'subscription_service.dart';

/// 会员权益和商业化功能服务
/// 处理会员权益验证、使用限制、消费统计等功能
class MembershipService {
  static final MembershipService _instance = MembershipService._internal();
  factory MembershipService() => _instance;
  MembershipService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

  /// 检查用户是否有权限使用特定功能
  Future<bool> hasPermission({
    required String userId,
    required String feature,
  }) async {
    try {
      debugPrint('🔒 检查用户权限: userId=$userId, feature=$feature');
      
      final membership = await _subscriptionService.getCurrentMembership(userId);
      if (membership == null || !membership.isActive) {
        debugPrint('❌ 用户无有效会员资格');
        return false;
      }

      final hasPermission = membership.canUseFeature(feature);
      debugPrint('✅ 权限检查结果: $hasPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('❌ 权限检查失败: $e');
      return false;
    }
  }

  /// 获取用户功能使用限制
  Future<int> getUsageLimit({
    required String userId,
    required String feature,
  }) async {
    try {
      debugPrint('📊 获取使用限制: userId=$userId, feature=$feature');
      
      final membership = await _subscriptionService.getCurrentMembership(userId);
      if (membership == null || !membership.isActive) {
        return 0; // 无会员则无使用限制
      }

      final limit = membership.getFeatureLimit<int>(feature) ?? 0;
      debugPrint('✅ 使用限制: $limit');
      return limit;
    } catch (e) {
      debugPrint('❌ 获取使用限制失败: $e');
      return 0;
    }
  }

  /// 获取用户当前使用量
  Future<int> getCurrentUsage({
    required String userId,
    required String feature,
    DateTime? startDate,
  }) async {
    try {
      debugPrint('📈 获取当前使用量: userId=$userId, feature=$feature');
      
      final start = startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      
      final response = await _client
          .from('user_usage_stats')
          .select('usage_count')
          .eq('user_id', userId)
          .eq('feature_name', feature)
          .gte('usage_date', start.toIso8601String())
          .single();

      final usage = response['usage_count'] as int? ?? 0;
      debugPrint('✅ 当前使用量: $usage');
      return usage;
    } catch (e) {
      debugPrint('❌ 获取使用量失败: $e');
      return 0;
    }
  }

  /// 记录功能使用
  Future<void> recordUsage({
    required String userId,
    required String feature,
    int amount = 1,
  }) async {
    try {
      debugPrint('📝 记录功能使用: userId=$userId, feature=$feature, amount=$amount');
      
      // 使用 RPC 函数原子性地更新使用统计
      await _client
          .rpc('record_user_usage', params: {
            'p_user_id': userId,
            'p_feature_name': feature,
            'p_amount': amount,
          });

      debugPrint('✅ 功能使用记录成功');
    } catch (e) {
      debugPrint('❌ 记录功能使用失败: $e');
    }
  }

  /// 检查功能使用是否超限
  Future<bool> isUsageExceeded({
    required String userId,
    required String feature,
    int additionalUsage = 1,
  }) async {
    try {
      final limit = await getUsageLimit(userId: userId, feature: feature);
      final currentUsage = await getCurrentUsage(userId: userId, feature: feature);
      
      final wouldExceed = (currentUsage + additionalUsage) > limit;
      debugPrint('🚦 使用限制检查: 当前=$currentUsage, 限制=$limit, 将超限=$wouldExceed');
      return wouldExceed;
    } catch (e) {
      debugPrint('❌ 检查使用限制失败: $e');
      return true; // 发生错误时保守返回true
    }
  }

  /// 获取用户剩余使用量
  Future<int> getRemainingUsage({
    required String userId,
    required String feature,
  }) async {
    try {
      final limit = await getUsageLimit(userId: userId, feature: feature);
      final currentUsage = await getCurrentUsage(userId: userId, feature: feature);
      
      final remaining = (limit - currentUsage).clamp(0, limit);
      debugPrint('📊 剩余使用量: $remaining');
      return remaining;
    } catch (e) {
      debugPrint('❌ 获取剩余使用量失败: $e');
      return 0;
    }
  }

  /// 获取用户会员权益详情
  Future<Map<String, dynamic>> getMembershipBenefits(String userId) async {
    try {
      debugPrint('💎 获取会员权益详情: $userId');
      
      final membership = await _subscriptionService.getCurrentMembership(userId);
      if (membership == null || !membership.isActive) {
        return _getFreeMemberBenefits();
      }

      final plan = membership.subscriptionPlan;
      if (plan == null) {
        return _getFreeMemberBenefits();
      }

      final benefits = <String, dynamic>{
        'membership_type': plan.tierName,
        'is_premium': membership.isPremiumUser,
        'ai_agent_limit': plan.aiAgentLimit,
        'creation_limit': plan.creationLimit,
        'export_limit': plan.exportLimit,
        'has_advanced_ai': plan.hasAdvancedAI,
        'has_priority_processing': plan.hasPriorityProcessing,
        'has_watermark_free': plan.hasWatermarkFree,
        'features': plan.features,
        'days_remaining': membership.daysUntilExpiration,
        'auto_renewal': membership.autoRenewal,
      };

      debugPrint('✅ 会员权益获取成功');
      return benefits;
    } catch (e) {
      debugPrint('❌ 获取会员权益失败: $e');
      return _getFreeMemberBenefits();
    }
  }

  /// 获取免费会员权益
  Map<String, dynamic> _getFreeMemberBenefits() {
    return {
      'membership_type': '免费用户',
      'is_premium': false,
      'ai_agent_limit': 1,
      'creation_limit': 5,
      'export_limit': 2,
      'has_advanced_ai': false,
      'has_priority_processing': false,
      'has_watermark_free': false,
      'features': {},
      'days_remaining': 0,
      'auto_renewal': false,
    };
  }

  /// 获取用户使用统计报告
  Future<Map<String, dynamic>> getUsageReport(String userId) async {
    try {
      debugPrint('📊 获取使用统计报告: $userId');
      
      final response = await _client
          .rpc('get_user_usage_report', params: {
            'p_user_id': userId,
          });

      final report = response as Map<String, dynamic>;
      debugPrint('✅ 使用统计报告获取成功');
      return report;
    } catch (e) {
      debugPrint('❌ 获取使用统计报告失败: $e');
      return {};
    }
  }

  /// 获取会员到期提醒信息
  Future<Map<String, dynamic>?> getExpirationReminder(String userId) async {
    try {
      debugPrint('⏰ 获取会员到期提醒: $userId');
      
      final membership = await _subscriptionService.getCurrentMembership(userId);
      if (membership == null || !membership.isActive) {
        return null;
      }

      if (!membership.isExpiringsoon) {
        return null;
      }

      final reminder = {
        'membership_id': membership.membershipId,
        'plan_name': membership.subscriptionPlan?.planName ?? '未知套餐',
        'days_remaining': membership.daysUntilExpiration,
        'expiry_date': membership.endDate.toIso8601String(),
        'auto_renewal': membership.autoRenewal,
        'reminder_type': membership.daysUntilExpiration == 0 ? 'expiry_today' : 'expiry_soon',
      };

      debugPrint('✅ 到期提醒信息获取成功');
      return reminder;
    } catch (e) {
      debugPrint('❌ 获取到期提醒失败: $e');
      return null;
    }
  }

  /// 验证会员功能访问权限
  Future<MembershipAccessResult> validateFeatureAccess({
    required String userId,
    required String feature,
    int requestedAmount = 1,
  }) async {
    try {
      debugPrint('🔐 验证功能访问权限: userId=$userId, feature=$feature');
      
      // 检查基础权限
      final hasPermission = await this.hasPermission(
        userId: userId,
        feature: feature,
      );

      if (!hasPermission) {
        return MembershipAccessResult.denied('您的会员等级不支持此功能');
      }

      // 检查使用限制
      final isExceeded = await isUsageExceeded(
        userId: userId,
        feature: feature,
        additionalUsage: requestedAmount,
      );

      if (isExceeded) {
        final remaining = await getRemainingUsage(userId: userId, feature: feature);
        return MembershipAccessResult.limitReached('功能使用次数已达上限，剩余：$remaining 次');
      }

      return MembershipAccessResult.allowed('功能访问验证通过');
    } catch (e) {
      debugPrint('❌ 验证功能访问权限失败: $e');
      return MembershipAccessResult.error('权限验证失败：$e');
    }
  }

  /// 消费功能使用量（在确认使用后调用）
  Future<void> consumeFeatureUsage({
    required String userId,
    required String feature,
    int amount = 1,
  }) async {
    try {
      debugPrint('💰 消费功能使用量: userId=$userId, feature=$feature, amount=$amount');
      
      await recordUsage(
        userId: userId,
        feature: feature,
        amount: amount,
      );

      debugPrint('✅ 功能使用量消费成功');
    } catch (e) {
      debugPrint('❌ 消费功能使用量失败: $e');
    }
  }

  /// 获取升级建议
  Future<Map<String, dynamic>> getUpgradeSuggestion(String userId) async {
    try {
      debugPrint('📈 获取升级建议: $userId');
      
      final membership = await _subscriptionService.getCurrentMembership(userId);
      final plans = await _subscriptionService.getAvailablePlans();
      
      if (membership == null || !membership.isActive) {
        // 免费用户，推荐基础套餐
        final basicPlan = plans.where((p) => p.planTier == 1).firstOrNull;
        if (basicPlan != null) {
          return {
            'current_plan': '免费用户',
            'suggested_plan': basicPlan.planName,
            'suggested_plan_id': basicPlan.planId,
            'benefits': ['更多AI智能体', '更多创作次数', '高级AI功能'],
            'reason': '升级到基础版享受更多功能',
          };
        }
      } else {
        // 现有会员，推荐更高级套餐
        final currentTier = membership.membershipTier;
        final higherPlans = plans.where((p) => p.planTier > currentTier).toList();
        
        if (higherPlans.isNotEmpty) {
          final suggestedPlan = higherPlans.first;
          return {
            'current_plan': membership.subscriptionPlan?.planName ?? '当前套餐',
            'suggested_plan': suggestedPlan.planName,
            'suggested_plan_id': suggestedPlan.planId,
            'benefits': ['无限AI智能体', '无限创作次数', '优先处理'],
            'reason': '升级享受更多高级功能',
          };
        }
      }

      return {
        'current_plan': membership?.subscriptionPlan?.planName ?? '免费用户',
        'message': '您已使用最高级套餐',
      };
    } catch (e) {
      debugPrint('❌ 获取升级建议失败: $e');
      return {};
    }
  }

  /// 获取会员专属内容
  Future<List<Map<String, dynamic>>> getPremiumContent({
    required String userId,
    String? contentType,
    int limit = 20,
  }) async {
    try {
      debugPrint('💎 获取会员专属内容: userId=$userId');
      
      final membership = await _subscriptionService.getCurrentMembership(userId);
      if (membership == null || !membership.isPremiumUser) {
        return [];
      }

      var query = _client
          .from('premium_contents')
          .select()
          .eq('is_premium_only', true);

      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final contents = response as List<Map<String, dynamic>>;
      debugPrint('✅ 获取到 ${contents.length} 个会员专属内容');
      return contents;
    } catch (e) {
      debugPrint('❌ 获取会员专属内容失败: $e');
      return [];
    }
  }

  /// 检查是否可以导出无水印内容
  Future<bool> canExportWatermarkFree(String userId) async {
    try {
      final membership = await _subscriptionService.getCurrentMembership(userId);
      return membership?.hasWatermarkFree ?? false;
    } catch (e) {
      debugPrint('❌ 检查无水印导出权限失败: $e');
      return false;
    }
  }

  /// 检查是否支持优先处理
  Future<bool> hasPriorityProcessing(String userId) async {
    try {
      final membership = await _subscriptionService.getCurrentMembership(userId);
      return membership?.subscriptionPlan?.hasPriorityProcessing ?? false;
    } catch (e) {
      debugPrint('❌ 检查优先处理权限失败: $e');
      return false;
    }
  }
}

/// 会员功能访问结果
class MembershipAccessResult {
  final bool isAllowed;
  final String message;
  final MembershipAccessStatus status;

  const MembershipAccessResult._({
    required this.isAllowed,
    required this.message,
    required this.status,
  });

  factory MembershipAccessResult.allowed(String message) {
    return MembershipAccessResult._(
      isAllowed: true,
      message: message,
      status: MembershipAccessStatus.allowed,
    );
  }

  factory MembershipAccessResult.denied(String message) {
    return MembershipAccessResult._(
      isAllowed: false,
      message: message,
      status: MembershipAccessStatus.denied,
    );
  }

  factory MembershipAccessResult.limitReached(String message) {
    return MembershipAccessResult._(
      isAllowed: false,
      message: message,
      status: MembershipAccessStatus.limitReached,
    );
  }

  factory MembershipAccessResult.error(String message) {
    return MembershipAccessResult._(
      isAllowed: false,
      message: message,
      status: MembershipAccessStatus.error,
    );
  }
}

/// 会员访问状态枚举
enum MembershipAccessStatus {
  allowed,      // 允许访问
  denied,       // 权限不足
  limitReached, // 达到使用限制
  error,        // 验证错误
}