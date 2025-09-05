-- 星趣后台管理系统优化 - 系统配置和A/B测试功能
-- Migration 003: 创建系统配置相关表
-- Created: 2025-09-05
-- Purpose: 支持系统配置管理和A/B测试功能

-- ==============================================
-- 系统配置管理
-- ==============================================

-- 系统配置表
CREATE TABLE IF NOT EXISTS xq_system_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(100) NOT NULL, -- 配置分类：app, ai, payment, notification, security等
    config_key VARCHAR(200) NOT NULL, -- 配置键名
    config_value JSONB NOT NULL, -- 配置值，支持复杂数据结构
    data_type VARCHAR(50) DEFAULT 'string', -- 数据类型：string, number, boolean, object, array
    description TEXT, -- 配置项描述
    validation_rules JSONB DEFAULT '{}', -- 验证规则配置
    is_active BOOLEAN DEFAULT TRUE, -- 是否启用
    is_public BOOLEAN DEFAULT FALSE, -- 是否对前端公开
    requires_restart BOOLEAN DEFAULT FALSE, -- 修改后是否需要重启服务
    environment VARCHAR(20) DEFAULT 'all', -- 适用环境：development, staging, production, all
    updated_by UUID REFERENCES xq_xq_admin_users(id), -- 最后修改人
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 唯一约束：同一分类下的键名唯一
    UNIQUE(category, config_key)
);

-- 系统配置索引
CREATE INDEX IF NOT EXISTS idx_xq_system_configurations_category ON xq_system_configurations(category);
CREATE INDEX IF NOT EXISTS idx_xq_system_configurations_key ON xq_system_configurations(config_key);
CREATE INDEX IF NOT EXISTS idx_xq_system_configurations_active ON xq_system_configurations(is_active);
CREATE INDEX IF NOT EXISTS idx_xq_system_configurations_public ON xq_system_configurations(is_public);
CREATE INDEX IF NOT EXISTS idx_xq_system_configurations_environment ON xq_system_configurations(environment);

-- 配置变更历史表
CREATE TABLE IF NOT EXISTS xq_system_config_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_id UUID NOT NULL REFERENCES xq_system_configurations(id) ON DELETE CASCADE,
    old_value JSONB, -- 修改前的值
    new_value JSONB NOT NULL, -- 修改后的值
    change_reason TEXT, -- 修改原因
    changed_by UUID NOT NULL REFERENCES xq_xq_admin_users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 配置历史索引
CREATE INDEX IF NOT EXISTS idx_xq_system_config_history_config_id ON xq_system_config_history(config_id);
CREATE INDEX IF NOT EXISTS idx_xq_system_config_history_changed_at ON xq_system_config_history(changed_at);
CREATE INDEX IF NOT EXISTS idx_xq_system_config_history_changed_by ON xq_system_config_history(changed_by);

-- ==============================================
-- A/B测试管理
-- ==============================================

-- A/B测试配置表
CREATE TABLE IF NOT EXISTS xq_ab_test_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL, -- 测试名称
    description TEXT, -- 测试描述
    feature_flag VARCHAR(100) NOT NULL, -- 功能标识
    status VARCHAR(20) DEFAULT 'draft', -- 状态：draft, running, paused, completed, cancelled
    
    -- 测试配置
    variants JSONB NOT NULL DEFAULT '[]', -- 测试变体配置 [{"name": "control", "weight": 50}, {"name": "variant_a", "weight": 50}]
    traffic_allocation DECIMAL(5,4) DEFAULT 1.0000, -- 流量分配比例 (0-1)
    target_audience JSONB DEFAULT '{}', -- 目标用户条件
    success_metrics JSONB DEFAULT '[]', -- 成功指标定义
    
    -- 时间控制
    start_date TIMESTAMP WITH TIME ZONE, -- 开始时间
    end_date TIMESTAMP WITH TIME ZONE, -- 结束时间
    duration_days INTEGER, -- 持续天数
    
    -- 统计信息
    total_participants INTEGER DEFAULT 0, -- 总参与用户数
    conversion_rate DECIMAL(8,6), -- 转化率
    statistical_significance DECIMAL(5,4), -- 统计显著性
    confidence_level DECIMAL(5,4) DEFAULT 0.95, -- 置信水平
    
    -- 管理信息
    created_by UUID NOT NULL REFERENCES xq_admin_users(id),
    updated_by UUID REFERENCES xq_admin_users(id),
    approved_by UUID REFERENCES xq_admin_users(id), -- 审批人
    approved_at TIMESTAMP WITH TIME ZONE, -- 审批时间
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- A/B测试索引
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_configs_name ON xq_ab_test_configs(name);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_configs_feature_flag ON xq_ab_test_configs(feature_flag);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_configs_status ON xq_ab_test_configs(status);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_configs_start_date ON xq_ab_test_configs(start_date);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_configs_created_by ON xq_ab_test_configs(created_by);

