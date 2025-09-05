-- 星趣后台管理系统优化 - 权限管理和审计功能
-- Migration 002: 扩展管理员权限表和创建审计相关表
-- Created: 2025-09-05
-- Purpose: 支持角色权限管理和审计功能

-- ==============================================
-- 管理员权限扩展
-- ==============================================

-- 首先检查是否存在admin_users表，如果不存在则创建
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    encrypted_password VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 扩展admin_users表，添加权限管理相关字段
ALTER TABLE admin_users 
ADD COLUMN IF NOT EXISTS name VARCHAR(100),
ADD COLUMN IF NOT EXISTS role VARCHAR(50) NOT NULL DEFAULT 'operator',
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS login_attempts INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS department VARCHAR(100);

-- 添加角色约束
ALTER TABLE admin_users DROP CONSTRAINT IF EXISTS chk_admin_users_role;
ALTER TABLE admin_users ADD CONSTRAINT chk_admin_users_role 
    CHECK (role IN ('super_admin', 'operator', 'moderator', 'technical'));

-- 创建管理员索引
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON admin_users(is_active);
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);

-- ==============================================
-- 操作审计日志表
-- ==============================================

-- 管理员操作日志表
CREATE TABLE IF NOT EXISTS admin_operation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL, -- 操作类型：CREATE, UPDATE, DELETE, VIEW, EXPORT, LOGIN, LOGOUT等
    resource VARCHAR(100), -- 操作的资源类型：user, order, subscription, config等
    resource_id VARCHAR(100), -- 具体资源ID
    resource_name VARCHAR(200), -- 资源名称或描述
    details JSONB DEFAULT '{}', -- 操作详细信息，包含before/after数据
    result VARCHAR(20) DEFAULT 'success', -- 操作结果：success, failed, unauthorized
    error_message TEXT, -- 错误信息
    ip_address INET, -- 操作者IP地址
    user_agent TEXT, -- 浏览器信息
    session_id VARCHAR(100), -- 会话ID
    request_id VARCHAR(100), -- 请求追踪ID
    duration_ms INTEGER, -- 操作耗时（毫秒）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 操作日志索引
CREATE INDEX IF NOT EXISTS idx_admin_operation_logs_admin_id ON admin_operation_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_operation_logs_action ON admin_operation_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_operation_logs_resource ON admin_operation_logs(resource);
CREATE INDEX IF NOT EXISTS idx_admin_operation_logs_created_at ON admin_operation_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_operation_logs_result ON admin_operation_logs(result);
CREATE INDEX IF NOT EXISTS idx_admin_operation_logs_resource_id ON admin_operation_logs(resource_id);

-- ==============================================
-- 内容审核相关表
-- ==============================================

-- 内容审核记录表
CREATE TABLE IF NOT EXISTS content_moderation_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id VARCHAR(200) NOT NULL, -- 内容ID（可能来自不同的内容表）
    content_type VARCHAR(20) NOT NULL, -- 内容类型：text, image, audio, video, user_profile等
    content_source VARCHAR(50), -- 内容来源表名
    original_content TEXT, -- 原始内容（敏感信息需要脱敏）
    moderation_result VARCHAR(20) NOT NULL, -- 审核结果：approved, rejected, pending, needs_review
    ai_confidence DECIMAL(5,4), -- AI审核置信度 (0-1)
    ai_reasons JSONB DEFAULT '[]', -- AI检测到的问题原因列表
    human_reviewer_id UUID REFERENCES admin_users(id), -- 人工审核员ID
    human_review_result VARCHAR(20), -- 人工审核结果
    human_review_reason TEXT, -- 人工审核原因
    violation_types JSONB DEFAULT '[]', -- 违规类型列表
    severity_level INTEGER DEFAULT 1, -- 严重程度：1-5级
    auto_action VARCHAR(50), -- 自动执行的操作：block, warn, delete等
    appeal_status VARCHAR(20) DEFAULT 'none', -- 申诉状态：none, submitted, reviewing, approved, rejected
    appeal_reason TEXT, -- 申诉理由
    appeal_handled_by UUID REFERENCES admin_users(id), -- 申诉处理人
    appeal_handled_at TIMESTAMP WITH TIME ZONE, -- 申诉处理时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 审核创建时间
    reviewed_at TIMESTAMP WITH TIME ZONE, -- 人工审核时间
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 审核记录索引
CREATE INDEX IF NOT EXISTS idx_content_moderation_content_id ON content_moderation_records(content_id);
CREATE INDEX IF NOT EXISTS idx_content_moderation_content_type ON content_moderation_records(content_type);
CREATE INDEX IF NOT EXISTS idx_content_moderation_result ON content_moderation_records(moderation_result);
CREATE INDEX IF NOT EXISTS idx_content_moderation_reviewer ON content_moderation_records(human_reviewer_id);
CREATE INDEX IF NOT EXISTS idx_content_moderation_created_at ON content_moderation_records(created_at);
CREATE INDEX IF NOT EXISTS idx_content_moderation_appeal_status ON content_moderation_records(appeal_status);

