-- ============================================================================
-- 星趣App Sprint 3 完整部署脚本
-- 在Supabase SQL Editor中执行
-- 版本: 3.0.0
-- ============================================================================

-- ============================================================================
-- 第一步: 创建迁移日志表（如果不存在）
-- ============================================================================
CREATE TABLE IF NOT EXISTS migration_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    migration_name VARCHAR(255) NOT NULL,
    migration_version VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 记录Sprint 3迁移开始
INSERT INTO migration_logs (migration_name, migration_version, status) 
VALUES ('Sprint 3 Complete Database Extension', '3.0.0', 'running');

-- ============================================================================
-- 第二步: 订阅套餐系统
-- ============================================================================

-- 1. 订阅套餐配置表
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
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 插入默认套餐数据
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
 4, false, '一次性付费');

-- 2. 用户会员状态表
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

-- 添加唯一约束（每个用户只能有一个active状态的会员）
CREATE UNIQUE INDEX idx_user_memberships_active_unique 
ON user_memberships (user_id) 
WHERE status = 'active';

-- 3. 支付订单管理表
CREATE TABLE IF NOT EXISTS payment_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(64) UNIQUE NOT NULL,
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
    expires_at TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    
    -- 元数据
    metadata JSONB DEFAULT '{}',
    failure_reason TEXT,
    refund_reason TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 支付回调记录表
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

-- ============================================================================
-- 第三步: 推荐系统扩展
-- ============================================================================

-- 5. 推荐算法配置表
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

-- ============================================================================
-- 第四步: 智能体生态系统
-- ============================================================================

-- 7. 自定义智能体表
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
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. 智能体运行状态表
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

-- ============================================================================
-- 第五步: 会员权益系统
-- ============================================================================

-- 10. 会员权益配置表
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

-- 插入默认权益数据
INSERT INTO membership_benefits (benefit_code, benefit_name, benefit_category, description, icon_name, applicable_plans, limit_config, display_order, is_highlighted) VALUES
('unlimited_chat', 'AI助手无限制', 'core', '不限次数使用AI创作助手', 'robot', ARRAY['basic', 'premium', 'lifetime'], '{"daily_limit": -1}', 1, true),
('premium_characters', '专属AI角色', 'content', '解锁200+专属AI聊天角色', 'users', ARRAY['basic', 'premium', 'lifetime'], '{"character_access": "premium"}', 2, true),
('priority_response', '优先响应', 'core', 'AI回复速度提升3倍', 'zap', ARRAY['premium', 'lifetime'], '{"priority_level": "high"}', 3, true),
('cloud_storage', '云端存储', 'storage', '专属云端存储空间', 'database', ARRAY['basic', 'premium', 'lifetime'], '{"storage_gb": {"basic": 1, "premium": 10, "lifetime": -1}}', 4, false),
('custom_themes', '专属主题', 'content', '独享精美界面主题', 'palette', ARRAY['premium', 'lifetime'], '{}', 5, false),
('ad_free', '无广告体验', 'core', '享受纯净无干扰环境', 'shield', ARRAY['basic', 'premium', 'lifetime'], '{}', 6, false);

-- 11. 会员权益使用记录表
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

-- ============================================================================
-- 第六步: 用户偏好设置
-- ============================================================================

-- 12. 用户Tab偏好设置表
CREATE TABLE IF NOT EXISTS user_tab_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Tab偏好配置
    default_tab VARCHAR(50) DEFAULT 'comprehensive',
    tab_order TEXT[] DEFAULT ARRAY['assistant', 'fm', 'comprehensive', 'selection'],
    hidden_tabs TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- 子Tab偏好
    comprehensive_default_subtab VARCHAR(50) DEFAULT 'recommend',
    subtab_preferences JSONB DEFAULT '{}',
    
    -- 个性化设置
    quick_actions TEXT[] DEFAULT ARRAY[]::TEXT[],
    layout_preferences JSONB DEFAULT '{}',
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 唯一约束
    UNIQUE(user_id)
);

-- ============================================================================
-- 第七步: 创建索引
-- ============================================================================

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
-- 第八步: 创建函数和触发器
-- ============================================================================

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
DECLARE
    plan_info subscription_plans%ROWTYPE;
    new_expires_at TIMESTAMPTZ;
BEGIN
    -- 当订单状态变为已支付时，更新用户会员状态
    IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
        -- 获取套餐信息
        SELECT * INTO plan_info FROM subscription_plans WHERE id = NEW.plan_id;
        
        -- 计算到期时间
        IF plan_info.duration_type = 'lifetime' THEN
            new_expires_at := NULL;
        ELSE
            new_expires_at := NOW() + INTERVAL '1 day' * plan_info.duration_value;
        END IF;
        
        -- 先将用户其他active会员设为expired
        UPDATE user_memberships 
        SET status = 'expired', updated_at = NOW()
        WHERE user_id = NEW.user_id AND status = 'active';
        
        -- 插入新的会员状态
        INSERT INTO user_memberships (user_id, plan_id, status, started_at, expires_at, auto_renewal)
        VALUES (NEW.user_id, NEW.plan_id, 'active', NOW(), new_expires_at, false);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER trigger_update_membership_on_payment
