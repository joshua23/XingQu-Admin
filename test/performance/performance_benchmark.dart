import 'dart:io';
import 'dart:convert';

/// 性能基准测试工具
/// 用于在不同设备配置下测试应用性能
class PerformanceBenchmark {
  static const Map<String, Map<String, dynamic>> deviceProfiles = {
    // 低端设备配置
    'low_end': {
      'name': '低端设备 (Android 6.0, 2GB RAM)',
      'expected_startup_ms': 4000,
      'expected_memory_mb': 120,
      'expected_cpu_idle': 25,
      'expected_fps': 40,
    },
    
    // 中端设备配置
    'mid_range': {
      'name': '中端设备 (Android 9.0, 4GB RAM)',
      'expected_startup_ms': 2500,
      'expected_memory_mb': 80,
      'expected_cpu_idle': 20,
      'expected_fps': 55,
    },
    
    // 高端设备配置
    'high_end': {
      'name': '高端设备 (Android 11+, 8GB RAM)',
      'expected_startup_ms': 1500,
      'expected_memory_mb': 60,
      'expected_cpu_idle': 15,
      'expected_fps': 60,
    },
  };
  
  /// 运行性能基准测试
  static Future<Map<String, dynamic>> runBenchmark({
    required String deviceType,
    required Map<String, dynamic> actualResults,
  }) async {
    final profile = deviceProfiles[deviceType];
    if (profile == null) {
      throw ArgumentError('未知设备类型: $deviceType');
    }
    
    final benchmark = <String, dynamic>{
      'device_profile': profile,
      'test_timestamp': DateTime.now().toIso8601String(),
      'results': <String, dynamic>{},
    };
    
    // 启动性能评分
    final startupScore = _calculateScore(
      actualResults['startup']['cold_start_ms'],
      profile['expected_startup_ms'],
      inverse: true, // 启动时间越低越好
    );
    
    // 内存使用评分
    final memoryScore = _calculateScore(
      actualResults['memory']['peak_usage_mb'],
      profile['expected_memory_mb'],
      inverse: true, // 内存使用越低越好
    );
    
    // CPU使用评分
    final cpuScore = _calculateScore(
      actualResults['cpu']['idle_percent'],
      profile['expected_cpu_idle'],
      inverse: true, // CPU使用越低越好
    );
    
    // FPS性能评分
    final fpsScore = _calculateScore(
      actualResults['scrolling']['average_fps'],
      profile['expected_fps'],
      inverse: false, // FPS越高越好
    );
    
    // 计算综合评分
    final overallScore = (startupScore + memoryScore + cpuScore + fpsScore) / 4;
    
    benchmark['results'] = {
      'startup_score': startupScore,
      'memory_score': memoryScore,
      'cpu_score': cpuScore,
      'fps_score': fpsScore,
      'overall_score': overallScore,
      'performance_grade': _getPerformanceGrade(overallScore),
      'recommendations': _generateRecommendations(
        startupScore, memoryScore, cpuScore, fpsScore),
    };
    
    return benchmark;
  }
  
  /// 计算性能评分 (0-100)
  static double _calculateScore(double actual, double expected, {required bool inverse}) {
    if (inverse) {
      // 数值越低越好（如启动时间、内存使用）
      if (actual <= expected) return 100.0;
      return (100.0 * expected / actual).clamp(0.0, 100.0);
    } else {
      // 数值越高越好（如FPS）
      if (actual >= expected) return 100.0;
      return (100.0 * actual / expected).clamp(0.0, 100.0);
    }
  }
  
  /// 获取性能等级
  static String _getPerformanceGrade(double score) {
    if (score >= 90) return 'A+ 优秀';
    if (score >= 80) return 'A 良好';
    if (score >= 70) return 'B 一般';
    if (score >= 60) return 'C 较差';
    return 'D 需要优化';
  }
  
  /// 生成优化建议
  static List<String> _generateRecommendations(
    double startupScore, double memoryScore, double cpuScore, double fpsScore) {
    final recommendations = <String>[];
    
    if (startupScore < 70) {
      recommendations.add('🚀 优化应用启动时间：考虑延迟加载、减少初始化操作');
    }
    
    if (memoryScore < 70) {
      recommendations.add('💾 优化内存使用：检查内存泄漏、优化图片缓存策略');
    }
    
    if (cpuScore < 70) {
      recommendations.add('⚡ 优化CPU使用：减少不必要的计算、优化算法复杂度');
    }
    
    if (fpsScore < 70) {
      recommendations.add('📱 优化渲染性能：减少Widget重建、优化动画实现');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ 性能表现良好，继续保持！');
    }
    
    return recommendations;
  }
  
  /// 生成性能报告
  static Future<void> generateReport(Map<String, dynamic> benchmark, String outputPath) async {
    final report = StringBuffer();
    
    report.writeln('# 星趣项目 Flutter 性能测试报告');
    report.writeln('');
    report.writeln('## 测试环境');
    report.writeln('- 设备类型: ${benchmark['device_profile']['name']}');
    report.writeln('- 测试时间: ${benchmark['test_timestamp']}');
    report.writeln('');
    
    report.writeln('## 性能指标');
    final results = benchmark['results'];
    report.writeln('- 启动性能: ${results['startup_score'].toStringAsFixed(1)}/100');
    report.writeln('- 内存使用: ${results['memory_score'].toStringAsFixed(1)}/100');
    report.writeln('- CPU效率: ${results['cpu_score'].toStringAsFixed(1)}/100');
    report.writeln('- 渲染性能: ${results['fps_score'].toStringAsFixed(1)}/100');
    report.writeln('');
    
    report.writeln('## 综合评分');
    report.writeln('**${results['overall_score'].toStringAsFixed(1)}/100 (${results['performance_grade']})**');
    report.writeln('');
    
    report.writeln('## 优化建议');
    final recommendations = results['recommendations'] as List<String>;
    for (final recommendation in recommendations) {
      report.writeln('- $recommendation');
    }
    
    // 写入文件
    final file = File(outputPath);
    await file.writeAsString(report.toString());
    print('📄 性能报告已生成: $outputPath');
  }
  
  /// 生成JSON格式的性能数据
  static Future<void> exportToJson(Map<String, dynamic> benchmark, String outputPath) async {
    final file = File(outputPath);
    final jsonString = JsonEncoder.withIndent('  ').convert(benchmark);
    await file.writeAsString(jsonString);
    print('📊 性能数据已导出: $outputPath');
  }
}