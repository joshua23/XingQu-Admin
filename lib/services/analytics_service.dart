import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_models.dart';

/// 数据分析服务
/// 负责与xq_前缀表进行数据交互，为后台仪表板提供数据
class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  // xq_前缀表名常量
  static const String trackingEventsTable = 'xq_tracking_events';
  static const String userProfilesTable = 'xq_user_profiles'; 
  static const String userSessionsTable = 'xq_user_sessions';

  /// 获取总览数据
  Future<OverviewData> getOverviewData() async {
    try {
      // 并行查询所有统计数据
      final results = await Future.wait([
        _getTotalUsers(),
        _getTotalSessions(),
        _getTotalEvents(),
        _getActiveUsersToday(),
        _getNewUsersToday(),
        _getAverageSessionDuration(),
      ]);

      return OverviewData(
        totalUsers: results[0] as int,
        totalSessions: results[1] as int,
        totalEvents: results[2] as int,
        activeUsersToday: results[3] as int,
        newUsersToday: results[4] as int,
        averageSessionDuration: results[5] as double,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('获取总览数据失败: $e');
    }
  }

  /// 获取用户分析数据
  Future<UserAnalyticsData> getUserAnalytics() async {
    try {
      final profilesResponse = await _client
          .from(userProfilesTable)
          .select('*');

      final userProfiles = (profilesResponse as List)
          .map((json) => UserProfileData.fromJson(json))
          .toList();

      // 计算用户统计
      final totalUsers = userProfiles.length;
      final activeUsers = userProfiles.where((u) => u.accountStatus == 'active').length;
      final memberUsers = userProfiles.where((u) => u.isMember).length;
      final maleUsers = userProfiles.where((u) => u.gender == 'male').length;
      final femaleUsers = userProfiles.where((u) => u.gender == 'female').length;

      return UserAnalyticsData(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        memberUsers: memberUsers,
        genderDistribution: {
          'male': maleUsers,
          'female': femaleUsers,
          'other': totalUsers - maleUsers - femaleUsers,
        },
        userProfiles: userProfiles,
      );
    } catch (e) {
      throw Exception('获取用户分析数据失败: $e');
    }
  }

  /// 获取行为分析数据
  Future<BehaviorAnalyticsData> getBehaviorAnalytics() async {
    try {
      final eventsResponse = await _client
          .from(trackingEventsTable)
          .select('*')
          .order('timestamp', ascending: false)
          .limit(1000);

      final events = (eventsResponse as List)
          .map((json) => TrackingEventData.fromJson(json))
          .toList();

      // 统计各种事件类型
      final eventTypeStats = <String, int>{};
      final platformStats = <String, int>{};
      final dailyEventCounts = <String, int>{};

      for (final event in events) {
        // 事件类型统计
        eventTypeStats[event.eventType] = 
            (eventTypeStats[event.eventType] ?? 0) + 1;
        
        // 平台统计
        final platform = event.eventData['device_info']?['platform'] as String? ?? 'unknown';
        platformStats[platform] = (platformStats[platform] ?? 0) + 1;
        
        // 每日事件统计
        final dateKey = event.timestamp.toIso8601String().substring(0, 10);
        dailyEventCounts[dateKey] = (dailyEventCounts[dateKey] ?? 0) + 1;
      }

      return BehaviorAnalyticsData(
        totalEvents: events.length,
        eventTypeStats: eventTypeStats,
        platformStats: platformStats,
        dailyEventCounts: dailyEventCounts,
        recentEvents: events.take(50).toList(),
      );
    } catch (e) {
      throw Exception('获取行为分析数据失败: $e');
    }
  }

  /// 获取会话分析数据
  Future<SessionAnalyticsData> getSessionAnalytics() async {
    try {
      final sessionsResponse = await _client
          .from(userSessionsTable)
          .select('*')
          .order('start_time', ascending: false);

      final sessions = (sessionsResponse as List)
          .map((json) => UserSessionData.fromJson(json))
          .toList();

      // 计算会话统计
      final totalSessions = sessions.length;
      final activeSessions = sessions.where((s) => s.isActive).length;
      final avgDuration = sessions
          .where((s) => s.durationSeconds > 0)
          .map((s) => s.durationSeconds)
          .fold<double>(0, (sum, duration) => sum + duration) / 
          sessions.where((s) => s.durationSeconds > 0).length;

      final platformDistribution = <String, int>{};
      final hourlyDistribution = <int, int>{};

      for (final session in sessions) {
        // 平台分布
        platformDistribution[session.platform] = 
            (platformDistribution[session.platform] ?? 0) + 1;
        
        // 每小时分布
        final hour = session.startTime.hour;
        hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
      }

      return SessionAnalyticsData(
        totalSessions: totalSessions,
        activeSessions: activeSessions,
        averageDuration: avgDuration,
        platformDistribution: platformDistribution,
        hourlyDistribution: hourlyDistribution,
        recentSessions: sessions.take(20).toList(),
      );
    } catch (e) {
      throw Exception('获取会话分析数据失败: $e');
    }
  }

  /// 获取实时指标
  Future<RealTimeMetrics> getRealTimeMetrics() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      // 获取最近1小时的数据
      final recentEvents = await _client
          .from(trackingEventsTable)
          .select('*')
          .gte('timestamp', oneHourAgo.toIso8601String())
          .order('timestamp', ascending: false);

      final recentSessions = await _client
          .from(userSessionsTable)
          .select('*')
          .gte('start_time', oneHourAgo.toIso8601String())
          .eq('is_active', true);

      return RealTimeMetrics(
        currentActiveUsers: (recentSessions as List).length,
        eventsPerHour: (recentEvents as List).length,
        lastUpdateTime: now,
        systemStatus: 'healthy',
      );
    } catch (e) {
      throw Exception('获取实时指标失败: $e');
    }
  }

  /// 获取追踪事件列表
  Future<List<TrackingEventData>> getTrackingEvents({int limit = 100}) async {
    try {
      final response = await _client
          .from(trackingEventsTable)
          .select('*')
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TrackingEventData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('获取追踪事件失败: $e');
    }
  }

  /// 获取用户会话列表
  Future<List<UserSessionData>> getUserSessions({int limit = 50}) async {
    try {
      final response = await _client
          .from(userSessionsTable)
          .select('*')
          .order('start_time', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => UserSessionData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('获取用户会话失败: $e');
    }
  }

  /// 获取指定日期范围的追踪事件
  Future<List<TrackingEventData>> getTrackingEventsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from(trackingEventsTable)
          .select('*')
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => TrackingEventData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('获取日期范围事件失败: $e');
    }
  }

  /// 获取指定日期范围的用户会话
  Future<List<UserSessionData>> getUserSessionsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from(userSessionsTable)
          .select('*')
          .gte('start_time', startDate.toIso8601String())
          .lte('start_time', endDate.toIso8601String())
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => UserSessionData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('获取日期范围会话失败: $e');
    }
  }

  /// 根据事件类型获取事件
  Future<List<TrackingEventData>> getEventsByType(String eventType) async {
    try {
      final response = await _client
          .from(trackingEventsTable)
          .select('*')
          .eq('event_type', eventType)
          .order('timestamp', ascending: false)
          .limit(200);

      return (response as List)
          .map((json) => TrackingEventData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('获取特定类型事件失败: $e');
    }
  }

  // 私有辅助方法
  Future<int> _getTotalUsers() async {
    final response = await _client
        .from(userProfilesTable)
        .select('id', const FetchOptions(count: CountOption.exact));
    return response.count ?? 0;
  }

  Future<int> _getTotalSessions() async {
    final response = await _client
        .from(userSessionsTable)
        .select('id', const FetchOptions(count: CountOption.exact));
    return response.count ?? 0;
  }

  Future<int> _getTotalEvents() async {
    final response = await _client
        .from(trackingEventsTable)
        .select('id', const FetchOptions(count: CountOption.exact));
    return response.count ?? 0;
  }

  Future<int> _getActiveUsersToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final response = await _client
        .from(userSessionsTable)
        .select('user_id', const FetchOptions(count: CountOption.exact))
        .gte('start_time', startOfDay.toIso8601String())
        .eq('is_active', true);
    
    return response.count ?? 0;
  }

  Future<int> _getNewUsersToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final response = await _client
        .from(userProfilesTable)
        .select('id', const FetchOptions(count: CountOption.exact))
        .gte('created_at', startOfDay.toIso8601String());
    
    return response.count ?? 0;
  }

  Future<double> _getAverageSessionDuration() async {
    final response = await _client
        .from(userSessionsTable)
        .select('duration_seconds')
        .gt('duration_seconds', 0);

    if ((response as List).isEmpty) return 0.0;
    
    final durations = response.map((s) => s['duration_seconds'] as int).toList();
    return durations.fold<double>(0, (sum, duration) => sum + duration) / durations.length;
  }
}