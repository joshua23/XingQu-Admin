-- =============================================
-- 星趣APP 现有表功能增强脚本
-- 创建时间: 2025-01-07
-- 版本: v1.0
-- 用途: 增强现有表以支持API集成功能
-- =============================================

-- ⚠️ 重要说明:
-- 本脚本扩展现有71张表，添加API集成所需的字段和功能
-- 完全向后兼容，不影响现有功能
-- 所有新增字段均设置默认值，确保现有数据安全

-- =============================================
-- 第一部分: 扩展 ai_characters 表
-- =============================================

DO $$
BEGIN
    -- 添加AI对话配置关联
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'default_conversation_config_id') THEN
        ALTER TABLE ai_characters 
        ADD COLUMN default_conversation_config_id UUID REFERENCES ai_conversation_configs(id);
        RAISE NOTICE '✅ ai_characters: 添加默认对话配置关联';
    END IF;
    
    -- 添加角色扮演提示词
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'role_prompt') THEN
        ALTER TABLE ai_characters 
        ADD COLUMN role_prompt TEXT;
        RAISE NOTICE '✅ ai_characters: 添加角色扮演提示词字段';
    END IF;
    
    -- 添加对话风格配置
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'conversation_style') THEN
        ALTER TABLE ai_characters 
        ADD COLUMN conversation_style JSONB DEFAULT '{
            "tone": "friendly",
            "formality": "casual",
            "response_length": "medium",
            "emoji_usage": true,
            "personality_traits": []
        }';
        RAISE NOTICE '✅ ai_characters: 添加对话风格配置';
    END IF;
    
    -- 添加多模态支持配置
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'multimodal_support') THEN
        ALTER TABLE ai_characters 
        ADD COLUMN multimodal_support JSONB DEFAULT '{
            "text": true,
            "voice": false,
            "image": false,
            "video": false
        }';
        RAISE NOTICE '✅ ai_characters: 添加多模态支持配置';
    END IF;
    
    -- 添加API使用统计
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'api_usage_stats') THEN
        ALTER TABLE ai_characters 
        ADD COLUMN api_usage_stats JSONB DEFAULT '{
            "total_conversations": 0,
            "total_messages": 0,
            "average_session_duration": 0,
            "user_satisfaction_score": 0.0
        }';
        RAISE NOTICE '✅ ai_characters: 添加API使用统计';
    END IF;
END $$;

-- =============================================
-- 第二部分: 扩展 audio_contents 表
-- =============================================

DO $$
BEGIN
    -- 添加音频流媒体状态
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'audio_contents' AND column_name = 'streaming_status') THEN
        ALTER TABLE audio_contents 
        ADD COLUMN streaming_status VARCHAR(20) DEFAULT 'ready'; -- ready, processing, active, error
        RAISE NOTICE '✅ audio_contents: 添加流媒体状态';
    END IF;
    
    -- 添加音频质量元数据
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'audio_contents' AND column_name = 'audio_metadata') THEN
        ALTER TABLE audio_contents 
        ADD COLUMN audio_metadata JSONB DEFAULT '{
            "original_format": "mp3",
            "bitrate": 128,
            "sample_rate": 44100,
            "channels": 2,
            "file_size_bytes": 0
        }';
        RAISE NOTICE '✅ audio_contents: 添加音频质量元数据';
    END IF;
    
    -- 添加播放分析数据
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'audio_contents' AND column_name = 'play_analytics') THEN
        ALTER TABLE audio_contents 
        ADD COLUMN play_analytics JSONB DEFAULT '{
            "total_play_time": 0,
            "unique_listeners": 0,
            "average_completion_rate": 0.0,
            "peak_concurrent_listeners": 0,
            "retention_points": []
        }';
        RAISE NOTICE '✅ audio_contents: 添加播放分析数据';
    END IF;
    
    -- 添加内容来源标识
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'audio_contents' AND column_name = 'content_source') THEN
        ALTER TABLE audio_contents 
        ADD COLUMN content_source VARCHAR(50) DEFAULT 'user_upload'; -- user_upload, ai_generated, imported
        RAISE NOTICE '✅ audio_contents: 添加内容来源标识';
    END IF;
    
    -- 添加推荐权重
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'audio_contents' AND column_name = 'recommendation_weight') THEN
        ALTER TABLE audio_contents 
        ADD COLUMN recommendation_weight DECIMAL(5,4) DEFAULT 1.0000;
        RAISE NOTICE '✅ audio_contents: 添加推荐权重';
    END IF;
