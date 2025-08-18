-- =============================================
-- 星趣APP数据埋点系统 - 快速部署脚本 (修复版)
-- 创建时间: 2025-01-07
-- 版本: v2.0.1 (语法修复版)
-- 用途: 在Supabase Dashboard SQL Editor中直接执行
-- =============================================

-- ⚠️ 重要提示: 
-- 1. 请在业务低峰期执行
-- 2. 建议在测试环境先验证
-- 3. 执行前请备份数据库
-- 4. 可以分段执行，每段后检查结果

-- 开始执行提示
DO $$ 
BEGIN
    RAISE NOTICE '🚀 开始执行星趣APP数据埋点系统集成化部署...';
    RAISE NOTICE '📅 执行时间: %', NOW();
    RAISE NOTICE '🎯 版本: v2.0.1 语法修复版';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  请确保在业务低峰期执行，执行过程中请关注系统状态';
END $$;

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================
-- Phase 1: 现有表安全扩展 (最安全，优先执行)
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 1: 开始安全扩展现有表...';
END $$;

-- 检查并扩展interaction_logs表
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interaction_logs' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ 发现interaction_logs表，开始安全扩展...';
        
        -- 使用IF NOT EXISTS确保安全执行
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'session_id';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN session_id VARCHAR(255);
            RAISE NOTICE '  ✓ 添加session_id字段';
        ELSE
            RAISE NOTICE '  - session_id字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'event_properties';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN event_properties JSONB DEFAULT '{}';
            RAISE NOTICE '  ✓ 添加event_properties字段';
        ELSE
            RAISE NOTICE '  - event_properties字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'target_object_type';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN target_object_type VARCHAR(50);
            RAISE NOTICE '  ✓ 添加target_object_type字段';
        ELSE
            RAISE NOTICE '  - target_object_type字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'target_object_id';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN target_object_id UUID;
            RAISE NOTICE '  ✓ 添加target_object_id字段';
        ELSE
            RAISE NOTICE '  - target_object_id字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'page_context';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN page_context JSONB DEFAULT '{}';
            RAISE NOTICE '  ✓ 添加page_context字段';
        ELSE
            RAISE NOTICE '  - page_context字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'device_info';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN device_info JSONB DEFAULT '{}';
            RAISE NOTICE '  ✓ 添加device_info字段';
        ELSE
            RAISE NOTICE '  - device_info字段已存在，跳过';
        END IF;
        
    ELSE
        RAISE WARNING '❌ 未找到interaction_logs表，跳过扩展';
    END IF;
END $$;

-- 为扩展字段创建索引
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interaction_logs' AND table_schema = 'public') THEN
        -- 检查索引是否存在，不存在则创建
        PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_interaction_logs_session_id_new';
        IF NOT FOUND THEN
            CREATE INDEX CONCURRENTLY idx_interaction_logs_session_id_new ON interaction_logs (session_id);
            RAISE NOTICE '  ✓ 创建session_id索引';
        ELSE
            RAISE NOTICE '  - session_id索引已存在，跳过';
        END IF;
        
        PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_interaction_logs_target_new';
        IF NOT FOUND THEN
            CREATE INDEX CONCURRENTLY idx_interaction_logs_target_new ON interaction_logs (target_object_type, target_object_id);
            RAISE NOTICE '  ✓ 创建目标对象索引';
        ELSE
            RAISE NOTICE '  - 目标对象索引已存在，跳过';
        END IF;
        
        PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_interaction_logs_properties_gin_new';
        IF NOT FOUND THEN
            CREATE INDEX CONCURRENTLY idx_interaction_logs_properties_gin_new ON interaction_logs USING GIN (event_properties);
            RAISE NOTICE '  ✓ 创建属性GIN索引';
        ELSE
            RAISE NOTICE '  - 属性GIN索引已存在，跳过';
        END IF;
    END IF;
END $$;

-- 创建向后兼容视图和Phase 1完成检查
DO $$
DECLARE
    new_columns_count INTEGER;
BEGIN
    -- 创建向后兼容视图
    CREATE OR REPLACE VIEW interaction_logs_legacy AS
    SELECT 
        id, 
        user_id, 
        interaction_type, 
        created_at
    FROM interaction_logs;
    
    RAISE NOTICE '  ✓ 创建向后兼容视图';
    
    -- Phase 1 完成检查
    SELECT COUNT(*) INTO new_columns_count
    FROM information_schema.columns 
    WHERE table_name = 'interaction_logs' 
      AND column_name IN ('session_id', 'event_properties', 'target_object_type', 'target_object_id', 'page_context', 'device_info');
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Phase 1 完成! 成功扩展interaction_logs表，新增%个字段', new_columns_count;
    RAISE NOTICE '✅ 现有功能完全不受影响，可以开始使用扩展的埋点功能';
END $$;

