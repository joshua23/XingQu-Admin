-- ============================================================================
-- 星趣App Sprint 3 Supabase完整部署脚本
-- 在Supabase SQL Editor中按顺序执行
-- 执行前请确保已备份现有数据
-- ============================================================================

-- ============================================================================
-- 执行前检查和准备
-- ============================================================================

-- 1. 检查当前环境
DO $$
DECLARE
    current_version TEXT;
    user_count INTEGER;
    character_count INTEGER;
BEGIN
    -- 检查数据库版本
    SELECT version() INTO current_version;
    RAISE NOTICE '数据库版本: %', current_version;
    
    -- 检查现有数据量
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO character_count FROM characters;
    
    RAISE NOTICE '当前数据统计:';
    RAISE NOTICE '- 用户数量: %', user_count;
    RAISE NOTICE '- 角色数量: %', character_count;
    
    -- 检查必要的扩展
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        RAISE NOTICE '已启用 uuid-ossp 扩展';
    END IF;
    
    RAISE NOTICE '环境检查完成，准备开始部署...';
END $$;

-- ============================================================================
-- 第一阶段: 执行数据库结构创建
-- ============================================================================

-- 记录部署开始
INSERT INTO migration_logs (migration_name, migration_version, status) 
VALUES ('Sprint 3 Supabase Deployment', '3.0.0', 'running');

-- ============================================================================
-- 扩展现有表结构（兼容性保证）
-- ============================================================================

-- 扩展users表
DO $$ 
BEGIN
    RAISE NOTICE '正在扩展users表...';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'membership_tier') THEN
        ALTER TABLE users ADD COLUMN membership_tier VARCHAR(20) DEFAULT 'free';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'total_spent_cents') THEN
        ALTER TABLE users ADD COLUMN total_spent_cents INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'referral_code') THEN
        ALTER TABLE users ADD COLUMN referral_code VARCHAR(20) UNIQUE;
    END IF;
    
    -- 为现有用户生成推荐码
    UPDATE users 
    SET referral_code = 'XQ' || UPPER(SUBSTRING(id::TEXT, 1, 6))
    WHERE referral_code IS NULL;
    
    RAISE NOTICE 'users表扩展完成';
END $$;

-- 扩展characters表
DO $$ 
BEGIN
    RAISE NOTICE '正在扩展characters表...';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'characters' AND column_name = 'character_type') THEN
        ALTER TABLE characters ADD COLUMN character_type VARCHAR(20) DEFAULT 'official';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'characters' AND column_name = 'access_level') THEN
        ALTER TABLE characters ADD COLUMN access_level VARCHAR(20) DEFAULT 'free';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'characters' AND column_name = 'creator_id') THEN
        ALTER TABLE characters ADD COLUMN creator_id UUID REFERENCES users(id);
    END IF;
    
    -- 设置现有角色为官方角色
    UPDATE characters 
    SET character_type = 'official', 
        access_level = 'free',
        updated_at = NOW()
    WHERE character_type IS NULL;
    
    RAISE NOTICE 'characters表扩展完成';
END $$;

-- ============================================================================
-- 创建新的业务表
-- ============================================================================

-- 1. 订阅套餐配置表
RAISE NOTICE '正在创建subscription_plans表...';

CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_code VARCHAR(50) UNIQUE NOT NULL,
    plan_name VARCHAR(100) NOT NULL,
    plan_type VARCHAR(20) NOT NULL,
    duration_type VARCHAR(20) NOT NULL,
    duration_value INTEGER DEFAULT 0,
    
    -- 价格信息
    price_cents INTEGER NOT NULL DEFAULT 0,
    original_price_cents INTEGER,
    currency VARCHAR(3) DEFAULT 'CNY',
    
    -- 权益配置
    features JSONB NOT NULL DEFAULT '{}',
    limits JSONB DEFAULT '{}',
    
    -- 显示配置
    display_order INTEGER DEFAULT 0,
    is_recommended BOOLEAN DEFAULT false,
    badge_text VARCHAR(50),
    badge_color VARCHAR(7),
    
    -- 状态管理
    is_active BOOLEAN DEFAULT true,
    available_from TIMESTAMPTZ,
    available_until TIMESTAMPTZ,
    
    -- 元数据
    description TEXT,
    terms_conditions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 约束
    CONSTRAINT check_price_non_negative CHECK (price_cents >= 0),
    CONSTRAINT check_original_price_greater CHECK (original_price_cents IS NULL OR original_price_cents >= price_cents)
);

