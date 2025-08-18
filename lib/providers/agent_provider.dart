import 'package:flutter/material.dart';
import '../models/custom_agent.dart';
import '../services/agent_management_service.dart';

/// AI智能体状态管理Provider
/// 管理智能体创建、使用、配置等功能
class AgentProvider with ChangeNotifier {
  final AgentManagementService _agentService = AgentManagementService();

  // 用户的智能体列表
  List<CustomAgent> _userAgents = [];
  List<CustomAgent> get userAgents => _userAgents;

  // 公开的智能体列表
  List<CustomAgent> _publicAgents = [];
  List<CustomAgent> get publicAgents => _publicAgents;

  // 热门智能体列表
  List<CustomAgent> _popularAgents = [];
  List<CustomAgent> get popularAgents => _popularAgents;

  // 高评分智能体列表
  List<CustomAgent> _highRatedAgents = [];
  List<CustomAgent> get highRatedAgents => _highRatedAgents;

  // 推荐智能体列表
  List<CustomAgent> _recommendedAgents = [];
  List<CustomAgent> get recommendedAgents => _recommendedAgents;

  // 当前选中/查看的智能体
  CustomAgent? _currentAgent;
  CustomAgent? get currentAgent => _currentAgent;

  // 智能体分类列表
  List<String> _categories = [];
  List<String> get categories => _categories;

  // 智能体评分列表
  List<Map<String, dynamic>> _agentRatings = [];
  List<Map<String, dynamic>> get agentRatings => _agentRatings;

  // 用户智能体使用历史
  List<Map<String, dynamic>> _usageHistory = [];
  List<Map<String, dynamic>> get usageHistory => _usageHistory;

  // 智能体统计信息
  Map<String, dynamic> _agentStats = {};
  Map<String, dynamic> get agentStats => _agentStats;

  // 加载状态
  bool _isLoadingUserAgents = false;
  bool _isLoadingPublicAgents = false;
  bool _isLoadingPopular = false;
  bool _isLoadingHighRated = false;
  bool _isLoadingRecommended = false;
  bool _isCreatingAgent = false;
  bool _isUpdatingAgent = false;

  bool get isLoadingUserAgents => _isLoadingUserAgents;
  bool get isLoadingPublicAgents => _isLoadingPublicAgents;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingHighRated => _isLoadingHighRated;
  bool get isLoadingRecommended => _isLoadingRecommended;
  bool get isCreatingAgent => _isCreatingAgent;
  bool get isUpdatingAgent => _isUpdatingAgent;

  // 搜索和过滤状态
  String? _searchQuery;
  String? _selectedCategory;
  String? get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  // 错误信息
  String? _error;
  String? get error => _error;

  /// 初始化智能体数据
  Future<void> initialize(String userId) async {
    await Future.wait([
      loadUserAgents(userId),
      loadPublicAgents(),
      loadCategories(),
      loadUserUsageHistory(userId),
    ]);
  }

  /// 加载用户的智能体
  Future<void> loadUserAgents(String userId) async {
    if (_isLoadingUserAgents) return;
    
    _isLoadingUserAgents = true;
    _error = null;
    notifyListeners();

    try {
      _userAgents = await _agentService.getUserAgents(userId);
      debugPrint('👤 已加载 ${_userAgents.length} 个用户智能体');
    } catch (e) {
      _error = '加载用户智能体失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingUserAgents = false;
      notifyListeners();
    }
  }

  /// 加载公开智能体
  Future<void> loadPublicAgents({
    int limit = 50,
    String? category,
    String? searchQuery,
  }) async {
    if (_isLoadingPublicAgents) return;
    
    _isLoadingPublicAgents = true;
    _error = null;
    notifyListeners();

    try {
      _publicAgents = await _agentService.getPublicAgents(
        limit: limit,
        category: category ?? _selectedCategory,
        searchQuery: searchQuery ?? _searchQuery,
      );
      debugPrint('🌍 已加载 ${_publicAgents.length} 个公开智能体');
    } catch (e) {
      _error = '加载公开智能体失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingPublicAgents = false;
      notifyListeners();
    }
  }

