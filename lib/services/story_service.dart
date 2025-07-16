import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/story.dart';
import 'auth_service.dart';

/// 故事服务类
/// 处理故事相关的数据操作，包括获取、创建、更新、删除等功能
class StoryService {
  // Supabase客户端实例
  final SupabaseClient _client = Supabase.instance.client;

  /// 获取故事列表
  /// [page] 页码，从0开始
  /// [limit] 每页数量，默认10
  /// [orderBy] 排序字段，默认按创建时间
  /// [ascending] 是否升序，默认false（降序）
  /// 返回故事列表
  Future<List<Story>> getStories({
    int page = 0,
    int limit = 10,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.stories)
          .select('''
            *,
            author:users(id, nickname, avatar_url),
            story_tags(tags(*))
          ''')
          .order(orderBy, ascending: ascending)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      debugPrint('获取故事列表失败: $e');
      return [];
    }
  }

  /// 根据用户ID获取故事列表
  /// [userId] 用户ID
  /// [page] 页码
  /// [limit] 每页数量
  /// 返回该用户的故事列表
  Future<List<Story>> getStoriesByUser({
    required String userId,
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.stories)
          .select('''
            *,
            author:users(id, nickname, avatar_url),
            story_tags(tags(*))
          ''')
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      debugPrint('获取用户故事失败: $e');
      return [];
    }
  }

  /// 根据关键词搜索故事
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// [limit] 每页数量
  /// 返回匹配的故事列表
  Future<List<Story>> searchStories({
    required String keyword,
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.stories)
          .select('''
            *,
            author:users(id, nickname, avatar_url),
            story_tags(tags(*))
          ''')
          .or('title.ilike.%$keyword%,content.ilike.%$keyword%')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      debugPrint('搜索故事失败: $e');
      return [];
    }
  }

  /// 根据标签获取故事列表
  /// [tagId] 标签ID
  /// [page] 页码
  /// [limit] 每页数量
  /// 返回包含该标签的故事列表
  Future<List<Story>> getStoriesByTag({
    required String tagId,
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.stories)
          .select('''
            *,
            author:users(id, nickname, avatar_url),
            story_tags!inner(tags(*))
          ''')
          .eq('story_tags.tag_id', tagId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      debugPrint('获取标签故事失败: $e');
      return [];
    }
  }

  /// 根据ID获取单个故事详情
  /// [storyId] 故事ID
  /// 返回故事详情，如果不存在则返回null
  Future<Story?> getStoryById(String storyId) async {
    try {
      final response = await _client.from(SupabaseTables.stories).select('''
            *,
            author:users(id, nickname, avatar_url, bio),
            story_tags(tags(*))
          ''').eq('id', storyId).single();

      return Story.fromJson(response);
    } catch (e) {
      debugPrint('获取故事详情失败: $e');
      return null;
    }
  }

  /// 创建新故事
  /// [title] 故事标题
  /// [content] 故事内容
  /// [imageUrl] 图片URL（可选）
  /// [tagIds] 标签ID列表（可选）
  /// 返回创建成功的故事对象
  Future<Story?> createStory({
    required String title,
    required String content,
    String? imageUrl,
    List<String>? tagIds,
  }) async {
    try {
      // 获取当前用户ID
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('用户未登录');
      }

      // 创建故事记录
      final response = await _client.from(SupabaseTables.stories).insert({
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'author_id': userId,
      }).select('''
            *,
            author:users(id, nickname, avatar_url)
          ''').single();

      final story = Story.fromJson(response);

      // 如果有标签，添加标签关联
      if (tagIds != null && tagIds.isNotEmpty) {
        await _addStoryTags(story.id, tagIds);
      }

      return story;
    } catch (e) {
      debugPrint('创建故事失败: $e');
      return null;
    }
  }

  /// 更新故事
  /// [storyId] 故事ID
  /// [title] 新标题（可选）
  /// [content] 新内容（可选）
  /// [imageUrl] 新图片URL（可选）
  /// 返回是否更新成功
  Future<bool> updateStory({
    required String storyId,
    String? title,
    String? content,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (imageUrl != null) updateData['image_url'] = imageUrl;

      if (updateData.isEmpty) return true;

      await _client
          .from(SupabaseTables.stories)
          .update(updateData)
          .eq('id', storyId);

      return true;
    } catch (e) {
      debugPrint('更新故事失败: $e');
      return false;
    }
  }

  /// 删除故事
  /// [storyId] 故事ID
  /// 返回是否删除成功
  Future<bool> deleteStory(String storyId) async {
    try {
      await _client.from(SupabaseTables.stories).delete().eq('id', storyId);

      return true;
    } catch (e) {
      debugPrint('删除故事失败: $e');
      return false;
    }
  }

  /// 检查用户是否点赞了指定故事
  /// [storyId] 故事ID
  /// 返回是否已点赞
  Future<bool> isLiked(String storyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from(SupabaseTables.likes)
          .select()
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('检查点赞状态失败: $e');
      return false;
    }
  }

  /// 切换故事点赞状态
  /// [storyId] 故事ID
  /// 返回新的点赞状态（true表示已点赞，false表示已取消点赞）
  Future<bool> toggleLike(String storyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('用户未登录');
      }

      final isCurrentlyLiked = await isLiked(storyId);

      if (isCurrentlyLiked) {
        // 取消点赞
        await _client
            .from(SupabaseTables.likes)
            .delete()
            .eq('story_id', storyId)
            .eq('user_id', userId);
        return false;
      } else {
        // 添加点赞
        await _client.from(SupabaseTables.likes).insert({
          'story_id': storyId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('切换点赞状态失败: $e');
      rethrow;
    }
  }

  /// 获取故事评论列表
  /// [storyId] 故事ID
  /// [page] 页码
  /// [limit] 每页数量
  /// 返回评论列表
  Future<List<Map<String, dynamic>>> getComments({
    required String storyId,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.comments)
          .select('''
            *,
            user:users(id, nickname, avatar_url)
          ''')
          .eq('story_id', storyId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response;
    } catch (e) {
      debugPrint('获取评论失败: $e');
      return [];
    }
  }

  /// 添加评论
  /// [storyId] 故事ID
  /// [content] 评论内容
  /// 返回是否添加成功
  Future<bool> addComment({
    required String storyId,
    required String content,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('用户未登录');
      }

      await _client.from(SupabaseTables.comments).insert({
        'story_id': storyId,
        'user_id': userId,
        'content': content,
      });

      return true;
    } catch (e) {
      debugPrint('添加评论失败: $e');
      return false;
    }
  }

  /// 获取推荐故事
  /// [limit] 返回数量，默认10
  /// 返回推荐的故事列表
  Future<List<Story>> getRecommendedStories({int limit = 10}) async {
    try {
      // 简单的推荐算法：按点赞数和创建时间综合排序
      final response = await _client
          .from(SupabaseTables.stories)
          .select('''
            *,
            author:users(id, nickname, avatar_url),
            story_tags(tags(*))
          ''')
          .order('likes_count', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      debugPrint('获取推荐故事失败: $e');
      return [];
    }
  }

  /// 获取关注用户的故事
  /// [page] 页码
  /// [limit] 每页数量
  /// 返回关注用户发布的故事列表
  Future<List<Story>> getFollowingStories({
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // 首先获取当前用户关注的用户ID列表
      final followsResponse = await _client
          .from(SupabaseTables.follows)
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = followsResponse
          .map((item) => item['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) {
        return [];
      }

      // 查询关注用户发布的故事
      final response = await _client
          .from(SupabaseTables.stories)
          .select('''
            *,
            author:users!inner(id, nickname, avatar_url),
            story_tags(tags(*))
          ''')
          .inFilter('author_id', followingIds)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      debugPrint('获取关注故事失败: $e');
      return [];
    }
  }

  /// 获取故事统计信息
  /// [storyId] 故事ID
  /// 返回包含点赞数、评论数等统计信息的Map
  Future<Map<String, int>> getStoryStats(String storyId) async {
    try {
      // 并行查询点赞数和评论数
      final futures = await Future.wait([
        _client.from(SupabaseTables.likes).select('id').eq('story_id', storyId),
        _client
            .from(SupabaseTables.comments)
            .select('id')
            .eq('story_id', storyId),
      ]);

      return {
        'likes': futures[0].length,
        'comments': futures[1].length,
      };
    } catch (e) {
      debugPrint('获取故事统计失败: $e');
      return {'likes': 0, 'comments': 0};
    }
  }

  /// 添加故事标签关联
  /// [storyId] 故事ID
  /// [tagIds] 标签ID列表
  /// 返回是否添加成功
  Future<bool> _addStoryTags(String storyId, List<String> tagIds) async {
    try {
      final data = tagIds
          .map((tagId) => {
                'story_id': storyId,
                'tag_id': tagId,
              })
          .toList();

      await _client.from(SupabaseTables.storyTags).insert(data);

      return true;
    } catch (e) {
      debugPrint('添加故事标签失败: $e');
      return false;
    }
  }

  /// 移除故事标签关联
  /// [storyId] 故事ID
  /// [tagIds] 要移除的标签ID列表
  /// 返回是否移除成功
  Future<bool> removeStoryTags(String storyId, List<String> tagIds) async {
    try {
      await _client
          .from(SupabaseTables.storyTags)
          .delete()
          .eq('story_id', storyId)
          .inFilter('tag_id', tagIds);

      return true;
    } catch (e) {
      debugPrint('移除故事标签失败: $e');
      return false;
    }
  }

  /// 获取所有标签
  /// 返回标签列表
  Future<List<Map<String, dynamic>>> getAllTags() async {
    try {
      final response =
          await _client.from(SupabaseTables.tags).select().order('name');

      return response;
    } catch (e) {
      debugPrint('获取标签列表失败: $e');
      return [];
    }
  }

  /// 创建新标签
  /// [name] 标签名称
  /// [color] 标签颜色（可选）
  /// 返回创建的标签信息
  Future<Map<String, dynamic>?> createTag({
    required String name,
    String? color,
  }) async {
    try {
      final response = await _client
          .from(SupabaseTables.tags)
          .insert({
            'name': name,
            'color': color ?? '#4251F5',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('创建标签失败: $e');
      return null;
    }
  }
}
