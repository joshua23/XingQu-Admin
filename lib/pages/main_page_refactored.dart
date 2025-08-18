import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_bar.dart';
import '../widgets/bottom_navigation_refactored.dart';
import '../services/auth_guard_service.dart';
import 'home_refactored.dart';
import 'messages_page.dart';
import 'creation_center_page.dart';
import 'discovery_page.dart';
import 'profile_page.dart';

/// 主页面容器 - 包含底部导航的顶层页面
/// 管理5个主要页面的切换：首页、消息、创作、发现、我的
class MainPageRefactored extends StatefulWidget {
  const MainPageRefactored({super.key});

  @override
  State<MainPageRefactored> createState() => _MainPageRefactoredState();
}

class _MainPageRefactoredState extends State<MainPageRefactored> {
  int _currentIndex = 0;
  late PageController _pageController;

  // 页面列表
  final List<Widget> _pages = [
    const HomeRefactored(),              // 首页（包含4个Tab）
    const MessagesPage(),                // 消息页
    const CreationCenterPage(),          // 创作中心
    const DiscoveryPage(),               // 发现页
    const ProfilePage(),                 // 我的页面
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 页面内容
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      
      // 底部导航
      bottomNavigationBar: BottomNavigationRefactored(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  /// 页面切换回调
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// 底部导航点击回调
  void _onTabTapped(int index) {
    // 根据Tab index确定需要的权限
    String action = _getActionForTabIndex(index);
    
    // 使用认证守卫检查权限
    context.checkAuth(action, () {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  /// 根据Tab索引确定需要的权限操作
  String _getActionForTabIndex(int index) {
    switch (index) {
      case 0: // 首页
        return 'view'; // 首页可以游客浏览
      case 1: // 消息
        return 'view'; // 消息页可以游客浏览（但具体操作可能需要登录）
      case 2: // 创作中心
        return 'create'; // 创作需要登录
      case 3: // 发现
        return 'view'; // 发现页可以游客浏览
      case 4: // 我的
        return 'view'; // 我的页面可以游客浏览（显示登录提示）
      default:
        return 'view';
    }
  }
}