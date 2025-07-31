import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
// import 'package:fluwx/fluwx.dart' as fluwx; // 暂时注释掉微信SDK
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

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
  @override
  void initState() {
    super.initState();
    // _initFluwx(); // 暂时注释掉微信初始化
  }

  /// 初始化fluwx - 暂时注释掉
  // Future<void> _initFluwx() async {
  //   await fluwx.registerWxApi(
  //     appId: 'YOUR_WECHAT_APP_ID', // 替换为实际微信App ID
  //     universalLink: 'YOUR_UNIVERSAL_LINK', // iOS Universal Link
  //   );
  // }

  /// 处理微信登录 - 暂时注释掉
  // Future<void> _handleWechatLogin() async {
  //   try {
  //     final result = await fluwx.sendWeChatAuth(
  //       scope: 'snsapi_userinfo',
  //       state: 'wechat_sdk_demo_test',
  //     );
  //     if (result.code == 0) {
  //       // 授权成功，获取access_token和用户信息
  //       // TODO: 调用后端API交换code for token
  //       // 假设成功后
  //       await Provider.of<AuthProvider>(context, listen: false).login();
  //       Navigator.of(context).pushReplacement(
  //         MaterialPageRoute(builder: (context) => const HomePage()),
  //       );
  //     } else {
  //       // 授权失败
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('微信授权失败: ${result.errStr}'))
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('微信登录异常: $e'))
  //     );
  //   }
  // }

  /// 临时处理函数 - 显示提示信息
  Future<void> _handleWechatLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('微信登录功能正在配置中，请先使用短信登录'))
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
              const SizedBox(height: 24),
              // 授权按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleWechatLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wechat,
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
                  child: const Text('授权并登录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
