import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_bar.dart';
import 'home_tabs/home_selection_page.dart';
import 'home_tabs/home_comprehensive_page.dart';
import 'home_tabs/home_fm_page.dart';
import 'home_tabs/home_assistant_page.dart';

/// 重构后的首页Widget - 基于原型文件的4个Tab页模式
/// 包含精选、综合、FM、助理四个子页面
class HomeRefactored extends StatefulWidget {
  const HomeRefactored({super.key});

  @override
  State<HomeRefactored> createState() => _HomeRefactoredState();
}

/// 首页状态类 - 管理Tab页切换和顶部导航
class _HomeRefactoredState extends State<HomeRefactored>
    with TickerProviderStateMixin {
  // Tab控制器
  late TabController _tabController;
  int _currentTabIndex = 0;

  // 4个Tab页配置
  final List<String> _tabTitles = ['精选', '综合', 'FM', '助理'];
  final List<Widget> _tabPages = [
    const HomeSelectionPage(),
    const HomeComprehensivePage(),
    const HomeFMPage(),
    const HomeAssistantPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Tab页变化监听
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 状态栏
          const StatusBar(),
          
          // 顶部导航区域
          _buildTopNavigation(),
          
          // Tab标签栏
          _buildTabBar(),
          
          // Tab页面内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabPages,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航区域
  Widget _buildTopNavigation() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧功能入口
          Row(
            children: [
              _buildNavIcon(
                icon: Icons.highlight_outlined,
                label: 'Highlight',
                onTap: () => _onHighlightTap(),
              ),
              const SizedBox(width: 20),
              _buildNavIcon(
                icon: Icons.radio_outlined,
                label: 'FM',
                onTap: () => _onFMTap(),
              ),
            ],
          ),
          
          // 中间标题
          Text(
            '星趣',
            style: AppTextStyles.brand.copyWith(fontSize: 20),
          ),
          
          // 右侧功能入口
          Row(
            children: [
              _buildNavIcon(
                icon: Icons.person_outline,
                label: '角色设计',
                onTap: () => _onCharacterDesignTap(),
              ),
              const SizedBox(width: 20),
              _buildNavIcon(
                icon: Icons.search_outlined,
                label: '搜索',
                onTap: () => _onSearchTap(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建导航图标
  Widget _buildNavIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 构建Tab标签栏
  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
          insets: EdgeInsets.symmetric(horizontal: 24),
        ),
        indicatorColor: AppColors.primary,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.body1.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.body1,
        tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  // 导航按钮事件处理
  void _onHighlightTap() {
    // TODO: 实现Highlight功能
  }

  void _onFMTap() {
    // 切换到FM Tab
    _tabController.animateTo(2);
  }

  void _onCharacterDesignTap() {
    // TODO: 跳转到角色设计页面
    Navigator.pushNamed(context, '/character_create');
  }

  void _onSearchTap() {
    // TODO: 跳转到搜索页面
    Navigator.pushNamed(context, '/story_search');
  }
}