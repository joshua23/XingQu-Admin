-- 星趣项目数据库性能测试SQL脚本
-- 测试各种查询场景的性能表现

-- 启用查询执行时间显示
\timing on

-- 启用查询计划显示
SET enable_seqscan = off; -- 强制使用索引

-- ===========================================
-- 1. 基础查询性能测试
-- ===========================================

-- 测试用户认证查询性能
EXPLAIN ANALYZE
SELECT id, email, raw_user_meta_data 
FROM auth.users 
WHERE email = 'test@example.com';

-- 测试记忆项目基础查询
EXPLAIN ANALYZE
SELECT * FROM memory_items 
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY created_at DESC 
LIMIT 20;

-- ===========================================
-- 2. 复杂关联查询性能测试
-- ===========================================

-- 测试记忆项目与分类的关联查询
EXPLAIN ANALYZE
SELECT 
    mi.id,
    mi.title,
    mi.content,
    mi.priority,
    mc.name as category_name,
    mc.color as category_color
FROM memory_items mi
LEFT JOIN memory_categories mc ON mi.category_id = mc.id
WHERE mi.user_id = '550e8400-e29b-41d4-a716-446655440000'
    AND mi.priority IN ('high', 'medium')
ORDER BY mi.updated_at DESC
LIMIT 50;

-- ===========================================
-- 3. 聚合查询性能测试
-- ===========================================

-- 测试记忆统计聚合查询
EXPLAIN ANALYZE
SELECT 
    COUNT(*) as total_memories,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) as high_priority,
    COUNT(CASE WHEN priority = 'medium' THEN 1 END) as medium_priority,
    COUNT(CASE WHEN priority = 'low' THEN 1 END) as low_priority,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_memories
FROM memory_items 
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000';

-- 测试订阅统计聚合查询
EXPLAIN ANALYZE
SELECT 
    s.status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (COALESCE(s.updated_at, s.created_at) - s.created_at))) as avg_duration_seconds
FROM subscriptions s
WHERE s.user_id = '550e8400-e29b-41d4-a716-446655440000'
GROUP BY s.status;

-- ===========================================
-- 4. 全文搜索性能测试
-- ===========================================

-- 测试记忆内容全文搜索
EXPLAIN ANALYZE
SELECT 
    id,
    title,
    content,
    ts_rank(search_vector, plainto_tsquery('chinese', '工作 项目')) as rank
FROM memory_items 
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
    AND search_vector @@ plainto_tsquery('chinese', '工作 项目')
ORDER BY rank DESC, updated_at DESC
LIMIT 20;

-- ===========================================
-- 5. 推荐系统查询性能测试
-- ===========================================

-- 测试协同过滤推荐查询
EXPLAIN ANALYZE
SELECT 
    ri.item_id,
    ri.item_type,
    ri.title,
    ri.description,
    AVG(ui.rating) as avg_rating,
    COUNT(ui.user_id) as interaction_count
FROM recommendation_items ri
LEFT JOIN user_interactions ui ON ri.item_id = ui.item_id
WHERE ri.category IN ('ai', 'tech', 'story')
    AND ri.status = 'active'
    AND ui.interaction_type IN ('like', 'share', 'favorite')
GROUP BY ri.item_id, ri.item_type, ri.title, ri.description
HAVING COUNT(ui.user_id) >= 5
ORDER BY avg_rating DESC, interaction_count DESC
LIMIT 10;

-- ===========================================
-- 6. 时间序列查询性能测试
-- ===========================================

-- 测试交互日志时间序列查询
EXPLAIN ANALYZE
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as interaction_count,
    COUNT(DISTINCT user_id) as unique_users
FROM interaction_logs 
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
    AND page_type = 'ai_interaction'
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour DESC;

-- ===========================================
-- 7. 数据更新性能测试
-- ===========================================

-- 测试批量更新性能
EXPLAIN ANALYZE
UPDATE memory_items 
SET last_accessed_at = NOW()
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
    AND last_accessed_at < CURRENT_DATE - INTERVAL '7 days';

-- ===========================================
-- 8. 索引效率检查
-- ===========================================

-- 检查索引使用情况
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes 
WHERE tablename IN (
    'memory_items', 'subscriptions', 'recommendation_items', 
    'user_interactions', 'interaction_logs'
)
ORDER BY idx_scan DESC;

-- 检查表扫描统计
SELECT 
    schemaname,
    tablename,
    seq_scan as sequential_scans,
    seq_tup_read as sequential_tuples_read,
    idx_scan as index_scans,
    idx_tup_fetch as index_tuples_fetched,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables 
WHERE tablename IN (
    'memory_items', 'subscriptions', 'recommendation_items', 
    'user_interactions', 'interaction_logs'
)
ORDER BY seq_scan DESC;

-- ===========================================
-- 9. 性能优化建议查询
-- ===========================================

-- 查找缺失的索引建议
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE query LIKE '%memory_items%' 
    OR query LIKE '%subscriptions%' 
    OR query LIKE '%recommendation_items%'
ORDER BY total_time DESC
LIMIT 10;

-- 查找慢查询
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    (total_time/calls) as avg_time_per_call
FROM pg_stat_statements 
WHERE mean_time > 100 -- 平均执行时间超过100ms的查询
ORDER BY mean_time DESC
LIMIT 20;

-- ===========================================
-- 10. 数据库连接和锁统计
-- ===========================================

-- 检查当前活跃连接
SELECT 
    count(*) as total_connections,
    count(*) FILTER (WHERE state = 'active') as active_connections,
    count(*) FILTER (WHERE state = 'idle') as idle_connections
FROM pg_stat_activity;

-- 检查锁等待情况
SELECT 
    pid,
    usename,
    query,
    state,
    wait_event_type,
    wait_event
FROM pg_stat_activity 
WHERE wait_event_type IS NOT NULL
    AND state = 'active';

-- ===========================================
-- 性能测试结果摘要
-- ===========================================

-- 创建性能测试结果表
CREATE TEMP TABLE performance_test_results (
    test_name TEXT,
    execution_time_ms NUMERIC,
    rows_returned INTEGER,
    index_used BOOLEAN,
    performance_grade TEXT
);

-- 插入测试结果（示例数据）
INSERT INTO performance_test_results VALUES
('用户认证查询', 2.5, 1, true, 'A'),
('记忆列表查询', 15.2, 20, true, 'A'),
('复杂关联查询', 45.8, 50, true, 'B'),
('聚合统计查询', 78.3, 1, true, 'B'),
('全文搜索查询', 120.5, 15, true, 'C'),
('推荐系统查询', 180.2, 10, true, 'C'),
('时间序列查询', 95.4, 168, true, 'B');

-- 显示性能测试摘要
SELECT 
    test_name,
    execution_time_ms,
    rows_returned,
    CASE 
        WHEN index_used THEN '✓' 
        ELSE '✗' 
    END as index_used,
    performance_grade,
    CASE 
        WHEN execution_time_ms < 50 THEN '快速'
        WHEN execution_time_ms < 200 THEN '正常'
        ELSE '需要优化'
    END as performance_status
FROM performance_test_results
ORDER BY execution_time_ms;

-- 关闭查询时间显示
\timing off

-- 性能测试完成提示
\echo '======================================'
\echo '数据库性能测试完成！'
\echo '======================================'
\echo '请检查上述查询的执行计划和时间'
\echo '关注以下指标：'
\echo '1. 查询执行时间 < 100ms (良好)'
\echo '2. 索引使用率 > 90%'
\echo '3. 扫描行数与返回行数比例'
\echo '4. 无长时间锁等待'
\echo '======================================';