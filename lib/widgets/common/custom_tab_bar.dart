import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/sprint3_design_tokens.dart' as sprint3;

/// 自定义Tab栏组件
/// 提供统一的Tab样式和交互行为
class CustomTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final bool showIndicator;
  final bool showUnderline;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? indicatorColor;
  final double indicatorWidth;
  final double indicatorHeight;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment alignment;
  final bool scrollable;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.showIndicator = true,
    this.showUnderline = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
    this.activeColor,
    this.inactiveColor,
    this.indicatorColor,
    this.indicatorWidth = 20,
    this.indicatorHeight = 3,
    this.padding,
    this.alignment = MainAxisAlignment.start,
    this.scrollable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeTextColor = activeColor ?? AppColors.textPrimary;
    final inactiveTextColor = inactiveColor ?? AppColors.textSecondary;
    final indicatorGradient = indicatorColor != null
        ? LinearGradient(colors: [indicatorColor!, indicatorColor!])
        : sprint3.AppColors.goldGradient;

    Widget tabBar = Container(
      height: 56,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: showUnderline
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTabRow(activeTextColor, inactiveTextColor, indicatorGradient),
            )
          : _buildTabRow(activeTextColor, inactiveTextColor, indicatorGradient),
    );

    return tabBar;
  }

  Widget _buildTabRow(
    Color activeTextColor,
    Color inactiveTextColor,
    LinearGradient indicatorGradient,
  ) {
    return Row(
      mainAxisAlignment: scrollable ? MainAxisAlignment.start : alignment,
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final title = entry.value;
        final isActive = currentIndex == index;

        return GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: scrollable ? 16 : 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isActive ? FontWeight.w600 : fontWeight,
                    color: isActive ? activeTextColor : inactiveTextColor,
                    height: 1.0,
                  ),
                ),
                if (showIndicator && isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: indicatorWidth,
                    height: indicatorHeight,
                    decoration: BoxDecoration(
                      gradient: indicatorGradient,
                      borderRadius: BorderRadius.circular(indicatorHeight / 2),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Tab栏预设样式
class TabBarPresets {
  /// 主页Tab栏样式
  static CustomTabBar homeTabBar({
    Key? key,
    required List<String> tabs,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return CustomTabBar(
      key: key,
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      showIndicator: true,
      showUnderline: false,
      activeColor: AppColors.textPrimary,
      inactiveColor: AppColors.textSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollable: true,
    );
  }

  /// 市场页面Tab栏样式（无指示器）
  static CustomTabBar marketplaceTabBar({
    Key? key,
    required List<String> tabs,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return CustomTabBar(
      key: key,
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      showIndicator: false,
      showUnderline: false,
      activeColor: AppColors.primary,
      inactiveColor: AppColors.textSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollable: true,
    );
  }

  /// 小尺寸Tab栏样式
  static CustomTabBar compactTabBar({
    Key? key,
    required List<String> tabs,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return CustomTabBar(
      key: key,
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      fontSize: 13, // 使用减小后的字体
      fontWeight: FontWeight.w500,
      showIndicator: true,
      showUnderline: false,
      activeColor: AppColors.textPrimary,
      inactiveColor: AppColors.textSecondary,
      indicatorWidth: 16,
      indicatorHeight: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollable: true,
    );
  }
}