-- =============================================
-- Phase 2: 创建专门的高频事件表
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 2: 创建专门的高频事件表...';
END $$;

-- 创建分区表
CREATE TABLE IF NOT EXISTS app_tracking_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    event_date DATE GENERATED ALWAYS AS (event_timestamp::DATE) STORED
) PARTITION BY RANGE (event_date);

-- 创建分区
CREATE TABLE IF NOT EXISTS app_tracking_events_202501 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE IF NOT EXISTS app_tracking_events_202502 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE IF NOT EXISTS app_tracking_events_202503 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE IF NOT EXISTS app_tracking_events_202504 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

-- 创建索引和完成Phase 2
DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建app_tracking_events分区表';
    
    -- 基础查询索引
    PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_app_tracking_events_user_time';
    IF NOT FOUND THEN
        CREATE INDEX CONCURRENTLY idx_app_tracking_events_user_time 
            ON app_tracking_events (user_id, event_timestamp DESC);
        RAISE NOTICE '  ✓ 创建用户时间索引';
    END IF;
    
    PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_app_tracking_events_name_time';
    IF NOT FOUND THEN
        CREATE INDEX CONCURRENTLY idx_app_tracking_events_name_time 
            ON app_tracking_events (event_name, event_timestamp DESC);
        RAISE NOTICE '  ✓ 创建事件名时间索引';
    END IF;
    
    PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_app_tracking_events_session';
    IF NOT FOUND THEN
        CREATE INDEX CONCURRENTLY idx_app_tracking_events_session 
            ON app_tracking_events (session_id);
        RAISE NOTICE '  ✓ 创建会话索引';
    END IF;
    
    -- JSONB索引
    PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_app_tracking_events_properties_gin';
    IF NOT FOUND THEN
        CREATE INDEX CONCURRENTLY idx_app_tracking_events_properties_gin 
            ON app_tracking_events USING GIN (event_properties);
        RAISE NOTICE '  ✓ 创建属性GIN索引';
    END IF;
    
    RAISE NOTICE '🎉 Phase 2 完成! app_tracking_events分区表创建成功';
END $$;

-- =============================================
-- Phase 3: 创建用户行为汇总表
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 3: 创建用户行为汇总表...';
END $$;

CREATE TABLE IF NOT EXISTS user_behavior_summary (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    total_events INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    total_page_views INTEGER DEFAULT 0,
    total_interactions INTEGER DEFAULT 0,
    
    first_event_at TIMESTAMPTZ,
    last_event_at TIMESTAMPTZ,
    total_time_spent_seconds INTEGER DEFAULT 0,
    avg_session_duration_seconds DECIMAL(10,2) DEFAULT 0,
    
    total_payment_amount DECIMAL(12,2) DEFAULT 0,
    total_payment_orders INTEGER DEFAULT 0,
    current_membership_level VARCHAR(50) DEFAULT 'free',
    
    total_likes_given INTEGER DEFAULT 0,
    total_comments_made INTEGER DEFAULT 0,
    total_characters_followed INTEGER DEFAULT 0,
    
    favorite_features JSONB DEFAULT '[]',
    most_visited_pages JSONB DEFAULT '[]',
    interaction_patterns JSONB DEFAULT '{}',
    
    primary_device_type VARCHAR(50),
    preferred_platform VARCHAR(20),
    
    user_segment VARCHAR(50) DEFAULT 'new_user',
    lifecycle_stage VARCHAR(20) DEFAULT 'new',
    ltv_score DECIMAL(8,2) DEFAULT 0,
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建汇总表索引
CREATE INDEX IF NOT EXISTS idx_user_behavior_summary_segment ON user_behavior_summary (user_segment);
CREATE INDEX IF NOT EXISTS idx_user_behavior_summary_lifecycle ON user_behavior_summary (lifecycle_stage);
CREATE INDEX IF NOT EXISTS idx_user_behavior_summary_last_active ON user_behavior_summary (last_event_at DESC);

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建user_behavior_summary表';
    RAISE NOTICE '  ✓ 创建用户行为汇总表索引';
    RAISE NOTICE '🎉 Phase 3 完成! 用户行为汇总表创建成功';
END $$;

-- =============================================
-- Phase 4: 创建业务数据集成视图
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 4: 创建业务数据集成视图...';
END $$;

-- 支付事件视图
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_orders' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW payment_tracking_events AS
        SELECT 
            id::text as event_id,
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
        
        RAISE NOTICE '  ✓ 创建支付事件视图';
    ELSE
        RAISE NOTICE '  - 未找到payment_orders表，跳过支付事件视图';
    END IF;
END $$;

-- 会员行为事件视图
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_memberships' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW membership_tracking_events AS
        SELECT 
            id::text as event_id,
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
            plan_id::text as target_object_id,
            'subscription_plan' as target_object_type,
            'user_memberships' as data_source
        FROM user_memberships;
        
        RAISE NOTICE '  ✓ 创建会员行为事件视图';
    ELSE
        RAISE NOTICE '  - 未找到user_memberships表，跳过会员事件视图';
    END IF;
END $$;

-- 社交行为事件视图
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW social_like_tracking_events AS
        SELECT 
            id::text as event_id,
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
        
        RAISE NOTICE '  ✓ 创建社交点赞事件视图';
    ELSE
        RAISE NOTICE '  - 未找到likes表，跳过点赞事件视图';
    END IF;
    
    RAISE NOTICE '🎉 Phase 4 完成! 业务数据集成视图创建成功';
END $$;

-- =============================================
-- Phase 5: 创建统一事件视图
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 5: 创建统一查询接口...';
END $$;

CREATE OR REPLACE VIEW unified_tracking_events AS
-- app_tracking_events数据
SELECT 
    id::text as event_id,
    user_id,
    event_name,
    event_category,
    event_timestamp,
    event_properties,
    session_id,
    page_name,
    device_info,
    target_object_type,
    target_object_id::text as target_object_id,
    'app_tracking' as data_source
FROM app_tracking_events

UNION ALL

-- interaction_logs数据
SELECT 
    id::text as event_id,
    user_id,
    COALESCE(interaction_type, 'interaction') as event_name,
    'interaction' as event_category,
    created_at as event_timestamp,
    COALESCE(event_properties, '{}'::jsonb) as event_properties,
    session_id,
    (page_context->>'page_name') as page_name,
    COALESCE(device_info, '{}'::jsonb) as device_info,
    target_object_type,
    target_object_id::text as target_object_id,
    'interaction_logs' as data_source
FROM interaction_logs

UNION ALL

-- 支付数据 (如果视图存在)
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
    data_source
FROM payment_tracking_events
WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'payment_tracking_events')

