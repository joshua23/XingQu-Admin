-- =====================================================================
-- 星趣项目 - 数据一致性检查和验证脚本
-- 用途：全面验证数据库修复效果，确保埋点功能正常
-- 执行环境：Supabase SQL编辑器
-- =====================================================================

-- 执行说明：
-- 此脚本用于验证数据库修复的完整性和正确性
-- 可以在主修复脚本执行后运行，确保所有问题都已解决

-- =====================================================================
-- 第一阶段：基础数据结构检查
-- =====================================================================

SELECT '🔍 第一阶段：基础数据结构检查' as phase;

-- 检查关键表是否存在
WITH table_check AS (
    SELECT 
        table_name,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_name = t.table_name
            )
            THEN '✅ 存在'
            ELSE '❌ 不存在'
        END as table_status
    FROM (VALUES ('users'), ('user_analytics'), ('ai_characters')) as t(table_name)
)
SELECT 
    '📊 表存在性检查' as category,
    table_name,
    table_status
FROM table_check
ORDER BY table_name;

-- 检查users表字段结构
SELECT 
    '🔧 users表字段检查' as category,
    column_name,
    data_type,
    CASE 
        WHEN is_nullable = 'YES' THEN '✅ 允许NULL'
        ELSE '⚠️ NOT NULL'
    END as nullable_status,
    CASE 
        WHEN column_default IS NOT NULL THEN '✅ 有默认值'
        ELSE '⭕ 无默认值'
    END as default_status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
AND column_name IN ('id', 'phone', 'nickname', 'updated_at', 'created_at')
ORDER BY ordinal_position;

-- 检查user_analytics表字段结构
SELECT 
    '📈 user_analytics表字段检查' as category,
    column_name,
    data_type,
    CASE 
        WHEN is_nullable = 'YES' THEN '✅ 允许NULL'
        ELSE '⚠️ NOT NULL'
    END as nullable_status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'user_analytics'
AND column_name IN ('id', 'user_id', 'event_type', 'event_data', 'session_id', 'page_name', 'created_at', 'updated_at')
ORDER BY ordinal_position;

-- =====================================================================
-- 第二阶段：数据完整性检查
-- =====================================================================

SELECT '🔍 第二阶段：数据完整性检查' as phase;

-- 检查目标用户是否存在
DO $$
DECLARE
    target_user_exists BOOLEAN;
    target_user_id UUID := 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d'::UUID;
BEGIN
    SELECT EXISTS(SELECT 1 FROM users WHERE id = target_user_id) INTO target_user_exists;
    
    IF target_user_exists THEN
        RAISE NOTICE '✅ 目标用户 % 存在', target_user_id;
    ELSE
        RAISE WARNING '❌ 目标用户 % 不存在！', target_user_id;
    END IF;
END $$;

-- 检查外键约束完整性
WITH orphaned_analytics AS (
    SELECT COUNT(*) as orphaned_count
    FROM user_analytics ua
    WHERE ua.user_id IS NOT NULL 
    AND ua.user_id NOT IN (SELECT id FROM users)
),
total_analytics AS (
    SELECT COUNT(*) as total_count
    FROM user_analytics
)
SELECT 
    '🔗 外键约束检查' as category,
    ta.total_count as total_analytics_records,
    oa.orphaned_count as orphaned_records,
    CASE 
        WHEN oa.orphaned_count = 0 THEN '✅ 无孤儿记录'
        ELSE '⚠️ 存在 ' || oa.orphaned_count || ' 个孤儿记录'
    END as constraint_status
FROM orphaned_analytics oa, total_analytics ta;

-- 检查phone字段唯一约束
WITH phone_conflicts AS (
    SELECT phone, COUNT(*) as duplicate_count
    FROM users 
    WHERE phone IS NOT NULL AND phone != ''
    GROUP BY phone
    HAVING COUNT(*) > 1
)
SELECT 
    '📱 phone字段约束检查' as category,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 无重复phone记录'
        ELSE '⚠️ 存在 ' || COUNT(*) || ' 个重复phone'
    END as phone_constraint_status,
    COUNT(*) as conflict_count
FROM phone_conflicts;

-- =====================================================================
-- 第三阶段：RLS策略检查
-- =====================================================================

SELECT '🔍 第三阶段：RLS策略检查' as phase;