-- 用户举报表
CREATE TABLE IF NOT EXISTS xq_user_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID, -- 举报人ID，可能为匿名
    reported_content_id VARCHAR(200), -- 被举报的内容ID
    reported_user_id UUID, -- 被举报的用户ID
    report_type VARCHAR(50) NOT NULL, -- 举报类型：spam, inappropriate, harassment, fake, copyright等
    report_category VARCHAR(50), -- 举报分类：content, user, system
    reason TEXT NOT NULL, -- 举报原因描述
    evidence_urls JSONB DEFAULT '[]', -- 证据文件URL列表
    status VARCHAR(20) DEFAULT 'pending', -- 处理状态：pending, investigating, resolved, dismissed
    priority INTEGER DEFAULT 3, -- 优先级：1-5，1最高
    assigned_to UUID REFERENCES xq_admin_users(id), -- 分配给的处理员
    handler_notes TEXT, -- 处理员备注
    resolution TEXT, -- 处理结果说明
    handled_by UUID REFERENCES xq_admin_users(id), -- 最终处理人
    handled_at TIMESTAMP WITH TIME ZONE, -- 处理完成时间
    reporter_ip INET, -- 举报人IP
    reporter_user_agent TEXT, -- 举报人浏览器信息
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户举报索引
CREATE INDEX IF NOT EXISTS idx_user_reports_reporter_id ON user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user ON user_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_type ON user_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_user_reports_assigned_to ON user_reports(assigned_to);
CREATE INDEX IF NOT EXISTS idx_user_reports_created_at ON user_reports(created_at);
CREATE INDEX IF NOT EXISTS idx_user_reports_priority ON user_reports(priority);

-- ==============================================
-- 数据完整性约束
-- ==============================================

-- 审核结果约束
ALTER TABLE content_moderation_records DROP CONSTRAINT IF EXISTS chk_content_moderation_result;
ALTER TABLE content_moderation_records ADD CONSTRAINT chk_content_moderation_result
    CHECK (moderation_result IN ('approved', 'rejected', 'pending', 'needs_review'));

-- AI置信度约束
ALTER TABLE content_moderation_records DROP CONSTRAINT IF EXISTS chk_content_moderation_confidence;
ALTER TABLE content_moderation_records ADD CONSTRAINT chk_content_moderation_confidence
    CHECK (ai_confidence IS NULL OR (ai_confidence >= 0 AND ai_confidence <= 1));

-- 严重程度约束
ALTER TABLE content_moderation_records DROP CONSTRAINT IF EXISTS chk_content_moderation_severity;
ALTER TABLE content_moderation_records ADD CONSTRAINT chk_content_moderation_severity
    CHECK (severity_level BETWEEN 1 AND 5);

-- 举报优先级约束
ALTER TABLE user_reports DROP CONSTRAINT IF EXISTS chk_user_reports_priority;
ALTER TABLE user_reports ADD CONSTRAINT chk_user_reports_priority
    CHECK (priority BETWEEN 1 AND 5);

-- ==============================================
-- 触发器：自动更新时间戳和审计
-- ==============================================

-- 为admin_users表添加更新时间戳触发器
CREATE TRIGGER trigger_admin_users_updated_at
    BEFORE UPDATE ON admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为审核记录表添加更新时间戳触发器
CREATE TRIGGER trigger_content_moderation_updated_at
    BEFORE UPDATE ON content_moderation_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为用户举报表添加更新时间戳触发器  
CREATE TRIGGER trigger_user_reports_updated_at
    BEFORE UPDATE ON user_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 管理员操作自动记录触发器函数
CREATE OR REPLACE FUNCTION log_admin_operation()
RETURNS TRIGGER AS $$
DECLARE
    admin_id UUID;
