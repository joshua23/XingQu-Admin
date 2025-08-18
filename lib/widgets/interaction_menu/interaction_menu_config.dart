import 'package:flutter/material.dart';

/// 交互功能类型枚举
enum InteractionType {
  reload,        // 重新加载 🔄
  voiceCall,     // 语音通话 📞  
  image,         // 图片 🖼️
  link,          // 链接 🔗
  share,         // 分享 📱
  report,        // 举报 🚩
  camera,        // 相机 📸
  location,      // 位置 📍
  file,          // 文件 📁
  gift,          // 礼物 🎁
}

/// 页面类型枚举
enum PageType {
  aiInteraction,     // AI互动页面（精选页、FM页）
  gridRecommendation, // 网格推荐页面（综合页子页面）
}

/// 交互菜单项数据模型
class InteractionMenuItem {
  final InteractionType type;
  final IconData icon;
  final String label;
  final Color? customColor;
  
  const InteractionMenuItem(
    this.type, 
    this.icon, 
    this.label, 
    {this.customColor}
  );
}

/// 交互功能菜单配置类
class InteractionMenuConfig {
  // 菜单样式配置
  static const double menuHeight = 200.0;
  static const double iconSize = 50.0;
  static const double iconBorderRadius = 25.0;
  static const double labelFontSize = 12.0;
  static const double iconSpacing = 16.0;
  
  // 颜色配置
  static final Color menuBackground = Colors.black.withOpacity(0.9);
  static final Color iconBackground = Colors.grey.shade800;
  static const Color iconActiveColor = Colors.amber;
  static final Color labelColor = Colors.grey.shade400;
  
  // 动画配置
  static const Duration showAnimation = Duration(milliseconds: 300);
  static const Duration hideAnimation = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeInOut;
  
  /// 根据页面类型获取菜单项配置
  static List<InteractionMenuItem> getMenuItems(PageType pageType) {
    switch (pageType) {
      case PageType.aiInteraction:  // 精选页、FM页
        return [
          const InteractionMenuItem(InteractionType.reload, Icons.refresh, '重新加载'),
          const InteractionMenuItem(InteractionType.voiceCall, Icons.call, '语音通话'),
          const InteractionMenuItem(InteractionType.image, Icons.image, '图片'),
          const InteractionMenuItem(InteractionType.camera, Icons.camera_alt, '相机'),
          const InteractionMenuItem(InteractionType.gift, Icons.card_giftcard, '礼物'),
          const InteractionMenuItem(InteractionType.share, Icons.share, '分享'),
        ];
        
      case PageType.gridRecommendation:  // 综合页子页面
        return [
          const InteractionMenuItem(InteractionType.reload, Icons.refresh, '刷新'),
          const InteractionMenuItem(InteractionType.image, Icons.image, '图片'),
          const InteractionMenuItem(InteractionType.link, Icons.link, '链接'),
          const InteractionMenuItem(InteractionType.share, Icons.share, '分享'),
          const InteractionMenuItem(InteractionType.file, Icons.folder, '文件'),
          const InteractionMenuItem(InteractionType.report, Icons.flag, '举报'),
        ];
    }
  }
  
  /// 获取加号按钮样式配置
  static const double plusButtonSize = 36.0;
  static const double plusButtonBorderRadius = 18.0;
  static const double plusButtonBorderWidth = 1.5;
  static const double plusIconSize = 18.0;
}