import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

/// API连接测试类
class ApiTester {
  static final ApiService _apiService = ApiService.instance;
  static final SupabaseService _supabaseService = SupabaseService.instance;

  /// 测试数据库连接
  static Future<bool> testDatabaseConnection() async {
    try {
      final result = await _supabaseService.client
          .from('users')
          .select('count')
          .count();
      debugPrint('✅ 数据库连接成功！');
      return true;
    } catch (e) {
      debugPrint('❌ 数据库连接失败: $e');
      return false;
    }
  }

  /// 运行所有测试
  static Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};
    debugPrint('🧪 开始API连接测试...');
    results['database'] = await testDatabaseConnection();
    return results;
  }
}