-- 2. 用户会员状态表
RAISE NOTICE '正在创建user_memberships表...';

CREATE TABLE IF NOT EXISTS user_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id),
    
    -- 订阅状态
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    
    -- 时间管理
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    suspended_at TIMESTAMPTZ,
    
    -- 自动续费
    auto_renewal BOOLEAN DEFAULT false,
    next_billing_date TIMESTAMPTZ,
    
    -- 使用统计
    usage_stats JSONB DEFAULT '{}',
    total_usage_stats JSONB DEFAULT '{}',
    
    -- 元数据
    source VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 支付订单管理表
RAISE NOTICE '正在创建payment_orders表...';

CREATE TABLE IF NOT EXISTS payment_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(64) UNIQUE NOT NULL DEFAULT ('XQ' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0')),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id),
    
    -- 订单状态
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    
    -- 金额信息
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'CNY',
    discount_cents INTEGER DEFAULT 0,
    final_amount_cents INTEGER NOT NULL,
    
    -- 支付信息
    payment_method VARCHAR(50),
    payment_provider VARCHAR(50),
    provider_order_id VARCHAR(200),
    provider_transaction_id VARCHAR(200),
    
    -- 时间信息
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 minutes'),
    paid_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    
    -- 元数据
    metadata JSONB DEFAULT '{}',
    failure_reason TEXT,
    refund_reason TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 约束
    CONSTRAINT check_amounts_non_negative CHECK (amount_cents >= 0 AND final_amount_cents >= 0 AND discount_cents >= 0),
    CONSTRAINT check_final_amount_calculation CHECK (final_amount_cents = amount_cents - discount_cents)
);

-- 4. 支付回调记录表
RAISE NOTICE '正在创建payment_callbacks表...';

CREATE TABLE IF NOT EXISTS payment_callbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES payment_orders(id) ON DELETE CASCADE,
    
    -- 回调信息
    callback_type VARCHAR(50) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    raw_data JSONB NOT NULL,
    signature VARCHAR(500),
    
    -- 处理状态
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    processing_result JSONB,
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 推荐算法配置表
RAISE NOTICE '正在创建recommendation_configs表...';

CREATE TABLE IF NOT EXISTS recommendation_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    algorithm_name VARCHAR(100) NOT NULL,
    algorithm_version VARCHAR(20) NOT NULL,
    
    -- 算法参数
    parameters JSONB NOT NULL DEFAULT '{}',
    weights JSONB DEFAULT '{}',
    
    -- 适用范围
    target_user_types TEXT[],
    content_types TEXT[],
    
    -- 状态管理
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 用户推荐反馈表
RAISE NOTICE '正在创建recommendation_feedback表...';

CREATE TABLE IF NOT EXISTS recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recommendation_id UUID,
    content_type VARCHAR(50) NOT NULL,
    content_id UUID NOT NULL,
    
    -- 反馈类型
    feedback_type VARCHAR(50) NOT NULL,
    feedback_value DECIMAL(3,2),
    
    -- 上下文信息
    session_id UUID,
    page_context VARCHAR(50),
    position_in_list INTEGER,
    display_duration_seconds INTEGER,
    
    -- 元数据
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. 自定义智能体表
RAISE NOTICE '正在创建custom_agents表...';

CREATE TABLE IF NOT EXISTS custom_agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- 基本信息
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    description TEXT,
    category VARCHAR(50),
    
    -- 智能体配置
    personality_config JSONB NOT NULL DEFAULT '{}',
    knowledge_base JSONB DEFAULT '{}',
    conversation_style JSONB DEFAULT '{}',
    capabilities TEXT[],
    
    -- 运行配置
    model_config JSONB DEFAULT '{}',
    response_settings JSONB DEFAULT '{}',
    safety_filters JSONB DEFAULT '{}',
    
    -- 权限与可见性
    visibility VARCHAR(20) DEFAULT 'private',
    is_approved BOOLEAN DEFAULT false,
    approval_status VARCHAR(20) DEFAULT 'pending',
    
    -- 使用统计
    usage_count INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0,
    
    -- 状态管理
    status VARCHAR(20) DEFAULT 'draft',
    last_trained_at TIMESTAMPTZ,
    version INTEGER DEFAULT 1,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 约束
    CONSTRAINT check_rating_range CHECK (rating >= 0.0 AND rating <= 5.0),
    CONSTRAINT check_version_positive CHECK (version > 0)
);

