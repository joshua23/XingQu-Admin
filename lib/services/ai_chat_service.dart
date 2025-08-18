import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../config/supabase_config.dart';

/// 火山引擎AI对话服务
/// 集成已部署的Edge Functions，提供完整的AI对话功能
class AiChatService {
  static AiChatService? _instance;
  
  /// Edge Functions基础URL
  static const String _baseUrl = 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1';
  
  /// HTTP客户端
  final http.Client _httpClient = http.Client();
  
  /// Supabase客户端
  final SupabaseClient _supabase = Supabase.instance.client;

  AiChatService._internal();

  /// 获取单例实例
  static AiChatService get instance {
    _instance ??= AiChatService._internal();
    return _instance!;
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }

  /// 发送消息给AI（非流式）
  /// 
  /// [message] 用户消息内容
  /// [sessionId] 会话ID，可选，不提供则创建新会话
  /// [characterId] AI角色ID，可选
  /// [temperature] 温度参数，控制回复随机性，默认0.7
  /// [maxTokens] 最大Token数，默认2048
  /// 
  /// 返回 [AiChatResponse] AI回复内容
  Future<AiChatResponse> sendMessage({
    required String message,
    String? sessionId,
    String? characterId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      // 获取认证Token
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken == null) {
        throw AiChatException('用户未登录');
      }

      // 构建请求
      final requestBody = {
        'message': message,
        'stream': false,
        'temperature': temperature,
        'maxTokens': maxTokens,
      };
      
      if (sessionId != null) {
        requestBody['sessionId'] = sessionId;
      }
      
      if (characterId != null) {
        requestBody['characterId'] = characterId;
      }

      // 发送请求
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/ai-chat'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AiChatResponse.fromJson(responseData);
      } else {
        final error = jsonDecode(response.body);
        throw AiChatException(
          error['error'] ?? '请求失败: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw AiChatException('请求超时，请检查网络连接');
    } catch (e) {
      if (e is AiChatException) {
        rethrow;
      }
      throw AiChatException('发送消息失败: $e');
    }
  }

  /// 发送消息给AI（流式响应）
  /// 
  /// [message] 用户消息内容
  /// [sessionId] 会话ID，可选，不提供则创建新会话
  /// [characterId] AI角色ID，可选
  /// [temperature] 温度参数，控制回复随机性，默认0.7
  /// [maxTokens] 最大Token数，默认2048
  /// 
  /// 返回 [Stream<String>] 流式响应内容流
  Stream<String> sendMessageStream({
    required String message,
    String? sessionId,
    String? characterId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    try {
      // 获取认证Token
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken == null) {
        throw AiChatException('用户未登录');
      }

      // 构建请求
      final requestBody = {
        'message': message,
        'stream': true,
        'temperature': temperature,
        'maxTokens': maxTokens,
      };
      
      if (sessionId != null) {
        requestBody['sessionId'] = sessionId;
      }
      
      if (characterId != null) {
        requestBody['characterId'] = characterId;
      }

      // 发送流式请求
      final request = http.Request('POST', Uri.parse('$_baseUrl/ai-chat'));
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });
      request.body = jsonEncode(requestBody);

      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        throw AiChatException('请求失败: ${streamedResponse.statusCode}');
      }

      // 处理Server-Sent Events
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              return;
            }
            
            try {
              final jsonData = jsonDecode(data);
              final content = jsonData['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              // 忽略JSON解析错误，继续处理下一行
              continue;
            }
          }
        }
      }
    } on TimeoutException {
      throw AiChatException('请求超时，请检查网络连接');
    } catch (e) {
      if (e is AiChatException) {
        rethrow;
      }
      throw AiChatException('流式请求失败: $e');
    }
  }

  /// 获取对话历史
  /// 
  /// [sessionId] 会话ID
  /// [limit] 消息数量限制，默认50
  /// [offset] 偏移量，默认0
  /// 
  /// 返回 [List<ChatMessage>] 对话消息列表
  Future<List<ChatMessage>> getChatHistory({
    required String sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('ai_conversation_messages')
          .select('*')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw AiChatException('获取对话历史失败: $e');
    }
  }

  /// 创建新的对话会话
  /// 
  /// [title] 会话标题，可选
  /// [characterId] AI角色ID，可选
  /// 
  /// 返回 [ChatSession] 新创建的会话
  Future<ChatSession> createSession({
    String? title,
    String? characterId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AiChatException('用户未登录');
      }

      final session = ChatSession.create(
        userId: userId,
        characterId: characterId,
        title: title,
      );

      // 如果需要，可以将会话保存到数据库
      // await _supabase.from('ai_conversation_sessions').insert(session.toJson());

      return session;
    } catch (e) {
      throw AiChatException('创建会话失败: $e');
    }
  }

  /// 获取用户的对话会话列表
  /// 
  /// [limit] 会话数量限制，默认20
  /// [offset] 偏移量，默认0
  /// 
  /// 返回 [List<ChatSession>] 会话列表
  Future<List<ChatSession>> getSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AiChatException('用户未登录');
      }

      final response = await _supabase
          .from('ai_conversation_sessions')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
    } catch (e) {
      throw AiChatException('获取会话列表失败: $e');
    }
  }

  /// 删除会话
  /// 
  /// [sessionId] 要删除的会话ID
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase
          .from('ai_conversation_sessions')
          .update({'status': 'deleted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
    } catch (e) {
      throw AiChatException('删除会话失败: $e');
    }
  }

  /// 更新会话标题
  /// 
  /// [sessionId] 会话ID
  /// [title] 新标题
  Future<void> updateSessionTitle(String sessionId, String title) async {
    try {
      await _supabase
          .from('ai_conversation_sessions')
          .update({
            'title': title,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      throw AiChatException('更新会话标题失败: $e');
    }
  }

  /// 检查API配额
  Future<bool> checkApiQuota() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AiChatException('用户未登录');
      }

      // 调用RPC函数检查配额
      final response = await _supabase.rpc('check_api_quota', params: {
        'p_user_id': userId,
        'p_api_type': 'llm',
      });

      return response['allowed'] ?? false;
    } catch (e) {
      // 如果检查失败，假设有配额（避免阻塞用户）
      return true;
    }
  }
}

/// AI对话服务异常
class AiChatException implements Exception {
  /// 错误消息
  final String message;
  
  /// HTTP状态码（如果有）
  final int? statusCode;
  
  /// 原始错误（如果有）
  final dynamic originalError;

  const AiChatException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'AiChatException(${statusCode}): $message';
    }
    return 'AiChatException: $message';
  }
}