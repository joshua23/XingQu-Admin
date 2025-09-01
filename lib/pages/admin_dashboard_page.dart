import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/admin/admin_sidebar.dart';
import '../widgets/admin/overview_module.dart';
import '../widgets/admin/user_analytics_module.dart';
import '../widgets/admin/behavior_analytics_module.dart';
import '../widgets/admin/session_analytics_module.dart';
import '../widgets/admin/real_time_module.dart';

/// 星趣App后台管理系统 - 数据分析仪表板
/// 基于insight-builder项目架构，整合xq_前缀表数据
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _activeModule = 'overview';

  @override
  void initState() {
    super.initState();
    // 初始化数据加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadDashboardData();
    });
  }

  Widget _buildModuleContent() {
    switch (_activeModule) {
      case 'overview':
        return const OverviewModule();
      case 'user-analytics':
        return const UserAnalyticsModule();
      case 'behavior-analytics':
        return const BehaviorAnalyticsModule();
      case 'session-analytics':
        return const SessionAnalyticsModule();
      case 'realtime':
        return const RealTimeModule();
      default:
        return const OverviewModule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 侧边栏
          AdminSidebar(
            activeModule: _activeModule,
            onModuleChanged: (module) {
              setState(() {
                _activeModule = module;
              });
            },
          ),
          // 主要内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildModuleContent(),
            ),
          ),
        ],
      ),
    );
  }
}