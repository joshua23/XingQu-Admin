-- =============================================
-- 埋点数据验证SQL脚本
-- 用于验证埋点测试数据是否成功写入Supabase
-- =============================================

-- 1. 检查user_analytics表是否存在并有数据
SELECT 
    'user_analytics表状态' as check_item,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 表存在且有数据'
        ELSE '❌ 表存在但无数据'
    END as status,
    COUNT(*) as total_records
FROM user_analytics;

-- 2. 查看最近24小时的埋点数据
SELECT 
    '最近24小时埋点数据' as period,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions
FROM user_analytics
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- 3. 查看最近的测试数据（带test标记的）
SELECT 
    event_type,
    session_id,
    (event_data->>'source')::text as source,
    (event_data->>'test_type')::text as test_type,
    created_at
FROM user_analytics
WHERE 
    session_id LIKE 'test_%' 
    OR (event_data->>'source')::text IN ('test_script', 'analytics_test', 'featured_page')
    OR (event_data->>'test_type')::text IS NOT NULL
ORDER BY created_at DESC
LIMIT 20;

-- 4. 查看首页-精选页相关的埋点数据
SELECT 
    event_type,
    COUNT(*) as count,
    MAX(created_at) as last_event_time
FROM user_analytics
WHERE 
    (event_data->>'page_name')::text = 'home_selection_page'
    OR (event_data->>'source')::text = 'featured_page'
    OR event_type IN ('page_view', 'social_interaction', 'character_interaction')
GROUP BY event_type
ORDER BY count DESC;

-- 5. 查看社交互动埋点详情（点赞、关注等）
SELECT 
    event_type,
    (event_data->>'actionType')::text as action_type,
    (event_data->>'targetType')::text as target_type,
    (event_data->>'character_name')::text as character_name,
    created_at
FROM user_analytics
WHERE 
    event_type = 'social_interaction'
    OR (event_data->>'actionType')::text IN ('like', 'follow', 'share')
ORDER BY created_at DESC
LIMIT 10;

-- 6. 统计各类埋点事件的数量
SELECT 
    event_type,
    COUNT(*) as total_count,
    COUNT(DISTINCT user_id) as unique_users,
    MIN(created_at) as first_event,
    MAX(created_at) as last_event
FROM user_analytics
GROUP BY event_type
ORDER BY total_count DESC;

-- 7. 查看批量上报的测试数据
SELECT 
    event_type,
    session_id,
    (event_data->>'index')::int as batch_index,
    created_at
FROM user_analytics
WHERE 
    event_type LIKE 'test_batch_%'
    OR event_type LIKE 'batch_test_%'
ORDER BY created_at DESC
LIMIT 10;

-- 8. 验证数据完整性
SELECT 
    '数据完整性检查' as check_type,
    COUNT(*) as total_records,
    COUNT(user_id) as records_with_user,
    COUNT(event_type) as records_with_type,
    COUNT(event_data) as records_with_data,
    COUNT(session_id) as records_with_session
FROM user_analytics
WHERE created_at >= NOW() - INTERVAL '1 hour';

-- 9. 查看特定测试会话的所有事件
-- 注意：将下面的 'test_XXXXXXXXX' 替换为实际的测试会话ID
/*
SELECT 
    event_type,
    event_data,
    created_at
FROM user_analytics
WHERE session_id = 'test_1736284800000'  -- 替换为实际的session_id
ORDER BY created_at ASC;
*/

-- 10. 生成测试报告摘要
WITH test_summary AS (
    SELECT 
        COUNT(*) as total_events,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT session_id) as unique_sessions,
        COUNT(DISTINCT event_type) as event_types,
        MIN(created_at) as first_event_time,
        MAX(created_at) as last_event_time
    FROM user_analytics
    WHERE created_at >= NOW() - INTERVAL '1 hour'
)
SELECT 
    '📊 埋点测试验证报告' as report_title,
    CASE 
        WHEN total_events > 0 THEN '✅ 测试通过'
        ELSE '❌ 无测试数据'
    END as test_status,
    total_events,
    unique_users,
    unique_sessions,
    event_types,
    first_event_time,
    last_event_time,
    EXTRACT(EPOCH FROM (last_event_time - first_event_time)) as duration_seconds
FROM test_summary;