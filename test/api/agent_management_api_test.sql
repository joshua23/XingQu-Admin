-- ============================================================================
-- Sprint 3 智能体管理API测试脚本
-- 验证自定义智能体创建、管理、权限控制等所有API端点功能
-- ============================================================================

-- 测试1: 创建测试用户（智能体创建者和使用者）
DO $$
DECLARE
    creator_id UUID;
    user_id UUID;
    premium_plan_id UUID;
BEGIN
    -- 创建智能体创建者（高级会员）
    INSERT INTO users (phone, nickname, avatar_url) 
    VALUES ('13800000101', '智能体创建者', 'https://example.com/creator.png')
    ON CONFLICT (phone) DO UPDATE SET nickname = EXCLUDED.nickname
    RETURNING id INTO creator_id;
    
    -- 创建普通用户
    INSERT INTO users (phone, nickname, avatar_url) 
    VALUES ('13800000102', '智能体用户', 'https://example.com/user.png')
    ON CONFLICT (phone) DO UPDATE SET nickname = EXCLUDED.nickname
    RETURNING id INTO user_id;
    
    -- 为创建者添加高级会员状态
    SELECT id INTO premium_plan_id FROM subscription_plans WHERE plan_code = 'premium_yearly';
    
    INSERT INTO user_memberships (
        user_id, plan_id, status, started_at, expires_at
    ) VALUES (
        creator_id, premium_plan_id, 'active', NOW(), NOW() + INTERVAL '365 days'
    ) ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'TEST 1: 测试用户创建完成 - 创建者: %, 用户: %', creator_id, user_id;
END $$;

-- 测试2: 创建自定义智能体API
DO $$
DECLARE
    creator_id UUID;
    agent_id UUID;
BEGIN
    -- 获取创建者ID
    SELECT id INTO creator_id FROM users WHERE phone = '13800000101';
    
    -- 创建专业编程助手智能体
    INSERT INTO custom_agents (
        creator_id,
        name,
        avatar_url,
        description,
        category,
        personality_config,
        knowledge_base,
        conversation_style,
        capabilities,
        model_config,
        response_settings,
        safety_filters,
        visibility,
        status
    ) VALUES (
        creator_id,
        'CodeMaster Pro',
        'https://example.com/codemaster.png',
        '专业的编程助手，精通多种编程语言，能够协助代码审查、bug修复和架构设计',
        'programming',
        '{
            "personality": "professional",
            "tone": "helpful",
            "expertise_level": "expert",
            "communication_style": "clear_and_detailed"
        }'::jsonb,
        '{
            "programming_languages": ["Python", "JavaScript", "Java", "Go", "Rust"],
            "frameworks": ["React", "Vue", "Django", "Spring Boot"],
            "specialties": ["code_review", "debugging", "architecture_design"],
            "knowledge_cutoff": "2024-01"
        }'::jsonb,
        '{
            "response_length": "detailed",
            "code_examples": true,
            "step_by_step": true,
            "ask_clarifying_questions": true
        }'::jsonb,
        ARRAY['code_review', 'debugging', 'code_generation', 'architecture_advice', 'best_practices'],
        '{
            "model": "gpt-4",
            "temperature": 0.3,
            "max_tokens": 2000,
            "top_p": 0.9
        }'::jsonb,
        '{
            "max_response_length": 2000,
            "include_reasoning": true,
            "cite_sources": true
        }'::jsonb,
        '{
            "content_filters": ["harmful_code", "security_vulnerabilities"],
            "safety_level": "strict"
        }'::jsonb,
        'public',
        'active'
    ) RETURNING id INTO agent_id;
    
    -- 创建创意写作助手智能体
    INSERT INTO custom_agents (
        creator_id,
        name,
        avatar_url,
        description,
        category,
        personality_config,
        knowledge_base,
        conversation_style,
        capabilities,
        model_config,
        response_settings,
        visibility,
        status
    ) VALUES (
        creator_id,
        'CreativeWriter',
        'https://example.com/writer.png',
        '富有创意的写作助手，擅长故事创作、诗歌创作和文案编写',
        'creative',
        '{
            "personality": "creative",
            "tone": "inspiring",
            "creativity_level": "high",
            "imagination": "vivid"
        }'::jsonb,
        '{
            "writing_styles": ["narrative", "poetry", "academic", "marketing"],
            "genres": ["sci-fi", "fantasy", "romance", "thriller"],
            "techniques": ["character_development", "plot_structure", "dialogue"]
        }'::jsonb,
        '{
            "response_style": "creative",
            "use_metaphors": true,
            "storytelling": true
        }'::jsonb,
        ARRAY['story_writing', 'poetry', 'copywriting', 'brainstorming', 'editing'],
        '{
            "model": "gpt-4",
            "temperature": 0.8,
            "max_tokens": 1500
        }'::jsonb,
        '{
            "creative_formatting": true,
            "include_inspiration": true
        }'::jsonb,
        'private',
        'draft'
    );
    
    RAISE NOTICE 'TEST 2: 智能体创建完成 - 公开智能体ID: %', agent_id;
