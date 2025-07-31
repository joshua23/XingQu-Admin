import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase后端服务基础类
/// 提供数据库操作、认证、存储等核心功能
class SupabaseService {
  static SupabaseService? _instance;
  late SupabaseClient _client;

  SupabaseService._internal();

  /// 获取单例实例
  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  /// 初始化Supabase客户端
  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// 获取Supabase客户端
  SupabaseClient get client => _client;

  /// 获取当前用户
  User? get currentUser => _client.auth.currentUser;

  /// 检查用户是否已登录
  bool get isLoggedIn => currentUser != null;

  /// 获取当前用户ID
  String? get currentUserId => currentUser?.id;

  // ============================================================================
  // 认证相关方法
  // ============================================================================

  /// 手机号登录/注册
  Future<AuthResponse> signInWithPhone(String phone) async {
    return await _client.auth.signInWithOtp(
      phone: phone,
      channel: OtpChannel.sms,
    );
  }

  /// 验证OTP验证码
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
  }

  /// 退出登录
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 监听认证状态变化
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================================================
  // 用户数据操作
  // ============================================================================

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  /// 更新用户信息
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('users')
        .update(data)
        .eq('id', userId);
  }

  /// 创建用户档案
  Future<void> createUserProfile({
    required String userId,
    required String phone,
    required String nickname,
    String? avatarUrl,
    String? bio,
  }) async {
    await _client.from('users').insert({
      'id': userId,
      'phone': phone,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'bio': bio,
    });
  }

  // ============================================================================
  // AI角色相关操作
  // ============================================================================

  /// 获取AI角色列表
  Future<List<Map<String, dynamic>>> getAICharacters({
    int limit = 20,
    int offset = 0,
    String? category,
    bool? isFeature,
  }) async {
    var query = _client
        .from('ai_characters')
        .select()
        .eq('is_public', true)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (category != null) {
      query = query.eq('category', category);
    }

    if (isFeature != null) {
      query = query.eq('is_featured', isFeature);
    }

    return await query;
  }

  /// 获取单个AI角色详情
  Future<Map<String, dynamic>?> getAICharacter(String characterId) async {
    final response = await _client
        .from('ai_characters')
        .select()
        .eq('id', characterId)
        .single();
    return response;
  }

  /// 创建AI角色
  Future<String> createAICharacter({
    required String creatorId,
    required String name,
    required String personality,
    String? avatarUrl,
    String? description,
    String? backgroundStory,
    String? greetingMessage,
    List<String>? tags,
    String? category,
  }) async {
    final response = await _client.from('ai_characters').insert({
      'creator_id': creatorId,
      'name': name,
      'personality': personality,
      'avatar_url': avatarUrl,
      'description': description,
      'background_story': backgroundStory,
      'greeting_message': greetingMessage,
      'tags': tags,
      'category': category,
    }).select().single();

    return response['id'];
  }

  /// 关注/取消关注AI角色
  Future<void> toggleCharacterFollow({
    required String userId,
    required String characterId,
    required bool isFollowing,
  }) async {
    if (isFollowing) {
      await _client.from('character_follows').insert({
        'user_id': userId,
        'character_id': characterId,
      });
    } else {
      await _client
          .from('character_follows')
          .delete()
          .eq('user_id', userId)
          .eq('character_id', characterId);
    }
  }

  /// 检查是否关注了AI角色
  Future<bool> isCharacterFollowed({
    required String userId,
    required String characterId,
  }) async {
    final response = await _client
        .from('character_follows')
        .select()
        .eq('user_id', userId)
        .eq('character_id', characterId);
    
    return response.isNotEmpty;
  }

  // ============================================================================
  // 音频内容相关操作
  // ============================================================================

  /// 获取音频内容列表
  Future<List<Map<String, dynamic>>> getAudioContents({
    int limit = 20,
    int offset = 0,
    String? category,
    bool? isFeatured,
  }) async {
    var query = _client
        .from('audio_contents')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (category != null) {
      query = query.eq('category', category);
    }

    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    return await query;
  }

  /// 获取单个音频内容
  Future<Map<String, dynamic>?> getAudioContent(String audioId) async {
    final response = await _client
        .from('audio_contents')
        .select()
        .eq('id', audioId)
        .single();
    return response;
  }

  /// 记录音频播放
  Future<void> recordAudioPlay({
    required String userId,
    required String audioId,
    int playPosition = 0,
    bool completed = false,
  }) async {
    await _client.from('audio_play_history').insert({
      'user_id': userId,
      'audio_id': audioId,
      'play_position': playPosition,
      'completed': completed,
    });

    // 更新播放次数
    await _client.rpc('increment_play_count', params: {
      'audio_id': audioId,
    });
  }

  /// 获取用户播放历史
  Future<List<Map<String, dynamic>>> getUserPlayHistory({
    required String userId,
    int limit = 20,
  }) async {
    return await _client
        .from('audio_play_history')
        .select('''
          *,
          audio_contents (
            id, title, creator_id, cover_url, duration_seconds
          )
        ''')
        .eq('user_id', userId)
        .order('played_at', ascending: false)
        .limit(limit);
  }

  // ============================================================================
  // 创作项目相关操作
  // ============================================================================

  /// 获取用户创作项目
  Future<List<Map<String, dynamic>>> getUserCreations({
    required String userId,
    int limit = 20,
    int offset = 0,
    String? contentType,
    String? status,
  }) async {
    var query = _client
        .from('creation_items')
        .select()
        .eq('creator_id', userId)
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (contentType != null) {
      query = query.eq('content_type', contentType);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    return await query;
  }

  /// 创建创作项目
  Future<String> createCreationItem({
    required String creatorId,
    required String title,
    required String contentType,
    String? description,
    Map<String, dynamic>? content,
    String? thumbnailUrl,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    final response = await _client.from('creation_items').insert({
      'creator_id': creatorId,
      'title': title,
      'content_type': contentType,
      'description': description,
      'content': content,
      'thumbnail_url': thumbnailUrl,
      'tags': tags,
      'is_public': isPublic,
    }).select().single();

    return response['id'];
  }

  /// 更新创作项目
  Future<void> updateCreationItem({
    required String itemId,
    required String creatorId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('creation_items')
        .update(data)
        .eq('id', itemId)
        .eq('creator_id', creatorId);
  }

  // ============================================================================
  // 发现内容相关操作
  // ============================================================================

  /// 获取发现内容列表
  Future<List<Map<String, dynamic>>> getDiscoveryContents({
    int limit = 20,
    int offset = 0,
    String? category,
    bool? isFeatured,
    bool? isTrending,
    String? searchQuery,
  }) async {
    var query = _client
        .from('discovery_contents')
        .select()
        .order('weight', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (category != null) {
      query = query.eq('category', category);
    }

    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    if (isTrending != null) {
      query = query.eq('is_trending', isTrending);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.textSearch('title,description', searchQuery);
    }

    return await query;
  }

  // ============================================================================
  // 社交功能相关操作
  // ============================================================================

  /// 点赞/取消点赞
  Future<void> toggleLike({
    required String userId,
    required String targetType,
    required String targetId,
    required bool isLiked,
  }) async {
    if (isLiked) {
      await _client.from('likes').insert({
        'user_id': userId,
        'target_type': targetType,
        'target_id': targetId,
      });
    } else {
      await _client
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('target_type', targetType)
          .eq('target_id', targetId);
    }
  }

  /// 检查是否已点赞
  Future<bool> isLiked({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final response = await _client
        .from('likes')
        .select()
        .eq('user_id', userId)
        .eq('target_type', targetType)
        .eq('target_id', targetId);
    
    return response.isNotEmpty;
  }

  /// 添加评论
  Future<String> addComment({
    required String userId,
    required String targetType,
    required String targetId,
    required String content,
    String? parentId,
  }) async {
    final response = await _client.from('comments').insert({
      'user_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'content': content,
      'parent_id': parentId,
    }).select().single();

    return response['id'];
  }

  /// 获取评论列表
  Future<List<Map<String, dynamic>>> getComments({
    required String targetType,
    required String targetId,
    int limit = 20,
    int offset = 0,
  }) async {
    return await _client
        .from('comments')
        .select('''
          *,
          users (nickname, avatar_url)
        ''')
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .is_('parent_id', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
  }

  // ============================================================================
  // 文件存储相关操作
  // ============================================================================

  /// 上传文件
  Future<String> uploadFile({
    required String bucket,
    required String fileName,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    final response = await _client.storage
        .from(bucket)
        .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(
          contentType: contentType,
        ));

    return _client.storage.from(bucket).getPublicUrl(fileName);
  }

  /// 删除文件
  Future<void> deleteFile({
    required String bucket,
    required String fileName,
  }) async {
    await _client.storage.from(bucket).remove([fileName]);
  }

  // ============================================================================
  // 搜索功能
  // ============================================================================

  /// 全文搜索
  Future<Map<String, List<Map<String, dynamic>>>> searchAll({
    required String query,
    int limit = 10,
  }) async {
    final results = <String, List<Map<String, dynamic>>>{};

    // 搜索AI角色
    final characters = await _client
        .from('ai_characters')
        .select()
        .textSearch('name,description', query)
        .eq('is_public', true)
        .limit(limit);
    results['characters'] = characters;

    // 搜索音频内容
    final audios = await _client
        .from('audio_contents')
        .select()
        .textSearch('title,description', query)
        .eq('is_public', true)
        .limit(limit);
    results['audios'] = audios;

    // 搜索发现内容
    final discoveries = await _client
        .from('discovery_contents')
        .select()
        .textSearch('title,description', query)
        .limit(limit);
    results['discoveries'] = discoveries;

    return results;
  }

  // ============================================================================
  // 统计和分析
  // ============================================================================

  /// 记录用户行为
  Future<void> recordUserAnalytics({
    required String userId,
    required String eventType,
    Map<String, dynamic>? eventData,
    String? sessionId,
  }) async {
    await _client.from('user_analytics').insert({
      'user_id': userId,
      'event_type': eventType,
      'event_data': eventData,
      'session_id': sessionId,
    });
  }

  /// 获取热门内容
  Future<List<Map<String, dynamic>>> getTrendingContent({
    String contentType = 'all',
    int limit = 10,
  }) async {
    // 这里可以根据播放量、点赞数等指标计算热门内容
    // 实际实现可能需要更复杂的算法
    
    switch (contentType) {
      case 'characters':
        return await _client
            .from('ai_characters')
            .select()
            .eq('is_public', true)
            .order('follower_count', ascending: false)
            .limit(limit);
      
      case 'audios':
        return await _client
            .from('audio_contents')
            .select()
            .eq('is_public', true)
            .order('play_count', ascending: false)
            .limit(limit);
      
      default:
        return await _client
            .from('discovery_contents')
            .select()
            .eq('is_trending', true)
            .order('view_count', ascending: false)
            .limit(limit);
    }
  }
}