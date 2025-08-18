-- =============================================
-- 星趣APP数据埋点分析系统 - 数据库模型
-- 创建时间: 2025-01-07
-- 版本: v1.0.0
-- 说明: 支持实时数据看板和运营分析的完整埋点体系
-- =============================================

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================
-- 1. 核心埋点数据表
-- =============================================

-- 用户事件表 - 存储所有用户行为事件
CREATE TABLE IF NOT EXISTS user_events (
    -- 主键和基础信息
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id VARCHAR(255) NOT NULL,
    
    -- 事件基本信息
    event_name VARCHAR(100) NOT NULL,
    event_category VARCHAR(50), -- 事件分类：lifecycle, navigation, interaction, business等
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 事件属性 (JSONB for flexible properties)
    properties JSONB DEFAULT '{}',
    
    -- 设备和环境信息
    device_info JSONB DEFAULT '{}', -- 设备型号、OS版本、APP版本等
    network_info JSONB DEFAULT '{}', -- 网络类型、运营商等
    
    -- 位置和渠道信息
    location_info JSONB DEFAULT '{}', -- 地理位置、IP等
    attribution_info JSONB DEFAULT '{}', -- 来源渠道、utm参数等
    
    -- 业务关联字段 (与现有业务表关联)
    story_id UUID REFERENCES stories(id) ON DELETE SET NULL,
    target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- 被操作的用户ID
    
    -- 性能和技术字段
    page_load_time INTEGER, -- 页面加载时间(ms)
    network_latency INTEGER, -- 网络延迟(ms)
    
    -- 索引和分区字段
    event_date DATE GENERATED ALWAYS AS (event_timestamp::DATE) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (event_date);

-- 创建分区表 (按月分区，提升查询性能)
CREATE TABLE user_events_202501 PARTITION OF user_events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE user_events_202502 PARTITION OF user_events
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE user_events_202503 PARTITION OF user_events
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- 用户会话表 - 会话级别的数据聚合
CREATE TABLE IF NOT EXISTS user_sessions (
    -- 主键
    id VARCHAR(255) PRIMARY KEY, -- session_id作为主键
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- 会话时间信息
    session_start TIMESTAMPTZ NOT NULL,
    session_end TIMESTAMPTZ,
    session_duration INTEGER, -- 会话时长(秒)
    
    -- 会话统计
    page_views INTEGER DEFAULT 0,
    events_count INTEGER DEFAULT 0,
    interactions_count INTEGER DEFAULT 0,
    
    -- 设备和环境
    device_info JSONB DEFAULT '{}',
    app_version VARCHAR(50),
    platform VARCHAR(20), -- ios, android, web
    
    -- 业务指标
    is_first_session BOOLEAN DEFAULT FALSE,
    conversion_events JSONB DEFAULT '[]', -- 转化事件列表
    
    -- 地理和渠道
    location_info JSONB DEFAULT '{}',
    attribution_info JSONB DEFAULT '{}',
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户属性表 - 用户画像和分层信息
CREATE TABLE IF NOT EXISTS user_attributes (
    -- 主键
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- 用户生命周期
    lifecycle_stage VARCHAR(20) DEFAULT 'new', -- new, active, dormant, churned
    user_segment VARCHAR(50), -- 用户分层标签
    ltv_score DECIMAL(10,2) DEFAULT 0, -- 生命周期价值评分
    
    -- 行为统计
    total_sessions INTEGER DEFAULT 0,
    total_events INTEGER DEFAULT 0,
    total_time_spent INTEGER DEFAULT 0, -- 总使用时长(秒)
    avg_session_duration DECIMAL(8,2) DEFAULT 0,
    
    -- 业务指标
    stories_created INTEGER DEFAULT 0,
    stories_liked INTEGER DEFAULT 0,
    comments_made INTEGER DEFAULT 0,
    follows_count INTEGER DEFAULT 0,
    
    -- 商业化指标
    is_paying_user BOOLEAN DEFAULT FALSE,
    total_paid_amount DECIMAL(10,2) DEFAULT 0,
    subscription_level VARCHAR(20) DEFAULT 'free', -- free, basic, premium, vip
    first_payment_date TIMESTAMPTZ,
    last_payment_date TIMESTAMPTZ,
    
    -- engagement指标
    last_active_date TIMESTAMPTZ,
    days_since_registration INTEGER,
    retention_day_7 BOOLEAN DEFAULT FALSE,
    retention_day_30 BOOLEAN DEFAULT FALSE,
    
    -- 自定义属性
    custom_properties JSONB DEFAULT '{}',
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 2. 数据分析和看板表
-- =============================================

-- 日常指标汇总表 (T+1数据)
CREATE TABLE IF NOT EXISTS daily_metrics (
    -- 主键
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_date DATE NOT NULL,
    metric_type VARCHAR(50) NOT NULL, -- dau, revenue, retention etc.
    
    -- 分组维度
    segment_type VARCHAR(50), -- overall, channel, user_segment etc.
    segment_value VARCHAR(100), -- 分组的具体值
    
    -- 指标值
    metric_value DECIMAL(12,2) NOT NULL,
    metric_count INTEGER DEFAULT 0,
    
    -- 对比数据
    previous_day_value DECIMAL(12,2),
    previous_week_value DECIMAL(12,2),
    week_over_week_change DECIMAL(5,2), -- 周同比变化率
    day_over_day_change DECIMAL(5,2), -- 日环比变化率
    
    -- 额外数据
    metadata JSONB DEFAULT '{}',
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 唯一约束
    UNIQUE(metric_date, metric_type, segment_type, segment_value)
);

-- 实时指标表 (实时数据)
CREATE TABLE IF NOT EXISTS realtime_metrics (
    -- 主键
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_type VARCHAR(50) NOT NULL, -- revenue, active_users, conversion etc.
    
    -- 时间窗口
    time_window VARCHAR(20) NOT NULL, -- 1min, 5min, 1hour, 1day
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    
    -- 指标值
    metric_value DECIMAL(12,2) NOT NULL,
    metric_count INTEGER DEFAULT 0,
    
    -- 分组维度
    dimensions JSONB DEFAULT '{}', -- 灵活的维度存储
    
    -- 聚合数据
    aggregation_data JSONB DEFAULT '{}',
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 索引优化
    UNIQUE(metric_type, time_window, window_start, dimensions)
);

-- AARRR漏斗分析表
CREATE TABLE IF NOT EXISTS funnel_analysis (
    -- 主键
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    funnel_name VARCHAR(100) NOT NULL, -- AARRR, registration, payment etc.
    analysis_date DATE NOT NULL,
    
    -- 漏斗步骤数据
    step_name VARCHAR(50) NOT NULL, -- acquisition, activation, retention, revenue, referral
    step_order INTEGER NOT NULL,
    
    -- 指标数据
    step_users INTEGER NOT NULL,
    step_rate DECIMAL(5,2), -- 转化率
    conversion_from_previous DECIMAL(5,2), -- 从上一步的转化率
    
    -- 分组维度
    segment_type VARCHAR(50) DEFAULT 'overall',
    segment_value VARCHAR(100) DEFAULT 'all',
    
    -- 额外数据
    metadata JSONB DEFAULT '{}',
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 唯一约束
    UNIQUE(funnel_name, analysis_date, step_name, segment_type, segment_value)
);

-- 用户分层结果表
CREATE TABLE IF NOT EXISTS user_segments (
    -- 主键
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- 分层信息
    segment_name VARCHAR(50) NOT NULL, -- high_value, churning, new_user etc.
    segment_type VARCHAR(30) NOT NULL, -- behavioral, value, lifecycle etc.
    segment_score DECIMAL(8,4), -- 分层评分
    
    -- 分层依据
    criteria_data JSONB DEFAULT '{}', -- 分层的具体指标和阈值
    
    -- 有效期
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 索引
    UNIQUE(user_id, segment_type, valid_from)
);

-- =============================================
-- 3. 索引优化
-- =============================================

-- user_events表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_events_user_id_timestamp 
    ON user_events (user_id, event_timestamp DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_events_event_name_timestamp 
    ON user_events (event_name, event_timestamp DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_events_session_id 
    ON user_events (session_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_events_category_timestamp 
    ON user_events (event_category, event_timestamp DESC);
-- JSONB属性索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_events_properties_gin 
    ON user_events USING GIN (properties);

-- user_sessions表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_user_id_start 
    ON user_sessions (user_id, session_start DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_start_time 
    ON user_sessions (session_start DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_platform 
    ON user_sessions (platform);

-- user_attributes表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_attributes_lifecycle_stage 
    ON user_attributes (lifecycle_stage);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_attributes_segment 
    ON user_attributes (user_segment);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_attributes_paying_user 
    ON user_attributes (is_paying_user);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_attributes_last_active 
    ON user_attributes (last_active_date DESC);

-- daily_metrics表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_metrics_date_type 
    ON daily_metrics (metric_date DESC, metric_type);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_metrics_segment 
    ON daily_metrics (segment_type, segment_value);

-- realtime_metrics表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_realtime_metrics_type_window 
    ON realtime_metrics (metric_type, time_window, window_start DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_realtime_metrics_created 
    ON realtime_metrics (created_at DESC);

-- funnel_analysis表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_funnel_analysis_date_name 
    ON funnel_analysis (analysis_date DESC, funnel_name);

-- user_segments表索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_segments_user_active 
    ON user_segments (user_id, is_active, valid_from DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_segments_type_active 
    ON user_segments (segment_type, is_active);

-- =============================================
-- 4. 视图和物化视图
-- =============================================

-- 用户概况视图 - 整合用户基础信息和分析属性
CREATE OR REPLACE VIEW user_overview AS
SELECT 
    u.id,
    u.email,
    u.created_at as registration_date,
    ua.lifecycle_stage,
    ua.user_segment,
    ua.ltv_score,
    ua.total_sessions,
    ua.total_time_spent,
    ua.is_paying_user,
    ua.subscription_level,
    ua.last_active_date,
    ua.days_since_registration,
    -- 最近会话信息
    (
        SELECT json_build_object(
            'session_id', us.id,
            'session_start', us.session_start,
            'session_duration', us.session_duration,
            'page_views', us.page_views,
            'platform', us.platform
        )
        FROM user_sessions us 
        WHERE us.user_id = u.id 
        ORDER BY us.session_start DESC 
        LIMIT 1
    ) as last_session_info
FROM auth.users u
LEFT JOIN user_attributes ua ON u.id = ua.user_id;

-- 今日实时指标物化视图
CREATE MATERIALIZED VIEW IF NOT EXISTS today_realtime_metrics AS
SELECT 
    metric_type,
    time_window,
    AVG(metric_value) as avg_value,
    SUM(metric_count) as total_count,
    MAX(window_end) as latest_update,
    COUNT(*) as data_points
FROM realtime_metrics 
WHERE DATE(window_start) = CURRENT_DATE
GROUP BY metric_type, time_window;

-- 创建刷新今日实时指标的函数
CREATE OR REPLACE FUNCTION refresh_today_realtime_metrics()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW today_realtime_metrics;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 5. 触发器和自动化
-- =============================================

-- 自动更新updated_at字段的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表添加updated_at自动更新触发器
CREATE TRIGGER update_user_sessions_updated_at 
    BEFORE UPDATE ON user_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_attributes_updated_at 
    BEFORE UPDATE ON user_attributes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_metrics_updated_at 
    BEFORE UPDATE ON daily_metrics 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 用户事件写入后自动更新用户属性的函数
CREATE OR REPLACE FUNCTION update_user_attributes_on_event()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新用户的最后活跃时间和事件计数
    INSERT INTO user_attributes (
        user_id, 
        total_events, 
        last_active_date,
        updated_at
    ) VALUES (
        NEW.user_id, 
        1, 
        NEW.event_timestamp,
        NOW()
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_events = user_attributes.total_events + 1,
        last_active_date = GREATEST(user_attributes.last_active_date, NEW.event_timestamp),
        updated_at = NOW();
        
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建事件写入触发器
CREATE TRIGGER trigger_update_user_attributes_on_event
    AFTER INSERT ON user_events
    FOR EACH ROW EXECUTE FUNCTION update_user_attributes_on_event();

-- =============================================
-- 6. 数据保留和清理策略
-- =============================================

-- 创建数据清理函数
CREATE OR REPLACE FUNCTION cleanup_old_analytics_data()
RETURNS void AS $$
BEGIN
    -- 删除90天前的原始事件数据
    DELETE FROM user_events 
    WHERE event_timestamp < NOW() - INTERVAL '90 days';
    
    -- 删除30天前的实时指标数据
    DELETE FROM realtime_metrics 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- 删除过期的用户分层数据
    UPDATE user_segments 
    SET is_active = FALSE 
    WHERE valid_until < NOW() AND is_active = TRUE;
    
    -- 记录清理日志
    INSERT INTO system_logs (log_level, message, created_at) 
    VALUES ('INFO', 'Analytics data cleanup completed', NOW());
    
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 7. 性能优化配置
-- =============================================

-- 配置表的存储参数
ALTER TABLE user_events SET (
    fillfactor = 90,  -- 为后续更新预留空间
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE realtime_metrics SET (
    fillfactor = 95,  -- 主要是插入操作
    autovacuum_vacuum_scale_factor = 0.05
);

-- =============================================
-- 8. 注释说明
-- =============================================

COMMENT ON TABLE user_events IS '用户行为事件表 - 存储所有用户行为的原始数据，按月分区';
COMMENT ON TABLE user_sessions IS '用户会话表 - 聚合会话级别的统计数据';
COMMENT ON TABLE user_attributes IS '用户属性表 - 用户画像和生命周期管理';
COMMENT ON TABLE daily_metrics IS '日常指标表 - T+1运营数据汇总';
COMMENT ON TABLE realtime_metrics IS '实时指标表 - 商业化实时数据';
COMMENT ON TABLE funnel_analysis IS 'AARRR漏斗分析表 - 转化漏斗数据';
COMMENT ON TABLE user_segments IS '用户分层表 - 用户分群结果存储';

COMMENT ON COLUMN user_events.properties IS '事件属性的JSONB存储，支持灵活的事件参数';
COMMENT ON COLUMN user_events.session_id IS '会话标识，用于关联同一会话的多个事件';
COMMENT ON COLUMN user_attributes.ltv_score IS '用户生命周期价值评分，用于用户价值分层';
COMMENT ON COLUMN realtime_metrics.time_window IS '时间窗口类型：1min/5min/1hour/1day';

-- 执行完成提示
DO $$ 
BEGIN 
    RAISE NOTICE '星趣APP数据埋点分析系统数据库模型创建完成！';
    RAISE NOTICE '包含：7个核心表、多个索引、视图、触发器和优化配置';
    RAISE NOTICE '支持：实时数据处理、T+1指标计算、AARRR漏斗分析、用户分层';
END $$;