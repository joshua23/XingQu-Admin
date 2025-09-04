const { Client } = require('pg')
const fs = require('fs')
const path = require('path')

// 数据库连接配置
const client = new Client({
  host: 'db.wqdpqhfqrxvssxifpmvt.supabase.co',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: '7232527xyznByEp',
  ssl: {
    rejectUnauthorized: false // Supabase requires SSL
  }
})

async function initDatabase() {
  console.log('🚀 开始连接数据库...')
  
  try {
    // 连接到数据库
    await client.connect()
    console.log('✅ 数据库连接成功!')
    
    // 读取SQL文件
    const sqlFile = path.join(__dirname, 'init-admin-users-table.sql')
    const sqlContent = fs.readFileSync(sqlFile, 'utf8')
    
    console.log('📝 读取SQL文件成功')
    
    // 执行完整的SQL脚本
    console.log('⚡ 执行SQL脚本...')
    await client.query(sqlContent)
    
    console.log('✅ SQL脚本执行成功!')
    
    // 验证表是否创建成功并查询数据
    console.log('🔍 验证表创建和查询数据...')
    
    const result = await client.query('SELECT * FROM xq_admin_users ORDER BY created_at DESC')
    
    console.log(`📊 查询成功，共有 ${result.rows.length} 个管理员用户:`)
    result.rows.forEach((user, index) => {
      console.log(`  ${index + 1}. ${user.nickname} (${user.email}) - ${user.role} - ${user.account_status}`)
    })
    
    // 查询表结构信息
    const tableInfo = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'xq_admin_users' 
      ORDER BY ordinal_position
    `)
    
    console.log('\n📋 表结构信息:')
    tableInfo.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? '(NOT NULL)' : ''}`)
    })
    
    // 查询索引信息
    const indexInfo = await client.query(`
      SELECT indexname, indexdef 
      FROM pg_indexes 
      WHERE tablename = 'xq_admin_users'
    `)
    
    console.log('\n🔍 索引信息:')
    indexInfo.rows.forEach(idx => {
      console.log(`  - ${idx.indexname}`)
    })
    
    console.log('\n🎉 数据库初始化完成!')
    console.log('\n📱 现在可以刷新应用页面测试用户管理功能了!')
    
  } catch (error) {
    console.error('❌ 数据库初始化失败:', error.message)
    
    if (error.message.includes('does not exist')) {
      console.log('\n💡 建议: 表可能需要先在Supabase Dashboard中手动创建')
    }
    
    if (error.message.includes('connection')) {
      console.log('\n💡 建议: 检查网络连接或数据库配置')
    }
  } finally {
    // 关闭数据库连接
    await client.end()
    console.log('🔒 数据库连接已关闭')
  }
}

// 执行初始化
initDatabase()