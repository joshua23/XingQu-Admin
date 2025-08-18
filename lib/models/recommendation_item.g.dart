// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationItem _$RecommendationItemFromJson(Map<String, dynamic> json) =>
    RecommendationItem(
      recommendationId: json['recommendation_id'] as String,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as String,
      contentType: json['content_type'] as String,
      recommendationScore: (json['recommendation_score'] as num).toDouble(),
      algorithmType: json['algorithm_type'] as String,
      recommendationReason: json['recommendation_reason'] as String?,
      positionRank: (json['position_rank'] as num).toInt(),
      isClicked: json['is_clicked'] as bool,
      clickTime: json['click_time'] == null
          ? null
          : DateTime.parse(json['click_time'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$RecommendationItemToJson(RecommendationItem instance) =>
    <String, dynamic>{
      'recommendation_id': instance.recommendationId,
      'user_id': instance.userId,
      'content_id': instance.contentId,
      'content_type': instance.contentType,
      'recommendation_score': instance.recommendationScore,
      'algorithm_type': instance.algorithmType,
      'recommendation_reason': instance.recommendationReason,
      'position_rank': instance.positionRank,
      'is_clicked': instance.isClicked,
      'click_time': instance.clickTime?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };
