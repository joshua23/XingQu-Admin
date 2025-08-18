// =============================================
// 端到端埋点数据流测试脚本
// 测试从Flutter移动端到后台管理系统的完整数据流
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/analytics_service.dart';
import '../lib/services/supabase_service.dart';

/// 埋点数据流端到端测试
/// 验证首页-精选页埋点数据是否能正确传输到后台系统
void main() {
  group('埋点数据流端到端测试', () {
    late AnalyticsService analyticsService;
    late SupabaseService supabaseService;
    
    setUpAll(() async {
      // 初始化服务
      supabaseService = SupabaseService.instance;
      await supabaseService.initialize();
      
      analyticsService = AnalyticsService.instance;
      await analyticsService.initialize();
      
      print('🚀 测试环境初始化完成');
    });
    
    testWidgets('测试首页-精选页埋点数据完整流程', (WidgetTester tester) async {
      print('🧪 开始测试首页-精选页埋点数据流...');
      
      // 1. 测试页面访问埋点
      await analyticsService.trackPageView(
        'home_selection_page',
        additionalData: {
          'source': 'navigation',
          'user_action': 'tab_switch',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ 页面访问埋点发送成功');
      
      // 2. 测试社交互动埋点（点赞）
      await analyticsService.trackSocialInteraction(
        actionType: 'like',
        targetType: 'character',
        targetId: 'test_character_id',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'like_count_before': 21000,
          'like_count_after': 21001,
        },
      );
      print('✅ 社交互动埋点（点赞）发送成功');
      
      // 3. 测试角色交互埋点（关注）
      await analyticsService.trackCharacterInteraction(
        characterId: 'test_character_id',
        interactionType: 'follow',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'follow_count_before': 924000,
          'follow_count_after': 924001,
        },
      );
      print('✅ 角色交互埋点（关注）发送成功');
      
      // 4. 等待数据传输
      await Future.delayed(Duration(seconds: 2));
      print('⏳ 等待数据传输到Supabase...');
      
      // 5. 验证数据是否成功存储（需要有效的用户ID）
      final userId = supabaseService.currentUserId;
      if (userId != null) {
        // 这里可以添加数据库查询验证
        // 但在单元测试中不建议直接查询生产数据库
        print('✅ 用户ID已获取: $userId');
        print('💡 数据存储验证请在Supabase控制台手动检查');
      } else {
        print('⚠️  当前用户未登录，无法验证数据存储');
      }
      
      print('🎉 埋点数据流测试完成');
    });
    
    test('测试批量埋点数据上报', () async {
      print('🧪 开始测试批量埋点数据上报...');
      
      // 模拟多个用户交互事件
      final batchEvents = [
        {
          'event_type': 'page_view',
          'page_name': 'home_selection_page',
          'event_data': {
            'source': 'tab_navigation',
            'timestamp': DateTime.now().toIso8601String(),
          }
        },
        {
          'event_type': 'character_interaction',
          'event_data': {
            'interaction_type': 'view_profile',
            'character_id': 'test_character_id',
            'character_name': '寂文泽',
            'timestamp': DateTime.now().toIso8601String(),
          }
        },
        {
          'event_type': 'social_interaction',
          'event_data': {
            'action_type': 'like',
            'target_type': 'character',
            'target_id': 'test_character_id',
            'timestamp': DateTime.now().toIso8601String(),
          }
        },
      ];
      
      // 执行批量上报
      await analyticsService.trackBatchEvents(batchEvents);
      print('✅ 批量埋点数据上报完成');
      
      // 等待处理
      await Future.delayed(Duration(seconds: 1));
      print('⏳ 批量数据处理完成');
    });
    
    test('测试埋点服务状态', () async {
      print('🔍 检查埋点服务状态...');
      
      // 检查服务是否启用
      expect(analyticsService.isEnabled, true);
      print('✅ 埋点服务已启用');
      
      // 检查会话ID是否生成
      expect(analyticsService.sessionId, isNotNull);
      print('✅ 会话ID已生成: ${analyticsService.sessionId}');
      
      // 检查设备信息是否收集
      expect(analyticsService.deviceInfo, isNotNull);
      print('✅ 设备信息已收集: ${analyticsService.deviceInfo}');
      
      print('🎯 埋点服务状态检查完成');
    });
  });
}

/// 手动测试助手类
/// 用于在真实应用中触发埋点事件
class AnalyticsTestHelper {
  static final AnalyticsService _analytics = AnalyticsService.instance;
  
  /// 模拟首页-精选页完整用户流程
  static Future<void> simulateFeaturePage() async {
    print('🎬 开始模拟首页-精选页用户流程...');
    
    // 1. 页面进入
    await _analytics.trackPageView('home_selection_page', additionalData: {
      'source': 'bottom_navigation',
      'previous_page': 'home_comprehensive_page',
    });
    
    // 等待1秒模拟用户浏览
    await Future.delayed(Duration(seconds: 1));
    
    // 2. 查看角色信息
    await _analytics.trackCharacterInteraction(
      characterId: 'ji_wen_ze_character_id',
      interactionType: 'view_profile',
      additionalData: {
        'character_name': '寂文泽',
        'view_duration': 3,
      },
    );
    
    // 3. 点赞操作
    await _analytics.trackSocialInteraction(
      actionType: 'like',
      targetType: 'character',
      targetId: 'ji_wen_ze_character_id',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'is_first_like': false,
      },
    );
    
    // 4. 关注操作
    await _analytics.trackSocialInteraction(
      actionType: 'follow',
      targetType: 'character', 
      targetId: 'ji_wen_ze_character_id',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'is_first_follow': true,
      },
    );
    
    // 5. 进入聊天
    await _analytics.trackCharacterInteraction(
      characterId: 'ji_wen_ze_character_id',
      interactionType: 'start_chat',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'chat_type': 'new_session',
      },
    );
    
    print('✅ 首页-精选页用户流程模拟完成');
    print('💡 请在后台管理系统查看实时数据是否更新');
  }
  
  /// 检查埋点数据是否成功发送的辅助方法
  static Future<bool> checkDataSubmission() async {
    try {
      // 发送一个测试事件
      await _analytics.trackEvent('connectivity_test', {
        'test_timestamp': DateTime.now().toIso8601String(),
        'test_id': 'connectivity_test_${DateTime.now().millisecondsSinceEpoch}',
      });
      
      // 如果没有抛出异常，说明发送成功
      return true;
    } catch (e) {
      print('❌ 埋点数据发送失败: $e');
      return false;
    }
  }
}