import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_prompt_dialog.dart';

/// 认证守卫服务
/// 提供统一的认证检查和处理方法
class AuthGuardService {
  /// 检查并执行需要认证的操作
  /// 如果用户未登录且操作需要认证，显示登录提示；否则执行操作
  /// 
  /// [context] - 上下文
  /// [action] - 操作类型（如 'subscribe', 'like', 'comment' 等）
  /// [operation] - 需要执行的操作回调
  /// [showPrompt] - 是否显示登录提示（默认true）
  /// 
  /// 返回 true 表示操作已执行或用户选择登录，false 表示操作被阻止
  static Future<bool> checkAndExecute(
    BuildContext context, {
    required String action,
    required VoidCallback operation,
    bool showPrompt = true,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 检查是否需要认证
    if (!authProvider.requiresAuthentication(action)) {
      // 不需要认证，直接执行操作
      operation();
      return true;
    }
    
    // 需要认证但用户未登录
    if (showPrompt) {
      final shouldLogin = await LoginPromptDialog.show(
        context,
        action: action,
      );
      
      return shouldLogin ?? false;
    }
    
    return false;
  }

  /// 检查操作权限（不执行操作，只检查）
  /// 
  /// [context] - 上下文
  /// [action] - 操作类型
  /// 
  /// 返回 true 表示可以执行操作，false 表示需要登录
  static bool canExecute(BuildContext context, String action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.canPerformAction(action);
  }

  /// 静默检查认证状态（不显示提示）
  /// 
  /// [context] - 上下文
  /// [action] - 操作类型
  /// 
  /// 返回 true 表示已认证，false 表示需要登录
  static bool isAuthenticated(BuildContext context, String action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return !authProvider.requiresAuthentication(action);
  }

  /// 为按钮等UI组件提供的包装方法
  /// 自动根据认证状态调整按钮状态和行为
  /// 
  /// [context] - 上下文
  /// [action] - 操作类型
  /// [child] - 子组件
  /// [onPressed] - 点击回调
  /// [disabledChild] - 禁用时的子组件（可选）
  static Widget wrapWithAuthCheck(
    BuildContext context, {
    required String action,
    required Widget child,
    required VoidCallback onPressed,
    Widget? disabledChild,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final canExecute = authProvider.canPerformAction(action);
        
        if (canExecute) {
          // 可以执行操作
          return GestureDetector(
            onTap: onPressed,
            child: child,
          );
        } else {
          // 需要登录才能执行
          return GestureDetector(
            onTap: () async {
              await LoginPromptDialog.show(context, action: action);
            },
            child: disabledChild ?? child,
          );
        }
      },
    );
  }
}

/// AuthGuard Widget - 用于包装需要认证的UI组件
class AuthGuard extends StatelessWidget {
  final String action;
  final Widget child;
  final Widget? guestChild; // 游客模式下显示的组件
  final bool hideForGuests; // 是否对游客隐藏组件

  const AuthGuard({
    super.key,
    required this.action,
    required this.child,
    this.guestChild,
    this.hideForGuests = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final canExecute = authProvider.canPerformAction(action);
        
        if (canExecute) {
          return child;
        } else if (hideForGuests) {
          return const SizedBox.shrink();
        } else if (guestChild != null) {
          return guestChild!;
        } else {
          // 显示需要登录的提示版本
          return Opacity(
            opacity: 0.6,
            child: child,
          );
        }
      },
    );
  }
}

/// 快速认证检查的扩展方法
extension AuthGuardExtension on BuildContext {
  /// 检查并执行需要认证的操作
  Future<bool> checkAuth(String action, VoidCallback operation) {
    return AuthGuardService.checkAndExecute(
      this,
      action: action,
      operation: operation,
    );
  }

  /// 检查是否可以执行操作
  bool canExecuteAction(String action) {
    return AuthGuardService.canExecute(this, action);
  }

  /// 检查是否已认证
  bool isAuthenticatedFor(String action) {
    return AuthGuardService.isAuthenticated(this, action);
  }
}