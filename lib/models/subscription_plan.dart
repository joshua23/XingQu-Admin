import 'package:json_annotation/json_annotation.dart';

part 'subscription_plan.g.dart';

/// 订阅套餐数据模型
/// 对应数据库 subscription_plans 表
@JsonSerializable()
class SubscriptionPlan {
  @JsonKey(name: 'plan_id')
  final String planId;
  
  @JsonKey(name: 'plan_name')
  final String planName;
  
  final String description;
  
  @JsonKey(name: 'price_monthly')
  final double priceMonthly;
  
  @JsonKey(name: 'price_yearly')
  final double? priceYearly;
  
  @JsonKey(name: 'plan_type')
  final int planTier;
  
  final Map<String, dynamic> features;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const SubscriptionPlan({
    required this.planId,
    required this.planName,
    required this.description,
    required this.priceMonthly,
    this.priceYearly,
    required this.planTier,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);

  /// 获取计划显示名称
  String get displayName => planName;

  /// 获取月付价格文本
  String get monthlyPriceText => '¥${priceMonthly.toStringAsFixed(0)}/月';

  /// 获取年付价格文本
  String get yearlyPriceText => priceYearly != null 
      ? '¥${priceYearly!.toStringAsFixed(0)}/年' 
      : '';

  /// 获取年付折扣比例
  double get yearlyDiscount => priceYearly != null && priceMonthly > 0
      ? (1 - (priceYearly! / 12) / priceMonthly) * 100
      : 0.0;

  /// 是否为免费计划
  bool get isFree => priceMonthly == 0.0;

  /// 是否为高级计划
  bool get isPremium => planTier >= 2;

  /// 获取计划层级名称
  String get tierName {
    switch (planTier) {
      case 0:
        return '体验版';
      case 1:
        return '基础版';
      case 2:
        return '专业版';
      case 3:
        return '企业版';
      default:
        return '未知';
    }
  }

  /// 获取特定功能的限制值
  T? getFeatureLimit<T>(String featureName) {
    return features[featureName] as T?;
  }

  /// 检查是否包含特定功能
  bool hasFeature(String featureName) {
    return features.containsKey(featureName) && features[featureName] == true;
  }

  /// 获取AI智能体数量限制
  int get aiAgentLimit => getFeatureLimit<int>('ai_agent_limit') ?? 0;

  /// 获取创作次数限制
  int get creationLimit => getFeatureLimit<int>('creation_limit') ?? 0;

  /// 获取导出次数限制
  int get exportLimit => getFeatureLimit<int>('export_limit') ?? 0;

  /// 是否支持高级AI功能
  bool get hasAdvancedAI => hasFeature('advanced_ai');

  /// 是否支持优先级处理
  bool get hasPriorityProcessing => hasFeature('priority_processing');

  /// 是否支持无水印导出
  bool get hasWatermarkFree => hasFeature('watermark_free');

  @override
  String toString() {
    return 'SubscriptionPlan(planId: $planId, planName: $planName, tier: $planTier, price: $monthlyPriceText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.planId == planId;
  }

  @override
  int get hashCode => planId.hashCode;

  /// 复制并修改部分属性
  SubscriptionPlan copyWith({
    String? planId,
    String? planName,
    String? description,
    double? priceMonthly,
    double? priceYearly,
    int? planTier,
    Map<String, dynamic>? features,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      priceMonthly: priceMonthly ?? this.priceMonthly,
      priceYearly: priceYearly ?? this.priceYearly,
      planTier: planTier ?? this.planTier,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 订阅计划类型枚举
enum SubscriptionPlanType {
  free(0, '体验版'),
  basic(1, '基础版'), 
  professional(2, '专业版'),
  enterprise(3, '企业版');

  const SubscriptionPlanType(this.tier, this.displayName);
  
  final int tier;
  final String displayName;
  
  static SubscriptionPlanType fromTier(int tier) {
    return SubscriptionPlanType.values.firstWhere(
      (type) => type.tier == tier,
      orElse: () => SubscriptionPlanType.free,
    );
  }
}