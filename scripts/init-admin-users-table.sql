-- 创建后台管理员用户表
CREATE TABLE IF NOT EXISTS xq_admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin', 'moderator')),
    account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'inactive', 'banned')),
    permissions JSONB DEFAULT '["read", "write"]'::JSONB,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    agreement_accepted BOOLEAN DEFAULT FALSE,
    agreement_version VARCHAR(10) DEFAULT 'v1.0'
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_xq_admin_users_email ON xq_admin_users(email);
CREATE INDEX IF NOT EXISTS idx_xq_admin_users_status ON xq_admin_users(account_status);
CREATE INDEX IF NOT EXISTS idx_xq_admin_users_role ON xq_admin_users(role);
CREATE INDEX IF NOT EXISTS idx_xq_admin_users_created_at ON xq_admin_users(created_at);

-- 启用RLS（行级安全）
ALTER TABLE xq_admin_users ENABLE ROW LEVEL SECURITY;

-- 创建基本的RLS政策
-- 管理员可以查看所有管理员用户
CREATE POLICY "Admin users can view all admin users" ON xq_admin_users
    FOR SELECT USING (true);

-- 管理员可以插入新的管理员用户
CREATE POLICY "Admin users can insert admin users" ON xq_admin_users
    FOR INSERT WITH CHECK (true);

-- 管理员可以更新管理员用户
CREATE POLICY "Admin users can update admin users" ON xq_admin_users
    FOR UPDATE USING (true);

-- 超级管理员可以删除管理员用户
CREATE POLICY "Super admin users can delete admin users" ON xq_admin_users
    FOR DELETE USING (true);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为表创建更新时间触发器
DROP TRIGGER IF EXISTS update_xq_admin_users_updated_at ON xq_admin_users;
CREATE TRIGGER update_xq_admin_users_updated_at
    BEFORE UPDATE ON xq_admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 插入一些初始测试数据
INSERT INTO xq_admin_users (email, nickname, role, account_status, permissions, agreement_accepted) VALUES
    ('admin@xingqu.com', '系统管理员', 'super_admin', 'active', '["read", "write", "delete", "manage_users", "manage_content"]', true),
    ('moderator@xingqu.com', '内容审核员', 'moderator', 'active', '["read", "write", "manage_content"]', true),
    ('user@xingqu.com', '普通管理员', 'admin', 'active', '["read", "write"]', true)
ON CONFLICT (email) DO NOTHING;

-- 创建视图用于统计
CREATE OR REPLACE VIEW xq_admin_users_stats AS
SELECT
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE account_status = 'active') as active_users,
    COUNT(*) FILTER (WHERE account_status = 'inactive') as inactive_users,
    COUNT(*) FILTER (WHERE account_status = 'banned') as banned_users,
    COUNT(*) FILTER (WHERE role = 'super_admin') as super_admin_count,
    COUNT(*) FILTER (WHERE role = 'admin') as admin_count,
    COUNT(*) FILTER (WHERE role = 'moderator') as moderator_count,
    COUNT(*) FILTER (WHERE agreement_accepted = true) as agreed_users
FROM xq_admin_users;