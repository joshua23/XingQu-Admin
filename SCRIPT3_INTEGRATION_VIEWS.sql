-- =============================================
-- 星趣APP数据埋点系统 - 部署步骤3: 集成视图创建
-- 创建时间: 2025-01-07
-- 版本: v2.1.0 (拆分版本)
-- 用途: 在Supabase Dashboard SQL Editor中执行
-- =============================================

-- 开始执行提示
DO $$ 
BEGIN
    RAISE NOTICE '🚀 开始执行步骤3: 创建业务集成视图...';
    RAISE NOTICE '📅 执行时间: %', NOW();
    RAISE NOTICE '⚠️  将创建数据集成视图，复用现有业务表';
END $$;

-- =============================================
-- 支付事件集成视图
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📋 创建支付事件集成视图...';
    
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
        
        RAISE NOTICE '  ✓ 创建支付事件视图 (payment_tracking_events)';
    ELSE
        RAISE NOTICE '  - 未找到payment_orders表，跳过支付事件视图';
    END IF;
END $$;

-- =============================================
-- 会员行为事件集成视图
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📋 创建会员行为事件集成视图...';
    
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
        
        RAISE NOTICE '  ✓ 创建会员行为事件视图 (membership_tracking_events)';
    ELSE
        RAISE NOTICE '  - 未找到user_memberships表，跳过会员事件视图';
    END IF;
END $$;

-- =============================================
-- 社交行为事件集成视图
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📋 创建社交行为事件集成视图...';
    
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
        
        RAISE NOTICE '  ✓ 创建社交点赞事件视图 (social_like_tracking_events)';
    ELSE
        RAISE NOTICE '  - 未找到likes表，跳过点赞事件视图';
    END IF;
END $$;

-- =============================================
-- 评论行为事件集成视图
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📋 创建评论行为事件集成视图...';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments' AND table_schema = 'public') THEN
        CREATE OR REPLACE VIEW social_comment_tracking_events AS
        SELECT 
            id::text as event_id,
            user_id,
            'social_comment' as event_name,
            'social' as event_category,
            created_at as event_timestamp,
            json_build_object(
                'comment_id', id,
                'target_type', target_type,
                'target_id', target_id,
                'content_length', LENGTH(content)
            ) as event_properties,
            target_id::text as target_object_id,
            target_type as target_object_type,
            'comments' as data_source
        FROM comments;
        
        RAISE NOTICE '  ✓ 创建社交评论事件视图 (social_comment_tracking_events)';
    ELSE
        RAISE NOTICE '  - 未找到comments表，跳过评论事件视图';
    END IF;
END $$;

-- =============================================
-- 统一事件查询视图
-- =============================================

DO $$ 
DECLARE
    has_extended_interaction_logs BOOLEAN;
BEGIN
    RAISE NOTICE '📋 创建统一事件查询接口...';
    
    -- 检查interaction_logs表是否有扩展字段
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'interaction_logs' 
        AND column_name IN ('session_id', 'event_properties', 'device_info')
    ) INTO has_extended_interaction_logs;
    
    IF has_extended_interaction_logs THEN
        RAISE NOTICE '  - 检测到interaction_logs扩展字段，创建完整版统一视图';
        
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
            'app_tracking' as data_source,
            created_at
        FROM app_tracking_events

        UNION ALL

        -- interaction_logs数据 (包含扩展字段)
        SELECT 
            id::text as event_id,
            user_id,
            COALESCE(interaction_type, 'interaction') as event_name,
            'interaction' as event_category,
            created_at as event_timestamp,
            COALESCE(event_properties, '{}'::jsonb) as event_properties,
            session_id,
            CASE WHEN page_context IS NOT NULL THEN page_context->>'page_name' ELSE NULL END as page_name,
            COALESCE(device_info, '{}'::jsonb) as device_info,
            target_object_type,
            target_object_id::text as target_object_id,
            'interaction_logs' as data_source,
            created_at
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
            data_source,
            event_timestamp as created_at
        FROM payment_tracking_events
        WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'payment_tracking_events' AND table_schema = 'public')

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
            data_source,
            event_timestamp as created_at
        FROM membership_tracking_events
        WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'membership_tracking_events' AND table_schema = 'public')

        UNION ALL

        -- 社交点赞数据 (如果视图存在)
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
            data_source,
            event_timestamp as created_at
        FROM social_like_tracking_events
        WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'social_like_tracking_events' AND table_schema = 'public')

        UNION ALL

        -- 社交评论数据 (如果视图存在)  
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
            data_source,
            event_timestamp as created_at
        FROM social_comment_tracking_events
        WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'social_comment_tracking_events' AND table_schema = 'public');
        
    ELSE
        RAISE NOTICE '  - interaction_logs表未扩展，创建基础版统一视图';
        
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
            'app_tracking' as data_source,
            created_at
        FROM app_tracking_events

        UNION ALL

        -- interaction_logs数据 (基础字段)
        SELECT 
            id::text as event_id,
            user_id,
            COALESCE(interaction_type, 'interaction') as event_name,
            'interaction' as event_category,
            created_at as event_timestamp,
            '{}'::jsonb as event_properties,
            NULL as session_id,
            NULL as page_name,
            '{}'::jsonb as device_info,
            NULL as target_object_type,
            NULL as target_object_id,
            'interaction_logs' as data_source,
            created_at
        FROM interaction_logs;
    END IF;
    
    RAISE NOTICE '  ✓ 创建unified_tracking_events统一查询视图';
END $$;

-- =============================================
-- 添加视图注释
-- =============================================

COMMENT ON VIEW unified_tracking_events IS '统一埋点事件视图 - 所有数据源合并查询接口，支持完整的事件分析';

-- =============================================
-- 完成检查
-- =============================================

DO $$ 
DECLARE
    views_count INTEGER;
BEGIN
    -- 统计创建的视图
    SELECT COUNT(*) INTO views_count
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%tracking_events%';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 步骤3完成! 成功创建%个集成视图', views_count;
    RAISE NOTICE '✅ 业务数据集成视图已就绪';
    RAISE NOTICE '✅ unified_tracking_events统一查询接口已创建';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 下一步：请执行 SCRIPT4_AUTOMATION.sql';
END $$;