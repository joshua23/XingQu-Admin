# 星趣APP数据埋点系统 - 部署执行指南

> 📅 **部署时间**: 2025-01-07  
> 🎯 **版本**: v2.0.0 集成版  
> ⚠️ **重要**: 请在业务低峰期执行，建议先在测试环境验证

---

## 🔍 部署前检查

### 1. 环境准备检查
```bash
# 检查Supabase CLI版本
supabase --version

# 检查项目连接状态
supabase projects list

# 确认目标项目
echo "目标项目: wqdpqhfqrxvssxifpmvt (星趣APP)"
```

### 2. 数据库状态检查
在执行部署前，请先在Supabase Dashboard → SQL Editor中执行以下检查：

#### 2.1 检查现有关键表
```sql
-- 检查核心业务表是否存在
SELECT table_name, 'exists' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'users', 'interaction_logs', 'payment_orders', 
    'user_memberships', 'likes', 'comments', 'ai_characters'
  )
ORDER BY table_name;
```

#### 2.2 检查现有数据量
```sql
-- 检查关键表的数据量（评估影响范围）
SELECT 
    'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 
    'interaction_logs' as table_name, COUNT(*) as row_count FROM interaction_logs
UNION ALL  
SELECT 
    'payment_orders' as table_name, COUNT(*) as row_count FROM payment_orders
UNION ALL
SELECT 
    'user_memberships' as table_name, COUNT(*) as row_count FROM user_memberships;
```

#### 2.3 检查现有索引（避免冲突）
```sql
-- 检查是否存在可能冲突的索引
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE '%interaction_logs%'
ORDER BY indexname;
```

---

## 🚀 部署执行方案

### 方案A: Supabase Dashboard执行 (推荐)

#### 步骤1: 登录Supabase Dashboard
1. 访问 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择项目：星趣APP (wqdpqhfqrxvssxifpmvt)
3. 进入 SQL Editor

#### 步骤2: 分段执行DDL脚本
**重要**: 不要一次性执行全部脚本，建议分段执行以便观察结果

**第一段: 现有表扩展 (最安全)**
```sql
-- 复制并执行 Phase 1 部分 (第1-100行)
-- 这部分只是安全地添加字段，风险最低
DO $$ 
BEGIN
    RAISE NOTICE '开始执行Phase 1: 现有表安全扩展...';
END $$;

-- 检查interaction_logs表是否存在并安全扩展...
-- (复制DDL脚本中的Phase 1部分)
```

**执行后检查**:
```sql
-- 验证字段添加成功
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'interaction_logs' 
  AND column_name IN ('session_id', 'event_properties', 'target_object_type');
```

**第二段: 新建专门表**
```sql
-- 复制并执行 Phase 2 部分
-- 这部分创建新表，不影响现有数据
```

**第三段: 视图和汇总表**
```sql
-- 复制并执行 Phase 3-5 部分
-- 创建汇总表和集成视图
```

**第四段: 触发器和安全策略**
```sql
-- 复制并执行 Phase 6-7 部分
-- 添加自动化和安全策略
```

### 方案B: Supabase CLI执行 (高级用户)

```bash
# 确保在项目根目录
cd /Volumes/wawa_outer_4T/Users/wawa002/Documents/XingQu

# 连接到项目
supabase link --project-ref wqdpqhfqrxvssxifpmvt

# 执行迁移
supabase db push
```

---

## ⚠️ 安全执行策略

### 1. 回滚准备
在执行前，准备回滚方案：

```sql
-- 如需回滚，删除新建的对象
-- ⚠️ 仅在测试环境或确认需要时执行
DROP TABLE IF EXISTS app_tracking_events CASCADE;
DROP TABLE IF EXISTS user_behavior_summary CASCADE;
DROP VIEW IF EXISTS unified_tracking_events CASCADE;
DROP VIEW IF EXISTS payment_tracking_events CASCADE;
DROP VIEW IF EXISTS membership_tracking_events CASCADE;
DROP VIEW IF EXISTS social_like_tracking_events CASCADE;
DROP VIEW IF EXISTS interaction_logs_legacy CASCADE;

-- 移除添加的字段 (谨慎操作！)
-- ALTER TABLE interaction_logs DROP COLUMN IF EXISTS session_id;
-- ALTER TABLE interaction_logs DROP COLUMN IF EXISTS event_properties;
-- 等等...
```

### 2. 分步验证策略

#### Phase 1 验证
```sql
-- 验证interaction_logs扩展成功
SELECT 
    COUNT(*) as total_records,
    COUNT(session_id) as records_with_session,
    COUNT(event_properties) as records_with_properties
FROM interaction_logs;

-- 验证兼容性视图
SELECT COUNT(*) FROM interaction_logs_legacy;
```

#### Phase 2 验证  
```sql
-- 验证新表创建
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('app_tracking_events', 'user_behavior_summary');

-- 验证分区表
SELECT tablename, partitionname FROM pg_partitions 
WHERE tablename = 'app_tracking_events';
```

#### Phase 3-5 验证
```sql
-- 验证视图创建
SELECT table_name FROM information_schema.views 
WHERE table_name LIKE '%tracking_events';

-- 测试统一视图查询
SELECT data_source, COUNT(*) 
FROM unified_tracking_events 
GROUP BY data_source;
```

---

## 🧪 部署后测试

### 1. 基础功能测试

