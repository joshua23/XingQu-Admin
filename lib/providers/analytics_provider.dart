import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/analytics_service.dart';
import '../services/analytics_service_real.dart';
import '../models/analytics_models.dart';

/// 数据分析状态管理
/// 管理后台仪表板的所有数据状态
class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final RealAnalyticsService _realAnalyticsService = RealAnalyticsService();
  
  // 真实数据存储
  Map<String, dynamic>? _realBasicStats;
  Map<String, dynamic>? _realEventsData;
  Map<String, dynamic>? _realUsersData;
  Map<String, dynamic>? _realSessionsData;
  
  // 加载状态
  bool _isLoading = false;
  String? _error;
  
  // 总览数据
  OverviewData? _overviewData;
  
  // 用户数据
  UserAnalyticsData? _userAnalytics;
  
  // 行为数据
  List<TrackingEventData> _trackingEvents = [];
  BehaviorAnalyticsData? _behaviorAnalytics;
  
  // 会话数据
  List<UserSessionData> _userSessions = [];
  SessionAnalyticsData? _sessionAnalytics;
  
  // 实时数据
  RealTimeMetrics? _realTimeMetrics;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  OverviewData? get overviewData => _overviewData;
  UserAnalyticsData? get userAnalytics => _userAnalytics;
  List<TrackingEventData> get trackingEvents => _trackingEvents;
  BehaviorAnalyticsData? get behaviorAnalytics => _behaviorAnalytics;
  List<UserSessionData> get userSessions => _userSessions;
  SessionAnalyticsData? get sessionAnalytics => _sessionAnalytics;
  RealTimeMetrics? get realTimeMetrics => _realTimeMetrics;
  
  // 真实数据 Getters
  Map<String, dynamic>? get realBasicStats => _realBasicStats;
  Map<String, dynamic>? get realEventsData => _realEventsData;
  Map<String, dynamic>? get realUsersData => _realUsersData;
  Map<String, dynamic>? get realSessionsData => _realSessionsData;

  /// 加载仪表板数据
  Future<void> loadDashboardData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadOverviewData(),
        _loadUserAnalytics(),
        _loadBehaviorAnalytics(),
        _loadSessionAnalytics(),
        _loadRealTimeMetrics(),
        _loadRealData(), // 加载真实数据
      ]);
      _clearError();
    } catch (e) {
      _setError('加载数据失败: $e');
      debugPrint('Dashboard data loading error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载真实xq_表数据
  Future<void> _loadRealData() async {
    try {
      final results = await Future.wait([
        _realAnalyticsService.getBasicStats(),
        _realAnalyticsService.getTrackingEventsData(),
        _realAnalyticsService.getUserProfilesData(),
        _realAnalyticsService.getUserSessionsData(),
      ]);
      
      _realBasicStats = results[0];
      _realEventsData = results[1];
      _realUsersData = results[2];
      _realSessionsData = results[3];
      
      debugPrint('✅ Real data loaded successfully');
    } catch (e) {
      debugPrint('❌ Failed to load real data: $e');
      // 不抛出异常，允许其他数据正常加载
    }
  }

  /// 加载总览数据
  Future<void> _loadOverviewData() async {
    _overviewData = await _analyticsService.getOverviewData();
  }

  /// 加载用户分析数据
  Future<void> _loadUserAnalytics() async {
    _userAnalytics = await _analyticsService.getUserAnalytics();
  }

  /// 加载行为分析数据
  Future<void> _loadBehaviorAnalytics() async {
    _trackingEvents = await _analyticsService.getTrackingEvents();
    _behaviorAnalytics = await _analyticsService.getBehaviorAnalytics();
  }

  /// 加载会话分析数据
  Future<void> _loadSessionAnalytics() async {
    _userSessions = await _analyticsService.getUserSessions();
    _sessionAnalytics = await _analyticsService.getSessionAnalytics();
  }

  /// 加载实时指标数据
  Future<void> _loadRealTimeMetrics() async {
    _realTimeMetrics = await _analyticsService.getRealTimeMetrics();
  }

  /// 刷新特定模块数据
  Future<void> refreshModule(String moduleName) async {
    try {
      switch (moduleName) {
        case 'overview':
          await _loadOverviewData();
          break;
        case 'user-analytics':
          await _loadUserAnalytics();
          break;
        case 'behavior-analytics':
          await _loadBehaviorAnalytics();
          break;
        case 'session-analytics':
          await _loadSessionAnalytics();
          break;
        case 'realtime':
          await _loadRealTimeMetrics();
          break;
      }
      notifyListeners();
    } catch (e) {
      _setError('刷新数据失败: $e');
    }
  }

  /// 获取特定时间范围的数据
  Future<void> loadDataForDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    try {
      _trackingEvents = await _analyticsService.getTrackingEventsForDateRange(
        startDate, endDate);
      _userSessions = await _analyticsService.getUserSessionsForDateRange(
        startDate, endDate);
      
      // 重新计算分析数据
      await _loadBehaviorAnalytics();
      await _loadSessionAnalytics();
      
      _clearError();
    } catch (e) {
      _setError('加载时间范围数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 获取特定事件类型的数据
  Future<void> loadEventsByType(String eventType) async {
    try {
      final events = await _analyticsService.getEventsByType(eventType);
      _trackingEvents = events;
      notifyListeners();
    } catch (e) {
      _setError('加载事件数据失败: $e');
    }
  }

  /// 实时数据更新（WebSocket或定期刷新）
  void startRealTimeUpdates() {
    // TODO: 实现WebSocket连接或定时器
    // 这里可以设置定期更新实时数据
  }

  void stopRealTimeUpdates() {
    // TODO: 停止实时更新
  }

  // 私有辅助方法
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopRealTimeUpdates();
    super.dispose();
  }
}