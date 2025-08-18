import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 登录提示对话框组件
/// 当游客用户尝试执行需要认证的操作时显示
class LoginPromptDialog extends StatelessWidget {
  final String action; // 用户尝试执行的操作
  final VoidCallback? onLoginPressed; // 登录按钮回调
  final VoidCallback? onCancelPressed; // 取消按钮回调

  const LoginPromptDialog({
    super.key,
    required this.action,
    this.onLoginPressed,
    this.onCancelPressed,
  });

  /// 显示登录提示对话框的静态方法
  static Future<bool?> show(
    BuildContext context, {
    required String action,
    VoidCallback? onLoginPressed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LoginPromptDialog(
        action: action,
        onLoginPressed: onLoginPressed ?? () => _defaultLoginAction(context),
        onCancelPressed: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// 默认登录操作 - 导航到登录页面
  static void _defaultLoginAction(BuildContext context) {
    Navigator.of(context).pop(true);
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 标题
            Text(
              '需要登录',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 描述文本
            Text(
              _getPromptMessage(action),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 按钮组
            Row(
              children: [
                // 取消按钮
                Expanded(
                  child: TextButton(
                    onPressed: onCancelPressed ?? () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: const Text(
                      '暂不登录',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 登录按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLoginPressed ?? () => _defaultLoginAction(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '立即登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 根据操作类型获取提示消息
  String _getPromptMessage(String action) {
    switch (action.toLowerCase()) {
      case 'subscribe':
      case '订阅':
        return '订阅需要登录后才能使用\n登录后您可以订阅喜欢的角色和内容';
      case 'like':
      case '点赞':
        return '点赞需要登录后才能使用\n登录后您可以为喜欢的内容点赞';
      case 'comment':
      case '评论':
        return '评论需要登录后才能使用\n登录后您可以参与讨论和交流';
      case 'follow':
      case '关注':
        return '关注需要登录后才能使用\n登录后您可以关注感兴趣的用户';
      case 'create':
      case '创作':
        return '创作需要登录后才能使用\n登录后您可以创建和发布内容';
      case 'publish':
      case '发布':
        return '发布需要登录后才能使用\n登录后您可以分享您的作品';
      case 'upload':
      case '上传':
        return '上传需要登录后才能使用\n登录后您可以上传图片和文件';
      case 'edit_profile':
      case '编辑资料':
        return '编辑资料需要登录后才能使用\n登录后您可以完善个人信息';
      default:
        return '此功能需要登录后才能使用\n登录后您可以享受完整的应用体验';
    }
  }
}

/// 快速显示登录提示的扩展方法
extension LoginPromptExtension on BuildContext {
  /// 快速显示登录提示对话框
  Future<bool?> showLoginPrompt(String action) {
    return LoginPromptDialog.show(this, action: action);
  }
}