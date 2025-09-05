-- 星趣后台管理系统优化 - 数据库表创建脚本
-- Migration 001: 创建管理系统核心表
-- Created: 2025-09-05
-- Purpose: 建立监控、商业化、权限管理等功能的数据库基础结构

-- ==============================================
-- 监控相关表
-- ==============================================

-- 系统监控指标表
CREATE TABLE IF NOT EXISTS xq_admin_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC NOT NULL,
    metric_unit VARCHAR(20),
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 添加索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_xq_admin_metrics_name_time ON xq_admin_metrics(metric_name, timestamp);
CREATE INDEX IF NOT EXISTS idx_xq_admin_metrics_timestamp ON xq_admin_metrics(timestamp);

-- 系统告警表
CREATE TABLE IF NOT EXISTS xq_admin_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(50) NOT NULL, -- 'warning', 'error', 'info', 'success'
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    metric_name VARCHAR(100),
    threshold_value NUMERIC,
    current_value NUMERIC,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'acknowledged', 'resolved'
    acknowledged_by UUID, -- 将在后续迁移中添加外键约束
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 告警表索引
CREATE INDEX IF NOT EXISTS idx_xq_admin_alerts_status_created ON xq_admin_alerts(status, created_at);
CREATE INDEX IF NOT EXISTS idx_xq_admin_alerts_metric_name ON xq_admin_alerts(metric_name);
CREATE INDEX IF NOT EXISTS idx_xq_admin_alerts_created_at ON xq_admin_alerts(created_at);

-- ==============================================
-- 商业化相关表
-- ==============================================

