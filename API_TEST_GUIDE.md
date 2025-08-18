# 星趣APP数据埋点系统 - API测试指南

> 🚀 **测试目标**: 验证数据埋点分析系统的API功能和Edge Functions  
> 📅 **创建时间**: 2025-01-07  

---

## 📋 测试概览

### 已开发的API服务

#### 1. **analytics-processor** - 数据处理核心
- **功能**: 接收并处理用户行为事件数据
- **路径**: `supabase/functions/analytics-processor/index.ts`
- **端点**: `POST /functions/v1/analytics-processor`

#### 2. **analytics-metrics** - 指标计算服务  
- **功能**: 计算各类业务指标(DAU、收入、留存、漏斗等)
- **路径**: `supabase/functions/analytics-metrics/index.ts`
- **端点**: `POST /functions/v1/analytics-metrics`

---

## 🧪 API测试用例

### 测试用例 1: 事件数据上报

**测试接口**: `analytics-processor`

```bash
curl -X POST 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/analytics-processor' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "event_name": "page_view",
  "event_category": "navigation",
  "properties": {
    "page_name": "home_selection",
    "page_title": "精选推荐",
    "from_page": "main_tab",
    "load_time": 320
  },
  "user_id": "user-test-001",
  "session_id": "session-test-001",
  "device_info": {
    "device_model": "iPhone 13",
    "os_version": "iOS 15.0",
    "app_version": "1.0.0"
  },
  "location_info": {
    "country": "CN",
    "city": "Beijing"
  }
}'
```

**预期响应**:
```json
{
  "success": true,
  "event_id": "uuid-generated-id",
  "message": "Event processed successfully"
}
```

### 测试用例 2: 会员购买事件

```bash
curl -X POST 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/analytics-processor' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "event_name": "membership_purchase_complete",
  "event_category": "business",
  "properties": {
    "plan_type": "premium",
    "amount": 298,
    "payment_method": "wechat",
    "order_id": "order_123456"
  },
  "user_id": "user-test-002",
  "session_id": "session-test-002"
}'
```

### 测试用例 3: 获取DAU指标

**测试接口**: `analytics-metrics`

```bash
curl -X POST 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/analytics-metrics' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "metric_type": "dau",
  "date_range": {
    "start_date": "2025-01-01",
    "end_date": "2025-01-07"
  },
  "filters": {
    "platform": "mobile"
  }
}'
```

**预期响应**:
```json
{
  "success": true,
  "data": {
    "metric_name": "Daily Active Users",
    "time_range": {"start_date": "2025-01-01", "end_date": "2025-01-07"},
    "total_days": 7,
    "average_dau": 1250,
    "peak_dau": 1800,
    "chart_data": [
      {"date": "2025-01-01", "dau": 1200, "users": ["user1", "user2"]},
      {"date": "2025-01-02", "dau": 1350, "users": ["user1", "user3"]}
    ]
  }
}
```

### 测试用例 4: 收入指标查询

```bash
curl -X POST 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/analytics-metrics' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "metric_type": "revenue",
  "date_range": {
    "start_date": "2025-01-01",
    "end_date": "2025-01-07"
  }
}'
```

### 测试用例 5: AARRR漏斗分析

```bash
curl -X POST 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/analytics-metrics' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "metric_type": "funnel",
  "date_range": {
    "start_date": "2025-01-01",
    "end_date": "2025-01-07"
  }
}'
```

---

## 🔍 基础API测试

### 测试Supabase自动生成的API

#### 1. 测试user_events表插入

```bash
curl -X POST 'https://wqdpqhfqrxvssxifpmvt.supabase.co/rest/v1/user_events' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'apikey: YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "event_name": "app_launch",
  "event_category": "lifecycle",
  "properties": {"launch_type": "cold_start", "is_first": false},
  "user_id": "test-user-uuid",
  "session_id": "test-session-001",
  "device_info": {"device_model": "iPhone 13", "os": "iOS"},
  "location_info": {"country": "CN"}
}'
```

