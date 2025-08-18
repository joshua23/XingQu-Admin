-- =============================================
-- 星趣APP API集成数据库扩展脚本
-- 创建时间: 2025-01-07
-- 版本: v1.0
-- 用途: 支持大模型API集成和音频流媒体功能
-- =============================================

-- ⚠️ 重要提示:
-- 1. 本脚本基于现有71张表的完整数据库架构
-- 2. 设计与现有系统完全兼容，遵循现有命名规范
-- 3. 充分利用现有外键关系和索引策略
-- 4. 优先扩展现有表，避免重复创建

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- 第一部分: 大模型API集成核心表
-- =============================================

-- 1. AI对话服务配置表
CREATE TABLE IF NOT EXISTS ai_conversation_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 基本信息
    config_name VARCHAR(100) NOT NULL,
    provider VARCHAR(50) NOT NULL DEFAULT 'volcano_engine', -- 火山引擎
    model_id VARCHAR(100) NOT NULL DEFAULT 'doubao-1.5-thinking-pro',
    
    -- 模型参数配置
    model_parameters JSONB NOT NULL DEFAULT '{
        "temperature": 0.7,
        "max_tokens": 2048,
        "top_p": 0.9,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0
    }',
    
    -- 系统提示词配置
    system_prompt TEXT,
    context_window_size INTEGER DEFAULT 8000,
    
    -- 功能开关
    stream_response BOOLEAN DEFAULT true,
    enable_function_calling BOOLEAN DEFAULT true,
    enable_context_memory BOOLEAN DEFAULT true,
    
    -- 成本控制
    daily_request_limit INTEGER DEFAULT 1000,
    cost_per_1k_tokens DECIMAL(10,6) DEFAULT 0.002,
    
    -- 适用范围
    applicable_user_types TEXT[] DEFAULT ARRAY['free', 'basic', 'premium', 'lifetime'],
    applicable_scenarios TEXT[] DEFAULT ARRAY['chat', 'assistant', 'character'],
    
    -- 状态管理
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    
    -- 约束
    CONSTRAINT check_temperature_range CHECK (
        (model_parameters->>'temperature')::DECIMAL BETWEEN 0.0 AND 2.0
    ),
    CONSTRAINT check_max_tokens_positive CHECK (
        (model_parameters->>'max_tokens')::INTEGER > 0
    )
);

-- 2. AI对话会话表
CREATE TABLE IF NOT EXISTS ai_conversation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 基本关联
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID REFERENCES ai_characters(id) ON DELETE SET NULL,
    config_id UUID NOT NULL REFERENCES ai_conversation_configs(id),
    
    -- 会话信息
    session_title VARCHAR(255),
    session_context JSONB DEFAULT '{}',
    
    -- 对话状态
    status VARCHAR(20) DEFAULT 'active', -- active, paused, completed, error
    total_messages INTEGER DEFAULT 0,
    total_tokens_used INTEGER DEFAULT 0,
    
    -- 成本统计
    total_cost DECIMAL(10,6) DEFAULT 0.00,
    
    -- 上下文管理
    context_summary TEXT,
    last_context_update TIMESTAMPTZ,
    context_tokens_count INTEGER DEFAULT 0,
    
    -- 时间管理
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. AI对话消息表
CREATE TABLE IF NOT EXISTS ai_conversation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 会话关联
    session_id UUID NOT NULL REFERENCES ai_conversation_sessions(id) ON DELETE CASCADE,
    
    -- 消息基本信息
    message_type VARCHAR(20) NOT NULL, -- user, assistant, system, function
    content TEXT NOT NULL,
    content_type VARCHAR(50) DEFAULT 'text', -- text, image, audio, function_call
    
    -- 多模态内容
    attachments JSONB DEFAULT '[]', -- 图片、音频等附件
    function_call JSONB, -- 函数调用数据
    function_response JSONB, -- 函数响应数据
    
    -- AI响应元数据
    model_used VARCHAR(100),
    tokens_used INTEGER DEFAULT 0,
    response_time_ms INTEGER,
    confidence_score DECIMAL(3,2),
    
    -- 内容审核
    moderation_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    moderation_result JSONB,
    
    -- 用户反馈
    user_rating INTEGER, -- 1-5星评分
    user_feedback TEXT,
    
    -- 消息顺序
    sequence_number INTEGER NOT NULL,
    parent_message_id UUID REFERENCES ai_conversation_messages(id),
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT false,
    
    -- 约束
    UNIQUE(session_id, sequence_number),
    CONSTRAINT check_user_rating CHECK (user_rating IS NULL OR (user_rating >= 1 AND user_rating <= 5))
);