-- A/B测试参与记录表
CREATE TABLE IF NOT EXISTS xq_ab_test_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID NOT NULL REFERENCES xq_ab_test_configs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- 参与用户ID
    variant VARCHAR(100) NOT NULL, -- 分配的变体
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 分配时间
    converted BOOLEAN DEFAULT FALSE, -- 是否转化
    conversion_value DECIMAL(10,2) DEFAULT 0, -- 转化价值
    metadata JSONB DEFAULT '{}', -- 额外元数据
    
    -- 唯一约束：用户在同一测试中只能参与一次
    UNIQUE(test_id, user_id)
);

-- A/B测试参与记录索引
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_participants_test_id ON xq_ab_test_participants(test_id);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_participants_user_id ON xq_ab_test_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_participants_variant ON xq_ab_test_participants(variant);
CREATE INDEX IF NOT EXISTS idx_xq_ab_test_participants_converted ON xq_ab_test_participants(converted);

-- ==============================================
-- 功能开关管理
-- ==============================================

-- 功能开关表
CREATE TABLE IF NOT EXISTS xq_feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL, -- 功能标识名
    display_name VARCHAR(200) NOT NULL, -- 显示名称
    description TEXT, -- 功能描述
    flag_type VARCHAR(50) DEFAULT 'boolean', -- 开关类型：boolean, percentage, config
    is_enabled BOOLEAN DEFAULT FALSE, -- 是否启用
    
    -- 高级配置
    config_value JSONB DEFAULT '{}', -- 配置值（用于config类型）
    percentage_enabled DECIMAL(5,4) DEFAULT 0, -- 启用百分比（用于percentage类型）
    target_audience JSONB DEFAULT '{}', -- 目标用户规则
    environments JSONB DEFAULT '["production"]', -- 适用环境
    
    -- 依赖和冲突
    dependencies JSONB DEFAULT '[]', -- 依赖的其他功能开关
    conflicts JSONB DEFAULT '[]', -- 冲突的功能开关
    
    -- 管理信息
    owner_team VARCHAR(100), -- 负责团队
    created_by UUID NOT NULL REFERENCES xq_admin_users(id),
    updated_by UUID REFERENCES xq_admin_users(id),
    
    -- 生命周期
    expires_at TIMESTAMP WITH TIME ZONE, -- 过期时间
    archived BOOLEAN DEFAULT FALSE, -- 是否归档
    archived_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 功能开关索引
CREATE INDEX IF NOT EXISTS idx_xq_feature_flags_name ON xq_feature_flags(name);
CREATE INDEX IF NOT EXISTS idx_xq_feature_flags_enabled ON xq_feature_flags(is_enabled);
CREATE INDEX IF NOT EXISTS idx_xq_feature_flags_type ON xq_feature_flags(flag_type);
CREATE INDEX IF NOT EXISTS idx_xq_feature_flags_archived ON xq_feature_flags(archived);
CREATE INDEX IF NOT EXISTS idx_xq_feature_flags_expires_at ON xq_feature_flags(expires_at);

