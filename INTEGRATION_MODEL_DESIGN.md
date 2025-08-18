# 星趣APP数据埋点系统 - 集成化数据库模型设计

> 📅 **设计时间**: 2025-01-07  
> 🎯 **版本**: v2.0.0 (集成版)  
> 🏗️ **设计原则**: 基于现有表扩展，避免重复，渐进式增强

---

## 🎯 设计总览

### 核心理念
**"智能集成，渐进增强"** - 在不影响现有系统的前提下，通过扩展现有表和适度新建专门表，构建完整的数据埋点分析体系。

### 架构层次
```
📊 分析应用层
    ├── 统一查询接口 (unified_tracking_events)
    ├── 实时指标计算
    └── 数据看板API
              ↓
🔄 数据处理层  
    ├── 自动汇总更新 (triggers)
    ├── 数据一致性检查
    └── 实时同步机制
              ↓
💾 数据存储层
    ├── 扩展表: interaction_logs (enhanced)
    ├── 专门表: app_tracking_events (partitioned)
    ├── 汇总表: user_behavior_summary
    └── 集成视图: payment/membership/social events
              ↓
🏛️ 现有业务层
    ├── payment_orders (利用)
    ├── user_memberships (利用)
    ├── likes, comments (利用)
    └── users, ai_characters (关联)
```

---

## 📋 数据库模型详细设计

### Phase 1: 现有表安全扩展

#### 1.1 interaction_logs 表扩展
**扩展策略**: 零影响添加字段，保持向后兼容

```sql
-- 新增埋点专用字段
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS session_id VARCHAR(255);
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS event_properties JSONB DEFAULT '{}';
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS target_object_type VARCHAR(50);
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS target_object_id UUID;
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS page_context JSONB DEFAULT '{}';
ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}';
```

**兼容性保证**:
```sql
-- 创建向后兼容视图
CREATE VIEW interaction_logs_legacy AS
SELECT id, user_id, interaction_type, created_at FROM interaction_logs;
```

**立即支持的事件**:
| 事件类型 | interaction_type | event_properties 示例 |
|----------|------------------|----------------------|
| 社交点赞 | 'like' | `{"target_type": "story", "target_id": "uuid"}` |
| 用户关注 | 'follow' | `{"target_type": "character", "character_id": "uuid"}` |
| AI对话 | 'ai_chat' | `{"character_id": "uuid", "message_count": 5}` |
| 页面交互 | 'page_action' | `{"action": "scroll", "page": "home_selection"}` |

### Phase 2: 专门高频事件表

#### 2.1 app_tracking_events 表设计
**设计特点**: 分区表，专门处理高频系统事件

```sql
CREATE TABLE app_tracking_events (
    -- 核心标识
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255) NOT NULL,
    
    -- 事件信息
    event_name VARCHAR(100) NOT NULL,          -- 如: page_view, app_launch
    event_category VARCHAR(50) DEFAULT 'general', -- 如: navigation, lifecycle
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 灵活属性存储
    event_properties JSONB DEFAULT '{}',       -- 事件自定义属性
    
    -- 页面信息
    page_name VARCHAR(100),                    -- 页面名称
    page_path VARCHAR(255),                    -- 页面路径
    referrer_page VARCHAR(255),                -- 来源页面
    
    -- 环境信息
    device_info JSONB DEFAULT '{}',            -- 设备型号、OS、APP版本
    network_info JSONB DEFAULT '{}',           -- 网络类型、运营商
    location_info JSONB DEFAULT '{}',          -- 地理位置、IP
    channel_attribution JSONB DEFAULT '{}',   -- 来源渠道、UTM参数
    
    -- 性能指标
    page_load_time INTEGER,                   -- 页面加载时间(ms)
    network_latency INTEGER,                  -- 网络延迟(ms)
    
    -- 业务关联
    story_id UUID,                           -- 相关故事ID
    character_id UUID,                       -- 相关AI角色ID
    target_object_type VARCHAR(50),          -- 通用目标类型
    target_object_id UUID,                   -- 通用目标ID
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    event_date DATE GENERATED ALWAYS AS (event_timestamp::DATE) STORED
) PARTITION BY RANGE (event_date);
```

