import 'package:json_annotation/json_annotation.dart';
import 'subscription_plan.dart';

part 'user_membership.g.dart';

/// 用户会员信息数据模型
/// 对应数据库 user_memberships 表
@JsonSerializable()
class UserMembership {
  @JsonKey(name: 'membership_id')
  final String membershipId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'plan_id')
  final String planId;
  
  final String status;
  
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  
  @JsonKey(name: 'auto_renewal')
  final bool autoRenewal;
  
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // 关联的订阅计划信息
  @JsonKey(includeFromJson: false, includeToJson: false)
  SubscriptionPlan? subscriptionPlan;

  UserMembership({
    required this.membershipId,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenewal,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionPlan,
  });

  factory UserMembership.fromJson(Map<String, dynamic> json) =>
      _$UserMembershipFromJson(json);

  Map<String, dynamic> toJson() => _$UserMembershipToJson(this);

  /// 检查会员是否有效
  bool get isActive {
    final now = DateTime.now();
    return status == 'active' && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }

  /// 检查会员是否已过期
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  /// 检查会员是否即将到期（7天内）
  bool get isExpiringsoon {
    final daysUntilExpiry = daysUntilExpiration;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
  }

  /// 获取距离到期的天数
  int get daysUntilExpiration {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  /// 获取剩余天数文本
  String get remainingDaysText {
    final days = daysUntilExpiration;
    if (days < 0) {
      return '已过期';
    } else if (days == 0) {
      return '今日到期';
    } else if (days == 1) {
      return '明日到期';
    } else {
      return '$days天后到期';
    }
  }

  /// 获取会员状态显示文本
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'active':
        return isExpired ? '已过期' : '有效';
      case 'canceled':
        return '已取消';
      case 'suspended':
        return '暂停';
      case 'pending':
        return '待激活';
      default:
        return '未知状态';
    }
  }

  /// 获取会员类型显示
  String get membershipTypeDisplay {
    if (subscriptionPlan != null) {
      return subscriptionPlan!.tierName;
    }
    return '未知类型';
  }

  /// 获取支付方式显示文本
  String get paymentMethodDisplay {
    switch (paymentMethod?.toLowerCase()) {
      case 'wechat':
        return '微信支付';
      case 'alipay':
        return '支付宝';
      case 'apple':
        return 'Apple Pay';
      case 'credit_card':
        return '信用卡';
      default:
        return paymentMethod ?? '未知';
    }
  }

  /// 是否为免费会员
  bool get isFreeUser {
    return subscriptionPlan?.isFree ?? false;
  }

  /// 是否为高级会员
  bool get isPremiumUser {
    return isActive && (subscriptionPlan?.isPremium ?? false);
  }

  /// 获取会员等级
  int get membershipTier {
    return subscriptionPlan?.planTier ?? 0;
  }

  /// 检查是否可以使用特定功能
  bool canUseFeature(String featureName) {
    if (!isActive) return false;
    return subscriptionPlan?.hasFeature(featureName) ?? false;
  }

  /// 获取功能使用限制
  T? getFeatureLimit<T>(String featureName) {
    if (!isActive) return null;
    return subscriptionPlan?.getFeatureLimit<T>(featureName);
  }

  /// 获取AI智能体使用限制
  int get aiAgentLimit {
    return getFeatureLimit<int>('ai_agent_limit') ?? 0;
  }

  /// 获取创作次数限制
  int get creationLimit {
    return getFeatureLimit<int>('creation_limit') ?? 0;
  }

  /// 检查是否支持高级AI功能
  bool get hasAdvancedAI {
    return canUseFeature('advanced_ai');
  }

  /// 检查是否支持无水印导出
  bool get hasWatermarkFree {
    return canUseFeature('watermark_free');
  }

  @override
  String toString() {
    return 'UserMembership(userId: $userId, status: $status, plan: ${subscriptionPlan?.planName}, expires: ${endDate.toString().substring(0, 10)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMembership && other.membershipId == membershipId;
  }

  @override
  int get hashCode => membershipId.hashCode;

  /// 复制并修改部分属性
  UserMembership copyWith({
    String? membershipId,
    String? userId,
    String? planId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenewal,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    SubscriptionPlan? subscriptionPlan,
  }) {
    return UserMembership(
      membershipId: membershipId ?? this.membershipId,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }

  /// 设置关联的订阅计划
  UserMembership withSubscriptionPlan(SubscriptionPlan plan) {
    return copyWith(subscriptionPlan: plan);
  }
}

/// 会员状态枚举
enum MembershipStatus {
  active('active', '有效'),
  canceled('canceled', '已取消'),
  suspended('suspended', '暂停'),
  pending('pending', '待激活'),
  expired('expired', '已过期');

  const MembershipStatus(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static MembershipStatus fromString(String status) {
    return MembershipStatus.values.firstWhere(
      (s) => s.value == status.toLowerCase(),
      orElse: () => MembershipStatus.expired,
    );
  }
}

/// 支付方式枚举
enum PaymentMethod {
  wechat('wechat', '微信支付'),
  alipay('alipay', '支付宝'),
  apple('apple', 'Apple Pay'),
  creditCard('credit_card', '信用卡');

  const PaymentMethod(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static PaymentMethod fromString(String method) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value == method.toLowerCase(),
      orElse: () => PaymentMethod.wechat,
    );
  }
}