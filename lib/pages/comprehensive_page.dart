import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/agent_provider.dart';
import '../widgets/enhanced_vip_membership_card.dart';
import '../widgets/agent_search_bar.dart';
import '../widgets/agent_card.dart';
import '../widgets/recommendation_card.dart';
import '../services/analytics_service.dart';
import '../services/enhanced_recommendation_service.dart';
import 'subscription_plans_page.dart';
import 'agent_marketplace_page.dart';
// import 'recommendation_page.dart'; // 暂未使用

/// 综合页面 - Sprint 3商业化功能集成
/// 展示会员权益、推荐内容、智能体市场等核心功能
class ComprehensivePage extends StatefulWidget {
  const ComprehensivePage({super.key});

  @override
  State<ComprehensivePage> createState() => _ComprehensivePageState();
}

class _ComprehensivePageState extends State<ComprehensivePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  final ScrollController _scrollController = ScrollController();
  final EnhancedRecommendationService _recommendationService = EnhancedRecommendationService();
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedCategory = '全部';
  String? _sortBy = 'popular';

  final List<String> _categories = [
    '全部',
    '会员专享',
    '热门推荐',
    '智能体',
    '个性化',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializePage();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 初始化页面数据
  void _initializePage() async {
    await _analyticsService.trackPageView('comprehensive_page');
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      await _loadUserData();
    } else {
      await _loadPublicData();
    }
    
    setState(() => _isLoading = false);
  }

  /// 加载用户数据
  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id;
    
    await Future.wait([
      context.read<SubscriptionProvider>().initialize(userId),
      context.read<RecommendationProvider>().initialize(userId),
      context.read<AgentProvider>().initialize(userId),
      _loadSmartRecommendations(userId),
    ]);
  }

  /// 加载公共数据
  Future<void> _loadPublicData() async {
    await Future.wait([
      context.read<RecommendationProvider>().loadPublicRecommendations(),
      context.read<AgentProvider>().loadPublicAgents(),
    ]);
  }

  /// 加载智能推荐
  Future<void> _loadSmartRecommendations(String userId) async {
    try {
      final recommendations = await _recommendationService.getSmartRecommendations(
        userId: userId,
        limit: 20,
        includePopular: true,
        includeTrending: true,
        includePersonalized: true,
      );
      
      if (mounted) {
        context.read<RecommendationProvider>().updateSmartRecommendations(recommendations);
      }
    } catch (e) {
      debugPrint('❌ 加载智能推荐失败: $e');
    }
  }

  /// 设置滚动监听
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreContent();
      }
    });
  }

  /// 加载更多内容
  void _loadMoreContent() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) return;

    final userId = authProvider.currentUser!.id;
    
    switch (_selectedCategory) {
      case '智能体':
        // TODO: 实现加载更多智能体
        // context.read<AgentProvider>().loadMoreAgents();
        break;
      case '热门推荐':
        context.read<RecommendationProvider>().loadMoreRecommendations(userId);
        break;
      case '个性化':
        _loadSmartRecommendations(userId);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading ? _buildLoadingState() : _buildMainContent(),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text(
            '正在加载个性化内容...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent() {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '综合',
                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.surface,
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  // 搜索和筛选栏
                  AgentSearchBar(
                    categories: _categories,
                    sortOptions: const ['popular', 'rating', 'recent', 'name'],
                    selectedCategory: _selectedCategory,
                    sortBy: _sortBy,
                    onSearchChanged: _onSearchChanged,
                    onCategoryChanged: _onCategoryChanged,
                    onSortChanged: _onSortChanged,
                  ),
                  
                  // Tab栏
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accent,
                    tabs: const [
                      Tab(text: '推荐'),
                      Tab(text: '会员'),
                      Tab(text: '智能体'),
                      Tab(text: '发现'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendationsTab(),
          _buildMembershipTab(),
          _buildAgentTab(),
          _buildDiscoveryTab(),
        ],
      ),
    );
  }

  /// 构建推荐Tab
  Widget _buildRecommendationsTab() {
    return Consumer<RecommendationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.recommendations.isEmpty) {
          return _buildLoadingGrid();
        }

        if (provider.recommendations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.recommend,
            title: '暂无推荐内容',
            subtitle: '使用应用一段时间后，我们将为您推荐合适的内容',
            actionText: '刷新',
            onAction: () => _refreshRecommendations(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshRecommendations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.recommendations.length + (provider.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.recommendations.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                );
              }

              final recommendation = provider.recommendations[index];
              return RecommendationCard(
                recommendation: recommendation,
                onTap: () => _onRecommendationTap(recommendation),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建会员Tab
  Widget _buildMembershipTab() {
    return Consumer2<AuthProvider, SubscriptionProvider>(
      builder: (context, authProvider, subscriptionProvider, child) {
        if (!authProvider.isLoggedIn) {
          return _buildLoginPrompt();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VIP会员卡片
              EnhancedVipMembershipCard(
                membership: subscriptionProvider.currentMembership,
                onUpgradePressed: _navigateToSubscriptionPlans,
                onManagePressed: _navigateToMembershipManagement,
                showBenefitsDetail: true,
                enableAnimation: true,
              ),

              const SizedBox(height: 24),

              // 会员专属推荐
              _buildSectionTitle('会员专属', '为VIP用户精心挑选'),
              const SizedBox(height: 16),
              _buildMemberExclusiveContent(),

              const SizedBox(height: 24),

              // 使用统计
              _buildUsageStats(subscriptionProvider),
            ],
          ),
        );
      },
    );
  }

  /// 构建智能体Tab
  Widget _buildAgentTab() {
    return Consumer<AgentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPublicAgents && provider.publicAgents.isEmpty) {
          return _buildLoadingGrid();
        }

        if (provider.publicAgents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.smart_toy,
            title: '暂无智能体',
            subtitle: '探索AI智能体市场，发现更多可能',
            actionText: '去市场看看',
            onAction: () => _navigateToAgentMarketplace(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPublicAgents(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.publicAgents.length + (provider.isLoadingPublicAgents ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.publicAgents.length) {
                return _buildLoadingCard();
              }

              final agent = provider.publicAgents[index];
              return AgentCard(
                agent: agent,
                onTap: () => _onAgentTap(agent),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建发现Tab
  Widget _buildDiscoveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 趋势内容
          _buildSectionTitle('趋势', '正在快速流行的内容'),
          const SizedBox(height: 16),
          _buildTrendingContent(),

          const SizedBox(height: 32),

          // 分类探索
          _buildSectionTitle('分类探索', '按兴趣发现更多'),
          const SizedBox(height: 16),
          _buildCategoryExploration(),

          const SizedBox(height: 32),

          // 数据洞察
          _buildSectionTitle('数据洞察', '了解你的使用习惯'),
          const SizedBox(height: 16),
          _buildDataInsights(),
        ],
      ),
    );
  }

  // ========== 构建组件 ==========

  /// 构建区域标题
  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建加载网格
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildLoadingCard(),
    );
  }

  /// 构建加载卡片
  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建登录提示
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('登录后查看更多内容', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            '登录或注册账号，享受个性化推荐和会员权益',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  /// 构建会员专属内容
  Widget _buildMemberExclusiveContent() {
    // TODO: 实现会员专属内容展示
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          '会员专属内容',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建使用统计
  Widget _buildUsageStats(SubscriptionProvider provider) {
    // TODO: 实现使用统计展示
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本月使用统计', style: AppTextStyles.h4),
          SizedBox(height: 16),
          Text('功能正在开发中...', style: AppTextStyles.body2),
        ],
      ),
    );
  }

  /// 构建趋势内容
  Widget _buildTrendingContent() {
    // TODO: 实现趋势内容展示
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('趋势内容展示'),
      ),
    );
  }

  /// 构建分类探索
  Widget _buildCategoryExploration() {
    // TODO: 实现分类探索
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('分类探索'),
      ),
    );
  }

  /// 构建数据洞察
  Widget _buildDataInsights() {
    // TODO: 实现数据洞察
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('数据洞察'),
      ),
    );
  }

  // ========== 事件处理 ==========

  /// 搜索变化处理
  void _onSearchChanged(String query) {
    _analyticsService.trackSearch(
      query: query,
      searchType: 'comprehensive',
    );
  }

  /// 分类变化处理
  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category ?? '全部');
    _analyticsService.trackEvent('category_selected', {
      'category': category,
      'page': 'comprehensive',
    });
  }

  /// 排序变化处理
  void _onSortChanged(String? sortBy) {
    setState(() => _sortBy = sortBy);
    _analyticsService.trackEvent('sort_changed', {
      'sort_by': sortBy,
      'page': 'comprehensive',
    });
  }

  /// 刷新推荐
  Future<void> _refreshRecommendations() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      await _loadSmartRecommendations(authProvider.currentUser!.id);
    }
    await context.read<RecommendationProvider>().refresh();
  }

  /// 推荐点击处理
  void _onRecommendationTap(recommendation) {
    _analyticsService.trackEvent('recommendation_click', {
      'content_id': recommendation.contentId,
      'content_type': recommendation.contentType,
      'algorithm_type': recommendation.algorithmType,
      'position': recommendation.positionRank,
    });
  }

  /// 推荐点赞处理
  void _onRecommendationLike(recommendation) {
    _analyticsService.trackEvent('recommendation_like', {
      'content_id': recommendation.contentId,
      'content_type': recommendation.contentType,
    });
  }

  /// 推荐踩处理
  void _onRecommendationDislike(recommendation) {
    _analyticsService.trackEvent('recommendation_dislike', {
      'content_id': recommendation.contentId,
      'content_type': recommendation.contentType,
    });
  }

  /// 智能体点击处理
  void _onAgentTap(agent) {
    _analyticsService.trackEvent('agent_click', {
      'agent_id': agent.id,
      'agent_type': agent.agentType,
    });
  }

  /// 智能体收藏处理
  void _onAgentFavorite(agent) {
    _analyticsService.trackEvent('agent_favorite', {
      'agent_id': agent.id,
      'agent_type': agent.agentType,
    });
  }

  // ========== 导航方法 ==========

  void _navigateToSubscriptionPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()),
    );
  }

  void _navigateToMembershipManagement() {
    // TODO: 导航到会员管理页面
  }

  void _navigateToAgentMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgentMarketplacePage()),
    );
  }
}