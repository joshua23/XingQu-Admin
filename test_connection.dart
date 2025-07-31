import 'package:flutter/material.dart';
import 'lib/services/supabase_service.dart';
import 'lib/utils/api_tester.dart';

/// 简单的连接测试脚本
/// 不依赖Flutter UI，直接测试后端连接
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 开始测试星趣App数据库连接...');
  print('=' * 50);
  
  try {
    // 初始化Supabase服务
    await SupabaseService.instance.initialize();
    print('✅ Supabase服务初始化成功');
    
    // 运行完整验证
    final results = await ApiTester.runFullValidation();
    
    print('');
    print('📊 最终测试结果：');
    print('=' * 50);
    
    results.forEach((key, passed) {
      final status = passed ? '✅ 通过' : '❌ 失败';
      print('$key: $status');
    });
    
    final successCount = results.values.where((v) => v).length;
    final totalTests = results.length;
    
    print('');
    if (successCount == totalTests) {
      print('🎉 恭喜！所有测试通过 ($successCount/$totalTests)');
      print('✅ 数据库部署成功，API连接正常！');
      print('🚀 星趣App后端已就绪，可以开始使用！');
    } else {
      print('⚠️ 部分测试失败 ($successCount/$totalTests)');
      print('❌ 请检查数据库配置和部署状态');
    }
    
    print('');
    await ApiTester.showDatabaseStats();
    
  } catch (e) {
    print('❌ 测试过程中发生错误: $e');
  }
  
  print('');
  print('测试完成！');
}