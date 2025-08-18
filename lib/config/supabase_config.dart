/// 数据库表名常量类
/// 包含所有数据库表的名称定义
class SupabaseTables {
  // 私有构造函数，防止实例化
  SupabaseTables._();

  // 基础表
  static const String users = 'users'; // 用户表
  static const String stories = 'stories'; // 故事表
  static const String likes = 'likes'; // 点赞表
  static const String comments = 'comments'; // 评论表
  static const String follows = 'follows'; // 关注表
  static const String tags = 'tags'; // 标签表
  static const String storyTags = 'story_tags'; // 故事标签关联表
  
  // Sprint 2 新增表 - 交互功能
  static const String interactionMenuConfigs = 'interaction_menu_configs'; // 交互菜单配置表
  static const String interactionLogs = 'interaction_logs'; // 用户交互日志表
  
  // Sprint 2 新增表 - 订阅模块
  static const String userSubscriptions = 'user_subscriptions'; // 用户订阅关系表
  static const String subscriptionGroups = 'subscription_groups'; // 订阅分组表
  static const String subscriptionGroupItems = 'subscription_group_items'; // 订阅分组关系表
  
  // Sprint 2 新增表 - 推荐算法模块
  static const String recommendationAlgorithms = 'recommendation_algorithms'; // 推荐算法配置表
  static const String userRecommendations = 'user_recommendations'; // 用户推荐结果缓存表
  static const String aiAgentCategories = 'ai_agent_categories'; // 智能体分类表
  static const String aiCharacterExtensions = 'ai_character_extensions'; // AI角色扩展属性表
  
  // Sprint 2 新增表 - 记忆簿模块
  static const String memoryTypes = 'memory_types'; // 记忆类型配置表
  static const String memoryItems = 'memory_items'; // 用户记忆条目表
  static const String memorySearchVectors = 'memory_search_vectors'; // 记忆搜索向量表
  
  // Sprint 2 新增表 - 双语学习模块
  static const String bilingualContents = 'bilingual_contents'; // 双语内容表
  static const String userBilingualProgress = 'user_bilingual_progress'; // 用户双语学习进度表
  
  // Sprint 2 新增表 - 挑战任务模块
  static const String challengeTypes = 'challenge_types'; // 挑战任务类型表
  static const String challengeTasks = 'challenge_tasks'; // 挑战任务表
  static const String userChallengeParticipations = 'user_challenge_participations'; // 用户挑战参与记录表
  static const String userAchievements = 'user_achievements'; // 用户成就表
  
  // Sprint 2 新增表 - UI装饰模块
  static const String uiDecorations = 'ui_decorations'; // UI装饰元素配置表
  static const String userUiPreferences = 'user_ui_preferences'; // 用户UI偏好设置表
  
  // Sprint 2 新增表 - 系统配置
  static const String systemConfigs = 'system_configs'; // 系统配置表
  static const String dataCache = 'data_cache'; // 数据缓存表
}

/// 认证相关配置类
/// 包含Supabase认证的相关设置
class SupabaseAuth {
  // 私有构造函数，防止实例化
  SupabaseAuth._();

  /// JWT过期时间（秒）
  static const int jwtExpiryMargin = 60;

  /// 自动刷新Token
  static const bool autoRefreshToken = true;

  /// 持久化Session
  static const bool persistSession = true;
}

/// 实时订阅配置类
/// 包含Supabase实时功能的相关设置
class SupabaseRealtime {
  // 私有构造函数，防止实例化
  SupabaseRealtime._();

  /// 心跳间隔（毫秒）
  static const int heartbeatIntervalMs = 30000;

  /// 重连间隔（毫秒）
  static const int reconnectDelayMs = 1000;
}

/// 存储配置类
/// 包含Supabase存储的相关设置
class SupabaseStorage {
  // 私有构造函数，防止实例化
  SupabaseStorage._();

  /// 头像存储桶
  static const String avatarsBucket = 'avatars';

  /// 故事图片存储桶
  static const String storyImagesBucket = 'story-images';

  /// 文件上传大小限制（MB）
  static const int maxFileSizeMB = 5;

  /// 支持的图片格式
  static const List<String> supportedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
}

/// Supabase配置类
/// 管理Supabase连接信息和相关配置
class SupabaseConfig {
  // 私有构造函数，防止实例化
  SupabaseConfig._();

  /// Supabase项目URL
  /// 优先从环境变量获取，开发环境可使用默认值
  static const String supabaseUrl = 'https://wqdpqhfqrxvssxifpmvt.supabase.co';

  /// Supabase匿名密钥
  /// 优先从环境变量获取，开发环境可使用默认值
  /// 注意：这是匿名密钥，用于客户端访问，相对安全
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w';
}

/// 环境变量获取辅助类
/// 用于在不同环境中获取配置信息
class EnvironmentConfig {
  /// 获取Supabase URL
  /// 优先从环境变量获取，回退到默认值
  static String getSupabaseUrl() {
    return const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: SupabaseConfig.supabaseUrl,
    );
  }

  /// 获取Supabase匿名密钥
  /// 优先从环境变量获取，回退到默认值
  static String getSupabaseAnonKey() {
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: SupabaseConfig.supabaseAnonKey,
    );
  }

  /// 检查是否为调试模式
  static bool get isDebugMode {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }

  /// 检查是否为生产环境
  static bool get isProduction {
    return const String.fromEnvironment('ENV', defaultValue: 'dev') == 'prod';
  }
}
