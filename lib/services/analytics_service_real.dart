import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// 真实数据分析服务
/// 直接对接xq_表的真实数据，进行可视化处理
class RealAnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  // xq_前缀表名常量
  static const String trackingEventsTable = 'xq_tracking_events';
  static const String userProfilesTable = 'xq_user_profiles'; 
  static const String userSessionsTable = 'xq_user_sessions';

  /// 获取所有表的基础统计数据
  Future<Map<String, dynamic>> getBasicStats() async {
    try {
      debugPrint('📊 开始获取基础统计数据...');
      
      // 并行查询三个表的数据量
      final results = await Future.wait([
        _client.from(trackingEventsTable).select('*', const FetchOptions(count: CountOption.exact)).limit(0),
        _client.from(userProfilesTable).select('*', const FetchOptions(count: CountOption.exact)).limit(0),
        _client.from(userSessionsTable).select('*', const FetchOptions(count: CountOption.exact)).limit(0),
      ]);

      final eventsCount = results[0].count ?? 0;
      final profilesCount = results[1].count ?? 0;
      final sessionsCount = results[2].count ?? 0;

      debugPrint('✅ 统计数据获取成功: 事件$eventsCount, 用户$profilesCount, 会话$sessionsCount');

      return {
        'totalEvents': eventsCount,
        'totalUsers': profilesCount,
        'totalSessions': sessionsCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ 获取基础统计失败: $e');
      rethrow;
    }
  }

  /// 获取xq_tracking_events表的详细数据
  Future<Map<String, dynamic>> getTrackingEventsData() async {
    try {
      debugPrint('📈 获取用户行为事件数据...');
      
      final response = await _client
          .from(trackingEventsTable)
          .select('*')
          .order('timestamp', ascending: false)
          .limit(100);

      final events = response as List;
      debugPrint('✅ 获取到 ${events.length} 条事件数据');

      // 分析事件类型分布
      final eventTypeStats = <String, int>{};
      final platformStats = <String, int>{};
      final hourlyStats = List<int>.filled(24, 0);
      final dailyStats = <String, int>{};

      for (final event in events) {
        // 事件类型统计
        final eventType = event['event_type'] as String? ?? 'unknown';
        eventTypeStats[eventType] = (eventTypeStats[eventType] ?? 0) + 1;

        // 平台统计
        final eventData = event['event_data'] as Map<String, dynamic>? ?? {};
        final deviceInfo = eventData['device_info'] as Map<String, dynamic>? ?? {};
        final platform = deviceInfo['platform'] as String? ?? 'unknown';
        platformStats[platform] = (platformStats[platform] ?? 0) + 1;

        // 小时分布统计
        final timestamp = DateTime.parse(event['timestamp'] as String);
        hourlyStats[timestamp.hour] += 1;

        // 日期分布统计
        final dateKey = timestamp.toIso8601String().substring(0, 10);
        dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + 1;
      }

      return {
        'rawData': events.take(20).toList(), // 最新20条原始数据
        'eventTypeStats': eventTypeStats,
        'platformStats': platformStats,
        'hourlyDistribution': hourlyStats,
        'dailyStats': dailyStats,
        'totalEvents': events.length,
      };
    } catch (e) {
      debugPrint('❌ 获取事件数据失败: $e');
      rethrow;
    }
  }

  /// 获取xq_user_profiles表的详细数据
  Future<Map<String, dynamic>> getUserProfilesData() async {
    try {
      debugPrint('👥 获取用户资料数据...');
      
      final response = await _client
          .from(userProfilesTable)
          .select('*');

      final profiles = response as List;
      debugPrint('✅ 获取到 ${profiles.length} 条用户资料');

      // 分析用户数据
      final genderStats = <String, int>{'male': 0, 'female': 0, 'other': 0};
      final statusStats = <String, int>{};
      final memberStats = {'members': 0, 'regular': 0};

      for (final profile in profiles) {
        // 性别统计
        final gender = profile['gender'] as String? ?? 'other';
        genderStats[gender] = (genderStats[gender] ?? 0) + 1;

        // 账户状态统计
        final status = profile['account_status'] as String? ?? 'unknown';
        statusStats[status] = (statusStats[status] ?? 0) + 1;

        // 会员统计
        final isMember = profile['is_member'] as bool? ?? false;
        if (isMember) {
          memberStats['members'] = memberStats['members']! + 1;
        } else {
          memberStats['regular'] = memberStats['regular']! + 1;
        }
      }

      return {
        'rawData': profiles,
        'genderDistribution': genderStats,
        'statusDistribution': statusStats,
        'membershipDistribution': memberStats,
        'totalUsers': profiles.length,
      };
    } catch (e) {
      debugPrint('❌ 获取用户资料失败: $e');
      rethrow;
    }
  }

  /// 获取xq_user_sessions表的详细数据
  Future<Map<String, dynamic>> getUserSessionsData() async {
    try {
      debugPrint('⏱️ 获取用户会话数据...');
      
      final response = await _client
          .from(userSessionsTable)
          .select('*')
          .order('start_time', ascending: false)
          .limit(50);

      final sessions = response as List;
      debugPrint('✅ 获取到 ${sessions.length} 条会话数据');

      // 分析会话数据
      final platformStats = <String, int>{};
      final activeSessionsCount = sessions.where((s) => s['is_active'] == true).length;
      final hourlyDistribution = List<int>.filled(24, 0);
      final durationStats = <String, int>{'short': 0, 'medium': 0, 'long': 0};

      double totalDuration = 0;
      int validDurationCount = 0;

      for (final session in sessions) {
        // 平台统计
        final platform = session['platform'] as String? ?? 'unknown';
        platformStats[platform] = (platformStats[platform] ?? 0) + 1;

        // 小时分布统计
        final startTime = DateTime.parse(session['start_time'] as String);
        hourlyDistribution[startTime.hour] += 1;

        // 会话时长统计
        final duration = session['duration_seconds'] as int? ?? 0;
        if (duration > 0) {
          totalDuration += duration;
          validDurationCount++;

          if (duration < 60) {
            durationStats['short'] = durationStats['short']! + 1;
          } else if (duration < 300) {
            durationStats['medium'] = durationStats['medium']! + 1;
          } else {
            durationStats['long'] = durationStats['long']! + 1;
          }
        }
      }

      final averageDuration = validDurationCount > 0 ? totalDuration / validDurationCount : 0.0;

      return {
        'rawData': sessions.take(20).toList(), // 最新20条会话数据
        'platformDistribution': platformStats,
        'hourlyDistribution': hourlyDistribution,
        'durationStats': durationStats,
        'totalSessions': sessions.length,
        'activeSessions': activeSessionsCount,
        'averageDuration': averageDuration,
      };
    } catch (e) {
      debugPrint('❌ 获取会话数据失败: $e');
      rethrow;
    }
  }

  /// 获取所有数据的综合报告
  Future<Map<String, dynamic>> getCompleteAnalyticsReport() async {
    try {
      debugPrint('📊 生成完整数据分析报告...');
      
      final results = await Future.wait([
        getBasicStats(),
        getTrackingEventsData(),
        getUserProfilesData(),
        getUserSessionsData(),
      ]);

      debugPrint('✅ 完整报告生成成功');

      return {
        'basicStats': results[0],
        'eventsData': results[1],
        'usersData': results[2],
        'sessionsData': results[3],
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ 生成分析报告失败: $e');
      rethrow;
    }
  }

  /// 测试数据库连接
  Future<bool> testConnection() async {
    try {
      debugPrint('🔗 测试数据库连接...');
      
      // 测试三个表的基本查询
      await Future.wait([
        _client.from(trackingEventsTable).select('id').limit(1),
        _client.from(userProfilesTable).select('id').limit(1),
        _client.from(userSessionsTable).select('id').limit(1),
      ]);

      debugPrint('✅ 数据库连接测试成功');
      return true;
    } catch (e) {
      debugPrint('❌ 数据库连接测试失败: $e');
      return false;
    }
  }
}