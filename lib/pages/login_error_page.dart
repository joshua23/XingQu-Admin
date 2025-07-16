import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// 登录异常类型枚举
enum LoginErrorType {
  invalidCode, // 验证码错误
  accountNotFound, // 账号不存在
  networkError, // 网络错误
  serverError, // 服务器错误
  tooManyAttempts, // 尝试次数过多
  agreementRequired, // 未同意协议
}

/// 登录异常页面
/// 提供异常处理、解决方案、客服联系等功能
class LoginErrorPage extends StatefulWidget {
  final LoginErrorType errorType;
  final String? message;

  const LoginErrorPage({
    super.key,
    required this.errorType,
    this.message,
  });

  @override
  State<LoginErrorPage> createState() => _LoginErrorPageState();
}

class _LoginErrorPageState extends State<LoginErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '登录异常',
        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
      ),
      centerTitle: true,
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildErrorInfo(),
          const SizedBox(height: AppDimensions.paddingL),
          _buildSolutions(),
          const SizedBox(height: AppDimensions.paddingL),
          _buildActions(),
          const SizedBox(height: AppDimensions.paddingL),
          _buildContactSupport(),
        ],
      ),
    );
  }

  /// 构建错误信息
  Widget _buildErrorInfo() {
    final errorInfo = _getErrorInfo(widget.errorType);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errorInfo.icon,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Expanded(
                child: Text(
                  errorInfo.title,
                  style: AppTextStyles.h3.copyWith(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            widget.message ?? errorInfo.description,
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  /// 构建解决方案
  Widget _buildSolutions() {
    final solutions = _getSolutions(widget.errorType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '解决方案',
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        ...solutions.asMap().entries.map((entry) {
          final index = entry.key;
          final solution = entry.value;
          return _buildSolutionItem(index + 1, solution);
        }).toList(),
      ],
    );
  }

  /// 构建解决方案项
  Widget _buildSolutionItem(int index, String solution) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$index',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              solution,
              style: AppTextStyles.body1,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速操作',
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _retryLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: Text(
                  '重新登录',
                  style: AppTextStyles.button,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: OutlinedButton(
                onPressed: _clearData,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: Text(
                  '清除数据',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建联系客服
  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, color: AppColors.primary),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                '联系客服',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '如果以上方案都无法解决您的问题，请联系客服获取帮助。',
            style: AppTextStyles.body1,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email,
                  label: '邮箱客服',
                  onTap: _contactEmail,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat,
                  label: '在线客服',
                  onTap: _contactChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建联系按钮
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppDimensions.paddingXS),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  /// 获取错误信息
  _ErrorInfo _getErrorInfo(LoginErrorType type) {
    switch (type) {
      case LoginErrorType.invalidCode:
        return _ErrorInfo(
          icon: Icons.error_outline,
          title: '验证码错误',
          description: '您输入的验证码不正确或已过期，请重新获取验证码。',
        );
      case LoginErrorType.accountNotFound:
        return _ErrorInfo(
          icon: Icons.person_off,
          title: '账号不存在',
          description: '该手机号尚未注册，请检查手机号是否正确或先进行注册。',
        );
      case LoginErrorType.networkError:
        return _ErrorInfo(
          icon: Icons.wifi_off,
          title: '网络连接异常',
          description: '网络连接失败，请检查您的网络设置后重试。',
        );
      case LoginErrorType.serverError:
        return _ErrorInfo(
          icon: Icons.cloud_off,
          title: '服务器异常',
          description: '服务器暂时无法响应，请稍后再试。',
        );
      case LoginErrorType.tooManyAttempts:
        return _ErrorInfo(
          icon: Icons.security,
          title: '尝试次数过多',
          description: '登录尝试次数过多，账号已被临时锁定，请稍后再试。',
        );
      case LoginErrorType.agreementRequired:
        return _ErrorInfo(
          icon: Icons.assignment,
          title: '需要同意协议',
          description: '请阅读并同意《用户协议》和《隐私政策》后再进行登录。',
        );
    }
  }

  /// 获取解决方案
  List<String> _getSolutions(LoginErrorType type) {
    switch (type) {
      case LoginErrorType.invalidCode:
        return [
          '点击"重新获取验证码"获取新的验证码',
          '检查短信是否被拦截或在垃圾短信中',
          '确认手机号输入是否正确',
          '等待片刻再次尝试，验证码可能有延迟',
        ];
      case LoginErrorType.accountNotFound:
        return [
          '检查手机号是否输入正确',
          '使用其他方式登录（如微信登录）',
          '如果是新用户，请先完成注册',
          '联系客服确认账号状态',
        ];
      case LoginErrorType.networkError:
        return [
          '检查WiFi或移动网络连接',
          '尝试切换网络环境',
          '关闭并重新打开应用',
          '清除应用缓存后重试',
        ];
      case LoginErrorType.serverError:
        return [
          '等待几分钟后重新尝试',
          '检查应用是否为最新版本',
          '重启应用再次尝试',
          '如果问题持续，请联系客服',
        ];
      case LoginErrorType.tooManyAttempts:
        return [
          '等待30分钟后再次尝试',
          '检查手机号和验证码是否正确',
          '使用其他登录方式',
          '联系客服解除锁定',
        ];
      case LoginErrorType.agreementRequired:
        return [
          '仔细阅读《用户协议》和《隐私政策》',
          '勾选同意协议的复选框',
          '确认理解并接受相关条款',
          '重新提交登录申请',
        ];
    }
  }

  /// 重新登录
  void _retryLogin() {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// 清除数据
  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('清除数据', style: AppTextStyles.h3),
        content:
            Text('确定要清除所有本地数据吗？这将清除登录信息、缓存等数据。', style: AppTextStyles.body1),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performClearData();
            },
            child: Text('清除',
                style: AppTextStyles.button.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 执行清除数据
  void _performClearData() {
    // TODO: 实现清除数据逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('数据已清除'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 联系邮箱客服
  void _contactEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@xinqu.app'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('客服邮箱已复制到剪贴板'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 联系在线客服
  void _contactChat() {
    // TODO: 实现在线客服功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('在线客服功能开发中'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 错误信息数据类
class _ErrorInfo {
  final IconData icon;
  final String title;
  final String description;

  _ErrorInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}
