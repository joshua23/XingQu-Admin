-- ============================================================================
-- Sprint 3 推荐系统API测试脚本
-- 验证推荐算法和用户反馈相关的所有API端点功能
-- ============================================================================

-- 测试1: 验证推荐算法配置
SELECT 
    'TEST 1: 推荐算法配置验证' as test_name,
    algorithm_name,
    algorithm_version,
    is_active,
    priority,
    target_user_types,
    content_types,
    jsonb_pretty(parameters) as parameters,
    jsonb_pretty(weights) as weights
FROM recommendation_configs
ORDER BY priority;

-- 预期结果: 应该有3个算法配置（collaborative_filtering, content_based, hybrid_premium）

-- 测试2: 创建测试用户和内容数据
DO $$
DECLARE
    test_user1_id UUID;
    test_user2_id UUID;
    test_character_id UUID;
    test_story_id UUID;
BEGIN
    -- 创建测试用户1 (免费用户)
    INSERT INTO users (phone, nickname, avatar_url) 
    VALUES ('13900000001', '推荐测试用户1', 'https://example.com/avatar1.png')
    ON CONFLICT (phone) DO UPDATE SET nickname = EXCLUDED.nickname
    RETURNING id INTO test_user1_id;
    
    -- 创建测试用户2 (会员用户)
    INSERT INTO users (phone, nickname, avatar_url) 
    VALUES ('13900000002', '推荐测试用户2', 'https://example.com/avatar2.png')
    ON CONFLICT (phone) DO UPDATE SET nickname = EXCLUDED.nickname
    RETURNING id INTO test_user2_id;
    
    -- 为用户2添加会员状态
    INSERT INTO user_memberships (
        user_id, 
        plan_id, 
        status, 
        started_at, 
        expires_at
    ) 
    SELECT 
        test_user2_id,
        sp.id,
        'active',
        NOW(),
        NOW() + INTERVAL '30 days'
    FROM subscription_plans sp 
    WHERE sp.plan_code = 'premium_yearly'
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'TEST 2: 测试用户创建完成 - 用户1: %, 用户2: %', test_user1_id, test_user2_id;
END $$;

-- 测试3: 模拟用户行为数据（推荐反馈）
DO $$
DECLARE
    test_user1_id UUID;
    test_user2_id UUID;
    feedback_id UUID;
BEGIN
    -- 获取测试用户ID
    SELECT id INTO test_user1_id FROM users WHERE phone = '13900000001';
    SELECT id INTO test_user2_id FROM users WHERE phone = '13900000002';
    
    -- 用户1的反馈数据（喜欢角色类内容）
    INSERT INTO recommendation_feedback (
        user_id, content_type, content_id, feedback_type, 
        feedback_value, session_id, page_context, position_in_list,
        display_duration_seconds, metadata
    ) VALUES 
    (test_user1_id, 'character', gen_random_uuid(), 'like', 1.0, gen_random_uuid(), 'home_feed', 1, 30, '{"source": "api_test"}'),
    (test_user1_id, 'character', gen_random_uuid(), 'view', 0.8, gen_random_uuid(), 'home_feed', 2, 15, '{"source": "api_test"}'),
    (test_user1_id, 'story', gen_random_uuid(), 'skip', 0.2, gen_random_uuid(), 'home_feed', 3, 2, '{"source": "api_test"}'),
    (test_user1_id, 'character', gen_random_uuid(), 'share', 1.0, gen_random_uuid(), 'discovery', 1, 45, '{"source": "api_test"}');
    
    -- 用户2的反馈数据（喜欢多种类型内容）
    INSERT INTO recommendation_feedback (
        user_id, content_type, content_id, feedback_type, 
        feedback_value, session_id, page_context, position_in_list,
        display_duration_seconds, metadata
    ) VALUES 
    (test_user2_id, 'character', gen_random_uuid(), 'like', 0.9, gen_random_uuid(), 'home_feed', 1, 60, '{"source": "api_test"}'),
    (test_user2_id, 'story', gen_random_uuid(), 'like', 0.85, gen_random_uuid(), 'home_feed', 2, 40, '{"source": "api_test"}'),
    (test_user2_id, 'audio', gen_random_uuid(), 'view', 0.7, gen_random_uuid(), 'fm_page', 1, 120, '{"source": "api_test"}'),
    (test_user2_id, 'agent', gen_random_uuid(), 'create', 1.0, gen_random_uuid(), 'agent_page', 1, 300, '{"source": "api_test"}');
    
    RAISE NOTICE 'TEST 3: 用户行为反馈数据创建完成';
