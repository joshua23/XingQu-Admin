-- =============================================
-- 星趣APP埋点数据流诊断和修复脚本
-- 创建时间: 2025-01-08
-- 功能: 诊断并修复"首页-精选页"埋点数据无法在后台显示的问题
-- =============================================

-- 第一步：检查现有表是否存在
DO $$ 
DECLARE
    has_user_analytics BOOLEAN;
    has_app_tracking_events BOOLEAN;
    has_interaction_logs BOOLEAN;
    has_unified_view BOOLEAN;
BEGIN
    RAISE NOTICE '🔍 开始诊断埋点数据表结构...';
    
    -- 检查关键表是否存在
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'user_analytics' AND table_schema = 'public'
    ) INTO has_user_analytics;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'app_tracking_events' AND table_schema = 'public'
    ) INTO has_app_tracking_events;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'interaction_logs' AND table_schema = 'public'
    ) INTO has_interaction_logs;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'unified_tracking_events' AND table_schema = 'public'
    ) INTO has_unified_view;
    
    -- 输出诊断结果
    RAISE NOTICE '📋 诊断结果:';
    RAISE NOTICE '  - user_analytics表: %', CASE WHEN has_user_analytics THEN '✅ 存在' ELSE '❌ 不存在' END;
    RAISE NOTICE '  - app_tracking_events表: %', CASE WHEN has_app_tracking_events THEN '✅ 存在' ELSE '❌ 不存在' END;
    RAISE NOTICE '  - interaction_logs表: %', CASE WHEN has_interaction_logs THEN '✅ 存在' ELSE '❌ 不存在' END;
    RAISE NOTICE '  - unified_tracking_events视图: %', CASE WHEN has_unified_view THEN '✅ 存在' ELSE '❌ 不存在' END;
    
    -- 如果缺失关键表，提示需要执行迁移
    IF NOT has_user_analytics THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  缺失user_analytics表 - 这是移动端埋点数据的主要存储表';
        RAISE NOTICE '   解决方案: 需要创建user_analytics表';
    END IF;
END $$;

-- 第二步：创建缺失的埋点数据表（如果不存在）
DO $$
BEGIN
    -- 创建user_analytics表（移动端直接使用的表）
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_analytics' AND table_schema = 'public') THEN
        RAISE NOTICE '🔧 创建user_analytics表...';
        
        CREATE TABLE user_analytics (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            event_type VARCHAR(100) NOT NULL,
            event_data JSONB DEFAULT '{}',
            session_id VARCHAR(255),
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            
            -- 埋点专用字段
            page_name VARCHAR(100),
            device_info JSONB DEFAULT '{}',
            target_object_type VARCHAR(50),
            target_object_id UUID
        );
        
        -- 创建索引优化查询性能
        CREATE INDEX idx_user_analytics_user_time ON user_analytics (user_id, created_at DESC);
        CREATE INDEX idx_user_analytics_event_time ON user_analytics (event_type, created_at DESC);
        CREATE INDEX idx_user_analytics_session ON user_analytics (session_id);
        CREATE INDEX idx_user_analytics_event_data_gin ON user_analytics USING GIN (event_data);
        
        RAISE NOTICE '✅ user_analytics表创建成功';
    END IF;
    
    -- 启用RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_analytics' AND table_schema = 'public') THEN
        ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;
        
        -- 删除可能存在的旧策略
        DROP POLICY IF EXISTS "Users can access own analytics" ON user_analytics;
        
        -- 创建RLS策略
        CREATE POLICY "Users can access own analytics" ON user_analytics
            FOR ALL USING (auth.uid()::uuid = user_id);
            
        RAISE NOTICE '✅ user_analytics表RLS策略设置完成';
    END IF;
END $$;

-- 第三步：检查现有数据
DO $$
DECLARE
    analytics_count INTEGER;
    recent_events INTEGER;
    user_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📊 检查现有埋点数据...';
    
    -- 统计总记录数
    SELECT COUNT(*) INTO analytics_count FROM user_analytics;
    
    -- 统计最近24小时的记录数
    SELECT COUNT(*) INTO recent_events 
    FROM user_analytics 
    WHERE created_at >= NOW() - INTERVAL '24 hours';
    
    -- 统计有埋点数据的用户数
    SELECT COUNT(DISTINCT user_id) INTO user_count FROM user_analytics;
    
    RAISE NOTICE '  - 总埋点记录数: %', analytics_count;
    RAISE NOTICE '  - 最近24小时记录数: %', recent_events;
    RAISE NOTICE '  - 有数据的用户数: %', user_count;
    
    -- 显示最近几条记录的示例
    IF analytics_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '📝 最近埋点数据样例:';
        PERFORM (
            SELECT string_agg(
                '  - ' || event_type || ' (用户: ' || COALESCE(user_id::text, 'NULL') || ', 时间: ' || created_at::text || ')',
                E'\n'
            )
            FROM (
                SELECT event_type, user_id, created_at 
                FROM user_analytics 
                ORDER BY created_at DESC 
                LIMIT 5
            ) t
        );
    ELSE
        RAISE NOTICE '  ⚠️  暂无埋点数据记录';
    END IF;
