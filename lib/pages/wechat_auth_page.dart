import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 微信授权登录页面（高保真还原）
/// 1. 居中微信logo、标题、副标题、授权按钮，米色卡片风格
/// 2. 按钮高亮微信绿，圆角，字体加粗
/// 3. 整体居中，背景为极夜黑半透明蒙层
class WeChatAuthPage extends StatelessWidget {
  const WeChatAuthPage({Key? key}) : super(key: key);

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
                  onPressed: () {
                    // TODO: 实现微信授权逻辑
                  },
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