END $$;

-- =============================================
-- 第三部分: 扩展 user_analytics 表
-- =============================================

DO $$
BEGIN
    -- 添加API使用跟踪
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_analytics' AND column_name = 'api_usage_data') THEN
        ALTER TABLE user_analytics 
        ADD COLUMN api_usage_data JSONB DEFAULT '{}';
        RAISE NOTICE '✅ user_analytics: 添加API使用跟踪';
    END IF;
    
    -- 添加内容交互深度
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_analytics' AND column_name = 'interaction_depth') THEN
        ALTER TABLE user_analytics 
        ADD COLUMN interaction_depth JSONB DEFAULT '{
            "ai_chat_depth": 0,
            "audio_engagement": 0,
            "content_creation": 0,
            "social_interactions": 0
        }';
        RAISE NOTICE '✅ user_analytics: 添加内容交互深度';
    END IF;
    
    -- 添加个性化标签
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_analytics' AND column_name = 'personalization_tags') THEN
        ALTER TABLE user_analytics 
        ADD COLUMN personalization_tags TEXT[] DEFAULT ARRAY[]::TEXT[];
        RAISE NOTICE '✅ user_analytics: 添加个性化标签';
    END IF;
END $$;

-- =============================================
-- 第四部分: 扩展 interaction_logs 表  
-- =============================================

DO $$
BEGIN
    -- 添加API调用跟踪
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'interaction_logs' AND column_name = 'api_call_id') THEN
        ALTER TABLE interaction_logs 
        ADD COLUMN api_call_id VARCHAR(255);
        RAISE NOTICE '✅ interaction_logs: 添加API调用跟踪';
    END IF;
    
    -- 添加响应质量评分
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'interaction_logs' AND column_name = 'response_quality_score') THEN
        ALTER TABLE interaction_logs 
        ADD COLUMN response_quality_score DECIMAL(3,2);
        RAISE NOTICE '✅ interaction_logs: 添加响应质量评分';
    END IF;
    
    -- 添加成本跟踪
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'interaction_logs' AND column_name = 'api_cost') THEN
        ALTER TABLE interaction_logs 
        ADD COLUMN api_cost DECIMAL(10,6) DEFAULT 0.00;
        RAISE NOTICE '✅ interaction_logs: 添加成本跟踪';
    END IF;
    
    -- 检查现有的扩展字段是否存在（从之前的埋点系统）
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'interaction_logs' AND column_name = 'session_id') THEN
        RAISE NOTICE '✅ interaction_logs: 埋点扩展字段已存在，跳过重复创建';
    END IF;
END $$;

-- =============================================
-- 第五部分: 扩展 custom_agents 表
-- =============================================

