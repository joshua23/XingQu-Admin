import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recommendation_item.dart';
import '../models/ai_character.dart';
import '../models/custom_agent.dart';
import 'supabase_service.dart';
import 'analytics_service.dart';

/// 增强版推荐系统服务
/// 提供智能个性化推荐、多维度算法和用户行为学习
class EnhancedRecommendationService {
  static final EnhancedRecommendationService _instance = EnhancedRecommendationService._internal();
  factory EnhancedRecommendationService() => _instance;
  EnhancedRecommendationService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // 缓存机制
  final Map<String, List<RecommendationItem>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  /// 获取智能个性化推荐
  /// 综合用户行为、偏好、时间因素等多维度数据
  Future<List<RecommendationItem>> getSmartRecommendations({
    required String userId,
    String? contentType,
    int limit = 20,
    bool includePopular = true,
    bool includeTrending = true,
    bool includePersonalized = true,
  }) async {
    try {
      debugPrint('🧠 获取智能推荐: userId=$userId, type=$contentType');

      // 检查缓存
      final cacheKey = 'smart_$userId${contentType ?? ''}_$limit';
      if (_isCacheValid(cacheKey)) {
        debugPrint('📦 使用缓存数据');
        return _cache[cacheKey]!;
      }

      final recommendations = <RecommendationItem>[];

      // 1. 个性化推荐（基于用户行为）
      if (includePersonalized) {
        final personalizedItems = await _getPersonalizedRecommendations(
          userId: userId,
          contentType: contentType,
          limit: (limit * 0.5).round(),
        );
        recommendations.addAll(personalizedItems);
      }

      // 2. 热门内容推荐
      if (includePopular) {
        final popularItems = await _getPopularRecommendations(
          contentType: contentType,
          limit: (limit * 0.3).round(),
          excludeIds: recommendations.map((r) => r.contentId).toList(),
        );
        recommendations.addAll(popularItems);
      }

      // 3. 趋势内容推荐
      if (includeTrending) {
        final trendingItems = await _getTrendingRecommendations(
          contentType: contentType,
          limit: limit - recommendations.length,
          excludeIds: recommendations.map((r) => r.contentId).toList(),
        );
        recommendations.addAll(trendingItems);
      }

      // 4. 智能排序和去重
      final finalRecommendations = await _smartSort(recommendations, userId);
      
      // 填充内容详情
      await _fillContentDetails(finalRecommendations);
      
      // 更新缓存
      _updateCache(cacheKey, finalRecommendations);

      // 记录推荐事件
      await _analyticsService.trackEvent('recommendations_generated', {
        'user_id': userId,
        'content_type': contentType,
        'count': finalRecommendations.length,
        'algorithm_types': _getAlgorithmTypes(finalRecommendations),
      });

      debugPrint('✅ 生成 ${finalRecommendations.length} 条智能推荐');
      return finalRecommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ 智能推荐失败: $e');
      // 降级到基础推荐
      return await _getFallbackRecommendations(contentType: contentType, limit: limit);
    }
  }

  /// 获取个性化推荐（基于用户画像和行为）
  Future<List<RecommendationItem>> _getPersonalizedRecommendations({
    required String userId,
    String? contentType,
    required int limit,
  }) async {
    try {
      // 获取用户行为数据
      final userBehavior = await _getUserBehaviorProfile(userId);
      
      // 获取用户偏好标签
      final userPreferences = await _getUserPreferences(userId);
      
      // 基于协同过滤的推荐
      final collaborativeItems = await _getCollaborativeFilteringRecommendations(
        userId: userId,
        contentType: contentType,
        limit: (limit * 0.6).round(),
        userBehavior: userBehavior,
      );
      
      // 基于内容相似性的推荐
      final contentBasedItems = await _getContentBasedRecommendations(
        userId: userId,
        contentType: contentType,
        limit: limit - collaborativeItems.length,
        userPreferences: userPreferences,
      );
      
      return [...collaborativeItems, ...contentBasedItems];
    } catch (e) {
      debugPrint('❌ 获取个性化推荐失败: $e');
      return [];
    }
  }