-- 功能开关使用日志表
CREATE TABLE IF NOT EXISTS xq_feature_flag_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_id UUID NOT NULL REFERENCES xq_feature_flags(id) ON DELETE CASCADE,
    user_id UUID, -- 使用用户ID（可选）
    result BOOLEAN NOT NULL, -- 开关结果
    variant VARCHAR(100), -- 变体（如果有的话）
    context JSONB DEFAULT '{}', -- 上下文信息
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 使用日志分区（按月分区）
CREATE INDEX IF NOT EXISTS idx_xq_feature_flag_usage_logs_flag_timestamp ON xq_feature_flag_usage_logs(flag_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_xq_feature_flag_usage_logs_user ON xq_feature_flag_usage_logs(user_id);

-- ==============================================
-- 系统通知和公告
-- ==============================================

-- 系统公告表
CREATE TABLE IF NOT EXISTS xq_system_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL, -- 公告标题
    content TEXT NOT NULL, -- 公告内容
    announcement_type VARCHAR(50) DEFAULT 'info', -- 类型：info, warning, error, success, maintenance
    priority INTEGER DEFAULT 3, -- 优先级：1-5
    
    -- 显示控制
    is_active BOOLEAN DEFAULT TRUE,
    is_sticky BOOLEAN DEFAULT FALSE, -- 是否置顶
    show_in_dashboard BOOLEAN DEFAULT TRUE, -- 是否在仪表板显示
    show_popup BOOLEAN DEFAULT FALSE, -- 是否弹窗显示
    
    -- 目标受众
    target_roles JSONB DEFAULT '["all"]', -- 目标角色
    target_users JSONB DEFAULT '[]', -- 特定目标用户
    
    -- 时间控制
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    
    -- 统计信息
    view_count INTEGER DEFAULT 0, -- 查看次数
    click_count INTEGER DEFAULT 0, -- 点击次数
    
    created_by UUID NOT NULL REFERENCES xq_admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 系统公告索引
CREATE INDEX IF NOT EXISTS idx_xq_system_announcements_active ON xq_system_announcements(is_active);
CREATE INDEX IF NOT EXISTS idx_xq_system_announcements_type ON xq_system_announcements(announcement_type);
CREATE INDEX IF NOT EXISTS idx_xq_system_announcements_priority ON xq_system_announcements(priority);
CREATE INDEX IF NOT EXISTS idx_xq_system_announcements_start_time ON xq_system_announcements(start_time);

-- ==============================================
-- 数据完整性约束
-- ==============================================

-- A/B测试状态约束
ALTER TABLE xq_ab_test_configs DROP CONSTRAINT IF EXISTS chk_xq_ab_test_status;
ALTER TABLE xq_ab_test_configs ADD CONSTRAINT chk_xq_ab_test_status
    CHECK (status IN ('draft', 'running', 'paused', 'completed', 'cancelled'));

-- A/B测试流量分配约束
ALTER TABLE xq_ab_test_configs DROP CONSTRAINT IF EXISTS chk_xq_ab_test_traffic;
ALTER TABLE xq_ab_test_configs ADD CONSTRAINT chk_xq_ab_test_traffic
    CHECK (traffic_allocation >= 0 AND traffic_allocation <= 1);

-- 功能开关百分比约束
ALTER TABLE xq_feature_flags DROP CONSTRAINT IF EXISTS chk_xq_feature_flags_percentage;
ALTER TABLE xq_feature_flags ADD CONSTRAINT chk_xq_feature_flags_percentage
    CHECK (percentage_enabled >= 0 AND percentage_enabled <= 1);

-- 公告优先级约束
ALTER TABLE xq_system_announcements DROP CONSTRAINT IF EXISTS chk_xq_announcements_priority;
ALTER TABLE xq_system_announcements ADD CONSTRAINT chk_xq_announcements_priority
    CHECK (priority BETWEEN 1 AND 5);

-- A/B测试时间约束
ALTER TABLE xq_ab_test_configs DROP CONSTRAINT IF EXISTS chk_xq_ab_test_dates;
ALTER TABLE xq_ab_test_configs ADD CONSTRAINT chk_xq_ab_test_dates
    CHECK (start_date IS NULL OR end_date IS NULL OR start_date < end_date);

-- ==============================================
-- 触发器和函数
-- ==============================================

-- 配置变更自动记录历史
CREATE OR REPLACE FUNCTION record_config_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 记录配置变更历史
    INSERT INTO xq_system_config_history (
        config_id, old_value, new_value, changed_by, change_reason
    ) VALUES (
        NEW.id,
        OLD.config_value,
        NEW.config_value,
        NEW.updated_by,
        '系统自动记录'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为系统配置表添加变更历史触发器
CREATE TRIGGER trigger_xq_system_configurations_history
    AFTER UPDATE OF config_value ON xq_system_configurations
    FOR EACH ROW
    WHEN (OLD.config_value IS DISTINCT FROM NEW.config_value)
    EXECUTE FUNCTION record_config_change();

-- 添加更新时间戳触发器
CREATE TRIGGER trigger_xq_system_configurations_updated_at
    BEFORE UPDATE ON xq_system_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_xq_ab_test_configs_updated_at
    BEFORE UPDATE ON xq_ab_test_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_xq_feature_flags_updated_at
    BEFORE UPDATE ON xq_feature_flags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_xq_system_announcements_updated_at
    BEFORE UPDATE ON xq_system_announcements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- 权限设置 (RLS)
-- ==============================================

-- 启用行级安全策略
ALTER TABLE xq_system_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_ab_test_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_system_announcements ENABLE ROW LEVEL SECURITY;

-- 系统配置访问策略
CREATE POLICY "管理员可管理系统配置" ON xq_system_configurations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'technical')
        )
    );

CREATE POLICY "运营人员可查看公开配置" ON xq_system_configurations
    FOR SELECT USING (
        is_public = true OR EXISTS (
            SELECT 1 FROM xq_admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
        )
    );