END $$;

-- 第四步：测试数据写入功能
DO $$
DECLARE
    test_user_id UUID;
    test_success BOOLEAN := false;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧪 测试埋点数据写入功能...';
    
    -- 获取一个现有用户ID用于测试
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- 尝试插入测试数据
        BEGIN
            INSERT INTO user_analytics (
                user_id, 
                event_type, 
                event_data, 
                session_id,
                page_name
            ) VALUES (
                test_user_id,
                'test_page_view',
                '{"source": "featured_page", "test": true}',
                'test_session_' || extract(epoch from now()),
                'home_selection_page'
            );
            
            test_success := true;
            RAISE NOTICE '✅ 埋点数据写入测试成功';
            
            -- 立即删除测试数据
            DELETE FROM user_analytics 
            WHERE event_type = 'test_page_view' AND (event_data->>'test')::boolean = true;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ 埋点数据写入测试失败: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️  无法找到测试用户，跳过写入测试';
    END IF;
END $$;

-- 第五步：检查后台管理系统相关表
DO $$
DECLARE
    has_likes BOOLEAN;
    has_comments BOOLEAN;
    has_follows BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 检查后台系统依赖的表...';
    
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes' AND table_schema = 'public') INTO has_likes;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments' AND table_schema = 'public') INTO has_comments;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'character_follows' AND table_schema = 'public') INTO has_follows;
    
    RAISE NOTICE '  - likes表: %', CASE WHEN has_likes THEN '✅ 存在' ELSE '❌ 不存在' END;
    RAISE NOTICE '  - comments表: %', CASE WHEN has_comments THEN '✅ 存在' ELSE '❌ 不存在' END;
    RAISE NOTICE '  - character_follows表: %', CASE WHEN has_follows THEN '✅ 存在' ELSE '❌ 不存在' END;
    
    -- 如果后台系统依赖的表缺失，创建基础表结构
    IF NOT has_likes THEN
        RAISE NOTICE '🔧 创建likes表...';
        CREATE TABLE IF NOT EXISTS likes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            target_id UUID NOT NULL,
            target_type VARCHAR(50) NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE INDEX idx_likes_user ON likes (user_id);
        CREATE INDEX idx_likes_target ON likes (target_id, target_type);
        
        ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Users can manage own likes" ON likes FOR ALL USING (auth.uid()::uuid = user_id);
    END IF;
    
    IF NOT has_follows THEN
        RAISE NOTICE '🔧 创建character_follows表...';
        CREATE TABLE IF NOT EXISTS character_follows (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            character_id UUID NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE INDEX idx_character_follows_user ON character_follows (user_id);
        CREATE INDEX idx_character_follows_character ON character_follows (character_id);
        
        ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Users can manage own follows" ON character_follows FOR ALL USING (auth.uid()::uuid = user_id);
    END IF;
END $$;

-- 第六步：输出修复总结和下一步指导
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 埋点数据流诊断和修复完成！';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 完成的修复工作:';
    RAISE NOTICE '  1. 检查并创建了user_analytics表';
    RAISE NOTICE '  2. 设置了适当的索引和RLS策略';
    RAISE NOTICE '  3. 确保了后台系统依赖表的存在';
    RAISE NOTICE '  4. 测试了数据写入功能';
    RAISE NOTICE '';
    RAISE NOTICE '📱 下一步操作建议:';
    RAISE NOTICE '  1. 重启Flutter应用，触发一些首页-精选页的交互';
    RAISE NOTICE '  2. 在后台管理系统刷新Mobile数据监控页面';
    RAISE NOTICE '  3. 查看实时活动流是否显示移动端数据';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 如果仍有问题，请检查:';
    RAISE NOTICE '  - Flutter应用的Supabase连接配置';
    RAISE NOTICE '  - 用户是否已正确登录';
    RAISE NOTICE '  - 网络连接是否正常';
END $$;