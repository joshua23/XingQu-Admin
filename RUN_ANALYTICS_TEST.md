# 🧪 埋点测试执行指南

## 📱 在Flutter应用中运行测试

### 方法1：在main.dart中添加测试调用

在 `lib/main.dart` 中添加以下代码：

```dart
// 在main.dart顶部添加导入
import 'utils/analytics_test_helper.dart';

// 在main()函数中或应用启动后添加
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Supabase等服务...
  
  runApp(MyApp());
  
  // 在应用启动后执行埋点测试（仅调试模式）
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await QuickAnalyticsTest.quickTest();
  });
}
```

### 方法2：在首页-精选页中手动触发

在 `lib/pages/home_tabs/home_selection_page.dart` 中添加测试按钮：

```dart
// 在initState()中添加
@override
void initState() {
  super.initState();
  _ensureUserAndLoadStatus();
  
  // 开发模式下自动运行测试
  if (kDebugMode) {
    Future.delayed(Duration(seconds: 2), () {
      QuickAnalyticsTest.liveTest();
    });
  }
}

// 或添加一个测试按钮
FloatingActionButton(
  onPressed: () async {
    await AnalyticsTestHelper.runFeaturePageTest();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('埋点测试完成，请检查后台数据')),
    );
  },
  child: Icon(Icons.analytics),
  backgroundColor: Colors.orange,
)
```

## 🔍 测试验证步骤

### 1. 执行测试
- 运行Flutter应用（`flutter run`）
- 应用启动后会自动执行埋点测试
- 在控制台查看测试日志输出

### 2. 检查Supabase数据
在Supabase控制台执行以下查询：

```sql
-- 查看最近的测试埋点数据
SELECT 
    event_type,
    event_data->>'session_id' as session_id,
    event_data->>'test_type' as test_type,
    created_at
FROM user_analytics 
WHERE event_data->>'test_type' IN ('automated', 'real_simulation', 'connectivity')
ORDER BY created_at DESC 
LIMIT 20;
```

### 3. 检查后台管理系统
- 打开后台管理系统
- 进入"Mobile数据监控"页面
- 检查：
  - ✅ 连接状态显示"已连接"
  - ✅ 活跃用户数有更新
  - ✅ 互动次数有增长  
  - ✅ 实时活动流显示测试事件

### 4. 验证实时数据流
- 在Flutter应用中触发真实交互（点赞、关注等）
- 观察后台系统是否实时显示新数据
- 检查活动流是否出现相应事件

## 📊 预期测试结果

### 控制台输出示例
```
🚀 开始快速埋点测试...
🔍 检查埋点服务连通性...
✅ 埋点服务连通性正常
🧪 开始执行首页-精选页埋点测试...
🔍 测试页面访问埋点...
✅ 页面访问埋点测试完成
🔍 测试角色交互埋点...
✅ 角色交互埋点测试完成
🔍 测试社交互动埋点...
✅ 社交互动埋点测试完成
🔍 测试批量埋点上报...
✅ 批量埋点测试完成 (3 个事件)
🔍 检查埋点服务状态...
  - 服务启用状态: true
  - 会话ID: 1736284800000
  - 设备信息: 已收集
✅ 服务状态检查完成
✅ 所有埋点测试完成！
```

### Supabase数据示例
```sql
event_type              | session_id    | test_type  | created_at
-------------------------|---------------|------------|---------------------------
page_view               | test_1736284  | automated  | 2025-01-08 10:30:15+00
character_interaction   | test_1736284  | automated  | 2025-01-08 10:30:16+00
social_interaction      | test_1736284  | automated  | 2025-01-08 10:30:17+00
```

## 🚨 问题排查

### 如果测试失败
1. **检查网络连接**：确保设备能访问Supabase
2. **检查用户登录**：确保用户已登录或使用匿名登录
3. **检查Supabase配置**：验证`lib/config/supabase_config.dart`配置正确
4. **查看详细错误**：在控制台查看具体错误信息

### 如果后台系统无数据显示
1. **检查表结构**：确认`user_analytics`表已创建并包含所有字段
2. **检查RLS策略**：确认用户有权限访问数据
3. **检查实时连接**：确认Supabase Realtime功能正常
4. **刷新页面**：尝试刷新后台管理系统页面

## 🎯 测试成功标志

- ✅ Flutter控制台显示所有测试步骤完成
- ✅ Supabase数据库中有测试数据记录
- ✅ 后台管理系统显示"已连接"状态
- ✅ 实时活动流显示测试事件
- ✅ 统计数字（用户数、互动数）有更新

完成以上验证后，埋点数据流修复即宣告成功！🎉