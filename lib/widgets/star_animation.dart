import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 星形动效组件 - 为星趣品牌设计提供几何装饰效果
class StarAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final bool autoPlay;
  final int starCount;

  const StarAnimation({
    super.key,
    this.size = 20.0,
    this.color = Colors.amber,
    this.duration = const Duration(seconds: 2),
    this.autoPlay = true,
    this.starCount = 5,
  });

  @override
  State<StarAnimation> createState() => _StarAnimationState();
}

class _StarAnimationState extends State<StarAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.autoPlay) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopAnimation() {
    _rotationController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: StarPainter(
                color: widget.color,
                starCount: widget.starCount,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 星形绘制器
class StarPainter extends CustomPainter {
  final Color color;
  final int starCount;

  StarPainter({
    required this.color,
    required this.starCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path();
    
    // 绘制星形
    for (int i = 0; i < starCount * 2; i++) {
      final angle = (i * math.pi) / starCount;
      final currentRadius = i.isEven ? radius : radius * 0.5;
      
      final x = center.dx + currentRadius * math.cos(angle - math.pi / 2);
      final y = center.dy + currentRadius * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 星形粒子动效组件
class StarParticleEffect extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final int particleCount;
  final Duration duration;

  const StarParticleEffect({
    super.key,
    required this.child,
    this.enabled = true,
    this.particleCount = 8,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<StarParticleEffect> createState() => _StarParticleEffectState();
}

class _StarParticleEffectState extends State<StarParticleEffect>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<StarParticle> _particles;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(widget.particleCount, (index) {
      return StarParticle(
        delay: Duration(milliseconds: index * 200),
        controller: _controller,
      );
    });

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.enabled)
          ..._particles.map((particle) => particle.build(context)),
      ],
    );
  }
}

/// 星形粒子
class StarParticle {
  final Duration delay;
  final AnimationController controller;
  late Animation<double> _animation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  StarParticle({
    required this.delay,
    required this.controller,
  }) {
    _animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = 50 + random.nextDouble() * 30;

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      ),
    ).animate(_animation);

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animation);
  }

  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: StarAnimation(
              size: 12,
              color: Colors.amber.withOpacity(0.8),
              autoPlay: false,
            ),
          ),
        );
      },
    );
  }
}

/// 星形装饰组件 - 用于品牌设计装饰
class StarDecoration extends StatelessWidget {
  final double size;
  final Color color;
  final bool withGlow;

  const StarDecoration({
    super.key,
    this.size = 16.0,
    this.color = Colors.amber,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget star = StarAnimation(
      size: size,
      color: color,
      autoPlay: false,
    );

    if (withGlow) {
      star = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: star,
      );
    }

    return star;
  }
}