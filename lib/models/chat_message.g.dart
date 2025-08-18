// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  content: json['content'] as String,
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  timestamp: DateTime.parse(json['timestamp'] as String),
  characterId: json['characterId'] as String?,
  tokensUsed: (json['tokensUsed'] as num?)?.toInt(),
  cost: (json['cost'] as num?)?.toDouble(),
  status:
      $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
      MessageStatus.sent,
  error: json['error'] as String?,
  isStreaming: json['isStreaming'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'characterId': instance.characterId,
      'tokensUsed': instance.tokensUsed,
      'cost': instance.cost,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'error': instance.error,
      'isStreaming': instance.isStreaming,
    };

const _$MessageTypeEnumMap = {
  MessageType.user: 'user',
  MessageType.assistant: 'assistant',
  MessageType.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.receiving: 'receiving',
  MessageStatus.received: 'received',
  MessageStatus.failed: 'failed',
};

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => ChatSession(
  id: json['id'] as String,
  title: json['title'] as String,
  userId: json['userId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  characterId: json['characterId'] as String?,
  messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
  totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
  status:
      $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
      SessionStatus.active,
);

Map<String, dynamic> _$ChatSessionToJson(ChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'characterId': instance.characterId,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'messageCount': instance.messageCount,
      'totalCost': instance.totalCost,
      'status': _$SessionStatusEnumMap[instance.status]!,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.archived: 'archived',
  SessionStatus.deleted: 'deleted',
};

AiChatResponse _$AiChatResponseFromJson(Map<String, dynamic> json) =>
    AiChatResponse(
      sessionId: json['sessionId'] as String,
      messageId: json['messageId'] as String,
      content: json['content'] as String,
      tokensUsed: (json['tokensUsed'] as num).toInt(),
      cost: (json['cost'] as num).toDouble(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$AiChatResponseToJson(AiChatResponse instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'messageId': instance.messageId,
      'content': instance.content,
      'tokensUsed': instance.tokensUsed,
      'cost': instance.cost,
      'error': instance.error,
    };