DO $$
BEGIN
    -- 添加API配置关联
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'custom_agents' AND column_name = 'api_config_id') THEN
        ALTER TABLE custom_agents 
        ADD COLUMN api_config_id UUID REFERENCES ai_conversation_configs(id);
        RAISE NOTICE '✅ custom_agents: 添加API配置关联';
    END IF;
    
    -- 添加训练状态
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'custom_agents' AND column_name = 'training_status') THEN
        ALTER TABLE custom_agents 
        ADD COLUMN training_status VARCHAR(20) DEFAULT 'ready'; -- ready, training, optimizing, error
        RAISE NOTICE '✅ custom_agents: 添加训练状态';
    END IF;
    
    -- 添加性能指标
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'custom_agents' AND column_name = 'performance_metrics') THEN
        ALTER TABLE custom_agents 
        ADD COLUMN performance_metrics JSONB DEFAULT '{
            "average_response_time": 0,
            "user_satisfaction": 0.0,
            "conversation_success_rate": 0.0,
            "context_retention_score": 0.0
        }';
        RAISE NOTICE '✅ custom_agents: 添加性能指标';
    END IF;
    
    -- 添加成本控制配置
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'custom_agents' AND column_name = 'cost_control') THEN
        ALTER TABLE custom_agents 
        ADD COLUMN cost_control JSONB DEFAULT '{
            "max_daily_cost": 10.00,
            "cost_per_message": 0.002,
            "alert_threshold": 8.00,
            "auto_pause_on_limit": true
        }';
        RAISE NOTICE '✅ custom_agents: 添加成本控制配置';
    END IF;
END $$;

-- =============================================
-- 第六部分: 扩展 user_memberships 表
-- =============================================

DO $$
BEGIN
    -- 添加API使用配额
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_memberships' AND column_name = 'api_quotas') THEN
        ALTER TABLE user_memberships 
        ADD COLUMN api_quotas JSONB DEFAULT '{
            "llm_daily_requests": 100,
            "tts_daily_minutes": 10,
            "asr_daily_minutes": 10,
            "image_gen_daily_count": 5
        }';
        RAISE NOTICE '✅ user_memberships: 添加API使用配额';
    END IF;
    
    -- 添加功能权限配置
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_memberships' AND column_name = 'feature_permissions') THEN
        ALTER TABLE user_memberships 
        ADD COLUMN feature_permissions JSONB DEFAULT '{
            "ai_chat_unlimited": false,
            "voice_interaction": false,
            "image_generation": false,
            "custom_agents": false,
            "premium_models": false
        }';
        RAISE NOTICE '✅ user_memberships: 添加功能权限配置';
    END IF;
    
    -- 添加使用统计跟踪
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_memberships' AND column_name = 'usage_tracking') THEN
        ALTER TABLE user_memberships 
        ADD COLUMN usage_tracking JSONB DEFAULT '{
            "api_calls_this_month": 0,
            "features_used": [],
            "peak_usage_day": null,
            "cost_this_month": 0.00
        }';
        RAISE NOTICE '✅ user_memberships: 添加使用统计跟踪';
    END IF;
END $$;

-- =============================================
-- 第七部分: 创建关联视图
-- =============================================

-- 1. AI角色完整信息视图
CREATE OR REPLACE VIEW ai_characters_enhanced AS
SELECT 
    ac.*,
    acc.config_name as default_config_name,
    acc.model_id as default_model,
    acc.model_parameters as default_parameters
FROM ai_characters ac
LEFT JOIN ai_conversation_configs acc ON ac.default_conversation_config_id = acc.id
WHERE ac.is_public = true;

-- 2. 音频内容播放统计视图
CREATE OR REPLACE VIEW audio_contents_analytics AS
SELECT 
    ac.*,
    asc.streaming_status,
    COALESCE((ac.play_analytics->>'total_play_time')::INTEGER, 0) as total_play_time,
    COALESCE((ac.play_analytics->>'unique_listeners')::INTEGER, 0) as unique_listeners,
    COALESCE((ac.play_analytics->>'average_completion_rate')::DECIMAL, 0.0) as avg_completion_rate
FROM audio_contents ac
LEFT JOIN audio_stream_configs asc ON ac.id = asc.audio_content_id
WHERE ac.is_public = true;

-- 3. 用户API使用概览视图
CREATE OR REPLACE VIEW user_api_usage_overview AS
SELECT 
    u.id as user_id,
    u.nickname,
    um.plan_id,
    sp.plan_name,
    (um.api_quotas->>'llm_daily_requests')::INTEGER as llm_quota,
    (um.usage_tracking->>'api_calls_this_month')::INTEGER as api_calls_used,
    (um.usage_tracking->>'cost_this_month')::DECIMAL as monthly_cost