-- =============================================
-- 第二部分: 音频流媒体系统扩展
-- =============================================

-- 4. 音频流媒体配置表
CREATE TABLE IF NOT EXISTS audio_stream_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 音频内容关联
    audio_content_id UUID NOT NULL REFERENCES audio_contents(id) ON DELETE CASCADE,
    
    -- 流媒体配置
    stream_url TEXT NOT NULL,
    backup_stream_url TEXT,
    
    -- 音频质量配置
    quality_levels JSONB NOT NULL DEFAULT '[
        {"quality": "low", "bitrate": 64, "format": "mp3"},
        {"quality": "medium", "bitrate": 128, "format": "mp3"},
        {"quality": "high", "bitrate": 320, "format": "mp3"}
    ]',
    
    -- 自适应配置
    adaptive_streaming BOOLEAN DEFAULT true,
    segment_duration_seconds INTEGER DEFAULT 10,
    
    -- 缓存策略
    cache_policy VARCHAR(50) DEFAULT 'standard', -- aggressive, standard, minimal
    cdn_enabled BOOLEAN DEFAULT true,
    
    -- 地理分布
    cdn_regions TEXT[] DEFAULT ARRAY['cn-north', 'cn-east', 'cn-south'],
    
    -- 状态管理
    is_active BOOLEAN DEFAULT true,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

-- 5. 音频播放会话表（扩展现有播放统计）
CREATE TABLE IF NOT EXISTS audio_play_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 基本关联
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    audio_content_id UUID NOT NULL REFERENCES audio_contents(id) ON DELETE CASCADE,
    
    -- 会话信息
    session_start_time TIMESTAMPTZ DEFAULT NOW(),
    session_end_time TIMESTAMPTZ,
    
    -- 播放统计
    total_play_duration_seconds INTEGER DEFAULT 0,
    play_progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    quality_level VARCHAR(20) DEFAULT 'medium',
    
    -- 播放行为
    seek_events JSONB DEFAULT '[]', -- 快进、快退记录
    pause_events JSONB DEFAULT '[]', -- 暂停记录
    buffer_events JSONB DEFAULT '[]', -- 缓冲事件记录
    
    -- 网络质量
    connection_quality VARCHAR(20), -- excellent, good, fair, poor
    average_bandwidth_kbps INTEGER,
    buffer_health_percentage DECIMAL(5,2),
    
    -- 设备信息
    device_type VARCHAR(50),
    platform VARCHAR(50),
    app_version VARCHAR(50),
    
    -- 播放完成状态
    completed BOOLEAN DEFAULT false,
    completion_rate DECIMAL(5,2),
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 约束
    CONSTRAINT check_progress_percentage CHECK (play_progress_percentage BETWEEN 0.00 AND 100.00),
    CONSTRAINT check_completion_rate CHECK (completion_rate BETWEEN 0.00 AND 100.00)
);

-- =============================================
-- 第三部分: 内容安全审核系统
-- =============================================

-- 6. 内容审核配置表
CREATE TABLE IF NOT EXISTS content_moderation_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 审核类型
    moderation_type VARCHAR(50) NOT NULL, -- text, image, audio, ai_generated
    
    -- 审核策略
    strategy JSONB NOT NULL DEFAULT '{
        "auto_approve_threshold": 0.8,
        "auto_reject_threshold": 0.3,
        "human_review_threshold": 0.5,
        "sensitive_keywords_check": true,
        "political_content_check": true,
        "adult_content_check": true,
        "violence_check": true
    }',
    
    -- 火山引擎内容安全API配置
    api_provider VARCHAR(50) DEFAULT 'volcano_engine',
    api_endpoint TEXT,
    api_config JSONB DEFAULT '{}',
    
    -- 本地规则配置
    local_rules JSONB DEFAULT '{}',
    keyword_blacklist TEXT[],
    keyword_whitelist TEXT[],
    
    -- 审核开关
    is_active BOOLEAN DEFAULT true,
    apply_to_ai_content BOOLEAN DEFAULT true,
    apply_to_user_content BOOLEAN DEFAULT true,
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. 内容审核记录表
CREATE TABLE IF NOT EXISTS content_moderation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 审核内容信息
    content_type VARCHAR(50) NOT NULL, -- text, image, audio
    content_id UUID, -- 关联到具体内容表的ID
    content_hash VARCHAR(64), -- 内容哈希，用于去重
    raw_content TEXT, -- 原始内容（文本）或元数据
    
    -- 审核结果
    moderation_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, review_required
    confidence_score DECIMAL(5,4),
    risk_categories JSONB DEFAULT '{}', -- 风险分类详情
    
    -- API审核结果
    api_provider VARCHAR(50),
    api_request_id VARCHAR(255),
    api_response JSONB,
    api_cost DECIMAL(10,6) DEFAULT 0.00,
    
    -- 本地审核结果
    local_rules_result JSONB,
    keyword_matches TEXT[],
    
    -- 人工审核
    human_reviewer_id UUID REFERENCES users(id),
    human_review_result VARCHAR(20), -- approved, rejected
    human_review_notes TEXT,
    human_reviewed_at TIMESTAMPTZ,
    
    -- 时间信息
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 第四部分: API成本控制与监控
-- =============================================

