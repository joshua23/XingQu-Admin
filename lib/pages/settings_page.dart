import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 设置页面（SettingsPage）
/// 该页面用于展示和管理应用的设置项。
/// 包含Sprint 2功能的快速访问入口。
class SettingsPage extends StatelessWidget {
  /// 构造函数，支持const，便于性能优化。
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold 提供页面结构，包括AppBar和内容区域
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'), // 页面标题
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sprint 2 功能区
          _buildSectionHeader('Sprint 2 新功能'),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            title: '智能推荐',
            subtitle: '基于AI的个性化内容推荐',
            icon: Icons.recommend,
            onTap: () => Navigator.pushNamed(context, '/recommendation'),
          ),
          _buildSettingTile(
            context,
            title: '记忆簿',
            subtitle: '记录和管理您的重要信息',
            icon: Icons.auto_stories,
            onTap: () => Navigator.pushNamed(context, '/memory_book'),
          ),
          
          const SizedBox(height: 24),
          
          // 常规设置区
          _buildSectionHeader('常规设置'),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            title: '账户设置',
            subtitle: '管理您的账户信息',
            icon: Icons.account_circle,
            onTap: () => _showComingSoon(context, '账户设置'),
          ),
          _buildSettingTile(
            context,
            title: '隐私设置',
            subtitle: '控制您的隐私和数据',
            icon: Icons.privacy_tip,
            onTap: () => _showComingSoon(context, '隐私设置'),
          ),
          _buildSettingTile(
            context,
            title: '通知设置',
            subtitle: '管理推送通知',
            icon: Icons.notifications,
            onTap: () => _showComingSoon(context, '通知设置'),
          ),
          
          const SizedBox(height: 24),
          
          // 关于区
          _buildSectionHeader('关于'),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            title: '帮助与反馈',
            subtitle: '获取帮助或提供反馈',
            icon: Icons.help,
            onTap: () => _showComingSoon(context, '帮助与反馈'),
          ),
          _buildSettingTile(
            context,
            title: '关于星趣',
            subtitle: '版本信息和开发团队',
            icon: Icons.info,
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          '敬请期待',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '$feature功能正在开发中，敬请期待！',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '知道了',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '星趣',
      applicationVersion: 'Sprint 2.0',
      applicationIcon: const Icon(
        Icons.star,
        size: 48,
        color: Colors.amber,
      ),
      children: [
        Text(
          '星趣是一个AI驱动的智能交互平台，提供个性化推荐、记忆管理等功能。',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
