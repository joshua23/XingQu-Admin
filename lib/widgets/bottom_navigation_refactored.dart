import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'bottom_navigation/tab_item.dart';
import 'bottom_navigation/tab_config.dart';

/// 重构后的底部导航组件
/// 基于设计规范: Material Design + iOS Human Interface Guidelines
/// Tab栏高度: Android 56dp, iOS 68pt, 中国市场常见 44px
/// 可点击区域: 至少 44×44px
class BottomNavigationRefactored extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<TabItemData>? customTabs;

  const BottomNavigationRefactored({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.customTabs,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = customTabs ?? TabConfig.getDefaultTabs();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: const Border(
          top: BorderSide(
            color: Color(0xFF1C1C1E),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68, // 增加高度以适配图标
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tabData) {
              return TabItem(
                data: tabData,
                isActive: currentIndex == tabData.index,
                onTap: () => onTap(tabData.index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

}

