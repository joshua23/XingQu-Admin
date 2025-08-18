import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_tabs/home_selection_page.dart';
import 'home_tabs/home_comprehensive_simple.dart';
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
  int _currentTabIndex = 3; // 默认选中"精选"tab
  bool _isSearchVisible = false; // 搜索框显示状态
  

  // 4个Tab页配置 - 按照原型顺序：助理、FM、综合、精选
  final List<String> _tabTitles = ['助理', 'FM', '综合', '精选'];
  final List<Widget> _tabPages = [
    const HomeAssistantPage(),
    const HomeFMPage(),
    const HomeComprehensivePageSimple(),
    const HomeSelectionPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: 3, // 默认选中"精选"tab
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

  /// 计算指示器位置
  double _calculateIndicatorPosition(int tabIndex) {
    // 每个tab的布局：16px左padding + 文字宽度 + 16px右padding + 8px右margin
    // 指示器宽度24px，需要居中对齐
    
    // 计算每个tab的中心位置
    double tabCenter = 0;
    
    for (int i = 0; i <= tabIndex; i++) {
      double tabWidth = 16.0 + _getTabTextWidth(_tabTitles[i]) + 16.0; // padding + 文字宽度 + padding
      
      if (i < tabIndex) {
        tabCenter += tabWidth + 8.0; // 累加前面tab的总宽度（包括margin）
      } else {
        tabCenter += tabWidth / 2; // 当前tab的一半宽度，找到中心位置
      }
    }
    
    // 指示器居中：tab中心位置 - 指示器宽度的一半
    return tabCenter - 12.0;
  }
  
  /// 估算tab文字宽度（16px字体大小的近似值）
  double _getTabTextWidth(String text) {
    // 根据文字内容估算宽度
    switch (text) {
      case '助理': return 32.0; // 2个中文字符
      case 'FM': return 24.0;   // 2个英文字符
      case '综合': return 32.0; // 2个中文字符
      case '精选': return 32.0; // 2个中文字符
      default: return 30.0;
    }
  }

  /// 处理搜索点击事件
  void _onSearchTap() {
    debugPrint('🔍 搜索被点击');
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 使用应用默认背景色
      body: Stack(
        children: [
          // 只在精选页显示背景图片
          if (_currentTabIndex == 3) // 精选页的索引是3
            Positioned.fill(
              child: Image.asset(
                'assets/images/image.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ 背景图片加载失败: $error');
                  return Container(
                    color: AppColors.background,
                  );
                },
              ),
            ),
          
          // 主要内容
          Column(
            children: [
              // Tab标签栏 - 根据当前页面调整样式
              _buildTabBarWithBlur(),
              
              // 搜索框 - 根据状态显示
              if (_isSearchVisible) _buildSearchBar(),
              
              // Tab页面内容
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabPages,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建Tab标签栏 - 包含Tab标签和右侧操作图标
  Widget _buildTabBarWithBlur() {
    // 根据是否在精选页决定颜色方案
    final bool isSelectionPage = _currentTabIndex == 3;
    final Color activeColor = isSelectionPage ? Colors.white : AppColors.textPrimary;
    final Color inactiveColor = isSelectionPage ? const Color(0xFF8E8E93) : AppColors.textSecondary;
    final Color iconColor = isSelectionPage ? Colors.white : AppColors.textPrimary;
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // 左侧Tab标签 - 使用Stack来实现动画下划线
          Expanded(
            child: Stack(
              children: [
                // Tab标签文字
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _tabTitles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final title = entry.value;
                    final isActive = _currentTabIndex == index;
                    
                    return GestureDetector(
                      onTap: () {
                        _tabController.animateTo(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isActive ? activeColor : inactiveColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6), // 为下划线预留空间
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // 动画下划线 - 简化计算逻辑
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    // 计算指示器位置：每个tab包含16px左右padding + 8px margin = 约40px
                    // tab文字宽度：助理(32px), FM(24px), 综合(32px), 精选(32px)
                    margin: EdgeInsets.only(
                      left: _calculateIndicatorPosition(_currentTabIndex),
                    ),
                    width: 24,
                    height: 2,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 右侧搜索图标
          GestureDetector(
            onTap: () {
              _onSearchTap();
            },
            child: Icon(
              Icons.search,
              color: iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '搜索角色、聊天记录...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                debugPrint('🔍 搜索内容: $value');
                // 这里可以添加搜索逻辑
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearchVisible = false;
              });
            },
            child: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
