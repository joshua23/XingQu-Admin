// 检查埋点数据的Dart脚本
// 可以在Flutter应用中直接运行

import 'package:supabase_flutter/supabase_flutter.dart';

/// 检查并显示埋点数据的辅助函数
class AnalyticsDataChecker {
  static final SupabaseClient _client = Supabase.instance.client;
  
  /// 检查用户分析数据
  static Future<void> checkAnalyticsData() async {
    print('🔍 开始检查埋点数据...');
    
    try {
      // 1. 检查最近的用户分析记录
      final recentAnalytics = await _client
          .from('user_analytics')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);
      
      print('\n📊 最近10条埋点记录:');
      for (final record in recentAnalytics) {
        print('- ${record['event_type']} at ${record['created_at']}');
        if (record['page_name'] != null) {
          print('  页面: ${record['page_name']}');
        }
        if (record['event_data'] != null) {
          print('  数据: ${record['event_data']}');
        }
        print('  用户ID: ${record['user_id']}');
        print('  会话ID: ${record['session_id']}');
        print('---');
      }
      
      // 2. 检查用户数据表状态
      final userCount = await _client
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact));
      
      print('\n👥 用户数据表状态:');
      print('- 用户总数: ${userCount.count}');
      
      // 3. 检查点赞数据
      final likesCount = await _client
          .from('likes')
          .select('id', const FetchOptions(count: CountOption.exact));
      
      print('\n❤️ 点赞数据状态:');
      print('- 点赞总数: ${likesCount.count}');
      
      // 4. 检查关注数据
      final followsCount = await _client
          .from('character_follows')
          .select('id', const FetchOptions(count: CountOption.exact));
      
      print('\n👥 关注数据状态:');
      print('- 关注总数: ${followsCount.count}');
      
      // 5. 检查评论数据
      final commentsCount = await _client
          .from('comments')
          .select('id', const FetchOptions(count: CountOption.exact));
      
      print('\n💬 评论数据状态:');
      print('- 评论总数: ${commentsCount.count}');
      
      // 6. 按事件类型统计埋点数据
      final eventTypeStats = await _client
          .from('user_analytics')
          .select('event_type')
          .order('created_at', ascending: false)
          .limit(100);
      
      final eventCounts = <String, int>{};
      for (final record in eventTypeStats) {
        final eventType = record['event_type'] as String;
        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
      }
      
      print('\n📈 埋点事件类型统计（最近100条）:');
      eventCounts.entries.forEach((entry) {
        print('- ${entry.key}: ${entry.value}次');
      });
      
      // 7. 检查页面访问统计
      final pageViews = await _client
          .from('user_analytics')
          .select('page_name')
          .eq('event_type', 'page_view')
          .order('created_at', ascending: false)
          .limit(50);
      
      final pageCounts = <String, int>{};
      for (final record in pageViews) {
        final pageName = record['page_name'] as String? ?? '未知页面';
        pageCounts[pageName] = (pageCounts[pageName] ?? 0) + 1;
      }
      
      print('\n📱 页面访问统计（最近50次）:');
      pageCounts.entries.forEach((entry) {
        print('- ${entry.key}: ${entry.value}次');
      });
      
      print('\n✅ 埋点数据检查完成！');
      
    } catch (e) {
      print('❌ 检查埋点数据失败: $e');
      
      // 如果是表不存在的错误，提供建议
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        print('💡 可能的原因：数据库表不存在或权限不足');
        print('建议：检查数据库架构和RLS策略');
      } else if (e.toString().contains('foreign key constraint')) {
        print('💡 可能的原因：外键约束错误');
        print('建议：执行用户数据表修复脚本');
      }
    }
  }
  
  /// 执行数据库修复
  static Future<void> executeDbFix() async {
    print('🔧 开始执行数据库修复...');
    
    try {
      // 执行用户存在性检查函数
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId != null) {
        print('当前用户ID: $currentUserId');
        
        // 尝试手动插入用户记录
        try {
          await _client.from('users').insert({
            'id': currentUserId,
            'phone': '',
            'nickname': '测试用户',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ 成功创建用户记录');
        } catch (insertError) {
          if (insertError.toString().contains('duplicate key')) {
            print('✅ 用户记录已存在');
          } else {
            print('❌ 创建用户记录失败: $insertError');
          }
        }
        
        // 测试插入一条测试埋点
        try {
          await _client.from('user_analytics').insert({
            'user_id': currentUserId,
            'event_type': 'test_event',
            'page_name': 'test_page',
            'session_id': 'test_session_${DateTime.now().millisecondsSinceEpoch}',
            'event_data': {'test': true, 'timestamp': DateTime.now().toIso8601String()},
          });
          print('✅ 测试埋点插入成功');
        } catch (testError) {
          print('❌ 测试埋点插入失败: $testError');
        }
      }
      
    } catch (e) {
      print('❌ 数据库修复失败: $e');
    }
  }
}

/// 主执行函数
void main() async {
  // 初始化Supabase
  await Supabase.initialize(
    url: 'https://wqdpqhfqrxvssxifpmvt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w',
  );
  
  // 执行数据库修复
  await AnalyticsDataChecker.executeDbFix();
  
  // 检查埋点数据
  await AnalyticsDataChecker.checkAnalyticsData();
}