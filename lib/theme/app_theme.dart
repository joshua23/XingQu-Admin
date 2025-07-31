import 'package:flutter/material.dart';

/// 应用颜色配置类 - 基于星趣品牌视觉识别系统设计规范
/// 严格按照设计文档的颜色系统和使用比例
class AppColors {
  // 私有构造函数，防止实例化
  AppColors._();

  // 主色 (使用比例70% + 15%)
  static const Color background = Color(0xFF000000);     // 极夜黑 - 主背景色
  static const Color primary = Color(0xFFF5DFAF);        // 浅米色 - 品牌识别色

  // 强调色 (使用比例10% + 5%)  
  static const Color accent = Color(0xFFFFC542);         // 琥珀黄 - 点赞、通知、重要操作
  static const Color highlight = Color(0xFFAAB2C8);      // 浅灰蓝 - 按钮高亮、链接

  // 功能色
  static const Color success = Color(0xFFB7C68B);        // 浅橄榄绿 - 成功状态
  static const Color warning = Color(0xFFFFC542);        // 琥珀黄 - 警告状态
  static const Color error = Color(0xFFFF5757);          // 错误红 - 错误状态

  // 中性色
  static const Color textPrimary = Color(0xFFFFFFFF);    // 文字高亮
  static const Color textSecondary = Color(0xFFCFCFCF);  // 文本普通
  static const Color cardBackground = Color(0xFF1E1E1E); // 卡片底色
  
  // 扩展色彩
  static const Color surface = Color(0xFF1E1E1E);        // 表面色
  static const Color surfaceVariant = Color(0xFF2A2A2A); // 变体表面色
  static const Color textTertiary = Color(0xFF999999);   // 三级文字色
  static const Color textHint = Color(0xFF666666);       // 提示文字色
  static const Color wechat = Color(0xFF07C160);         // 微信绿

  // 边框和分割线
  static const Color border = Color(0x1AF5DFAF);         // 边框色（透明度10%）
  static const Color divider = Color(0x33F5DFAF);        // 分割线色（透明度20%）

  // 品牌渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF5DFAF), Color(0xFFFFC542)],      // 浅米色到琥珀黄
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFC542), Color(0xFFAAB2C8)],      // 琥珀黄到浅灰蓝
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// 应用文字样式配置类 - 基于星趣品牌视觉识别系统设计规范
/// 严格按照设计文档的字体系统和排版规范
class AppTextStyles {
  // 私有构造函数，防止实例化
  AppTextStyles._();

  // 基础字体配置 - 思源黑体(Noto Sans SC) + HarmonyOS Sans SC
  // static const String fontFamilyChinese = 'Noto Sans SC';
  // static const String fontFamilyTitle = 'HarmonyOS Sans SC';

  // 标题样式 (HarmonyOS Sans SC Bold)
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  // 正文样式 (思源黑体 Regular)
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  // 说明文字 (12sp)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  // 按钮样式
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
    height: 1.4,
    letterSpacing: 0.02,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
    height: 1.4,
    letterSpacing: 0.02,
  );

  // 输入框样式
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.02,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.4,
    letterSpacing: 0.02,
  );

  // 链接样式
  static const TextStyle link = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.highlight,
    height: 1.4,
    letterSpacing: 0.02,
    decoration: TextDecoration.underline,
  );

  // 品牌样式 - 星趣标志文字
  static const TextStyle brand = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.2,
    letterSpacing: 2.0,
  );
}

/// 应用尺寸配置类
/// 包含所有应用中使用的尺寸常量
class AppDimensions {
  // 私有构造函数，防止实例化
  AppDimensions._();

  // 基础间距
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // 圆角半径
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

  // 组件尺寸
  static const double buttonHeight = 50.0;
  static const double inputHeight = 50.0;
  static const double appBarHeight = 60.0;
  static const double bottomNavHeight = 83.0;
  static const double statusBarHeight = 47.0;

  // 图标尺寸
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
}

/// 星趣App主题配置类
/// 包含Flutter主题的创建和配置方法
class AppTheme {
  // 私有构造函数，防止实例化
  AppTheme._();

  /// 创建Flutter主题数据
  /// 返回配置好的ThemeData对象
  static ThemeData get theme {
    return ThemeData(
      // 基础配置
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(AppColors.primary),
      // fontFamily: AppTextStyles.fontFamily,

      // 色彩方案
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.background,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.background,
      ),

      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textHint),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  /// 创建MaterialColor的辅助方法
  /// [color] 基础颜色值
  /// 返回MaterialColor对象
  static MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    final Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}
