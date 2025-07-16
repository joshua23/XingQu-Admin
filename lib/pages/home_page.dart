import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';
import '../widgets/status_bar.dart';
import '../widgets/story_card.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 首页Widget
/// 显示故事广场，包含故事列表、顶部导航、底部导航等
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 首页状态类
/// 管理故事列表数据、刷新状态、滚动监听等
class _HomePageState extends State<HomePage> {
  // 故事列表数据
  List<Story> _stories = [];

  // 加载状态标识
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  // 滚动控制器，用于监听滚动事件
  final ScrollController _scrollController = ScrollController();

  // 底部导航当前选中索引
  int _currentNavIndex = 0;

  // 服务实例
  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // 监听滚动事件，实现无限滚动
    _scrollController.addListener(_onScroll);

    // 直接加载本地模拟数据，跳过Supabase
    _loadFallbackStories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面展示时，自动高亮“故事”tab
    if (_currentNavIndex != 0) {
      setState(() {
        _currentNavIndex = 0;
      });
    }
  }

  /// 滚动监听器
  /// 当滚动到底部时自动加载更多数据
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // 使用Scaffold的appBar属性，更符合规范
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: AppDimensions.appBarHeight,
        titleSpacing: 0,
        title: _buildTopNavigation(),
      ),
      // 主体内容现在直接放在body里
      body: CustomScrollView(
        slivers: [
          // 游客模式提示（Provider响应式）
          SliverToBoxAdapter(
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (!auth.isLoggedIn) {
                  return Container(
                    width: double.infinity,
                    color: AppColors.accent.withOpacity(0.08),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '当前为游客模式，部分功能需登录后使用',
                            style: AppTextStyles.body2
                                .copyWith(color: AppColors.accent),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          },
                          child: const Text('去登录'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          // 故事卡片列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _stories.length) {
                  return _buildLoadMoreIndicator();
                }
                final story = _stories[index];
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: StoryCard(
                    story: story,
                    onLike: () => _handleLike(index),
                    onComment: () => _handleComment(story),
                    onShare: () => _handleShare(story),
                    onFollow: () => _handleFollow(index),
                  ),
                );
              },
              childCount: _stories.length + (_isLoadingMore ? 1 : 0),
            ),
          ),
        ],
      ),
      // 使用Scaffold的bottomNavigationBar属性
      bottomNavigationBar: _buildBottomNavigation(),
      // 使用Scaffold的floatingActionButton属性
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 修正：应为endFloat
    );
  }

  /// 构建顶部导航栏
  /// 包含标题、搜索按钮、通知按钮
  Widget _buildTopNavigation() {
    return Container(
      height: AppDimensions.appBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDimensions.paddingM),

          // 标题
          Row(
            children: [
              const Text(
                '✦',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '故事广场',
                style: AppTextStyles.h3,
              ),
            ],
          ),

          const Spacer(),

          // 搜索按钮
          _buildNavActionButton(
            icon: Icons.search,
            onTap: _openSearch,
          ),

          const SizedBox(width: AppDimensions.paddingS),

          // 通知按钮
          _buildNavActionButton(
            icon: Icons.notifications_outlined,
            onTap: _openNotifications,
          ),

          const SizedBox(width: AppDimensions.paddingM),
        ],
      ),
    );
  }

  /// 构建导航栏操作按钮
  /// [icon] 图标
  /// [onTap] 点击回调
  Widget _buildNavActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: AppDimensions.iconM,
        ),
      ),
    );
  }

  /// 构建故事列表
  /// 支持下拉刷新和无限滚动
  Widget _buildStoryList() {
    if (_stories.isEmpty && !_isRefreshing) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshStories,
      backgroundColor: AppColors.surface,
      color: AppColors.accent,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          0,
          AppDimensions.paddingM,
          AppDimensions.bottomNavHeight + 16, // 为底部导航和浮动按钮留空间
        ),
        itemCount: _stories.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 加载更多指示器
          if (index == _stories.length) {
            return _buildLoadMoreIndicator();
          }

          // 故事卡片
          final story = _stories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
            child: StoryCard(
              story: story,
              onLike: () => _handleLike(index),
              onComment: () => _handleComment(story),
              onShare: () => _handleShare(story),
              onFollow: () => _handleFollow(index),
            ),
          );
        },
      ),
    );
  }

  /// 构建空状态界面
  /// 当没有故事时显示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '暂无故事',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            '快来分享你的第一个故事吧',
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          ElevatedButton(
            onPressed: _createStory,
            child: const Text('创建故事'),
          ),
        ],
      ),
    );
  }

  /// 构建加载更多指示器
  /// 显示在列表底部
  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 构建底部导航栏
  /// 包含故事、AI聊天、消息、个人中心四个选项
  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        height: AppDimensions.bottomNavHeight,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.menu_book,
              label: '故事',
              index: 0,
              isActive: _currentNavIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.smart_toy_outlined,
              label: 'AI聊天',
              index: 1,
              isActive: _currentNavIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.edit,
              label: '创作',
              index: 2,
              isActive: _currentNavIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.chat_bubble_outline,
              label: '消息',
              index: 3,
              isActive: _currentNavIndex == 3,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: '我的',
              index: 4,
              isActive: _currentNavIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导航项
  /// [icon] 图标
  /// [label] 文字标签
  /// [index] 索引
  /// [isActive] 是否激活状态
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.border : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              size: AppDimensions.iconL,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建浮动发布按钮
  /// 用于创建新故事
  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: _createStory,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              offset: const Offset(0, 4),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.background,
          size: 24,
          weight: 600,
        ),
      ),
    );
  }

  /// 加载故事数据
  /// [isRefresh] 是否为刷新操作（默认false）
  Future<void> _loadStories({bool isRefresh = false}) async {
    // 直接加载本地模拟数据
    _loadFallbackStories();
  }

  /// 加载备用故事数据
  /// 当网络连接失败时使用的示例数据
  void _loadFallbackStories() {
    print('加载本地模拟数据'); // 调试输出
    if (!mounted) return; // 安全校验
    setState(() {
      _stories = [
        Story(
          id: 'fallback_1',
          title: '城市夜归人的温暖瞬间',
          content:
              '深夜十一点，我走在回家的路上，看到一家小店还亮着温暖的灯光。老板娘正在为最后一位客人准备热腾腾的汤面，那一刻我突然觉得这个城市充满了温度...',
          imageUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=200&fit=crop&auto=format',
          tags: ['温暖', '城市', '夜晚'],
          user: const User(
            id: 'fallback_u1',
            nickname: '小明的奇幻世界',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likeCount: 127,
          commentCount: 23,
          isLiked: false,
          views: 1850,
        ),
        Story(
          id: 'fallback_2',
          title: '与猫咪的不期而遇',
          content:
              '今天在公园散步时，遇到了一只橘猫。它很亲人，一直跟着我走。后来我发现它的项圈上有主人的电话，帮它找到了回家的路。有时候善意就是这样简单...',
          imageUrl:
              'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=200&fit=crop&auto=format',
          tags: ['温馨', '宠物', '善意'],
          user: const User(
            id: 'fallback_u2',
            nickname: '星空下的旅行者',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          likeCount: 256,
          commentCount: 45,
          isLiked: true,
          views: 3200,
        ),
        Story(
          id: 'fallback_3',
          title: '第一次看到极光的感动',
          content:
              '经过三年的计划和准备，终于在冰岛看到了梦寐以求的极光。当绿色的光幕在天空中舞动的那一刻，我感动得泪流满面。有些美好值得我们等待...',
          imageUrl:
              'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=400&h=200&fit=crop&auto=format',
          tags: ['旅行', '极光', '梦想'],
          user: const User(
            id: 'fallback_u3',
            nickname: '梦想追逐者',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          likeCount: 389,
          commentCount: 67,
          isLiked: false,
          views: 5600,
        ),
        // 新增丰富模拟数据
        Story(
          id: 'fallback_4',
          title: '深夜食堂的故事',
          content: '加班到深夜，偶遇一家小食堂，老板用心做的蛋炒饭让我忘记了疲惫。陌生人之间的微笑，是城市最温柔的光。',
          imageUrl:
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=200&fit=crop&auto=format',
          tags: ['美食', '治愈', '深夜'],
          user: const User(
            id: 'fallback_u4',
            nickname: '治愈系少女',
            isFollowed: true,
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          likeCount: 88,
          commentCount: 12,
          isLiked: false,
          views: 1200,
        ),
        Story(
          id: 'fallback_5',
          title: '毕业季的告别',
          content: '和最好的朋友在操场上拍了最后一张合影。我们都哭了，但也都相信未来会更好。',
          imageUrl:
              'https://images.unsplash.com/photo-1464983953574-0892a716854b?w=400&h=200&fit=crop&auto=format',
          tags: ['青春', '毕业', '友情'],
          user: const User(
            id: 'fallback_u5',
            nickname: '阿狸',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          likeCount: 201,
          commentCount: 34,
          isLiked: true,
          views: 2800,
        ),
        Story(
          id: 'fallback_6',
          title: '雨中的温柔',
          content: '下班路上突然下起大雨，一位陌生人递给我一把伞。那一刻，世界都变得温柔了。',
          imageUrl:
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=200&fit=crop&auto=format',
          tags: ['温情', '雨天', '善良'],
          user: const User(
            id: 'fallback_u6',
            nickname: '温暖的陌生人',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 15)),
          likeCount: 59,
          commentCount: 7,
          isLiked: false,
          views: 890,
        ),
        Story(
          id: 'fallback_7',
          title: '独自旅行的意义',
          content: '第一次一个人去云南，沿途遇到很多有趣的人和事。原来勇敢迈出第一步，世界会给你惊喜。',
          imageUrl:
              'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=400&h=200&fit=crop&auto=format',
          tags: ['旅行', '成长', '勇气'],
          user: const User(
            id: 'fallback_u7',
            nickname: '勇敢的心',
            isFollowed: true,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          likeCount: 143,
          commentCount: 19,
          isLiked: false,
          views: 2100,
        ),
        Story(
          id: 'fallback_8',
          title: '深夜的便利店',
          content: '凌晨两点，便利店的灯光成了城市的守夜人。买了一杯热牛奶，和店员聊了几句，心情莫名变好。',
          imageUrl:
              'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?w=400&h=200&fit=crop&auto=format',
          tags: ['夜晚', '便利店', '温暖'],
          user: const User(
            id: 'fallback_u8',
            nickname: '夜行者',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
          likeCount: 77,
          commentCount: 10,
          isLiked: false,
          views: 1350,
        ),
        Story(
          id: 'fallback_9',
          title: '和家人的团聚',
          content: '一年一度的春节终于回家，和家人围坐吃年夜饭，才发现幸福其实很简单。',
          imageUrl:
              'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400&h=200&fit=crop&auto=format',
          tags: ['家庭', '团聚', '春节'],
          user: const User(
            id: 'fallback_u9',
            nickname: '小团圆',
            isFollowed: true,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          likeCount: 312,
          commentCount: 56,
          isLiked: true,
          views: 4200,
        ),
        Story(
          id: 'fallback_10',
          title: '晨跑的坚持',
          content: '连续晨跑30天，身体和心情都变得更好了。坚持真的会带来改变！',
          imageUrl:
              'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=400&h=200&fit=crop&auto=format',
          tags: ['运动', '健康', '自律'],
          user: const User(
            id: 'fallback_u10',
            nickname: '自律达人',
            isFollowed: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          likeCount: 98,
          commentCount: 15,
          isLiked: false,
          views: 1680,
        ),
      ];
    });
  }

  /// 刷新故事列表
  /// 下拉刷新时调用
  Future<void> _refreshStories() async {
    await _loadStories(isRefresh: true);
  }

  /// 加载更多故事
  /// 滚动到底部时调用
  Future<void> _loadMoreStories() async {
    if (_isLoadingMore) return;

    if (!mounted) return; // 安全校验
    setState(() {
      _isLoadingMore = true;
    });

    // 直接加载本地模拟数据（可扩展为追加更多模拟数据）
    // 这里只做提示，不再追加新数据
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有更多内容了（本地模拟）'),
          backgroundColor: AppColors.textSecondary,
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (!mounted) return; // 安全校验
    setState(() {
      _isLoadingMore = false;
    });
  }

  /// 处理点赞操作
  /// [index] 故事在列表中的索引
  Future<void> _handleLike(int index) async {
    if (!await _authService.isLoggedIn()) {
      _showLoginRequiredDialog();
      return;
    }

    final story = _stories[index];
    final originalIsLiked = story.isLiked;
    final originalLikeCount = story.likeCount;

    // 乐观更新UI
    if (!mounted) return; // 安全校验
    setState(() {
      _stories[index] = story.copyWith(
        isLiked: !story.isLiked,
        likeCount: story.isLiked ? story.likeCount - 1 : story.likeCount + 1,
      );
    });

    try {
      // 调用Supabase API更新点赞状态
      await _storyService.toggleLike(story.id);
    } catch (e) {
      debugPrint('点赞操作失败: $e');

      // 恢复原始状态
      if (!mounted) return; // 安全校验
      setState(() {
        _stories[index] = story.copyWith(
          isLiked: originalIsLiked,
          likeCount: originalLikeCount,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败，请重试'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 处理关注操作
  /// [index] 故事在列表中的索引
  Future<void> _handleFollow(int index) async {
    if (!await _authService.isLoggedIn()) {
      _showLoginRequiredDialog();
      return;
    }

    final story = _stories[index];
    final originalIsFollowed = story.user.isFollowed;

    // 乐观更新UI
    if (!mounted) return; // 安全校验
    setState(() {
      _stories[index] = story.copyWith(
        user: story.user.copyWith(
          isFollowed: !story.user.isFollowed,
        ),
      );
    });

    try {
      // 调用Supabase API更新关注状态
      await _authService.toggleFollow(story.user.id);
    } catch (e) {
      debugPrint('关注操作失败: $e');

      // 恢复原始状态
      if (!mounted) return; // 安全校验
      setState(() {
        _stories[index] = story.copyWith(
          user: story.user.copyWith(
            isFollowed: originalIsFollowed,
          ),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败，请重试'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 显示登录提示对话框
  /// 当用户未登录时引导到登录页面
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '需要登录',
          style: AppTextStyles.h3,
        ),
        content: Text(
          '请先登录以使用完整功能',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  /// 处理导航项点击
  /// [index] 导航项索引
  void _onNavItemTap(int index) async {
    if (!await _authService.isLoggedIn() && index != 0) {
      _showLoginRequiredDialog();
      return;
    }

    if (!mounted) return; // 安全校验
    setState(() {
      _currentNavIndex = index;
    });

    // 根据索引跳转到不同页面
    switch (index) {
      case 0:
        // 故事页面（当前页面）
        break;
      case 1:
        // AI聊天页面
        Navigator.of(context).pushNamed('/ai_chat');
        break;
      case 2:
        // 创作中心页面
        Navigator.of(context).pushNamed('/creation_center');
        break;
      case 3:
        // 消息页面
        Navigator.of(context).pushNamed('/messages');
        break;
      case 4:
        // 个人中心页面
        Navigator.of(context).pushNamed('/profile');
        break;
    }
  }

  /// 处理评论操作
  /// [story] 要评论的故事
  void _handleComment(Story story) async {
    if (!await _authService.isLoggedIn()) {
      _showLoginRequiredDialog();
      return;
    }

    debugPrint('打开评论页面: ${story.title}');
    // TODO: 实现评论页面跳转
  }

  /// 处理分享操作
  /// [story] 要分享的故事
  void _handleShare(Story story) {
    debugPrint('分享故事: ${story.title}');
    // TODO: 实现分享功能
  }

  /// 处理用户头像点击
  /// [userId] 用户ID
  void _handleUserProfile(String userId) {
    debugPrint('查看用户资料: $userId');
    // TODO: 实现用户资料页面跳转
  }

  /// 处理故事详情点击
  /// [story] 要查看的故事
  void _handleStoryDetail(Story story) {
    debugPrint('查看故事详情: ${story.title}');
    // TODO: 实现故事详情页面跳转
  }

  /// 打开搜索页面
  void _openSearch() {
    Navigator.of(context).pushNamed('/story_search');
  }

  /// 打开通知页面
  void _openNotifications() async {
    if (!await _authService.isLoggedIn()) {
      _showLoginRequiredDialog();
      return;
    }

    debugPrint('打开通知页面');
    // TODO: 实现通知功能
  }

  /// 创建新故事
  void _createStory() async {
    if (!await _authService.isLoggedIn()) {
      _showLoginRequiredDialog();
      return;
    }

    debugPrint('创建新故事');
    // 跳转到创作中心页面
    Navigator.of(context).pushNamed('/creation_center');
  }
}