-- 检查表RLS启用状态
SELECT 
    '🛡️ RLS启用状态' as category,
    tablename as table_name,
    CASE 
        WHEN rowsecurity THEN '✅ RLS已启用'
        ELSE '❌ RLS未启用'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'user_analytics')
ORDER BY tablename;

-- 检查策略数量
WITH policy_counts AS (
    SELECT 
        tablename,
        COUNT(*) as policy_count,
        STRING_AGG(policyname, ', ') as policy_names
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('users', 'user_analytics')
    GROUP BY tablename
)
SELECT 
    '📋 RLS策略统计' as category,
    tablename as table_name,
    policy_count,
    CASE 
        WHEN policy_count >= 3 THEN '✅ 策略充足'
        WHEN policy_count >= 1 THEN '⚠️ 策略偏少'
        ELSE '❌ 无策略'
    END as policy_status
FROM policy_counts
ORDER BY tablename;

-- =====================================================================
-- 第四阶段：性能索引检查
-- =====================================================================

SELECT '🔍 第四阶段：性能索引检查' as phase;

-- 检查关键索引
WITH index_check AS (
    SELECT 
        schemaname,
        tablename,
        indexname,
        indexdef
    FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND tablename IN ('users', 'user_analytics')
    AND indexname NOT LIKE '%_pkey'  -- 排除主键索引
)
SELECT 
    '🚀 性能索引检查' as category,
    tablename as table_name,
    COUNT(*) as index_count,
    CASE 
        WHEN COUNT(*) >= 3 THEN '✅ 索引充足'
        WHEN COUNT(*) >= 1 THEN '⚠️ 索引偏少'
        ELSE '❌ 缺少索引'
    END as index_status
FROM index_check
GROUP BY tablename
ORDER BY tablename;

-- =====================================================================
-- 第五阶段：功能测试
-- =====================================================================

SELECT '🔍 第五阶段：功能测试' as phase;

-- 测试插入埋点数据（不会实际提交）
DO $$
DECLARE
    test_user_id UUID := 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d'::UUID;
    test_session_id VARCHAR := 'consistency_test_' || extract(epoch from now())::integer;
    insert_success BOOLEAN := false;
BEGIN
    SAVEPOINT test_insert;
    
    BEGIN
        -- 尝试插入测试数据
        INSERT INTO user_analytics (
            user_id,
            event_type,
            event_data,
            session_id,
            page_name
        ) VALUES (
            test_user_id,
            'consistency_test',
            jsonb_build_object(
                'test_type', 'database_consistency',
                'timestamp', extract(epoch from now())
            ),
            test_session_id,
            'test_page'
        );
        
        insert_success := true;
        RAISE NOTICE '✅ 埋点数据插入测试成功';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '❌ 埋点数据插入测试失败: %', SQLERRM;
    END;
    
    -- 回滚测试数据，不保留在数据库中
    ROLLBACK TO test_insert;
    
    IF insert_success THEN
        RAISE NOTICE '🎯 功能测试通过：数据库可以正常接收埋点数据';
    ELSE
        RAISE WARNING '⚠️ 功能测试失败：埋点数据插入存在问题';
    END IF;
END $$;

-- =====================================================================
-- 第六阶段：数据统计和总结
-- =====================================================================

SELECT '🔍 第六阶段：数据统计和总结' as phase;

-- 用户数据统计
WITH user_stats AS (
    SELECT 
        COUNT(*) as total_users,
        COUNT(phone) as users_with_phone,
        COUNT(*) - COUNT(phone) as users_without_phone
    FROM users
),
analytics_stats AS (
    SELECT 
        COUNT(*) as total_analytics,
        COUNT(DISTINCT user_id) as unique_users_in_analytics,
        COUNT(DISTINCT session_id) as unique_sessions,
        COUNT(DISTINCT event_type) as unique_event_types
    FROM user_analytics
)
SELECT 
    '📊 数据统计总览' as category,
    us.total_users,
    us.users_with_phone,
    us.users_without_phone,
    asts.total_analytics,
    asts.unique_users_in_analytics,
    asts.unique_sessions,
    asts.unique_event_types
FROM user_stats us, analytics_stats asts;

-- 最近的埋点活动
SELECT 
    '📈 最近埋点活动' as category,
    event_type,
    COUNT(*) as event_count,
    MAX(created_at) as latest_event,
    MIN(created_at) as earliest_event
