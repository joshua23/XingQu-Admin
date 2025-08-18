/// Edge Functions API 测试脚本
/// 用于验证部署后的Edge Functions是否正常工作

import 'dart:convert';
import 'package:http/http.dart' as http;

class EdgeFunctionsTest {
  static const String baseUrl = 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w';

  /// 测试AI对话服务
  static Future<void> testAiChat() async {
    print('\n🧪 测试 AI 对话服务...');
    print('----------------------------------------');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai-chat'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': '你好，请介绍一下星趣App',
          'stream': false,
          'temperature': 0.7,
          'maxTokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ AI对话服务测试成功');
        print('回复内容: ${data['content']?.substring(0, 100)}...');
        print('Token使用: ${data['tokensUsed']}');
        print('成本: ${data['cost']}');
      } else {
        print('❌ AI对话服务测试失败');
        print('状态码: ${response.statusCode}');
        print('错误信息: ${response.body}');
      }
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }

  /// 测试音频内容服务
  static Future<void> testAudioContent() async {
    print('\n🧪 测试音频内容服务...');
    print('----------------------------------------');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/audio-content'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': 'list',
          'category': 'all',
          'page': 1,
          'pageSize': 5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 音频内容服务测试成功');
        print('返回数据: ${data['success']}');
        print('内容数量: ${data['data']?['contents']?.length ?? 0}');
      } else {
        print('❌ 音频内容服务测试失败');
        print('状态码: ${response.statusCode}');
        print('错误信息: ${response.body}');
      }
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }

  /// 测试用户权限服务
  static Future<void> testUserPermission() async {
    print('\n🧪 测试用户权限服务...');
    print('----------------------------------------');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-permission'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': 'check',
          'resource': 'ai_chat',
          'permission': 'use',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 用户权限服务测试成功');
        print('权限状态: ${data['allowed']}');
        print('用户等级: ${data['userLevel']}');
      } else {
        print('❌ 用户权限服务测试失败');
        print('状态码: ${response.statusCode}');
        print('错误信息: ${response.body}');
      }
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }

  /// 测试推荐服务
  static Future<void> testRecommendations() async {
    print('\n🧪 测试推荐服务...');
    print('----------------------------------------');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': 'ai_characters',
          'count': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 推荐服务测试成功');
        print('推荐数量: ${data['recommendations']?.length ?? 0}');
      } else {
        print('❌ 推荐服务测试失败');
        print('状态码: ${response.statusCode}');
        print('错误信息: ${response.body}');
      }
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }

  /// 运行所有测试
  static Future<void> runAllTests() async {
    print('');
    print('🚀 开始测试 Supabase Edge Functions');
    print('=====================================');
    
    await testAiChat();
    await Future.delayed(Duration(seconds: 1)); // 避免请求过快
    
    await testAudioContent();
    await Future.delayed(Duration(seconds: 1));
    
    await testUserPermission();
    await Future.delayed(Duration(seconds: 1));
    
    await testRecommendations();
    
    print('\n=====================================');
    print('✅ 所有测试完成！');
    print('');
    print('📝 后续步骤：');
    print('1. 检查失败的测试项');
    print('2. 查看 Supabase Dashboard 中的函数日志');
    print('3. 根据错误信息调整配置');
  }
}

// 主函数
void main() async {
  await EdgeFunctionsTest.runAllTests();
}