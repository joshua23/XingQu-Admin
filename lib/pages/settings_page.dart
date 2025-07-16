import 'package:flutter/material.dart';

/// 设置页面（SettingsPage）
/// 该页面用于展示和管理应用的设置项。
/// 当前为基础实现，可根据需求扩展。
class SettingsPage extends StatelessWidget {
  /// 构造函数，支持const，便于性能优化。
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold 提供页面结构，包括AppBar和内容区域
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'), // 页面标题
      ),
      body: const Center(
        // 页面主体内容，后续可扩展为设置项列表
        child: Text('这里是设置页面'),
      ),
    );
  }
}