END $$;

-- 测试4: 查询用户偏好分析API
SELECT 
    'TEST 4: 用户偏好分析' as test_name,
    u.nickname,
    rf.content_type,
    rf.feedback_type,
    COUNT(*) as feedback_count,
    AVG(rf.feedback_value) as avg_feedback_score,
    AVG(rf.display_duration_seconds) as avg_engagement_time
FROM users u
JOIN recommendation_feedback rf ON u.id = rf.user_id
WHERE u.phone IN ('13900000001', '13900000002')
GROUP BY u.id, u.nickname, rf.content_type, rf.feedback_type
ORDER BY u.nickname, rf.content_type, avg_feedback_score DESC;

-- 测试5: 基于内容类型的推荐API
SELECT 
    'TEST 5: 基于内容类型推荐' as test_name,
    content_type,
    COUNT(*) as interaction_count,
    STRING_AGG(DISTINCT feedback_type, ', ') as feedback_types,
    AVG(feedback_value) as avg_score
FROM recommendation_feedback
WHERE user_id = (SELECT id FROM users WHERE phone = '13900000001')
GROUP BY content_type
ORDER BY avg_score DESC;

-- 测试6: 协同过滤推荐算法测试
WITH user_similarity AS (
    SELECT 
        rf1.user_id as user1_id,
        rf2.user_id as user2_id,
        COUNT(*) as common_interactions,
        AVG(ABS(rf1.feedback_value - rf2.feedback_value)) as avg_difference
    FROM recommendation_feedback rf1
    JOIN recommendation_feedback rf2 ON rf1.content_type = rf2.content_type
    WHERE rf1.user_id != rf2.user_id
      AND rf1.user_id IN (SELECT id FROM users WHERE phone IN ('13900000001', '13900000002'))
      AND rf2.user_id IN (SELECT id FROM users WHERE phone IN ('13900000001', '13900000002'))
    GROUP BY rf1.user_id, rf2.user_id
    HAVING COUNT(*) > 0
)
SELECT 
    'TEST 6: 协同过滤相似度' as test_name,
    u1.nickname as user1,
    u2.nickname as user2,
    us.common_interactions,
    ROUND((1 - us.avg_difference)::NUMERIC, 3) as similarity_score
FROM user_similarity us
JOIN users u1 ON us.user1_id = u1.id
JOIN users u2 ON us.user2_id = u2.id
ORDER BY similarity_score DESC;

-- 测试7: 推荐结果个性化测试
CREATE TEMP TABLE mock_recommendations AS
SELECT 
    gen_random_uuid() as recommendation_id,
    u.id as user_id,
    'character' as content_type,
    gen_random_uuid() as content_id,
    'Mock角色_' || generate_series as title,
    CASE 
        WHEN u.phone = '13900000001' THEN 'collaborative_filtering'
        ELSE 'hybrid_premium'
    END as algorithm_used,
    CASE 
        WHEN u.phone = '13900000001' THEN 0.75 + random() * 0.2
        ELSE 0.85 + random() * 0.15
    END as confidence_score,
    '基于用户行为推荐' as reason
FROM users u
CROSS JOIN generate_series(1, 5)
WHERE u.phone IN ('13900000001', '13900000002');

SELECT 
    'TEST 7: 个性化推荐结果' as test_name,
    u.nickname,
    mr.algorithm_used,
    COUNT(*) as recommendation_count,
    AVG(mr.confidence_score) as avg_confidence,
    MIN(mr.confidence_score) as min_confidence,
    MAX(mr.confidence_score) as max_confidence
FROM mock_recommendations mr
JOIN users u ON mr.user_id = u.id
GROUP BY u.id, u.nickname, mr.algorithm_used
ORDER BY u.nickname;

-- 测试8: 推荐算法性能对比
SELECT 
    'TEST 8: 算法性能对比' as test_name,
    rc.algorithm_name,
    rc.priority,
    CASE 
        WHEN 'free' = ANY(rc.target_user_types) THEN '✓支持免费用户'
        ELSE '✗仅限付费用户'
    END as free_user_support,
    CASE 
        WHEN 'premium' = ANY(rc.target_user_types) THEN '✓支持高级用户'
        ELSE '✗不支持高级用户'
    END as premium_user_support,
    array_to_string(rc.content_types, ', ') as supported_content_types
FROM recommendation_configs rc
WHERE rc.is_active = true
ORDER BY rc.priority;

