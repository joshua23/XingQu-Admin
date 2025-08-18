import 'package:flutter/material.dart';
import '../models/recommendation_item.dart';
import '../services/recommendation_service.dart';

/// 推荐系统状态管理Provider
/// 管理个性化推荐、内容发现等功能
class RecommendationProvider with ChangeNotifier {
  final RecommendationService _recommendationService = RecommendationService();

  // 个性化推荐列表
  List<RecommendationItem> _personalizedRecommendations = [];
  List<RecommendationItem> get personalizedRecommendations => _personalizedRecommendations;

  // 热门推荐列表
  List<RecommendationItem> _popularRecommendations = [];
  List<RecommendationItem> get popularRecommendations => _popularRecommendations;

  // 趋势推荐列表
  List<RecommendationItem> _trendingRecommendations = [];
  List<RecommendationItem> get trendingRecommendations => _trendingRecommendations;

  // 混合推荐列表（综合推荐）
  List<RecommendationItem> _mixedRecommendations = [];
  List<RecommendationItem> get mixedRecommendations => _mixedRecommendations;

  // 相似内容推荐
  List<RecommendationItem> _similarContentRecommendations = [];
  List<RecommendationItem> get similarContentRecommendations => _similarContentRecommendations;

  // 智能推荐列表（用于综合页面）
  List<RecommendationItem> _smartRecommendations = [];
  List<RecommendationItem> get smartRecommendations => _smartRecommendations;

  // 通用推荐列表（用于兼容性）
  List<RecommendationItem> get recommendations => _mixedRecommendations.isEmpty ? _smartRecommendations : _mixedRecommendations;

  // 用户偏好设置
  Map<String, dynamic> _userPreferences = {};
  Map<String, dynamic> get userPreferences => _userPreferences;

  // 推荐统计信息
  Map<String, dynamic> _recommendationStats = {};
  Map<String, dynamic> get recommendationStats => _recommendationStats;

  // 加载状态
  bool _isLoadingPersonalized = false;
  bool _isLoadingPopular = false;
  bool _isLoadingTrending = false;
  bool _isLoadingMixed = false;
  bool _isLoadingSimilar = false;
  bool _isRefreshing = false;

  bool get isLoadingPersonalized => _isLoadingPersonalized;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingMixed => _isLoadingMixed;
  bool get isLoadingSimilar => _isLoadingSimilar;
  bool get isRefreshing => _isRefreshing;

  // 当前选中的内容类型过滤
  String? _selectedContentType;
  String? get selectedContentType => _selectedContentType;

  // 错误信息
  String? _error;
  String? get error => _error;

  /// 初始化推荐数据
  Future<void> initialize(String userId) async {
    await Future.wait([
      loadPersonalizedRecommendations(userId),
      loadPopularRecommendations(),
      loadUserPreferences(userId),
      loadRecommendationStats(userId),
    ]);
  }

  /// 加载个性化推荐
  Future<void> loadPersonalizedRecommendations(
    String userId, {
    String? contentType,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (_isLoadingPersonalized && !refresh) return;
    
    _isLoadingPersonalized = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final recommendations = await _recommendationService.getPersonalizedRecommendations(
        userId: userId,
        limit: limit,
        contentType: contentType ?? _selectedContentType,
      );

      if (refresh) {
        _personalizedRecommendations = recommendations;
      } else {
        _personalizedRecommendations.addAll(recommendations);
      }

      debugPrint('🎯 已加载 ${recommendations.length} 条个性化推荐');
    } catch (e) {
      _error = '加载个性化推荐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingPersonalized = false;
      notifyListeners();
    }
  }