-- 订阅计划表
CREATE TABLE IF NOT EXISTS xq_subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'CNY',
    duration_days INTEGER NOT NULL,
    features JSONB NOT NULL DEFAULT '[]',
    limitations JSONB DEFAULT '{}', -- 使用限制，如每日AI调用次数等
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 订阅计划索引
CREATE INDEX IF NOT EXISTS idx_xq_subscription_plans_active_sort ON xq_subscription_plans(is_active, sort_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_xq_subscription_plans_name ON xq_subscription_plans(name) WHERE is_active = TRUE;

-- 用户订阅表
CREATE TABLE IF NOT EXISTS xq_user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- 关联到xq_user_profiles表
    plan_id UUID NOT NULL REFERENCES xq_subscription_plans(id),
    status VARCHAR(20) NOT NULL, -- 'active', 'expired', 'cancelled', 'pending'
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT FALSE,
    renewal_price DECIMAL(10,2), -- 续费价格，可能与原价不同
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户订阅索引
CREATE INDEX IF NOT EXISTS idx_xq_user_subscriptions_user_id_status ON xq_user_subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_xq_user_subscriptions_expires_at ON xq_user_subscriptions(expires_at);
CREATE INDEX IF NOT EXISTS idx_xq_user_subscriptions_plan_id ON xq_user_subscriptions(plan_id);

-- 支付订单表
CREATE TABLE IF NOT EXISTS xq_payment_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL, -- 订单号
    user_id UUID NOT NULL, -- 关联到xq_user_profiles表
    plan_id UUID NOT NULL REFERENCES xq_subscription_plans(id),
    subscription_id UUID REFERENCES xq_user_subscriptions(id), -- 关联的订阅记录
    amount DECIMAL(10,2) NOT NULL, -- 支付金额
    currency VARCHAR(3) DEFAULT 'CNY',
    status VARCHAR(20) NOT NULL, -- 'pending', 'completed', 'failed', 'refunded', 'cancelled'
    payment_method VARCHAR(50), -- 'wechat', 'alipay', 'card', 'apple_pay', etc.
    payment_provider VARCHAR(50), -- 第三方支付提供商
    transaction_id VARCHAR(200), -- 第三方交易ID
    payment_data JSONB, -- 支付相关的额外数据
    paid_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,
    refund_amount DECIMAL(10,2),
    refund_reason TEXT,
    failure_reason TEXT, -- 支付失败原因
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 支付订单索引
CREATE INDEX IF NOT EXISTS idx_xq_payment_orders_user_id ON xq_payment_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_xq_payment_orders_status ON xq_payment_orders(status);
CREATE INDEX IF NOT EXISTS idx_xq_payment_orders_created_at ON xq_payment_orders(created_at);
CREATE INDEX IF NOT EXISTS idx_xq_payment_orders_order_number ON xq_payment_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_xq_payment_orders_transaction_id ON xq_payment_orders(transaction_id);

-- ==============================================
-- 数据完整性约束
-- ==============================================

-- 订单金额必须为正数
ALTER TABLE xq_payment_orders ADD CONSTRAINT chk_xq_payment_orders_amount_positive CHECK (amount > 0);

-- 退款金额不能超过原金额
ALTER TABLE xq_payment_orders ADD CONSTRAINT chk_xq_payment_orders_refund_amount CHECK (
    refund_amount IS NULL OR (refund_amount > 0 AND refund_amount <= amount)
);

-- 订阅计划价格必须为非负数
ALTER TABLE xq_subscription_plans ADD CONSTRAINT chk_xq_subscription_plans_price CHECK (price >= 0);

-- 订阅时长必须为正数
ALTER TABLE xq_subscription_plans ADD CONSTRAINT chk_xq_subscription_plans_duration CHECK (duration_days > 0);

-- 订阅开始时间必须早于结束时间
ALTER TABLE xq_user_subscriptions ADD CONSTRAINT chk_xq_user_subscriptions_dates CHECK (started_at < expires_at);

-- ==============================================
-- 触发器：自动更新时间戳
-- ==============================================

-- 创建更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为相关表添加自动更新时间戳触发器
CREATE TRIGGER trigger_xq_admin_alerts_updated_at
    BEFORE UPDATE ON xq_admin_alerts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_xq_subscription_plans_updated_at
    BEFORE UPDATE ON xq_subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_xq_user_subscriptions_updated_at
    BEFORE UPDATE ON xq_user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_xq_payment_orders_updated_at
    BEFORE UPDATE ON xq_payment_orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- 默认数据插入
-- ==============================================

-- 插入默认订阅计划
INSERT INTO xq_subscription_plans (name, display_name, description, price, duration_days, features, limitations, sort_order)
VALUES 
    ('free', '免费版', '基础功能，适合体验用户', 0.00, 0, 
     '["基础AI对话", "每日10次对话限制", "标准响应速度"]'::jsonb,
     '{"daily_conversations": 10, "ai_model": "basic", "storage_mb": 100}'::jsonb, 1),
    
    ('basic', '基础会员', '月付会员，解锁更多功能', 29.90, 30,
     '["无限AI对话", "高级AI模型", "语音消息", "优先响应速度", "1GB云存储"]'::jsonb,
     '{"daily_conversations": -1, "ai_model": "advanced", "storage_mb": 1024, "voice_messages": true}'::jsonb, 2),
     
    ('premium', '高级会员', '年付会员，享受最佳体验', 299.00, 365,
     '["所有基础会员功能", "最新AI模型", "无限云存储", "专属客服", "高级分析", "API访问"]'::jsonb,
     '{"daily_conversations": -1, "ai_model": "premium", "storage_mb": -1, "voice_messages": true, "api_access": true}'::jsonb, 3),
     
    ('lifetime', '终身会员', '一次购买，终身享受', 999.00, 36500,
     '["所有高级会员功能", "终身更新", "内测版本访问", "社区专属权限"]'::jsonb,
     '{"daily_conversations": -1, "ai_model": "premium", "storage_mb": -1, "voice_messages": true, "api_access": true, "beta_access": true}'::jsonb, 4)

ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    duration_days = EXCLUDED.duration_days,
    features = EXCLUDED.features,
    limitations = EXCLUDED.limitations,
    sort_order = EXCLUDED.sort_order,
    updated_at = NOW();

-- ==============================================
-- 权限设置 (RLS - Row Level Security)
-- ==============================================

-- 启用行级安全策略
ALTER TABLE xq_admin_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_admin_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_payment_orders ENABLE ROW LEVEL SECURITY;

-- 创建管理员访问策略 (将在后续迁移中完善)
-- 这里先创建基础策略，允许认证用户访问

-- 监控数据：只允许管理员查看
CREATE POLICY "管理员可查看监控指标" ON xq_admin_metrics
    FOR SELECT USING (true); -- 将在权限系统完善后限制为管理员

CREATE POLICY "管理员可插入监控指标" ON xq_admin_metrics
    FOR INSERT WITH CHECK (true);

-- 告警数据：只允许管理员管理
CREATE POLICY "管理员可管理告警" ON xq_admin_alerts
    FOR ALL USING (true); -- 将在权限系统完善后限制

-- 订阅计划：管理员可管理，普通用户只能查看激活的计划
CREATE POLICY "用户可查看激活的订阅计划" ON xq_subscription_plans
    FOR SELECT USING (is_active = true);

CREATE POLICY "管理员可管理订阅计划" ON xq_subscription_plans
    FOR ALL USING (true); -- 将在权限系统完善后限制为管理员

-- 用户订阅：用户只能查看自己的订阅
CREATE POLICY "用户可查看自己的订阅" ON xq_user_subscriptions
    FOR SELECT USING (user_id = auth.uid()::text::uuid);

CREATE POLICY "管理员可管理所有订阅" ON xq_user_subscriptions
    FOR ALL USING (true); -- 将在权限系统完善后限制为管理员

-- 支付订单：用户只能查看自己的订单
CREATE POLICY "用户可查看自己的订单" ON xq_payment_orders
    FOR SELECT USING (user_id = auth.uid()::text::uuid);

CREATE POLICY "管理员可管理所有订单" ON xq_payment_orders
    FOR ALL USING (true); -- 将在权限系统完善后限制为管理员

-- ==============================================
-- 迁移完成标记
-- ==============================================

-- 记录迁移执行
INSERT INTO xq_admin_metrics (metric_name, metric_value, metric_unit, tags)
VALUES ('migration_executed', 1, 'count', '{"migration": "001_admin_system_tables", "executed_at": "' || NOW()::text || '"}'::jsonb);

-- 迁移脚本结束
COMMENT ON TABLE xq_admin_metrics IS '系统监控指标数据表';
COMMENT ON TABLE xq_admin_alerts IS '系统告警记录表';
COMMENT ON TABLE xq_subscription_plans IS '订阅计划配置表';
COMMENT ON TABLE xq_user_subscriptions IS '用户订阅记录表';
COMMENT ON TABLE xq_payment_orders IS '支付订单记录表';