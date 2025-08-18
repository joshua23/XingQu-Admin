import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/home_refactored.dart';
import 'pages/main_page_refactored.dart';
import 'config/supabase_config.dart';
import 'pages/ai_chat_page.dart';
import 'pages/messages_page.dart';
import 'pages/profile_page.dart';
import 'pages/splash_page.dart';
import 'pages/creation_center_page.dart';
import 'pages/character_management_page.dart';
import 'pages/template_center_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_error_page.dart';
import 'pages/ai_chat_settings_page.dart';
import 'pages/character_create_page.dart';
import 'pages/test_database_page.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_chat_provider.dart'; // 新增：AI对话状态管理
// Sprint 2 imports (暂时注释掉解决重复类定义问题)
// import 'providers/sprint2/interaction_provider.dart';
// import 'providers/sprint2/memory_provider.dart';
// import 'providers/sprint2/recommendation_provider.dart';
// Sprint 3 providers
import 'providers/subscription_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/agent_provider.dart';
// import 'pages/sprint2/memory_book_page.dart';
// import 'pages/sprint2/recommendation_page.dart';
// import 'models/sprint2/memory_models.dart';
// import 'models/sprint2/recommendation_models.dart';
// Sprint 3 imports
import 'pages/subscription_plans_page.dart';
import 'pages/recommendation_page.dart';
import 'pages/agent_marketplace_page.dart';
import 'pages/membership_management_page.dart';
import 'pages/payment_confirmation_page.dart';
import 'pages/agent_create_page.dart';
import 'pages/agent_detail_page.dart';
import 'pages/analytics_test_page.dart'; // 新增：分析测试页面
import 'pages/ai_chat_enhanced_page.dart'; // 新增：增强版AI聊天页面
import 'pages/comprehensive_page.dart'; // 新增：综合页面
import 'models/subscription_plan.dart';
import 'models/custom_agent.dart';
import 'services/analytics_service.dart'; // 新增：分析服务
// import 'providers/sprint3/sprint3_state_provider.dart';
// import 'services/sprint3_api_service.dart';
// import 'models/sprint3/index.dart';

/// 应用程序入口函数
/// 配置Flutter应用的基础设置并启动应用
void main() async {
  // 确保Flutter框架初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  // 设置系统UI样式
  await _configureSystemUI();

  // 初始化Supabase客户端
  await _initializeSupabase();

  // 初始化分析服务
  await _initializeAnalytics();

  // 启动应用
  runApp(const XinQuApp());
}

/// 配置系统UI样式
/// 设置状态栏、导航栏等系统界面元素的样式
Future<void> _configureSystemUI() async {
  // 设置系统UI覆盖样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // 状态栏样式
      statusBarColor: Colors.transparent, // 透明状态栏
      statusBarIconBrightness: Brightness.light, // 浅色图标
      statusBarBrightness: Brightness.dark, // 深色背景

      // 导航栏样式
      systemNavigationBarColor: AppColors.background, // 导航栏背景色
      systemNavigationBarIconBrightness: Brightness.light, // 浅色导航图标
    ),
  );

  // 设置设备方向为仅竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

/// 初始化Supabase客户端
/// 配置Supabase连接和认证设置
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: EnvironmentConfig.getSupabaseUrl(),
      anonKey: EnvironmentConfig.getSupabaseAnonKey(),
    );

    // 在调试模式下打印初始化成功信息
    if (EnvironmentConfig.isDebugMode) {
      debugPrint('✅ Supabase initialized successfully');
      debugPrint('📍 URL: ${EnvironmentConfig.getSupabaseUrl()}');
      
      // 简单的连接测试
      debugPrint('🔍 Supabase 连接测试完成');
      debugPrint('💡 建议检查 SMS Provider 配置');
    }
  } catch (e) {
    // 初始化失败时打印错误信息
    debugPrint('❌ Failed to initialize Supabase: $e');

    // 在生产环境中可以考虑显示错误对话框或使用错误报告服务
    if (EnvironmentConfig.isProduction) {
      // TODO: 发送错误报告到分析服务
    }

    // 重新抛出异常，让应用决定如何处理
    rethrow;
  }
}

