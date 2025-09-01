/// 星趣App后台管理系统启动脚本
/// 运行命令: dart start_admin_system.dart
/// 或者: flutter run lib/start_admin_system.dart

import 'dart:io';

void main() async {
  print('🚀 启动星趣App后台管理系统...\n');
  
  // 显示系统信息
  _showSystemInfo();
  
  // 检查环境
  await _checkEnvironment();
  
  // 启动说明
  _showStartupInstructions();
}

void _showSystemInfo() {
  print('📊 星趣App数据分析后台管理系统');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📱 基于Flutter + Supabase构建');
  print('🎨 整合insight-builder项目设计');  
  print('💾 直接对接xq_前缀表数据');
  print('');
  
  print('🗂️  支持的功能模块：');
  print('   • 📈 数据总览 - 系统关键指标');
  print('   • 👥 用户分析 - 基于xq_user_profiles');
  print('   • 📊 行为分析 - 基于xq_tracking_events');
  print('   • ⏱️  会话分析 - 基于xq_user_sessions');
  print('   • 🔴 实时监控 - 系统状态追踪');
  print('');
}

Future<void> _checkEnvironment() async {
  print('🔍 环境检查...');
  
  // 检查Flutter
  final flutterResult = await Process.run('flutter', ['--version']);
  if (flutterResult.exitCode == 0) {
    print('✅ Flutter 环境正常');
  } else {
    print('❌ Flutter 环境异常');
    exit(1);
  }
  
  // 检查项目依赖
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    print('✅ 项目配置文件存在');
  } else {
    print('❌ 项目配置文件缺失');
    exit(1);
  }
  
  // 检查关键文件
  final keyFiles = [
    'lib/pages/admin_dashboard_page.dart',
    'lib/providers/analytics_provider.dart', 
    'lib/services/analytics_service.dart',
    'lib/models/analytics_models.dart',
  ];
  
  for (final file in keyFiles) {
    final fileObj = File(file);
    if (await fileObj.exists()) {
      print('✅ $file');
    } else {
      print('❌ $file 缺失');
      exit(1);
    }
  }
  
  print('✅ 环境检查完成\n');
}

void _showStartupInstructions() {
  print('🎯 启动方法：');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
  
  print('方法1: 命令行启动');
  print('   flutter run');
  print('   然后访问 /admin 路由');
  print('');
  
  print('方法2: 直接启动到后台管理');
  print('   flutter run --dart-define=INITIAL_ROUTE=/admin');
  print('');
  
  print('方法3: 在运行的应用中导航');
  print('   在任何页面执行: Navigator.pushNamed(context, \'/admin\')');
  print('');
  
  print('📱 设备支持：');
  print('   • iOS:     flutter run -d ios');
  print('   • Android: flutter run -d android');  
  print('   • Web:     flutter run -d chrome');
  print('   • 模拟器:   flutter run');
  print('');
  
  print('🔧 调试功能：');
  print('   • 数据库测试: /test_database');
  print('   • 分析测试:  /analytics_test');
  print('   • 后台管理:  /admin');
  print('');
  
  print('🌐 访问地址示例：');
  print('   • 本地:     http://localhost:port/#/admin');
  print('   • Web部署:  https://your-domain.com/#/admin');
  print('');
  
  print('💡 使用提示：');
  print('   1. 首次启动会自动加载Supabase数据');
  print('   2. 确保xq_前缀表有数据才能看到统计'); 
  print('   3. 支持实时数据刷新和模块切换');
  print('   4. 数据基于您的真实Supabase表结构');
  print('');
  
  print('🎉 准备就绪！现在可以启动后台管理系统了。');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}