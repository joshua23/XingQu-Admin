-- ============================================================================
-- 星趣App Sprint 3 数据库架构设计
-- 新增功能：综合页Tab切换、订阅页商业化、推荐页算法、智能体生态、会员权益、支付系统
-- 基于现有Sprint 1-2数据结构进行扩展
-- ============================================================================

-- ============================================================================
-- 第一部分: 迁移准备与版本控制
-- ============================================================================

-- 记录Sprint 3迁移开始
INSERT INTO migration_logs (migration_name, migration_version, status) 
VALUES ('Sprint 3 Complete Database Extension', '3.0.0', 'running');

-- ============================================================================
-- 第二部分: 订阅页商业化功能 - 核心商业模型
-- ============================================================================

-- 1. 订阅套餐配置表
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_code VARCHAR(50) UNIQUE NOT NULL, -- 'free', 'basic_monthly', 'premium_yearly', 'lifetime'
    plan_name VARCHAR(100) NOT NULL, -- '免费版', '基础会员', '高级会员', '终身会员'
    plan_type VARCHAR(20) NOT NULL, -- 'free', 'basic', 'premium', 'lifetime'
    duration_type VARCHAR(20) NOT NULL, -- 'free', 'monthly', 'yearly', 'lifetime'
    duration_value INTEGER DEFAULT 0, -- 天数，0表示永久
    
    -- 价格信息
    price_cents INTEGER NOT NULL DEFAULT 0, -- 价格（分）
    original_price_cents INTEGER, -- 原价（分）
    currency VARCHAR(3) DEFAULT 'CNY',
    
    -- 权益配置
    features JSONB NOT NULL DEFAULT '{}', -- 具体权益列表
    limits JSONB DEFAULT '{}', -- 使用限制配置
    
    -- 显示配置
    display_order INTEGER DEFAULT 0,
    is_recommended BOOLEAN DEFAULT false,
    badge_text VARCHAR(50), -- '推荐', '限时优惠' 等
    badge_color VARCHAR(7), -- 角标颜色
    
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
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'expired', 'cancelled', 'suspended'
    
    -- 时间管理
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ, -- NULL表示永久有效
    cancelled_at TIMESTAMPTZ,
    suspended_at TIMESTAMPTZ,
    
    -- 自动续费
    auto_renewal BOOLEAN DEFAULT false,
    next_billing_date TIMESTAMPTZ,
    
    -- 使用统计
    usage_stats JSONB DEFAULT '{}', -- 当期使用统计
    total_usage_stats JSONB DEFAULT '{}', -- 总使用统计
    
    -- 元数据
    source VARCHAR(50), -- 'app', 'web', 'promotion'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 确保用户同时只有一个有效订阅
    UNIQUE(user_id, status) DEFERRABLE INITIALLY DEFERRED
);

-- 3. 支付订单管理表
CREATE TABLE IF NOT EXISTS payment_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(64) UNIQUE NOT NULL, -- 订单号
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id),
    
    -- 订单状态
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'paid', 'failed', 'cancelled', 'refunded'
    
    -- 金额信息
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'CNY',
    discount_cents INTEGER DEFAULT 0,
    final_amount_cents INTEGER NOT NULL,
    
    -- 支付信息
    payment_method VARCHAR(50), -- 'alipay', 'wechat', 'apple_pay'
    payment_provider VARCHAR(50), -- 第三方支付服务商
    provider_order_id VARCHAR(200), -- 第三方订单ID
    provider_transaction_id VARCHAR(200), -- 第三方交易ID
    
    -- 时间信息
    expires_at TIMESTAMPTZ NOT NULL, -- 订单过期时间（30分钟）
    paid_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    
    -- 元数据
    metadata JSONB DEFAULT '{}', -- 订单额外信息
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
    callback_type VARCHAR(50) NOT NULL, -- 'payment_success', 'payment_failed', 'refund_success'
    provider VARCHAR(50) NOT NULL,
    raw_data JSONB NOT NULL, -- 原始回调数据
    signature VARCHAR(500), -- 回调签名
    
    -- 处理状态
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    processing_result JSONB,
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 第三部分: 推荐页个性化算法扩展
-- ============================================================================

