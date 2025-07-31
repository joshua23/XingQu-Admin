import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_bar.dart';
import '../widgets/bottom_navigation_refactored.dart';
import 'home_refactored.dart';
import 'messages_page.dart';
import 'creation_center_refactored.dart';
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
    const CreationCenterRefactored(),    // 创作中心（重构版）
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
      body: Column(
        children: [
          // 状态栏
          const StatusBar(),
          
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
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}