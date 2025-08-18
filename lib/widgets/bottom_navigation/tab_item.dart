import 'package:flutter/material.dart';

/// Tab项的类型枚举
enum TabItemType {
  text,      // 纯文字Tab
  icon,      // 图标Tab
  special,   // 特殊Tab（如创作中心）
}

/// Tab项数据模型
class TabItemData {
  final int index;
  final String? label;
  final IconData? icon;
  final String? emoji;
  final TabItemType type;
  final VoidCallback? onTap;

  const TabItemData({
    required this.index,
    this.label,
    this.icon,
    this.emoji,
    required this.type,
    this.onTap,
  });
}

/// 可复用的Tab项组件
class TabItem extends StatelessWidget {
  final TabItemData data;
  final bool isActive;
  final VoidCallback? onTap;

  const TabItem({
    super.key,
    required this.data,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case TabItemType.text:
        return _buildTextTab();
      case TabItemType.icon:
        return _buildIconTab();
      case TabItemType.special:
        return _buildSpecialTab();
    }
  }

  /// 构建纯文字Tab项
  Widget _buildTextTab() {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive 
                ? const Color(0xFFFFC542).withOpacity(0.1) 
                : Colors.transparent,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isActive ? 14 : 12,
                color: isActive 
                    ? const Color(0xFFFFC542) 
                    : const Color(0xFF8E8E93),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'SF Pro Text',
              ),
              child: Text(
                data.label ?? '',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图标Tab项
  Widget _buildIconTab() {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isActive ? 1.1 : 1.0,
                child: Icon(
                  data.icon,
                  size: 24,
                  color: isActive 
                      ? const Color(0xFFFFC542) 
                      : const Color(0xFF8E8E93),
                ),
              ),
              if (data.label != null) ...[
                const SizedBox(height: 2),
                Text(
                  data.label!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive 
                        ? const Color(0xFFFFC542) 
                        : const Color(0xFF8E8E93),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建特殊Tab项（如创作中心）
  Widget _buildSpecialTab() {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.1 : 1.0,
              child: Text(
                data.emoji ?? '✨',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.0,
                  color: isActive 
                      ? const Color(0xFFFFC542) 
                      : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
