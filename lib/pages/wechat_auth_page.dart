import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/mock_wechat_service.dart';
import 'main_page_refactored.dart';

/// 微信授权登录页面（高保真还原）
/// 1. 居中微信logo、标题、副标题、授权按钮，米色卡片风格
/// 2. 按钮高亮微信绿，圆角，字体加粗
/// 3. 整体居中，背景为极夜黑半透明蒙层
class WeChatAuthPage extends StatefulWidget {
  const WeChatAuthPage({Key? key}) : super(key: key);

  @override
  State<WeChatAuthPage> createState() => _WeChatAuthPageState();
}

class _WeChatAuthPageState extends State<WeChatAuthPage> {
  final MockWeChatService _mockWechatService = MockWeChatService();
  bool _isLoading = false;
  int _selectedUserIndex = -1; // -1表示随机用户

  @override
  void initState() {
    super.initState();
    _initWeChatService();
  }

  /// 初始化微信服务
  Future<void> _initWeChatService() async {
    await _mockWechatService.initialize();
  }

  /// 处理微信登录
  Future<void> _handleWechatLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 检查微信是否安装（模拟）
      final isInstalled = await _mockWechatService.checkWeChatInstalled();
      if (!isInstalled) {
        _showError('请先安装微信应用');
        return;
      }

      // 执行模拟微信登录流程
      MockWeChatLoginResult result;
      if (_selectedUserIndex >= 0) {
        // 使用指定用户登录
        final users = _mockWechatService.getAllMockUsers();
        result = await _mockWechatService.loginWithSpecificUser(users[_selectedUserIndex].openId);
      } else {
        // 随机用户登录
        result = await _mockWechatService.completeLogin();
      }
      
      if (result.isSuccess) {
        // 登录成功，更新认证状态
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // 使用专门的微信登录方法
        await authProvider.loginWithWeChat(
          wechatOpenId: result.user!.openId,
          nickname: result.user!.nickname,
          avatarUrl: result.user!.avatarUrl,
        );

        // 显示登录成功提示
        _showSuccess('微信登录成功！欢迎 ${result.user!.nickname}');

        // 导航到主页面
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPageRefactored()),
        );
      } else {
        _showError(result.errorMessage ?? '微信登录失败');
      }
    } catch (e) {
      debugPrint('❌ 微信登录异常: $e');
      _showError('微信登录遇到问题，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  /// 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示成功信息
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.primary, // 米色卡片
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 微信logo
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.wechat, color: AppColors.wechat, size: 40),
                ),
              ),
              // 标题
              const Text(
                '微信授权登录',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              // 开发模式：用户选择
              _buildUserSelector(),
              const SizedBox(height: 24),
              // 授权按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleWechatLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : AppColors.wechat,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('登录中...'),
                          ],
                        )
                      : const Text('授权并登录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建用户选择器（开发模式）
  Widget _buildUserSelector() {
    final users = _mockWechatService.getAllMockUsers();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '开发模式 - 选择测试用户:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // 随机用户选项
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUserIndex = -1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedUserIndex == -1 ? AppColors.wechat : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedUserIndex == -1 ? AppColors.wechat : Colors.grey[400]!,
                    ),
                  ),
                  child: Text(
                    '随机用户',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedUserIndex == -1 ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              // 具体用户选项
              ...users.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                final isSelected = _selectedUserIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.wechat : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.wechat : Colors.grey[400]!,
                      ),
                    ),
                    child: Text(
                      user.nickname,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