-- 5. 推荐算法配置表
CREATE TABLE IF NOT EXISTS recommendation_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    algorithm_name VARCHAR(100) NOT NULL, -- 'collaborative_filtering', 'content_based', 'hybrid'
    algorithm_version VARCHAR(20) NOT NULL,
    
    -- 算法参数
    parameters JSONB NOT NULL DEFAULT '{}',
    weights JSONB DEFAULT '{}', -- 各因子权重
    
    -- 适用范围
    target_user_types TEXT[], -- ['free', 'basic', 'premium']
    content_types TEXT[], -- ['character', 'story', 'audio']
    
    -- 状态管理
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 用户推荐反馈表（扩展现有recommendation表）
CREATE TABLE IF NOT EXISTS recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recommendation_id UUID, -- 关联推荐记录
    content_type VARCHAR(50) NOT NULL,
    content_id UUID NOT NULL,
    
    -- 反馈类型
    feedback_type VARCHAR(50) NOT NULL, -- 'click', 'like', 'dislike', 'share', 'favorite', 'skip'
    feedback_value DECIMAL(3,2), -- 反馈权重值 0.0-1.0
    
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
-- 第四部分: 智能体页面生态系统
-- ============================================================================

-- 7. 自定义智能体表
CREATE TABLE IF NOT EXISTS custom_agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- 基本信息
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    description TEXT,
    category VARCHAR(50), -- 'assistant', 'creative', 'educational', 'entertainment'
    
    -- 智能体配置
    personality_config JSONB NOT NULL DEFAULT '{}', -- 性格配置
    knowledge_base JSONB DEFAULT '{}', -- 知识库配置
    conversation_style JSONB DEFAULT '{}', -- 对话风格
    capabilities TEXT[], -- 能力标签
    
    -- 运行配置
    model_config JSONB DEFAULT '{}', -- AI模型配置
    response_settings JSONB DEFAULT '{}', -- 响应设置
    safety_filters JSONB DEFAULT '{}', -- 安全过滤器
    
    -- 权限与可见性
    visibility VARCHAR(20) DEFAULT 'private', -- 'private', 'public', 'unlisted'
    is_approved BOOLEAN DEFAULT false, -- 是否通过审核
    approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    
    -- 使用统计
    usage_count INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0,
    
    -- 状态管理
    status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'active', 'suspended', 'deleted'
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
    status VARCHAR(20) NOT NULL DEFAULT 'stopped', -- 'running', 'stopped', 'error', 'maintenance'
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
    health_check_status VARCHAR(20) DEFAULT 'unknown', -- 'healthy', 'unhealthy', 'unknown'
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
    permission_type VARCHAR(50) NOT NULL, -- 'view', 'chat', 'edit', 'admin'
    granted_by UUID REFERENCES users(id), -- 授权者
    
    -- 权限限制
    usage_limit INTEGER, -- 使用次数限制，NULL表示无限制
    usage_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ, -- 权限过期时间
    
    -- 状态
    is_active BOOLEAN DEFAULT true,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    
    -- 唯一约束：同一用户对同一智能体的同一权限类型只能有一条记录
    UNIQUE(agent_id, user_id, permission_type)
);

-- ============================================================================
-- 第五部分: 会员权益页面功能
-- ============================================================================

