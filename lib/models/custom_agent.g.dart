// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomAgent _$CustomAgentFromJson(Map<String, dynamic> json) => CustomAgent(
  agentId: json['agent_id'] as String,
  userId: json['user_id'] as String,
  agentName: json['agent_name'] as String,
  description: json['description'] as String,
  systemPrompt: json['system_prompt'] as String,
  configuration: json['configuration'] as Map<String, dynamic>,
  avatarUrl: json['avatar_url'] as String?,
  capabilities: (json['capabilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  isPublic: json['is_public'] as bool,
  isActive: json['is_active'] as bool,
  usageCount: (json['usage_count'] as num).toInt(),
  ratingScore: (json['rating_score'] as num).toDouble(),
  ratingCount: (json['rating_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  lastUsedAt: json['last_used_at'] == null
      ? null
      : DateTime.parse(json['last_used_at'] as String),
);

Map<String, dynamic> _$CustomAgentToJson(CustomAgent instance) =>
    <String, dynamic>{
      'agent_id': instance.agentId,
      'user_id': instance.userId,
      'agent_name': instance.agentName,
      'description': instance.description,
      'system_prompt': instance.systemPrompt,
      'configuration': instance.configuration,
      'avatar_url': instance.avatarUrl,
      'capabilities': instance.capabilities,
      'tags': instance.tags,
      'is_public': instance.isPublic,
      'is_active': instance.isActive,
      'usage_count': instance.usageCount,
      'rating_score': instance.ratingScore,
      'rating_count': instance.ratingCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };
