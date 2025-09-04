const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const path = require('path')

// Supabase配置
const supabaseUrl = 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.HnHxsL2pZxHqJf7qZQKT_wXe7Y0aRoA1VSMHjgUP7JE'

// 数据库密码
const dbPassword = '7232527xyznByEp'

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function executeSQL() {
  console.log('🚀 开始执行数据库SQL初始化...')
  
  try {
    // 直接使用 Supabase 的原生 REST API 来执行 SQL
    console.log('📝 准备执行SQL语句...')
    
    // 方法1: 直接插入数据测试表是否存在
    console.log('🔍 测试1: 尝试插入测试数据...')
    
    const testUser = {
      email: 'admin@xingqu.com',
      nickname: '系统管理员',
      role: 'super_admin',
      account_status: 'active',
      permissions: ['read', 'write', 'delete', 'manage_users', 'manage_content'],
      agreement_accepted: true
    }
    
    const { data: insertData, error: insertError } = await supabase
      .from('xq_admin_users')
      .insert(testUser)
      .select()
    
    if (insertError) {
      if (insertError.message.includes('does not exist')) {
        console.log('❌ 表不存在，需要先创建表')
        
        // 尝试使用 rpc 执行建表语句
        console.log('🛠️  尝试创建表...')
        
        const createTableSQL = `
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
);`
        
        // 使用 rpc 调用 sql 函数
        const { data: rpcData, error: rpcError } = await supabase.rpc('exec', {
          sql: createTableSQL
        })
        
        if (rpcError) {
          console.log('❌ RPC执行失败:', rpcError.message)
          console.log('💡 请手动在Supabase Dashboard中执行SQL')
          
          // 显示完整的SQL
          const fullSQL = fs.readFileSync(path.join(__dirname, 'init-admin-users-table.sql'), 'utf8')
          console.log('\n📋 完整的SQL代码:')
          console.log('='  .repeat(80))
          console.log(fullSQL)
          console.log('=' .repeat(80))
          
          return
        } else {
          console.log('✅ 表创建成功，重试插入数据...')
          
          // 重新尝试插入
          const { data: retryData, error: retryError } = await supabase
            .from('xq_admin_users')
            .insert(testUser)
            .select()
          
          if (retryError) {
            console.log('❌ 重试插入失败:', retryError.message)
          } else {
            console.log('✅ 数据插入成功!')
          }
        }
      } else {
        console.log('❌ 插入数据失败:', insertError.message)
      }
    } else {
      console.log('✅ 数据插入成功，表已存在!')
      console.log('📊 插入的用户:', insertData)
    }
    
    // 测试查询所有数据
    console.log('\n📊 查询现有的管理员用户...')
    const { data: allUsers, error: selectError } = await supabase
      .from('xq_admin_users')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (selectError) {
      console.log('❌ 查询失败:', selectError.message)
    } else {
      console.log(`✅ 查询成功，共有 ${allUsers.length} 个管理员用户:`)
      allUsers.forEach((user, index) => {
        console.log(`  ${index + 1}. ${user.nickname} (${user.email}) - ${user.role} - ${user.account_status}`)
      })
    }
    
    // 如果数据不足，继续插入其他用户
    if (allUsers && allUsers.length < 3) {
      console.log('\n👥 插入其他测试用户...')
      
      const otherUsers = [
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
      
      for (const user of otherUsers) {
        const { data: userData, error: userError } = await supabase
          .from('xq_admin_users')
          .upsert(user, { onConflict: 'email' })
          .select()
        
        if (userError) {
          console.log(`❌ 创建用户 ${user.nickname} 失败:`, userError.message)
        } else {
          console.log(`✅ 用户 ${user.nickname} 创建/更新成功`)
        }
      }
    }
    
    console.log('\n🎉 数据库初始化完成!')
    
  } catch (error) {
    console.error('❌ 执行失败:', error)
  }
}

// 执行
executeSQL()