-- 8. 智能体运行状态表
RAISE NOTICE '正在创建agent_runtime_status表...';

CREATE TABLE IF NOT EXISTS agent_runtime_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES custom_agents(id) ON DELETE CASCADE,
    
    -- 运行状态
    status VARCHAR(20) NOT NULL DEFAULT 'stopped',
    last_activity_at TIMESTAMPTZ,
    
    -- 性能指标
    response_time_ms INTEGER,
    memory_usage_mb INTEGER,
    cpu_usage_percent DECIMAL(5,2),
    error_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    
    -- 运行时配置
    runtime_config JSONB DEFAULT '{}',
    resource_limits JSONB DEFAULT '{}',
    
    -- 健康检查
    health_check_status VARCHAR(20) DEFAULT 'unknown',
    last_health_check_at TIMESTAMPTZ,
    health_check_details JSONB,
    
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. 智能体使用权限表
RAISE NOTICE '正在创建agent_permissions表...';

CREATE TABLE IF NOT EXISTS agent_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES custom_agents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- 权限类型
    permission_type VARCHAR(50) NOT NULL,
    granted_by UUID REFERENCES users(id),
    
    -- 权限限制
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    
    -- 状态
    is_active BOOLEAN DEFAULT true,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    
    -- 唯一约束
    UNIQUE(agent_id, user_id, permission_type)
);

-- 10. 会员权益配置表
RAISE NOTICE '正在创建membership_benefits表...';

CREATE TABLE IF NOT EXISTS membership_benefits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    benefit_code VARCHAR(50) UNIQUE NOT NULL,
    benefit_name VARCHAR(100) NOT NULL,
    benefit_category VARCHAR(50) NOT NULL,
    
    -- 权益描述
    description TEXT,
    icon_name VARCHAR(50),
    
    -- 适用计划
    applicable_plans TEXT[] NOT NULL,
    
    -- 权益限制
    limit_config JSONB DEFAULT '{}',
    
    -- 显示配置
    display_order INTEGER DEFAULT 0,
    is_highlighted BOOLEAN DEFAULT false,
    
    -- 状态
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. 会员权益使用记录表
RAISE NOTICE '正在创建membership_usage_logs表...';

CREATE TABLE IF NOT EXISTS membership_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    membership_id UUID REFERENCES user_memberships(id) ON DELETE CASCADE,
    benefit_code VARCHAR(50) NOT NULL,
    
    -- 使用信息
    usage_type VARCHAR(50) NOT NULL,
    usage_amount INTEGER DEFAULT 1,
    
    -- 上下文信息
    feature_context VARCHAR(100),
    session_id UUID,
    metadata JSONB DEFAULT '{}',
    
    -- 时间信息
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. 用户Tab偏好设置表
RAISE NOTICE '正在创建user_tab_preferences表...';

CREATE TABLE IF NOT EXISTS user_tab_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Tab偏好配置
    default_tab VARCHAR(50) DEFAULT 'comprehensive',
    tab_order TEXT[] DEFAULT '["assistant", "fm", "comprehensive", "selection"]',
    hidden_tabs TEXT[] DEFAULT '[]',
    
    -- 子Tab偏好
    comprehensive_default_subtab VARCHAR(50) DEFAULT 'recommend',
    subtab_preferences JSONB DEFAULT '{}',
    
    -- 个性化设置
    quick_actions TEXT[] DEFAULT '[]',
    layout_preferences JSONB DEFAULT '{}',
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 确保每个用户只有一条偏好记录
    UNIQUE(user_id)
);

-- ============================================================================
-- 创建索引
-- ============================================================================

RAISE NOTICE '正在创建性能优化索引...';

-- 订阅套餐索引
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_type ON subscription_plans(plan_type, duration_type);

