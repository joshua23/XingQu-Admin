import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

/// 个人中心页（Profile Page）
/// 展示用户信息、编辑资料、设置入口、退出登录等
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        children: [
          const SizedBox(height: 32),
          // 用户信息
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surfaceVariant,
                  child: const Icon(Icons.person,
                      size: 48, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text('昵称：星趣用户', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('ID: 10001', style: AppTextStyles.body2),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 编辑资料
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('编辑资料', style: AppTextStyles.body1),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              // TODO: 实现编辑资料功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('编辑资料功能开发中...')),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          // 我的故事
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppColors.accent),
            title: const Text('我的故事', style: AppTextStyles.body1),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              // TODO: 实现我的故事功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('我的故事功能开发中...')),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          // 设置入口
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.secondary),
            title: const Text('设置', style: AppTextStyles.body1),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          // 退出登录
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('退出登录', style: AppTextStyles.body1),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}
