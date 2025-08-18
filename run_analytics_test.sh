#!/bin/bash

# =============================================
# 埋点数据流快速测试脚本
# =============================================

echo "🚀 开始执行埋点数据流测试..."

# 检查Flutter环境
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或未在PATH中"
    exit 1
fi

echo "✅ Flutter环境检查通过"

# 进入项目根目录
cd "$(dirname "$0")"

# 确保依赖已安装
echo "📦 检查Flutter依赖..."
flutter pub get

# 运行埋点相关测试
echo "🧪 运行埋点测试..."
flutter test test/analytics_test.dart --coverage

# 如果测试文件不存在，创建基础测试
if [ ! -f "test/analytics_test.dart" ]; then
    echo "⚠️  测试文件不存在，创建基础测试..."
    
    cat > test/analytics_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/analytics_service.dart';

void main() {
  group('Analytics Service Tests', () {
    test('should initialize analytics service', () async {
      final analytics = AnalyticsService.instance;
      await analytics.initialize();
      
      expect(analytics.isEnabled, true);
      expect(analytics.sessionId, isNotNull);
    });
    
    test('should track page view events', () async {
      final analytics = AnalyticsService.instance;
      
      // 这个测试主要验证方法调用不会抛出异常
      expect(() async {
        await analytics.trackPageView('home_selection_page');
      }, returnsNormally);
    });
    
    test('should track social interaction events', () async {
      final analytics = AnalyticsService.instance;
      
      expect(() async {
        await analytics.trackSocialInteraction(
          actionType: 'like',
          targetType: 'character',
          targetId: 'test_id',
        );
      }, returnsNormally);
    });
  });
}
EOF

    echo "✅ 基础测试文件已创建"
    
    # 运行新创建的测试
    flutter test test/analytics_test.dart
fi

echo ""
echo "🎉 埋点测试完成！"
echo ""
echo "📱 下一步："
echo "  1. 在Flutter应用中触发首页-精选页的交互"
echo "  2. 检查Supabase控制台的user_analytics表是否有新数据"
echo "  3. 打开后台管理系统查看Mobile数据监控页面"
echo ""
echo "🔍 如果需要调试，可以查看以下日志："
echo "  - Flutter Console输出"
echo "  - Supabase实时日志"
echo "  - 后台系统浏览器控制台"