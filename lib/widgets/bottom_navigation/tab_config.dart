import 'package:flutter/material.dart';
import 'tab_item.dart';

/// Tab栏配置类
class TabConfig {
  /// 获取默认的Tab项配置
  static List<TabItemData> getDefaultTabs() {
    return [
      const TabItemData(
        index: 0,
        label: '首页',
        type: TabItemType.text,
      ),
      const TabItemData(
        index: 1,
        label: '消息',
        type: TabItemType.text,
      ),
      const TabItemData(
        index: 2,
        emoji: '✨',
        type: TabItemType.special,
      ),
      const TabItemData(
        index: 3,
        label: '发现',
        type: TabItemType.text,
      ),
      const TabItemData(
        index: 4,
        label: '我的',
        type: TabItemType.text,
      ),
    ];
  }

  /// 获取带图标的Tab项配置（备用方案）
  static List<TabItemData> getIconTabs() {
    return [
      const TabItemData(
        index: 0,
        label: '首页',
        icon: Icons.home_outlined,
        type: TabItemType.icon,
      ),
      const TabItemData(
        index: 1,
        label: '消息',
        icon: Icons.chat_bubble_outline,
        type: TabItemType.icon,
      ),
      const TabItemData(
        index: 2,
        emoji: '✨',
        type: TabItemType.special,
      ),
      const TabItemData(
        index: 3,
        label: '发现',
        icon: Icons.explore_outlined,
        type: TabItemType.icon,
      ),
      const TabItemData(
        index: 4,
        label: '我的',
        icon: Icons.person_outline,
        type: TabItemType.icon,
      ),
    ];
  }
}