#### 2. 测试user_events表查询

```bash
curl -X GET 'https://wqdpqhfqrxvssxifpmvt.supabase.co/rest/v1/user_events?select=*&limit=10' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'apikey: YOUR_ANON_KEY'
```

#### 3. 测试实时指标表查询

```bash
curl -X GET 'https://wqdpqhfqrxvssxifpmvt.supabase.co/rest/v1/realtime_metrics?select=*&order=created_at.desc&limit=10' \
-H 'Authorization: Bearer YOUR_ANON_KEY' \
-H 'apikey: YOUR_ANON_KEY'
```

---

## 📊 数据验证测试

### 验证数据表创建成功

```sql
-- 在Supabase SQL Editor中执行
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN (
    'user_events', 'user_sessions', 'user_attributes', 
    'daily_metrics', 'realtime_metrics', 'funnel_analysis', 'user_segments'
);
```

### 验证分区表设置

```sql
SELECT 
    schemaname, tablename, partitionname 
FROM pg_partitions 
WHERE tablename = 'user_events';
```

### 验证索引创建

```sql
SELECT indexname 
FROM pg_indexes 
WHERE tablename IN ('user_events', 'user_sessions', 'user_attributes')
ORDER BY tablename, indexname;
```

---

## 🛠️ 部署测试步骤

### 1. 部署Edge Functions

```bash
# 部署analytics-processor函数
supabase functions deploy analytics-processor --project-ref wqdpqhfqrxvssxifpmvt

# 部署analytics-metrics函数  
supabase functions deploy analytics-metrics --project-ref wqdpqhfqrxvssxifpmvt
```

### 2. 设置环境变量

在Supabase Dashboard → Settings → Functions中配置：
- `SUPABASE_URL`: https://wqdpqhfqrxvssxifpmvt.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: [从Dashboard获取service_role密钥]

### 3. 测试函数健康状态

```bash
curl -X GET 'https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/' \
-H 'Authorization: Bearer YOUR_ANON_KEY'
```

---

## ⚠️ 测试注意事项

### 1. 认证密钥配置
- **anon key**: 用于客户端API调用
- **service_role key**: 用于管理员权限API调用  
- 在生产环境中请妥善保管密钥

### 2. RLS策略测试
- 确保用户只能查询自己的数据
- 验证管理员可以查询所有数据
- 测试匿名用户的访问限制

### 3. 性能基准测试
- 单个事件写入延迟 < 100ms
- 批量查询响应时间 < 2s  
- 并发处理能力 > 100 req/s

### 4. 数据一致性验证
- 验证事件数据写入后触发器正常工作
- 检查用户属性自动更新
- 确认实时指标正确计算

---

## 📈 测试结果记录

| 测试项目 | 状态 | 响应时间 | 备注 |
|---------|------|----------|------|
| 数据库表创建 | ⏳ 待测试 | - | 需要先执行DDL |
| 事件数据上报 | ⏳ 待测试 | - | 需要部署Edge Function |
| DAU指标查询 | ⏳ 待测试 | - | 依赖基础数据 |
| 收入指标查询 | ⏳ 待测试 | - | 依赖payment_orders数据 |
| 漏斗分析 | ⏳ 待测试 | - | 需要足够的用户数据 |
| 基础CRUD API | ⏳ 待测试 | - | Supabase自动生成 |

---

## 🎯 下一步测试计划

1. **DDL执行** → 验证表结构创建
2. **Edge Functions部署** → 测试自定义业务逻辑  
3. **基础API测试** → 验证CRUD操作
4. **业务逻辑测试** → 验证指标计算准确性
5. **性能压力测试** → 验证系统承载能力
6. **安全策略测试** → 验证权限控制

完成API测试后，请输入 **/测试安全** 进行权限验证阶段。