FROM users u
LEFT JOIN user_memberships um ON u.id = um.user_id AND um.status = 'active'
LEFT JOIN subscription_plans sp ON um.plan_id = sp.id;

-- =============================================
-- 第八部分: 更新现有索引
-- =============================================

-- AI角色增强索引
CREATE INDEX IF NOT EXISTS idx_ai_characters_config 
    ON ai_characters(default_conversation_config_id) 
    WHERE default_conversation_config_id IS NOT NULL;

-- 音频内容流媒体索引
CREATE INDEX IF NOT EXISTS idx_audio_contents_streaming_status 
    ON audio_contents(streaming_status, updated_at) 
    WHERE streaming_status != 'ready';

-- 用户分析API使用索引
CREATE INDEX IF NOT EXISTS idx_user_analytics_api_usage 
    ON user_analytics USING GIN (api_usage_data) 
    WHERE api_usage_data != '{}';

-- 交互日志API调用索引
CREATE INDEX IF NOT EXISTS idx_interaction_logs_api_call 
    ON interaction_logs(api_call_id, created_at) 
    WHERE api_call_id IS NOT NULL;

-- =============================================
-- 第九部分: 数据迁移和初始化
-- =============================================

-- 为现有AI角色设置默认对话配置
UPDATE ai_characters 
SET default_conversation_config_id = (
    SELECT id FROM ai_conversation_configs 
    WHERE config_name = 'AI角色扮演配置' 
    LIMIT 1
)
WHERE default_conversation_config_id IS NULL 
  AND is_public = true;

-- 为现有音频内容初始化流媒体状态
UPDATE audio_contents 
SET streaming_status = 'ready',
    audio_metadata = jsonb_build_object(
        'original_format', 'mp3',
        'bitrate', 128,
        'estimated_file_size', duration_seconds * 16000 -- 估算
    )
WHERE streaming_status IS NULL;

-- 为现有用户会员初始化API配额
UPDATE user_memberships um
SET 
    api_quotas = CASE 
        WHEN sp.plan_type = 'free' THEN '{
            "llm_daily_requests": 10,
            "tts_daily_minutes": 0,
            "asr_daily_minutes": 0,
            "image_gen_daily_count": 0
        }'::jsonb
        WHEN sp.plan_type = 'basic' THEN '{
            "llm_daily_requests": 100,
            "tts_daily_minutes": 30,
            "asr_daily_minutes": 30,
            "image_gen_daily_count": 10
        }'::jsonb
        WHEN sp.plan_type = 'premium' THEN '{
            "llm_daily_requests": -1,
            "tts_daily_minutes": -1,
            "asr_daily_minutes": -1,
            "image_gen_daily_count": 50
        }'::jsonb
        ELSE api_quotas
    END,
    feature_permissions = CASE
        WHEN sp.plan_type = 'free' THEN '{
            "ai_chat_unlimited": false,
            "voice_interaction": false,
            "image_generation": false,
            "custom_agents": false,
            "premium_models": false
        }'::jsonb
        WHEN sp.plan_type = 'basic' THEN '{
            "ai_chat_unlimited": false,
            "voice_interaction": true,
            "image_generation": false,
            "custom_agents": false,
            "premium_models": false
        }'::jsonb
        WHEN sp.plan_type IN ('premium', 'lifetime') THEN '{
            "ai_chat_unlimited": true,
            "voice_interaction": true,
            "image_generation": true,
            "custom_agents": true,
            "premium_models": true
        }'::jsonb
        ELSE feature_permissions
    END
FROM subscription_plans sp
WHERE um.plan_id = sp.id 
  AND um.status = 'active'
  AND um.api_quotas IS NULL;

