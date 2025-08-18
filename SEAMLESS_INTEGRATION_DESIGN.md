# 数据埋点系统无缝集成设计方案

> 📅 **设计时间**: 2025-01-07  
> 🎯 **目标**: 基于分层混合策略，设计与现有星趣系统完全兼容的埋点集成方案

---

## 📋 集成设计总览

### 设计原则
1. **零影响原则** - 不影响现有业务功能和性能
2. **渐进增强原则** - 分阶段实施，每阶段都可独立运行
3. **数据权威性原则** - 使用现有表作为数据权威源
4. **向后兼容原则** - 新功能向后兼容现有API和查询

### 三层集成架构
```
第三层：数据分析层 (新增)
    ├── 实时指标计算
    ├── 数据看板API
    └── 用户行为分析
              ↓
第二层：埋点数据层 (扩展+新建)
    ├── interaction_logs (扩展)
    ├── app_tracking_events (新建)
    └── user_behavior_summary (新建)
              ↓
第一层：业务数据层 (现有)
    ├── payment_orders (利用)
    ├── user_memberships (利用)
    ├── likes, comments (利用)
    └── users, ai_characters (利用)
```

---

## 🔧 第一阶段：扩展现有表 (P0实施)

### 1.1 扩展interaction_logs表

#### 当前推测结构
```sql
-- 现有interaction_logs表结构 (推测)
CREATE TABLE interaction_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    interaction_type VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 无缝扩展方案
```sql
-- 安全扩展：添加埋点专用字段
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS session_id VARCHAR(255);
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS event_properties JSONB DEFAULT '{}';
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS target_object_type VARCHAR(50);
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS target_object_id UUID;
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS page_context JSONB DEFAULT '{}';
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}';

