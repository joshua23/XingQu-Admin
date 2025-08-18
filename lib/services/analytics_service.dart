import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'supabase_service.dart';

/// 用户行为分析服务（增强版）
/// 负责收集和上报用户行为数据到后台管理系统
/// 特性：数据验证、降级机制、重试逻辑、错误恢复
class AnalyticsService {
  static AnalyticsService? _instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  String? _sessionId;
  Map<String, dynamic>? _deviceInfo;
  bool _isEnabled = true;
  
  // 增强功能配置
  bool _enableFallback = true; // 降级机制开关
  int _maxRetryAttempts = 3; // 最大重试次数
  int _retryDelayMs = 1000; // 重试延迟（毫秒）
  List<Map<String, dynamic>> _offlineQueue = []; // 离线队列
  bool _isProcessingQueue = false; // 队列处理状态
  
  AnalyticsService._internal();
  
  /// 获取单例实例
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._internal();
    return _instance!;
  }
  
  /// 初始化分析服务
  Future<void> initialize() async {
    try {
      // 生成会话ID
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 获取设备信息
      await _collectDeviceInfo();
      
      // 上报应用启动事件
      await trackEvent('app_launch', {
        'session_id': _sessionId,
        'device_info': _deviceInfo,
        'app_version': await _getAppVersion(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      print('Analytics service initialized with session: $_sessionId');
    } catch (e) {
      print('Failed to initialize analytics: $e');
    }
  }
  
  /// 收集设备信息
  Future<void> _collectDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'ios',
          'device_model': iosInfo.model,
          'os_version': iosInfo.systemVersion,
          'device_name': iosInfo.name,
          'is_simulator': !iosInfo.isPhysicalDevice,
          'identifier': iosInfo.identifierForVendor,
        };
      } else if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'android',
          'device_model': androidInfo.model,
          'os_version': androidInfo.version.release,
          'device_name': '${androidInfo.manufacturer} ${androidInfo.model}',
          'is_simulator': !androidInfo.isPhysicalDevice,
          'identifier': androidInfo.id,
        };
      } else {
        _deviceInfo = {
          'platform': 'unknown',
          'device_model': 'unknown',
          'os_version': 'unknown',
          'is_simulator': false,
        };
      }
    } catch (e) {
      print('Failed to collect device info: $e');
      _deviceInfo = {
        'platform': Platform.operatingSystem,
        'error': 'Failed to collect device info',
      };
    }
  }
  
  /// 获取应用版本
  Future<String> _getAppVersion() async {
    // 这里可以从pubspec.yaml或其他配置获取版本号
    return '1.0.0'; // 临时版本号
  }
  
  /// 跟踪用户事件（增强版）
  /// 包含数据验证、重试机制和降级处理
  Future<void> trackEvent(String eventType, Map<String, dynamic>? eventData) async {
    if (!_isEnabled) return;
    
    // 验证基础数据
    final validatedData = _validateAndEnrichEventData(eventType, eventData);
    if (validatedData == null) {
      if (kDebugMode) {
        print('⚠️ 埋点数据验证失败，已跳过: $eventType');
      }
      return;
    }
    
    // 尝试上报埋点，带有重试机制
    await _trackEventWithRetry(eventType, validatedData);
  }
  
  /// 验证和丰富事件数据
  Map<String, dynamic>? _validateAndEnrichEventData(String eventType, Map<String, dynamic>? eventData) {
    try {
      // 基础数据验证
      if (eventType.trim().isEmpty) {
        print('❌ 埋点验证失败: event_type 为空');
        return null;
      }
      
      final userId = _supabaseService.currentUserId;
      if (userId == null || userId.trim().isEmpty) {
        if (kDebugMode) {
          print('⚠️ 埋点警告: 用户ID为空，尝试匿名登录');
        }
        // 在后台尝试匿名登录，但不阻塞当前操作
        _attemptAnonymousLogin();
        return null; // 返回 null 以跳过本次埋点
      }
      
      // 构建并验证完整数据
      final Map<String, dynamic> enrichedData = {
        'user_id': userId,
        'event_type': eventType.trim(),
        'event_data': eventData ?? {},
        'session_id': _sessionId ?? 'unknown_session',
        'device_info': _deviceInfo ?? {'platform': 'unknown'},
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        // 添加数据完整性标记
        'data_version': '1.1',
        'sdk_version': 'flutter_enhanced',
      };
      
      // 特殊处理：确保 page_name 和action_type 不为空
      if (eventType == 'page_view') {
        final data = enrichedData['event_data'] as Map<String, dynamic>;
        if (data['page_name'] == null || data['page_name'].toString().trim().isEmpty) {
          data['page_name'] = 'unknown_page'; // 设置默认值
          if (kDebugMode) {
            print('⚠️ 埋点修复: page_name 为空，已设置为 unknown_page');
          }
        }
      }
      
      if (eventType == 'social_interaction' || eventType == 'character_interaction') {
        final data = enrichedData['event_data'] as Map<String, dynamic>;
        if (data['action_type'] == null || data['action_type'].toString().trim().isEmpty) {
          data['action_type'] = 'unknown_action'; // 设置默认值
          if (kDebugMode) {
            print('⚠️ 埋点修复: action_type 为空，已设置为 unknown_action');
          }
        }
      }
      
      return enrichedData;
      
    } catch (e) {
      print('❌ 埋点数据验证异常: $e');
      return null;
    }
  }
  
  /// 尝试匿名登录（在后台进行）
  Future<void> _attemptAnonymousLogin() async {
    try {
      if (!_supabaseService.isLoggedIn) {
        await _supabaseService.client.auth.signInAnonymously();
        if (kDebugMode) {
          print('✅ 埋点服务: 匿名登录成功');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ 埋点服务: 匿名登录失败 (ignored): $e');
      }
    }
  }
  
  /// 带重试机制的事件跟踪
  Future<void> _trackEventWithRetry(String eventType, Map<String, dynamic> eventData) async {
    int attempts = 0;
    
    while (attempts < _maxRetryAttempts) {
      try {
        attempts++;
        
        final userId = eventData['user_id'] as String;
        
        // 尝试上报到 Supabase
        await _supabaseService.recordUserAnalytics(
          userId: userId,
          eventType: eventType,
          eventData: eventData,
          sessionId: eventData['session_id'] as String?,
        );
        
        // 成功日志
        if (kDebugMode) {
          print('✅ 埋点上报成功: $eventType (尝试 $attempts/$_maxRetryAttempts)');
          print('   数据: ${jsonEncode(eventData['event_data'])}');
        }
        
        // 成功则退出循环
        return;
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ 埋点上报失败 (尝试 $attempts/$_maxRetryAttempts): $e');
        }
        
        // 最后一次尝试失败，执行降级逻辑
        if (attempts >= _maxRetryAttempts) {
          await _handleAnalyticsFallback(eventType, eventData, e);
          return;
        }
        
        // 重试前的延迟
        await Future.delayed(Duration(milliseconds: _retryDelayMs * attempts));
      }
    }
  }
  
  /// 埋点失败降级处理
  Future<void> _handleAnalyticsFallback(String eventType, Map<String, dynamic> eventData, dynamic error) async {
    if (!_enableFallback) {
      if (kDebugMode) {
        print('⚠️ 埋点降级已禁用，跳过处理');
      }
      return;
    }
    
    try {
      // 1. 添加到离线队列
      _offlineQueue.add({
        ...eventData,
        'retry_count': _maxRetryAttempts,
        'last_error': error.toString(),
        'queued_at': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('📦 埋点已加入离线队列: $eventType (队列长度: ${_offlineQueue.length})');
      }
      
      // 2. 限制队列大小（防止内存溢出）
      if (_offlineQueue.length > 50) {
        _offlineQueue.removeAt(0); // 移除最早的记录
        if (kDebugMode) {
          print('⚠️ 离线队列超限，已移除最早记录');
        }
      }
      
      // 3. 尝试处理队列（异步，不阻塞当前操作）
      _processOfflineQueueAsync();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 埋点降级处理失败: $e');
      }
    }
  }
  
  /// 异步处理离线队列
  Future<void> _processOfflineQueueAsync() async {
    if (_isProcessingQueue || _offlineQueue.isEmpty) {
      return;
    }
    
    _isProcessingQueue = true;
    
    try {
      // 等待一段时间再尝试（给网络恢复时间）
      await Future.delayed(Duration(seconds: 5));
      
      final List<Map<String, dynamic>> queueCopy = List.from(_offlineQueue);
      
      for (int i = 0; i < queueCopy.length && i < 5; i++) { // 每次最多处理5条
        final item = queueCopy[i];
        try {
          await _supabaseService.recordUserAnalytics(
            userId: item['user_id'],
            eventType: item['event_type'],
            eventData: item,
            sessionId: item['session_id'],
          );
          
          // 成功则从队列中移除
          _offlineQueue.removeWhere((e) => e['queued_at'] == item['queued_at']);
          
          if (kDebugMode) {
            print('✅ 离线埋点重试成功: ${item['event_type']}');
          }
          
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ 离线埋点重试失败: ${item['event_type']}: $e');
          }
        }
      }
      
    } finally {
      _isProcessingQueue = false;
    }
  }
  
  /// 跟踪页面访问（增强版）
  Future<void> trackPageView(String pageName, {Map<String, dynamic>? additionalData}) async {
    // 数据验证
    if (pageName.trim().isEmpty) {
      if (kDebugMode) {
        print('⚠️ 页面访问埋点: pageName 为空，已跳过');
      }
      return;
    }
    
    await trackEvent('page_view', {
      'page_name': pageName.trim(),
      'page_title': additionalData?['page_title'] ?? pageName,
      'timestamp': DateTime.now().toIso8601String(),
      'visit_duration': 0, // 初始值，可后续更新
      ...?additionalData,
    });
  }
  
  /// 跟踪用户登录
  Future<void> trackLogin(String method, {bool isNewUser = false}) async {
    await trackEvent('user_login', {
      'method': method,
      'is_new_user': isNewUser,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// 跟踪用户注销
  Future<void> trackLogout() async {
    await trackEvent('user_logout', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// 跟踪AI角色交互（增强版）
  Future<void> trackCharacterInteraction({
    required String characterId,
    required String interactionType,
    String? pageName,
    Map<String, dynamic>? additionalData,
  }) async {
    // 数据验证
    if (characterId.trim().isEmpty || interactionType.trim().isEmpty) {
      if (kDebugMode) {
        print('⚠️ AI角色交互埋点: 必要参数为空，已跳过');
      }
      return;
    }
    
    final data = {
      'character_id': characterId.trim(),
      'interaction_type': interactionType.trim(),
      'action_type': interactionType.trim(), // 兼容字段
      'page_name': pageName?.trim() ?? 'unknown_page',
      'timestamp': DateTime.now().toIso8601String(),
      'interaction_id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...?additionalData,
    };
    
    await trackEvent('character_interaction', data);
  }
  
  /// 跟踪音频播放
  Future<void> trackAudioPlay({
    required String audioId,
    required int duration,
    required int playPosition,
    bool completed = false,
  }) async {
    await trackEvent('audio_play', {
      'audio_id': audioId,
      'duration': duration,
      'play_position': playPosition,
      'completed': completed,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// 跟踪内容创建
  Future<void> trackContentCreation({
    required String contentType,
    required String contentId,
    Map<String, dynamic>? contentMetadata,
  }) async {
    await trackEvent('content_create', {
      'content_type': contentType,
      'content_id': contentId,
      'metadata': contentMetadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪搜索行为
  Future<void> trackSearch({
    required String query,
    required String searchType,
    int? resultCount,
    List<String>? resultIds,
  }) async {
    await trackEvent('search', {
      'query': query,
      'search_type': searchType,
      'result_count': resultCount,
      'result_ids': resultIds,
      'query_length': query.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪购买行为
  Future<void> trackPurchase({
    required String productId,
    required String productType,
    required double amount,
    required String currency,
    String? paymentMethod,
  }) async {
    await trackEvent('purchase', {
      'product_id': productId,
      'product_type': productType,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪会员订阅
  Future<void> trackSubscription({
    required String planId,
    required String planType,
    required String action, // 'subscribe', 'upgrade', 'downgrade', 'cancel'
    double? amount,
  }) async {
    await trackEvent('subscription_$action', {
      'plan_id': planId,
      'plan_type': planType,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪AI对话
  Future<void> trackAiChat({
    required String sessionId,
    required String characterId,
    required int messageCount,
    required int tokensUsed,
    double? cost,
    int? duration,
  }) async {
    await trackEvent('ai_chat', {
      'session_id': sessionId,
      'character_id': characterId,
      'message_count': messageCount,
      'tokens_used': tokensUsed,
      'cost': cost,
      'duration_seconds': duration,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪用户偏好变化
  Future<void> trackPreferenceUpdate({
    required String preferenceType,
    required String oldValue,
    required String newValue,
  }) async {
    await trackEvent('preference_update', {
      'preference_type': preferenceType,
      'old_value': oldValue,
      'new_value': newValue,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪错误事件
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent('error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪性能指标
  Future<void> trackPerformance({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic>? tags,
  }) async {
    await trackEvent('performance', {
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'tags': tags,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 跟踪用户留存关键行为
  Future<void> trackRetentionEvent({
    required String eventName,
    int? daysSinceInstall,
    int? daysSinceLastUse,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('retention_event', {
      'event_name': eventName,
      'days_since_install': daysSinceInstall,
      'days_since_last_use': daysSinceLastUse,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 批量上报事件（用于离线缓存后上报）
  Future<void> trackBatchEvents(List<Map<String, dynamic>> events) async {
    if (!_isEnabled) return;

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) return;

      // 为每个事件添加基础信息
      final enrichedEvents = events.map((event) => {
        ...event,
        'user_id': userId,
        'session_id': _sessionId,
        'device_info': _deviceInfo,
        'batch_timestamp': DateTime.now().toIso8601String(),
      }).toList();

      // 使用现有的单个记录方法进行批量处理
      for (final event in enrichedEvents) {
        await _supabaseService.recordUserAnalytics(
          userId: userId,
          eventType: event['event_type'],
          eventData: event,
          sessionId: _sessionId,
        );
      }

      if (kDebugMode) {
        print('📊 Batch Analytics: ${events.length} events uploaded');
      }
    } catch (e) {
      print('Failed to track batch events: $e');
    }
  }

  /// 启用/禁用分析
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 获取分析启用状态
  bool get isEnabled => _isEnabled;

  /// 获取当前会话ID
  String? get sessionId => _sessionId;

  /// 获取设备信息
  Map<String, dynamic>? get deviceInfo => _deviceInfo;
  
  /// 跟踪社交互动（增强版）
  Future<void> trackSocialInteraction({
    required String actionType, // like, comment, follow, share
    required String targetType, // character, audio, creation
    required String targetId,
    String? pageName,
    Map<String, dynamic>? additionalData,
  }) async {
    // 数据验证
    if (actionType.trim().isEmpty || targetType.trim().isEmpty || targetId.trim().isEmpty) {
      if (kDebugMode) {
        print('⚠️ 社交互动埋点: 必要参数为空，已跳过');
      }
      return;
    }
    
    final data = {
      'action_type': actionType.trim(),
      'target_type': targetType.trim(),
      'target_id': targetId.trim(),
      'page_name': pageName?.trim() ?? 'unknown_page',
      'timestamp': DateTime.now().toIso8601String(),
      'interaction_id': DateTime.now().millisecondsSinceEpoch.toString(), // 用于去重
      ...?additionalData,
    };
    
    await trackEvent('social_interaction', data);
  }
  
  /// 跟踪用户偏好设置
  Future<void> trackPreferenceChange({
    required String setting,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    await trackEvent('preference_change', {
      'setting': setting,
      'old_value': oldValue,
      'new_value': newValue,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// 发送实时心跳（用于在线状态监控）
  Future<void> sendHeartbeat() async {
    await trackEvent('heartbeat', {
      'timestamp': DateTime.now().toIso8601String(),
      'session_duration': _getSessionDuration(),
    });
  }
  
  /// 获取会话持续时间
  int _getSessionDuration() {
    if (_sessionId == null) return 0;
    final startTime = int.parse(_sessionId!);
    return DateTime.now().millisecondsSinceEpoch - startTime;
  }
  
  
  /// 清理资源
  Future<void> dispose() async {
    // 发送会话结束事件
    await trackEvent('session_end', {
      'session_duration': _getSessionDuration(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _sessionId = null;
    _deviceInfo = null;
  }
  
  /// 批量上报事件（用于离线数据同步）
  Future<void> batchTrackEvents(List<Map<String, dynamic>> events) async {
    if (!_isEnabled || events.isEmpty) return;
    
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) return;
      
      // 为每个事件添加用户信息
      final List<Map<String, dynamic>> enrichedEvents = events.map((event) => {
        ...event,
        'user_id': userId,
        'session_id': _sessionId,
        'device_info': _deviceInfo,
        'uploaded_at': DateTime.now().toIso8601String(),
      }).toList();
      
      // 批量插入到数据库
      for (final event in enrichedEvents) {
        await _supabaseService.recordUserAnalytics(
          userId: userId,
          eventType: event['event_type'],
          eventData: event,
          sessionId: _sessionId,
        );
      }
      
      print('📊 Batch uploaded ${events.length} analytics events');
    } catch (e) {
      print('Failed to batch upload events: $e');
    }
  }
  
  // ============================================================================
  // 增强功能：调试和测试工具
  // ============================================================================
  
  /// 获取离线队列状态
  Map<String, dynamic> getOfflineQueueStatus() {
    return {
      'queue_length': _offlineQueue.length,
      'is_processing': _isProcessingQueue,
      'enabled_fallback': _enableFallback,
      'max_retry_attempts': _maxRetryAttempts,
      'retry_delay_ms': _retryDelayMs,
    };
  }
  
  /// 手动触发离线队列处理
  Future<void> forceProcessOfflineQueue() async {
    if (kDebugMode) {
      print('🔧 手动触发离线队列处理...');
    }
    await _processOfflineQueueAsync();
  }
  
  /// 清空离线队列
  void clearOfflineQueue() {
    if (kDebugMode) {
      print('🗑️ 清空离线队列 (${_offlineQueue.length} 条记录)');
    }
    _offlineQueue.clear();
  }
  
  /// 设置降级机制开关
  void setFallbackEnabled(bool enabled) {
    _enableFallback = enabled;
    if (kDebugMode) {
      print('⚙️ 埋点降级机制: ${enabled ? '已启用' : '已禁用'}');
    }
  }
  
  /// 设置重试参数
  void setRetryConfig({int? maxAttempts, int? delayMs}) {
    if (maxAttempts != null && maxAttempts > 0) {
      _maxRetryAttempts = maxAttempts;
    }
    if (delayMs != null && delayMs > 0) {
      _retryDelayMs = delayMs;
    }
    if (kDebugMode) {
      print('⚙️ 埋点重试配置: 最大尝试 $_maxRetryAttempts 次，延迟 $_retryDelayMs ms');
    }
  }
  
  /// 测试埋点连通性
  Future<bool> testAnalyticsConnection() async {
    try {
      if (kDebugMode) {
        print('🔍 测试埋点连通性...');
      }
      
      final testData = {
        'test_type': 'connectivity_check',
        'timestamp': DateTime.now().toIso8601String(),
        'test_id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      await trackEvent('analytics_test', testData);
      
      if (kDebugMode) {
        print('✅ 埋点连通性测试成功');
      }
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 埋点连通性测试失败: $e');
      }
      return false;
    }
  }
  
  /// 获取分析服务状态报告
  Map<String, dynamic> getServiceStatus() {
    return {
      'service_enabled': _isEnabled,
      'user_logged_in': _supabaseService.isLoggedIn,
      'current_user_id': _supabaseService.currentUserId,
      'session_id': _sessionId,
      'device_info_loaded': _deviceInfo != null,
      'fallback_enabled': _enableFallback,
      'offline_queue': getOfflineQueueStatus(),
      'service_version': '1.1.0-enhanced',
    };
  }
}

/// 分析事件包装器
/// 用于简化事件跟踪调用
class Analytics {
  static final AnalyticsService _service = AnalyticsService.instance;
  
  // 页面访问
  static Future<void> page(String pageName, [Map<String, dynamic>? data]) async {
    return _service.trackPageView(pageName, additionalData: data);
  }
  
  // 用户行为
  static Future<void> event(String eventType, [Map<String, dynamic>? data]) async {
    return _service.trackEvent(eventType, data);
  }
  
  // AI角色交互
  static Future<void> character(String characterId, String action, [Map<String, dynamic>? data]) async {
    return _service.trackCharacterInteraction(
      characterId: characterId,
      interactionType: action,
      additionalData: data,
    );
  }
  
  // 音频播放
  static Future<void> audio(String audioId, int duration, int position, [bool completed = false]) async {
    return _service.trackAudioPlay(
      audioId: audioId,
      duration: duration,
      playPosition: position,
      completed: completed,
    );
  }
  
  // 社交互动
  static Future<void> social(String action, String targetType, String targetId, [Map<String, dynamic>? data]) async {
    return _service.trackSocialInteraction(
      actionType: action,
      targetType: targetType,
      targetId: targetId,
      additionalData: data,
    );
  }
  
  // 错误跟踪
  static Future<void> error(String type, String message, [String? stackTrace, Map<String, dynamic>? context]) async {
    return _service.trackError(
      errorType: type,
      errorMessage: message,
      stackTrace: stackTrace,
      context: context,
    );
  }
}