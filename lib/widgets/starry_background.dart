import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 星空渐变背景组件（高保真还原登录页）
/// - 背景为135°深色渐变。
/// - 规则网格分布五角星，品牌主色，低透明度，无动画。
class StarryBackground extends StatelessWidget {
  final Widget child;
  final double starSize;
  final double starSpacing;

  /// [child]为包裹内容，[starSize]为五角星边长，[starSpacing]为星星间距。
  const StarryBackground(
      {Key? key,
      required this.child,
      this.starSize = 48,
      this.starSpacing = 16})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 渐变背景
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
            ),
          ),
        ),
        // 2. 规则网格五角星层
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter:
              _StarGridPainter(starSize: starSize, starSpacing: starSpacing),
        ),
        // 3. 主要内容
        child,
      ],
    );
  }
}

/// 规则网格五角星Painter，高保真还原原型SVG平铺效果。
class _StarGridPainter extends CustomPainter {
  final double starSize;
  final double starSpacing;
  _StarGridPainter({required this.starSize, required this.starSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    // 计算行列数，保证全屏覆盖
    final int cols = (size.width / (starSize + starSpacing)).ceil();
    final int rows = (size.height / (starSize + starSpacing)).ceil();
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double dx = col * (starSize + starSpacing);
        final double dy = row * (starSize + starSpacing);
        _drawStar(canvas, Offset(dx, dy), starSize / 2, paint);
      }
    }
  }

  /// 绘制五角星，中心为center，外接圆半径为radius
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const int points = 5;
    final Path path = Path();
    for (int i = 0; i < points; i++) {
      final double angle = (pi / 2) + (2 * pi * i / points);
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy - radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final double angle2 = angle + pi / points;
      final double x2 = center.dx + radius * 0.5 * cos(angle2);
      final double y2 = center.dy - radius * 0.5 * sin(angle2);
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
