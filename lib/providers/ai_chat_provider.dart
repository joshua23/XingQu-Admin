import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';

/// AI对话状态管理Provider
/// 管理对话会话、消息历史和实时状态
class AiChatProvider extends ChangeNotifier {
  final AiChatService _aiChatService = AiChatService.instance;
  
  /// 当前会话
  ChatSession? _currentSession;
  ChatSession? get currentSession => _currentSession;
  
  /// 当前会话的消息列表
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  /// 会话列表
  List<ChatSession> _sessions = [];
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  
  /// 是否正在发送消息
  bool _isSending = false;
  bool get isSending => _isSending;
  
  /// 是否正在接收流式响应
  bool _isReceivingStream = false;
  bool get isReceivingStream => _isReceivingStream;
  
  /// 当前正在接收的流式消息
  ChatMessage? _currentStreamMessage;
  ChatMessage? get currentStreamMessage => _currentStreamMessage;
  
  /// 流式响应订阅
  StreamSubscription<String>? _streamSubscription;
  
  /// 错误信息
  String? _error;
  String? get error => _error;
  
  /// 是否有API配额
  bool _hasApiQuota = true;
  bool get hasApiQuota => _hasApiQuota;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// 创建新会话
  Future<void> createNewSession({
    String? characterId,
    String? title,
  }) async {
    try {
      _error = null;
      notifyListeners();
      
      final session = await _aiChatService.createSession(
        characterId: characterId,
        title: title ?? '新的对话',
      );
      
      _currentSession = session;
      _messages = [];
      
      // 添加到会话列表
      _sessions.insert(0, session);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 切换到指定会话
  Future<void> switchToSession(ChatSession session) async {
    try {
      _error = null;
      notifyListeners();
      
      _currentSession = session;
      
      // 加载会话的消息历史
      await _loadMessages(session.id);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 发送消息（非流式）
  Future<void> sendMessage({
    required String content,
    String? characterId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (_isSending || content.trim().isEmpty) return;

    try {
      _isSending = true;
      _error = null;
      notifyListeners();

      // 检查API配额
      _hasApiQuota = await _aiChatService.checkApiQuota();
      if (!_hasApiQuota) {
        throw Exception('API配额不足，请升级会员或等待配额重置');
      }

      // 确保有当前会话
      if (_currentSession == null) {
        await createNewSession(characterId: characterId);
      }

      // 添加用户消息
      final userMessage = ChatMessage.user(
        content: content,
        sessionId: _currentSession!.id,
        characterId: characterId,
      );
      _messages.add(userMessage);
      notifyListeners();

      // 发送到AI服务
      final response = await _aiChatService.sendMessage(
        message: content,
        sessionId: _currentSession!.id,
        characterId: characterId,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      // 添加AI回复消息
      final aiMessage = ChatMessage.assistant(
        content: response.content,
        sessionId: response.sessionId,
        characterId: characterId,
        tokensUsed: response.tokensUsed,
        cost: response.cost,
      );
      _messages.add(aiMessage);

      // 更新会话信息
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          messageCount: _messages.length,
          totalCost: _currentSession!.totalCost + response.cost,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      // 添加错误消息
      final errorMessage = ChatMessage.error(
        error: e.toString(),
        sessionId: _currentSession?.id ?? '',
        characterId: characterId,
      );
      _messages.add(errorMessage);
      _error = e.toString();
      notifyListeners();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// 发送消息（流式响应）
  Future<void> sendMessageStream({
    required String content,
    String? characterId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (_isSending || _isReceivingStream || content.trim().isEmpty) return;

    try {
      _isSending = true;
      _isReceivingStream = false;
      _error = null;
      notifyListeners();

      // 检查API配额
      _hasApiQuota = await _aiChatService.checkApiQuota();
      if (!_hasApiQuota) {
        throw Exception('API配额不足，请升级会员或等待配额重置');
      }

      // 确保有当前会话
      if (_currentSession == null) {
        await createNewSession(characterId: characterId);
      }

      // 添加用户消息
      final userMessage = ChatMessage.user(
        content: content,
        sessionId: _currentSession!.id,
        characterId: characterId,
      );
      _messages.add(userMessage);
      _isSending = false;
      _isReceivingStream = true;
      notifyListeners();

      // 创建流式AI消息占位符
      _currentStreamMessage = ChatMessage.assistant(
        content: '',
        sessionId: _currentSession!.id,
        characterId: characterId,
        isStreaming: true,
      );
      _messages.add(_currentStreamMessage!);
      notifyListeners();

      // 开始流式接收
      final stream = _aiChatService.sendMessageStream(
        message: content,
        sessionId: _currentSession!.id,
        characterId: characterId,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      _streamSubscription = stream.listen(
        (chunk) {
          // 更新流式消息内容
          if (_currentStreamMessage != null) {
            final updatedContent = _currentStreamMessage!.content + chunk;
            _currentStreamMessage = _currentStreamMessage!.copyWith(
              content: updatedContent,
            );
            
            // 更新消息列表中的对应消息
            final index = _messages.indexWhere((msg) => msg.id == _currentStreamMessage!.id);
            if (index != -1) {
              _messages[index] = _currentStreamMessage!;
            }
            
            notifyListeners();
          }
        },
        onDone: () {
          // 流式响应完成
          if (_currentStreamMessage != null) {
            _currentStreamMessage = _currentStreamMessage!.copyWith(
              isStreaming: false,
              status: MessageStatus.sent,
            );
            
            final index = _messages.indexWhere((msg) => msg.id == _currentStreamMessage!.id);
            if (index != -1) {
              _messages[index] = _currentStreamMessage!;
            }
          }
          
          _isReceivingStream = false;
          _currentStreamMessage = null;
          _streamSubscription = null;
          notifyListeners();
        },
        onError: (error) {
          // 流式响应错误
          if (_currentStreamMessage != null) {
            _currentStreamMessage = _currentStreamMessage!.copyWith(
              content: _currentStreamMessage!.content.isEmpty 
                  ? '接收失败: $error' 
                  : _currentStreamMessage!.content,
              isStreaming: false,
              status: MessageStatus.failed,
              error: error.toString(),
            );
            
            final index = _messages.indexWhere((msg) => msg.id == _currentStreamMessage!.id);
            if (index != -1) {
              _messages[index] = _currentStreamMessage!;
            }
          }
          
          _error = error.toString();
          _isReceivingStream = false;
          _currentStreamMessage = null;
          _streamSubscription = null;
          notifyListeners();
        },
      );

    } catch (e) {
      // 添加错误消息
      final errorMessage = ChatMessage.error(
        error: e.toString(),
        sessionId: _currentSession?.id ?? '',
        characterId: characterId,
      );
      _messages.add(errorMessage);
      _error = e.toString();
      _isSending = false;
      _isReceivingStream = false;
      _currentStreamMessage = null;
      notifyListeners();
    }
  }

  /// 停止流式响应
  void stopStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isReceivingStream = false;
    
    if (_currentStreamMessage != null) {
      _currentStreamMessage = _currentStreamMessage!.copyWith(
        isStreaming: false,
        status: MessageStatus.sent,
      );
      
      final index = _messages.indexWhere((msg) => msg.id == _currentStreamMessage!.id);
      if (index != -1) {
        _messages[index] = _currentStreamMessage!;
      }
      
      _currentStreamMessage = null;
    }
    
    notifyListeners();
  }

  /// 重试发送消息
  Future<void> retryMessage(ChatMessage message) async {
    if (message.type != MessageType.user) return;
    
    // 移除失败的消息和后续消息
    final index = _messages.indexOf(message);
    if (index != -1) {
      _messages.removeRange(index, _messages.length);
      notifyListeners();
    }
    
    // 重新发送
    await sendMessage(
      content: message.content,
      characterId: message.characterId,
    );
  }

  /// 删除消息
  void deleteMessage(ChatMessage message) {
    _messages.remove(message);
    notifyListeners();
  }

  /// 清空当前会话消息
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// 加载会话列表
  Future<void> loadSessions() async {
    try {
      _error = null;
      notifyListeners();
      
      _sessions = await _aiChatService.getSessions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 删除会话
  Future<void> deleteSession(ChatSession session) async {
    try {
      await _aiChatService.deleteSession(session.id);
      _sessions.remove(session);
      
      // 如果删除的是当前会话，清空状态
      if (_currentSession?.id == session.id) {
        _currentSession = null;
        _messages.clear();
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新会话标题
  Future<void> updateSessionTitle(ChatSession session, String title) async {
    try {
      await _aiChatService.updateSessionTitle(session.id, title);
      
      final index = _sessions.indexOf(session);
      if (index != -1) {
        _sessions[index] = session.copyWith(title: title);
      }
      
      if (_currentSession?.id == session.id) {
        _currentSession = _currentSession!.copyWith(title: title);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 加载指定会话的消息
  Future<void> _loadMessages(String sessionId) async {
    try {
      _messages = await _aiChatService.getChatHistory(sessionId: sessionId);
    } catch (e) {
      _error = e.toString();
      _messages = [];
    }
  }

  /// 清除错误状态
  void clearError() {
    _error = null;
    notifyListeners();
  }
}