-- 添加必要索引（不影响现有查询）
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_logs_session_id 
    ON interaction_logs (session_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_logs_target 
    ON interaction_logs (target_object_type, target_object_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_logs_properties 
    ON interaction_logs USING GIN (event_properties);
```

#### 兼容性保证
```sql
-- 创建视图保证向后兼容
CREATE VIEW interaction_logs_legacy AS
SELECT id, user_id, interaction_type, created_at 
FROM interaction_logs;

-- 现有应用继续使用legacy视图，新功能使用完整表
```

### 1.2 数据写入兼容策略

#### 智能字段映射
```typescript
// 埋点数据写入时的智能映射
interface LegacyInteractionLog {
    user_id: string;
    interaction_type: string;
}

interface EnhancedInteractionLog extends LegacyInteractionLog {
    session_id?: string;
    event_properties?: Record<string, any>;
    target_object_type?: string;
    target_object_id?: string;
    page_context?: Record<string, any>;
    device_info?: Record<string, any>;
}

// 兼容写入函数
function logInteraction(data: EnhancedInteractionLog) {
    // 如果是新格式数据，使用完整字段
    if (hasEnhancedFields(data)) {
        return insertEnhancedInteraction(data);
    }
    // 如果是旧格式数据，保持兼容
    return insertLegacyInteraction(data);
}
```

### 1.3 立即可用的埋点事件

基于扩展后的`interaction_logs`，立即支持以下PRD核心事件：

| PRD事件 | interaction_type值 | event_properties示例 |
|---------|-------------------|---------------------|
| social_like | 'like' | `{"target_type": "story", "target_id": "uuid"}` |
| social_follow | 'follow' | `{"target_type": "character", "character_id": "uuid"}` |
| social_comment | 'comment' | `{"target_type": "story", "content_preview": "..."}` |
| ai_chat_start | 'ai_chat' | `{"character_id": "uuid", "chat_type": "voice"}` |
| page_interaction | 'page_action' | `{"action": "scroll", "page": "home_selection"}` |

---

## 🆕 第二阶段：新建专门表 (P1实施)

### 2.1 新建app_tracking_events表

#### 专门设计的埋点表
```sql
-- 专门的应用事件追踪表
CREATE TABLE app_tracking_events (
    -- 主键和基础信息
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255) NOT NULL,
    
    -- 事件核心信息
    event_name VARCHAR(100) NOT NULL,
    event_category VARCHAR(50) DEFAULT 'general',
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 事件属性 (JSONB for flexibility)
    event_properties JSONB DEFAULT '{}',
    
    -- 页面相关信息
    page_name VARCHAR(100),
    page_path VARCHAR(255),
    page_title VARCHAR(255),
    referrer_page VARCHAR(255),
    
    -- 设备和环境信息
    device_info JSONB DEFAULT '{}', -- 设备型号、OS版本、APP版本等
    network_info JSONB DEFAULT '{}', -- 网络类型、运营商等
    
    -- 位置和渠道信息
    location_info JSONB DEFAULT '{}', -- 地理位置、IP等
    channel_attribution JSONB DEFAULT '{}', -- 来源渠道、utm参数等
    
    -- 性能指标
    page_load_time INTEGER, -- 页面加载时间(ms)
    network_latency INTEGER, -- 网络延迟(ms)
    
    -- 业务关联字段 (与现有业务表关联)
    story_id UUID REFERENCES stories(id) ON DELETE SET NULL,
    character_id UUID REFERENCES ai_characters(id) ON DELETE SET NULL,
    target_object_type VARCHAR(50), -- 通用目标类型
    target_object_id UUID, -- 通用目标ID
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (event_timestamp); -- 按时间分区优化

-- 创建分区表 (按月分区)
CREATE TABLE app_tracking_events_202501 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE app_tracking_events_202502 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE app_tracking_events_202503 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
```

#### 性能优化索引
```sql
-- 核心查询索引
CREATE INDEX CONCURRENTLY idx_app_tracking_events_user_time 
    ON app_tracking_events (user_id, event_timestamp DESC);
CREATE INDEX CONCURRENTLY idx_app_tracking_events_name_time 
    ON app_tracking_events (event_name, event_timestamp DESC);
CREATE INDEX CONCURRENTLY idx_app_tracking_events_session 
    ON app_tracking_events (session_id);
CREATE INDEX CONCURRENTLY idx_app_tracking_events_category 
    ON app_tracking_events (event_category, event_timestamp DESC);

-- JSONB属性查询索引
CREATE INDEX CONCURRENTLY idx_app_tracking_events_properties 
    ON app_tracking_events USING GIN (event_properties);
CREATE INDEX CONCURRENTLY idx_app_tracking_events_device 
    ON app_tracking_events USING GIN (device_info);
```

### 2.2 支持的专门事件类型

| PRD事件 | event_name | event_category | 特殊字段 |
|---------|------------|----------------|----------|
| app_launch | 'app_launch' | 'lifecycle' | launch_type, is_cold_start |
| page_view | 'page_view' | 'navigation' | page_name, load_time, from_page |
| app_background | 'app_background' | 'lifecycle' | session_duration, pages_visited |
| search_query | 'search_query' | 'discovery' | query_text, results_count |
| content_view | 'content_view' | 'engagement' | content_type, view_duration |

---

## 🔗 第三阶段：业务数据集成 (P0实施)

### 3.1 利用现有支付数据

#### payment_orders表集成
```sql
-- 创建支付事件视图（避免重复存储）
CREATE VIEW payment_tracking_events AS
SELECT 
    id as event_id,
    user_id,
    'membership_purchase_complete' as event_name,
    'business' as event_category,
    created_at as event_timestamp,
    json_build_object(
        'amount', amount,
        'plan_id', plan_id,
        'payment_provider', payment_provider,
        'order_number', order_number,
        'status', status
    ) as event_properties,
    plan_id as target_object_id,
    'subscription_plan' as target_object_type
FROM payment_orders 
WHERE status = 'completed';
```

### 3.2 利用现有会员数据

#### user_memberships表集成
```sql
-- 创建会员行为事件视图
CREATE VIEW membership_tracking_events AS
SELECT 
    id as event_id,
    user_id,
    CASE 
        WHEN status = 'active' THEN 'membership_activated'
        WHEN status = 'expired' THEN 'membership_expired'
        WHEN status = 'cancelled' THEN 'membership_cancelled'
    END as event_name,
    'membership' as event_category,
    updated_at as event_timestamp,
    json_build_object(
        'plan_id', plan_id,
        'status', status,
        'auto_renew', auto_renew,
        'expires_at', expires_at
    ) as event_properties
FROM user_memberships;
```

### 3.3 利用现有社交数据

#### likes表集成
```sql
-- 创建点赞事件视图
CREATE VIEW like_tracking_events AS
SELECT 
    id as event_id,
    user_id,
    'social_like' as event_name,
    'social' as event_category,
    created_at as event_timestamp,
    json_build_object(
        'target_type', target_type,
        'target_id', target_id
    ) as event_properties,
    target_id as target_object_id,
    target_type as target_object_type
FROM likes;
```

---

## 📊 第四阶段：统一数据视图 (P1实施)

### 4.1 创建统一埋点事件视图

#### 全量事件统一查询
```sql
-- 统一的埋点事件视图（所有数据源合并）
CREATE VIEW unified_tracking_events AS
-- 来自app_tracking_events的数据
SELECT 
    id as event_id,
    user_id,
    event_name,
    event_category,
    event_timestamp,
    event_properties,
    session_id,
    page_name,
    device_info,
    target_object_type,
    target_object_id,
    'app_tracking' as data_source
FROM app_tracking_events

UNION ALL

-- 来自扩展后interaction_logs的数据
SELECT 
    id as event_id,
    user_id,
    interaction_type as event_name,
    'interaction' as event_category,
    created_at as event_timestamp,
    event_properties,
    session_id,
    (page_context->>'page_name') as page_name,
    device_info,
    target_object_type,
    target_object_id,
    'interaction_logs' as data_source
FROM interaction_logs

UNION ALL

-- 来自支付数据的事件
SELECT 
    event_id,
    user_id,
    event_name,
    event_category,
    event_timestamp,
    event_properties,
    NULL as session_id,
    NULL as page_name,
    '{}'::jsonb as device_info,
    target_object_type,
    target_object_id,
    'payment_orders' as data_source
FROM payment_tracking_events

UNION ALL

-- 来自会员数据的事件
SELECT 
    event_id,
    user_id,
    event_name,
    event_category,
    event_timestamp,
    event_properties,
    NULL as session_id,
    NULL as page_name,
    '{}'::jsonb as device_info,
    NULL as target_object_type,
    NULL as target_object_id,
    'user_memberships' as data_source
FROM membership_tracking_events;
```

### 4.2 用户行为汇总表

#### 实时用户行为摘要
```sql
-- 用户行为汇总表（实时更新）
CREATE TABLE user_behavior_summary (
    -- 主键
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- 基础统计
    total_events INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    total_pages_viewed INTEGER DEFAULT 0,
    total_interactions INTEGER DEFAULT 0,
    
    -- 时间统计
    first_event_at TIMESTAMPTZ,
    last_event_at TIMESTAMPTZ,
    total_time_spent_seconds INTEGER DEFAULT 0,
    avg_session_duration DECIMAL(10,2) DEFAULT 0,
    
    -- 业务统计
    total_payments DECIMAL(12,2) DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    membership_level VARCHAR(50) DEFAULT 'free',
    
    -- 行为特征
    favorite_features TEXT[],
    most_used_pages TEXT[],
    interaction_patterns JSONB DEFAULT '{}',
    
    -- 设备偏好
    primary_device_type VARCHAR(50),
    preferred_network_type VARCHAR(20),
    
    -- 更新时间
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建更新触发器
CREATE OR REPLACE FUNCTION update_user_behavior_summary()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_behavior_summary (
        user_id, 
        total_events, 
        last_event_at,
        updated_at
    ) VALUES (
        NEW.user_id, 
        1, 
        NEW.event_timestamp,
        NOW()
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_events = user_behavior_summary.total_events + 1,
        last_event_at = GREATEST(user_behavior_summary.last_event_at, NEW.event_timestamp),
        updated_at = NOW();
        
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为app_tracking_events创建触发器
CREATE TRIGGER trigger_update_user_summary_app_events
    AFTER INSERT ON app_tracking_events
    FOR EACH ROW EXECUTE FUNCTION update_user_behavior_summary();
```

---

## 🔄 第五阶段：数据同步和一致性保证

### 5.1 实时数据同步机制

#### Edge Function: 数据同步处理器
```typescript
// supabase/functions/data-sync-processor/index.ts
interface SyncConfig {
    source_table: string;
    target_summary: string;
    sync_fields: string[];
    aggregation_rules: Record<string, string>;
}

const syncConfigs: SyncConfig[] = [
    {
        source_table: 'payment_orders',
        target_summary: 'user_behavior_summary',
        sync_fields: ['total_payments', 'total_orders'],
        aggregation_rules: {
            'total_payments': 'SUM(amount)',
            'total_orders': 'COUNT(*)'
        }
    },
    {
        source_table: 'user_memberships',
        target_summary: 'user_behavior_summary', 
        sync_fields: ['membership_level'],
        aggregation_rules: {
            'membership_level': 'MAX(plan_name)'
        }
    }
];

// 实时同步处理逻辑
export async function syncUserBehaviorData(userId: string) {
    for (const config of syncConfigs) {
        await syncSingleTable(userId, config);
    }
}
```

### 5.2 数据一致性检查

#### 定时一致性校验
```sql
-- 创建数据一致性检查函数
CREATE OR REPLACE FUNCTION check_data_consistency()
RETURNS TABLE (
    check_name TEXT,
    inconsistency_count BIGINT,
    details JSONB
) AS $$
BEGIN
    -- 检查用户行为汇总与实际事件数据的一致性
    RETURN QUERY
    SELECT 
        'user_event_count_consistency'::TEXT,
        COUNT(*)::BIGINT,
        json_agg(json_build_object(
            'user_id', s.user_id,
            'summary_count', s.total_events,
            'actual_count', e.actual_count
        ))::JSONB
    FROM user_behavior_summary s
    LEFT JOIN (
        SELECT 
            user_id, 
            COUNT(*) as actual_count 
        FROM unified_tracking_events 
        GROUP BY user_id
    ) e ON s.user_id = e.user_id
    WHERE s.total_events != COALESCE(e.actual_count, 0);
    
    -- 检查支付数据一致性
    RETURN QUERY
    SELECT 
        'payment_consistency'::TEXT,
        COUNT(*)::BIGINT,
        json_agg(json_build_object(
            'user_id', s.user_id,
            'summary_amount', s.total_payments,
            'actual_amount', p.actual_amount
        ))::JSONB
    FROM user_behavior_summary s
    LEFT JOIN (
        SELECT 
            user_id, 
            SUM(amount) as actual_amount 
        FROM payment_orders 
        WHERE status = 'completed'
        GROUP BY user_id
    ) p ON s.user_id = p.user_id
    WHERE ABS(s.total_payments - COALESCE(p.actual_amount, 0)) > 0.01;
END;
$$ LANGUAGE plpgsql;
```

---

## 🛡️ 安全与权限集成

### 6.1 RLS策略兼容

#### 继承现有权限体系
```sql
-- 为新建表设置RLS策略，与现有表保持一致
ALTER TABLE app_tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_summary ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的数据
CREATE POLICY "Users can view own tracking events" ON app_tracking_events
    FOR ALL USING (auth.uid()::uuid = user_id);

CREATE POLICY "Users can view own behavior summary" ON user_behavior_summary
    FOR ALL USING (auth.uid()::uuid = user_id);

-- 管理员可以查看所有数据
CREATE POLICY "Admins can view all tracking data" ON app_tracking_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users 
            WHERE user_id = auth.uid()::uuid 
            AND is_active = true
        )
    );
```

### 6.2 API权限继承

#### 利用现有认证体系
```typescript
// 埋点API使用现有的Supabase认证
const supabaseClient = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    {
        auth: {
            // 继承现有的认证配置
            persistSession: true,
            autoRefreshToken: true,
        }
    }
);

// API调用自动继承用户权限
async function trackEvent(eventData: TrackingEvent) {
    // RLS策略自动确保用户只能写入自己的数据
    const { data, error } = await supabaseClient
        .from('app_tracking_events')
        .insert({
            ...eventData,
            user_id: (await supabaseClient.auth.getUser()).data.user?.id
        });
    
    return { data, error };
}
```

---

## 📈 性能优化与监控

### 7.1 查询性能优化

#### 智能索引策略
```sql
-- 基于查询模式的复合索引
CREATE INDEX CONCURRENTLY idx_app_tracking_complex_queries
    ON app_tracking_events (user_id, event_category, event_timestamp DESC)
    WHERE event_timestamp >= NOW() - INTERVAL '30 days';

-- 热数据分离索引
CREATE INDEX CONCURRENTLY idx_app_tracking_hot_data
    ON app_tracking_events (event_timestamp DESC, event_name)
    WHERE event_timestamp >= NOW() - INTERVAL '7 days';
```

### 7.2 性能监控集成

#### 利用现有监控体系
```sql
-- 创建性能监控视图
CREATE VIEW tracking_performance_metrics AS
SELECT 
    'app_tracking_events' as table_name,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 day') as daily_inserts,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour') as hourly_inserts,
    AVG(EXTRACT(EPOCH FROM (NOW() - created_at))) as avg_age_seconds
