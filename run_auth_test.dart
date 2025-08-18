#!/usr/bin/env dart

// 简单的认证系统测试脚本
// 不依赖Flutter UI，直接测试核心逻辑

import 'dart:io';

// 模拟AuthService的核心逻辑
class SimpleAuthService {
  /// 检查手机号格式是否正确
  bool isValidPhoneNumber(String phone) {
    // 移除所有非数字字符
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 检查是否为11位中国手机号
    if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return RegExp(r'^1[3-9]\d{9}$').hasMatch(cleanPhone);
    }

    return false;
  }

  /// 格式化手机号码
  String formatPhoneNumber(String phone) {
    // 移除所有非数字字符
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 如果是11位中国手机号，添加+86前缀
    if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return '+86$cleanPhone';
    }

    // 如果已经有+86前缀，直接返回
    if (cleanPhone.startsWith('86') && cleanPhone.length == 13) {
      return '+$cleanPhone';
    }

    return phone; // 其他情况返回原始号码
  }

  /// 生成6位验证码
  String generateCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (100000 + (now % 900000)).toString();
  }
}

void main() {
  print('🚀 星趣认证系统测试');
  print('=' * 50);
  
  final authService = SimpleAuthService();
  
  // 测试用例
  final testCases = [
    '13812345678',
    '15987654321', 
    '18666777888',
    '12345678901', // 无效
    '138123456789', // 无效
    '1381234567', // 无效
    '0138123456', // 无效
  ];
  
  print('\n📱 手机号验证测试:');
  for (final phone in testCases) {
    final isValid = authService.isValidPhoneNumber(phone);
    final formatted = isValid ? authService.formatPhoneNumber(phone) : '无效格式';
    final status = isValid ? '✅' : '❌';
    print('  $status $phone -> $formatted');
  }
  
  print('\n🔐 验证码生成测试:');
  for (int i = 0; i < 5; i++) {
    final code = authService.generateCode();
    print('  生成验证码 ${i + 1}: $code');
    sleep(Duration(milliseconds: 100)); // 确保时间戳不同
  }
  
  print('\n📊 测试总结:');
  final validCount = testCases.where((phone) => authService.isValidPhoneNumber(phone)).length;
  print('  有效手机号: $validCount/${testCases.length}');
  print('  验证码长度: 6位数字');
  print('  格式化规则: +86前缀');
  
  print('\n✅ 核心认证逻辑测试完成');
  print('💡 建议下一步：');
  print('  1. 在iOS模拟器中测试调试页面');
  print('  2. 配置Supabase SMS Provider进行真实测试');
  print('  3. 测试完整的认证流程');
}