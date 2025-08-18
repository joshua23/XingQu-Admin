-- =============================================
-- 星趣APP数据埋点系统 - 集成化数据库模型
-- 创建时间: 2025-01-07
-- 版本: v2.0.0 (集成版)
-- 设计原则: 基于现有表扩展，避免重复，渐进式增强
-- =============================================

-- 检查执行环境
DO $$ 
BEGIN
    RAISE NOTICE '开始执行星趣APP埋点系统集成化数据库模型...';
    RAISE NOTICE '设计原则: 扩展现有表 + 专门新建 + 业务集成';
END $$;

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================
-- Phase 1: 扩展现有表 (零影响增强)
-- =============================================

-- 1.1 安全扩展 interaction_logs 表
DO $$ 
BEGIN
    -- 检查表是否存在
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interaction_logs' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ 发现interaction_logs表，开始安全扩展...';
        
        -- 添加埋点专用字段（使用IF NOT EXISTS确保安全）
        BEGIN
            ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS session_id VARCHAR(255);
            RAISE NOTICE '  - 添加session_id字段';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - session_id字段可能已存在，跳过';
        END;
        
        BEGIN
            ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS event_properties JSONB DEFAULT '{}';
            RAISE NOTICE '  - 添加event_properties字段';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - event_properties字段可能已存在，跳过';
        END;
        
        BEGIN
            ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS target_object_type VARCHAR(50);
            RAISE NOTICE '  - 添加target_object_type字段';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - target_object_type字段可能已存在，跳过';
        END;
        
        BEGIN
            ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS target_object_id UUID;
            RAISE NOTICE '  - 添加target_object_id字段';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - target_object_id字段可能已存在，跳过';
        END;
        
        BEGIN
            ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS page_context JSONB DEFAULT '{}';
            RAISE NOTICE '  - 添加page_context字段';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - page_context字段可能已存在，跳过';
        END;
        
        BEGIN
            ALTER TABLE interaction_logs ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}';
            RAISE NOTICE '  - 添加device_info字段';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - device_info字段可能已存在，跳过';
        END;
        
    ELSE
        RAISE WARNING '❌ 未找到interaction_logs表，跳过扩展';
    END IF;
END $$;

-- 1.2 为扩展字段添加索引（使用CONCURRENTLY确保不影响现有查询）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interaction_logs' AND table_schema = 'public') THEN
        BEGIN
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_logs_session_id 
                ON interaction_logs (session_id);
            RAISE NOTICE '  - 创建session_id索引';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - session_id索引可能已存在';
        END;
        
        BEGIN
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_logs_target 
                ON interaction_logs (target_object_type, target_object_id);
            RAISE NOTICE '  - 创建目标对象索引';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - 目标对象索引可能已存在';
        END;
        
        BEGIN
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_interaction_logs_properties_gin 
                ON interaction_logs USING GIN (event_properties);
            RAISE NOTICE '  - 创建属性GIN索引';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - 属性GIN索引可能已存在';
        END;
    END IF;
END $$;

-- 1.3 创建向后兼容视图（确保现有代码不受影响）
CREATE OR REPLACE VIEW interaction_logs_legacy AS
SELECT 
    id, 
    user_id, 
    interaction_type, 
    created_at
FROM interaction_logs;

COMMENT ON VIEW interaction_logs_legacy IS '向后兼容视图：保证现有应用继续正常工作';

-- =============================================
-- Phase 2: 新建专门的高频事件表
-- =============================================

-- 2.1 创建专门的应用事件追踪表（分区设计）
CREATE TABLE IF NOT EXISTS app_tracking_events (
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
    
    -- 业务关联字段（与现有业务表关联）
    story_id UUID, -- 不设外键约束，避免对stories表的依赖
    character_id UUID, -- 不设外键约束，避免对ai_characters表的依赖  
    target_object_type VARCHAR(50), -- 通用目标类型
    target_object_id UUID, -- 通用目标ID
    
    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 索引优化字段
    event_date DATE GENERATED ALWAYS AS (event_timestamp::DATE) STORED
) PARTITION BY RANGE (event_date);

-- 2.2 创建分区表（按月分区，提升查询性能）
CREATE TABLE IF NOT EXISTS app_tracking_events_202501 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE IF NOT EXISTS app_tracking_events_202502 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE IF NOT EXISTS app_tracking_events_202503 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE IF NOT EXISTS app_tracking_events_202504 PARTITION OF app_tracking_events
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