**分区设计**: 按月分区，优化时间序列查询
```sql
-- 2025年各月分区
CREATE TABLE app_tracking_events_202501 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
-- ... 后续月份分区
```

**性能索引**:
```sql
-- 高频查询优化
CREATE INDEX idx_app_tracking_events_user_time ON app_tracking_events (user_id, event_timestamp DESC);
CREATE INDEX idx_app_tracking_events_name_time ON app_tracking_events (event_name, event_timestamp DESC);

-- JSONB属性查询优化  
CREATE INDEX idx_app_tracking_events_properties_gin ON app_tracking_events USING GIN (event_properties);

-- 热数据查询优化
CREATE INDEX idx_app_tracking_events_recent_hot ON app_tracking_events (event_timestamp DESC, event_name)
    WHERE event_timestamp >= NOW() - INTERVAL '7 days';
```

#### 2.2 支持的专门事件类型

| PRD需求事件 | event_name | event_category | 关键属性 |
|------------|------------|----------------|----------|
| **应用启动** | 'app_launch' | 'lifecycle' | launch_type, is_cold_start, app_version |
| **页面浏览** | 'page_view' | 'navigation' | page_name, load_time, from_page, duration |
| **应用后台** | 'app_background' | 'lifecycle' | session_duration, pages_visited |
| **搜索查询** | 'search_query' | 'discovery' | query_text, results_count, filters |
| **内容浏览** | 'content_view' | 'engagement' | content_type, content_id, view_duration |

### Phase 3: 用户行为汇总表

#### 3.1 user_behavior_summary 表设计
**用途**: 实时维护用户行为统计，支持快速用户画像查询

```sql
CREATE TABLE user_behavior_summary (
    -- 主键
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- 基础统计
    total_events INTEGER DEFAULT 0,               -- 总事件数
    total_sessions INTEGER DEFAULT 0,             -- 总会话数
    total_page_views INTEGER DEFAULT 0,           -- 总页面浏览数
    total_interactions INTEGER DEFAULT 0,         -- 总交互数
    
    -- 时间统计  
    first_event_at TIMESTAMPTZ,                  -- 首次活动时间
    last_event_at TIMESTAMPTZ,                   -- 最后活动时间
    total_time_spent_seconds INTEGER DEFAULT 0,  -- 总使用时长
    avg_session_duration_seconds DECIMAL(10,2) DEFAULT 0, -- 平均会话时长
    
    -- 业务统计（从现有表同步）
    total_payment_amount DECIMAL(12,2) DEFAULT 0, -- 总支付金额
    total_payment_orders INTEGER DEFAULT 0,       -- 总订单数
    current_membership_level VARCHAR(50) DEFAULT 'free', -- 当前会员等级
    
    -- 社交统计（从现有表同步）
    total_likes_given INTEGER DEFAULT 0,          -- 总点赞数
    total_comments_made INTEGER DEFAULT 0,        -- 总评论数
    total_characters_followed INTEGER DEFAULT 0,  -- 总关注角色数
    
    -- 行为特征（JSONB存储复杂分析）
    favorite_features JSONB DEFAULT '[]',         -- 最爱功能列表
    most_visited_pages JSONB DEFAULT '[]',        -- 常访问页面
    interaction_patterns JSONB DEFAULT '{}',      -- 交互模式分析
    
    -- 设备偏好
    primary_device_type VARCHAR(50),              -- 主要设备类型
    preferred_platform VARCHAR(20),               -- 偏好平台 (iOS/Android/Web)
    
    -- 用户分层
    user_segment VARCHAR(50) DEFAULT 'new_user',  -- 用户分层标签
    lifecycle_stage VARCHAR(20) DEFAULT 'new',    -- 生命周期阶段
    ltv_score DECIMAL(8,2) DEFAULT 0,            -- 生命周期价值评分
    
    -- 时间戳
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 3.2 自动更新机制
```sql
-- 事件触发自动更新汇总表
CREATE FUNCTION update_user_behavior_summary_from_events() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_behavior_summary (user_id, total_events, first_event_at, last_event_at)
    VALUES (NEW.user_id, 1, NEW.event_timestamp, NEW.event_timestamp)
    ON CONFLICT (user_id) DO UPDATE SET 
        total_events = user_behavior_summary.total_events + 1,
        last_event_at = GREATEST(user_behavior_summary.last_event_at, NEW.event_timestamp),
        total_page_views = CASE WHEN NEW.event_name = 'page_view' 
                          THEN user_behavior_summary.total_page_views + 1 
                          ELSE user_behavior_summary.total_page_views END,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为app_tracking_events添加触发器