  /// 协同过滤推荐算法
  Future<List<RecommendationItem>> _getCollaborativeFilteringRecommendations({
    required String userId,
    String? contentType,
    required int limit,
    required Map<String, dynamic> userBehavior,
  }) async {
    try {
      // 查找相似用户
      final similarUsers = await _findSimilarUsers(userId, userBehavior);
      
      if (similarUsers.isEmpty) return [];
      
      // 获取相似用户喜欢的内容
      var query = _client
          .from('user_interactions')
          .select('content_id, content_type, interaction_type, COUNT(*)')
          .inFilter('user_id', similarUsers.map((u) => u['user_id']).toList())
          .eq('interaction_type', 'like')
          .neq('user_id', userId); // 排除自己
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      final response = await query
          .order('COUNT(*)', ascending: false)
          .limit(limit);
      
      final recommendations = <RecommendationItem>[];
      
      for (final item in response) {
        recommendations.add(RecommendationItem(
          recommendationId: _generateRecommendationId(),
          userId: userId,
          contentId: item['content_id'],
          contentType: item['content_type'],
          algorithmType: 'collaborative_filtering',
          recommendationScore: _calculateCollaborativeScore(item, similarUsers),
          positionRank: recommendations.length + 1,
          recommendationReason: '因为与你兴趣相似的用户也喜欢',
          isClicked: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ));
      }
      
      return recommendations;
    } catch (e) {
      debugPrint('❌ 协同过滤推荐失败: $e');
      return [];
    }
  }

