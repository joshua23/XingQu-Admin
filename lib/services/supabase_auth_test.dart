import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 认证测试服务
/// 用于验证短信认证功能是否正常工作
class SupabaseAuthTest {
  final SupabaseClient _client = Supabase.instance.client;

  /// 测试 Supabase 连接
  Future<Map<String, dynamic>> testConnection() async {
    try {
      debugPrint('🔍 测试 Supabase 连接...');
      
      // 检查客户端是否初始化
      if (_client == null) {
        return {
          'success': false,
          'error': 'Supabase 客户端未初始化',
        };
      }

      // 检查当前用户状态
      final currentUser = _client.auth.currentUser;
      debugPrint('👤 当前用户: ${currentUser?.id ?? '未登录'}');

      // 检查认证设置
      final authSettings = await _testAuthSettings();
      
      return {
        'success': true,
        'currentUser': currentUser?.id,
        'authSettings': authSettings,
        'message': 'Supabase 连接测试完成',
      };
    } catch (e) {
      debugPrint('❌ Supabase 连接测试失败: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 测试认证设置
  Future<Map<String, dynamic>> _testAuthSettings() async {
    try {
      debugPrint('🔐 检查认证设置...');
      
      // 尝试获取认证设置（这可能需要管理员权限）
      // 注意：某些设置可能无法通过客户端 API 获取
      
      return {
        'phoneAuthEnabled': '需要检查 Supabase Dashboard',
        'smsProvider': '需要检查 Supabase Dashboard',
        'message': '请在 Supabase Dashboard 中检查短信认证设置',
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// 测试短信认证流程
  Future<Map<String, dynamic>> testSmsAuth(String phone) async {
    try {
      debugPrint('📱 测试短信认证流程...');
      debugPrint('📞 手机号: $phone');

      // 步骤 1: 发送 OTP
      debugPrint('🚀 步骤 1: 发送 OTP...');
      await _client.auth.signInWithOtp(
        phone: phone,
        channel: OtpChannel.sms,
      );
      
      debugPrint('✅ OTP 发送成功');
      
      return {
        'success': true,
        'message': '短信认证测试成功',
        'phone': phone,
      };
    } catch (e) {
      debugPrint('❌ 短信认证测试失败: $e');
      
      // 分析错误类型
      String errorType = 'unknown';
      String suggestion = '';
      
      if (e.toString().contains('phone_provider_disabled')) {
        errorType = 'phone_provider_disabled';
        suggestion = '请在 Supabase Dashboard > Authentication > Providers 中启用 Phone 认证';
      } else if (e.toString().contains('invalid_phone')) {
        errorType = 'invalid_phone';
        suggestion = '请检查手机号格式是否正确';
      } else if (e.toString().contains('rate_limit')) {
        errorType = 'rate_limit';
        suggestion = '请求过于频繁，请稍后再试';
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'errorType': errorType,
        'suggestion': suggestion,
      };
    }
  }

  /// 测试验证码验证
  Future<Map<String, dynamic>> testVerifyOtp(String phone, String code) async {
    try {
      debugPrint('🔍 测试验证码验证...');
      debugPrint('📞 手机号: $phone');
      debugPrint('🔢 验证码: $code');

      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );

      if (response.user != null) {
        debugPrint('✅ 验证码验证成功');
        return {
          'success': true,
          'user': response.user?.id,
          'message': '验证码验证成功',
        };
      } else {
        debugPrint('❌ 验证码验证失败');
        return {
          'success': false,
          'error': '验证码无效',
        };
      }
    } catch (e) {
      debugPrint('❌ 验证码验证失败: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 运行完整的认证测试
  Future<Map<String, dynamic>> runFullAuthTest(String phone) async {
    debugPrint('🚀 开始完整的认证测试...');
    
    final connectionTest = await testConnection();
    final smsTest = await testSmsAuth(phone);
    
    final report = {
      'connection': connectionTest,
      'smsAuth': smsTest,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 打印测试报告
    debugPrint('📊 认证测试报告:');
    debugPrint('连接状态: ${connectionTest['success'] ? '✅ 成功' : '❌ 失败'}');
    debugPrint('短信认证: ${smsTest['success'] ? '✅ 成功' : '❌ 失败'}');
    
    if (!smsTest['success']) {
      debugPrint('💡 建议: ${smsTest['suggestion'] ?? '请检查 Supabase 配置'}');
    }

    return report;
  }
} 