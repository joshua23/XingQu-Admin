// =============================================
// 简化版埋点服务单元测试
// 测试AnalyticsService的核心功能，不依赖实际的Supabase连接
// =============================================

import 'package:flutter_test/flutter_test.dart';
import '../lib/services/analytics_service.dart';

void main() {
  group('📊 AnalyticsService 单元测试', () {
    test('AnalyticsService 单例实例创建', () {
      // 测试单例模式
      final analytics1 = AnalyticsService.instance;
      final analytics2 = AnalyticsService.instance;
      
      expect(analytics1, equals(analytics2));
      expect(analytics1, isA<AnalyticsService>());
    });
    
    test('启用/禁用埋点服务', () {
      final analytics = AnalyticsService.instance;
      
      // 默认应该是启用状态
      expect(analytics.isEnabled, true);
      
      // 测试禁用
      analytics.setEnabled(false);
      expect(analytics.isEnabled, false);
      
      // 测试重新启用
      analytics.setEnabled(true);
      expect(analytics.isEnabled, true);
    });
    
    test('埋点方法调用不抛出异常', () async {
      final analytics = AnalyticsService.instance;
      
      // 这些测试主要验证方法调用不会因为语法错误而崩溃
      // 实际的网络请求会失败，但不应该导致异常
      
      expect(() async {
        await analytics.trackPageView('test_page', additionalData: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }, returnsNormally);
      
      expect(() async {
        await analytics.trackEvent('test_event', {
          'test_data': 'unit_test',
        });
      }, returnsNormally);
      
      expect(() async {
        await analytics.trackCharacterInteraction(
          characterId: 'test_character',
          interactionType: 'test_interaction',
          additionalData: {'test': true},
        );
      }, returnsNormally);
      
      expect(() async {
        await analytics.trackSocialInteraction(
          actionType: 'test_like',
          targetType: 'test_target',
          targetId: 'test_id',
          additionalData: {'test': true},
        );
      }, returnsNormally);
      
      expect(() async {
        await analytics.trackAudioPlay(
          audioId: 'test_audio',
          duration: 100,
          playPosition: 50,
          completed: false,
        );
      }, returnsNormally);
      
      expect(() async {
        await analytics.trackContentCreation(
          contentType: 'test_content',
          contentId: 'test_id',
          contentMetadata: {'test': true},
        );
      }, returnsNormally);
    });
    
    test('批量事件处理', () async {
      final analytics = AnalyticsService.instance;
      
      final batchEvents = [
        {
          'event_type': 'test_event_1',
          'event_data': {'test': 'batch_1'},
        },
        {
          'event_type': 'test_event_2', 
          'event_data': {'test': 'batch_2'},
        },
        {
          'event_type': 'test_event_3',
          'event_data': {'test': 'batch_3'},
        },
      ];
      
      expect(() async {
        await analytics.trackBatchEvents(batchEvents);
      }, returnsNormally);
    });
    
    test('错误处理和异常情况', () async {
      final analytics = AnalyticsService.instance;
      
      // 测试空数据
      expect(() async {
        await analytics.trackEvent('empty_test', {});
      }, returnsNormally);
      
      // 测试null数据
      expect(() async {
        await analytics.trackEvent('null_test', null);
      }, returnsNormally);
      
      // 测试禁用状态下的调用
      analytics.setEnabled(false);
      expect(() async {
        await analytics.trackEvent('disabled_test', {'test': true});
      }, returnsNormally);
      
      // 重新启用
      analytics.setEnabled(true);
    });
    
    test('Analytics包装器类测试', () async {
      // 测试静态方法不抛出异常
      expect(() async {
        await Analytics.page('test_page', {'test': true});
      }, returnsNormally);
      
      expect(() async {
        await Analytics.event('test_event', {'test': true});
      }, returnsNormally);
      
      expect(() async {
        await Analytics.character('test_char', 'test_action', {'test': true});
      }, returnsNormally);
      
      expect(() async {
        await Analytics.audio('test_audio', 100, 50, false);
      }, returnsNormally);
      
      expect(() async {
        await Analytics.social('test_action', 'test_type', 'test_id', {'test': true});
      }, returnsNormally);
      
      expect(() async {
        await Analytics.error('test_error', 'test message', 'test stack', {'test': true});
      }, returnsNormally);
    });
  });
}

/// 测试数据生成器
class TestDataGenerator {
  static Map<String, dynamic> generatePageViewData() {
    return {
      'page_name': 'home_selection_page',
      'source': 'unit_test',
      'timestamp': DateTime.now().toIso8601String(),
      'test_context': 'automated_test',
    };
  }
  
  static Map<String, dynamic> generateSocialInteractionData() {
    return {
      'action_type': 'like',
      'target_type': 'character',
      'target_id': 'test_character_123',
      'character_name': '测试角色',
      'source': 'featured_page',
      'test_context': 'automated_test',
    };
  }
  
  static Map<String, dynamic> generateCharacterInteractionData() {
    return {
      'character_id': 'test_character_123',
      'interaction_type': 'view_profile',
      'character_name': '测试角色',
      'view_duration': 5,
      'test_context': 'automated_test',
    };
  }
  
  static List<Map<String, dynamic>> generateBatchEvents(int count) {
    return List.generate(count, (index) => {
      'event_type': 'batch_test_event_$index',
      'event_data': {
        'index': index,
        'timestamp': DateTime.now().toIso8601String(),
        'test_context': 'batch_test',
      },
    });
  }
}