// =============================================
// 埋点数据流实际应用测试助手
// 可以在真实应用中调用进行埋点功能验证
// =============================================

import '../services/analytics_service.dart';
import 'package:flutter/foundation.dart';

/// 埋点测试助手类
/// 用于在实际应用运行时验证埋点功能
class AnalyticsTestHelper {
  static final AnalyticsService _analytics = AnalyticsService.instance;
  
  /// 执行完整的首页-精选页埋点测试
  static Future<bool> runFeaturePageTest() async {
    if (kDebugMode) {
      print('🧪 开始执行首页-精选页埋点测试...');
    }
    
    final testSessionId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    bool allTestsPassed = true;
    
    try {
      // 1. 测试页面访问埋点
      await _testPageView(testSessionId);
      
      // 2. 测试角色交互埋点  
      await _testCharacterInteraction(testSessionId);
      
      // 3. 测试社交互动埋点
      await _testSocialInteractions(testSessionId);
      
      // 4. 测试批量埋点
      await _testBatchEvents(testSessionId);
      
      // 5. 测试服务状态
      _testServiceStatus();
      
      if (kDebugMode) {
        print('✅ 所有埋点测试完成！');
        print('📊 测试会话ID: $testSessionId');
        print('💡 请在Supabase控制台和后台管理系统查看数据');
      }
      
    } catch (e) {
      allTestsPassed = false;
      if (kDebugMode) {
        print('❌ 埋点测试失败: $e');
      }
    }
    
    return allTestsPassed;
  }
  
  /// 测试页面访问埋点
  static Future<void> _testPageView(String sessionId) async {
    if (kDebugMode) {
      print('🔍 测试页面访问埋点...');
    }
    
    await _analytics.trackPageView('home_selection_page', additionalData: {
      'source': 'analytics_test',
      'test_type': 'automated',
      'session_id': sessionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (kDebugMode) {
      print('✅ 页面访问埋点测试完成');
    }
  }
  
  /// 测试角色交互埋点
  static Future<void> _testCharacterInteraction(String sessionId) async {
    if (kDebugMode) {
      print('🔍 测试角色交互埋点...');
    }
    
    // 测试查看角色
    await _analytics.trackCharacterInteraction(
      characterId: 'test_ji_wen_ze',
      interactionType: 'view_profile',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'analytics_test',
        'session_id': sessionId,
        'view_duration': 3,
        'test_type': 'automated',
      },
    );
    
    // 测试开始聊天
    await _analytics.trackCharacterInteraction(
      characterId: 'test_ji_wen_ze',
      interactionType: 'start_chat',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'session_id': sessionId,
        'test_type': 'automated',
      },
    );
    
    if (kDebugMode) {
      print('✅ 角色交互埋点测试完成');
    }
  }
  
  /// 测试社交互动埋点
  static Future<void> _testSocialInteractions(String sessionId) async {
    if (kDebugMode) {
      print('🔍 测试社交互动埋点...');
    }
    
    // 测试点赞
    await _analytics.trackSocialInteraction(
      actionType: 'like',
      targetType: 'character',
      targetId: 'test_ji_wen_ze',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'session_id': sessionId,
        'like_count_before': 21000,
        'like_count_after': 21001,
        'test_type': 'automated',
      },
    );
    
