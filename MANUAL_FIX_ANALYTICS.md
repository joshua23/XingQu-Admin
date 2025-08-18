# 🔧 埋点数据流修复指南

## 问题诊断

通过对代码分析，我发现了"首页-精选页"埋点数据无法在后台管理系统显示的问题：

### ✅ **已确认正常的部分**
1. ✅ Flutter移动端埋点代码已正确实现（`lib/services/analytics_service.dart`）
2. ✅ 后台管理系统监听逻辑正确（`web-components/src/components/MobileDataMonitor.tsx`）
3. ✅ 数据库迁移文件存在（`supabase/migrations/20250107_analytics_integration_schema.sql`）

### ❌ **可能的问题根源**
- **数据库表缺失**：`user_analytics`表可能未在Supabase数据库中创建
- **RLS策略未配置**：表的访问权限策略可能缺失
- **索引缺失**：影响查询性能和实时监听

## 🛠️ 修复步骤

### 步骤1：执行数据库修复脚本

请在Supabase控制台的SQL编辑器中执行以下脚本：

```sql
-- 创建user_analytics表（如果不存在）
CREATE TABLE IF NOT EXISTS user_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}',
    session_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 埋点专用字段
    page_name VARCHAR(100),
    device_info JSONB DEFAULT '{}',
    target_object_type VARCHAR(50),
    target_object_id UUID
);

-- 创建必要的索引
CREATE INDEX IF NOT EXISTS idx_user_analytics_user_time ON user_analytics (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_analytics_event_time ON user_analytics (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_analytics_session ON user_analytics (session_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_event_data_gin ON user_analytics USING GIN (event_data);

-- 启用RLS并设置策略
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- 删除可能存在的旧策略
DROP POLICY IF EXISTS "Users can access own analytics" ON user_analytics;

-- 创建新的RLS策略
CREATE POLICY "Users can access own analytics" ON user_analytics
    FOR ALL USING (auth.uid()::uuid = user_id);

-- 创建likes表（如果不存在，后台监听需要）
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id UUID NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_likes_user ON likes (user_id);
CREATE INDEX IF NOT EXISTS idx_likes_target ON likes (target_id, target_type);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
CREATE POLICY "Users can manage own likes" ON likes FOR ALL USING (auth.uid()::uuid = user_id);

-- 创建character_follows表（如果不存在，后台监听需要）
CREATE TABLE IF NOT EXISTS character_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_character_follows_user ON character_follows (user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_character ON character_follows (character_id);

ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own follows" ON character_follows;
CREATE POLICY "Users can manage own follows" ON character_follows FOR ALL USING (auth.uid()::uuid = user_id);
```

### 步骤2：测试数据写入

在Supabase控制台执行以下测试SQL，确认数据可以正常写入：

```sql
-- 测试插入数据
INSERT INTO user_analytics (
    user_id, 
    event_type, 
    event_data, 
    session_id,
    page_name
) VALUES (
    (SELECT id FROM users LIMIT 1),  -- 使用第一个现有用户
    'test_page_view',
    '{"source": "featured_page", "test": true}',
    'test_session_' || extract(epoch from now()),
    'home_selection_page'
);

-- 验证数据插入成功
SELECT COUNT(*) as total_records FROM user_analytics;
SELECT event_type, page_name, created_at FROM user_analytics WHERE event_type = 'test_page_view';

-- 删除测试数据
DELETE FROM user_analytics WHERE event_type = 'test_page_view';
```

### 步骤3：验证移动端连接

1. **重启Flutter应用**：确保应用重新初始化analytics服务
2. **触发埋点事件**：在首页-精选页进行点赞、关注等交互
3. **检查数据库**：在Supabase控制台查看`user_analytics`表是否有新数据

```sql
-- 检查最近的埋点记录
SELECT 
    event_type, 
    page_name, 
    user_id, 
    created_at,
    event_data
FROM user_analytics 
ORDER BY created_at DESC 
LIMIT 10;
```

### 步骤4：验证后台系统显示

1. **刷新后台管理系统**的Mobile数据监控页面
2. **查看实时活动流**是否显示移动端交互数据
3. **检查连接状态**是否显示"已连接"

## 🔧 额外修复 - SupabaseService记录方法增强

如果上述步骤完成后仍有问题，请在Flutter代码中添加更详细的日志：

在`lib/services/supabase_service.dart`的`recordUserAnalytics`方法中添加调试日志：

```dart
/// 记录用户行为 - 增强版
Future<void> recordUserAnalytics({
  required String userId,
  required String eventType,
  Map<String, dynamic>? eventData,
  String? sessionId,
}) async {
  try {
    print('🔍 Attempting to record analytics: $eventType for user: $userId');
    
    final data = {
      'user_id': userId,
      'event_type': eventType,
      'event_data': eventData ?? {},
      'session_id': sessionId,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    print('📤 Analytics data: ${jsonEncode(data)}');
    
    final result = await client.from('user_analytics').insert(data);
    
    print('✅ Analytics recorded successfully');
    
  } catch (e) {
    print('❌ Failed to record analytics: $e');
    print('   Event: $eventType');
    print('   User: $userId');
    rethrow;
  }
}
```

## 📊 验证检查清单

完成修复后，请确认以下各项：

- [ ] Supabase控制台中`user_analytics`表存在且有数据
- [ ] Flutter应用点击首页-精选页的点赞/关注有console日志输出
- [ ] 后台管理系统Mobile监控页面显示"已连接"状态
- [ ] 实时活动流显示移动端交互数据
- [ ] 统计数字（活跃用户数、互动次数）有数据显示

## 🆘 如果仍有问题

请提供以下信息以便进一步诊断：

1. **Supabase控制台截图**：显示`user_analytics`表结构和数据
2. **Flutter Console日志**：应用运行时的analytics相关日志
3. **后台管理系统截图**：Mobile数据监控页面的显示状态
4. **网络检查**：确认移动端和后台都能正常连接Supabase

---

**预计修复时间**：5-10分钟  
**影响范围**：不影响现有功能，仅增强数据监控能力