FROM app_tracking_events
UNION ALL
SELECT 
    'interaction_logs' as table_name,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 day') as daily_inserts,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour') as hourly_inserts,
    AVG(EXTRACT(EPOCH FROM (NOW() - created_at))) as avg_age_seconds
FROM interaction_logs;
```

---

## 🎯 集成实施计划

### Phase 1: 基础扩展 (第1-2周)
| 任务 | 描述 | 预计工时 | 风险评级 |
|------|------|----------|----------|
| 扩展interaction_logs | 添加埋点字段、索引 | 1天 | 🟢 低风险 |
| 创建兼容性视图 | 确保现有功能不受影响 | 0.5天 | 🟢 低风险 |
| 基础埋点测试 | 验证扩展字段功能 | 1天 | 🟢 低风险 |

### Phase 2: 专门表建设 (第3-4周) 
| 任务 | 描述 | 预计工时 | 风险评级 |
|------|------|----------|----------|
| 创建app_tracking_events | 新建分区表和索引 | 2天 | 🟡 中风险 |
| 数据同步机制 | Edge Functions开发 | 2天 | 🟡 中风险 |
| 统一视图创建 | 多数据源合并视图 | 1天 | 🟢 低风险 |

### Phase 3: 业务集成 (第5周)
| 任务 | 描述 | 预计工时 | 风险评级 |
|------|------|----------|----------|
| 支付数据集成 | payment_orders视图 | 1天 | 🟢 低风险 |
| 会员数据集成 | user_memberships视图 | 1天 | 🟢 低风险 |
| 行为汇总表 | 实时汇总和触发器 | 2天 | 🟡 中风险 |

### Phase 4: 完善优化 (第6周)
| 任务 | 描述 | 预计工时 | 风险评级 |
|------|------|----------|----------|
| 一致性检查 | 数据校验和修复机制 | 1天 | 🟢 低风险 |
| 性能调优 | 索引和查询优化 | 2天 | 🟢 低风险 |
| 监控告警 | 集成现有监控体系 | 1天 | 🟢 低风险 |

---

## 🎉 集成方案总结

### 核心优势
✅ **零中断集成** - 现有功能完全不受影响  
✅ **数据权威性** - 充分利用现有权威数据源  
✅ **性能优化** - 分层架构确保查询性能  
✅ **安全继承** - 自动继承现有权限和安全策略  
✅ **监控集成** - 无缝集成现有监控和告警体系  

### 立即可用的功能
- ✅ 用户交互埋点 (基于扩展的interaction_logs)
- ✅ 支付转化分析 (基于payment_orders)
- ✅ 会员行为分析 (基于user_memberships)  
- ✅ 社交行为分析 (基于likes, comments)

### 渐进增强的路径
1. **Phase 1** - 立即获得基础埋点能力
2. **Phase 2** - 专门的高性能事件追踪
3. **Phase 3** - 完整的业务数据整合
4. **Phase 4** - 企业级的监控和优化

这个设计确保了与现有星趣系统的**完美兼容**，同时为未来的数据分析需求提供了**坚实的基础**。