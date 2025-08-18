import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/sprint3_design_tokens.dart' as sprint3;

/// 通用卡片基础组件
/// 提供统一的卡片样式和交互行为
class BaseCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadows;
  final double? elevation;
  final bool showHoverEffect;
  final bool showRipple;
  final Duration animationDuration;

  const BaseCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.elevation,
    this.showHoverEffect = true,
    this.showRipple = true,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.showHoverEffect) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.showHoverEffect) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    if (!widget.showHoverEffect) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.surface;
    final borderColor = widget.borderColor ?? AppColors.border;
    final borderRadius = widget.borderRadius ?? 16.0;
    final borderWidth = widget.borderWidth ?? 1.0;
    final shadows = widget.shadows ?? sprint3.AppShadows.cardShadow;

    Widget cardChild = Container(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardChild = GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: widget.showRipple
            ? Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: widget.onTap,
                  child: cardChild,
                ),
              )
            : cardChild,
      );
    }

    if (widget.showHoverEffect) {
      cardChild = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: cardChild,
          );
        },
      );
    }

    return cardChild;
  }
}

/// 特定类型的卡片样式预设
class CardPresets {
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets compactPadding = EdgeInsets.all(12.0);
  static const EdgeInsets expandedPadding = EdgeInsets.all(20.0);

  /// AI角色卡片样式
  static BaseCard aiCharacterCard({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return BaseCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: defaultPadding,
      borderRadius: 16.0,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.primary.withOpacity(0.2),
      borderWidth: 1.0,
      shadows: sprint3.AppShadows.cardShadow,
    );
  }

  /// 会员卡片样式
  static BaseCard membershipCard({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    String membershipType = 'free',
  }) {
    return BaseCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: expandedPadding,
      borderRadius: 20.0,
      backgroundColor: AppColors.surface,
      borderColor: sprint3.AppColors.getMembershipColor(membershipType),
      borderWidth: 2.0,
      shadows: sprint3.AppShadows.getMembershipGlowShadow(membershipType),
    );
  }

  /// 推荐内容卡片样式
  static BaseCard recommendationCard({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return BaseCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: defaultPadding,
      borderRadius: 12.0,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      borderWidth: 0.5,
      shadows: sprint3.AppShadows.cardShadow,
    );
  }

  /// 功能卡片样式（发现页面用）
  static BaseCard featureCard({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return BaseCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: compactPadding,
      borderRadius: 12.0,
      backgroundColor: AppColors.cardBackground,
      borderColor: AppColors.divider,
      borderWidth: 0.5,
      shadows: sprint3.AppShadows.cardShadow,
    );
  }
}