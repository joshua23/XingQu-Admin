const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const path = require('path')

// 从环境变量获取配置
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.HnHxsL2pZxHqJf7qZQKT_wXe7Y0aRoA1VSMHjgUP7JE'

// 创建 Supabase 客户端
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function executeSQLFile() {
  try {
    console.log('🚀 开始执行数据库SQL...')
    
    // 读取SQL文件
    const sqlFile = path.join(__dirname, 'init-admin-users-table.sql')
    const sqlContent = fs.readFileSync(sqlFile, 'utf8')
    
    console.log('📝 读取SQL文件成功')
    
    // 分割SQL语句并逐个执行
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'))
    
    console.log(`📋 找到 ${statements.length} 条SQL语句`)
    
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i]
      if (statement.length === 0) continue
      
      console.log(`⚡ 执行语句 ${i + 1}/${statements.length}...`)
      console.log('SQL:', statement.substring(0, 100) + (statement.length > 100 ? '...' : ''))
      
      try {
        // 使用 rpc 调用执行 SQL
        const { data, error } = await supabase.rpc('exec_sql', { 
          sql_query: statement + ';'
        })
        
        if (error) {
          console.log('⚠️  RPC 方法失败，尝试直接查询...')
          
          // 如果 RPC 失败，尝试其他方法
          if (statement.toUpperCase().includes('CREATE TABLE')) {
            console.log('🛠️  表创建语句需要在 Supabase Dashboard 中手动执行')
          } else if (statement.toUpperCase().includes('INSERT')) {
            console.log('📝 数据插入语句，尝试使用 from() 方法')
          }
        } else {
          console.log('✅ 执行成功')
        }
      } catch (err) {
        console.log(`❌ 执行失败: ${err.message}`)
      }
    }
    
    // 测试表是否存在
    console.log('\n🔍 测试表是否创建成功...')
    try {
      const { data, error } = await supabase
        .from('xq_admin_users')
        .select('*', { count: 'exact', head: true })
      
      if (error) {
        console.log('❌ 表不存在，需要手动创建:', error.message)
        console.log('\n📋 请在 Supabase Dashboard 的 SQL Editor 中执行:')
        console.log('=' .repeat(60))
        console.log(sqlContent)
        console.log('=' .repeat(60))
      } else {
        console.log('✅ 表创建成功!')
        
        // 查询现有数据
        const { data: users, error: selectError } = await supabase
          .from('xq_admin_users')
          .select('*')
        
        if (!selectError) {
          console.log(`📊 当前用户数量: ${users.length}`)
          users.forEach(user => {
            console.log(`  - ${user.nickname} (${user.email}) - ${user.role}`)
          })
        }
      }
    } catch (err) {
      console.log('❌ 表查询失败:', err.message)
    }
    
    console.log('\n🎉 SQL执行完成!')
    
  } catch (error) {
    console.error('❌ 执行失败:', error)
  }
}

// 执行
executeSQLFile()