CREATE TRIGGER trigger_update_user_summary_from_app_events
    AFTER INSERT ON app_tracking_events
    FOR EACH ROW EXECUTE FUNCTION update_user_behavior_summary_from_events();
```

### Phase 4: 业务数据集成视图

#### 4.1 避免重复存储的集成策略

**设计理念**: 利用现有业务表作为权威数据源，通过视图提供统一的事件格式

##### 支付事件视图
```sql
CREATE VIEW payment_tracking_events AS
SELECT 
    id as event_id,
    user_id,
    'membership_purchase_complete' as event_name,
    'business' as event_category,
    created_at as event_timestamp,
    json_build_object(
        'order_id', id,
        'amount', amount,
        'plan_id', plan_id,
        'payment_provider', payment_provider,
        'order_number', order_number,
        'status', status,
        'currency', 'CNY'
    ) as event_properties,
    plan_id::text as target_object_id,
    'subscription_plan' as target_object_type,
    'payment_orders' as data_source
FROM payment_orders 
WHERE status = 'completed';
```

##### 会员行为事件视图
```sql
CREATE VIEW membership_tracking_events AS
SELECT 
    id as event_id,
    user_id,
    CASE 
        WHEN status = 'active' THEN 'membership_activated'
        WHEN status = 'expired' THEN 'membership_expired'
        WHEN status = 'cancelled' THEN 'membership_cancelled'
        ELSE 'membership_status_changed'
    END as event_name,
    'membership' as event_category,
    COALESCE(updated_at, created_at) as event_timestamp,
    json_build_object(
        'membership_id', id,
        'plan_id', plan_id,
        'status', status,
        'auto_renew', COALESCE(auto_renew, false),
        'expires_at', expires_at
    ) as event_properties,
    -- 其他字段...
FROM user_memberships;
```

##### 社交行为事件视图
```sql
CREATE VIEW social_like_tracking_events AS
SELECT 
    id as event_id,
    user_id,
    'social_like' as event_name,
    'social' as event_category,
    created_at as event_timestamp,
    json_build_object(
        'like_id', id,
        'target_type', target_type,
        'target_id', target_id
    ) as event_properties,
    target_id::text as target_object_id,
    target_type as target_object_type,
    'likes' as data_source
FROM likes;
```

### Phase 5: 统一数据接口

#### 5.1 unified_tracking_events 视图
**功能**: 合并所有数据源，提供统一的埋点事件查询接口

```sql
CREATE VIEW unified_tracking_events AS
-- app_tracking_events 数据
SELECT 
    id::text as event_id,
    user_id, event_name, event_category, event_timestamp,
    event_properties, session_id, page_name, device_info,
    target_object_type, target_object_id::text as target_object_id,
    'app_tracking' as data_source
FROM app_tracking_events

UNION ALL

-- interaction_logs 数据  
SELECT 
    id::text as event_id,
    user_id, interaction_type as event_name, 'interaction' as event_category,
    created_at as event_timestamp, event_properties, session_id,
    (page_context->>'page_name') as page_name, device_info,
    target_object_type, target_object_id::text as target_object_id,
    'interaction_logs' as data_source
FROM interaction_logs

UNION ALL

-- 支付事件数据
SELECT event_id::text, user_id, event_name, event_category, event_timestamp,
       event_properties, NULL as session_id, NULL as page_name, 
       '{}'::jsonb as device_info, target_object_type, target_object_id, data_source
FROM payment_tracking_events

-- ... 其他数据源
;
```

**查询示例**:
```sql
-- 获取用户最近7天的所有行为事件
SELECT * FROM unified_tracking_events 
WHERE user_id = 'specific-user-uuid' 
  AND event_timestamp >= NOW() - INTERVAL '7 days'
ORDER BY event_timestamp DESC;

-- 分析页面浏览行为
SELECT 
    page_name, 
    COUNT(*) as view_count,
    COUNT(DISTINCT user_id) as unique_users,
    AVG((event_properties->>'load_time')::integer) as avg_load_time