BEGIN
    -- 尝试获取当前管理员ID（从应用层传入）
    admin_id := current_setting('app.current_admin_id', true)::UUID;
    
    -- 记录操作日志
    INSERT INTO admin_operation_logs (
        admin_id, action, resource, resource_id, details, created_at
    ) VALUES (
        COALESCE(admin_id, '00000000-0000-0000-0000-000000000000'::UUID),
        TG_OP,
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.id::TEXT
            ELSE NEW.id::TEXT
        END,
        CASE 
            WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD)
            WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW)
            ELSE jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW))
        END,
        NOW()
    );
    
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
EXCEPTION
    WHEN OTHERS THEN
        -- 如果日志记录失败，不影响主操作
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- 权限设置 (RLS - Row Level Security)
-- ==============================================

-- 启用行级安全策略
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_operation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_moderation_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

-- 管理员用户策略
CREATE POLICY "超级管理员可管理所有管理员" ON admin_users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users a 
            WHERE a.id = auth.uid() AND a.role = 'super_admin' AND a.is_active = true
        )
    );

CREATE POLICY "管理员可查看自己的信息" ON admin_users
    FOR SELECT USING (id = auth.uid());

-- 操作日志策略
CREATE POLICY "管理员可查看操作日志" ON admin_operation_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'operator')
        )
    );

CREATE POLICY "系统可插入操作日志" ON admin_operation_logs
    FOR INSERT WITH CHECK (true);

-- 审核记录策略
CREATE POLICY "审核员可管理审核记录" ON content_moderation_records
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'moderator', 'operator')
        )
    );

-- 用户举报策略
CREATE POLICY "管理员可处理用户举报" ON user_reports
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'moderator', 'operator')
        )
    );

-- ==============================================
-- 默认数据和初始化
-- ==============================================

-- 创建默认超级管理员（如果不存在）
INSERT INTO admin_users (email, name, role, is_active, permissions)
VALUES ('admin@xingqu.com', '系统管理员', 'super_admin', true, 
        '{"all": true, "modules": ["monitoring", "users", "moderation", "commerce", "system"]}'::jsonb)
ON CONFLICT (email) DO UPDATE SET
    role = EXCLUDED.role,
    permissions = EXCLUDED.permissions,
    updated_at = NOW();

-- 更新admin_alerts表的外键约束
ALTER TABLE admin_alerts 
ADD CONSTRAINT fk_admin_alerts_acknowledged_by 
FOREIGN KEY (acknowledged_by) REFERENCES admin_users(id) ON DELETE SET NULL;

-- ==============================================
-- 审核规则配置表（可选，用于配置自动审核规则）
-- ==============================================

CREATE TABLE IF NOT EXISTS moderation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    content_types JSONB NOT NULL DEFAULT '[]', -- 适用的内容类型
    rule_type VARCHAR(50) NOT NULL, -- keyword, regex, ai_threshold, length, etc.
    rule_config JSONB NOT NULL DEFAULT '{}', -- 规则配置
    action VARCHAR(50) NOT NULL, -- 触发后的行为：block, flag, warn
    severity_level INTEGER DEFAULT 3,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID NOT NULL REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moderation_rules_active ON moderation_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_moderation_rules_type ON moderation_rules(rule_type);

-- 审核规则RLS策略
ALTER TABLE moderation_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "管理员可管理审核规则" ON moderation_rules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users a 
            WHERE a.id = auth.uid() AND a.is_active = true
            AND a.role IN ('super_admin', 'moderator')
        )
    );

-- 添加更新时间戳触发器
CREATE TRIGGER trigger_moderation_rules_updated_at
    BEFORE UPDATE ON moderation_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- 迁移完成标记
-- ==============================================

-- 记录迁移执行
INSERT INTO admin_metrics (metric_name, metric_value, metric_unit, tags)
VALUES ('migration_executed', 2, 'count', '{"migration": "002_admin_permissions", "executed_at": "' || NOW()::text || '"}'::jsonb);

-- 迁移脚本结束
COMMENT ON TABLE admin_users IS '管理员用户表，包含角色和权限信息';
COMMENT ON TABLE admin_operation_logs IS '管理员操作审计日志表';
COMMENT ON TABLE content_moderation_records IS '内容审核记录表';
COMMENT ON TABLE user_reports IS '用户举报记录表';
COMMENT ON TABLE moderation_rules IS '内容审核规则配置表';