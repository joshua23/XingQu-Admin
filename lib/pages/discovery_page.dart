import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/discovery_content.dart';

/// 发现页面 - 内容发现和搜索功能
/// 基于原型文件discovery.html设计
class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with TickerProviderStateMixin {
  
  // 控制器
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _categoryController;
  
  // 状态管理
  String _selectedCategory = '全部';
  bool _isSearching = false;
  
  // 分类数据
  final List<Map<String, dynamic>> _categories = [
    {'label': '全部', 'emoji': '🌟', 'count': 0},
    {'label': 'AI角色', 'emoji': '🤖', 'count': 23},
    {'label': 'FM电台', 'emoji': '📻', 'count': 15},
    {'label': '创意故事', 'emoji': '📖', 'count': 45},
    {'label': '游戏世界', 'emoji': '🎮', 'count': 12},
    {'label': '学习助手', 'emoji': '📚', 'count': 8},
    {'label': '生活服务', 'emoji': '🏠', 'count': 19},
  ];
  
  // 搜索建议
  final List<String> _searchSuggestions = [
    'AI聊天伙伴', '星空电台', '学习计划', '创意写作', '情感陪伴'
  ];
  
  // 核心功能入口
  final List<Map<String, dynamic>> _featuredFunctions = [
    {
      'title': 'VIP会员',
      'desc': '解锁全部高级功能',
      'icon': '💎',
      'badge': '热门',
      'route': '/subscription_plans',
    },
    {
      'title': '智能推荐',
      'desc': 'AI个性化内容推荐',
      'icon': '🎯',
      'badge': '新增',
      'route': '/recommendation',
    },
    {
      'title': 'AI智能体',
      'desc': '探索智能体市场',
      'icon': '🤖',
      'badge': null,
      'route': '/agent_marketplace',
    },
    {
      'title': '会员中心',
      'desc': '管理订阅和权益',
      'icon': '⚙️',
      'badge': null,
      'route': '/membership_management',
    },
    {
      'title': 'AI角色创建',
      'desc': '设计专属AI伙伴',
      'icon': '🎭',
      'badge': null,
      'route': '/character_create',
    },
    {
      'title': 'FM电台',
      'desc': '发现有趣的音频',
      'icon': '📻',
      'badge': null,
      'route': '/fm_discovery',
    },
  ];
  
  // 模拟内容数据
  List<DiscoveryContent> _contents = [];

