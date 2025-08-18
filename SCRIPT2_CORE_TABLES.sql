-- =============================================
-- 星趣APP数据埋点系统 - 部署步骤2: 核心表创建
-- 创建时间: 2025-01-07
-- 版本: v2.1.0 (拆分版本)
-- 用途: 在Supabase Dashboard SQL Editor中执行
-- =============================================

-- 开始执行提示
DO $$ 
BEGIN
    RAISE NOTICE '🚀 开始执行步骤2: 创建核心表...';
    RAISE NOTICE '📅 执行时间: %', NOW();
    RAISE NOTICE '⚠️  将创建新表，不会影响现有数据';
END $$;

-- =============================================
-- 创建高频事件表（解决分区主键问题）
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '📋 创建app_tracking_events高频事件表...';
END $$;

-- 创建非分区版本的事件表（避免分区主键复杂性）
CREATE TABLE IF NOT EXISTS app_tracking_events (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255) NOT NULL,
    
    event_name VARCHAR(100) NOT NULL,
    event_category VARCHAR(50) DEFAULT 'general',
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    event_properties JSONB DEFAULT '{}',
    
    page_name VARCHAR(100),
    page_path VARCHAR(255),
    page_title VARCHAR(255),
    referrer_page VARCHAR(255),
    
    device_info JSONB DEFAULT '{}',
    network_info JSONB DEFAULT '{}',
    location_info JSONB DEFAULT '{}',
    channel_attribution JSONB DEFAULT '{}',
    
    page_load_time INTEGER,
    network_latency INTEGER,
    
    story_id UUID,
    character_id UUID,
    target_object_type VARCHAR(50),
    target_object_id UUID,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    event_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- 使用复合主键，包含分区键（如果后续需要分区）
    CONSTRAINT pk_app_tracking_events PRIMARY KEY (id, event_date)
);

-- 创建触发器来自动更新event_date字段
CREATE OR REPLACE FUNCTION update_event_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW.event_date := NEW.event_timestamp::DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_event_date ON app_tracking_events;
CREATE TRIGGER trigger_update_event_date
    BEFORE INSERT OR UPDATE ON app_tracking_events
    FOR EACH ROW EXECUTE FUNCTION update_event_date();

-- 创建高性能索引
CREATE INDEX IF NOT EXISTS idx_app_tracking_events_user_time 
    ON app_tracking_events (user_id, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_app_tracking_events_name_time 
    ON app_tracking_events (event_name, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_app_tracking_events_session 
    ON app_tracking_events (session_id);
CREATE INDEX IF NOT EXISTS idx_app_tracking_events_properties_gin 
    ON app_tracking_events USING GIN (event_properties);
CREATE INDEX IF NOT EXISTS idx_app_tracking_events_date 
    ON app_tracking_events (event_date);
CREATE INDEX IF NOT EXISTS idx_app_tracking_events_id 
    ON app_tracking_events (id);

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建app_tracking_events表';
    RAISE NOTICE '  ✓ 创建性能优化索引';
END $$;

-- =============================================
-- 创建用户行为汇总表
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '📋 创建user_behavior_summary汇总表...';
END $$;

CREATE TABLE IF NOT EXISTS user_behavior_summary (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- 基础统计
    total_events INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    total_page_views INTEGER DEFAULT 0,
    total_interactions INTEGER DEFAULT 0,
    
    -- 时间统计  
    first_event_at TIMESTAMPTZ,
    last_event_at TIMESTAMPTZ,
    total_time_spent_seconds INTEGER DEFAULT 0,
    avg_session_duration_seconds DECIMAL(10,2) DEFAULT 0,
    
    -- 业务统计（从现有表同步）
    total_payment_amount DECIMAL(12,2) DEFAULT 0,
    total_payment_orders INTEGER DEFAULT 0,
    current_membership_level VARCHAR(50) DEFAULT 'free',
    
    -- 社交统计（从现有表同步）
    total_likes_given INTEGER DEFAULT 0,
    total_comments_made INTEGER DEFAULT 0,
    total_characters_followed INTEGER DEFAULT 0,
    
    -- 行为特征（JSONB存储复杂分析）
    favorite_features JSONB DEFAULT '[]',
    most_visited_pages JSONB DEFAULT '[]',
    interaction_patterns JSONB DEFAULT '{}',
    
    -- 设备偏好
    primary_device_type VARCHAR(50),
    preferred_platform VARCHAR(20),
    
    -- 用户分层
    user_segment VARCHAR(50) DEFAULT 'new_user',
    lifecycle_stage VARCHAR(20) DEFAULT 'new',
    ltv_score DECIMAL(8,2) DEFAULT 0,
    
    -- 时间戳
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建汇总表索引
CREATE INDEX IF NOT EXISTS idx_user_behavior_summary_segment 
    ON user_behavior_summary (user_segment);
CREATE INDEX IF NOT EXISTS idx_user_behavior_summary_lifecycle 
    ON user_behavior_summary (lifecycle_stage);
CREATE INDEX IF NOT EXISTS idx_user_behavior_summary_last_active 
    ON user_behavior_summary (last_event_at DESC);

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建user_behavior_summary表';
    RAISE NOTICE '  ✓ 创建汇总表索引';
END $$;

-- =============================================
-- 添加表注释
-- =============================================

COMMENT ON TABLE app_tracking_events IS '应用事件追踪表 - 高频系统事件存储，优化查询性能';
COMMENT ON TABLE user_behavior_summary IS '用户行为汇总表 - 实时维护用户行为统计';

COMMENT ON COLUMN app_tracking_events.event_date IS '事件日期 - 由触发器自动维护，用于分区和时间范围查询';
COMMENT ON COLUMN app_tracking_events.event_properties IS 'JSONB格式的事件属性 - 支持灵活的事件数据存储';

-- =============================================
-- 完成检查
-- =============================================

DO $$ 
DECLARE
    tables_count INTEGER;
BEGIN
    -- 统计创建的表
    SELECT COUNT(*) INTO tables_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('app_tracking_events', 'user_behavior_summary');
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 步骤2完成! 成功创建%个核心表', tables_count;
    RAISE NOTICE '✅ app_tracking_events: 高频事件存储表';
    RAISE NOTICE '✅ user_behavior_summary: 用户行为汇总表';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 下一步：请执行 SCRIPT3_INTEGRATION_VIEWS.sql';
END $$;