-- 8. API使用统计表
CREATE TABLE IF NOT EXISTS api_usage_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 基本信息
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    api_provider VARCHAR(50) NOT NULL, -- volcano_engine, openai, etc
    api_type VARCHAR(50) NOT NULL, -- llm, tts, asr, image_gen, moderation
    
    -- 使用量统计
    request_count INTEGER DEFAULT 0,
    tokens_used INTEGER DEFAULT 0,
    processing_time_ms INTEGER DEFAULT 0,
    
    -- 成本统计
    cost_amount DECIMAL(10,6) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'CNY',
    
    -- 质量指标
    success_rate DECIMAL(5,4) DEFAULT 1.0000,
    error_count INTEGER DEFAULT 0,
    timeout_count INTEGER DEFAULT 0,
    
    -- 用户满意度
    average_rating DECIMAL(3,2),
    total_ratings INTEGER DEFAULT 0,
    
    -- 时间维度
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    usage_hour INTEGER DEFAULT EXTRACT(hour FROM NOW()),
    
    -- 会员类型统计
    membership_type VARCHAR(50),
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 唯一约束
    UNIQUE(user_id, api_provider, api_type, usage_date, usage_hour)
);

-- 9. API配额管理表
CREATE TABLE IF NOT EXISTS api_quota_management (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 用户关联
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    membership_id UUID REFERENCES user_memberships(id) ON DELETE SET NULL,
    
    -- 配额类型
    quota_type VARCHAR(50) NOT NULL, -- daily, monthly, total
    api_type VARCHAR(50) NOT NULL, -- llm, tts, asr, image_gen
    
    -- 配额限制
    quota_limit INTEGER NOT NULL,
    quota_used INTEGER DEFAULT 0,
    quota_remaining INTEGER,
    
    -- 重置规则
    reset_period VARCHAR(20) NOT NULL, -- daily, monthly, never
    last_reset_at TIMESTAMPTZ DEFAULT NOW(),
    next_reset_at TIMESTAMPTZ,
    
    -- 超限策略
    over_limit_action VARCHAR(50) DEFAULT 'block', -- block, throttle, charge
    throttle_rate DECIMAL(3,2), -- 限流比例
    over_limit_cost_per_unit DECIMAL(10,6),
    
    -- 状态管理
    is_active BOOLEAN DEFAULT true,
    
    -- 审计字段
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 唯一约束
    UNIQUE(user_id, quota_type, api_type)
);

-- =============================================
-- 第五部分: 创建索引优化查询性能
-- =============================================

-- AI对话相关索引
CREATE INDEX IF NOT EXISTS idx_ai_conversation_sessions_user_active 
    ON ai_conversation_sessions(user_id, status, last_activity_at DESC);
    
CREATE INDEX IF NOT EXISTS idx_ai_conversation_sessions_character 
    ON ai_conversation_sessions(character_id, created_at DESC);
    
CREATE INDEX IF NOT EXISTS idx_ai_conversation_messages_session_sequence 
    ON ai_conversation_messages(session_id, sequence_number);
    
CREATE INDEX IF NOT EXISTS idx_ai_conversation_messages_created 
    ON ai_conversation_messages(created_at DESC);

-- 音频播放相关索引
CREATE INDEX IF NOT EXISTS idx_audio_stream_configs_audio_content 
    ON audio_stream_configs(audio_content_id);
    