  @override
  void initState() {
    super.initState();
    _categoryController = TabController(
      length: _categories.length,
      vsync: this,
    );
    _loadMockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// 加载模拟数据
  void _loadMockData() {
    _contents = [
      DiscoveryContent(
        id: '1',
        title: '星空夜语电台',
        description: '用温柔的声音陪伴你度过每个夜晚，分享生活中的美好瞬间',
        type: 'FM电台',
        author: '月光主播',
        coverEmoji: '🌙',
        viewCount: 1200,
        likeCount: 89,
        duration: '45分钟',
        tags: ['放松', '夜晚', '治愈'],
      ),
      DiscoveryContent(
        id: '2',
        title: '智能学习助手小爱',
        description: '专业的学习规划师，帮你制定个性化学习计划，提升学习效率',
        type: 'AI角色',
        author: '学习工坊',
        coverEmoji: '📚',
        viewCount: 2100,
        likeCount: 156,
        duration: null,
        tags: ['学习', '规划', '效率'],
      ),
      DiscoveryContent(
        id: '3',
        title: '奇幻冒险故事集',
        description: '与AI一起创作充满想象力的奇幻故事，探索无限可能的世界',
        type: '创意故事',
        author: '故事织梦者',
        coverEmoji: '🏰',
        viewCount: 3400,
        likeCount: 287,
        duration: null,
        tags: ['奇幻', '冒险', '创意'],
      ),
      DiscoveryContent(
        id: '4',
        title: '生活小百科',
        description: '日常生活中的实用知识和小贴士，让生活更加便利有趣',
        type: '生活服务',
        author: '生活达人',
        coverEmoji: '🏠',
        viewCount: 890,
        likeCount: 45,
        duration: null,
        tags: ['生活', '实用', '贴士'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 搜索头部
          _buildSearchHeader(),
          
          // 主要内容区域
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 核心功能入口
                _buildFeaturedSection(),
                
                // 分类导航
                _buildCategoryNavigation(),
                
                // 内容列表
                _buildContentSection(),
                
                // 底部间距
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索头部
  Widget _buildSearchHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 搜索栏
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isSearching ? AppColors.accent : AppColors.divider,
                    width: _isSearching ? 1.5 : 0.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索AI角色、电台、故事...',
                    hintStyle: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onTap: () => setState(() => _isSearching = true),
                  onSubmitted: _onSearchSubmitted,
                ),
              ),
              
              // 搜索建议
              if (_searchSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _searchSuggestions.map((suggestion) {
                      return GestureDetector(
                        onTap: () => _onSuggestionTap(suggestion),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建核心功能区域
  Widget _buildFeaturedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '核心功能',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _featuredFunctions.length,
              itemBuilder: (context, index) {
                return _buildFeaturedCard(_featuredFunctions[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能卡片
  Widget _buildFeaturedCard(Map<String, dynamic> function) {
    return GestureDetector(
      onTap: () => _onFunctionTap(function['route']),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            // 顶部装饰条
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
            
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        function['icon'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 标题
                  Text(
                    function['title'],
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 描述
                  Text(
                    function['desc'],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 徽章
            if (function['badge'] != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    function['badge'],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建分类导航
  Widget _buildCategoryNavigation() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['label'];
            
            return GestureDetector(
              onTap: () => _onCategorySelected(category['label']),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.accent 
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.accent 
                        : AppColors.divider,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['emoji'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['label'],
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected 
                            ? AppColors.background 
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (category['count'] > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          category['count'].toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentSection() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildContentCard(_contents[index]);
          },
          childCount: _contents.length,
        ),
      ),
    );
  }

  /// 构建内容卡片
  Widget _buildContentCard(DiscoveryContent content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部横幅
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                content.coverEmoji,
                style: const TextStyle(
                  fontSize: 40,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          
          // 内容信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  content.title,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // 描述
                Text(
                  content.description,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // 底部信息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 统计信息
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.viewCount.toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.favorite_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.likeCount.toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    // 操作按钮
                    GestureDetector(
                      onTap: () => _onContentTap(content),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          content.type == 'FM电台' ? '播放' : '查看',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 事件处理方法
  void _onSearchChanged(String value) {
    // 实时搜索筛选
    setState(() {
      if (value.isEmpty) {
        _loadMockData(); // 重新加载所有数据
      } else {
        _contents = _contents.where((content) {
          return content.title.toLowerCase().contains(value.toLowerCase()) ||
                 content.description.toLowerCase().contains(value.toLowerCase()) ||
                 content.tags.any((tag) => tag.toLowerCase().contains(value.toLowerCase()));
        }).toList();
      }
    });
  }

  void _onSearchSubmitted(String value) {
    setState(() => _isSearching = false);
    _performSearch(value);
  }
  
  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _loadMockData();
      } else {
        _contents = _contents.where((content) {
          final searchLower = query.toLowerCase();
          return content.title.toLowerCase().contains(searchLower) ||
                 content.description.toLowerCase().contains(searchLower) ||
                 content.author.toLowerCase().contains(searchLower) ||
                 content.type.toLowerCase().contains(searchLower) ||
                 content.tags.any((tag) => tag.toLowerCase().contains(searchLower));
        }).toList();
      }
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _onSearchSubmitted(suggestion);
  }

  void _onFunctionTap(String route) {
    Navigator.pushNamed(context, route);
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      // 根据分类筛选内容
      _loadMockData(); // 先重新加载所有数据
      if (category != '全部') {
        _contents = _contents.where((content) => content.type == category).toList();
      }
      // 如果有搜索关键字，继续应用搜索筛选
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _onContentTap(DiscoveryContent content) {
    // TODO: 跳转到内容详情页
    Navigator.pushNamed(
      context, 
      '/content_detail',
      arguments: content,
    );
  }
}