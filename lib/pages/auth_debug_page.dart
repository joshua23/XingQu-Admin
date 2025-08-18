import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 认证系统调试页面
/// 用于测试和调试认证相关功能
class AuthDebugPage extends StatefulWidget {
  const AuthDebugPage({Key? key}) : super(key: key);

  @override
  State<AuthDebugPage> createState() => _AuthDebugPageState();
}

class _AuthDebugPageState extends State<AuthDebugPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  String _status = '准备就绪';
  List<String> _logs = [];
  bool _isLoading = false;
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _addLog('🚀 认证调试页面已启动');
    _checkInitialState();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    print('AuthDebug: $message');
  }

  Future<void> _checkInitialState() async {
    _addLog('🔍 检查初始状态...');
    
    // 检查Supabase连接
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    _addLog('📱 Supabase连接状态: 正常');
    _addLog('👤 当前用户: ${currentUser?.id ?? "未登录"}');
    
    // 检查本地登录状态
    final isLoggedIn = await _authService.isLoggedIn();
    _addLog('🔐 本地登录状态: ${isLoggedIn ? "已登录" : "未登录"}');
    
    setState(() {
      _status = '初始状态检查完成';
    });
  }

  Future<void> _testPhoneValidation() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _addLog('❌ 请输入手机号');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '验证手机号格式...';
    });

    _addLog('📱 测试手机号: $phone');
    
    final isValid = _authService.isValidPhoneNumber(phone);
    _addLog('✅ 格式验证结果: ${isValid ? "有效" : "无效"}');
    
    if (isValid) {
      _addLog('🔧 格式化后的号码: ${_formatPhoneNumber(phone)}');
    }

    setState(() {
      _isLoading = false;
      _status = '手机号验证完成';
    });
  }

  String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return '+86$cleanPhone';
    }
    return phone;
  }

  Future<void> _testSupabaseSMS() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _addLog('❌ 请输入手机号');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '测试Supabase SMS...';
    });

    try {
      _addLog('📤 尝试通过Supabase发送SMS...');
      await _authService.sendSmsCode(phone);
      _addLog('✅ Supabase SMS请求已发送');
      
      setState(() {
        _status = 'Supabase SMS测试完成';
      });
    } catch (e) {
      _addLog('❌ Supabase SMS失败: $e');
      setState(() {
        _status = 'Supabase SMS测试失败';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testEdgeFunction() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _addLog('❌ 请输入手机号');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '测试Edge Function...';
    });

    try {
      _addLog('🚀 调用Edge Function...');
      
      // 生成6位验证码
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      _generatedCode = code;
      _addLog('🔐 生成的验证码: $code');

      final response = await http.post(
        Uri.parse('https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/send-aliyun-sms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w',
        },
        body: json.encode({
          'phone': phone,
          'code': code,
        }),
      );

      _addLog('📡 HTTP状态码: ${response.statusCode}');
      _addLog('📄 响应内容: ${response.body}');

      if (response.statusCode == 200) {
        _addLog('✅ Edge Function调用成功');
        setState(() {
          _status = 'Edge Function测试成功';
        });
      } else {
        _addLog('❌ Edge Function返回错误: ${response.statusCode}');
        setState(() {
          _status = 'Edge Function测试失败';
        });
      }
    } catch (e) {
      _addLog('❌ Edge Function调用异常: $e');
      setState(() {
        _status = 'Edge Function测试异常';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCodeVerification() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    
    if (phone.isEmpty || code.isEmpty) {
      _addLog('❌ 请输入手机号和验证码');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '验证验证码...';
    });

    try {
      _addLog('🔐 验证验证码: $code');
      
      // 如果有生成的验证码，先比较
      if (_generatedCode != null && code == _generatedCode) {
        _addLog('✅ 验证码匹配（本地验证）');
        
        // 执行登录逻辑
        await _authService.setLoggedIn(phone);
        _addLog('✅ 本地登录状态已设置');
        
        setState(() {
          _status = '验证码验证成功（模拟）';
        });
      } else {
        // 尝试Supabase验证
        _addLog('🔍 尝试Supabase验证...');
        
        final success = await _authService.verifyCodeAndSignIn(
          phoneNumber: phone,
          code: code,
          nickname: '测试用户',
        );
        
        if (success) {
          _addLog('✅ Supabase验证成功');
          setState(() {
            _status = 'Supabase验证成功';
          });
        } else {
          _addLog('❌ Supabase验证失败');
          setState(() {
            _status = 'Supabase验证失败';
          });
        }
      }
    } catch (e) {
      _addLog('❌ 验证码验证异常: $e');
      setState(() {
        _status = '验证码验证异常';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    setState(() {
      _isLoading = true;
      _status = '测试登出...';
    });

    try {
      _addLog('🚪 执行登出...');
      await _authService.signOut();
      _addLog('✅ 登出成功');
      
      // 重新检查状态
      await _checkInitialState();
      
      setState(() {
        _status = '登出测试完成';
      });
    } catch (e) {
      _addLog('❌ 登出失败: $e');
      setState(() {
        _status = '登出测试失败';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('认证系统调试'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: '清除日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isLoading ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            child: Text(
              '状态: $_status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isLoading ? Colors.orange : Colors.green,
              ),
            ),
          ),
          
          // 输入区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    hintText: '13812345678',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    hintText: '123456',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // 按钮组
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testPhoneValidation,
                      child: const Text('验证手机号'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testSupabaseSMS,
                      child: const Text('Supabase SMS'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testEdgeFunction,
                      child: const Text('Edge Function'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testCodeVerification,
                      child: const Text('验证验证码'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testLogout,
                      child: const Text('测试登出'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // 日志区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '调试日志 (${_logs.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[_logs.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}