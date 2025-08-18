import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'auth_debug_page.dart';
import 'package:flutter/foundation.dart';

/// 个人中心页（Profile Page）
/// 展示用户信息、编辑资料、设置入口、退出登录等 - 现代化设计风格
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> 
    with TickerProviderStateMixin {
  
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // 用户统计数据
  final Map<String, dynamic> _userStats = {
    'stories': 12,
    'characters': 8,
    'followers': 156,
    'following': 89,
  };
  
  // 功能菜单项
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.edit_outlined,
      'activeIcon': Icons.edit,
      'title': '编辑资料',
      'subtitle': '个性化你的个人信息',
      'color': Colors.blue,
      'route': '/edit_profile',
    },
    {
      'icon': Icons.menu_book_outlined,
      'activeIcon': Icons.menu_book,
      'title': '我的故事',
      'subtitle': '查看创作的所有故事',
      'color': Colors.purple,
      'route': '/my_stories',
    },
    {
      'icon': Icons.smart_toy_outlined,
      'activeIcon': Icons.smart_toy,
      'title': '我的角色',
      'subtitle': '管理创建的AI角色',
      'color': Colors.orange,
      'route': '/my_characters',
    },
    {
      'icon': Icons.favorite_outline,
      'activeIcon': Icons.favorite,
      'title': '我的收藏',
      'subtitle': '收藏的内容和角色',
      'color': Colors.pink,
      'route': '/my_favorites',
    },
    {
      'icon': Icons.history_outlined,
      'activeIcon': Icons.history,
      'title': '使用记录',
      'subtitle': '查看历史互动记录',
      'color': Colors.green,
      'route': '/usage_history',
    },
    {
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings,
      'title': '设置',
      'subtitle': '个性化设置和偏好',
      'color': Colors.grey,
      'route': '/settings',
    },
    if (kDebugMode) {
      'icon': Icons.bug_report_outlined,
      'activeIcon': Icons.bug_report,
      'title': '认证调试',
      'subtitle': '测试认证系统功能',
      'color': Colors.red,
      'route': '/auth_debug',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// 显示退出登录确认对话框
  /// [context] 上下文
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            '确认退出',
            style: AppTextStyles.h3,
          ),
          content: const Text(
            '确定要退出登录吗？',
            style: AppTextStyles.body1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 关闭对话框
                await _performLogout(context);
              },
              child: const Text(
                '确定',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 执行退出登录操作
  /// [context] 上下文
  Future<void> _performLogout(BuildContext context) async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        },
      );

      // 执行退出登录
      final authService = AuthService();
      await authService.signOut();

      // 关闭加载指示器
      if (context.mounted) {
        Navigator.of(context).pop();

        // 导航到登录页面并清除所有页面栈
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (context.mounted) {
        Navigator.of(context).pop();

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退出登录失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 自定义头部
            _buildCustomHeader(),
            
            // 用户信息区域
            SliverToBoxAdapter(
              child: _buildUserProfileSection(),
            ),
            
            // 用户统计数据
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),
            
            // 功能菜单列表
            SliverToBoxAdapter(
              child: _buildMenuSection(),
            ),
            
            // 退出登录按钮
            SliverToBoxAdapter(
              child: _buildLogoutSection(),
            ),
            
            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建自定义头部
  Widget _buildCustomHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background.withOpacity(0.95),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '个人中心',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              _showMoreOptions(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.more_vert,
                color: AppColors.accent,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建用户信息区域
  Widget _buildUserProfileSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 用户头像和编辑按钮
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.accent.withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🎆',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              
              // 编辑按钮
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _onEditProfileTap(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 用户名称
          Text(
            '星趣用户',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 用户ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: 10001',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 用户签名
          Text(
            '探索无限可能的AI世界 🌌',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// 构建统计数据区域
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('故事', _userStats['stories'], Icons.menu_book, Colors.purple),
          const SizedBox(width: 12),
          _buildStatCard('角色', _userStats['characters'], Icons.smart_toy, Colors.orange),
          const SizedBox(width: 12),
          _buildStatCard('粉丝', _userStats['followers'], Icons.favorite, Colors.pink),
          const SizedBox(width: 12),
          _buildStatCard('关注', _userStats['following'], Icons.person_add, Colors.blue),
        ],
      ),
    );
  }
  
  /// 构建统计卡片
  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
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
  
  /// 构建功能菜单区域
  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              '功能菜单',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ..._menuItems.map((item) => _buildMenuItem(item)),
        ],
      ),
    );
  }
  
  /// 构建功能菜单项
  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (item['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            item['icon'],
            color: item['color'],
            size: 24,
          ),
        ),
        title: Text(
          item['title'],
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item['subtitle'],
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onTap: () {
          _onMenuItemTap(item);
        },
      ),
    );
  }
  
  /// 构建退出登录区域
  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '退出登录',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 显示更多选项
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Icon(
                Icons.share,
                color: AppColors.primary,
              ),
              title: Text(
                '分享个人资料',
                style: AppTextStyles.body1,
              ),
              onTap: () {
                Navigator.pop(context);
                // 处理分享
              },
            ),
            
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: AppColors.accent,
              ),
              title: Text(
                '帮助与反馈',
                style: AppTextStyles.body1,
              ),
              onTap: () {
                Navigator.pop(context);
                // 处理帮助
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  /// 处理编辑资料点击
  void _onEditProfileTap() {
    debugPrint('点击编辑资料');
    // TODO: 导航到编辑资料页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑资料功能开发中...')),
    );
  }
  
  /// 处理菜单项点击
  void _onMenuItemTap(Map<String, dynamic> item) {
    debugPrint('点击菜单项: ${item['title']}');
    
    if (item['route'] == '/settings') {
      Navigator.of(context).pushNamed('/settings');
    } else if (item['route'] == '/auth_debug') {
      // 认证调试页面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AuthDebugPage(),
        ),
      );
    } else {
      // TODO: 实现其他功能
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['title']}功能开发中...')),
      );
    }
  }
}
