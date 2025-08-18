import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

/// AI对话消息模型
/// 支持火山引擎流式响应和多轮对话
@JsonSerializable()
class ChatMessage {
  /// 消息唯一ID
  final String id;
  
  /// 会话ID
  final String sessionId;
  
  /// 消息内容
  final String content;
  
  /// 消息类型：user(用户) / assistant(AI助手)
  final MessageType type;
  
  /// 发送时间
  final DateTime timestamp;
  
  /// AI角色ID（可选）
  final String? characterId;
  
  /// Token使用量（仅AI回复消息）
  final int? tokensUsed;
  
  /// API调用成本（仅AI回复消息）
  final double? cost;
  
  /// 消息状态
  final MessageStatus status;
  
  /// 错误信息（如果有）
  final String? error;
  
  /// 是否为流式响应中的部分消息
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.characterId,
    this.tokensUsed,
    this.cost,
    this.status = MessageStatus.sent,
    this.error,
    this.isStreaming = false,
  });

  /// 从JSON创建实例
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// 创建用户消息
  factory ChatMessage.user({
    required String content,
    required String sessionId,
    String? characterId,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      characterId: characterId,
      status: MessageStatus.sending,
    );
  }

  /// 创建AI助手消息
  factory ChatMessage.assistant({
    required String content,
    required String sessionId,
    String? characterId,
    int? tokensUsed,
    double? cost,
    bool isStreaming = false,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: content,
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      characterId: characterId,
      tokensUsed: tokensUsed,
      cost: cost,
      status: isStreaming ? MessageStatus.receiving : MessageStatus.sent,
      isStreaming: isStreaming,
    );
  }

  /// 创建系统消息
  factory ChatMessage.system({
    required String content,
    required String sessionId,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// 创建错误消息
  factory ChatMessage.error({
    required String error,
    required String sessionId,
    String? characterId,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: '发送失败: $error',
      type: MessageType.system,
      timestamp: DateTime.now(),
      characterId: characterId,
      status: MessageStatus.failed,
      error: error,
    );
  }

  /// 复制并更新消息
  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? characterId,
    int? tokensUsed,
    double? cost,
    MessageStatus? status,
    String? error,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      characterId: characterId ?? this.characterId,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      error: error ?? this.error,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}

/// 消息类型枚举
enum MessageType {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('system')
  system,
}

/// 消息状态枚举
enum MessageStatus {
  @JsonValue('sending')
  sending,     // 发送中
  @JsonValue('sent')
  sent,        // 已发送
  @JsonValue('receiving')
  receiving,   // 接收中（流式响应）
  @JsonValue('received')
  received,    // 已接收
  @JsonValue('failed')
  failed,      // 发送/接收失败
}

/// 对话会话模型
@JsonSerializable()
class ChatSession {
  /// 会话ID
  final String id;
  
  /// 会话标题
  final String title;
  
  /// AI角色ID
  final String? characterId;
  
  /// 用户ID
  final String userId;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后更新时间
  final DateTime updatedAt;
  
  /// 消息总数
  final int messageCount;
  
  /// 总成本
  final double totalCost;
  
  /// 会话状态
  final SessionStatus status;

  const ChatSession({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.characterId,
    this.messageCount = 0,
    this.totalCost = 0.0,
    this.status = SessionStatus.active,
  });

  /// 从JSON创建实例
  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);

  /// 创建新会话
  factory ChatSession.create({
    required String userId,
    String? characterId,
    String? title,
  }) {
    final now = DateTime.now();
    return ChatSession(
      id: now.millisecondsSinceEpoch.toString(),
      title: title ?? '新的对话',
      userId: userId,
      characterId: characterId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 复制并更新会话
  ChatSession copyWith({
    String? id,
    String? title,
    String? characterId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    double? totalCost,
    SessionStatus? status,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      characterId: characterId ?? this.characterId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
    );
  }
}

/// 会话状态枚举
enum SessionStatus {
  @JsonValue('active')
  active,      // 活跃
  @JsonValue('archived')
  archived,    // 已归档
  @JsonValue('deleted')
  deleted,     // 已删除
}

/// AI对话响应模型（来自火山引擎Edge Function）
@JsonSerializable()
class AiChatResponse {
  /// 会话ID
  final String sessionId;
  
  /// 消息ID
  final String messageId;
  
  /// AI回复内容
  final String content;
  
  /// Token使用量
  final int tokensUsed;
  
  /// API调用成本
  final double cost;
  
  /// 错误信息（如果有）
  final String? error;

  const AiChatResponse({
    required this.sessionId,
    required this.messageId,
    required this.content,
    required this.tokensUsed,
    required this.cost,
    this.error,
  });

  /// 从JSON创建实例
  factory AiChatResponse.fromJson(Map<String, dynamic> json) =>
      _$AiChatResponseFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$AiChatResponseToJson(this);
  
  /// 是否成功
  bool get isSuccess => error == null;
}