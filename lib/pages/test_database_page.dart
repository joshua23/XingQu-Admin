import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_tester.dart';

/// 数据库测试页面
/// 用于验证数据库连接和API功能
class TestDatabasePage extends StatefulWidget {
  const TestDatabasePage({Key? key}) : super(key: key);

  @override
  State<TestDatabasePage> createState() => _TestDatabasePageState();
}

class _TestDatabasePageState extends State<TestDatabasePage> {
  bool _isLoading = false;
  Map<String, bool> _testResults = {};
  String _statusMessage = '点击开始验证数据库连接';

  @override
  void initState() {
    super.initState();
    // 自动开始测试
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runTests();
    });
  }

  /// 运行所有测试
  Future<void> _runTests() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '正在验证数据库连接...';
      _testResults.clear();
    });

    try {
      final results = await ApiTester.runFullValidation();
      
      setState(() {
        _testResults = results;
        _isLoading = false;
        
        final successCount = results.values.where((v) => v).length;
        final totalTests = results.length;
        
        if (successCount == totalTests) {
          _statusMessage = '🎉 验证完成！数据库连接正常，所有功能可用';
        } else {
          _statusMessage = '⚠️ 验证完成，部分功能存在问题';
        }
      });

      // 显示统计信息
      await ApiTester.showDatabaseStats();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 验证失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '数据库连接验证',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface.withOpacity(0.3),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 状态卡片
                _buildStatusCard(),
                
                const SizedBox(height: 20),
                
                // 测试结果列表
                Expanded(
                  child: _buildTestResults(),
                ),
                
                const SizedBox(height: 20),
                
                // 操作按钮
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
          ],
          
          Text(
            _statusMessage,
            style: AppTextStyles.bodyLarge.copyWith(
              color: _isLoading 
                  ? AppColors.textSecondary 
                  : (_testResults.values.every((v) => v) && _testResults.isNotEmpty)
                      ? Colors.green
                      : _testResults.isNotEmpty
                          ? Colors.orange
                          : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_testResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _testResults.values.every((v) => v) 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: _testResults.values.every((v) => v) 
                      ? Colors.green 
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_testResults.values.where((v) => v).length}/${_testResults.length} 项测试通过',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建测试结果列表
  Widget _buildTestResults() {
    if (_testResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '等待测试结果...',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final testInfo = {
      'database_connection': {'name': '数据库连接', 'icon': Icons.link},
      'table_structure': {'name': '表结构验证', 'icon': Icons.table_chart},
      'test_data_creation': {'name': '测试数据创建', 'icon': Icons.add_box},
      'api_functions': {'name': 'API功能测试', 'icon': Icons.api},
    };

    return ListView.builder(
      itemCount: _testResults.length,
      itemBuilder: (context, index) {
        final key = _testResults.keys.elementAt(index);
        final passed = _testResults[key] ?? false;
        final info = testInfo[key];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: passed 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                (info?['icon'] as IconData?) ?? Icons.help,
                color: passed ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  (info?['name'] as String?) ?? key,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                passed ? Icons.check_circle : Icons.error,
                color: passed ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Column(
      children: [
        // 重新测试按钮
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _runTests,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _isLoading ? '验证中...' : '重新验证',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 返回首页按钮
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '返回首页',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}