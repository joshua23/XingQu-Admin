const { createClient } = require('@supabase/supabase-js')

// Supabase配置
const supabaseUrl = 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.HnHxsL2pZxHqJf7qZQKT_wXe7Y0aRoA1VSMHjgUP7JE'

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function createTableAndInsertData() {
  console.log('🚀 开始创建表和插入数据...')
  
  try {
    // 首先尝试插入数据来测试表是否存在
    console.log('🔍 测试表是否存在...')
    const { data: testData, error: testError } = await supabase
      .from('xq_admin_users')
      .select('*')
      .limit(1)
    
    if (testError) {
      console.log('❌ 表不存在，需要在Supabase Dashboard中手动创建')
      console.log('错误信息:', testError.message)
      
      console.log('\n📋 请在Supabase Dashboard的SQL Editor中执行以下SQL:')
      console.log('='  .repeat(80))
      console.log(getCreateTableSQL())
      console.log('=' .repeat(80))
      
      return
    }
    
    console.log('✅ 表已存在!')
    
    // 插入测试数据
    console.log('📝 插入测试数据...')
    
    const testUsers = [
      {
        email: 'admin@xingqu.com',
        nickname: '系统管理员',
        role: 'super_admin',
        account_status: 'active',
        permissions: ['read', 'write', 'delete', 'manage_users', 'manage_content'],
        agreement_accepted: true
      },
      {
        email: 'moderator@xingqu.com',
        nickname: '内容审核员',
        role: 'moderator',
        account_status: 'active',
        permissions: ['read', 'write', 'manage_content'],
        agreement_accepted: true
      },
      {
        email: 'user@xingqu.com',
        nickname: '普通管理员',
        role: 'admin',
        account_status: 'active',
        permissions: ['read', 'write'],
        agreement_accepted: true
      }
    ]
    
    for (const user of testUsers) {
      console.log(`👤 创建用户: ${user.nickname}`)
      
      const { data, error } = await supabase
        .from('xq_admin_users')
        .upsert(user, { onConflict: 'email' })
        .select()
      
      if (error) {
        console.log(`❌ 创建用户 ${user.nickname} 失败:`, error.message)
      } else {
        console.log(`✅ 用户 ${user.nickname} 创建/更新成功`)
      }
    }
    
    // 查询所有数据
    console.log('\n📊 查询所有管理员用户:')
    const { data: allUsers, error: selectError } = await supabase
      .from('xq_admin_users')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (selectError) {
      console.log('❌ 查询失败:', selectError.message)
    } else {
      console.log(`📈 共有 ${allUsers.length} 个管理员用户:`)
      allUsers.forEach(user => {
        console.log(`  - ${user.nickname} (${user.email}) - ${user.role} - ${user.account_status}`)
      })
    }
    
    console.log('\n🎉 数据库初始化完成!')
    
  } catch (error) {
    console.error('❌ 执行失败:', error)
  }
}

function getCreateTableSQL() {
  return `-- 创建后台管理员用户表
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
CREATE POLICY "Admin users can view all admin users" ON xq_admin_users
    FOR SELECT USING (true);

CREATE POLICY "Admin users can insert admin users" ON xq_admin_users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin users can update admin users" ON xq_admin_users
    FOR UPDATE USING (true);

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
FROM xq_admin_users;`
}

// 执行
createTableAndInsertData()