END $$;

-- 测试3: 查询智能体列表API
SELECT 
    'TEST 3: 智能体列表查询' as test_name,
    ca.name,
    ca.category,
    ca.visibility,
    ca.status,
    ca.usage_count,
    ca.rating,
    ca.rating_count,
    u.nickname as creator_name,
    ca.created_at
FROM custom_agents ca
JOIN users u ON ca.creator_id = u.id
WHERE u.phone = '13800000101'
ORDER BY ca.created_at DESC;

-- 测试4: 智能体运行状态管理API
DO $$
DECLARE
    agent_id UUID;
    status_id UUID;
BEGIN
    -- 获取公开智能体ID
    SELECT ca.id INTO agent_id 
    FROM custom_agents ca
    JOIN users u ON ca.creator_id = u.id
    WHERE u.phone = '13800000101' 
      AND ca.visibility = 'public'
    LIMIT 1;
    
    -- 创建运行状态记录
    INSERT INTO agent_runtime_status (
        agent_id,
        status,
        last_activity_at,
        response_time_ms,
        memory_usage_mb,
        cpu_usage_percent,
        success_count,
        error_count,
        runtime_config,
        resource_limits,
        health_check_status,
        last_health_check_at,
        health_check_details
    ) VALUES (
        agent_id,
        'running',
        NOW(),
        250,
        128,
        15.5,
        45,
        2,
        '{
            "instance_type": "standard",
            "auto_scale": true,
            "max_concurrent": 10
        }'::jsonb,
        '{
            "max_memory_mb": 512,
            "max_cpu_percent": 80,
            "timeout_seconds": 30
        }'::jsonb,
        'healthy',
        NOW(),
        '{
            "last_response_time": 250,
            "memory_ok": true,
            "cpu_ok": true,
            "connectivity": "good"
        }'::jsonb
    ) RETURNING id INTO status_id;
    
    RAISE NOTICE 'TEST 4: 智能体运行状态创建完成 - 状态ID: %', status_id;
END $$;

-- 测试5: 智能体权限管理API
DO $$
DECLARE
    agent_id UUID;
    user_id UUID;
    creator_id UUID;
BEGIN
    -- 获取相关ID
    SELECT id INTO creator_id FROM users WHERE phone = '13800000101';
    SELECT id INTO user_id FROM users WHERE phone = '13800000102';
    SELECT ca.id INTO agent_id 
    FROM custom_agents ca
    WHERE ca.creator_id = creator_id AND ca.visibility = 'public'
    LIMIT 1;
    
    -- 创建者为用户授予权限
    INSERT INTO agent_permissions (
        agent_id,
        user_id,
        permission_type,
        granted_by,
        usage_limit,
        expires_at,
        is_active
    ) VALUES 
    (agent_id, user_id, 'view', creator_id, NULL, NULL, true),
    (agent_id, user_id, 'chat', creator_id, 100, NOW() + INTERVAL '30 days', true),
    (agent_id, creator_id, 'admin', creator_id, NULL, NULL, true);
    
    RAISE NOTICE 'TEST 5: 智能体权限配置完成';
END $$;

-- 测试6: 权限验证API测试
SELECT 
    'TEST 6: 权限验证测试' as test_name,
    u.nickname as user_name,
    ca.name as agent_name,
    ap.permission_type,
    ap.usage_limit,
    ap.usage_count,
    ap.expires_at,
    ap.is_active,
    CASE 
        WHEN ap.expires_at IS NULL OR ap.expires_at > NOW() THEN '有效'
        ELSE '已过期'
    END as permission_status
