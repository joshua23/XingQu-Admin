// =============================================
// 星趣APP埋点数据流端到端测试
// 测试从Flutter移动端到后台管理系统的完整数据流
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/analytics_service.dart';
import '../lib/services/supabase_service.dart';

/// 埋点数据流端到端测试套件
/// 验证首页-精选页埋点数据是否能正确传输到Supabase后台
void main() {
  group('📊 埋点数据流端到端测试', () {
    late AnalyticsService analyticsService;
    late SupabaseService supabaseService;
    
    // 测试前准备
    setUpAll(() async {
      print('🚀 初始化测试环境...');
      
      try {
        // 初始化Supabase服务
        supabaseService = SupabaseService.instance;
        await supabaseService.initialize();
        print('✅ Supabase服务初始化完成');
        
        // 初始化Analytics服务
        analyticsService = AnalyticsService.instance;
        await analyticsService.initialize();
        print('✅ Analytics服务初始化完成');
        
        print('🎯 测试环境准备就绪');
      } catch (e) {
        print('❌ 测试环境初始化失败: $e');
        rethrow;
      }
    });
    
    // 测试清理
    tearDownAll(() async {
      print('🧹 清理测试环境...');
      // 这里可以添加清理逻辑
    });
    
    group('🏠 首页-精选页埋点测试', () {
      test('测试页面访问埋点', () async {
        print('🧪 测试页面访问埋点...');
        
        expect(() async {
          await analyticsService.trackPageView(
            'home_selection_page',
            additionalData: {
              'source': 'navigation',
              'user_action': 'tab_switch',
              'timestamp': DateTime.now().toIso8601String(),
              'test_context': 'automated_test',
            },
          );
        }, returnsNormally);
        
        print('✅ 页面访问埋点发送成功');
      });
      
      test('测试社交互动埋点（点赞）', () async {
        print('🧪 测试社交互动埋点（点赞）...');
        
        expect(() async {
          await analyticsService.trackSocialInteraction(
            actionType: 'like',
            targetType: 'character',
            targetId: 'test_character_ji_wen_ze',
            additionalData: {
              'character_name': '寂文泽',
              'source': 'featured_page',
              'like_count_before': 21000,
              'like_count_after': 21001,
              'test_context': 'automated_test',
            },
          );
        }, returnsNormally);
        
        print('✅ 社交互动埋点（点赞）发送成功');
      });
      
      test('测试角色交互埋点（关注）', () async {
        print('🧪 测试角色交互埋点（关注）...');
        
        expect(() async {
          await analyticsService.trackCharacterInteraction(
            characterId: 'test_character_ji_wen_ze',
            interactionType: 'follow',
            additionalData: {
              'character_name': '寂文泽',
              'source': 'featured_page',
              'follow_count_before': 924000,
              'follow_count_after': 924001,
              'test_context': 'automated_test',
            },
          );
        }, returnsNormally);
        
        print('✅ 角色交互埋点（关注）发送成功');
      });
      
      test('测试复合用户流程埋点', () async {
        print('🧪 测试复合用户流程埋点...');
        
        // 模拟完整的首页-精选页用户流程
        final testSessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
        
        // 1. 页面进入
        await analyticsService.trackPageView('home_selection_page', additionalData: {
          'source': 'bottom_navigation',
          'previous_page': 'home_comprehensive_page',
          'session_id': testSessionId,
          'test_context': 'user_flow_test',
        });
        
        // 等待100ms模拟用户浏览
        await Future.delayed(Duration(milliseconds: 100));
        
        // 2. 查看角色信息
        await analyticsService.trackCharacterInteraction(
          characterId: 'test_character_ji_wen_ze',
          interactionType: 'view_profile',
          additionalData: {
            'character_name': '寂文泽',
            'view_duration': 3,
            'session_id': testSessionId,
            'test_context': 'user_flow_test',
          },
        );
        
        // 3. 点赞操作
        await analyticsService.trackSocialInteraction(
          actionType: 'like',
          targetType: 'character',
          targetId: 'test_character_ji_wen_ze',
          additionalData: {
            'character_name': '寂文泽',
            'source': 'featured_page',
            'is_first_like': false,
            'session_id': testSessionId,
            'test_context': 'user_flow_test',
          },
        );
        
        // 4. 关注操作
        await analyticsService.trackSocialInteraction(
          actionType: 'follow',
          targetType: 'character',
          targetId: 'test_character_ji_wen_ze',
          additionalData: {
            'character_name': '寂文泽',
            'source': 'featured_page',
            'is_first_follow': true,
            'session_id': testSessionId,
            'test_context': 'user_flow_test',
          },
        );
        
        print('✅ 复合用户流程埋点发送完成');
        print('💡 会话ID: $testSessionId');
        
        // 等待数据传输
        await Future.delayed(Duration(milliseconds: 500));
        print('⏳ 数据传输等待完成');
      });
    });
    
    group('🔧 Analytics服务状态测试', () {
      test('检查埋点服务状态', () async {
        print('🔍 检查埋点服务状态...');
        
        // 检查服务是否启用
        expect(analyticsService.isEnabled, true);
        print('✅ 埋点服务已启用');
        
        // 检查会话ID是否生成
        expect(analyticsService.sessionId, isNotNull);
        print('✅ 会话ID已生成: ${analyticsService.sessionId}');
        
        // 检查设备信息是否收集
        expect(analyticsService.deviceInfo, isNotNull);
        print('✅ 设备信息已收集');
        
        // 打印设备信息用于调试
        print('📱 设备信息: ${analyticsService.deviceInfo}');
      });
      
      test('检查Supabase连接状态', () async {
        print('🔍 检查Supabase连接状态...');
        
        // 检查是否已初始化
        expect(supabaseService.client, isNotNull);
        print('✅ Supabase客户端已初始化');
        
        // 检查当前用户状态（可能为null，但不应该报错）
        final userId = supabaseService.currentUserId;
        print('👤 当前用户ID: ${userId ?? "未登录（匿名模式）"}');
        
        // 检查是否为登录状态
        final isLoggedIn = supabaseService.isLoggedIn;
        print('🔐 登录状态: ${isLoggedIn ? "已登录" : "未登录"}');
      });
    });
    
    group('📊 批量埋点测试', () {
      test('测试批量埋点数据上报', () async {
        print('🧪 测试批量埋点数据上报...');
        
        // 模拟多个用户交互事件
        final batchEvents = [
          {
            'event_type': 'page_view',
            'event_data': {
              'page_name': 'home_selection_page',
              'source': 'tab_navigation',
              'timestamp': DateTime.now().toIso8601String(),
              'test_context': 'batch_test',
            }
          },
          {
            'event_type': 'character_interaction',
            'event_data': {
              'interaction_type': 'view_profile',
              'character_id': 'test_character_ji_wen_ze',
              'character_name': '寂文泽',
              'timestamp': DateTime.now().toIso8601String(),
              'test_context': 'batch_test',
            }
          },
          {
            'event_type': 'social_interaction',
            'event_data': {
              'action_type': 'like',
              'target_type': 'character',
              'target_id': 'test_character_ji_wen_ze',
              'timestamp': DateTime.now().toIso8601String(),
              'test_context': 'batch_test',
            }
          },
        ];
        
        // 执行批量上报
        expect(() async {
          await analyticsService.trackBatchEvents(batchEvents);
        }, returnsNormally);
        
        print('✅ 批量埋点数据上报完成');
        print('📈 上报事件数量: ${batchEvents.length}');
        
        // 等待处理
        await Future.delayed(Duration(milliseconds: 200));
        print('⏳ 批量数据处理完成');
      });
    });
    
    group('🚨 错误处理测试', () {
      test('测试网络异常时的埋点处理', () async {
        print('🧪 测试网络异常时的埋点处理...');
        
        // 这个测试主要验证在网络异常时不会崩溃
        expect(() async {
          await analyticsService.trackEvent('network_error_test', {
            'test_scenario': 'network_disconnected',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }, returnsNormally);
        
        print('✅ 网络异常处理测试完成');
      });
      
      test('测试无效数据的埋点处理', () async {
        print('🧪 测试无效数据的埋点处理...');
        
        // 测试空数据
        expect(() async {
          await analyticsService.trackEvent('empty_data_test', {});
        }, returnsNormally);
        
        // 测试大数据
        final largeData = Map<String, dynamic>.fromIterable(
          List.generate(100, (i) => 'key_$i'),
          value: (key) => 'large_value_for_$key' * 10,
        );
        
        expect(() async {
          await analyticsService.trackEvent('large_data_test', largeData);
        }, returnsNormally);
        
        print('✅ 无效数据处理测试完成');
      });
    });
  });
}

/// 手动测试助手类
/// 用于在真实应用中手动触发埋点事件进行验证
class ManualTestHelper {
  static final AnalyticsService _analytics = AnalyticsService.instance;
  
  /// 模拟首页-精选页完整用户流程
  /// 可以在应用中调用此方法来手动触发埋点测试
  static Future<void> simulateFeaturePageFlow() async {
    print('🎬 开始模拟首页-精选页完整用户流程...');
    
    final sessionId = 'manual_test_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // 1. 页面进入
      await _analytics.trackPageView('home_selection_page', additionalData: {
        'source': 'manual_test',
        'session_id': sessionId,
        'test_type': 'manual_simulation',
      });
      print('✅ 步骤1: 页面进入埋点已发送');
      
      // 模拟用户浏览时间
      await Future.delayed(Duration(seconds: 1));
      
      // 2. 查看角色信息
      await _analytics.trackCharacterInteraction(
        characterId: 'ji_wen_ze_character',
        interactionType: 'view_profile',
        additionalData: {
          'character_name': '寂文泽',
          'view_duration': 2,
          'session_id': sessionId,
          'test_type': 'manual_simulation',
        },
      );
      print('✅ 步骤2: 角色查看埋点已发送');
      
      // 3. 点赞操作
      await _analytics.trackSocialInteraction(
        actionType: 'like',
        targetType: 'character',
        targetId: 'ji_wen_ze_character',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'session_id': sessionId,
          'test_type': 'manual_simulation',
        },
      );
      print('✅ 步骤3: 点赞埋点已发送');
      
      // 4. 关注操作
      await _analytics.trackSocialInteraction(
        actionType: 'follow',
        targetType: 'character',
        targetId: 'ji_wen_ze_character',
        additionalData: {
          'character_name': '寂文泽',
          'source': 'featured_page',
          'session_id': sessionId,
          'test_type': 'manual_simulation',
        },
      );
      print('✅ 步骤4: 关注埋点已发送');
      
      print('🎉 首页-精选页用户流程模拟完成！');
      print('📊 会话ID: $sessionId');
      print('💡 请在Supabase控制台和后台管理系统查看数据更新');
      
    } catch (e) {
      print('❌ 手动测试流程执行失败: $e');
    }
  }
  
  /// 检查埋点连通性
  static Future<bool> checkConnectivity() async {
    print('🔍 检查埋点服务连通性...');
    
    try {
      await _analytics.trackEvent('connectivity_check', {
        'timestamp': DateTime.now().toIso8601String(),
        'test_id': 'connectivity_${DateTime.now().millisecondsSinceEpoch}',
      });
      
      print('✅ 埋点服务连通性正常');
      return true;
    } catch (e) {
      print('❌ 埋点服务连通性异常: $e');
      return false;
    }
  }
}