FROM unified_tracking_events 
WHERE event_name = 'page_view' 
  AND event_timestamp >= NOW() - INTERVAL '1 day'
GROUP BY page_name
ORDER BY view_count DESC;
```

---

## 🔐 安全策略集成

### RLS策略继承
**原则**: 与现有权限体系保持完全一致

```sql
-- 启用RLS
ALTER TABLE app_tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_summary ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的数据
CREATE POLICY "Users can access own tracking events" ON app_tracking_events
    FOR ALL USING (auth.uid()::uuid = user_id);

-- 管理员可以访问所有数据（如果admin_users表存在）
CREATE POLICY "Admins can access all tracking data" ON app_tracking_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users 
            WHERE user_id = auth.uid()::uuid AND is_active = true
        )
    );
```

---

## ⚡ 性能优化策略

### 存储优化
```sql
-- 针对写入密集的事件表
ALTER TABLE app_tracking_events SET (
    fillfactor = 90,  -- 预留更新空间
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

-- 针对更新频繁的汇总表
ALTER TABLE user_behavior_summary SET (
    fillfactor = 80,  -- 更多更新空间
    autovacuum_vacuum_scale_factor = 0.2
);
```

### 查询优化
1. **分区查询**: 按时间范围自动路由到对应分区
2. **索引策略**: 复合索引覆盖常用查询模式
3. **JSONB优化**: GIN索引支持属性查询
4. **热数据分离**: 近期数据专门索引

---

## 📊 数据质量保证

### 一致性检查
```sql
CREATE FUNCTION check_tracking_data_consistency()
RETURNS TABLE (check_name TEXT, inconsistency_count BIGINT, details TEXT) AS $$
BEGIN
    -- 检查汇总表与实际事件的一致性
    RETURN QUERY
    SELECT 
        'user_event_count_consistency'::TEXT,
        COUNT(*)::BIGINT,
        '用户汇总表与实际事件数不匹配的用户数'::TEXT
    FROM user_behavior_summary s
    LEFT JOIN (
        SELECT user_id, COUNT(*) as actual_count 
        FROM unified_tracking_events 
        WHERE user_id IS NOT NULL GROUP BY user_id
    ) e ON s.user_id = e.user_id
    WHERE s.total_events != COALESCE(e.actual_count, 0);
END;
$$ LANGUAGE plpgsql;
```

---

## 🎉 集成模型核心优势

### ✅ 技术优势
1. **零影响部署** - 现有功能完全不受影响
2. **渐进式增强** - 可分阶段实施，每阶段都有价值  
3. **性能优化** - 分区表、索引策略、查询优化
4. **数据权威性** - 利用现有表避免数据不一致
5. **安全继承** - 自动继承现有权限和安全策略

### ✅ 业务价值
1. **立即可用** - Phase 1完成即可开始埋点
2. **全面覆盖** - 支持PRD中的所有核心事件类型
3. **实时分析** - 自动汇总支持实时用户画像
4. **统一接口** - 一个视图查询所有埋点数据
5. **扩展灵活** - JSONB字段支持任意自定义属性

### ✅ 运维优势  
1. **维护简单** - 复用现有运维流程
2. **监控集成** - 无缝集成现有监控体系
3. **备份恢复** - 遵循现有备份策略
4. **问题排查** - 统一的日志和错误处理

---

## 📋 部署检查清单

### Pre-deployment 检查
- [ ] 确认现有表结构（users, interaction_logs, payment_orders等）
- [ ] 验证现有索引不冲突
- [ ] 检查Supabase扩展可用性
- [ ] 确认RLS策略兼容性

### Deployment 执行
- [ ] 执行DDL脚本 (`20250107_analytics_integration_schema.sql`)
- [ ] 验证分区表创建成功
- [ ] 检查索引创建完成
- [ ] 测试视图查询功能
- [ ] 验证触发器正常工作

### Post-deployment 验证
- [ ] 插入测试事件数据
- [ ] 验证汇总表自动更新  
- [ ] 测试统一视图查询
- [ ] 检查RLS权限控制
- [ ] 运行一致性检查函数

---

**🎯 这个集成化模型设计确保了与现有星趣系统的完美兼容，同时提供了企业级的数据埋点分析能力。**