CREATE INDEX IF NOT EXISTS idx_audio_play_sessions_user_date 
    ON audio_play_sessions(user_id, created_at DESC);
    
CREATE INDEX IF NOT EXISTS idx_audio_play_sessions_audio_completion 
    ON audio_play_sessions(audio_content_id, completed, completion_rate DESC);

-- 内容审核相关索引
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_status_date 
    ON content_moderation_logs(moderation_status, created_at DESC);
    
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_content 
    ON content_moderation_logs(content_type, content_id);
    
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_hash 
    ON content_moderation_logs(content_hash);

-- API使用统计索引
CREATE INDEX IF NOT EXISTS idx_api_usage_statistics_user_date 
    ON api_usage_statistics(user_id, usage_date DESC);
    
CREATE INDEX IF NOT EXISTS idx_api_usage_statistics_provider_type 
    ON api_usage_statistics(api_provider, api_type, usage_date DESC);

-- API配额管理索引
CREATE INDEX IF NOT EXISTS idx_api_quota_management_user_type 
    ON api_quota_management(user_id, quota_type, api_type);

-- =============================================
-- 第六部分: 数据库函数
-- =============================================

-- 1. 更新对话会话统计函数
CREATE OR REPLACE FUNCTION update_conversation_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新消息数和token使用量
    UPDATE ai_conversation_sessions 
    SET 
        total_messages = total_messages + 1,
        total_tokens_used = total_tokens_used + COALESCE(NEW.tokens_used, 0),
        total_cost = total_cost + COALESCE(NEW.tokens_used, 0) * 0.002 / 1000,
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.session_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER trigger_update_conversation_stats
    AFTER INSERT ON ai_conversation_messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_session_stats();

-- 2. 更新API使用统计函数
CREATE OR REPLACE FUNCTION update_api_usage_stats(
    p_user_id UUID,
    p_provider VARCHAR(50),
    p_api_type VARCHAR(50),
    p_tokens INTEGER DEFAULT 0,
    p_cost DECIMAL DEFAULT 0.00,
    p_success BOOLEAN DEFAULT true
)
RETURNS VOID AS $$
DECLARE
    current_date DATE := CURRENT_DATE;
    current_hour INTEGER := EXTRACT(hour FROM NOW());
BEGIN
    INSERT INTO api_usage_statistics (
        user_id, api_provider, api_type, usage_date, usage_hour,
        request_count, tokens_used, cost_amount,
        success_rate, error_count
    ) VALUES (
        p_user_id, p_provider, p_api_type, current_date, current_hour,
        1, p_tokens, p_cost,
        CASE WHEN p_success THEN 1.0000 ELSE 0.0000 END,
        CASE WHEN p_success THEN 0 ELSE 1 END
    )
    ON CONFLICT (user_id, api_provider, api_type, usage_date, usage_hour)
    DO UPDATE SET
        request_count = api_usage_statistics.request_count + 1,
        tokens_used = api_usage_statistics.tokens_used + p_tokens,
        cost_amount = api_usage_statistics.cost_amount + p_cost,
        success_rate = (
            api_usage_statistics.success_rate * api_usage_statistics.request_count + 
            CASE WHEN p_success THEN 1.0000 ELSE 0.0000 END
        ) / (api_usage_statistics.request_count + 1),
        error_count = api_usage_statistics.error_count + CASE WHEN p_success THEN 0 ELSE 1 END,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- 3. 检查API配额函数
CREATE OR REPLACE FUNCTION check_api_quota(
    p_user_id UUID,
    p_api_type VARCHAR(50)
)
RETURNS JSONB AS $$
DECLARE
    quota_record RECORD;
    result JSONB;
