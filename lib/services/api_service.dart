import '../models/ai_character.dart';
import '../models/audio_content.dart';
import '../models/creation_item.dart';
import '../models/discovery_content.dart';
import 'supabase_service.dart';

/// API服务层
/// 将Supabase操作封装为业务逻辑方法，提供给前端调用
class ApiService {
  static ApiService? _instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  ApiService._internal();

  /// 获取单例实例
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // ============================================================================
  // 认证相关API
  // ============================================================================

  /// 发送登录验证码
  Future<bool> sendLoginCode(String phone) async {
    try {
      final response = await _supabaseService.signInWithPhone(phone);
      return response.user != null || response.session != null;
    } catch (e) {
      throw ApiException('发送验证码失败: $e');
    }
  }

  /// 验证登录码并登录
  Future<String?> verifyLoginCode({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _supabaseService.verifyOTP(
        phone: phone,
        token: code,
      );
      
      if (response.user != null) {
        // 检查用户档案是否存在，不存在则创建
        await _ensureUserProfile(response.user!, phone);
        return response.user!.id;
      }
      return null;
    } catch (e) {
      throw ApiException('验证码验证失败: $e');
    }
  }

  /// 确保用户档案存在
  Future<void> _ensureUserProfile(dynamic user, String phone) async {
    try {
      await _supabaseService.getUserProfile(user.id);
    } catch (e) {
      // 用户档案不存在，创建新档案
      await _supabaseService.createUserProfile(
        userId: user.id,
        phone: phone,
        nickname: '星趣用户${phone.substring(phone.length - 4)}',
      );
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      throw ApiException('退出登录失败: $e');
    }
  }

