import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  print('🔍 测试 Supabase 连接...\n');
  
  try {
    // 初始化 Supabase
    await Supabase.initialize(
      url: 'https://wqdpqhfqrxvssxifpmvt.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w',
    );
    
    final supabase = Supabase.instance.client;
    print('✅ Supabase 初始化成功');
    print('📍 项目 URL: ${supabase.supabaseUrl}');
    print('🔐 使用匿名密钥连接\n');
    
    // 测试数据库连接 - 查询订阅计划表
    print('📊 查询订阅计划表...');
    final response = await supabase
        .from('subscription_plans')
        .select('plan_id, plan_name, plan_type, price_monthly')
        .order('plan_type', ascending: true);
    
    print('✅ 查询成功！找到 ${response.length} 个订阅计划：\n');
    
    for (var plan in response) {
      print('  📋 ${plan['plan_name']}');
      print('     - ID: ${plan['plan_id']}');
      print('     - 类型: ${plan['plan_type']}');
      print('     - 月费: ¥${plan['price_monthly']}\n');
    }
    
    // 测试表结构
    print('🔍 获取数据库表列表...');
    final tablesResponse = await supabase.rpc('get_tables_list').select();
    print('✅ 数据库包含 ${tablesResponse.length} 个表');
    
  } catch (e) {
    print('❌ 错误: $e');
    
    if (e.toString().contains('get_tables_list')) {
      print('\n💡 提示: 表列表查询失败是正常的，因为这个函数可能不存在。');
      print('   但数据查询功能正常工作！');
    }
  }
  
  exit(0);
}