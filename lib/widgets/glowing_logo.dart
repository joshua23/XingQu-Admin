import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 带呼吸光环的Logo组件。
/// - Logo固定旋转45°。
/// - 多层光环渐变扩散，呼吸动画。
class GlowingLogo extends StatefulWidget {
  final double size;

  /// [size]为Logo整体区域尺寸，默认120。
  const GlowingLogo({Key? key, this.size = 120}) : super(key: key);

  @override
  State<GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<GlowingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 呼吸动画控制器，2秒一周期反复。
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 多层呼吸光环
          ...List.generate(3, (i) {
            final baseRadius = 40.0 + i * 15;
            final baseOpacity = 0.25 - i * 0.07;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + _controller.value * 0.3;
                return Opacity(
                  opacity: baseOpacity * (1 - _controller.value),
                  child: Container(
                    width: baseRadius * 2 * scale,
                    height: baseRadius * 2 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.5),
                          Colors.transparent,
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // 旋转Logo
          Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
