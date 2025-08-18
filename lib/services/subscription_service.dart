import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_plan.dart';
import '../models/user_membership.dart';
import 'supabase_service.dart';

/// 订阅管理服务
/// 处理订阅套餐、用户会员状态等功能
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService.instance;

  /// 获取所有可用的订阅套餐
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      debugPrint('📋 获取可用订阅套餐');
      
      final response = await _client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('plan_type', ascending: true);

      final plans = (response as List)
          .map((json) => SubscriptionPlan.fromJson(json))
          .toList();

      debugPrint('✅ 成功获取 ${plans.length} 个订阅套餐');
      return plans;
    } catch (e) {
      debugPrint('❌ 获取订阅套餐失败: $e');
      throw Exception('获取订阅套餐失败: $e');
    }
  }

  /// 根据套餐ID获取特定套餐
  Future<SubscriptionPlan?> getPlanById(String planId) async {
    try {
      debugPrint('🔍 获取套餐详情: $planId');
      
      final response = await _client
          .from('subscription_plans')
          .select()
          .eq('plan_id', planId)
          .single();

      final plan = SubscriptionPlan.fromJson(response);
      debugPrint('✅ 成功获取套餐: ${plan.planName}');
      return plan;
    } catch (e) {
      debugPrint('❌ 获取套餐详情失败: $e');
      return null;
    }
  }

  /// 获取用户当前会员信息
  Future<UserMembership?> getCurrentMembership(String userId) async {
    try {
      debugPrint('👤 获取用户会员信息: $userId');
      
      final response = await _client
          .from('user_memberships')
          .select('''
            *,
            subscription_plans (*)
          ''')
          .eq('user_id', userId)
          .eq('status', 'active')
          .single();

      final membership = UserMembership.fromJson(response);
      
      // 设置关联的订阅计划
      if (response['subscription_plans'] != null) {
        final plan = SubscriptionPlan.fromJson(response['subscription_plans']);
        final membershipWithPlan = membership.withSubscriptionPlan(plan);
        
        debugPrint('✅ 用户会员: ${membershipWithPlan.membershipTypeDisplay} - ${membershipWithPlan.statusDisplayText}');
        return membershipWithPlan;
      }

      return membership;
    } catch (e) {
      debugPrint('❌ 获取用户会员信息失败: $e');
      return null;
    }
  }

  /// 获取用户会员历史记录
  Future<List<UserMembership>> getMembershipHistory(String userId) async {
    try {
      debugPrint('📈 获取用户会员历史: $userId');
      
      final response = await _client
          .from('user_memberships')
          .select('''
            *,
            subscription_plans (*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final memberships = (response as List).map((json) {
        final membership = UserMembership.fromJson(json);
        
        // 设置关联的订阅计划
        if (json['subscription_plans'] != null) {
          final plan = SubscriptionPlan.fromJson(json['subscription_plans']);
          return membership.withSubscriptionPlan(plan);
        }
        
        return membership;
      }).toList();

      debugPrint('✅ 获取到 ${memberships.length} 条会员记录');
      return memberships;
    } catch (e) {
      debugPrint('❌ 获取会员历史失败: $e');
      return [];
    }
  }

  /// 创建订阅订单
  Future<String> createSubscription({
    required String userId,
    required String planId,
    required String paymentMethod,
    required bool isYearly,
  }) async {
    try {
      debugPrint('💳 创建订阅订单: userId=$userId, planId=$planId, yearly=$isYearly');
      
      // 获取套餐信息
      final plan = await getPlanById(planId);
      if (plan == null) {
        throw Exception('无效的套餐ID');
      }

      // 计算价格和到期时间
      final price = isYearly && plan.priceYearly != null 
          ? plan.priceYearly! 
          : plan.priceMonthly;
      
      final duration = isYearly ? 365 : 30;
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: duration));

      // 创建支付订单记录
      final orderResponse = await _client
          .from('payment_orders')
          .insert({
            'user_id': userId,
            'plan_id': planId,
            'amount': price,
            'payment_method': paymentMethod,
            'duration_days': duration,
            'status': 'pending',
            'created_at': startDate.toIso8601String(),
          })
          .select('order_id')
          .single();

      final orderId = orderResponse['order_id'] as String;
      
      debugPrint('✅ 订阅订单创建成功: $orderId');
      return orderId;
    } catch (e) {
      debugPrint('❌ 创建订阅订单失败: $e');
      throw Exception('创建订阅订单失败: $e');
    }
  }

  /// 确认支付并激活会员
  Future<UserMembership> confirmPaymentAndActivateMembership({
    required String orderId,
    required String transactionId,
  }) async {
    try {
      debugPrint('✅ 确认支付并激活会员: $orderId');
      
      // 获取订单信息
      final orderResponse = await _client
          .from('payment_orders')
          .select()
          .eq('order_id', orderId)
          .single();

      if (orderResponse['status'] != 'pending') {
        throw Exception('订单状态异常');
      }

      final userId = orderResponse['user_id'] as String;
      final planId = orderResponse['plan_id'] as String;
      final durationDays = orderResponse['duration_days'] as int;
      
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: durationDays));

      // 更新订单状态
      await _client
          .from('payment_orders')
          .update({
            'status': 'completed',
            'transaction_id': transactionId,
            'paid_at': startDate.toIso8601String(),
          })
          .eq('order_id', orderId);

      // 检查是否已有活跃会员，如果有则先取消
      final existingMembership = await getCurrentMembership(userId);
      if (existingMembership != null) {
        await _client
            .from('user_memberships')
            .update({'status': 'canceled'})
            .eq('membership_id', existingMembership.membershipId);
      }

      // 创建新的会员记录
      final membershipResponse = await _client
          .from('user_memberships')
          .insert({
            'user_id': userId,
            'plan_id': planId,
            'status': 'active',
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'auto_renewal': true,
            'payment_method': orderResponse['payment_method'],
          })
          .select()
          .single();

      final membership = UserMembership.fromJson(membershipResponse);
      
      // 获取并设置套餐信息
      final plan = await getPlanById(planId);
      if (plan != null) {
        final membershipWithPlan = membership.withSubscriptionPlan(plan);
        debugPrint('🎉 会员激活成功: ${plan.planName}');
        return membershipWithPlan;
      }

      return membership;
    } catch (e) {
      debugPrint('❌ 激活会员失败: $e');
      throw Exception('激活会员失败: $e');
    }
  }

  /// 取消订阅
  Future<void> cancelSubscription(String membershipId) async {
    try {
      debugPrint('🚫 取消订阅: $membershipId');
      
      await _client
          .from('user_memberships')
          .update({
            'status': 'canceled',
            'auto_renewal': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('membership_id', membershipId);

      debugPrint('✅ 订阅取消成功');
    } catch (e) {
      debugPrint('❌ 取消订阅失败: $e');
      throw Exception('取消订阅失败: $e');
    }
  }

  /// 暂停订阅
  Future<void> suspendSubscription(String membershipId) async {
    try {
      debugPrint('⏸️ 暂停订阅: $membershipId');
      
      await _client
          .from('user_memberships')
          .update({
            'status': 'suspended',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('membership_id', membershipId);

      debugPrint('✅ 订阅暂停成功');
    } catch (e) {
      debugPrint('❌ 暂停订阅失败: $e');
      throw Exception('暂停订阅失败: $e');
    }
  }

  /// 恢复订阅
  Future<void> resumeSubscription(String membershipId) async {
    try {
      debugPrint('▶️ 恢复订阅: $membershipId');
      
      await _client
          .from('user_memberships')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('membership_id', membershipId);

      debugPrint('✅ 订阅恢复成功');
    } catch (e) {
      debugPrint('❌ 恢复订阅失败: $e');
      throw Exception('恢复订阅失败: $e');
    }
  }

  /// 切换自动续费设置
  Future<void> toggleAutoRenewal(String membershipId, bool autoRenewal) async {
    try {
      debugPrint('🔄 切换自动续费: $membershipId -> $autoRenewal');
      
      await _client
          .from('user_memberships')
          .update({
            'auto_renewal': autoRenewal,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('membership_id', membershipId);

      debugPrint('✅ 自动续费设置已更新');
    } catch (e) {
      debugPrint('❌ 更新自动续费设置失败: $e');
      throw Exception('更新自动续费设置失败: $e');
    }
  }

  /// 检查用户权限
  Future<bool> checkUserPermission(String userId, String permission) async {
    try {
      final membership = await getCurrentMembership(userId);
      if (membership == null || !membership.isActive) {
        return false;
      }

      return membership.canUseFeature(permission);
    } catch (e) {
      debugPrint('❌ 检查用户权限失败: $e');
      return false;
    }
  }

  /// 获取用户功能使用限制
  Future<T?> getUserFeatureLimit<T>(String userId, String feature) async {
    try {
      final membership = await getCurrentMembership(userId);
      if (membership == null || !membership.isActive) {
        return null;
      }

      return membership.getFeatureLimit<T>(feature);
    } catch (e) {
      debugPrint('❌ 获取功能限制失败: $e');
      return null;
    }
  }

  /// 获取即将到期的会员列表（用于续费提醒）
  Future<List<UserMembership>> getExpiringMemberships([int days = 7]) async {
    try {
      debugPrint('⏰ 获取即将到期的会员 (${days}天内)');
      
      final expiryDate = DateTime.now().add(Duration(days: days));
      
      final response = await _client
          .from('user_memberships')
          .select('''
            *,
            subscription_plans (*)
          ''')
          .eq('status', 'active')
          .lt('end_date', expiryDate.toIso8601String())
          .order('end_date', ascending: true);

      final memberships = (response as List).map((json) {
        final membership = UserMembership.fromJson(json);
        
        if (json['subscription_plans'] != null) {
          final plan = SubscriptionPlan.fromJson(json['subscription_plans']);
          return membership.withSubscriptionPlan(plan);
        }
        
        return membership;
      }).toList();

      debugPrint('✅ 找到 ${memberships.length} 个即将到期的会员');
      return memberships;
    } catch (e) {
      debugPrint('❌ 获取即将到期会员失败: $e');
      return [];
    }
  }

  /// 获取订阅统计信息
  Future<Map<String, dynamic>> getSubscriptionStats(String userId) async {
    try {
      debugPrint('📊 获取订阅统计信息: $userId');
      
      final currentMembership = await getCurrentMembership(userId);
      final membershipHistory = await getMembershipHistory(userId);
      
      final stats = <String, dynamic>{
        'current_plan': currentMembership?.subscriptionPlan?.planName ?? '无',
        'current_status': currentMembership?.statusDisplayText ?? '未订阅',
        'membership_tier': currentMembership?.membershipTier ?? 0,
        'days_remaining': currentMembership?.daysUntilExpiration ?? 0,
        'auto_renewal': currentMembership?.autoRenewal ?? false,
        'total_subscriptions': membershipHistory.length,
        'is_premium': currentMembership?.isPremiumUser ?? false,
      };
      
      debugPrint('✅ 订阅统计信息获取成功');
      return stats;
    } catch (e) {
      debugPrint('❌ 获取订阅统计失败: $e');
      return {};
    }
  }
}