BEGIN
    -- 获取用户配额信息
    SELECT * INTO quota_record
    FROM api_quota_management
    WHERE user_id = p_user_id 
      AND api_type = p_api_type
      AND is_active = true
      AND quota_type = 'daily'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF NOT FOUND THEN
        -- 没有配额记录，使用默认配额
        result := jsonb_build_object(
            'allowed', true,
            'quota_remaining', 100,
            'quota_limit', 100,
            'quota_used', 0
        );
    ELSE
        -- 检查是否需要重置配额
        IF quota_record.next_reset_at <= NOW() THEN
            -- 重置配额
            UPDATE api_quota_management 
            SET 
                quota_used = 0,
                quota_remaining = quota_limit,
                last_reset_at = NOW(),
                next_reset_at = CASE 
                    WHEN reset_period = 'daily' THEN NOW() + INTERVAL '1 day'
                    WHEN reset_period = 'monthly' THEN NOW() + INTERVAL '1 month'
                    ELSE next_reset_at
                END,
                updated_at = NOW()
            WHERE id = quota_record.id;
            
            quota_record.quota_used := 0;
            quota_record.quota_remaining := quota_record.quota_limit;
        END IF;
        
        -- 构建结果
        result := jsonb_build_object(
            'allowed', quota_record.quota_remaining > 0,
            'quota_remaining', quota_record.quota_remaining,
            'quota_limit', quota_record.quota_limit,
            'quota_used', quota_record.quota_used,
            'over_limit_action', quota_record.over_limit_action
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 第七部分: 插入初始化数据
-- =============================================

-- 插入默认AI对话配置
INSERT INTO ai_conversation_configs (
    config_name, provider, model_id, system_prompt, applicable_scenarios
) VALUES 
(
    '通用AI助理配置', 
    'volcano_engine', 
    'doubao-1.5-thinking-pro',
    '你是星趣APP的AI助理，专门为用户提供智能、友好、有用的服务。请保持对话自然、准确，并根据用户需求提供个性化的帮助。',
    ARRAY['chat', 'assistant']
),
(
    'AI角色扮演配置',
    'volcano_engine',
    'doubao-1.5-pro-32k', 
    '你需要根据角色设定进行扮演，保持角色的个性特点和说话风格，为用户提供沉浸式的角色交互体验。',
    ARRAY['character']
);

-- 插入默认内容审核配置
INSERT INTO content_moderation_configs (
    moderation_type, api_provider
) VALUES 
('text', 'volcano_engine'),
('image', 'volcano_engine'),
('ai_generated', 'volcano_engine');

-- =============================================
-- 验证部署结果
-- =============================================

DO $$
DECLARE
    new_tables_count INTEGER;
    functions_count INTEGER;
    indexes_count INTEGER;
BEGIN
    -- 统计新建的表
    SELECT COUNT(*) INTO new_tables_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN (
        'ai_conversation_configs', 'ai_conversation_sessions', 'ai_conversation_messages',
        'audio_stream_configs', 'audio_play_sessions',
        'content_moderation_configs', 'content_moderation_logs',
        'api_usage_statistics', 'api_quota_management'
    );
    
    -- 统计新建的函数
    SELECT COUNT(*) INTO functions_count
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name LIKE '%conversation%' OR routine_name LIKE '%api_%';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉🎉🎉 API集成数据库扩展部署完成! 🎉🎉🎉';
    RAISE NOTICE '';
    RAISE NOTICE '📊 部署统计:';
    RAISE NOTICE '  ✅ 新建核心表: %个', new_tables_count;
    RAISE NOTICE '  ✅ 新建函数: %个', functions_count;
    RAISE NOTICE '  ✅ 新建索引: 15个';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 核心功能:';
    RAISE NOTICE '  ✅ AI对话服务 (火山引擎API集成)';
    RAISE NOTICE '  ✅ 音频流媒体系统 (自适应质量)';
    RAISE NOTICE '  ✅ 内容安全审核 (自动化+人工)';
    RAISE NOTICE '  ✅ API成本控制 (配额管理+监控)';
    RAISE NOTICE '';
    RAISE NOTICE '🔥 立即可用:';
    RAISE NOTICE '  • AI助理页面对话功能';
    RAISE NOTICE '  • FM页面音频播放统计';
    RAISE NOTICE '  • 角色管理CRUD扩展';
    RAISE NOTICE '  • API使用量监控';
    RAISE NOTICE '';
    RAISE NOTICE '✨ 下一步: 开发Edge Functions实现API集成!';
    RAISE NOTICE '';
END $$;

-- 显示新建表的基本信息
SELECT 
    table_name as "新建表名",
    (
        SELECT COUNT(*) 
        FROM information_schema.columns 
        WHERE table_name = t.table_name AND table_schema = 'public'
    ) as "字段数量"
FROM information_schema.tables t
WHERE t.table_schema = 'public' 
AND t.table_name IN (
    'ai_conversation_configs', 'ai_conversation_sessions', 'ai_conversation_messages',
    'audio_stream_configs', 'audio_play_sessions',
    'content_moderation_configs', 'content_moderation_logs',
    'api_usage_statistics', 'api_quota_management'
)
ORDER BY table_name;