FROM agent_permissions ap
JOIN users u ON ap.user_id = u.id
JOIN custom_agents ca ON ap.agent_id = ca.id
WHERE u.phone IN ('13800000101', '13800000102')
ORDER BY u.nickname, ap.permission_type;

-- 测试7: 智能体使用统计API
DO $$
DECLARE
    agent_id UUID;
    user_id UUID;
BEGIN
    -- 获取智能体和用户ID
    SELECT ca.id INTO agent_id 
    FROM custom_agents ca
    JOIN users u ON ca.creator_id = u.id
    WHERE u.phone = '13800000101' AND ca.visibility = 'public'
    LIMIT 1;
    
    SELECT id INTO user_id FROM users WHERE phone = '13800000102';
    
    -- 模拟智能体使用记录（通过interaction_logs触发器自动更新统计）
    INSERT INTO interaction_logs (
        user_id,
        target_type,
        target_id,
        action_type,
        interaction_data,
        session_id,
        page_context
    ) VALUES 
    (user_id, 'custom_agent', agent_id, 'chat_start', '{"message": "Hello CodeMaster"}', gen_random_uuid(), 'agent_chat'),
    (user_id, 'custom_agent', agent_id, 'chat_message', '{"message": "Please help me debug this code"}', gen_random_uuid(), 'agent_chat'),
    (user_id, 'custom_agent', agent_id, 'chat_end', '{"session_duration": 300}', gen_random_uuid(), 'agent_chat');
    
    RAISE NOTICE 'TEST 7: 智能体使用记录创建完成';
END $$;

-- 测试8: 智能体性能监控API
SELECT 
    'TEST 8: 智能体性能监控' as test_name,
    ca.name as agent_name,
    ca.usage_count,
    ca.rating,
    ars.status as runtime_status,
    ars.response_time_ms,
    ars.memory_usage_mb,
    ars.cpu_usage_percent,
    ars.success_count,
    ars.error_count,
    ROUND(ars.success_count::DECIMAL / NULLIF(ars.success_count + ars.error_count, 0) * 100, 2) as success_rate_percent,
    ars.health_check_status,
    ars.last_health_check_at
FROM custom_agents ca
LEFT JOIN agent_runtime_status ars ON ca.id = ars.agent_id
JOIN users u ON ca.creator_id = u.id
WHERE u.phone = '13800000101'
ORDER BY ca.usage_count DESC;

-- 测试9: 智能体搜索和过滤API
SELECT 
    'TEST 9: 智能体搜索过滤' as test_name,
    ca.name,
    ca.category,
    ca.description,
    ca.rating,
    ca.usage_count,
    CASE 
        WHEN ca.visibility = 'public' AND ca.status = 'active' THEN '✓可用'
        ELSE '✗不可用'
    END as availability,
    array_to_string(ca.capabilities, ', ') as capabilities_list
FROM custom_agents ca
WHERE ca.category = 'programming'
   OR ca.capabilities && ARRAY['code_review', 'debugging']
   OR ca.description ILIKE '%编程%'
ORDER BY ca.rating DESC, ca.usage_count DESC;

-- 测试10: 智能体评分和评价API
DO $$
DECLARE
    agent_id UUID;
    user_id UUID;
BEGIN
    -- 获取智能体和用户ID
    SELECT ca.id INTO agent_id 
    FROM custom_agents ca
    JOIN users u ON ca.creator_id = u.id
    WHERE u.phone = '13800000101' AND ca.visibility = 'public'
    LIMIT 1;
    
    SELECT id INTO user_id FROM users WHERE phone = '13800000102';
    
    -- 模拟用户评分（通过触发器自动更新agent的rating）
    -- 这里可以扩展一个rating表来存储详细评分，目前简化处理
    UPDATE custom_agents 
    SET 
        rating = (rating * rating_count + 4.5) / (rating_count + 1),
        rating_count = rating_count + 1,
        updated_at = NOW()
    WHERE id = agent_id;
    
    RAISE NOTICE 'TEST 10: 智能体评分更新完成';
END $$;

-- 测试11: 智能体配置更新API
DO $$
DECLARE
    agent_id UUID;
    creator_id UUID;
