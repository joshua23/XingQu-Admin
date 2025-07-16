import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

/// iOS风格状态栏组件
/// 模拟iPhone状态栏的外观和布局
class StatusBar extends StatelessWidget {
  /// 是否显示状态栏
  final bool visible;

  /// 时间显示文本
  final String timeText;

  /// 电池电量百分比 (0-100)
  final int batteryLevel;

  const StatusBar({
    super.key,
    this.visible = true,
    this.timeText = '9:41',
    this.batteryLevel = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      height: AppDimensions.statusBarHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        // 添加模糊效果背景
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧时间显示
            _buildTimeDisplay(),

            // 右侧状态图标组
            _buildStatusIcons(),
          ],
        ),
      ),
    );
  }

  /// 构建时间显示组件
  /// 返回显示当前时间的Widget
  Widget _buildTimeDisplay() {
    return Text(
      timeText,
      style: AppTextStyles.body1.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  /// 构建状态图标组
  /// 包含信号、WiFi、电池等状态指示器
  Widget _buildStatusIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 信号强度图标
        const FaIcon(
          FontAwesomeIcons.signal,
          size: 14,
          color: Colors.white,
        ),

        const SizedBox(width: 5),

        // WiFi图标
        const FaIcon(
          FontAwesomeIcons.wifi,
          size: 14,
          color: Colors.white,
        ),

        const SizedBox(width: 5),

        // 电池电量显示
        _buildBatteryIndicator(),
      ],
    );
  }

  /// 构建电池电量指示器
  /// 根据电量百分比显示不同的电池状态
  Widget _buildBatteryIndicator() {
    // 计算电池填充宽度
    final double fillWidth = (24 * batteryLevel / 100).clamp(0, 24);

    // 根据电量选择颜色
    Color batteryColor = AppColors.success;
    if (batteryLevel <= 20) {
      batteryColor = AppColors.error;
    } else if (batteryLevel <= 50) {
      batteryColor = AppColors.warning;
    }

    return Stack(
      children: [
        // 电池外框
        Container(
          width: 24,
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // 电池正极
        Positioned(
          right: -3,
          top: 3,
          child: Container(
            width: 2,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(1),
                bottomRight: Radius.circular(1),
              ),
            ),
          ),
        ),

        // 电池电量填充
        Positioned(
          left: 1,
          top: 1,
          child: Container(
            width: fillWidth - 2,
            height: 10,
            decoration: BoxDecoration(
              color: batteryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