    // 测试关注
    await _analytics.trackSocialInteraction(
      actionType: 'follow',
      targetType: 'character', 
      targetId: 'test_ji_wen_ze',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'session_id': sessionId,
        'follow_count_before': 924000,
        'follow_count_after': 924001,
        'is_first_follow': true,
        'test_type': 'automated',
      },
    );
    
    // 测试分享
    await _analytics.trackSocialInteraction(
      actionType: 'share',
      targetType: 'character',
      targetId: 'test_ji_wen_ze',
      additionalData: {
        'character_name': '寂文泽',
        'share_platform': 'wechat',
        'session_id': sessionId,
        'test_type': 'automated',
      },
    );
    
    if (kDebugMode) {
      print('✅ 社交互动埋点测试完成');
    }
  }
  
  /// 测试批量埋点上报
  static Future<void> _testBatchEvents(String sessionId) async {
    if (kDebugMode) {
      print('🔍 测试批量埋点上报...');
    }
    
    final batchEvents = [
      {
        'event_type': 'page_view',
        'event_data': {
          'page_name': 'home_selection_page',
          'source': 'batch_test',
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        }
      },
      {
        'event_type': 'character_interaction',
        'event_data': {
          'interaction_type': 'view_profile',
          'character_id': 'test_ji_wen_ze',
          'character_name': '寂文泽',
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        }
      },
      {
        'event_type': 'social_interaction',
        'event_data': {
          'action_type': 'like',
          'target_type': 'character',
          'target_id': 'test_ji_wen_ze',
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        }
      },
    ];
    
    await _analytics.trackBatchEvents(batchEvents);
    
    if (kDebugMode) {
      print('✅ 批量埋点测试完成 (${batchEvents.length} 个事件)');
    }
  }
  
  /// 测试服务状态
  static void _testServiceStatus() {
    if (kDebugMode) {
      print('🔍 检查埋点服务状态...');
      print('  - 服务启用状态: ${_analytics.isEnabled}');
      print('  - 会话ID: ${_analytics.sessionId}');
      print('  - 设备信息: ${_analytics.deviceInfo != null ? "已收集" : "未收集"}');
      print('✅ 服务状态检查完成');
    }
  }
  
  /// 模拟真实的用户流程
  static Future<void> simulateRealUserFlow() async {
    if (kDebugMode) {
      print('🎬 开始模拟真实用户流程...');
    }
    
    final sessionId = 'real_flow_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // 1. 用户进入首页-精选页
      await _analytics.trackPageView('home_selection_page', additionalData: {
        'source': 'bottom_navigation',
        'previous_page': 'home_comprehensive_page',
        'session_id': sessionId,
        'flow_type': 'real_simulation',
      });
      
      // 模拟用户浏览时间 (1秒)
      await Future.delayed(Duration(seconds: 1));
      
      // 2. 用户查看寂文泽角色信息
      await _analytics.trackCharacterInteraction(
        characterId: 'ji_wen_ze_official',
        interactionType: 'view_profile',
        additionalData: {
          'character_name': '寂文泽',
          'view_duration': 3,
          'session_id': sessionId,
          'flow_type': 'real_simulation',
        },
      );
      
      // 3. 用户点赞
      await _analytics.trackSocialInteraction(
        actionType: 'like',
        targetType: 'character',
        targetId: 'ji_wen_ze_official',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'session_id': sessionId,
          'flow_type': 'real_simulation',
        },
      );
      
      // 短暂延迟模拟用户思考
      await Future.delayed(Duration(milliseconds: 500));
      
      // 4. 用户关注角色
      await _analytics.trackSocialInteraction(
        actionType: 'follow',
        targetType: 'character',
        targetId: 'ji_wen_ze_official',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'session_id': sessionId,
          'flow_type': 'real_simulation',
        },
      );
      
      // 5. 用户进入聊天
      await _analytics.trackCharacterInteraction(
        characterId: 'ji_wen_ze_official',
        interactionType: 'start_chat',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'chat_type': 'new_session',
          'session_id': sessionId,
          'flow_type': 'real_simulation',
        },
      );
      
      if (kDebugMode) {
        print('✅ 真实用户流程模拟完成！');
        print('📊 模拟会话ID: $sessionId');
        print('💡 请在后台管理系统查看实时数据更新');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 用户流程模拟失败: $e');
      }
    }
  }
  
  /// 检查埋点连通性
  static Future<bool> checkConnectivity() async {
    if (kDebugMode) {
      print('🔍 检查埋点服务连通性...');
    }
    
    try {
      await _analytics.trackEvent('connectivity_check', {
        'timestamp': DateTime.now().toIso8601String(),
        'check_id': 'conn_${DateTime.now().millisecondsSinceEpoch}',
        'test_type': 'connectivity',
      });
      
      if (kDebugMode) {
        print('✅ 埋点服务连通性正常');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 埋点服务连通性异常: $e');
      }
      return false;
    }
  }
  
  /// 生成测试报告
  static Map<String, dynamic> generateTestReport() {
    return {
      'test_timestamp': DateTime.now().toIso8601String(),
      'service_enabled': _analytics.isEnabled,
      'session_id': _analytics.sessionId,
      'device_info_collected': _analytics.deviceInfo != null,
      'test_status': 'completed',
      'recommendation': [
        '1. 在Supabase控制台查看 user_analytics 表的数据',
        '2. 在后台管理系统查看 Mobile数据监控 页面',
        '3. 确认实时活动流显示测试事件',
        '4. 检查统计数字是否有更新',
      ],
      'next_steps': [
        '重启Flutter应用并进行真实交互',
        '观察后台系统的实时数据更新',
        '如有问题请检查网络连接和用户登录状态',
      ],
    };
  }
}

/// 在应用启动时调用的便捷方法
class QuickAnalyticsTest {
  /// 快速验证埋点功能（适用于开发调试）
  static Future<void> quickTest() async {
    if (!kDebugMode) return; // 只在调试模式下运行
    
    print('🚀 开始快速埋点测试...');
    
    final success = await AnalyticsTestHelper.checkConnectivity();
    
    if (success) {
      await AnalyticsTestHelper.runFeaturePageTest();
      
      final report = AnalyticsTestHelper.generateTestReport();
      print('📋 测试报告: ${report.toString()}');
    } else {
      print('❌ 埋点连通性检查失败，请检查网络和配置');
    }
  }
  
  /// 在实际使用中触发的简化测试
  static Future<void> liveTest() async {
    if (!kDebugMode) return;
    
    print('🎯 执行实际使用埋点测试...');
    await AnalyticsTestHelper.simulateRealUserFlow();
  }
}