  /// 加载热门推荐
  Future<void> loadPopularRecommendations({
    String? contentType,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (_isLoadingPopular && !refresh) return;
    
    _isLoadingPopular = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final recommendations = await _recommendationService.getPopularRecommendations(
        contentType: contentType ?? _selectedContentType,
        limit: limit,
      );

      if (refresh) {
        _popularRecommendations = recommendations;
      } else {
        _popularRecommendations.addAll(recommendations);
      }

      debugPrint('🔥 已加载 ${recommendations.length} 条热门推荐');
    } catch (e) {
      _error = '加载热门推荐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// 加载趋势推荐
  Future<void> loadTrendingRecommendations({
    String? contentType,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (_isLoadingTrending && !refresh) return;
    
    _isLoadingTrending = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final recommendations = await _recommendationService.getTrendingRecommendations(
        contentType: contentType ?? _selectedContentType,
        limit: limit,
      );

      if (refresh) {
        _trendingRecommendations = recommendations;
      } else {
        _trendingRecommendations.addAll(recommendations);
      }

      debugPrint('📈 已加载 ${recommendations.length} 条趋势推荐');
    } catch (e) {
      _error = '加载趋势推荐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// 加载混合推荐
  Future<void> loadMixedRecommendations(
    String userId, {
    String? contentType,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (_isLoadingMixed && !refresh) return;
    
    _isLoadingMixed = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final recommendations = await _recommendationService.getMixedRecommendations(
        userId: userId,
        contentType: contentType ?? _selectedContentType,
        limit: limit,
      );

      if (refresh) {
        _mixedRecommendations = recommendations;
      } else {
        _mixedRecommendations.addAll(recommendations);
      }

      debugPrint('🌈 已加载 ${recommendations.length} 条混合推荐');
    } catch (e) {
      _error = '加载混合推荐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingMixed = false;
      notifyListeners();
    }
  }

  /// 加载相似内容推荐
  Future<void> loadSimilarContentRecommendations({
    required String contentId,
    String? contentType,
    int limit = 10,
  }) async {
    if (_isLoadingSimilar) return;
    
    _isLoadingSimilar = true;
    _error = null;
    notifyListeners();

    try {
      _similarContentRecommendations = await _recommendationService.getSimilarContentRecommendations(
        contentId: contentId,
        contentType: contentType,
        limit: limit,
      );

      debugPrint('🔗 已加载 ${_similarContentRecommendations.length} 条相似内容推荐');
    } catch (e) {
      _error = '加载相似内容推荐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingSimilar = false;
      notifyListeners();
    }
  }

  /// 记录推荐点击
  Future<void> recordClick(String recommendationId) async {
    try {
      await _recommendationService.recordRecommendationClick(
        recommendationId: recommendationId,
      );

      // 更新本地状态，将对应的推荐项标记为已点击
      _updateRecommendationClickStatus(recommendationId);
      
      debugPrint('👆 推荐点击记录成功: $recommendationId');
    } catch (e) {
      debugPrint('❌ 记录推荐点击失败: $e');
    }
  }

  /// 提交用户反馈
  Future<void> submitFeedback({
    required String userId,
    required String contentId,
    required String feedbackType,
    String? reason,
  }) async {
    try {
      await _recommendationService.submitUserFeedback(
        userId: userId,
        contentId: contentId,
        feedbackType: feedbackType,
        reason: reason,
      );

      debugPrint('📝 用户反馈提交成功');
    } catch (e) {
      debugPrint('❌ 提交用户反馈失败: $e');
      throw Exception('提交反馈失败: $e');
    }
  }

  /// 更新用户偏好
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _recommendationService.updateUserPreferences(
        userId: userId,
        preferences: preferences,
      );

      _userPreferences = preferences;
      debugPrint('🔧 用户偏好更新成功');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 更新用户偏好失败: $e');
      throw Exception('更新偏好失败: $e');
    }
  }

  /// 加载用户偏好
  Future<void> loadUserPreferences(String userId) async {
    try {
      _userPreferences = await _recommendationService.getUserPreferences(userId);
      debugPrint('⚙️ 已加载用户偏好');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载用户偏好失败: $e');
    }
  }

  /// 刷新用户推荐
  Future<void> refreshRecommendations(String userId) async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      await _recommendationService.refreshUserRecommendations(userId);
      
      // 重新加载推荐数据
      await Future.wait([
        loadPersonalizedRecommendations(userId, refresh: true),
        loadMixedRecommendations(userId, refresh: true),
      ]);

      debugPrint('🔄 推荐数据刷新成功');
    } catch (e) {
      _error = '刷新推荐失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// 加载推荐统计
  Future<void> loadRecommendationStats(String userId) async {
    try {
      _recommendationStats = await _recommendationService.getRecommendationStats(userId);
      debugPrint('📊 已加载推荐统计');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载推荐统计失败: $e');
    }
  }

  /// 设置内容类型过滤
  void setContentTypeFilter(String? contentType) {
    if (_selectedContentType != contentType) {
      _selectedContentType = contentType;
      notifyListeners();
      
      // 可以选择自动重新加载推荐
      // 这里暂时不自动重新加载，由UI层决定何时调用
    }
  }

  /// 获取特定类型的推荐
  List<RecommendationItem> getRecommendationsByType(RecommendationAlgorithm type) {
    switch (type) {
      case RecommendationAlgorithm.collaborativeFiltering:
      case RecommendationAlgorithm.contentBased:
      case RecommendationAlgorithm.hybrid:
        return _personalizedRecommendations;
      case RecommendationAlgorithm.popularity:
        return _popularRecommendations;
      case RecommendationAlgorithm.trending:
        return _trendingRecommendations;
    }
  }

  /// 获取所有推荐（按分数排序）
  List<RecommendationItem> getAllRecommendations() {
    final allRecommendations = <RecommendationItem>[];
    allRecommendations.addAll(_personalizedRecommendations);
    allRecommendations.addAll(_popularRecommendations);
    allRecommendations.addAll(_trendingRecommendations);
    
    // 去重
    final uniqueRecommendations = <String, RecommendationItem>{};
    for (final rec in allRecommendations) {
      uniqueRecommendations[rec.contentId] = rec;
    }
    
    // 按推荐分数排序
    final sortedRecommendations = uniqueRecommendations.values.toList();
    sortedRecommendations.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));
    
    return sortedRecommendations;
  }