  /// 获取当前用户信息
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      return await _supabaseService.getUserProfile(userId);
    } catch (e) {
      throw ApiException('获取用户信息失败: $e');
    }
  }

  // ============================================================================
  // AI角色相关API
  // ============================================================================

  /// 获取AI角色列表
  Future<List<AICharacter>> getAICharacters({
    int page = 1,
    int pageSize = 20,
    String? category,
    bool? isFeatured,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final data = await _supabaseService.getAICharacters(
        limit: pageSize,
        offset: offset,
        category: category,
        isFeature: isFeatured,
      );

      return data.map((item) => AICharacter.fromJson(item)).toList();
    } catch (e) {
      throw ApiException('获取AI角色列表失败: $e');
    }
  }

  /// 获取精选AI角色
  Future<List<AICharacter>> getFeaturedCharacters({int limit = 10}) async {
    return await getAICharacters(
      pageSize: limit,
      isFeatured: true,
    );
  }

  /// 获取AI角色详情
  Future<AICharacter?> getAICharacterDetail(String characterId) async {
    try {
      final data = await _supabaseService.getAICharacter(characterId);
      if (data == null) return null;
      
      return AICharacter.fromJson(data);
    } catch (e) {
      throw ApiException('获取AI角色详情失败: $e');
    }
  }

  /// 关注/取消关注AI角色
  Future<void> toggleCharacterFollow(String characterId) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      final isFollowing = await _supabaseService.isCharacterFollowed(
        userId: userId,
        characterId: characterId,
      );

      await _supabaseService.toggleCharacterFollow(
        userId: userId,
        characterId: characterId,
        isFollowing: !isFollowing,
      );
    } catch (e) {
      throw ApiException('操作失败: $e');
    }
  }

  /// 检查是否关注了AI角色
  Future<bool> isCharacterFollowed(String characterId) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return false;

    try {
      return await _supabaseService.isCharacterFollowed(
        userId: userId,
        characterId: characterId,
      );
    } catch (e) {
      return false;
    }
  }

  /// 创建AI角色
  Future<String> createAICharacter({
    required String name,
    required String personality,
    String? avatarUrl,
    String? description,
    String? backgroundStory,
    List<String>? tags,
    String? category,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      return await _supabaseService.createAICharacter(
        creatorId: userId,
        name: name,
        personality: personality,
        avatarUrl: avatarUrl,
        description: description,
        backgroundStory: backgroundStory,
        tags: tags,
        category: category,
      );
    } catch (e) {
      throw ApiException('创建AI角色失败: $e');
    }
  }

  // ============================================================================
  // 音频内容相关API
  // ============================================================================

  /// 获取音频内容列表
  Future<List<AudioContent>> getAudioContents({
    int page = 1,
    int pageSize = 20,
    String? category,
    bool? isFeatured,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final data = await _supabaseService.getAudioContents(
        limit: pageSize,
        offset: offset,
        category: category,
        isFeatured: isFeatured,
      );

      return data.map((item) => _audioContentFromJson(item)).toList();
    } catch (e) {
      throw ApiException('获取音频内容失败: $e');
    }
  }

  /// 获取热门音频
  Future<List<AudioContent>> getTrendingAudios({int limit = 10}) async {
    try {
      final data = await _supabaseService.getTrendingContent(
        contentType: 'audios',
        limit: limit,
      );

      return data.map((item) => _audioContentFromJson(item)).toList();
    } catch (e) {
      throw ApiException('获取热门音频失败: $e');
    }
  }

  /// 记录音频播放
  Future<void> recordAudioPlay({
    required String audioId,
    int playPosition = 0,
    bool completed = false,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      await _supabaseService.recordAudioPlay(
        userId: userId,
        audioId: audioId,
        playPosition: playPosition,
        completed: completed,
      );
    } catch (e) {
      // 播放记录失败不影响用户体验，静默处理
    }
  }

  /// 获取用户播放历史
  Future<List<AudioContent>> getUserPlayHistory({int limit = 20}) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return [];

    try {
      final data = await _supabaseService.getUserPlayHistory(
        userId: userId,
        limit: limit,
      );

      return data.map((item) {
        final audioData = item['audio_contents'];
        return _audioContentFromJson(audioData);
      }).toList();
    } catch (e) {
      throw ApiException('获取播放历史失败: $e');
    }
  }

  // ============================================================================
  // 创作中心相关API
  // ============================================================================

  /// 获取用户创作项目
  Future<List<CreationItem>> getUserCreations({
    int page = 1,
    int pageSize = 20,
    String? contentType,
    String? status,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      final offset = (page - 1) * pageSize;
      final data = await _supabaseService.getUserCreations(
        userId: userId,
        limit: pageSize,
        offset: offset,
        contentType: contentType,
        status: status,
      );

      return data.map((item) => CreationItem.fromJson(item)).toList();
    } catch (e) {
      throw ApiException('获取创作项目失败: $e');
    }
  }

  /// 创建创作项目
  Future<String> createCreationItem({
    required String title,
    required String contentType,
    String? description,
    Map<String, dynamic>? content,
    String? thumbnailUrl,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      return await _supabaseService.createCreationItem(
        creatorId: userId,
        title: title,
        contentType: contentType,
        description: description,
        content: content,
        thumbnailUrl: thumbnailUrl,
        tags: tags,
        isPublic: isPublic,
      );
    } catch (e) {
      throw ApiException('创建项目失败: $e');
    }
  }

  /// 更新创作项目
  Future<void> updateCreationItem({
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      await _supabaseService.updateCreationItem(
        itemId: itemId,
        creatorId: userId,
        data: data,
      );
    } catch (e) {
      throw ApiException('更新项目失败: $e');
    }
  }

  // ============================================================================
  // 发现页面相关API
  // ============================================================================

  /// 获取发现内容列表
  Future<List<DiscoveryContent>> getDiscoveryContents({
    int page = 1,
    int pageSize = 20,
    String? category,
    bool? isFeatured,
    bool? isTrending,
    String? searchQuery,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final data = await _supabaseService.getDiscoveryContents(
        limit: pageSize,
        offset: offset,
        category: category,
        isFeatured: isFeatured,
        isTrending: isTrending,
        searchQuery: searchQuery,
      );

      return data.map((item) => DiscoveryContent.fromJson(item)).toList();
    } catch (e) {
      throw ApiException('获取发现内容失败: $e');
    }
  }

  /// 搜索内容
  Future<Map<String, List<dynamic>>> searchContent(String query) async {
    try {
      final results = await _supabaseService.searchAll(query: query);
      
      return {
        'characters': results['characters']?.map((item) => AICharacter.fromJson(item)).toList() ?? [],
        'audios': results['audios']?.map((item) => _audioContentFromJson(item)).toList() ?? [],
        'discoveries': results['discoveries']?.map((item) => DiscoveryContent.fromJson(item)).toList() ?? [],
      };
    } catch (e) {
      throw ApiException('搜索失败: $e');
    }
  }

  // ============================================================================
  // 社交功能相关API
  // ============================================================================

  /// 点赞/取消点赞
  Future<void> toggleLike({
    required String targetType,
    required String targetId,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      final isLiked = await _supabaseService.isLiked(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
      );

      await _supabaseService.toggleLike(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        isLiked: !isLiked,
      );
    } catch (e) {
      throw ApiException('操作失败: $e');
    }
  }

  /// 检查是否已点赞
  Future<bool> isLiked({
    required String targetType,
    required String targetId,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return false;

    try {
      return await _supabaseService.isLiked(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
      );
    } catch (e) {
      return false;
    }
  }

  /// 添加评论
  Future<String> addComment({
    required String targetType,
    required String targetId,
    required String content,
    String? parentId,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw ApiException('用户未登录');

    try {
      return await _supabaseService.addComment(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        content: content,
        parentId: parentId,
      );
    } catch (e) {
      throw ApiException('评论失败: $e');
    }
  }

  /// 获取评论列表
  Future<List<Map<String, dynamic>>> getComments({
    required String targetType,
    required String targetId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      return await _supabaseService.getComments(
        targetType: targetType,
        targetId: targetId,
        limit: pageSize,
        offset: offset,
      );
    } catch (e) {
      throw ApiException('获取评论失败: $e');
    }
  }

  // ============================================================================
  // 文件上传相关API
  // ============================================================================

  /// 上传头像
  Future<String> uploadAvatar(List<int> fileBytes, String fileName) async {
    try {
      return await _supabaseService.uploadFile(
        bucket: 'avatars',
        fileName: fileName,
        fileBytes: fileBytes,
        contentType: 'image/jpeg',
      );
    } catch (e) {
      throw ApiException('上传头像失败: $e');
    }
  }

  /// 上传音频文件
  Future<String> uploadAudio(List<int> fileBytes, String fileName) async {
    try {
      return await _supabaseService.uploadFile(
        bucket: 'audios',
        fileName: fileName,
        fileBytes: fileBytes,
        contentType: 'audio/mpeg',
      );
    } catch (e) {
      throw ApiException('上传音频失败: $e');
    }
  }

  // ============================================================================
  // 私有辅助方法
  // ============================================================================

  /// 从JSON创建AudioContent对象
  AudioContent _audioContentFromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: json['id'],
      title: json['title'],
      artist: json['creator_id'] ?? 'Unknown Artist', // 可以后续关联用户表获取名称
      album: json['category'] ?? 'Unknown Album',
      cover: '🎵', // 默认图标，可以从cover_url获取
      duration: Duration(seconds: json['duration_seconds'] ?? 0),
      category: json['category'] ?? 'Unknown',
      description: json['description'] ?? '',
      playCount: json['play_count'],
      likeCount: json['like_count'],
      audioUrl: json['audio_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }
}

/// API异常类
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}