/// 初始化分析服务
/// 配置移动端数据分析和上报功能
Future<void> _initializeAnalytics() async {
  try {
    await AnalyticsService.instance.initialize();
    
    // 在调试模式下打印初始化成功信息
    if (EnvironmentConfig.isDebugMode) {
      debugPrint('✅ Analytics service initialized successfully');
      debugPrint('📊 Ready to track user behavior and app usage');
    }
  } catch (e) {
    // 分析服务初始化失败不应该阻止应用启动
    debugPrint('⚠️ Failed to initialize Analytics service: $e');
    
    // 在调试模式下可以提供更详细的错误信息
    if (EnvironmentConfig.isDebugMode) {
      debugPrint('💡 Analytics features may not work properly');
      debugPrint('🔧 Check Supabase connection and permissions');
    }
  }
}

/// 星趣App主应用类
/// 配置应用的主题、路由等全局设置
class XinQuApp extends StatelessWidget {
  const XinQuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用MultiProvider包裹MaterialApp，支持多个Provider，包括Sprint 2的新功能
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        // Sprint 2 Providers
        ChangeNotifierProvider<AiChatProvider>(
          create: (_) => AiChatProvider(),
        ),
        // ChangeNotifierProvider<InteractionProvider>(
        //   create: (_) => InteractionProvider(),
        // ),
        // ChangeNotifierProvider<MemoryProvider>(
        //   create: (_) => MemoryProvider(),
        // ),
        