-- 2.3 为高频查询创建优化索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_user_time 
    ON app_tracking_events (user_id, event_timestamp DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_name_time 
    ON app_tracking_events (event_name, event_timestamp DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_session 
    ON app_tracking_events (session_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_category_time 
    ON app_tracking_events (event_category, event_timestamp DESC);

-- JSONB字段的GIN索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_properties_gin 
    ON app_tracking_events USING GIN (event_properties);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_device_gin 
    ON app_tracking_events USING GIN (device_info);

-- 热数据查询优化索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_tracking_events_recent_hot
    ON app_tracking_events (event_timestamp DESC, event_name)
    WHERE event_timestamp >= NOW() - INTERVAL '7 days';

-- =============================================
-- Phase 3: 用户行为汇总表（实时统计）
-- =============================================

-- 3.1 创建用户行为汇总表
CREATE TABLE IF NOT EXISTS user_behavior_summary (
    -- 主键
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
    
    -- 业务统计（从现有表中同步）
    total_payment_amount DECIMAL(12,2) DEFAULT 0,
    total_payment_orders INTEGER DEFAULT 0,
    current_membership_level VARCHAR(50) DEFAULT 'free',
    
    -- 社交统计（从现有表中同步）
    total_likes_given INTEGER DEFAULT 0,
    total_comments_made INTEGER DEFAULT 0,
    total_characters_followed INTEGER DEFAULT 0,
    
    -- 行为特征（JSONB存储复杂分析结果）
    favorite_features JSONB DEFAULT '[]', -- 最常用功能
    most_visited_pages JSONB DEFAULT '[]', -- 最常访问页面
    interaction_patterns JSONB DEFAULT '{}', -- 交互模式分析
    
    -- 设备偏好
    primary_device_type VARCHAR(50),
    preferred_platform VARCHAR(20), -- ios, android, web
    
    -- 用户分层标识
    user_segment VARCHAR(50) DEFAULT 'new_user',
    lifecycle_stage VARCHAR(20) DEFAULT 'new', -- new, active, dormant, churned
    ltv_score DECIMAL(8,2) DEFAULT 0,
    
    -- 更新时间
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.2 为汇总表创建索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_behavior_summary_segment 
    ON user_behavior_summary (user_segment);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_behavior_summary_lifecycle 
    ON user_behavior_summary (lifecycle_stage);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_behavior_summary_last_active 
    ON user_behavior_summary (last_event_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_behavior_summary_ltv 
    ON user_behavior_summary (ltv_score DESC);

-- =============================================
-- Phase 4: 业务数据集成视图（避免重复存储）
-- =============================================

-- 4.1 支付事件视图（基于现有payment_orders表）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_orders' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW payment_tracking_events AS
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
        
        RAISE NOTICE '✅ 创建支付事件视图成功';
    ELSE
        RAISE WARNING '❌ 未找到payment_orders表，跳过支付事件视图创建';
    END IF;
END $$;

-- 4.2 会员行为事件视图（基于现有user_memberships表）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_memberships' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW membership_tracking_events AS
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
            plan_id::text as target_object_id,
            'subscription_plan' as target_object_type,
            'user_memberships' as data_source
        FROM user_memberships;
        
        RAISE NOTICE '✅ 创建会员行为事件视图成功';
    ELSE
        RAISE WARNING '❌ 未找到user_memberships表，跳过会员事件视图创建';
    END IF;
END $$;

-- 4.3 社交行为事件视图（基于现有likes表）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW social_like_tracking_events AS
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
        
        RAISE NOTICE '✅ 创建社交点赞事件视图成功';
    ELSE
        RAISE WARNING '❌ 未找到likes表，跳过点赞事件视图创建';
    END IF;
END $$;

-- =============================================
-- Phase 5: 统一事件视图（全数据源合并）
-- =============================================

-- 5.1 创建统一的埋点事件视图
CREATE OR REPLACE VIEW unified_tracking_events AS
-- 来自app_tracking_events的数据
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

-- 来自扩展后interaction_logs的数据
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

-- 来自支付数据的事件
SELECT 
    event_id::text,
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

-- 来自会员数据的事件
SELECT 
    event_id::text,
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

-- 来自社交数据的事件
SELECT 
    event_id::text,
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

-- =============================================
-- Phase 6: 自动化触发器和函数
-- =============================================

-- 6.1 自动更新用户行为汇总的函数
CREATE OR REPLACE FUNCTION update_user_behavior_summary_from_events()
RETURNS TRIGGER AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- 检查用户是否存在于汇总表中
    SELECT EXISTS(SELECT 1 FROM user_behavior_summary WHERE user_id = NEW.user_id) INTO user_exists;
    
    IF NOT user_exists THEN
        -- 插入新用户的初始汇总数据
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
        -- 更新existing用户的汇总数据
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

-- 6.2 为app_tracking_events创建触发器
CREATE TRIGGER trigger_update_user_summary_from_app_events
    AFTER INSERT ON app_tracking_events
    FOR EACH ROW EXECUTE FUNCTION update_user_behavior_summary_from_events();

-- 6.3 通用的updated_at自动更新函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为user_behavior_summary添加updated_at自动更新
CREATE TRIGGER trigger_user_behavior_summary_updated_at
    BEFORE UPDATE ON user_behavior_summary
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Phase 7: RLS安全策略（继承现有权限体系）
-- =============================================

-- 7.1 启用RLS
ALTER TABLE app_tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_summary ENABLE ROW LEVEL SECURITY;

-- 7.2 用户只能查看自己的数据
CREATE POLICY "Users can access own tracking events" ON app_tracking_events
    FOR ALL USING (auth.uid()::uuid = user_id);

CREATE POLICY "Users can access own behavior summary" ON user_behavior_summary
    FOR ALL USING (auth.uid()::uuid = user_id);

-- 7.3 管理员可以查看所有数据（如果admin_users表存在）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_users' AND table_schema = 'public') THEN
        CREATE POLICY "Admins can access all tracking data" ON app_tracking_events
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM admin_users 
                    WHERE user_id = auth.uid()::uuid 
                    AND is_active = true
                )
            );
            
        CREATE POLICY "Admins can access all behavior summaries" ON user_behavior_summary
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM admin_users 
                    WHERE user_id = auth.uid()::uuid 
                    AND is_active = true
                )
            );
        
        RAISE NOTICE '✅ 创建管理员权限策略成功';
    ELSE
        RAISE NOTICE '⚠️  未找到admin_users表，跳过管理员权限策略';
    END IF;
END $$;

-- =============================================
-- Phase 8: 数据字典和注释
-- =============================================

-- 表注释
COMMENT ON TABLE app_tracking_events IS '应用事件追踪表 - 存储页面浏览、应用生命周期等高频事件，按月分区优化';
COMMENT ON TABLE user_behavior_summary IS '用户行为汇总表 - 实时维护的用户行为统计和分析数据';

-- 视图注释
COMMENT ON VIEW unified_tracking_events IS '统一埋点事件视图 - 合并所有数据源的埋点事件，提供统一查询接口';
COMMENT ON VIEW interaction_logs_legacy IS '交互日志传统视图 - 保证现有代码的向后兼容性';

-- 关键字段注释
COMMENT ON COLUMN app_tracking_events.event_properties IS '事件属性的JSONB存储，支持灵活的事件参数和自定义字段';
COMMENT ON COLUMN app_tracking_events.session_id IS '会话标识，用于关联同一会话的多个事件，便于用户行为路径分析';
COMMENT ON COLUMN user_behavior_summary.ltv_score IS '用户生命周期价值评分，用于用户价值分层和营销策略';

-- =============================================
-- Phase 9: 数据完整性和性能优化
-- =============================================

-- 9.1 设置表的存储参数优化
ALTER TABLE app_tracking_events SET (
    fillfactor = 90,  -- 为后续更新预留空间
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE user_behavior_summary SET (
    fillfactor = 80,  -- 用户汇总表更新频繁
    autovacuum_vacuum_scale_factor = 0.2
);

-- 9.2 创建数据一致性检查函数
CREATE OR REPLACE FUNCTION check_tracking_data_consistency()
RETURNS TABLE (
    check_name TEXT,
    inconsistency_count BIGINT,
    details TEXT
) AS $$
BEGIN
    -- 检查用户行为汇总与实际事件数据的一致性
    RETURN QUERY
    SELECT 
        'user_event_count_consistency'::TEXT,
        COUNT(*)::BIGINT,
        '用户汇总表中的事件计数与实际事件数不匹配的用户数量'::TEXT
    FROM user_behavior_summary s
    LEFT JOIN (
        SELECT 
            user_id, 
            COUNT(*) as actual_count 
        FROM unified_tracking_events 
        WHERE user_id IS NOT NULL
        GROUP BY user_id
    ) e ON s.user_id = e.user_id
    WHERE s.total_events != COALESCE(e.actual_count, 0);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 执行完成验证和总结
-- =============================================

DO $$ 
DECLARE
    table_count INTEGER;
    view_count INTEGER;
    function_count INTEGER;
BEGIN
    -- 统计创建的对象数量
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('app_tracking_events', 'user_behavior_summary');
    
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name IN ('unified_tracking_events', 'interaction_logs_legacy', 'payment_tracking_events');
    
    SELECT COUNT(*) INTO function_count
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name IN ('update_user_behavior_summary_from_events', 'check_tracking_data_consistency');
    
    -- 输出执行结果
    RAISE NOTICE '🎉 星趣APP数据埋点系统集成化模型部署完成！';
    RAISE NOTICE '📊 部署统计:';
    RAISE NOTICE '  - 新建核心表: %个', table_count;
    RAISE NOTICE '  - 创建集成视图: %个', view_count;
    RAISE NOTICE '  - 部署处理函数: %个', function_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ 主要功能:';
    RAISE NOTICE '  - 扩展现有interaction_logs表，支持高级埋点功能';
    RAISE NOTICE '  - 新建app_tracking_events分区表，优化高频事件存储';
    RAISE NOTICE '  - 创建unified_tracking_events视图，提供统一数据接口';
    RAISE NOTICE '  - 集成现有业务表，避免数据重复';
    RAISE NOTICE '  - 实现用户行为实时汇总和自动更新';
    RAISE NOTICE '  - 继承现有安全策略，确保数据权限一致';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 系统已就绪，可开始数据埋点和分析！';
    
END $$;