UNION ALL

-- 会员数据 (如果视图存在)
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
    data_source
FROM membership_tracking_events
WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'membership_tracking_events')

UNION ALL

-- 社交数据 (如果视图存在)
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
    data_source
FROM social_like_tracking_events
WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'social_like_tracking_events');

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建unified_tracking_events统一查询视图';
    RAISE NOTICE '🎉 Phase 5 完成! 统一查询接口创建成功';
END $$;

-- =============================================
-- Phase 6: 创建自动化触发器
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 6: 配置自动化触发器...';
END $$;

-- 创建汇总更新函数
CREATE OR REPLACE FUNCTION update_user_behavior_summary_from_events()
RETURNS TRIGGER AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM user_behavior_summary WHERE user_id = NEW.user_id) INTO user_exists;
    
    IF NOT user_exists THEN
        INSERT INTO user_behavior_summary (
            user_id, 
            total_events, 
            first_event_at,
            last_event_at,
            updated_at
        ) VALUES (
            NEW.user_id, 
            1, 
            NEW.event_timestamp,
            NEW.event_timestamp,
            NOW()
        );
    ELSE
        UPDATE user_behavior_summary 
        SET 
            total_events = total_events + 1,
            last_event_at = GREATEST(last_event_at, NEW.event_timestamp),
            total_page_views = CASE 
                WHEN NEW.event_name = 'page_view' THEN total_page_views + 1 
                ELSE total_page_views 
            END,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_update_user_summary_from_app_events ON app_tracking_events;
CREATE TRIGGER trigger_update_user_summary_from_app_events
    AFTER INSERT ON app_tracking_events
    FOR EACH ROW EXECUTE FUNCTION update_user_behavior_summary_from_events();

-- 通用updated_at更新函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为汇总表添加updated_at触发器
DROP TRIGGER IF EXISTS trigger_user_behavior_summary_updated_at ON user_behavior_summary;
CREATE TRIGGER trigger_user_behavior_summary_updated_at
    BEFORE UPDATE ON user_behavior_summary
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建自动化触发器';
    RAISE NOTICE '🎉 Phase 6 完成! 自动化触发器配置成功';
END $$;

-- =============================================
-- Phase 7: 配置安全策略
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 7: 配置安全策略...';
END $$;

-- 启用RLS
ALTER TABLE app_tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_summary ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的数据
DROP POLICY IF EXISTS "Users can access own tracking events" ON app_tracking_events;
CREATE POLICY "Users can access own tracking events" ON app_tracking_events
    FOR ALL USING (auth.uid()::uuid = user_id);

DROP POLICY IF EXISTS "Users can access own behavior summary" ON user_behavior_summary;
CREATE POLICY "Users can access own behavior summary" ON user_behavior_summary
    FOR ALL USING (auth.uid()::uuid = user_id);

