/// 数据分析相关的数据模型
/// 对应xq_前缀表的数据结构

/// 总览数据模型
class OverviewData {
  final int totalUsers;
  final int totalSessions;
  final int totalEvents;
  final int activeUsersToday;
  final int newUsersToday;
  final double averageSessionDuration;
  final DateTime lastUpdated;

  const OverviewData({
    required this.totalUsers,
    required this.totalSessions,
    required this.totalEvents,
    required this.activeUsersToday,
    required this.newUsersToday,
    required this.averageSessionDuration,
    required this.lastUpdated,
  });
}

/// 用户资料数据模型 (对应 xq_user_profiles 表)
class UserProfileData {
  final String id;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? wechatOpenid;
  final String? wechatUnionid;
  final String? wechatNickname;
  final String? wechatAvatarUrl;
  final String? appleUserId;
  final String? appleEmail;
  final String? appleFullName;
  final int likesReceivedCount;
  final int agentsUsageCount;
  final String accountStatus;
  final DateTime? deactivatedAt;
  final String? violationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isMember;
  final DateTime? membershipExpiresAt;
  final String? gender;

  const UserProfileData({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.wechatOpenid,
    this.wechatUnionid,
    this.wechatNickname,
    this.wechatAvatarUrl,
    this.appleUserId,
    this.appleEmail,
    this.appleFullName,
    required this.likesReceivedCount,
    required this.agentsUsageCount,
    required this.accountStatus,
    this.deactivatedAt,
    this.violationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.isMember,
    this.membershipExpiresAt,
    this.gender,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      wechatOpenid: json['wechat_openid'] as String?,
      wechatUnionid: json['wechat_unionid'] as String?,
      wechatNickname: json['wechat_nickname'] as String?,
      wechatAvatarUrl: json['wechat_avatar_url'] as String?,
      appleUserId: json['apple_user_id'] as String?,
      appleEmail: json['apple_email'] as String?,
      appleFullName: json['apple_full_name'] as String?,
      likesReceivedCount: json['likes_received_count'] as int,
      agentsUsageCount: json['agents_usage_count'] as int,
      accountStatus: json['account_status'] as String,
      deactivatedAt: json['deactivated_at'] != null 
          ? DateTime.parse(json['deactivated_at'] as String)
          : null,
      violationReason: json['violation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isMember: json['is_member'] as bool,
      membershipExpiresAt: json['membership_expires_at'] != null
          ? DateTime.parse(json['membership_expires_at'] as String)
          : null,
      gender: json['gender'] as String?,
    );
  }
}

/// 追踪事件数据模型 (对应 xq_tracking_events 表)
class TrackingEventData {
  final String id;
  final String? userId;
  final String? guestId;
  final String sessionId;
  final String eventType;
  final Map<String, dynamic> eventData;
  final DateTime timestamp;
  final DateTime createdAt;

  const TrackingEventData({
    required this.id,
    this.userId,
    this.guestId,
    required this.sessionId,
    required this.eventType,
    required this.eventData,
    required this.timestamp,
    required this.createdAt,
  });

  factory TrackingEventData.fromJson(Map<String, dynamic> json) {
    return TrackingEventData(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      guestId: json['guest_id'] as String?,
      sessionId: json['session_id'] as String,
      eventType: json['event_type'] as String,
      eventData: json['event_data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 用户会话数据模型 (对应 xq_user_sessions 表)
class UserSessionData {
  final String id;
  final String? userId;
  final String? guestId;
  final String sessionId;
  final String deviceId;
  final Map<String, dynamic> deviceInfo;
  final String appVersion;
  final String platform;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int pageViews;
  final int tabSwitches;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSessionData({
    required this.id,
    this.userId,
    this.guestId,
    required this.sessionId,
    required this.deviceId,
    required this.deviceInfo,
    required this.appVersion,
    required this.platform,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.pageViews,
    required this.tabSwitches,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSessionData.fromJson(Map<String, dynamic> json) {
    return UserSessionData(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      guestId: json['guest_id'] as String?,
      sessionId: json['session_id'] as String,
      deviceId: json['device_id'] as String,
      deviceInfo: json['device_info'] as Map<String, dynamic>,
      appVersion: json['app_version'] as String,
      platform: json['platform'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int,
      pageViews: json['page_views'] as int,
      tabSwitches: json['tab_switches'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// 用户分析数据汇总
class UserAnalyticsData {
  final int totalUsers;
  final int activeUsers;
  final int memberUsers;
  final Map<String, int> genderDistribution;
  final List<UserProfileData> userProfiles;

  const UserAnalyticsData({
    required this.totalUsers,
    required this.activeUsers,
    required this.memberUsers,
    required this.genderDistribution,
    required this.userProfiles,
  });
}

/// 行为分析数据汇总
class BehaviorAnalyticsData {
  final int totalEvents;
  final Map<String, int> eventTypeStats;
  final Map<String, int> platformStats;
  final Map<String, int> dailyEventCounts;
  final List<TrackingEventData> recentEvents;

  const BehaviorAnalyticsData({
    required this.totalEvents,
    required this.eventTypeStats,
    required this.platformStats,
    required this.dailyEventCounts,
    required this.recentEvents,
  });
}

/// 会话分析数据汇总
class SessionAnalyticsData {
  final int totalSessions;
  final int activeSessions;
  final double averageDuration;
  final Map<String, int> platformDistribution;
  final Map<int, int> hourlyDistribution;
  final List<UserSessionData> recentSessions;

  const SessionAnalyticsData({
    required this.totalSessions,
    required this.activeSessions,
    required this.averageDuration,
    required this.platformDistribution,
    required this.hourlyDistribution,
    required this.recentSessions,
  });
}

/// 实时指标数据模型
class RealTimeMetrics {
  final int currentActiveUsers;
  final int eventsPerHour;
  final DateTime lastUpdateTime;
  final String systemStatus; // 'healthy', 'warning', 'error'

  const RealTimeMetrics({
    required this.currentActiveUsers,
    required this.eventsPerHour,
    required this.lastUpdateTime,
    required this.systemStatus,
  });
}

/// 指标卡片数据模型
class MetricCardData {
  final String title;
  final String value;
  final double? changePercentage;
  final String? changeLabel;
  final bool isPositiveChange;
  final String? icon;

  const MetricCardData({
    required this.title,
    required this.value,
    this.changePercentage,
    this.changeLabel,
    required this.isPositiveChange,
    this.icon,
  });
}

/// 图表数据点模型
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.timestamp,
    this.metadata,
  });
}

/// 数据表格行模型
class DataTableRowData {
  final String id;
  final Map<String, dynamic> data;
  final bool isSelected;
  final bool isHighlighted;

  const DataTableRowData({
    required this.id,
    required this.data,
    this.isSelected = false,
    this.isHighlighted = false,
  });
}

/// 过滤器选项模型
class FilterOption {
  final String key;
  final String label;
  final dynamic value;
  final bool isSelected;

  const FilterOption({
    required this.key,
    required this.label,
    required this.value,
    this.isSelected = false,
  });
}