import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';
import '../models/user_membership.dart';
import '../services/subscription_service.dart';
import '../services/membership_service.dart';

/// 订阅状态管理Provider
/// 管理用户订阅状态、套餐信息等
class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final MembershipService _membershipService = MembershipService();

  // 订阅套餐列表
  List<SubscriptionPlan> _availablePlans = [];
  List<SubscriptionPlan> get availablePlans => _availablePlans;

  // 用户会员信息
  UserMembership? _currentMembership;
  UserMembership? get currentMembership => _currentMembership;

  // 会员权益信息
  Map<String, dynamic> _membershipBenefits = {};
  Map<String, dynamic> get membershipBenefits => _membershipBenefits;

  // 使用统计信息
  Map<String, dynamic> _usageStats = {};
  Map<String, dynamic> get usageStats => _usageStats;

  // 加载状态
  bool _isLoadingPlans = false;
  bool _isLoadingMembership = false;
  bool _isProcessingPayment = false;

  bool get isLoadingPlans => _isLoadingPlans;
  bool get isLoadingMembership => _isLoadingMembership;
  bool get isProcessingPayment => _isProcessingPayment;

  // 错误信息
  String? _error;
  String? get error => _error;

  /// 初始化订阅数据
  Future<void> initialize(String userId) async {
    await Future.wait([
      loadAvailablePlans(),
      loadCurrentMembership(userId),
      loadMembershipBenefits(userId),
    ]);
  }

  /// 加载可用订阅套餐
  Future<void> loadAvailablePlans() async {
    if (_isLoadingPlans) return;
    
    _isLoadingPlans = true;
    _error = null;
    notifyListeners();

    try {
      _availablePlans = await _subscriptionService.getAvailablePlans();
      debugPrint('📋 已加载 ${_availablePlans.length} 个订阅套餐');
    } catch (e) {
      _error = '加载订阅套餐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  /// 加载用户当前会员信息
  Future<void> loadCurrentMembership(String userId) async {
    if (_isLoadingMembership) return;
    
    _isLoadingMembership = true;
    _error = null;
    notifyListeners();

    try {
      _currentMembership = await _subscriptionService.getCurrentMembership(userId);
      debugPrint('👤 已加载用户会员信息: ${_currentMembership?.membershipTypeDisplay ?? '无会员'}');
    } catch (e) {
      _error = '加载会员信息失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingMembership = false;
      notifyListeners();
    }
  }

  /// 加载会员权益信息
  Future<void> loadMembershipBenefits(String userId) async {
    try {
      _membershipBenefits = await _membershipService.getMembershipBenefits(userId);
      debugPrint('💎 已加载会员权益信息');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载会员权益失败: $e');
    }
  }

  /// 创建订阅
  Future<bool> createSubscription({
    required String userId,
    required String planId,
    required String paymentMethod,
    required bool isYearly,
  }) async {
    if (_isProcessingPayment) return false;
    
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final orderId = await _subscriptionService.createSubscription(
        userId: userId,
        planId: planId,
        paymentMethod: paymentMethod,
        isYearly: isYearly,
      );

      debugPrint('💳 订阅订单创建成功: $orderId');
      
      // 这里应该调用支付SDK进行实际支付
      // 支付成功后调用 confirmPayment 方法
      
      return true;
    } catch (e) {
      _error = '创建订阅失败: $e';
      debugPrint('❌ $_error');
      return false;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  /// 确认支付并激活会员
  Future<bool> confirmPayment({
    required String orderId,
    required String transactionId,
    required String userId,
  }) async {
    try {
      final membership = await _subscriptionService.confirmPaymentAndActivateMembership(
        orderId: orderId,
        transactionId: transactionId,
      );

      _currentMembership = membership;
      debugPrint('🎉 会员激活成功: ${membership.membershipTypeDisplay}');
      
      // 重新加载会员权益
      await loadMembershipBenefits(userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = '激活会员失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// 取消订阅
  Future<bool> cancelSubscription(String userId) async {
    if (_currentMembership == null) return false;
    
    try {
      await _subscriptionService.cancelSubscription(_currentMembership!.membershipId);
      
      // 重新加载会员信息
      await loadCurrentMembership(userId);
      await loadMembershipBenefits(userId);
      
      debugPrint('🚫 订阅取消成功');
      return true;
    } catch (e) {
      _error = '取消订阅失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// 切换自动续费
  Future<bool> toggleAutoRenewal(String userId, bool autoRenewal) async {
    if (_currentMembership == null) return false;
    
    try {
      await _subscriptionService.toggleAutoRenewal(
        _currentMembership!.membershipId,
        autoRenewal,
      );
      
      // 更新本地状态
      _currentMembership = _currentMembership!.copyWith(autoRenewal: autoRenewal);
      
      debugPrint('🔄 自动续费设置已更新: $autoRenewal');
      notifyListeners();
      return true;
    } catch (e) {
      _error = '更新自动续费失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// 检查用户权限
  Future<bool> checkPermission(String userId, String permission) async {
    try {
      return await _membershipService.hasPermission(
        userId: userId,
        feature: permission,
      );
    } catch (e) {
      debugPrint('❌ 检查权限失败: $e');
      return false;
    }
  }

  /// 获取功能使用限制
  Future<int> getFeatureLimit(String userId, String feature) async {
    try {
      return await _membershipService.getUsageLimit(
        userId: userId,
        feature: feature,
      );
    } catch (e) {
      debugPrint('❌ 获取功能限制失败: $e');
      return 0;
    }
  }

  /// 获取剩余使用量
  Future<int> getRemainingUsage(String userId, String feature) async {
    try {
      return await _membershipService.getRemainingUsage(
        userId: userId,
        feature: feature,
      );
    } catch (e) {
      debugPrint('❌ 获取剩余使用量失败: $e');
      return 0;
    }
  }

  /// 消费功能使用量
  Future<void> consumeUsage(String userId, String feature, [int amount = 1]) async {
    try {
      await _membershipService.consumeFeatureUsage(
        userId: userId,
        feature: feature,
        amount: amount,
      );
      
      // 可以选择重新加载使用统计
      // await loadUsageStats(userId);
    } catch (e) {
      debugPrint('❌ 消费功能使用量失败: $e');
    }
  }

  /// 加载使用统计
  Future<void> loadUsageStats(String userId) async {
    try {
      _usageStats = await _membershipService.getUsageReport(userId);
      debugPrint('📊 已加载使用统计');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载使用统计失败: $e');
    }
  }

  /// 获取升级建议
  Future<Map<String, dynamic>> getUpgradeSuggestion(String userId) async {
    try {
      return await _membershipService.getUpgradeSuggestion(userId);
    } catch (e) {
      debugPrint('❌ 获取升级建议失败: $e');
      return {};
    }
  }

  /// 获取到期提醒
  Future<Map<String, dynamic>?> getExpirationReminder(String userId) async {
    try {
      return await _membershipService.getExpirationReminder(userId);
    } catch (e) {
      debugPrint('❌ 获取到期提醒失败: $e');
      return null;
    }
  }

  // 便捷属性和方法

  /// 是否为免费用户
  bool get isFreeUser => _currentMembership?.isFreeUser ?? true;

  /// 是否为高级会员
  bool get isPremiumUser => _currentMembership?.isPremiumUser ?? false;

  /// 是否有有效会员
  bool get hasActiveMembership => _currentMembership?.isActive ?? false;

  /// 会员类型显示名称
  String get membershipTypeDisplay => _currentMembership?.membershipTypeDisplay ?? '免费用户';

  /// 到期时间显示
  String get expirationDisplay => _currentMembership?.remainingDaysText ?? '永久';

  /// 是否即将到期
  bool get isExpiringSoon => _currentMembership?.isExpiringsoon ?? false;

  /// 是否自动续费
  bool get isAutoRenewal => _currentMembership?.autoRenewal ?? false;

  /// 根据层级获取套餐
  SubscriptionPlan? getPlanByTier(int tier) {
    try {
      return _availablePlans.firstWhere((plan) => plan.planTier == tier);
    } catch (e) {
      return null;
    }
  }

  /// 获取推荐套餐（通常是基础版或专业版）
  SubscriptionPlan? get recommendedPlan {
    return getPlanByTier(1) ?? getPlanByTier(2);
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 刷新所有数据
  Future<void> refresh(String userId) async {
    await initialize(userId);
  }

  /// 重置状态
  void reset() {
    _availablePlans.clear();
    _currentMembership = null;
    _membershipBenefits.clear();
    _usageStats.clear();
    _isLoadingPlans = false;
    _isLoadingMembership = false;
    _isProcessingPayment = false;
    _error = null;
    notifyListeners();
  }
}