  /// 更新推荐点击状态
  void _updateRecommendationClickStatus(String recommendationId) {
    final allLists = [
      _personalizedRecommendations,
      _popularRecommendations,
      _trendingRecommendations,
      _mixedRecommendations,
      _similarContentRecommendations,
    ];

    for (final list in allLists) {
      final index = list.indexWhere((item) => item.recommendationId == recommendationId);
      if (index != -1) {
        list[index] = list[index].markAsClicked();
      }
    }

    notifyListeners();
  }

  /// 清除特定推荐列表
  void clearRecommendations(RecommendationAlgorithm type) {
    switch (type) {
      case RecommendationAlgorithm.collaborativeFiltering:
      case RecommendationAlgorithm.contentBased:
      case RecommendationAlgorithm.hybrid:
        _personalizedRecommendations.clear();
        break;
      case RecommendationAlgorithm.popularity:
        _popularRecommendations.clear();
        break;
      case RecommendationAlgorithm.trending:
        _trendingRecommendations.clear();
        break;
    }
    notifyListeners();
  }

  /// 清除所有推荐
  void clearAllRecommendations() {
    _personalizedRecommendations.clear();
    _popularRecommendations.clear();
    _trendingRecommendations.clear();
    _mixedRecommendations.clear();
    _similarContentRecommendations.clear();
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 检查是否有加载中的操作
  bool get isAnyLoading {
    return _isLoadingPersonalized ||
           _isLoadingPopular ||
           _isLoadingTrending ||
           _isLoadingMixed ||
           _isLoadingSimilar ||
           _isRefreshing;
  }

  /// 重置所有状态
  void reset() {
    _personalizedRecommendations.clear();
    _popularRecommendations.clear();
    _trendingRecommendations.clear();
    _mixedRecommendations.clear();
    _similarContentRecommendations.clear();
    _userPreferences.clear();
    _recommendationStats.clear();
    
    _isLoadingPersonalized = false;
    _isLoadingPopular = false;
    _isLoadingTrending = false;
    _isLoadingMixed = false;
    _isLoadingSimilar = false;
    _isRefreshing = false;
    
    _selectedContentType = null;
    _error = null;
    
    notifyListeners();
  }

  // 便捷方法

  /// 获取高分推荐（评分>=0.8）
  List<RecommendationItem> getHighScoreRecommendations() {
    return getAllRecommendations()
        .where((rec) => rec.recommendationLevel == RecommendationLevel.high)
        .toList();
  }

  /// 获取未点击的推荐
  List<RecommendationItem> getUnclickedRecommendations() {
    return getAllRecommendations()
        .where((rec) => !rec.isClicked)
        .toList();
  }

  /// 获取特定内容类型的推荐数量
  int getRecommendationCountByType(String contentType) {
    return getAllRecommendations()
        .where((rec) => rec.contentType == contentType)
        .length;
  }

  // ========== 综合页面专用方法 ==========

  /// 更新智能推荐列表
  void updateSmartRecommendations(List<RecommendationItem> recommendations) {
    _smartRecommendations = recommendations;
    notifyListeners();
  }

  /// 通用加载状态（用于兼容性）
  bool get isLoading => _isLoadingMixed || _isLoadingPersonalized || _isLoadingPopular;

  /// 初始化（公共内容，无需登录）
  Future<void> loadPublicRecommendations() async {
    await loadPopularRecommendations();
    await loadTrendingRecommendations();
  }

  /// 刷新所有推荐
  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await loadPopularRecommendations();
      await loadTrendingRecommendations();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// 加载更多推荐（分页）
  Future<void> loadMoreRecommendations(String userId) async {
    // TODO: 实现分页加载逻辑
    debugPrint('加载更多推荐内容...');
  }
}