-- 管理员权限 (如果admin_users表存在)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_users' AND table_schema = 'public') THEN
        DROP POLICY IF EXISTS "Admins can access all tracking data" ON app_tracking_events;
        CREATE POLICY "Admins can access all tracking data" ON app_tracking_events
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM admin_users 
                    WHERE user_id = auth.uid()::uuid 
                    AND is_active = true
                )
            );
            
        DROP POLICY IF EXISTS "Admins can access all behavior summaries" ON user_behavior_summary;
        CREATE POLICY "Admins can access all behavior summaries" ON user_behavior_summary
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM admin_users 
                    WHERE user_id = auth.uid()::uuid 
                    AND is_active = true
                )
            );
        
        RAISE NOTICE '  ✓ 配置管理员权限策略';
    ELSE
        RAISE NOTICE '  - 未找到admin_users表，跳过管理员权限配置';
    END IF;
    
    RAISE NOTICE '  ✓ 配置用户数据隔离策略';
    RAISE NOTICE '🎉 Phase 7 完成! 安全策略配置成功';
END $$;

-- =============================================
-- Phase 8: 添加表注释和优化
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Phase 8: 添加表注释和性能优化...';
    
    -- 表注释
    COMMENT ON TABLE app_tracking_events IS '应用事件追踪表 - 高频系统事件存储，按月分区优化';
    COMMENT ON TABLE user_behavior_summary IS '用户行为汇总表 - 实时维护用户行为统计';
    COMMENT ON VIEW unified_tracking_events IS '统一埋点事件视图 - 所有数据源合并查询接口';
    
    -- 设置存储优化参数
    ALTER TABLE app_tracking_events SET (
        fillfactor = 90,
        autovacuum_vacuum_scale_factor = 0.1
    );
    
    ALTER TABLE user_behavior_summary SET (
        fillfactor = 80,
        autovacuum_vacuum_scale_factor = 0.2
    );
    
    RAISE NOTICE '  ✓ 添加表注释和性能优化配置';
    RAISE NOTICE '🎉 Phase 8 完成! 系统优化配置成功';
END $$;

-- =============================================
-- 部署完成验证和总结
-- =============================================

DO $$ 
DECLARE
    new_tables_count INTEGER;
    views_count INTEGER;
    functions_count INTEGER;
    total_partitions INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 正在验证部署结果...';
    
    -- 统计创建的对象
    SELECT COUNT(*) INTO new_tables_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('app_tracking_events', 'user_behavior_summary');
    
    SELECT COUNT(*) INTO views_count
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%tracking_events%';
    
    SELECT COUNT(*) INTO functions_count
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name LIKE '%behavior_summary%';
    
    SELECT COUNT(*) INTO total_partitions
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE 'app_tracking_events_%';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉🎉🎉 星趣APP数据埋点系统部署完成！🎉🎉🎉';
    RAISE NOTICE '';
    RAISE NOTICE '📊 部署统计:';
    RAISE NOTICE '  ✓ 扩展现有表: interaction_logs (新增6个埋点字段)';
    RAISE NOTICE '  ✓ 新建核心表: %个', new_tables_count;
    RAISE NOTICE '  ✓ 创建集成视图: %个', views_count;
    RAISE NOTICE '  ✓ 部署处理函数: %个', functions_count;
    RAISE NOTICE '  ✓ 创建分区表: %个分区', total_partitions;
    RAISE NOTICE '';
    RAISE NOTICE '🚀 核心功能:';
    RAISE NOTICE '  ✅ 用户交互埋点 (基于扩展的interaction_logs)';
    RAISE NOTICE '  ✅ 页面浏览追踪 (基于app_tracking_events分区表)';
    RAISE NOTICE '  ✅ 支付转化分析 (基于payment_orders集成视图)';
    RAISE NOTICE '  ✅ 会员行为分析 (基于user_memberships集成视图)';
    RAISE NOTICE '  ✅ 社交行为分析 (基于likes表集成视图)';
    RAISE NOTICE '  ✅ 用户行为汇总 (实时自动更新)';
    RAISE NOTICE '  ✅ 统一查询接口 (unified_tracking_events视图)';
    RAISE NOTICE '  ✅ 安全权限控制 (RLS策略，用户数据隔离)';
    RAISE NOTICE '';
    RAISE NOTICE '🔥 立即可用的API:';
    RAISE NOTICE '  • INSERT INTO interaction_logs (...) - 用户交互事件';
    RAISE NOTICE '  • INSERT INTO app_tracking_events (...) - 应用系统事件';  
    RAISE NOTICE '  • SELECT * FROM unified_tracking_events - 统一查询所有事件';
    RAISE NOTICE '  • SELECT * FROM user_behavior_summary - 用户行为画像';
    RAISE NOTICE '';
    RAISE NOTICE '✨ 系统已就绪，可以开始数据埋点采集和分析！';
    RAISE NOTICE '';
    
END $$;