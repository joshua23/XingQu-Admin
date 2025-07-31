import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/ai_character.dart';
import '../../widgets/character_card.dart';

/// 首页综合页面 - 包含6大子模块
/// 基于原型文件home-comprehensive.html设计
class HomeComprehensivePage extends StatefulWidget {
  const HomeComprehensivePage({super.key});

  @override
  State<HomeComprehensivePage> createState() => _HomeComprehensivePageState();
}

class _HomeComprehensivePageState extends State<HomeComprehensivePage>
    with TickerProviderStateMixin {
  
  // 当前选中的模块索引
  int _currentModuleIndex = 0;
  
  // 6大模块配置
  final List<String> _moduleNames = ['订阅', '推荐', '智能体', '记忆薄', '双语', '挑战'];
  final List<String> _moduleKeys = ['subscribe', 'recommend', 'agent', 'memory', 'bilingual', 'challenge'];
  
  // 搜索控制器
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _moduleScrollController = ScrollController();
  
  // 模拟数据
  List<AICharacter> _characters = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadMockData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _moduleScrollController.dispose();
    super.dispose();
  }

  /// 加载模拟数据
  void _loadMockData() {
    _characters = [
      AICharacter(
        id: '1',
        name: '智能助手',
        description: '全能型AI助手，帮你解决日常问题',
        avatar: '🤖',
        tags: ['智能', '助手', '全能'],
        followers: 15000,
        messages: 4500,
        isFollowed: false,
        personality: '专业、高效、贴心',
        background: '专为解决日常问题设计的全能AI助手',
      ),
      AICharacter(
        id: '2',
        name: '记忆管家',
        description: '帮你记录和管理重要信息',
        avatar: '📝',
        tags: ['记忆', '管理', '效率'],
        followers: 8200,
        messages: 2100,
        isFollowed: true,
        personality: '细致、有序、可靠',
        background: '专注于信息记录和管理的智能助手',
      ),
      AICharacter(
        id: '3',
        name: '语言导师',
        description: '双语学习的最佳伙伴',
        avatar: '🌍',
        tags: ['双语', '学习', '导师'],
        followers: 12500,
        messages: 3800,
        isFollowed: false,
        personality: '耐心、专业、友善',
        background: '专业的多语言学习指导助手',
      ),
    ];
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreContent();
    }
  }

  /// 加载更多内容
  void _loadMoreContent() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // 模拟网络请求
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 搜索栏
          _buildSearchSection(),
          
          // 模块分类导航
          _buildModuleNavigation(),
          
          // 主要内容区域
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  /// 构建搜索区域
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '搜索AI角色、智能体...',
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () => _onVoiceSearch(),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic,
                  color: AppColors.accent,
                  size: 16,
                ),
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  /// 构建模块导航
  Widget _buildModuleNavigation() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _moduleScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _moduleNames.length,
        itemBuilder: (context, index) {
          final isActive = _currentModuleIndex == index;
          return GestureDetector(
            onTap: () => _onModuleSelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive 
                      ? AppColors.accent
                      : AppColors.divider,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _moduleNames[index],
                  style: AppTextStyles.body2.copyWith(
                    color: isActive 
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight: isActive 
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 根据选中的模块显示不同内容
          _buildModuleContent(),
          
          // 加载更多指示器
          if (_isLoading)
            SliverToBoxAdapter(
              child: _buildLoadingIndicator(),
            ),
        ],
      ),
    );
  }

  /// 构建模块内容
  Widget _buildModuleContent() {
    switch (_moduleKeys[_currentModuleIndex]) {
      case 'subscribe':
        return _buildSubscribeContent();
      case 'recommend':
        return _buildRecommendContent();
      case 'agent':
        return _buildAgentContent();
      case 'memory':
        return _buildMemoryContent();
      case 'bilingual':
        return _buildBilingualContent();
      case 'challenge':
        return _buildChallengeContent();
      default:
        return _buildDefaultContent();
    }
  }

  /// 构建订阅内容
  Widget _buildSubscribeContent() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _characters.length) return null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildContentItem(_characters[index]),
          );
        },
      ),
    );
  }

  /// 构建推荐内容
  Widget _buildRecommendContent() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _characters.length) return null;
          return CharacterCard(
            character: _characters[index],
            onTap: () => _onCharacterTap(_characters[index]),
          );
        },
      ),
    );
  }

  /// 构建智能体内容
  Widget _buildAgentContent() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('热门智能体', () => _onMoreTap('agent')),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _characters.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 140,
                    child: CharacterCard(
                      character: _characters[index],
                      onTap: () => _onCharacterTap(_characters[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记忆薄、双语、挑战内容（使用默认内容）
  Widget _buildMemoryContent() => _buildDefaultContent();
  Widget _buildBilingualContent() => _buildDefaultContent();
  Widget _buildChallengeContent() => _buildDefaultContent();

  /// 构建默认内容
  Widget _buildDefaultContent() {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              '${_moduleNames[_currentModuleIndex]}功能开发中',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '该功能正在紧张开发中，敬请期待！',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadMockData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight,
                foregroundColor: AppColors.background,
              ),
              child: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容项
  Widget _buildContentItem(AICharacter character) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息头部
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      character.avatar,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '2小时前',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 内容描述
            Text(
              character.description,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 媒体内容（模拟）
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 32,
                  color: AppColors.accent,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 底部操作栏
            Row(
              children: [
                _buildActionButton(Icons.favorite_border, '123'),
                _buildActionButton(Icons.comment_outlined, '45'),
                _buildActionButton(Icons.share_outlined, '分享'),
                const Spacer(),
                _buildActionButton(Icons.bookmark_border, '收藏'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建区块标题
  Widget _buildSectionHeader(String title, VoidCallback onMoreTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.h3,
        ),
        GestureDetector(
          onTap: onMoreTap,
          child: Text(
            '更多',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.highlight,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "scroll_top",
          mini: true,
          backgroundColor: AppColors.highlight.withOpacity(0.1),
          foregroundColor: AppColors.highlight,
          onPressed: _scrollToTop,
          child: const Icon(Icons.keyboard_arrow_up),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "create_content",
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          onPressed: _createContent,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  // 事件处理方法
  void _onSearchChanged(String query) {
    // TODO: 实现搜索功能
  }

  void _onVoiceSearch() {
    // TODO: 实现语音搜索
  }

  void _onModuleSelected(int index) {
    setState(() {
      _currentModuleIndex = index;
    });
    _loadMockData(); // 重新加载对应模块的数据
  }

  void _onCharacterTap(AICharacter character) {
    Navigator.pushNamed(
      context,
      '/character_detail',
      arguments: character,
    );
  }

  void _onMoreTap(String category) {
    Navigator.pushNamed(
      context,
      '/category_detail',
      arguments: category,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _createContent() {
    Navigator.pushNamed(context, '/content_create');
  }
}