-- 用户会员状态索引
CREATE INDEX IF NOT EXISTS idx_user_memberships_user_status ON user_memberships(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_memberships_expires_at ON user_memberships(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_memberships_auto_renewal ON user_memberships(auto_renewal, next_billing_date) WHERE auto_renewal = true;

-- 支付订单索引
CREATE INDEX IF NOT EXISTS idx_payment_orders_user_status ON payment_orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_expires_at ON payment_orders(expires_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_payment_orders_provider_order ON payment_orders(payment_provider, provider_order_id);

-- 推荐反馈索引
CREATE INDEX IF NOT EXISTS idx_recommendation_feedback_user ON recommendation_feedback(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_recommendation_feedback_content ON recommendation_feedback(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_recommendation_feedback_type ON recommendation_feedback(feedback_type, created_at);

-- 自定义智能体索引
CREATE INDEX IF NOT EXISTS idx_custom_agents_creator ON custom_agents(creator_id, status);
CREATE INDEX IF NOT EXISTS idx_custom_agents_public ON custom_agents(visibility, is_approved, status) WHERE visibility = 'public';
CREATE INDEX IF NOT EXISTS idx_custom_agents_category ON custom_agents(category, rating DESC) WHERE status = 'active';

-- 智能体权限索引
CREATE INDEX IF NOT EXISTS idx_agent_permissions_user_agent ON agent_permissions(user_id, agent_id, permission_type);
CREATE INDEX IF NOT EXISTS idx_agent_permissions_expires ON agent_permissions(expires_at) WHERE expires_at IS NOT NULL;

-- 会员使用记录索引
CREATE INDEX IF NOT EXISTS idx_membership_usage_user_date ON membership_usage_logs(user_id, usage_date);
CREATE INDEX IF NOT EXISTS idx_membership_usage_benefit_date ON membership_usage_logs(benefit_code, usage_date);

-- ============================================================================
-- 创建业务函数和触发器
-- ============================================================================

RAISE NOTICE '正在创建业务函数和触发器...';

-- 1. 订单号生成函数
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
    RETURN 'XQ' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- 2. 更新用户会员状态函数
CREATE OR REPLACE FUNCTION update_user_membership_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- 当订单状态变为已支付时，更新用户会员状态
    IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
        DECLARE
            plan_info subscription_plans%ROWTYPE;
            new_expires_at TIMESTAMPTZ;
        BEGIN
            SELECT * INTO plan_info FROM subscription_plans WHERE id = NEW.plan_id;
            
            -- 计算到期时间
            IF plan_info.duration_type = 'lifetime' THEN
                new_expires_at := NULL;
            ELSE
                new_expires_at := NOW() + INTERVAL '1 day' * plan_info.duration_value;
            END IF;
            
            -- 插入或更新用户会员状态
            INSERT INTO user_memberships (user_id, plan_id, status, started_at, expires_at, auto_renewal)
            VALUES (NEW.user_id, NEW.plan_id, 'active', NOW(), new_expires_at, false)
            ON CONFLICT (user_id) DO UPDATE SET
                plan_id = EXCLUDED.plan_id,
                started_at = EXCLUDED.started_at,
                expires_at = EXCLUDED.expires_at,
                status = 'active',
                updated_at = NOW();
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. 智能体使用统计更新函数
CREATE OR REPLACE FUNCTION update_agent_usage_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新智能体使用次数
    IF NEW.target_type = 'custom_agent' AND NEW.target_id IS NOT NULL THEN
        UPDATE custom_agents 
        SET usage_count = usage_count + 1,
            updated_at = NOW()
        WHERE id = NEW.target_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. 会员权益检查函数
CREATE OR REPLACE FUNCTION check_user_membership_level(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    membership_level TEXT;
BEGIN
    SELECT sp.plan_type INTO membership_level
    FROM user_memberships um
    JOIN subscription_plans sp ON um.plan_id = sp.id
    WHERE um.user_id = user_uuid 
      AND um.status = 'active'
      AND (um.expires_at IS NULL OR um.expires_at > NOW())
    ORDER BY 
        CASE sp.plan_type 
            WHEN 'lifetime' THEN 4
            WHEN 'premium' THEN 3 
            WHEN 'basic' THEN 2
            WHEN 'free' THEN 1
            ELSE 0
        END DESC
    LIMIT 1;
    
    RETURN COALESCE(membership_level, 'free');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
DO $$
BEGIN
    -- 支付成功触发器
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_membership_on_payment') THEN
        CREATE TRIGGER trigger_update_membership_on_payment
        AFTER UPDATE ON payment_orders
        FOR EACH ROW
        WHEN (NEW.status = 'paid' AND OLD.status != 'paid')
        EXECUTE FUNCTION update_user_membership_on_payment();
    END IF;
    
    -- 智能体使用统计触发器
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_agent_usage') THEN
        CREATE TRIGGER trigger_update_agent_usage
        AFTER INSERT ON interaction_logs
        FOR EACH ROW
        EXECUTE FUNCTION update_agent_usage_stats();
    END IF;
END $$;

-- ============================================================================
-- 插入默认数据
-- ============================================================================

RAISE NOTICE '正在插入默认配置数据...';

-- 插入订阅套餐
INSERT INTO subscription_plans (plan_code, plan_name, plan_type, duration_type, duration_value, price_cents, original_price_cents, features, limits, display_order, is_recommended, badge_text) VALUES
('free', '免费版', 'free', 'free', 0, 0, NULL, 
 '{"ai_chat_daily": 10, "basic_characters": true, "voice_messages": false, "premium_characters": false, "cloud_storage_mb": 50, "ad_free": false}',
 '{"ai_chat_daily": 10, "characters_access": "basic", "storage_limit_mb": 50}', 
 1, false, NULL),

('basic_monthly', '基础会员', 'basic', 'monthly', 30, 2990, NULL,
 '{"ai_chat_daily": -1, "basic_characters": true, "premium_characters": true, "voice_messages": true, "cloud_storage_mb": 1000, "ad_free": true, "priority_response": true}',
 '{"ai_chat_daily": -1, "characters_access": "premium", "storage_limit_mb": 1000}',
 2, false, NULL),

('premium_yearly', '高级会员', 'premium', 'yearly', 365, 24000, 34800,
 '{"ai_chat_daily": -1, "all_characters": true, "voice_messages": true, "custom_agents": true, "cloud_storage_mb": 10000, "ad_free": true, "priority_response": true, "api_access": true, "exclusive_content": true}',
 '{"ai_chat_daily": -1, "characters_access": "all", "custom_agents_limit": 10, "storage_limit_mb": 10000}',
 3, true, '省31%'),

('lifetime', '终身会员', 'lifetime', 'lifetime', 0, 99900, NULL,
 '{"ai_chat_daily": -1, "all_characters": true, "voice_messages": true, "custom_agents": true, "cloud_storage_mb": -1, "ad_free": true, "priority_response": true, "api_access": true, "exclusive_content": true, "lifetime_updates": true}',
 '{"ai_chat_daily": -1, "characters_access": "all", "custom_agents_limit": -1, "storage_limit_mb": -1}',
 4, false, '一次性付费')
ON CONFLICT (plan_code) DO NOTHING;

-- 插入会员权益配置
INSERT INTO membership_benefits (benefit_code, benefit_name, benefit_category, description, icon_name, applicable_plans, limit_config, display_order, is_highlighted) VALUES
('unlimited_chat', 'AI助手无限制', 'core', '不限次数使用AI创作助手', 'robot', '["basic", "premium", "lifetime"]', '{"daily_limit": -1}', 1, true),
('premium_characters', '专属AI角色', 'content', '解锁200+专属AI聊天角色', 'users', '["basic", "premium", "lifetime"]', '{"character_access": "premium"}', 2, true),
('priority_response', '优先响应', 'core', 'AI回复速度提升3倍', 'zap', '["premium", "lifetime"]', '{"priority_level": "high"}', 3, true),
('cloud_storage', '云端存储', 'storage', '专属云端存储空间', 'database', '["basic", "premium", "lifetime"]', '{"storage_gb": {"basic": 1, "premium": 10, "lifetime": -1}}', 4, false),
('custom_themes', '专属主题', 'content', '独享精美界面主题', 'palette', '["premium", "lifetime"]', '{}', 5, false),
('ad_free', '无广告体验', 'core', '享受纯净无干扰环境', 'shield', '["basic", "premium", "lifetime"]', '{}', 6, false)
ON CONFLICT (benefit_code) DO NOTHING;

-- 插入推荐算法配置
INSERT INTO recommendation_configs (algorithm_name, algorithm_version, parameters, weights, target_user_types, content_types, is_active, priority) VALUES
('collaborative_filtering', '1.0', 
 '{"min_interactions": 5, "similarity_threshold": 0.3, "max_recommendations": 20}',
 '{"user_similarity": 0.4, "item_popularity": 0.3, "recency": 0.3}',
 '["free", "basic", "premium"]', '["character", "story", "audio"]', true, 1),

('content_based', '1.0',
 '{"feature_weights": {"category": 0.4, "tags": 0.3, "rating": 0.3}, "max_recommendations": 15}',
 '{"content_similarity": 0.6, "user_preferences": 0.4}',
 '["free", "basic", "premium"]', '["character", "story", "audio"]', true, 2),

('hybrid_premium', '1.0',
 '{"cf_weight": 0.5, "cb_weight": 0.3, "popularity_weight": 0.2, "diversity_factor": 0.1}',
 '{"collaborative": 0.5, "content": 0.3, "popularity": 0.2}',
 '["premium", "lifetime"]', '["character", "story", "audio"]', true, 3)
ON CONFLICT (algorithm_name, algorithm_version) DO NOTHING;

-- ============================================================================
-- 数据迁移和兼容性处理
-- ============================================================================

RAISE NOTICE '正在处理数据迁移和兼容性...';

-- 为现有用户创建免费会员记录
INSERT INTO user_memberships (user_id, plan_id, status, started_at, expires_at)
SELECT 
    u.id,
    sp.id,
    'active',
    COALESCE(u.created_at, NOW()),
    NULL
FROM users u
CROSS JOIN subscription_plans sp
WHERE sp.plan_code = 'free'
  AND NOT EXISTS (
      SELECT 1 FROM user_memberships um 
      WHERE um.user_id = u.id AND um.status = 'active'
  );

-- 为现有用户创建默认Tab偏好设置
INSERT INTO user_tab_preferences (user_id, default_tab, comprehensive_default_subtab)
SELECT 
    id,
    'comprehensive',
    'recommend'
FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM user_tab_preferences utp 
    WHERE utp.user_id = users.id
)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- 第二阶段: RLS策略配置
-- ============================================================================

RAISE NOTICE '正在配置Row Level Security策略...';

-- 启用所有新表的RLS
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_callbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_runtime_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_benefits ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tab_preferences ENABLE ROW LEVEL SECURITY;

-- 订阅套餐访问策略
DROP POLICY IF EXISTS "Public can view active subscription plans" ON subscription_plans;
CREATE POLICY "Public can view active subscription plans" ON subscription_plans
    FOR SELECT USING (is_active = true);

-- 用户会员状态策略
DROP POLICY IF EXISTS "Users can view own membership" ON user_memberships;
CREATE POLICY "Users can view own membership" ON user_memberships
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "System can manage memberships" ON user_memberships;
CREATE POLICY "System can manage memberships" ON user_memberships
    FOR ALL USING (auth.role() = 'service_role');

-- 支付订单安全策略
DROP POLICY IF EXISTS "Users can view own orders" ON payment_orders;
CREATE POLICY "Users can view own orders" ON payment_orders
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can create own orders" ON payment_orders;
CREATE POLICY "Users can create own orders" ON payment_orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "System can update order status" ON payment_orders;
CREATE POLICY "System can update order status" ON payment_orders
    FOR UPDATE USING (auth.role() = 'service_role');

-- 支付回调仅系统角色访问
DROP POLICY IF EXISTS "Only system can access payment callbacks" ON payment_callbacks;
CREATE POLICY "Only system can access payment callbacks" ON payment_callbacks
    FOR ALL USING (auth.role() = 'service_role');

-- 推荐配置公开访问
DROP POLICY IF EXISTS "Users can view active recommendation configs" ON recommendation_configs;
CREATE POLICY "Users can view active recommendation configs" ON recommendation_configs
    FOR SELECT USING (is_active = true);

-- 推荐反馈用户隔离
DROP POLICY IF EXISTS "Users can manage own recommendation feedback" ON recommendation_feedback;
CREATE POLICY "Users can manage own recommendation feedback" ON recommendation_feedback
    FOR ALL USING (user_id = auth.uid());

-- 自定义智能体访问控制
DROP POLICY IF EXISTS "Users can view accessible agents" ON custom_agents;
CREATE POLICY "Users can view accessible agents" ON custom_agents
    FOR SELECT USING (
        visibility = 'public' OR 
        creator_id = auth.uid()
    );

DROP POLICY IF EXISTS "Users can create own agents" ON custom_agents;
CREATE POLICY "Users can create own agents" ON custom_agents
    FOR INSERT WITH CHECK (creator_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own agents" ON custom_agents;
CREATE POLICY "Users can update own agents" ON custom_agents
    FOR UPDATE USING (creator_id = auth.uid());

-- 智能体权限管理
DROP POLICY IF EXISTS "Users can view own agent permissions" ON agent_permissions;
CREATE POLICY "Users can view own agent permissions" ON agent_permissions
    FOR SELECT USING (user_id = auth.uid());

-- 会员权益公开访问
DROP POLICY IF EXISTS "Users can view active membership benefits" ON membership_benefits;
CREATE POLICY "Users can view active membership benefits" ON membership_benefits
    FOR SELECT USING (is_active = true);

-- 使用记录用户隔离
DROP POLICY IF EXISTS "Users can view own usage logs" ON membership_usage_logs;
CREATE POLICY "Users can view own usage logs" ON membership_usage_logs
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "System can record usage logs" ON membership_usage_logs;
CREATE POLICY "System can record usage logs" ON membership_usage_logs
    FOR INSERT WITH CHECK (user_id = auth.uid() OR auth.role() = 'service_role');

-- Tab偏好用户隔离
DROP POLICY IF EXISTS "Users can manage own tab preferences" ON user_tab_preferences;
CREATE POLICY "Users can manage own tab preferences" ON user_tab_preferences
    FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- 部署完成验证
-- ============================================================================

-- 执行完整性检查
DO $$
DECLARE
    table_count INTEGER;
    index_count INTEGER;
    policy_count INTEGER;
    function_count INTEGER;
    data_count INTEGER;
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Sprint 3 Supabase部署完成验证';
    RAISE NOTICE '==========================================';
    
    -- 检查表创建
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN (
        'subscription_plans', 'user_memberships', 'payment_orders', 'payment_callbacks',
        'recommendation_configs', 'recommendation_feedback', 'custom_agents', 
        'agent_runtime_status', 'agent_permissions', 'membership_benefits',
        'membership_usage_logs', 'user_tab_preferences'
    );
    
    -- 检查索引创建
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%sprint3%' OR indexname LIKE 'idx_%subscription%' 
    OR indexname LIKE 'idx_%payment%' OR indexname LIKE 'idx_%agent%';
    
    -- 检查RLS策略
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    -- 检查函数创建
    SELECT COUNT(*) INTO function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN ('check_user_membership_level', 'generate_order_number', 
                      'update_user_membership_on_payment', 'update_agent_usage_stats');
    
    -- 检查默认数据
    SELECT COUNT(*) INTO data_count FROM subscription_plans WHERE is_active = true;
    
    RAISE NOTICE '✅ 数据表创建: % / 12', table_count;
    RAISE NOTICE '✅ 索引创建: % 个', index_count;
    RAISE NOTICE '✅ RLS策略: % 个', policy_count;
    RAISE NOTICE '✅ 业务函数: % / 4', function_count;
    RAISE NOTICE '✅ 默认数据: % 个套餐', data_count;
    
    IF table_count = 12 AND function_count = 4 AND data_count >= 4 THEN
        RAISE NOTICE '🎉 Sprint 3 Supabase部署成功完成！';
        
        -- 更新迁移日志
        UPDATE migration_logs 
        SET status = 'completed', 
            completed_at = NOW() 
        WHERE migration_name = 'Sprint 3 Supabase Deployment' 
          AND migration_version = '3.0.0';
    ELSE
        RAISE NOTICE '⚠️  部分组件部署不完整，请检查错误信息';
        
        UPDATE migration_logs 
        SET status = 'partial_failure',
            error_message = '部分组件部署不完整'
        WHERE migration_name = 'Sprint 3 Supabase Deployment' 
          AND migration_version = '3.0.0';
    END IF;
    
    RAISE NOTICE '==========================================';
END $$;

-- ============================================================================
-- Supabase部署脚本执行完成
-- ============================================================================