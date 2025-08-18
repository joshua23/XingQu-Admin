-- =============================================
-- 星趣APP数据埋点系统 - 部署步骤4: 自动化和安全策略
-- 创建时间: 2025-01-07
-- 版本: v2.1.0 (拆分版本)
-- 用途: 在Supabase Dashboard SQL Editor中执行
-- =============================================

-- 开始执行提示
DO $$ 
BEGIN
    RAISE NOTICE '🚀 开始执行步骤4: 配置自动化和安全策略...';
    RAISE NOTICE '📅 执行时间: %', NOW();
    RAISE NOTICE '⚠️  将配置触发器和RLS安全策略';
END $$;

-- =============================================
-- 创建自动化触发器函数
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '📋 创建自动化触发器函数...';
END $$;

-- 汇总表更新函数
CREATE OR REPLACE FUNCTION update_user_behavior_summary_from_events()
RETURNS TRIGGER AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- 检查user_id是否为空
    IF NEW.user_id IS NULL THEN
        RETURN NEW;
    END IF;
    
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
            total_interactions = CASE 
                WHEN NEW.event_category = 'interaction' THEN total_interactions + 1 
                ELSE total_interactions 
            END,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 通用updated_at更新函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建触发器函数';
END $$;

-- =============================================
-- 创建触发器
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '📋 配置自动化触发器...';
END $$;

-- 为app_tracking_events添加汇总更新触发器
DROP TRIGGER IF EXISTS trigger_update_user_summary_from_app_events ON app_tracking_events;
CREATE TRIGGER trigger_update_user_summary_from_app_events
    AFTER INSERT ON app_tracking_events
    FOR EACH ROW EXECUTE FUNCTION update_user_behavior_summary_from_events();

-- 为user_behavior_summary添加updated_at触发器
DROP TRIGGER IF EXISTS trigger_user_behavior_summary_updated_at ON user_behavior_summary;
CREATE TRIGGER trigger_user_behavior_summary_updated_at
    BEFORE UPDATE ON user_behavior_summary
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 检查interaction_logs是否有扩展字段，如有则添加触发器
DO $$
DECLARE
    has_extended_fields BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'interaction_logs' 
        AND column_name = 'event_properties'
    ) INTO has_extended_fields;
    
    IF has_extended_fields THEN
        -- 为扩展的interaction_logs也添加汇总更新触发器
        DROP TRIGGER IF EXISTS trigger_update_user_summary_from_interactions ON interaction_logs;
        CREATE TRIGGER trigger_update_user_summary_from_interactions
            AFTER INSERT ON interaction_logs
            FOR EACH ROW EXECUTE FUNCTION update_user_behavior_summary_from_events();
        
        RAISE NOTICE '  ✓ 为interaction_logs添加汇总更新触发器';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '  ✓ 配置app_tracking_events汇总更新触发器';
    RAISE NOTICE '  ✓ 配置user_behavior_summary更新时间触发器';
END $$;

-- =============================================
-- 配置Row Level Security (RLS)
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '📋 配置Row Level Security策略...';
END $$;

-- 启用RLS
ALTER TABLE app_tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_summary ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的数据
DROP POLICY IF EXISTS "Users can access own tracking events" ON app_tracking_events;
CREATE POLICY "Users can access own tracking events" ON app_tracking_events
    FOR ALL USING (auth.uid()::uuid = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can access own behavior summary" ON user_behavior_summary;
CREATE POLICY "Users can access own behavior summary" ON user_behavior_summary
    FOR ALL USING (auth.uid()::uuid = user_id);

-- 检查是否有admin_users表，如有则配置管理员权限
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_users' AND table_schema = 'public') THEN
        -- 管理员可以访问所有数据
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
        
        RAISE NOTICE '  ✓ 配置管理员权限策略 (基于admin_users表)';
    ELSE
        RAISE NOTICE '  - 未找到admin_users表，跳过管理员权限配置';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '  ✓ 配置用户数据隔离策略';
    RAISE NOTICE '  ✓ RLS安全策略配置完成';
END $$;

-- =============================================
-- 性能优化配置
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📋 配置性能优化参数...';
    
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
    
    RAISE NOTICE '  ✓ 配置存储优化参数';
    RAISE NOTICE '  ✓ 配置自动清理参数';
END $$;

-- =============================================
-- 创建数据质量检查函数
-- =============================================

CREATE OR REPLACE FUNCTION check_tracking_data_consistency()
RETURNS TABLE (
    check_name TEXT, 
    inconsistency_count BIGINT, 
    details TEXT,
    checked_at TIMESTAMPTZ
) AS $$
BEGIN
    -- 检查汇总表与实际事件的一致性
    RETURN QUERY
    SELECT 
        'user_event_count_consistency'::TEXT as check_name,
        COUNT(*)::BIGINT as inconsistency_count,
        '用户汇总表与实际事件数不匹配的用户数'::TEXT as details,
        NOW() as checked_at
    FROM user_behavior_summary s
    LEFT JOIN (
        SELECT user_id, COUNT(*) as actual_count 
        FROM app_tracking_events 
        WHERE user_id IS NOT NULL 
        GROUP BY user_id
    ) e ON s.user_id = e.user_id
    WHERE s.total_events != COALESCE(e.actual_count, 0);
    
    -- 检查最近一小时的事件处理情况
    RETURN QUERY
    SELECT 
        'recent_events_processing'::TEXT as check_name,
        COUNT(*)::BIGINT as inconsistency_count,
        '最近1小时新增事件数'::TEXT as details,
        NOW() as checked_at
    FROM app_tracking_events 
    WHERE created_at >= NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE '  ✓ 创建数据一致性检查函数';
END $$;

-- =============================================
-- 完成检查和测试
-- =============================================

DO $$ 
DECLARE
    triggers_count INTEGER;
    policies_count INTEGER;
BEGIN
    -- 统计触发器
    SELECT COUNT(*) INTO triggers_count
    FROM information_schema.triggers 
    WHERE event_object_schema = 'public' 
    AND (event_object_table = 'app_tracking_events' OR event_object_table = 'user_behavior_summary');
    
    -- 统计RLS策略 
    SELECT COUNT(*) INTO policies_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND (tablename = 'app_tracking_events' OR tablename = 'user_behavior_summary');
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 步骤4完成! 自动化和安全配置就绪';
    RAISE NOTICE '✅ 创建触发器: %个', triggers_count;
    RAISE NOTICE '✅ 配置RLS策略: %个', policies_count;
    RAISE NOTICE '✅ 性能优化参数已设置';
    RAISE NOTICE '✅ 数据质量检查函数已创建';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 下一步：请执行 deploy_step5_test.sql 进行系统测试';
END $$;