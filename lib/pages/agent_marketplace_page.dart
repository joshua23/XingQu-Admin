import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/custom_agent.dart';
import '../providers/agent_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/agent_card.dart';
import 'agent_detail_page.dart';
import 'agent_create_page.dart';

/// AI智能体市场页面
class AgentMarketplacePage extends StatefulWidget {
  const AgentMarketplacePage({Key? key}) : super(key: key);

  @override
  State<AgentMarketplacePage> createState() => _AgentMarketplacePageState();
}

class _AgentMarketplacePageState extends State<AgentMarketplacePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabTitles = ['推荐', '热门', '高评分', '全部'];
  final List<String> _categoryFilters = [
    '全部',
    '创意助手',
    '技术助手',
    '教育助手',
    '商务助手',
    '娱乐助手',
  ];
  
  String _selectedCategory = '全部';
  bool _isSearchMode = false;

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
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      agentProvider.initialize(authProvider.currentUser!.id);
    } else {
      // 游客模式，加载公开智能体
      agentProvider.loadPublicAgents();
      agentProvider.loadPopularAgents();
      agentProvider.loadHighRatedAgents();
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
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final currentTab = _tabController.index;
    
    switch (currentTab) {
      case 0: // 推荐
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser != null) {
          agentProvider.loadRecommendedAgents(authProvider.currentUser!.id);
        }
        break;
      case 1: // 热门
        agentProvider.loadPopularAgents();
        break;
      case 2: // 高评分
        agentProvider.loadHighRatedAgents();
        break;
      case 3: // 全部
        agentProvider.loadPublicAgents(
          category: _selectedCategory == '全部' ? null : _selectedCategory,
          searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索智能体...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: (value) => _performSearch(),
              )
            : const Text('智能体市场', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_isSearchMode)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => _exitSearchMode(),
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              onPressed: () => _enterSearchMode(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Tab栏
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: Colors.transparent, // 去掉下划线
                indicatorWeight: 0, // 设置下划线粗细为0
                dividerColor: Colors.transparent, // 去掉分隔线
                tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
              ),
              
              // 分类过滤器
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '分类:',
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
                          children: _categoryFilters.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) => _onCategoryChanged(category),
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
      ),
      body: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendedTab(agentProvider),
              _buildPopularTab(agentProvider),
              _buildHighRatedTab(agentProvider),
              _buildAllAgentsTab(agentProvider),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () => _navigateToCreateAgent(),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedTab(AgentProvider agentProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      return _buildGuestPrompt();
    }

    if (agentProvider.isLoadingRecommended && agentProvider.recommendedAgents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (agentProvider.recommendedAgents.isEmpty) {
      return _buildEmptyState('暂无推荐智能体', '使用应用一段时间后，我们将为您推荐合适的智能体');
    }

    return _buildAgentGrid(agentProvider.recommendedAgents, agentProvider.isLoadingRecommended);
  }

  Widget _buildPopularTab(AgentProvider agentProvider) {
    if (agentProvider.isLoadingPopular && agentProvider.popularAgents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (agentProvider.popularAgents.isEmpty) {
      return _buildEmptyState('暂无热门智能体', '热门智能体正在统计中，请稍后查看');
    }

    return _buildAgentGrid(agentProvider.popularAgents, agentProvider.isLoadingPopular);
  }

  Widget _buildHighRatedTab(AgentProvider agentProvider) {
    if (agentProvider.isLoadingHighRated && agentProvider.highRatedAgents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (agentProvider.highRatedAgents.isEmpty) {
      return _buildEmptyState('暂无高评分智能体', '高质量智能体正在评估中，请稍后查看');
    }

    return _buildAgentGrid(agentProvider.highRatedAgents, agentProvider.isLoadingHighRated);
  }

  Widget _buildAllAgentsTab(AgentProvider agentProvider) {
    if (agentProvider.isLoadingPublicAgents && agentProvider.publicAgents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (agentProvider.publicAgents.isEmpty) {
      return _buildEmptyState('暂无智能体', '当前分类下暂无智能体，请尝试其他分类');
    }

    return _buildAgentGrid(agentProvider.publicAgents, agentProvider.isLoadingPublicAgents);
  }

  Widget _buildAgentGrid(List<CustomAgent> agents, bool isLoading) {
    return RefreshIndicator(
      onRefresh: () => _refreshCurrentTab(),
      color: AppColors.primary,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: agents.length + (isLoading ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= agents.length) {
            return _buildLoadingCard();
          }
          
          final agent = agents[index];
          return AgentCard(
            agent: agent,
            onTap: () => _navigateToAgentDetail(agent),
            onUse: () => _useAgent(agent),
            onClone: () => _cloneAgent(agent),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildGuestPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '登录后查看推荐智能体',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '基于您的使用习惯，为您推荐最适合的AI智能体',
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
            Icons.smart_toy_outlined,
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

  void _enterSearchMode() {
    setState(() => _isSearchMode = true);
  }

  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
    });
    _applyFilters();
  }

  void _performSearch() {
    _applyFilters();
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _applyFilters() {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final category = _selectedCategory == '全部' ? null : _selectedCategory;
    final searchQuery = _searchController.text.isEmpty ? null : _searchController.text;
    
    agentProvider.search(query: searchQuery, category: category);
  }

  Future<void> _refreshCurrentTab() async {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentTab = _tabController.index;
    
    switch (currentTab) {
      case 0: // 推荐
        if (authProvider.currentUser != null) {
          await agentProvider.loadRecommendedAgents(authProvider.currentUser!.id);
        }
        break;
      case 1: // 热门
        await agentProvider.loadPopularAgents();
        break;
      case 2: // 高评分
        await agentProvider.loadHighRatedAgents();
        break;
      case 3: // 全部
        await agentProvider.loadPublicAgents(
          category: _selectedCategory == '全部' ? null : _selectedCategory,
          searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        );
        break;
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _navigateToCreateAgent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgentCreatePage(),
      ),
    );
  }

  void _navigateToAgentDetail(CustomAgent agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentDetailPage(
          agentId: agent.agentId,
          agent: agent,
        ),
      ),
    );
  }

  void _useAgent(CustomAgent agent) async {
    // 记录使用并导航到聊天页面
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    await agentProvider.recordAgentUsage(agent.agentId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始与${agent.agentName}对话'),
        backgroundColor: AppColors.primary,
      ),
    );
    
    // 这里应该导航到AI聊天页面
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AIChatPage(agent: agent)));
  }

  void _cloneAgent(CustomAgent agent) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      _navigateToLogin();
      return;
    }

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final clonedAgent = await agentProvider.cloneAgent(
        sourceAgentId: agent.agentId,
        userId: authProvider.currentUser!.id,
        newName: '${agent.agentName} (我的副本)',
      );

      if (clonedAgent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('智能体 "${clonedAgent.agentName}" 克隆成功'),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () => _navigateToAgentDetail(clonedAgent),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('克隆失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}