#### 测试数据写入
```sql
-- 测试interaction_logs扩展功能
INSERT INTO interaction_logs (
    user_id, interaction_type, session_id, event_properties, 
    target_object_type, target_object_id
) VALUES (
    (SELECT id FROM users LIMIT 1),
    'test_interaction',
    'test_session_001', 
    '{"test": true, "deployment_check": "success"}',
    'test_object',
    gen_random_uuid()
);

-- 测试app_tracking_events
INSERT INTO app_tracking_events (
    user_id, session_id, event_name, event_category,
    event_properties, page_name
) VALUES (
    (SELECT id FROM users LIMIT 1),
    'test_session_002',
    'test_page_view',
    'test',
    '{"test_deployment": true}',
    'deployment_test_page'
);
```

#### 验证自动触发器
```sql
-- 检查用户行为汇总是否自动更新
SELECT * FROM user_behavior_summary 
WHERE updated_at >= NOW() - INTERVAL '1 hour'
ORDER BY updated_at DESC;
```

#### 测试统一查询接口
```sql
-- 测试统一视图查询
SELECT 
    data_source, 
    event_name, 
    COUNT(*) as event_count
FROM unified_tracking_events 
WHERE event_timestamp >= NOW() - INTERVAL '1 hour'
GROUP BY data_source, event_name;
```

### 2. 性能测试

#### 查询性能测试
```sql
-- 测试高频查询性能
EXPLAIN ANALYZE 
SELECT * FROM app_tracking_events 
WHERE user_id = (SELECT id FROM users LIMIT 1)
  AND event_timestamp >= NOW() - INTERVAL '7 days';

-- 测试JSONB查询性能
EXPLAIN ANALYZE
SELECT * FROM app_tracking_events 
WHERE event_properties @> '{"test": true}'
  AND event_timestamp >= NOW() - INTERVAL '1 day';
```

### 3. 安全测试

#### RLS策略测试
```sql
-- 切换到普通用户视角测试
-- (需要在应用中通过实际用户token测试)

-- 测试用户只能查看自己的数据
SELECT COUNT(*) FROM app_tracking_events; -- 应该只返回当前用户的数据

-- 测试管理员权限
-- (需要管理员用户测试)
```

---

## 📊 部署验证清单

### ✅ Phase 1: 现有表扩展验证
- [ ] interaction_logs表字段添加成功
- [ ] 新增字段有合理默认值
- [ ] 现有数据完整性未受影响
- [ ] 兼容性视图查询正常
- [ ] 新增索引创建成功

### ✅ Phase 2: 新建表验证  
- [ ] app_tracking_events表创建成功
- [ ] 分区表结构正确
- [ ] user_behavior_summary表创建成功
- [ ] 所有索引创建完成
- [ ] 表注释和字段注释正确

### ✅ Phase 3-5: 集成视图验证
- [ ] payment_tracking_events视图可查询
- [ ] membership_tracking_events视图可查询
- [ ] social_like_tracking_events视图可查询
- [ ] unified_tracking_events视图可查询
- [ ] 视图数据格式统一正确

### ✅ Phase 6-7: 自动化和安全验证
- [ ] 触发器函数创建成功
- [ ] 用户行为汇总自动更新
- [ ] RLS策略生效
- [ ] 用户权限隔离正确
- [ ] 管理员权限正常

### ✅ 整体功能验证
- [ ] 测试数据写入成功
- [ ] 查询性能符合预期
- [ ] 数据一致性检查通过
- [ ] 现有应用功能未受影响

---

## 🚨 问题排查指南

### 常见问题及解决方案

#### 1. 扩展字段添加失败
**症状**: ALTER TABLE语句报错
**原因**: 可能的表锁或权限问题
**解决**: 
```sql
-- 检查表锁状态
SELECT * FROM pg_locks WHERE relation = (
    SELECT oid FROM pg_class WHERE relname = 'interaction_logs'
);

-- 使用IF NOT EXISTS确保安全
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS session_id VARCHAR(255);
```

#### 2. 索引创建缓慢
**症状**: CREATE INDEX CONCURRENTLY长时间执行
**原因**: 大表数据量导致
**解决**: 
- 在低峰期执行
- 可暂时跳过非关键索引
- 分批创建索引

#### 3. 视图查询失败
**症状**: 统一视图查询报错
**原因**: 依赖表不存在或结构不匹配
**解决**:
```sql
-- 检查依赖表
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('payment_orders', 'user_memberships', 'likes');

-- 逐个测试视图组件
SELECT * FROM payment_tracking_events LIMIT 1;
```

#### 4. 触发器不工作
**症状**: 用户行为汇总未自动更新
**原因**: 触发器函数或触发器创建失败
**解决**:
```sql
-- 检查触发器状态
SELECT * FROM information_schema.triggers 
WHERE event_object_table = 'app_tracking_events';

-- 手动测试触发器函数
SELECT update_user_behavior_summary_from_events();
```

---

## 🎯 部署成功标准

### 技术标准
- ✅ 所有DDL语句执行成功，无错误
- ✅ 新建表和视图查询正常
- ✅ 现有表功能完全不受影响
- ✅ 索引创建完成，查询性能良好
- ✅ 触发器和自动化功能正常工作

### 业务标准
- ✅ 现有应用功能完全正常
- ✅ 用户数据安全性和隐私保护不受影响
- ✅ 系统响应时间无明显变化
- ✅ 数据一致性和完整性得到保证

### 可用性标准
- ✅ 可以成功写入测试埋点事件
- ✅ 统一查询接口返回正确数据
- ✅ 用户行为汇总自动更新
- ✅ 集成视图显示现有业务数据

---

## 📞 部署支持

### 执行建议
1. **测试环境先行** - 如有测试环境，建议先执行验证
2. **分段执行** - 不要一次性执行全部DDL，分阶段观察结果
3. **备份重要** - 执行前确保数据库有可用备份
4. **监控关注** - 执行期间关注系统性能和错误日志
5. **回滚准备** - 准备好回滚脚本，必要时快速恢复

**执行完成后，请输入 /API测试 进入下一阶段。**