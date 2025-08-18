# Supabase数据埋点系统部署指南

## 📋 部署前准备

### 1. 获取Supabase连接信息
登录 [Supabase Dashboard](https://supabase.com/dashboard)：
- 项目：星趣APP (wqdpqhfqrxvssxifpmvt)
- 设置 → API → 获取 `service_role` 密钥
- 设置 → Database → Connection string

### 2. 数据库连接方式选择

#### 方式一：通过Supabase Dashboard执行 (推荐)
1. 进入 [Supabase Dashboard](https://supabase.com/dashboard) 
2. 选择项目：星趣APP
3. 左侧菜单 → SQL Editor
4. 复制 `supabase/migrations/20250107_analytics_schema.sql` 内容
5. 粘贴并执行

#### 方式二：通过psql命令行执行
```bash
# 使用connection string连接
psql "postgresql://postgres:[YOUR-PASSWORD]@db.wqdpqhfqrxvssxifpmvt.supabase.co:5432/postgres"

# 执行部署脚本
\i deploy_analytics_schema.sql
```

#### 方式三：通过Supabase CLI执行 (需要项目服务密钥)
```bash
# 登录Supabase
supabase login

# 链接到现有项目
supabase link --project-ref wqdpqhfqrxvssxifpmvt

# 执行迁移
supabase db push
```

## 🚀 部署执行

### 安全执行步骤：
1. **备份现有数据** (重要！)
2. 在非高峰时段执行
3. 逐步执行，观察每个步骤的结果
4. 验证表结构和数据完整性

### 执行验证：
部署后应看到以下输出：
```
✅ 分析系统部署成功！已创建7个核心表
🎉 数据埋点分析系统部署完成！
📊 可开始使用实时分析和运营看板功能
```

## 📊 部署后验证

### 检查表是否创建成功：
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN (
    'user_events', 'user_sessions', 'user_attributes', 
    'daily_metrics', 'realtime_metrics', 'funnel_analysis', 'user_segments'
);
```

### 检查分区是否创建：
```sql
SELECT schemaname, tablename, partitionname 
FROM pg_partitions 
WHERE tablename = 'user_events';
```

### 检查索引是否创建：
```sql
SELECT indexname 
FROM pg_indexes 
WHERE tablename IN ('user_events', 'user_sessions', 'user_attributes');
```

## ⚠️ 重要提醒

1. **生产环境执行**：请在业务低峰期执行，避免影响用户体验
2. **权限检查**：确保执行用户有CREATE TABLE、CREATE INDEX等权限
3. **存储空间**：分区表和索引会占用额外存储空间
4. **监控告警**：部署后监控数据库性能指标

## 🔄 回滚方案

如需回滚，请执行：
```sql
-- 删除分析系统相关表（谨慎操作！）
DROP TABLE IF EXISTS user_segments CASCADE;
DROP TABLE IF EXISTS funnel_analysis CASCADE;
DROP TABLE IF EXISTS realtime_metrics CASCADE;
DROP TABLE IF EXISTS daily_metrics CASCADE;
DROP TABLE IF EXISTS user_attributes CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS user_events CASCADE;

-- 删除物化视图
DROP MATERIALIZED VIEW IF EXISTS today_realtime_metrics;

-- 删除视图
DROP VIEW IF EXISTS user_overview;
```

部署完成后请输入 **/API测试** 进入下一阶段。