AFTER UPDATE ON payment_orders
FOR EACH ROW
WHEN (NEW.status = 'paid' AND OLD.status != 'paid')
EXECUTE FUNCTION update_user_membership_on_payment();

-- 3. 智能体使用统计更新函数
CREATE OR REPLACE FUNCTION update_agent_usage_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新智能体使用次数
    UPDATE custom_agents 
    SET usage_count = usage_count + 1,
        updated_at = NOW()
    WHERE id = NEW.target_id AND NEW.target_type = 'custom_agent';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器（基于现有interaction_logs表）
CREATE TRIGGER trigger_update_agent_usage
AFTER INSERT ON interaction_logs
FOR EACH ROW
WHEN (NEW.target_type = 'custom_agent')
EXECUTE FUNCTION update_agent_usage_stats();

-- 4. 自动清理过期订单函数
CREATE OR REPLACE FUNCTION cleanup_expired_orders()
RETURNS INTEGER AS $$
DECLARE
    cleanup_count INTEGER;
BEGIN
    UPDATE payment_orders 
    SET status = 'cancelled', 
        cancelled_at = NOW(),
        updated_at = NOW()
    WHERE status = 'pending' 
      AND expires_at < NOW();
    
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RETURN cleanup_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 第九步: 添加数据约束
-- ============================================================================

-- 添加检查约束
ALTER TABLE subscription_plans ADD CONSTRAINT check_price_non_negative 
    CHECK (price_cents >= 0);

ALTER TABLE subscription_plans ADD CONSTRAINT check_original_price_greater 
    CHECK (original_price_cents IS NULL OR original_price_cents >= price_cents);

ALTER TABLE payment_orders ADD CONSTRAINT check_amounts_non_negative 
    CHECK (amount_cents >= 0 AND final_amount_cents >= 0 AND discount_cents >= 0);

ALTER TABLE payment_orders ADD CONSTRAINT check_final_amount_calculation 
    CHECK (final_amount_cents = amount_cents - discount_cents);

ALTER TABLE custom_agents ADD CONSTRAINT check_rating_range 
    CHECK (rating >= 0.0 AND rating <= 5.0);

ALTER TABLE custom_agents ADD CONSTRAINT check_version_positive 
    CHECK (version > 0);

-- ============================================================================
-- 第十步: 插入推荐算法配置
-- ============================================================================

INSERT INTO recommendation_configs (algorithm_name, algorithm_version, parameters, weights, target_user_types, content_types, is_active, priority) VALUES
('collaborative_filtering', '1.0', 
 '{"min_interactions": 5, "similarity_threshold": 0.3, "max_recommendations": 20}',
 '{"user_similarity": 0.4, "item_popularity": 0.3, "recency": 0.3}',
 ARRAY['free', 'basic', 'premium'], ARRAY['character', 'story', 'audio'], true, 1),

('content_based', '1.0',
 '{"feature_weights": {"category": 0.4, "tags": 0.3, "rating": 0.3}, "max_recommendations": 15}',
 '{"content_similarity": 0.6, "user_preferences": 0.4}',
 ARRAY['free', 'basic', 'premium'], ARRAY['character', 'story', 'audio'], true, 2),

('hybrid_premium', '1.0',
 '{"cf_weight": 0.5, "cb_weight": 0.3, "popularity_weight": 0.2, "diversity_factor": 0.1}',
 '{"collaborative": 0.5, "content": 0.3, "popularity": 0.2}',
 ARRAY['premium', 'lifetime'], ARRAY['character', 'story', 'audio'], true, 3);

-- ============================================================================
-- 第十一步: 启用行级安全策略（RLS）
-- ============================================================================

-- 为新表启用RLS
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

-- ============================================================================
-- 第十二步: 更新迁移日志
-- ============================================================================

-- 更新迁移日志状态
UPDATE migration_logs 
SET status = 'completed', 
    completed_at = NOW() 
WHERE migration_name = 'Sprint 3 Complete Database Extension' 
  AND migration_version = '3.0.0';

-- ============================================================================
-- 部署完成总结
-- ============================================================================

DO $$
DECLARE
    table_count INTEGER;
    index_count INTEGER;
    function_count INTEGER;
BEGIN
    -- 统计新建的表
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN (
        'subscription_plans', 'user_memberships', 'payment_orders', 
        'payment_callbacks', 'recommendation_configs', 'recommendation_feedback',
        'custom_agents', 'agent_runtime_status', 'agent_permissions',
        'membership_benefits', 'membership_usage_logs', 'user_tab_preferences'
    );
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Sprint 3 数据库部署完成';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '新建表数量: %', table_count;
    RAISE NOTICE '商业化功能: 订阅套餐、支付系统、会员权益';
    RAISE NOTICE '个性化功能: 推荐算法、用户反馈、偏好设置';
    RAISE NOTICE '智能体生态: 自定义智能体、权限管理、运行状态';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '请执行 sprint3_rls_policies.sql 配置安全策略';
    RAISE NOTICE '==========================================';
END $$;