  /// 基于内容的推荐算法
  Future<List<RecommendationItem>> _getContentBasedRecommendations({
    required String userId,
    String? contentType,
    required int limit,
    required Map<String, dynamic> userPreferences,
  }) async {
    try {
      // 获取用户喜欢的内容特征
      final likedContent = await _getUserLikedContent(userId);
      if (likedContent.isEmpty) return [];
      
      // 提取内容特征向量
      final contentFeatures = await _extractContentFeatures(likedContent);
      
      // 查找相似内容
      var query = _client
          .from('content_similarity')
          .select('content_id, similarity_score, tags, category')
          .inFilter('base_content_id', likedContent.map((c) => c['content_id']).toList());
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      final response = await query
          .gte('similarity_score', 0.6) // 相似度阈值
          .order('similarity_score', ascending: false)
          .limit(limit * 2); // 多获取一些用于筛选
      
      final recommendations = <RecommendationItem>[];
      
      for (final item in response) {
        final score = _calculateContentBasedScore(item, contentFeatures, userPreferences);
        
        recommendations.add(RecommendationItem(
          recommendationId: _generateRecommendationId(),
          userId: userId,
          contentId: item['content_id'],
          contentType: contentType ?? 'unknown',
          algorithmType: 'content_based',
          recommendationScore: score,
          positionRank: recommendations.length + 1,
          recommendationReason: '基于你的兴趣偏好推荐',
          isClicked: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ));
      }
      
      // 按分数排序并取前N个
      recommendations.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));
      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ 基于内容推荐失败: $e');
      return [];
    }
  }

  /// 获取热门推荐
  Future<List<RecommendationItem>> _getPopularRecommendations({
    String? contentType,
    required int limit,
    List<String> excludeIds = const [],
  }) async {
    try {
      var query = _client
          .from('content_stats')
          .select('content_id, content_type, popularity_score, view_count, like_count')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      if (excludeIds.isNotEmpty) {
        query = query.not('content_id', 'in', '(${excludeIds.join(',')})');
      }
      
      final response = await query
          .order('popularity_score', ascending: false)
          .limit(limit);
      
      return (response as List).map((item) {
        return RecommendationItem(
          recommendationId: _generateRecommendationId(),
          userId: '', // 热门推荐不特定于用户
          contentId: item['content_id'],
          contentType: item['content_type'],
          algorithmType: 'popularity',
          recommendationScore: item['popularity_score']?.toDouble() ?? 0.0,
          positionRank: 0, // 会在后续排序中更新
          recommendationReason: '当前热门内容',
          isClicked: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ 获取热门推荐失败: $e');
      return [];
    }
  }

  /// 获取趋势推荐
  Future<List<RecommendationItem>> _getTrendingRecommendations({
    String? contentType,
    required int limit,
    List<String> excludeIds = const [],
  }) async {
    try {
      // 计算24小时内的增长趋势
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      var query = _client
          .from('content_trends')
          .select('content_id, content_type, growth_rate, momentum_score')
          .gte('calculated_at', yesterday.toIso8601String())
          .gte('growth_rate', 1.2); // 增长率阈值
          
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      if (excludeIds.isNotEmpty) {
        query = query.not('content_id', 'in', '(${excludeIds.join(',')})');
      }
      
      final response = await query
          .order('momentum_score', ascending: false)
          .limit(limit);
      
      return (response as List).map((item) {
        return RecommendationItem(
          recommendationId: _generateRecommendationId(),
          userId: '', // 趋势推荐不特定于用户
          contentId: item['content_id'],
          contentType: item['content_type'],
          algorithmType: 'trending',
          recommendationScore: item['momentum_score']?.toDouble() ?? 0.0,
          positionRank: 0, // 会在后续排序中更新
          recommendationReason: '正在快速流行',
          isClicked: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 6)),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ 获取趋势推荐失败: $e');
      return [];
    }
  }

  /// 智能排序算法
  Future<List<RecommendationItem>> _smartSort(List<RecommendationItem> items, String userId) async {
    try {
      // 获取用户活跃时段
      final userActiveHours = await _getUserActiveHours(userId);
      final currentHour = DateTime.now().hour;
      
      // 获取用户多样性偏好
      final diversityFactor = await _getUserDiversityPreference(userId);
      
      // 综合评分排序
      items.sort((a, b) {
        double scoreA = a.recommendationScore;
        double scoreB = b.recommendationScore;
        
        // 时段加权
        if (userActiveHours.contains(currentHour)) {
          if (a.algorithmType == 'personalized') scoreA *= 1.2;
          if (b.algorithmType == 'personalized') scoreB *= 1.2;
        }
        
        // 多样性调整
        final algorithmPenalty = _calculateDiversityPenalty(a, b, items, diversityFactor);
        scoreA -= algorithmPenalty['a']!;
        scoreB -= algorithmPenalty['b']!;
        
        return scoreB.compareTo(scoreA);
      });
      
      // 更新位置排名
      for (int i = 0; i < items.length; i++) {
        items[i] = RecommendationItem(
          recommendationId: items[i].recommendationId,
          userId: items[i].userId,
          contentId: items[i].contentId,
          contentType: items[i].contentType,
          algorithmType: items[i].algorithmType,
          recommendationScore: items[i].recommendationScore,
          positionRank: i + 1,
          recommendationReason: items[i].recommendationReason,
          isClicked: items[i].isClicked,
          createdAt: items[i].createdAt,
          expiresAt: items[i].expiresAt,
        );
      }
      
      // 去重（保持评分最高的）
      final seenContentIds = <String>{};
      return items.where((item) {
        if (seenContentIds.contains(item.contentId)) {
          return false;
        }
        seenContentIds.add(item.contentId);
        return true;
      }).toList();
    } catch (e) {
      debugPrint('❌ 智能排序失败: $e');
      return items;
    }
  }

  /// 填充内容详情
  Future<void> _fillContentDetails(List<RecommendationItem> recommendations) async {
    // 根据内容类型分组
    final groupedByType = <String, List<RecommendationItem>>{};
    for (final rec in recommendations) {
      groupedByType.putIfAbsent(rec.contentType, () => []).add(rec);
    }
    
    // 批量查询不同类型的内容详情
    for (final entry in groupedByType.entries) {
      final contentType = entry.key;
      final items = entry.value;
      
      try {
        switch (contentType) {
          case 'agent':
            await _fillAgentDetails(items);
            break;
          case 'character':
            await _fillCharacterDetails(items);
            break;
          // 添加其他内容类型...
        }
      } catch (e) {
        debugPrint('❌ 填充 $contentType 详情失败: $e');
      }
    }
  }

  /// 填充智能体详情
  Future<void> _fillAgentDetails(List<RecommendationItem> items) async {
    final contentIds = items.map((item) => item.contentId).toList();
    
    final response = await _client
        .from('custom_agents')
        .select()
        .inFilter('id', contentIds);
    
    final agentsMap = {
      for (final agent in response)
        agent['id']: CustomAgent.fromJson(agent)
    };
    
    // 更新推荐项的详情
    for (final item in items) {
      final agent = agentsMap[item.contentId];
      if (agent != null) {
        // 可以在这里设置额外的详情信息
        // 例如：item.contentDetails = agent.toJson();
      }
    }
  }

  /// 填充AI角色详情
  Future<void> _fillCharacterDetails(List<RecommendationItem> items) async {
    final contentIds = items.map((item) => item.contentId).toList();
    
    final response = await _client
        .from('ai_characters')
        .select()
        .inFilter('id', contentIds);
    
    final charactersMap = {
      for (final character in response)
        character['id']: AICharacter.fromJson(character)
    };
    
    // 更新推荐项的详情
    for (final item in items) {
      final character = charactersMap[item.contentId];
      if (character != null) {
        // 可以在这里设置额外的详情信息
      }
    }
  }

  /// 降级推荐方案
  Future<List<RecommendationItem>> _getFallbackRecommendations({
    String? contentType,
    required int limit,
  }) async {
    try {
      debugPrint('🔄 使用降级推荐方案');
      
      // 简单的热门内容推荐
      var query = _client.from('content_stats').select();
      
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      
      final response = await query
          .order('view_count', ascending: false)
          .limit(limit);
      
      return (response as List).map((item) {
        return RecommendationItem(
          recommendationId: _generateRecommendationId(),
          userId: '',
          contentId: item['content_id'] ?? '',
          contentType: item['content_type'] ?? contentType ?? 'unknown',
          algorithmType: 'fallback',
          recommendationScore: (item['view_count'] ?? 0).toDouble(),
          positionRank: 0,
          recommendationReason: '推荐内容',
          isClicked: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ 降级推荐也失败: $e');
      return [];
    }
  }

  // ========== 辅助方法 ==========

  /// 缓存相关方法
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTime.containsKey(key)) {
      return false;
    }
    
    final age = DateTime.now().difference(_cacheTime[key]!);
    return age < _cacheValidDuration;
  }

  void _updateCache(String key, List<RecommendationItem> items) {
    _cache[key] = items;
    _cacheTime[key] = DateTime.now();
  }

  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  /// 生成推荐ID
  String _generateRecommendationId() {
    return 'rec_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// 获取算法类型统计
  List<String> _getAlgorithmTypes(List<RecommendationItem> recommendations) {
    return recommendations.map((r) => r.algorithmType).toSet().toList();
  }

  /// 获取用户行为画像
  Future<Map<String, dynamic>> _getUserBehaviorProfile(String userId) async {
    // 这里实现用户行为分析逻辑
    return {};
  }

  /// 获取用户偏好
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    // 这里实现用户偏好分析逻辑
    return {};
  }

  /// 查找相似用户
  Future<List<Map<String, dynamic>>> _findSimilarUsers(String userId, Map<String, dynamic> userBehavior) async {
    // 这里实现相似用户查找逻辑
    return [];
  }

  /// 计算协同过滤分数
  double _calculateCollaborativeScore(Map<String, dynamic> item, List<Map<String, dynamic>> similarUsers) {
    // 这里实现协同过滤评分逻辑
    return (item['COUNT(*)'] ?? 1).toDouble();
  }

  /// 获取用户喜欢的内容
  Future<List<Map<String, dynamic>>> _getUserLikedContent(String userId) async {
    // 这里实现用户喜欢内容查询逻辑
    return [];
  }

  /// 提取内容特征
  Future<Map<String, dynamic>> _extractContentFeatures(List<Map<String, dynamic>> content) async {
    // 这里实现内容特征提取逻辑
    return {};
  }

  /// 计算基于内容的分数
  double _calculateContentBasedScore(Map<String, dynamic> item, Map<String, dynamic> features, Map<String, dynamic> preferences) {
    // 这里实现内容相似度评分逻辑
    return (item['similarity_score'] ?? 0.5).toDouble();
  }

  /// 获取用户活跃时段
  Future<List<int>> _getUserActiveHours(String userId) async {
    // 这里实现用户活跃时段分析
    return List.generate(24, (i) => i); // 默认全天活跃
  }

  /// 获取用户多样性偏好
  Future<double> _getUserDiversityPreference(String userId) async {
    // 这里实现多样性偏好分析
    return 0.3; // 默认中等多样性
  }

  /// 计算多样性惩罚
  Map<String, double> _calculateDiversityPenalty(RecommendationItem a, RecommendationItem b, List<RecommendationItem> allItems, double diversityFactor) {
    // 这里实现多样性惩罚计算逻辑
    return {'a': 0.0, 'b': 0.0};
  }
}