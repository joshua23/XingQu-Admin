import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recommendation_item.dart';
import 'supabase_service.dart';

/// 推荐系统服务
/// 处理个性化推荐、内容发现等功能
class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService.instance;

  /// 获取用户个性化推荐
  Future<List<RecommendationItem>> getPersonalizedRecommendations({
    required String userId,
    int limit = 20,
    String? contentType,
  }) async {
    try {
      debugPrint('🎯 获取个性化推荐: userId=$userId, limit=$limit, type=$contentType');
      
      var query = _client
          .from('recommendation_items')
          .select()
          .eq('user_id', userId)
          .gte('expires_at', DateTime.now().toIso8601String());
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      final response = await query
          .order('recommendation_score', ascending: false)
          .order('position_rank', ascending: true)
          .limit(limit);
      
      final recommendations = (response as List)
          .map((json) => RecommendationItem.fromJson(json))
          .toList();

      // 填充内容详细信息
      await _fillContentDetails(recommendations);

      debugPrint('✅ 获取到 ${recommendations.length} 条个性化推荐');
      return recommendations;
    } catch (e) {
      debugPrint('❌ 获取个性化推荐失败: $e');
      return [];
    }
  }

  /// 获取热门推荐内容
  Future<List<RecommendationItem>> getPopularRecommendations({
    String? contentType,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔥 获取热门推荐: type=$contentType, limit=$limit');
      
      var query = _client
          .from('recommendation_items')
          .select()
          .eq('algorithm_type', 'popularity')
          .gte('expires_at', DateTime.now().toIso8601String());
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      final response = await query
          .order('recommendation_score', ascending: false)
          .limit(limit);
      
      final recommendations = (response as List)
          .map((json) => RecommendationItem.fromJson(json))
          .toList();

      await _fillContentDetails(recommendations);

      debugPrint('✅ 获取到 ${recommendations.length} 条热门推荐');
      return recommendations;
    } catch (e) {
      debugPrint('❌ 获取热门推荐失败: $e');
      return [];
    }
  }

  /// 获取趋势推荐内容
  Future<List<RecommendationItem>> getTrendingRecommendations({
    String? contentType,
    int limit = 20,
  }) async {
    try {
      debugPrint('📈 获取趋势推荐: type=$contentType, limit=$limit');
      
      var query = _client
          .from('recommendation_items')
          .select()
          .eq('algorithm_type', 'trending')
          .gte('expires_at', DateTime.now().toIso8601String());
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      final response = await query
          .order('recommendation_score', ascending: false)
          .limit(limit);
      
      final recommendations = (response as List)
          .map((json) => RecommendationItem.fromJson(json))
          .toList();

      await _fillContentDetails(recommendations);

      debugPrint('✅ 获取到 ${recommendations.length} 条趋势推荐');
      return recommendations;
    } catch (e) {
      debugPrint('❌ 获取趋势推荐失败: $e');
      return [];
    }
  }

  /// 获取混合推荐（个性化 + 热门 + 趋势）
  Future<List<RecommendationItem>> getMixedRecommendations({
    required String userId,
    String? contentType,
    int limit = 20,
  }) async {
    try {
      debugPrint('🌈 获取混合推荐: userId=$userId, type=$contentType, limit=$limit');
      
      final personalizedLimit = (limit * 0.6).round();
      final popularLimit = (limit * 0.25).round();
      final trendingLimit = limit - personalizedLimit - popularLimit;
      
      final futures = await Future.wait([
        getPersonalizedRecommendations(
          userId: userId,
          contentType: contentType,
          limit: personalizedLimit,
        ),
        getPopularRecommendations(
          contentType: contentType,
          limit: popularLimit,
        ),
        getTrendingRecommendations(
          contentType: contentType,
          limit: trendingLimit,
        ),
      ]);
      
      final personalized = futures[0];
      final popular = futures[1];
      final trending = futures[2];
      
      // 合并并去重
      final allRecommendations = <RecommendationItem>[];
      final seenContentIds = <String>{};
      
      for (final rec in personalized) {
        if (!seenContentIds.contains(rec.contentId)) {
          allRecommendations.add(rec);
          seenContentIds.add(rec.contentId);
        }
      }
      
      for (final rec in popular) {
        if (!seenContentIds.contains(rec.contentId)) {
          allRecommendations.add(rec);
          seenContentIds.add(rec.contentId);
        }
      }
      
      for (final rec in trending) {
        if (!seenContentIds.contains(rec.contentId)) {
          allRecommendations.add(rec);
          seenContentIds.add(rec.contentId);
        }
      }
      
      // 按推荐分数排序
      allRecommendations.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));
      
      debugPrint('✅ 混合推荐完成: ${allRecommendations.length} 条推荐');
      return allRecommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ 获取混合推荐失败: $e');
      return [];
    }
  }

  /// 记录推荐点击
  Future<void> recordRecommendationClick({
    required String recommendationId,
  }) async {
    try {
      debugPrint('👆 记录推荐点击: $recommendationId');
      
      await _client
          .from('recommendation_items')
          .update({
            'is_clicked': true,
            'click_time': DateTime.now().toIso8601String(),
          })
          .eq('recommendation_id', recommendationId);

      debugPrint('✅ 推荐点击记录成功');
    } catch (e) {
      debugPrint('❌ 记录推荐点击失败: $e');
    }
  }

  /// 提交用户反馈
  Future<void> submitUserFeedback({
    required String userId,
    required String contentId,
    required String feedbackType,
    String? reason,
  }) async {
    try {
      debugPrint('📝 提交用户反馈: userId=$userId, contentId=$contentId, type=$feedbackType');
      
      await _client
          .from('user_feedback')
          .insert({
            'user_id': userId,
            'content_id': contentId,
            'feedback_type': feedbackType,
            'reason': reason,
            'created_at': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ 用户反馈提交成功');
    } catch (e) {
      debugPrint('❌ 提交用户反馈失败: $e');
    }
  }

  /// 获取用户偏好设置
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      debugPrint('⚙️ 获取用户偏好: $userId');
      
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .single();

      final preferences = response as Map<String, dynamic>;
      debugPrint('✅ 获取用户偏好成功');
      return preferences;
    } catch (e) {
      debugPrint('❌ 获取用户偏好失败: $e');
      return {};
    }
  }

  /// 更新用户偏好设置
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      debugPrint('🔧 更新用户偏好: $userId');
      
      await _client
          .from('user_preferences')
          .upsert({
            'user_id': userId,
            'preferences': preferences,
            'updated_at': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ 用户偏好更新成功');
    } catch (e) {
      debugPrint('❌ 更新用户偏好失败: $e');
    }
  }

  /// 获取内容相似推荐
  Future<List<RecommendationItem>> getSimilarContentRecommendations({
    required String contentId,
    String? contentType,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔗 获取相似内容推荐: contentId=$contentId, limit=$limit');
      
      // 调用 Supabase 函数获取相似内容
      final response = await _client
          .rpc('get_similar_content', params: {
            'p_content_id': contentId,
            'p_content_type': contentType,
            'p_limit': limit,
          });

      final recommendations = (response as List)
          .map((json) => RecommendationItem.fromJson(json))
          .toList();

      await _fillContentDetails(recommendations);

      debugPrint('✅ 获取到 ${recommendations.length} 条相似内容推荐');
      return recommendations;
    } catch (e) {
      debugPrint('❌ 获取相似内容推荐失败: $e');
      return [];
    }
  }

  /// 刷新用户推荐
  Future<void> refreshUserRecommendations(String userId) async {
    try {
      debugPrint('🔄 刷新用户推荐: $userId');
      
      // 调用 Supabase 函数重新生成推荐
      await _client
          .rpc('refresh_user_recommendations', params: {
            'p_user_id': userId,
          });

      debugPrint('✅ 用户推荐刷新成功');
    } catch (e) {
      debugPrint('❌ 刷新用户推荐失败: $e');
    }
  }

  /// 获取推荐统计信息
  Future<Map<String, dynamic>> getRecommendationStats(String userId) async {
    try {
      debugPrint('📊 获取推荐统计: $userId');
      
      final response = await _client
          .rpc('get_recommendation_stats', params: {
            'p_user_id': userId,
          });

      final stats = response as Map<String, dynamic>;
      debugPrint('✅ 推荐统计获取成功');
      return stats;
    } catch (e) {
      debugPrint('❌ 获取推荐统计失败: $e');
      return {};
    }
  }

  /// 填充推荐内容的详细信息
  Future<void> _fillContentDetails(List<RecommendationItem> recommendations) async {
    try {
      final contentGroups = <String, List<RecommendationItem>>{};
      
      // 按内容类型分组
      for (final rec in recommendations) {
        contentGroups.putIfAbsent(rec.contentType, () => []).add(rec);
      }
      
      // 为每个内容类型批量获取详细信息
      for (final entry in contentGroups.entries) {
        final contentType = entry.key;
        final items = entry.value;
        final contentIds = items.map((item) => item.contentId).toList();
        
        await _fillContentDetailsForType(contentType, contentIds, items);
      }
    } catch (e) {
      debugPrint('❌ 填充内容详细信息失败: $e');
    }
  }

  /// 为特定内容类型填充详细信息
  Future<void> _fillContentDetailsForType(
    String contentType,
    List<String> contentIds,
    List<RecommendationItem> items,
  ) async {
    try {
      String tableName;
      List<String> selectColumns;
      
      switch (contentType) {
        case 'story':
          tableName = 'stories';
          selectColumns = ['story_id', 'title', 'description', 'author', 'thumbnail_url', 'tags'];
          break;
        case 'character':
          tableName = 'characters';
          selectColumns = ['character_id', 'name', 'description', 'creator', 'avatar_url', 'tags'];
          break;
        case 'template':
          tableName = 'templates';
          selectColumns = ['template_id', 'name', 'description', 'author', 'thumbnail_url', 'tags'];
          break;
        case 'ai_agent':
          tableName = 'custom_agents';
          selectColumns = ['agent_id', 'agent_name', 'description', 'user_id', 'avatar_url', 'tags'];
          break;
        default:
          debugPrint('⚠️ 未知内容类型: $contentType');
          return;
      }
      
      final response = await _client
          .from(tableName)
          .select(selectColumns.join(','))
          .inFilter(selectColumns.first, contentIds);
      
      final contentMap = <String, Map<String, dynamic>>{};
      for (final content in response as List) {
        final id = content[selectColumns.first] as String;
        contentMap[id] = content;
      }
      
      // 为每个推荐项设置内容详细信息
      for (final item in items) {
        final details = contentMap[item.contentId];
        if (details != null) {
          final updatedItem = item.withContentDetails(details);
          final index = items.indexOf(item);
          items[index] = updatedItem;
        }
      }
    } catch (e) {
      debugPrint('❌ 填充内容类型详细信息失败: $e');
    }
  }

  /// 获取推荐算法性能指标
  Future<Map<String, dynamic>> getAlgorithmPerformance() async {
    try {
      debugPrint('📈 获取推荐算法性能指标');
      
      final response = await _client
          .rpc('get_algorithm_performance');

      final performance = response as Map<String, dynamic>;
      debugPrint('✅ 算法性能指标获取成功');
      return performance;
    } catch (e) {
      debugPrint('❌ 获取算法性能失败: $e');
      return {};
    }
  }
}