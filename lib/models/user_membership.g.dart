// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMembership _$UserMembershipFromJson(Map<String, dynamic> json) =>
    UserMembership(
      membershipId: json['membership_id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      autoRenewal: json['auto_renewal'] as bool,
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserMembershipToJson(UserMembership instance) =>
    <String, dynamic>{
      'membership_id': instance.membershipId,
      'user_id': instance.userId,
      'plan_id': instance.planId,
      'status': instance.status,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'auto_renewal': instance.autoRenewal,
      'payment_method': instance.paymentMethod,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