-- 10. 会员权益配置表
CREATE TABLE IF NOT EXISTS membership_benefits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    benefit_code VARCHAR(50) UNIQUE NOT NULL, -- 'unlimited_chat', 'premium_characters', 'cloud_storage'
    benefit_name VARCHAR(100) NOT NULL,
    benefit_category VARCHAR(50) NOT NULL, -- 'core', 'content', 'storage', 'social', 'support'
    
    -- 权益描述
    description TEXT,
    icon_name VARCHAR(50), -- 图标名称
    
    -- 适用计划
    applicable_plans TEXT[] NOT NULL, -- ['basic', 'premium', 'lifetime']
    
    -- 权益限制
    limit_config JSONB DEFAULT '{}', -- 限制配置
    
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
('unlimited_chat', 'AI助手无限制', 'core', '不限次数使用AI创作助手', 'robot', '["basic", "premium", "lifetime"]', '{"daily_limit": -1}', 1, true),
('premium_characters', '专属AI角色', 'content', '解锁200+专属AI聊天角色', 'users', '["basic", "premium", "lifetime"]', '{"character_access": "premium"}', 2, true),
('priority_response', '优先响应', 'core', 'AI回复速度提升3倍', 'zap', '["premium", "lifetime"]', '{"priority_level": "high"}', 3, true),
('cloud_storage', '云端存储', 'storage', '专属云端存储空间', 'database', '["basic", "premium", "lifetime"]', '{"storage_gb": {"basic": 1, "premium": 10, "lifetime": -1}}', 4, false),
('custom_themes', '专属主题', 'content', '独享精美界面主题', 'palette', '["premium", "lifetime"]', '{}', 5, false),
('ad_free', '无广告体验', 'core', '享受纯净无干扰环境', 'shield', '["basic", "premium", "lifetime"]', '{}', 6, false);

-- 11. 会员权益使用记录表
CREATE TABLE IF NOT EXISTS membership_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    membership_id UUID REFERENCES user_memberships(id) ON DELETE CASCADE,
    benefit_code VARCHAR(50) NOT NULL,
    
    -- 使用信息
    usage_type VARCHAR(50) NOT NULL, -- 'daily_reset', 'feature_used', 'limit_check'
    usage_amount INTEGER DEFAULT 1,
    
    -- 上下文信息
    feature_context VARCHAR(100), -- 具体使用的功能
    session_id UUID,
    metadata JSONB DEFAULT '{}',
    
    -- 时间信息
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 第六部分: 综合页Tab状态管理
-- ============================================================================

-- 12. 用户Tab偏好设置表
CREATE TABLE IF NOT EXISTS user_tab_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Tab偏好配置
    default_tab VARCHAR(50) DEFAULT 'comprehensive', -- 默认打开的Tab
    tab_order TEXT[] DEFAULT '["assistant", "fm", "comprehensive", "selection"]',
    hidden_tabs TEXT[] DEFAULT '[]',
    
    -- 子Tab偏好
    comprehensive_default_subtab VARCHAR(50) DEFAULT 'recommend',
    subtab_preferences JSONB DEFAULT '{}',
    
    -- 个性化设置
    quick_actions TEXT[] DEFAULT '[]', -- 快捷操作配置
    layout_preferences JSONB DEFAULT '{}',
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 确保每个用户只有一条偏好记录
    UNIQUE(user_id)
);

-- ============================================================================
-- 第七部分: 索引优化
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
-- 第八部分: 数据库函数和触发器
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
BEGIN
    -- 当订单状态变为已支付时，更新用户会员状态
    IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
        -- 获取套餐信息
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
            ON CONFLICT (user_id, status) DO UPDATE SET
                plan_id = NEW.plan_id,
                started_at = NOW(),
                expires_at = new_expires_at,
                updated_at = NOW();
        END;
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
-- 第九部分: 数据完整性和约束
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
-- 第十部分: 默认数据和配置
-- ============================================================================

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
 '["premium", "lifetime"]', '["character", "story", "audio"]', true, 3);

-- 更新迁移日志状态
UPDATE migration_logs 
SET status = 'completed', 
    completed_at = NOW() 
WHERE migration_name = 'Sprint 3 Complete Database Extension' 
  AND migration_version = '3.0.0';

-- ============================================================================
-- Sprint 3 数据库模型设计完成
-- ============================================================================

-- 生成模型总结
DO $$
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Sprint 3 数据库模型部署完成';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '新增数据表: 12个核心业务表';
    RAISE NOTICE '新增索引: 15个性能优化索引';
    RAISE NOTICE '新增函数: 4个业务逻辑函数';
    RAISE NOTICE '新增触发器: 2个自动化触发器';
    RAISE NOTICE '新增约束: 6个数据完整性约束';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '商业化功能: 订阅套餐、支付系统、会员权益';
    RAISE NOTICE '个性化功能: 推荐算法、用户反馈、偏好设置';
    RAISE NOTICE '智能体生态: 自定义智能体、权限管理、运行状态';
    RAISE NOTICE '==========================================';
END $$;