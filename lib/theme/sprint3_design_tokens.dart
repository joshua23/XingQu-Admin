// Sprint 3 设计令牌系统
// 基于SPRINT3_DESIGN_SPEC.md的完整设计规范

import 'package:flutter/material.dart';
import 'dart:math' as math;

// ============================================================================
// 颜色系统 (Color System)
// ============================================================================
class AppColors {
  AppColors._();

  // 基础色彩
  static const Color primaryBackground = Color(0xFF000000);
  static const Color secondaryBackground = Color(0xFF1C1C1E);
  static const Color surfaceColor = Color(0xFF2C2C2E);
  
  // 文本色彩
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  
  // 星川体系商业化配色
  static const Color freeUserGray = Color(0xFF8E8E93);
  static const Color basicMemberGold = Color(0xFFFFC542);
  static const Color premiumMemberPurple = Color(0xFF7C3AED);
  
  // 渐变色彩
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGoldGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient starSkyGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // 状态色彩
  static const Color successGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF453A);
  static const Color warningOrange = Color(0xFFFF9500);
  
  // 透明度变体
  static const Color whiteAlpha10 = Color(0x1AFFFFFF);
  static const Color whiteAlpha20 = Color(0x33FFFFFF);
  static const Color goldAlpha20 = Color(0x33FFC542);

  // 便利方法：根据会员类型获取颜色
  static Color getMembershipColor(String membershipType) {
    switch (membershipType) {
      case 'basic':
        return basicMemberGold;
      case 'premium':
      case 'lifetime':
        return premiumMemberPurple;
      default:
        return freeUserGray;
    }
  }

  // 便利方法：根据会员类型获取渐变
  static LinearGradient getMembershipGradient(String membershipType) {
    switch (membershipType) {
      case 'basic':
        return goldGradient;
      case 'premium':
      case 'lifetime':
        return purpleGoldGradient;
      default:
        return const LinearGradient(
          colors: [freeUserGray, Color(0xFFB0B0B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

// ============================================================================
// 字体系统 (Typography)
// ============================================================================
class AppTextStyles {
  AppTextStyles._();

  // 主标题样式
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // 正文样式
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.3,
  );
  
  // 按钮样式
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.black,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // 特殊样式
  static const TextStyle priceText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.basicMemberGold,
    height: 1.0,
  );
  
  static const TextStyle tabText = TextStyle(
    fontSize: 13, // 从16减小到13，减少3号
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.0,
  );
}

// ============================================================================
// 间距系统 (Spacing)
// ============================================================================
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  
  // 组件专用间距
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double tabBarHeight = 56.0;
  static const double bottomNavHeight = 80.0;
}

// ============================================================================
// 圆角系统 (Border Radius)
// ============================================================================
class AppRadius {
  AppRadius._();

  static const Radius small = Radius.circular(8.0);
  static const Radius medium = Radius.circular(12.0);
  static const Radius large = Radius.circular(16.0);
  static const Radius xlarge = Radius.circular(20.0);
  static const Radius round = Radius.circular(50.0);
  
  static const BorderRadius cardRadius = BorderRadius.all(large);
  static const BorderRadius buttonRadius = BorderRadius.all(medium);
  static const BorderRadius chipRadius = BorderRadius.all(xlarge);
}

// ============================================================================
// 阴影系统 (Shadows)
// ============================================================================
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> goldGlowShadow = [
    BoxShadow(
      color: Color(0x33FFC542),
      offset: Offset(0, 0),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> purpleGlowShadow = [
    BoxShadow(
      color: Color(0x337C3AED),
      offset: Offset(0, 0),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // 便利方法：根据会员类型获取发光阴影
  static List<BoxShadow> getMembershipGlowShadow(String membershipType) {
    switch (membershipType) {
      case 'basic':
        return goldGlowShadow;
      case 'premium':
      case 'lifetime':
        return purpleGlowShadow;
      default:
        return cardShadow;
    }
  }
}

// ============================================================================
// 动画参数 (Animation)
// ============================================================================
class AppAnimations {
  AppAnimations._();

  // 标准动画时长
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration verySlow = Duration(milliseconds: 500);
  
  // 特殊动画时长
  static const Duration tabSwitch = Duration(milliseconds: 200);
  static const Duration cardHover = Duration(milliseconds: 150);
  static const Duration starExplosion = Duration(milliseconds: 1500);
  static const Duration particleAnimation = Duration(seconds: 15);
  static const Duration crownFloat = Duration(seconds: 3);

  // 动画曲线
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}

// ============================================================================
// 图标系统 (Icons)
// ============================================================================
class AppIcons {
  AppIcons._();

  // Tab图标
  static const IconData tabHome = Icons.home_outlined;
  static const IconData tabHomeActive = Icons.home;
  static const IconData tabMessages = Icons.chat_bubble_outline;
  static const IconData tabMessagesActive = Icons.chat_bubble;
  static const IconData tabCreation = Icons.add_circle_outline;
  static const IconData tabCreationActive = Icons.add_circle;
  static const IconData tabDiscovery = Icons.explore_outlined;
  static const IconData tabDiscoveryActive = Icons.explore;
  static const IconData tabProfile = Icons.person_outline;
  static const IconData tabProfileActive = Icons.person;
  
  // 功能图标
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData star = Icons.star;
  static const IconData starOutline = Icons.star_outline;
  static const IconData crown = Icons.workspace_premium;
  static const IconData diamond = Icons.diamond;
  static const IconData robot = Icons.smart_toy;
  static const IconData users = Icons.group;
  static const IconData zap = Icons.bolt;
  static const IconData database = Icons.storage;
  static const IconData palette = Icons.palette;
  static const IconData shield = Icons.shield;
  
  // 状态图标
  static const IconData running = Icons.play_circle;
  static const IconData paused = Icons.pause_circle;
  static const IconData stopped = Icons.stop_circle;
  static const IconData error = Icons.error;
  static const IconData success = Icons.check_circle;
  static const IconData warning = Icons.warning;
  
  // 智能体类型图标
  static const IconData agentAssistant = Icons.support_agent;
  static const IconData agentCreative = Icons.brush;
  static const IconData agentEducational = Icons.school;
  static const IconData agentEntertainment = Icons.videogame_asset;
  static const IconData agentCode = Icons.code;
  static const IconData agentAnalytics = Icons.bar_chart;
  static const IconData agentDocument = Icons.description;
}

// ============================================================================
// 尺寸规范 (Dimensions)
// ============================================================================
class AppDimensions {
  AppDimensions._();

  // 卡片尺寸
  static const double cardMinHeight = 120.0;
  static const double cardMaxHeight = 200.0;
  static const double cardAspectRatio = 1.6; // 16:10
  
  // 头像尺寸
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXLarge = 80.0;
  
  // 按钮尺寸
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  
  // Tab相关尺寸
  static const double tabIndicatorHeight = 3.0;
  static const double tabIndicatorWidth = 20.0;
  
  // 分割线尺寸
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;
}

// ============================================================================
// 响应式断点 (Breakpoints)
// ============================================================================
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 480.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;
  
  // 便利方法：判断设备类型
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
}

// ============================================================================
// Z-Index层级 (Z-Index)
// ============================================================================
class AppZIndex {
  AppZIndex._();

  static const double background = 0;
  static const double content = 1;
  static const double card = 2;
  static const double overlay = 3;
  static const double modal = 4;
  static const double tooltip = 5;
  static const double dropdown = 6;
  static const double sticky = 7;
  static const double fixed = 8;
  static const double maximum = 9;
}