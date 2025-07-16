/// 数据库表名常量类
/// 包含所有数据库表的名称定义
class SupabaseTables {
  // 私有构造函数，防止实例化
  SupabaseTables._();

  static const String users = 'users'; // 用户表
  static const String stories = 'stories'; // 故事表
  static const String likes = 'likes'; // 点赞表
  static const String comments = 'comments'; // 评论表
  static const String follows = 'follows'; // 关注表
  static const String tags = 'tags'; // 标签表
  static const String storyTags = 'story_tags'; // 故事标签关联表
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
  /// 生产环境中应该从环境变量获取
  static const String supabaseUrl = 'https://wqdpqhfqrxvssxifpmvt.supabase.co';

  /// Supabase匿名密钥
  /// 生产环境中应该从环境变量获取
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