FROM user_analytics
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY event_type
ORDER BY event_count DESC
LIMIT 10;

-- =====================================================================
-- 最终验证报告
-- =====================================================================

DO $$
DECLARE
    total_issues INTEGER := 0;
    users_table_exists BOOLEAN;
    analytics_table_exists BOOLEAN;
    target_user_exists BOOLEAN;
    orphaned_records INTEGER;
    users_rls_enabled BOOLEAN;
    analytics_rls_enabled BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== 🎉 数据一致性检查完成报告 ===';
    
    -- 检查核心表
    SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') INTO users_table_exists;
    SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_analytics') INTO analytics_table_exists;
    
    -- 检查目标用户
    SELECT EXISTS(SELECT 1 FROM users WHERE id = 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d'::UUID) INTO target_user_exists;
    
    -- 检查孤儿记录
    SELECT COUNT(*) INTO orphaned_records FROM user_analytics ua WHERE ua.user_id IS NOT NULL AND ua.user_id NOT IN (SELECT id FROM users);
    
    -- 检查RLS状态
    SELECT rowsecurity INTO users_rls_enabled FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users';
    SELECT rowsecurity INTO analytics_rls_enabled FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_analytics';
    
    RAISE NOTICE '📋 检查结果:';
    RAISE NOTICE '• users表存在: %', CASE WHEN users_table_exists THEN '✅ YES' ELSE '❌ NO' END;
    RAISE NOTICE '• user_analytics表存在: %', CASE WHEN analytics_table_exists THEN '✅ YES' ELSE '❌ NO' END;
    RAISE NOTICE '• 目标用户存在: %', CASE WHEN target_user_exists THEN '✅ YES' ELSE '❌ NO' END;
    RAISE NOTICE '• 孤儿记录数量: %', orphaned_records;
    RAISE NOTICE '• users表RLS: %', CASE WHEN users_rls_enabled THEN '✅ 启用' ELSE '❌ 未启用' END;
    RAISE NOTICE '• analytics表RLS: %', CASE WHEN analytics_rls_enabled THEN '✅ 启用' ELSE '❌ 未启用' END;
    
    -- 统计问题
    IF NOT users_table_exists THEN total_issues := total_issues + 1; END IF;
    IF NOT analytics_table_exists THEN total_issues := total_issues + 1; END IF;
    IF NOT target_user_exists THEN total_issues := total_issues + 1; END IF;
    IF orphaned_records > 0 THEN total_issues := total_issues + 1; END IF;
    IF NOT users_rls_enabled THEN total_issues := total_issues + 1; END IF;
    IF NOT analytics_rls_enabled THEN total_issues := total_issues + 1; END IF;
    
    RAISE NOTICE '';
    IF total_issues = 0 THEN
        RAISE NOTICE '🎉 恭喜！数据库一致性检查全部通过！';
        RAISE NOTICE '🚀 首页-精选页埋点功能已完全修复，可以正常使用！';
    ELSE
        RAISE WARNING '⚠️ 发现 % 个问题需要解决', total_issues;
        RAISE NOTICE '建议重新执行主修复脚本或单独处理剩余问题';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 后续建议:';
    RAISE NOTICE '1. 重启Flutter应用测试埋点功能';
    RAISE NOTICE '2. 在应用中访问首页-精选页面';
    RAISE NOTICE '3. 检查Supabase控制台中的user_analytics表数据';
    RAISE NOTICE '4. 监控应用日志确保无错误';
    RAISE NOTICE '5. 定期运行此检查脚本维护数据一致性';
END $$;

-- 提供验证查询示例
SELECT 
    '🔍 验证查询示例' as info,
    '检查特定用户的埋点数据' as purpose,
    'SELECT event_type, event_data, created_at FROM user_analytics WHERE user_id = ''c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d''::UUID ORDER BY created_at DESC LIMIT 10;' as example_query
UNION ALL
SELECT 
    '🔍 验证查询示例' as info,
    '检查最近的埋点活动' as purpose,
    'SELECT event_type, COUNT(*) as count, MAX(created_at) as latest FROM user_analytics WHERE created_at >= NOW() - INTERVAL ''1 hour'' GROUP BY event_type;' as example_query;