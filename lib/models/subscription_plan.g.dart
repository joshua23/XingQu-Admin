// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    SubscriptionPlan(
      planId: json['plan_id'] as String,
      planName: json['plan_name'] as String,
      description: json['description'] as String,
      priceMonthly: (json['price_monthly'] as num).toDouble(),
      priceYearly: (json['price_yearly'] as num?)?.toDouble(),
      planTier: (json['plan_type'] as num).toInt(),
      features: json['features'] as Map<String, dynamic>,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) =>
    <String, dynamic>{
      'plan_id': instance.planId,
      'plan_name': instance.planName,
      'description': instance.description,
      'price_monthly': instance.priceMonthly,
      'price_yearly': instance.priceYearly,
      'plan_type': instance.planTier,
      'features': instance.features,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