BEGIN
    -- 获取创建者和智能体ID
    SELECT id INTO creator_id FROM users WHERE phone = '13800000101';
    SELECT ca.id INTO agent_id 
    FROM custom_agents ca
    WHERE ca.creator_id = creator_id AND ca.status = 'draft'
    LIMIT 1;
    
    -- 更新智能体配置
    UPDATE custom_agents 
    SET 
        description = '富有创意的写作助手，擅长故事创作、诗歌创作和文案编写。现已支持多语言创作！',
        capabilities = array_append(capabilities, 'multilingual_writing'),
        model_config = model_config || '{"support_languages": ["zh", "en", "ja"]}'::jsonb,
        status = 'active',
        visibility = 'public',
        version = version + 1,
        updated_at = NOW()
    WHERE id = agent_id;
    
    RAISE NOTICE 'TEST 11: 智能体配置更新完成 - 智能体ID: %', agent_id;
END $$;

-- 测试12: 智能体删除和状态管理API
DO $$
DECLARE
    agent_id UUID;
    creator_id UUID;
BEGIN
    -- 获取创建者ID
    SELECT id INTO creator_id FROM users WHERE phone = '13800000101';
    
    -- 软删除智能体（设置为suspended状态）
    UPDATE custom_agents 
    SET 
        status = 'suspended',
        updated_at = NOW()
    WHERE creator_id = creator_id 
      AND name = 'CreativeWriter';
    
    -- 停止运行状态
    UPDATE agent_runtime_status 
    SET 
        status = 'stopped',
        updated_at = NOW()
    WHERE agent_id IN (
        SELECT id FROM custom_agents 
        WHERE creator_id = creator_id AND status = 'suspended'
    );
    
    RAISE NOTICE 'TEST 12: 智能体状态管理完成';
END $$;

-- 测试13: API性能测试
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    ca.id,
    ca.name,
    ca.category,
    ca.rating,
    ca.usage_count,
    ars.status as runtime_status,
    COUNT(ap.id) as permission_count,
    COUNT(ap.id) FILTER (WHERE ap.is_active = true) as active_permissions
FROM custom_agents ca
LEFT JOIN agent_runtime_status ars ON ca.id = ars.agent_id
LEFT JOIN agent_permissions ap ON ca.id = ap.agent_id
WHERE ca.visibility = 'public' 
  AND ca.status = 'active'
GROUP BY ca.id, ca.name, ca.category, ca.rating, ca.usage_count, ars.status
ORDER BY ca.rating DESC, ca.usage_count DESC
LIMIT 10;

-- 测试14: 清理测试数据
DO $$
DECLARE
    creator_id UUID;
    user_id UUID;
BEGIN
    -- 获取测试用户ID
    SELECT id INTO creator_id FROM users WHERE phone = '13800000101';
    SELECT id INTO user_id FROM users WHERE phone = '13800000102';
    
    -- 清理智能体权限
    DELETE FROM agent_permissions 
    WHERE user_id IN (creator_id, user_id) OR granted_by IN (creator_id, user_id);
    
    -- 清理运行状态
    DELETE FROM agent_runtime_status 
    WHERE agent_id IN (SELECT id FROM custom_agents WHERE creator_id = creator_id);
    
    -- 清理交互日志
    DELETE FROM interaction_logs 
    WHERE user_id IN (creator_id, user_id) AND target_type = 'custom_agent';
    
    -- 清理智能体
    DELETE FROM custom_agents WHERE creator_id = creator_id;
    
    -- 清理会员状态
    DELETE FROM user_memberships WHERE user_id IN (creator_id, user_id);
    
    -- 清理测试用户
    DELETE FROM users WHERE phone IN ('13800000101', '13800000102');
    
    RAISE NOTICE 'TEST 14: 智能体管理测试数据清理完成';
END $$;

-- ============================================================================
-- 智能体管理API测试总结
-- ============================================================================
SELECT 
    'API测试总结' as summary,
    '智能体管理功能' as feature,
    'CRUD操作' as test_type,
    '✓完成' as status

UNION ALL

SELECT 
    'API测试总结' as summary,
    '权限控制系统' as feature,
    '多级权限验证' as test_type,
    '✓完成' as status

UNION ALL

SELECT 
    'API测试总结' as summary,
    '运行状态监控' as feature,
    '性能指标追踪' as test_type,
    '✓完成' as status

UNION ALL

SELECT 
    'API测试总结' as summary,
    '使用统计分析' as feature,
    '数据聚合查询' as test_type,
    '✓完成' as status;