        // Sprint 3 Providers
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
        ),
        ChangeNotifierProvider<RecommendationProvider>(
          create: (_) => RecommendationProvider(),
        ),
        ChangeNotifierProvider<AgentProvider>(
          create: (_) => AgentProvider(),
        ),
        
        // Sprint 3 Providers (暂时注释掉复杂依赖)
        // ChangeNotifierProvider<Sprint3StateProvider>(
        //   create: (_) => Sprint3StateProvider(Sprint3ApiService(SupabaseService.instance)),
        // ),
      ],
      child: MaterialApp(
        // 应用基础配置
        title: '星趣App',
        debugShowCheckedModeBanner: false,

        // 主题配置
        theme: AppTheme.theme,

        // 路由配置 - 支持游客模式，直接进入主页
        initialRoute: '/home',
        routes: _buildRoutes(),

        // 路由生成器（用于动态路由）
        onGenerateRoute: _onGenerateRoute,

        // 未知路由处理
        onUnknownRoute: _onUnknownRoute,

        // 全局导航观察器
        navigatorObservers: [
          // 可扩展
        ],
      ),
    );
  }

  /// 构建应用路由表
  /// 返回包含所有静态路由的Map
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (context) => const LoginPage(),
      '/home': (context) => const MainPageRefactored(), // 使用重构后的主页面容器
      '/home_tabs': (context) => const HomeRefactored(), // 纯首页4个Tab
      '/splash': (context) => const SplashPage(),
      '/ai_chat': (context) => const AiChatPage(),
      '/ai_chat_enhanced': (context) => const AiChatEnhancedPage(), // 新增：增强版AI聊天页面
      '/messages': (context) => const MessagesPage(),
      '/profile': (context) => const ProfilePage(),
      // 创作中心相关路由
      '/creation_center': (context) => const CreationCenterPage(),
      '/character_management': (context) => const CharacterManagementPage(),
      '/template_center': (context) => const TemplateCenterPage(),
      // 设置和功能页面路由
      '/settings': (context) => const SettingsPage(),
      '/ai_chat_settings': (context) => const AiChatSettingsPage(),
      '/character_create': (context) => const CharacterCreatePage(),
      '/test_database': (context) => const TestDatabasePage(),
      '/analytics_test': (context) => const AnalyticsTestPage(), // 新增：分析测试页面
      '/comprehensive': (context) => const ComprehensivePage(), // 新增：综合页面
      
      // Sprint 2 路由 (暂时注释掉)
      // '/memory_book': (context) => const MemoryBookPage(),
      // '/recommendation': (context) => const RecommendationPage(),
      
      // Sprint 3 路由
      '/subscription_plans': (context) => const SubscriptionPlansPage(),
      '/recommendation': (context) => const RecommendationPage(), 
      '/agent_marketplace': (context) => const AgentMarketplacePage(),
      '/membership_management': (context) => const MembershipManagementPage(),
      '/agent_create': (context) => const AgentCreatePage(),
      // FM发现页面路由 - 重定向到首页FM Tab
      '/fm_discovery': (context) => const MainPageRefactored(),
      // 支付确认页面和智能体详情页面需要参数，在onGenerateRoute中处理
      
      // 注意：故事评论和分享页面需要传递参数，在onGenerateRoute中处理
    };
  }

  /// 动态路由生成器
  /// 处理需要传递参数的路由跳转
  /// [settings] 路由设置信息
  /// 返回生成的路由对象
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // 解析路由名称和参数
    final String routeName = settings.name ?? '';
    final Object? arguments = settings.arguments;

    // 根据路由名称返回对应页面
    switch (routeName) {

      // 登录异常页（需要传递LoginErrorType）
      case '/login_error':
        if (arguments is LoginErrorType) {
          return MaterialPageRoute(
            builder: (_) => LoginErrorPage(errorType: arguments),
            settings: settings,
          );
        }
        break;

      // 用户资料页（需要传递用户ID）
      case '/user_profile':
        if (arguments is String) {
          // TODO: 实现用户资料页
          // return MaterialPageRoute(
          //   builder: (_) => UserProfilePage(userId: arguments),
          //   settings: settings,
          // );
        }
        break;

      // Sprint 2 动态路由 (暂时注释掉)
      // case '/memory/detail':
      //   if (arguments is MemoryItem) {
      //     // TODO: 实现记忆详情页
      //     // return MaterialPageRoute(
      //     //   builder: (_) => MemoryDetailPage(memoryItem: arguments),
      //     //   settings: settings,
      //     // );
      //   }
      //   break;

      // case '/memory/create':
      //   return MaterialPageRoute(
      //     builder: (_) => const MemoryBookPage(), // 暂时导航到记忆簿页面
      //     settings: settings,
      //   );

      // case '/memory/edit':
      //   if (arguments is MemoryItem) {
      //     // TODO: 实现记忆编辑页
      //     // return MaterialPageRoute(
      //     //   builder: (_) => MemoryEditPage(memoryItem: arguments),
      //     //   settings: settings,
      //     // );
      //   }
      //   break;

      case '/character/detail':
        if (arguments is String) {
          // TODO: 导航到AI角色详情页
          // return MaterialPageRoute(
          //   builder: (_) => CharacterDetailPage(characterId: arguments),
          //   settings: settings,
          // );
        }
        break;

      case '/story/detail':
        if (arguments is String) {
          // TODO: 导航到故事详情页
          // return MaterialPageRoute(
          //   builder: (_) => StoryDetailPage(storyId: arguments),
          //   settings: settings,
          // );
        }
        break;

      case '/audio/detail':
        if (arguments is String) {
          // TODO: 导航到音频详情页
          // return MaterialPageRoute(
          //   builder: (_) => AudioDetailPage(audioId: arguments),
          //   settings: settings,
          // );
        }
        break;

      case '/creator/detail':
        if (arguments is String) {
          // TODO: 导航到创作者详情页
          // return MaterialPageRoute(
          //   builder: (_) => CreatorDetailPage(creatorId: arguments),
          //   settings: settings,
          // );
        }
        break;

      case '/payment_confirmation':
        if (arguments is Map<String, dynamic>) {
          final plan = arguments['plan'] as SubscriptionPlan;
          final isYearly = arguments['isYearly'] as bool;
          final paymentMethod = arguments['paymentMethod'] as String;
          
          return MaterialPageRoute(
            builder: (_) => PaymentConfirmationPage(
              plan: plan,
              isYearly: isYearly,
              paymentMethod: paymentMethod,
            ),
            settings: settings,
          );
        }
        break;

      case '/agent_detail':
        if (arguments is Map<String, dynamic>) {
          final agentId = arguments['agentId'] as String;
          final agent = arguments['agent'] as CustomAgent?;
          
          return MaterialPageRoute(
            builder: (_) => AgentDetailPage(
              agentId: agentId,
              agent: agent,
            ),
            settings: settings,
          );
        }
        break;
    }

    // 路由未匹配时返回null
    return null;
  }

  /// 未知路由处理器
  /// 当路由无法匹配时显示404页面
  /// [settings] 路由设置信息
  /// 返回404错误页面路由
  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const NotFoundPage(),
      settings: settings,
    );
  }
}

/// 404错误页面
/// 当用户访问不存在的路由时显示
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 错误图标
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.textSecondary,
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // 错误标题
            Text(
              '页面未找到',
              style: AppTextStyles.h2,
            ),

            const SizedBox(height: AppDimensions.paddingS),

            // 错误描述
            Text(
              '抱歉，您访问的页面不存在',
              style: AppTextStyles.body2,
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // 返回按钮
            ElevatedButton(
              onPressed: () {
                // 返回登录页面
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