-- 测试9: 实时反馈API测试
DO $$
DECLARE
    test_user_id UUID;
    feedback_session_id UUID;
BEGIN
    SELECT id INTO test_user_id FROM users WHERE phone = '13900000001';
    SELECT gen_random_uuid() INTO feedback_session_id;
    
    -- 模拟实时反馈序列
    INSERT INTO recommendation_feedback (
        user_id, content_type, content_id, feedback_type, 
        feedback_value, session_id, page_context, position_in_list,
        display_duration_seconds, metadata
    ) VALUES 
    (test_user_id, 'character', gen_random_uuid(), 'impression', 0.5, feedback_session_id, 'recommendation_list', 1, 1, '{"real_time": true}'),
    (test_user_id, 'character', gen_random_uuid(), 'view', 0.8, feedback_session_id, 'recommendation_list', 1, 5, '{"real_time": true}'),
    (test_user_id, 'character', gen_random_uuid(), 'like', 1.0, feedback_session_id, 'recommendation_list', 1, 10, '{"real_time": true}');
    
    RAISE NOTICE 'TEST 9: 实时反馈序列创建完成，会话ID: %', feedback_session_id;
END $$;

-- 测试10: 会话级反馈分析
WITH latest_session AS (
    SELECT session_id 
    FROM recommendation_feedback 
    WHERE metadata @> '{"real_time": true}'
    ORDER BY created_at DESC 
    LIMIT 1
)
SELECT 
    'TEST 10: 会话级反馈分析' as test_name,
    rf.feedback_type,
    COUNT(*) as action_count,
    AVG(rf.feedback_value) as avg_score,
    SUM(rf.display_duration_seconds) as total_engagement_time
FROM recommendation_feedback rf
WHERE rf.session_id = (SELECT session_id FROM latest_session)
GROUP BY rf.feedback_type
ORDER BY avg_score DESC;

-- 测试11: 推荐效果评估API
SELECT 
    'TEST 11: 推荐效果评估' as test_name,
    DATE(rf.created_at) as feedback_date,
    rf.content_type,
    COUNT(*) as total_recommendations,
    COUNT(*) FILTER (WHERE rf.feedback_type = 'like') as liked_count,
    COUNT(*) FILTER (WHERE rf.feedback_type = 'share') as shared_count,
    COUNT(*) FILTER (WHERE rf.feedback_type = 'skip') as skipped_count,
    ROUND(
        COUNT(*) FILTER (WHERE rf.feedback_type IN ('like', 'share'))::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 
        2
    ) as engagement_rate_percent
FROM recommendation_feedback rf
WHERE rf.created_at >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY DATE(rf.created_at), rf.content_type
ORDER BY feedback_date DESC, engagement_rate_percent DESC;

-- 测试12: API性能测试
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.id,
    u.nickname,
    COUNT(rf.id) as total_feedback,
    AVG(rf.feedback_value) as avg_satisfaction,
    COUNT(DISTINCT rf.content_type) as content_diversity
FROM users u
LEFT JOIN recommendation_feedback rf ON u.id = rf.user_id
WHERE u.phone IN ('13900000001', '13900000002')
GROUP BY u.id, u.nickname;

-- 测试13: 清理测试数据
DO $$
DECLARE
    test_user1_id UUID;
    test_user2_id UUID;
BEGIN
    -- 获取测试用户ID
    SELECT id INTO test_user1_id FROM users WHERE phone = '13900000001';
    SELECT id INTO test_user2_id FROM users WHERE phone = '13900000002';
    
    -- 清理推荐反馈数据
    DELETE FROM recommendation_feedback 
    WHERE user_id IN (test_user1_id, test_user2_id);
    
    -- 清理会员状态
    DELETE FROM user_memberships 
    WHERE user_id IN (test_user1_id, test_user2_id);
    
    -- 清理测试用户
    DELETE FROM users WHERE phone IN ('13900000001', '13900000002');
    
    RAISE NOTICE 'TEST 13: 推荐系统测试数据清理完成';
END $$;

-- ============================================================================
-- 推荐系统API测试总结
-- ============================================================================
SELECT 
    'API测试总结' as summary,
    'recommendation_configs表' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE is_active = true) as active_algorithms
FROM recommendation_configs

UNION ALL

SELECT 
    'API测试总结' as summary,
    '今日推荐反馈数' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users
FROM recommendation_feedback
WHERE created_at >= CURRENT_DATE;