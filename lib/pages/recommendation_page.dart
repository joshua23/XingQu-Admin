import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/recommendation_item.dart';
import '../providers/recommendation_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/recommendation_card.dart';

/// 推荐内容页面
class RecommendationPage extends StatefulWidget {
  const RecommendationPage({Key? key}) : super(key: key);

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabTitles = ['推荐', '热门', '趋势'];
  final List<String> _contentTypeFilters = ['全部', '故事', '角色', '模板', 'AI智能体'];
  String _selectedContentType = '全部';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      recommendationProvider.initialize(authProvider.currentUser!.id);
    } else {
      // 游客模式，只加载热门和趋势
      recommendationProvider.loadPopularRecommendations();
      recommendationProvider.loadTrendingRecommendations();
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreContent();
      }
    });
  }

  void _loadMoreContent() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;
    
    final currentTab = _tabController.index;
    final contentType = _selectedContentType == '全部' ? null : _getContentTypeValue(_selectedContentType);
    
    switch (currentTab) {
      case 0: // 推荐
        recommendationProvider.loadPersonalizedRecommendations(
          authProvider.currentUser!.id,
          contentType: contentType,
        );
        break;
      case 1: // 热门
        recommendationProvider.loadPopularRecommendations(contentType: contentType);
        break;
      case 2: // 趋势
        recommendationProvider.loadTrendingRecommendations(contentType: contentType);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('发现内容', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Tab栏
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
              ),
              
              // 内容类型过滤器
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '类型:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _contentTypeFilters.map((type) {
                            final isSelected = _selectedContentType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) => _onFilterChanged(type),
                                selectedColor: AppColors.primary.withOpacity(0.2),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.currentUser != null) {
                return IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                  onPressed: () => _refreshRecommendations(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, recommendationProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendationTab(recommendationProvider),
              _buildPopularTab(recommendationProvider),
              _buildTrendingTab(recommendationProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecommendationTab(RecommendationProvider provider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      return _buildGuestPrompt();
    }

    if (provider.isLoadingPersonalized && provider.personalizedRecommendations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.personalizedRecommendations.isEmpty) {
      return _buildEmptyState('暂无个性化推荐', '使用应用一段时间后，我们将为您推荐个性化内容');
    }

    return RefreshIndicator(
      onRefresh: () => _refreshPersonalizedRecommendations(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.personalizedRecommendations.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.personalizedRecommendations.length) {
            return _buildLoadingFooter(provider.isLoadingPersonalized);
          }
          
          final item = provider.personalizedRecommendations[index];
          return RecommendationCard(
            recommendation: item,
            onTap: () => _onRecommendationTap(item),
            onFeedback: (feedbackType, reason) => _submitFeedback(item, feedbackType, reason),
          );
        },
      ),
    );
  }

  Widget _buildPopularTab(RecommendationProvider provider) {
    if (provider.isLoadingPopular && provider.popularRecommendations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.popularRecommendations.isEmpty) {
      return _buildEmptyState('暂无热门内容', '热门内容正在更新中，请稍后查看');
    }

    return RefreshIndicator(
      onRefresh: () => _refreshPopularRecommendations(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.popularRecommendations.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.popularRecommendations.length) {
            return _buildLoadingFooter(provider.isLoadingPopular);
          }
          
          final item = provider.popularRecommendations[index];
          return RecommendationCard(
            recommendation: item,
            onTap: () => _onRecommendationTap(item),
            onFeedback: (feedbackType, reason) => _submitFeedback(item, feedbackType, reason),
          );
        },
      ),
    );
  }

  Widget _buildTrendingTab(RecommendationProvider provider) {
    if (provider.isLoadingTrending && provider.trendingRecommendations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.trendingRecommendations.isEmpty) {
      return _buildEmptyState('暂无趋势内容', '趋势内容正在分析中，请稍后查看');
    }

    return RefreshIndicator(
      onRefresh: () => _refreshTrendingRecommendations(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.trendingRecommendations.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.trendingRecommendations.length) {
            return _buildLoadingFooter(provider.isLoadingTrending);
          }
          
          final item = provider.trendingRecommendations[index];
          return RecommendationCard(
            recommendation: item,
            onTap: () => _onRecommendationTap(item),
            onFeedback: (feedbackType, reason) => _submitFeedback(item, feedbackType, reason),
          );
        },
      ),
    );
  }

  Widget _buildGuestPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '登录后查看个性化推荐',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '基于您的兴趣和使用习惯，为您推荐专属内容',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _navigateToLogin(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '立即登录',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingFooter(bool isLoading) {
    if (!isLoading) return const SizedBox.shrink();
    
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  void _onFilterChanged(String type) {
    setState(() => _selectedContentType = type);
    _applyFilter();
  }

  void _applyFilter() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    
    final contentType = _selectedContentType == '全部' ? null : _getContentTypeValue(_selectedContentType);
    
    // 清除当前数据并重新加载
    final currentTab = _tabController.index;
    switch (currentTab) {
      case 0: // 推荐
        if (authProvider.currentUser != null) {
          recommendationProvider.clearRecommendations(RecommendationAlgorithm.hybrid);
          recommendationProvider.loadPersonalizedRecommendations(
            authProvider.currentUser!.id,
            contentType: contentType,
            refresh: true,
          );
        }
        break;
      case 1: // 热门
        recommendationProvider.clearRecommendations(RecommendationAlgorithm.popularity);
        recommendationProvider.loadPopularRecommendations(
          contentType: contentType,
          refresh: true,
        );
        break;
      case 2: // 趋势
        recommendationProvider.clearRecommendations(RecommendationAlgorithm.trending);
        recommendationProvider.loadTrendingRecommendations(
          contentType: contentType,
          refresh: true,
        );
        break;
    }
  }

  String? _getContentTypeValue(String displayName) {
    switch (displayName) {
      case '故事':
        return 'story';
      case '角色':
        return 'character';
      case '模板':
        return 'template';
      case 'AI智能体':
        return 'ai_agent';
      default:
        return null;
    }
  }

  void _onRecommendationTap(RecommendationItem recommendation) {
    // 记录点击
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    recommendationProvider.recordClick(recommendation.recommendationId);
    
    // 根据内容类型导航到相应页面
    switch (recommendation.contentType) {
      case 'story':
        _navigateToStoryDetail(recommendation.contentId);
        break;
      case 'character':
        _navigateToCharacterDetail(recommendation.contentId);
        break;
      case 'template':
        _navigateToTemplateDetail(recommendation.contentId);
        break;
      case 'ai_agent':
        _navigateToAgentDetail(recommendation.contentId);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开${recommendation.contentTypeDisplayName}: ${recommendation.contentTitle}'),
            backgroundColor: AppColors.primary,
          ),
        );
    }
  }

  void _submitFeedback(RecommendationItem recommendation, String feedbackType, String? reason) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;
    
    try {
      final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
      await recommendationProvider.submitFeedback(
        userId: authProvider.currentUser!.id,
        contentId: recommendation.contentId,
        feedbackType: feedbackType,
        reason: reason,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('反馈已提交，感谢您的建议'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('反馈提交失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;
    
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    await recommendationProvider.refreshRecommendations(authProvider.currentUser!.id);
  }

  Future<void> _refreshPersonalizedRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;
    
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    final contentType = _selectedContentType == '全部' ? null : _getContentTypeValue(_selectedContentType);
    
    await recommendationProvider.loadPersonalizedRecommendations(
      authProvider.currentUser!.id,
      contentType: contentType,
      refresh: true,
    );
  }

  Future<void> _refreshPopularRecommendations() async {
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    final contentType = _selectedContentType == '全部' ? null : _getContentTypeValue(_selectedContentType);
    
    await recommendationProvider.loadPopularRecommendations(
      contentType: contentType,
      refresh: true,
    );
  }

  Future<void> _refreshTrendingRecommendations() async {
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    final contentType = _selectedContentType == '全部' ? null : _getContentTypeValue(_selectedContentType);
    
    await recommendationProvider.loadTrendingRecommendations(
      contentType: contentType,
      refresh: true,
    );
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _navigateToStoryDetail(String storyId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开故事详情: $storyId'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToCharacterDetail(String characterId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开角色详情: $characterId'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToTemplateDetail(String templateId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开模板详情: $templateId'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToAgentDetail(String agentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开智能体详情: $agentId'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}