  /// 加载热门智能体
  Future<void> loadPopularAgents({int limit = 20}) async {
    if (_isLoadingPopular) return;
    
    _isLoadingPopular = true;
    _error = null;
    notifyListeners();

    try {
      _popularAgents = await _agentService.getPopularAgents(limit: limit);
      debugPrint('🔥 已加载 ${_popularAgents.length} 个热门智能体');
    } catch (e) {
      _error = '加载热门智能体失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// 加载高评分智能体
  Future<void> loadHighRatedAgents({int limit = 20}) async {
    if (_isLoadingHighRated) return;
    
    _isLoadingHighRated = true;
    _error = null;
    notifyListeners();

    try {
      _highRatedAgents = await _agentService.getHighRatedAgents(limit: limit);
      debugPrint('⭐ 已加载 ${_highRatedAgents.length} 个高评分智能体');
    } catch (e) {
      _error = '加载高评分智能体失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingHighRated = false;
      notifyListeners();
    }
  }

  /// 加载推荐智能体
  Future<void> loadRecommendedAgents(String userId, {int limit = 10}) async {
    if (_isLoadingRecommended) return;
    
    _isLoadingRecommended = true;
    _error = null;
    notifyListeners();

    try {
      _recommendedAgents = await _agentService.getRecommendedAgents(
        userId: userId,
        limit: limit,
      );
      debugPrint('🎯 已加载 ${_recommendedAgents.length} 个推荐智能体');
    } catch (e) {
      _error = '加载推荐智能体失败: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoadingRecommended = false;
      notifyListeners();
    }
  }

  /// 创建智能体
  Future<CustomAgent?> createAgent({
    required String userId,
    required String agentName,
    required String description,
    required String systemPrompt,
    required Map<String, dynamic> configuration,
    String? avatarUrl,
    List<String>? capabilities,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    if (_isCreatingAgent) return null;
    
    _isCreatingAgent = true;
    _error = null;
    notifyListeners();

    try {
      final agent = await _agentService.createCustomAgent(
        userId: userId,
        agentName: agentName,
        description: description,
        systemPrompt: systemPrompt,
        configuration: configuration,
        avatarUrl: avatarUrl,
        capabilities: capabilities,
        tags: tags,
        isPublic: isPublic,
      );

      // 添加到用户智能体列表
      _userAgents.insert(0, agent);
      
      debugPrint('🤖 智能体创建成功: ${agent.agentName}');
      return agent;
    } catch (e) {
      _error = '创建智能体失败: $e';
      debugPrint('❌ $_error');
      return null;
    } finally {
      _isCreatingAgent = false;
      notifyListeners();
    }
  }

  /// 更新智能体
  Future<bool> updateAgent({
    required String agentId,
    String? agentName,
    String? description,
    String? systemPrompt,
    Map<String, dynamic>? configuration,
    String? avatarUrl,
    List<String>? capabilities,
    List<String>? tags,
    bool? isPublic,
    bool? isActive,
  }) async {
    if (_isUpdatingAgent) return false;
    
    _isUpdatingAgent = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAgent = await _agentService.updateAgent(
        agentId: agentId,
        agentName: agentName,
        description: description,
        systemPrompt: systemPrompt,
        configuration: configuration,
        avatarUrl: avatarUrl,
        capabilities: capabilities,
        tags: tags,
        isPublic: isPublic,
        isActive: isActive,
      );

      // 更新本地列表中的智能体
      _updateAgentInLists(updatedAgent);
      
      debugPrint('🔧 智能体更新成功: ${updatedAgent.agentName}');
      return true;
    } catch (e) {
      _error = '更新智能体失败: $e';
      debugPrint('❌ $_error');
      return false;
    } finally {
      _isUpdatingAgent = false;
      notifyListeners();
    }
  }

  /// 删除智能体
  Future<bool> deleteAgent(String agentId) async {
    try {
      await _agentService.deleteAgent(agentId);
      
      // 从所有列表中移除
      _userAgents.removeWhere((agent) => agent.agentId == agentId);
      _publicAgents.removeWhere((agent) => agent.agentId == agentId);
      _popularAgents.removeWhere((agent) => agent.agentId == agentId);
      _highRatedAgents.removeWhere((agent) => agent.agentId == agentId);
      _recommendedAgents.removeWhere((agent) => agent.agentId == agentId);
      
      // 如果是当前选中的智能体，清除选择
      if (_currentAgent?.agentId == agentId) {
        _currentAgent = null;
      }
      
      debugPrint('🗑️ 智能体删除成功');
      notifyListeners();
      return true;
    } catch (e) {
      _error = '删除智能体失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// 设置当前智能体
  Future<void> setCurrentAgent(String agentId) async {
    try {
      _currentAgent = await _agentService.getAgentById(agentId);
      if (_currentAgent != null) {
        // 加载智能体详细信息
        await Future.wait([
          loadAgentRatings(agentId),
          loadAgentStats(agentId),
        ]);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 设置当前智能体失败: $e');
    }
  }

  /// 记录智能体使用
  Future<void> recordAgentUsage(String agentId) async {
    try {
      await _agentService.recordAgentUsage(agentId);
      
      // 更新本地智能体的使用次数
      _updateAgentUsageCount(agentId);
      
      debugPrint('📊 智能体使用记录成功');
    } catch (e) {
      debugPrint('❌ 记录智能体使用失败: $e');
    }
  }

  /// 为智能体评分
  Future<bool> rateAgent({
    required String agentId,
    required String userId,
    required double rating,
    String? review,
  }) async {
    try {
      await _agentService.rateAgent(
        agentId: agentId,
        userId: userId,
        rating: rating,
        review: review,
      );

      // 重新加载评分信息
      await loadAgentRatings(agentId);
      
      debugPrint('⭐ 智能体评分成功');
      return true;
    } catch (e) {
      _error = '智能体评分失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// 复制智能体
  Future<CustomAgent?> cloneAgent({
    required String sourceAgentId,
    required String userId,
    String? newName,
  }) async {
    try {
      final clonedAgent = await _agentService.cloneAgent(
        sourceAgentId: sourceAgentId,
        userId: userId,
        newName: newName,
      );

      // 添加到用户智能体列表
      _userAgents.insert(0, clonedAgent);
      
      debugPrint('📋 智能体复制成功: ${clonedAgent.agentName}');
      notifyListeners();
      return clonedAgent;
    } catch (e) {
      _error = '复制智能体失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return null;
    }
  }

  /// 加载智能体分类
  Future<void> loadCategories() async {
    try {
      _categories = await _agentService.getAgentCategories();
      debugPrint('📂 已加载 ${_categories.length} 个智能体分类');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载智能体分类失败: $e');
    }
  }

  /// 加载智能体评分
  Future<void> loadAgentRatings(String agentId) async {
    try {
      _agentRatings = await _agentService.getAgentRatings(agentId);
      debugPrint('📝 已加载 ${_agentRatings.length} 条评分');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载智能体评分失败: $e');
    }
  }

  /// 加载智能体统计
  Future<void> loadAgentStats(String agentId) async {
    try {
      _agentStats = await _agentService.getAgentStats(agentId);
      debugPrint('📊 已加载智能体统计');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载智能体统计失败: $e');
    }
  }

  /// 加载用户使用历史
  Future<void> loadUserUsageHistory(String userId) async {
    try {
      _usageHistory = await _agentService.getUserAgentHistory(userId);
      debugPrint('📈 已加载 ${_usageHistory.length} 条使用记录');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载使用历史失败: $e');
    }
  }

  /// 设置搜索查询
  void setSearchQuery(String? query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// 设置分类过滤
  void setSelectedCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// 执行搜索
  Future<void> search({String? query, String? category}) async {
    setSearchQuery(query);
    setSelectedCategory(category);
    await loadPublicAgents(category: category, searchQuery: query);
  }

  /// 导出智能体配置
  Future<Map<String, dynamic>?> exportAgentConfig(String agentId) async {
    try {
      return await _agentService.exportAgentConfig(agentId);
    } catch (e) {
      _error = '导出智能体配置失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return null;
    }
  }

  /// 导入智能体配置
  Future<CustomAgent?> importAgentConfig({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    try {
      final agent = await _agentService.importAgentConfig(
        userId: userId,
        config: config,
      );

      // 添加到用户智能体列表
      _userAgents.insert(0, agent);
      
      debugPrint('📥 智能体配置导入成功');
      notifyListeners();
      return agent;
    } catch (e) {
      _error = '导入智能体配置失败: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return null;
    }
  }

  /// 更新智能体在所有列表中的信息
  void _updateAgentInLists(CustomAgent updatedAgent) {
    final updateList = (List<CustomAgent> list) {
      final index = list.indexWhere((agent) => agent.agentId == updatedAgent.agentId);
      if (index != -1) {
        list[index] = updatedAgent;
      }
    };

    updateList(_userAgents);
    updateList(_publicAgents);
    updateList(_popularAgents);
    updateList(_highRatedAgents);
    updateList(_recommendedAgents);

    if (_currentAgent?.agentId == updatedAgent.agentId) {
      _currentAgent = updatedAgent;
    }
  }

  /// 更新智能体使用次数
  void _updateAgentUsageCount(String agentId) {
    final updateUsageCount = (List<CustomAgent> list) {
      final index = list.indexWhere((agent) => agent.agentId == agentId);
      if (index != -1) {
        list[index] = list[index].incrementUsage();
      }
    };

    updateUsageCount(_userAgents);
    updateUsageCount(_publicAgents);
    updateUsageCount(_popularAgents);
    updateUsageCount(_highRatedAgents);
    updateUsageCount(_recommendedAgents);

    if (_currentAgent?.agentId == agentId) {
      _currentAgent = _currentAgent!.incrementUsage();
    }

    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 清除当前智能体
  void clearCurrentAgent() {
    _currentAgent = null;
    _agentRatings.clear();
    _agentStats.clear();
    notifyListeners();
  }

  /// 检查是否有加载中的操作
  bool get isAnyLoading {
    return _isLoadingUserAgents ||
           _isLoadingPublicAgents ||
           _isLoadingPopular ||
           _isLoadingHighRated ||
           _isLoadingRecommended ||
           _isCreatingAgent ||
           _isUpdatingAgent;
  }

  /// 重置所有状态
  void reset() {
    _userAgents.clear();
    _publicAgents.clear();
    _popularAgents.clear();
    _highRatedAgents.clear();
    _recommendedAgents.clear();
    _currentAgent = null;
    _categories.clear();
    _agentRatings.clear();
    _usageHistory.clear();
    _agentStats.clear();
    
    _isLoadingUserAgents = false;
    _isLoadingPublicAgents = false;
    _isLoadingPopular = false;
    _isLoadingHighRated = false;
    _isLoadingRecommended = false;
    _isCreatingAgent = false;
    _isUpdatingAgent = false;
    
    _searchQuery = null;
    _selectedCategory = null;
    _error = null;
    
    notifyListeners();
  }

  // 便捷方法

  /// 获取用户活跃的智能体
  List<CustomAgent> get activeUserAgents {
    return _userAgents.where((agent) => agent.isActive).toList();
  }

  /// 获取用户公开的智能体
  List<CustomAgent> get publicUserAgents {
    return _userAgents.where((agent) => agent.isPublic).toList();
  }

  /// 获取最近使用的智能体
  List<CustomAgent> get recentlyUsedAgents {
    return _userAgents.where((agent) => agent.isRecentlyActive).toList();
  }

  /// 根据ID查找智能体
  CustomAgent? findAgentById(String agentId) {
    final allAgents = [
      ..._userAgents,
      ..._publicAgents,
      ..._popularAgents,
      ..._highRatedAgents,
      ..._recommendedAgents,
    ];

    try {
      return allAgents.firstWhere((agent) => agent.agentId == agentId);
    } catch (e) {
      return null;
    }
  }
}