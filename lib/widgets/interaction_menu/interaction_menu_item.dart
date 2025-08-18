import 'package:flutter/material.dart';
import 'interaction_menu_config.dart';

/// 交互菜单项组件
class InteractionMenuItemWidget extends StatefulWidget {
  final InteractionMenuItem item;
  final VoidCallback onTap;

  const InteractionMenuItemWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<InteractionMenuItemWidget> createState() => _InteractionMenuItemWidgetState();
}

class _InteractionMenuItemWidgetState extends State<InteractionMenuItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标容器
                Container(
                  width: InteractionMenuConfig.iconSize,
                  height: InteractionMenuConfig.iconSize,
                  decoration: BoxDecoration(
                    color: widget.item.customColor ?? InteractionMenuConfig.iconBackground,
                    borderRadius: BorderRadius.circular(InteractionMenuConfig.iconBorderRadius),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: InteractionMenuConfig.iconActiveColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 标签文字
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: InteractionMenuConfig.labelFontSize,
                    color: InteractionMenuConfig.labelColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}