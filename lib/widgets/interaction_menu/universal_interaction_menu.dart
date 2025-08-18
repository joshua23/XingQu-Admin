import 'package:flutter/material.dart';
import 'interaction_menu_config.dart';
import 'interaction_menu_item.dart';
import '../star_animation.dart';

/// 通用交互功能菜单组件
class UniversalInteractionMenu extends StatefulWidget {
  final PageType pageType;
  final VoidCallback onClose;
  final Function(InteractionType) onActionSelected;

  const UniversalInteractionMenu({
    super.key,
    required this.pageType,
    required this.onClose,
    required this.onActionSelected,
  });

  @override
  State<UniversalInteractionMenu> createState() => _UniversalInteractionMenuState();
}

class _UniversalInteractionMenuState extends State<UniversalInteractionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: InteractionMenuConfig.showAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: InteractionMenuConfig.animationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: InteractionMenuConfig.animationCurve,
    ));

    // 启动进入动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 关闭菜单
  Future<void> _closeMenu() async {
    await _animationController.reverse();
    widget.onClose();
  }

  /// 处理菜单项点击
  void _onMenuItemTap(InteractionType type) {
    widget.onActionSelected(type);
    _closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = InteractionMenuConfig.getMenuItems(widget.pageType);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // 背景遮罩
            GestureDetector(
              onTap: _closeMenu,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
              ),
            ),
            
            // 菜单内容
            Positioned(
              left: 0,
              right: 0,
              bottom: _slideAnimation.value * -InteractionMenuConfig.menuHeight,
              child: Container(
                height: InteractionMenuConfig.menuHeight,
                decoration: BoxDecoration(
                  color: InteractionMenuConfig.menuBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // 抽屉手柄和星形装饰
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const StarDecoration(
                            size: 12,
                            color: Colors.amber,
                            withGlow: true,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const StarDecoration(
                            size: 12,
                            color: Colors.amber,
                            withGlow: true,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 菜单项目
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: menuItems.map((item) {
                              return Container(
                                margin: EdgeInsets.only(
                                  right: menuItems.last == item ? 0 : InteractionMenuConfig.iconSpacing,
                                ),
                                child: InteractionMenuItemWidget(
                                  item: item,
                                  onTap: () => _onMenuItemTap(item.type),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 交互菜单触发器组件
class InteractionMenuTrigger {
  /// 构建加号按钮
  static Widget buildPlusButton({
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: InteractionMenuConfig.plusButtonSize,
        height: InteractionMenuConfig.plusButtonSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(InteractionMenuConfig.plusButtonBorderRadius),
          border: Border.all(
            color: isActive ? InteractionMenuConfig.iconActiveColor : Colors.white,
            width: InteractionMenuConfig.plusButtonBorderWidth,
          ),
          color: isActive ? InteractionMenuConfig.iconActiveColor.withOpacity(0.2) : Colors.transparent,
        ),
        child: Icon(
          isActive ? Icons.close : Icons.add,
          color: isActive ? InteractionMenuConfig.iconActiveColor : Colors.white,
          size: InteractionMenuConfig.plusIconSize,
        ),
      ),
    );
  }

  /// 显示菜单
  static void showMenu({
    required BuildContext context,
    required PageType pageType,
    required Function(InteractionType) onActionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => UniversalInteractionMenu(
        pageType: pageType,
        onClose: () => Navigator.of(context).pop(),
        onActionSelected: (type) {
          Navigator.of(context).pop();
          onActionSelected(type);
        },
      ),
    );
  }
}