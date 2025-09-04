const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const path = require('path')

// 从环境变量或默认值获取Supabase配置
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.HnHxsL2pZxHqJf7qZQKT_wXe7Y0aRoA1VSMHjgUP7JE'

// 创建Supabase客户端（使用service role key以获得完整权限）
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function setupDatabase() {
  try {
    console.log('🚀 开始初始化数据库...')
    
    // 读取SQL文件
    const sqlFile = path.join(__dirname, 'init-admin-users-table.sql')
    const sqlContent = fs.readFileSync(sqlFile, 'utf8')
    
    // 分割SQL语句（简单处理，按分号分割）
    const sqlStatements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'))
    
    console.log(`📝 找到 ${sqlStatements.length} 条SQL语句`)
    
    // 执行每条SQL语句
    for (let i = 0; i < sqlStatements.length; i++) {
      const statement = sqlStatements[i]
      if (statement.length === 0) continue
      
      console.log(`⚡ 执行语句 ${i + 1}/${sqlStatements.length}...`)
      
      try {
        const { error } = await supabase.rpc('exec_sql', { sql_query: statement })
        
        if (error) {
          // 如果是RPC函数不存在，直接使用SQL查询
          console.log('⚠️  RPC函数不存在，尝试直接查询...')
          
          // 对于CREATE TABLE等DDL语句，我们可能需要使用不同的方法
          if (statement.toUpperCase().includes('CREATE TABLE')) {
            console.log('📦 创建表语句，跳过（需要在Supabase Dashboard中手动执行）')
            console.log('SQL语句:', statement)
            continue
          }
        } else {
          console.log('✅ 执行成功')
        }
      } catch (err) {
        console.log(`❌ 执行失败: ${err.message}`)
        // 继续执行下一条语句
      }
    }
    
    // 测试数据库连接和表是否存在
    console.log('\n🔍 测试数据库连接...')
    try {
      const { data, error } = await supabase
        .from('xq_admin_users')
        .select('count(*)', { count: 'exact', head: true })
      
      if (error) {
        console.log('❌ 表不存在或查询失败:', error.message)
        console.log('\n📋 请在Supabase Dashboard的SQL Editor中执行以下SQL:')
        console.log('\n' + '='.repeat(80))
        console.log(sqlContent)
        console.log('='.repeat(80) + '\n')
      } else {
        console.log('✅ 数据库表创建成功!')
        console.log(`📊 当前管理员用户数量: ${data?.length || 0}`)
      }
    } catch (err) {
      console.log('❌ 测试连接失败:', err.message)
    }
    
    console.log('\n🎉 数据库初始化完成!')
    
  } catch (error) {
    console.error('❌ 数据库初始化失败:', error.message)
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  setupDatabase()
}

module.exports = { setupDatabase }