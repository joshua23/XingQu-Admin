import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'dart:math' as math;

/// 启动页（Splash Screen）
/// 展示品牌Logo、App名称、加载动画，3秒后自动跳转到登录页
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<double> _slideAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _progressAnim;
  late Animation<double> _glowScaleAnim;
  late Animation<double> _glowOpacityAnim;

  @override
  void initState() {
    super.initState();
    // 微光呼吸动画
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowScaleAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacityAnim = Tween<double>(begin: 0.32, end: 0.60).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    // 整体滑入动画
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnim = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
    // 进度条动画
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _progressAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    // 3秒后自动跳转
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 深色渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
              ),
            ),
          ),
          // 星星动画层
          _AnimatedStars(),
          // splash-content整体滑入动画
          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              );
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // logo固定45°+多层微光呼吸动画
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      // 多层发散微光参数
                      final List<_GlowLayer> layers = [
                        _GlowLayer(
                          baseRadius: 60,
                          scale: 1.0 + 0.10 * _glowScaleAnim.value,
                          color: const Color(0xFFF5DFAF)
                              .withOpacity(0.30 * _glowOpacityAnim.value),
                        ),
                        _GlowLayer(
                          baseRadius: 90,
                          scale: 1.0 + 0.18 * _glowScaleAnim.value,
                          color: const Color(0xFFFF4D67)
                              .withOpacity(0.16 * _glowOpacityAnim.value),
                        ),
                        _GlowLayer(
                          baseRadius: 120,
                          scale: 1.0 + 0.25 * _glowScaleAnim.value,
                          color: const Color(0xFFF5DFAF)
                              .withOpacity(0.08 * _glowOpacityAnim.value),
                        ),
                      ];
                      return Transform.rotate(
                        angle: math.pi / 4, // 固定45度
                        child: Container(
                          width: 120,
                          height: 120,
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 多层发散微光
                              for (final layer in layers)
                                AnimatedBuilder(
                                  animation: _glowController,
                                  builder: (context, _) {
                                    return Container(
                                      width: layer.baseRadius * layer.scale,
                                      height: layer.baseRadius * layer.scale,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: layer.color,
                                      ),
                                    );
                                  },
                                ),
                              // logo图片
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x4DF5DFAF),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  // 主标题
                  const Text(
                    '星趣',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF5DFAF),
                      shadows: [
                        Shadow(
                          color: Color(0x80F5DFAF),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 副标题
                  const Text(
                    '发现有趣的故事，遇见有趣的人',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFCFCFCF),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // 加载动画
                  _AnimatedSplashBar(progressAnim: _progressAnim),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 星星动画层，分布与原型一致
class _AnimatedStars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _TwinkleStar(top: 0.20, left: 0.10, delay: 0),
        _TwinkleStar(top: 0.30, left: 0.80, delay: 0.5),
        _TwinkleStar(top: 0.60, left: 0.20, delay: 1.0),
        _TwinkleStar(top: 0.80, left: 0.70, delay: 1.5),
        _TwinkleStar(top: 0.40, left: 0.90, delay: 2.0),
        _TwinkleStar(top: 0.70, left: 0.50, delay: 0.8),
      ],
    );
  }
}

/// 单颗星星twinkle动画
class _TwinkleStar extends StatefulWidget {
  final double top, left, delay;
  const _TwinkleStar(
      {required this.top, required this.left, required this.delay});
  @override
  State<_TwinkleStar> createState() => _TwinkleStarState();
}

class _TwinkleStarState extends State<_TwinkleStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _opacityAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * widget.top,
      left: MediaQuery.of(context).size.width * widget.left,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          );
        },
        child: const Icon(Icons.star, color: Color(0xFFF5DFAF), size: 14),
      ),
    );
  }
}

/// 加载进度条动画
class _AnimatedSplashBar extends StatelessWidget {
  final Animation<double> progressAnim;
  const _AnimatedSplashBar({required this.progressAnim});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0x33F5DFAF),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: progressAnim,
        builder: (context, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 200 * progressAnim.value,
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5DFAF), Color(0xFFFF4D67)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 多层微光参数结构体
class _GlowLayer {
  final double baseRadius;
  final double scale;
  final Color color;
  _GlowLayer(
      {required this.baseRadius, required this.scale, required this.color});
}
