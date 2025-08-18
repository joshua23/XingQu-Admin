// =============================================
// 在应用中直接运行的埋点测试脚本
// 可以在main.dart或任何页面中导入并调用
// =============================================

import 'package:flutter/foundation.dart';
import 'lib/services/analytics_service.dart';
import 'lib/services/supabase_service.dart';

/// 执行埋点测试
Future<void> runAnalyticsTest() async {
  print('🧪 ========== 开始埋点测试 ==========');
  print('⏰ 测试时间: ${DateTime.now()}');
  
  try {
    // 获取服务实例
    final analytics = AnalyticsService.instance;
    final supabase = SupabaseService.instance;
    
    // 检查服务状态
    print('\n📊 检查服务状态...');
    print('  - Analytics服务启用: ${analytics.isEnabled}');
    print('  - Supabase连接状态: ${supabase.client != null ? "已连接" : "未连接"}');
    print('  - 当前用户ID: ${supabase.currentUserId ?? "未登录"}');
    
    // 生成测试会话ID
    final testSessionId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    print('\n🔑 测试会话ID: $testSessionId');
    
    // 测试1：页面访问埋点
    print('\n📱 测试1: 页面访问埋点...');
    await analytics.trackPageView('home_selection_page', additionalData: {
      'source': 'test_script',
      'session_id': testSessionId,
      'test_time': DateTime.now().toIso8601String(),
    });
    print('  ✅ 页面访问埋点发送成功');
    
    // 测试2：角色交互埋点
    print('\n👤 测试2: 角色交互埋点...');
    await analytics.trackCharacterInteraction(
      characterId: 'test_ji_wen_ze',
      interactionType: 'view_profile',
      additionalData: {
        'character_name': '寂文泽',
        'session_id': testSessionId,
        'test_time': DateTime.now().toIso8601String(),
      },
    );
    print('  ✅ 角色交互埋点发送成功');
    
    // 测试3：社交互动埋点（点赞）
    print('\n❤️ 测试3: 社交互动埋点...');
    await analytics.trackSocialInteraction(
      actionType: 'like',
      targetType: 'character',
      targetId: 'test_ji_wen_ze',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'session_id': testSessionId,
        'test_time': DateTime.now().toIso8601String(),
      },
    );
    print('  ✅ 社交互动（点赞）埋点发送成功');
    
    // 测试4：社交互动埋点（关注）
    print('\n➕ 测试4: 关注埋点...');
    await analytics.trackSocialInteraction(
      actionType: 'follow',
      targetType: 'character',
      targetId: 'test_ji_wen_ze',
      additionalData: {
        'character_name': '寂文泽',
        'source': 'featured_page',
        'session_id': testSessionId,
        'test_time': DateTime.now().toIso8601String(),
      },
    );
    print('  ✅ 社交互动（关注）埋点发送成功');
    
    // 测试5：批量事件
    print('\n📦 测试5: 批量埋点上报...');
    final batchEvents = [
      {
        'event_type': 'test_batch_1',
        'event_data': {'index': 1, 'session_id': testSessionId},
      },
      {
        'event_type': 'test_batch_2',
        'event_data': {'index': 2, 'session_id': testSessionId},
      },
      {
        'event_type': 'test_batch_3',
        'event_data': {'index': 3, 'session_id': testSessionId},
      },
    ];
    await analytics.trackBatchEvents(batchEvents);
    print('  ✅ 批量埋点上报成功（${batchEvents.length}个事件）');
    
    // 测试完成
    print('\n🎉 ========== 埋点测试完成 ==========');
    print('📊 测试会话ID: $testSessionId');
    print('💡 请执行以下操作验证结果：');
    print('  1. 在Supabase控制台查看user_analytics表');
    print('  2. 执行SQL查询: SELECT * FROM user_analytics WHERE session_id = \'$testSessionId\'');
    print('  3. 打开后台管理系统Mobile数据监控页面');
    print('  4. 查看实时活动流是否显示测试事件');
    
    return;
  } catch (e) {
    print('\n❌ 测试失败: $e');
    print('📝 错误详情:');
    print('  - 错误类型: ${e.runtimeType}');
    print('  - 错误信息: $e');
    print('\n💡 可能的原因:');
    print('  1. Supabase未正确初始化');
    print('  2. 用户未登录');
    print('  3. 网络连接问题');
    print('  4. 数据库表结构问题');
  }
}

/// 快速测试入口
void quickTest() {
  runAnalyticsTest().then((_) {
    print('\n✅ 测试脚本执行完毕');
  }).catchError((error) {
    print('\n❌ 测试脚本执行出错: $error');
  });
}