-- A/B测试访问策略
CREATE POLICY "产品和运营可管理AB测试" ON xq_ab_test_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'operator')
        )
    );

-- 功能开关访问策略
CREATE POLICY "技术和产品可管理功能开关" ON xq_feature_flags
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'technical', 'operator')
        )
    );

-- 系统公告访问策略
CREATE POLICY "管理员可管理系统公告" ON xq_system_announcements
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
        )
    );

-- ==============================================
-- 默认数据插入
-- ==============================================

-- 插入默认系统配置
INSERT INTO xq_system_configurations (category, config_key, config_value, data_type, description, is_public) VALUES
-- 应用基础配置
('app', 'app_name', '"星趣App管理后台"', 'string', '应用名称', true),
('app', 'app_version', '"1.0.0"', 'string', '应用版本', true),
('app', 'maintenance_mode', 'false', 'boolean', '维护模式开关', false),
('app', 'max_upload_size', '10485760', 'number', '最大上传文件大小（字节）', false),

-- AI服务配置
('ai', 'daily_conversation_limit_free', '10', 'number', '免费用户每日对话限制', false),
('ai', 'daily_conversation_limit_basic', '-1', 'number', '基础会员每日对话限制（-1为无限制）', false),
('ai', 'ai_response_timeout', '30000', 'number', 'AI响应超时时间（毫秒）', false),
('ai', 'enable_voice_messages', 'true', 'boolean', '是否启用语音消息功能', false),

-- 支付配置
('payment', 'supported_methods', '["wechat", "alipay", "apple_pay"]', 'array', '支持的支付方式', false),
('payment', 'currency', '"CNY"', 'string', '默认货币', false),
('payment', 'refund_window_days', '7', 'number', '退款申请窗口期（天）', false),

-- 通知配置
('notification', 'email_notifications_enabled', 'true', 'boolean', '邮件通知开关', false),
('notification', 'push_notifications_enabled', 'true', 'boolean', '推送通知开关', false),
('notification', 'maintenance_notification_hours', '24', 'number', '维护通知提前小时数', false),

-- 安全配置
('security', 'max_login_attempts', '5', 'number', '最大登录尝试次数', false),
('security', 'account_lockout_duration', '30', 'number', '账号锁定时长（分钟）', false),
('security', 'session_timeout_minutes', '480', 'number', '会话超时时间（分钟）', false),
('security', 'enable_two_factor_auth', 'false', 'boolean', '是否启用双因素认证', false)

ON CONFLICT (category, config_key) DO UPDATE SET
    config_value = EXCLUDED.config_value,
    description = EXCLUDED.description,
    updated_at = NOW();

-- 插入默认功能开关
INSERT INTO xq_feature_flags (name, display_name, description, is_enabled, created_by) VALUES
('voice_messages', '语音消息功能', '用户可以发送和接收语音消息', true, 
 (SELECT id FROM xq_admin_users WHERE email = 'admin@xingqu.com' LIMIT 1)),
('ai_image_generation', 'AI图像生成', '用户可以使用AI生成图像', false,
 (SELECT id FROM xq_admin_users WHERE email = 'admin@xingqu.com' LIMIT 1)),
('premium_models', '高级AI模型', '高级会员可以使用更先进的AI模型', true,
 (SELECT id FROM xq_admin_users WHERE email = 'admin@xingqu.com' LIMIT 1)),
('user_feedback', '用户反馈系统', '用户可以提交反馈和建议', true,
 (SELECT id FROM xq_admin_users WHERE email = 'admin@xingqu.com' LIMIT 1))

ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    updated_at = NOW();

-- ==============================================
-- 迁移完成标记
-- ==============================================

-- 记录迁移执行
INSERT INTO xq_admin_metrics (metric_name, metric_value, metric_unit, tags)
VALUES ('migration_executed', 3, 'count', '{"migration": "003_system_configs", "executed_at": "' || NOW()::text || '"}'::jsonb);

-- 迁移脚本结束
COMMENT ON TABLE xq_system_configurations IS '系统配置参数表';
COMMENT ON TABLE xq_system_config_history IS '系统配置变更历史表';
COMMENT ON TABLE xq_ab_test_configs IS 'A/B测试配置表';
COMMENT ON TABLE xq_ab_test_participants IS 'A/B测试参与者记录表';
COMMENT ON TABLE xq_feature_flags IS '功能开关配置表';
COMMENT ON TABLE xq_feature_flag_usage_logs IS '功能开关使用日志表';
COMMENT ON TABLE xq_system_announcements IS '系统公告通知表';