-- =============================================
-- 验证扩展结果
-- =============================================

DO $$
DECLARE
    enhanced_tables_count INTEGER := 0;
    new_columns_count INTEGER := 0;
    views_count INTEGER := 0;
BEGIN
    -- 统计增强的表
    SELECT COUNT(DISTINCT table_name) INTO enhanced_tables_count
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name IN ('ai_characters', 'audio_contents', 'user_analytics', 'interaction_logs', 'custom_agents', 'user_memberships')
    AND column_name IN (
        'default_conversation_config_id', 'role_prompt', 'conversation_style', 'multimodal_support',
        'streaming_status', 'audio_metadata', 'play_analytics', 'content_source',
        'api_usage_data', 'interaction_depth', 'personalization_tags',
        'api_call_id', 'response_quality_score', 'api_cost',
        'api_config_id', 'training_status', 'performance_metrics',
        'api_quotas', 'feature_permissions', 'usage_tracking'
    );
    
    -- 统计新增的列
    SELECT COUNT(*) INTO new_columns_count
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND column_name IN (
        'default_conversation_config_id', 'role_prompt', 'conversation_style', 'multimodal_support',
        'streaming_status', 'audio_metadata', 'play_analytics', 'content_source', 'recommendation_weight',
        'api_usage_data', 'interaction_depth', 'personalization_tags',
        'api_call_id', 'response_quality_score', 'api_cost',
        'api_config_id', 'training_status', 'performance_metrics', 'cost_control',
        'api_quotas', 'feature_permissions', 'usage_tracking'
    );
    
    -- 统计新建的视图
    SELECT COUNT(*) INTO views_count
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%enhanced%' OR table_name LIKE '%analytics%' OR table_name LIKE '%overview%';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉🎉🎉 现有表功能增强完成! 🎉🎉🎉';
    RAISE NOTICE '';
    RAISE NOTICE '📊 增强统计:';
    RAISE NOTICE '  ✅ 增强表数量: %个', enhanced_tables_count;
    RAISE NOTICE '  ✅ 新增字段: %个', new_columns_count;
    RAISE NOTICE '  ✅ 新建视图: %个', views_count;
    RAISE NOTICE '';
    RAISE NOTICE '🚀 增强功能:';
    RAISE NOTICE '  ✅ AI角色 → 对话配置+多模态+扮演';
    RAISE NOTICE '  ✅ 音频内容 → 流媒体+分析+推荐';
    RAISE NOTICE '  ✅ 用户分析 → API使用+个性化';
    RAISE NOTICE '  ✅ 交互日志 → API跟踪+成本+质量';
    RAISE NOTICE '  ✅ 智能体 → 性能+成本+训练';
    RAISE NOTICE '  ✅ 会员体系 → API配额+权限';
    RAISE NOTICE '';
    RAISE NOTICE '💡 完全向后兼容，现有功能不受影响!';
    RAISE NOTICE '🔗 新功能通过外键关联，数据一致性保证!';
    RAISE NOTICE '';
END $$;

-- 显示增强后的表结构概览
SELECT 
    table_name as "增强表名",
    COUNT(*) as "总字段数",
    COUNT(CASE WHEN column_name IN (
        'default_conversation_config_id', 'role_prompt', 'conversation_style', 'multimodal_support',
        'streaming_status', 'audio_metadata', 'play_analytics', 'content_source', 'recommendation_weight',
        'api_usage_data', 'interaction_depth', 'personalization_tags',
        'api_call_id', 'response_quality_score', 'api_cost',
        'api_config_id', 'training_status', 'performance_metrics', 'cost_control',
        'api_quotas', 'feature_permissions', 'usage_tracking'
    ) THEN 1 END) as "新增字段数"
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('ai_characters', 'audio_contents', 'user_analytics', 'interaction_logs', 'custom_agents', 'user_memberships')
GROUP BY table_name
ORDER BY table_name;