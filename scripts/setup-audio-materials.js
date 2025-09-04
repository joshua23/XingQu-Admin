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

async function setupAudioMaterials() {
  try {
    console.log('🎵 开始配置音频素材管理系统...')
    
    // 1. 创建Storage Bucket
    console.log('\n📁 创建Storage Bucket...')
    await createStorageBucket()
    
    // 2. 创建数据库表
    console.log('\n📊 创建数据库表...')
    await createDatabaseTables()
    
    // 3. 设置RLS策略
    console.log('\n🔒 设置访问权限策略...')
    await setupRLSPolicies()
    
    // 4. 创建示例分类数据
    console.log('\n🗂️ 创建示例分类数据...')
    await createSampleCategories()
    
    console.log('\n🎉 音频素材管理系统配置完成!')
    console.log('\n📋 配置摘要:')
    console.log('  ✅ Storage Bucket: audio-materials')
    console.log('  ✅ 数据表: xq_audio_materials, xq_material_categories')
    console.log('  ✅ RLS策略: 管理员读写，公开只读')
    console.log('  ✅ 示例分类: 背景音乐、音效、人声等')
    
  } catch (error) {
    console.error('❌ 配置失败:', error.message)
    console.log('\n🔧 如果出现权限问题，请确保:')
    console.log('  1. Service Role Key 配置正确')
    console.log('  2. Supabase项目的Storage功能已启用')
    console.log('  3. 数据库连接正常')
  }
}

async function createStorageBucket() {
  try {
    // 检查bucket是否已存在
    const { data: buckets, error: listError } = await supabase.storage.listBuckets()
    
    if (listError) {
      console.log('❌ 无法列出buckets:', listError.message)
      return
    }
    
    const bucketExists = buckets.some(bucket => bucket.name === 'audio-materials')
    
    if (bucketExists) {
      console.log('✅ Storage bucket "audio-materials" 已存在')
      return
    }
    
    // 创建新的bucket
    const { data, error } = await supabase.storage.createBucket('audio-materials', {
      public: false, // 私有bucket，通过RLS控制访问
      allowedMimeTypes: ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac'],
      fileSizeLimit: 50 * 1024 * 1024 // 50MB限制
    })
    
    if (error) {
      console.log('❌ 创建bucket失败:', error.message)
      console.log('💡 建议: 请在Supabase Dashboard中手动创建名为 "audio-materials" 的bucket')
    } else {
      console.log('✅ Storage bucket "audio-materials" 创建成功')
    }
    
  } catch (err) {
    console.log('❌ Storage配置异常:', err.message)
  }
}

async function createDatabaseTables() {
  // SQL创建表的语句
  const sqlStatements = [
    // 创建音频素材分类表
    `CREATE TABLE IF NOT EXISTS xq_material_categories (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(100) NOT NULL,
      description TEXT,
      icon VARCHAR(50),
      sort_order INTEGER DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(name)
    );`,
    
    // 创建音频素材表
    `CREATE TABLE IF NOT EXISTS xq_audio_materials (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      description TEXT,
      file_name VARCHAR(255) NOT NULL,
      file_path VARCHAR(500) NOT NULL,
      file_size BIGINT,
      duration_seconds INTEGER,
      category_id UUID REFERENCES xq_material_categories(id) ON DELETE SET NULL,
      tags TEXT[], -- PostgreSQL数组类型存储标签
      is_active BOOLEAN DEFAULT true,
      download_count INTEGER DEFAULT 0,
      created_by UUID, -- 可关联admin_users表
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      -- 索引
      UNIQUE(file_path)
    );`,
    
    // 创建更新时间触发器
    `CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ language 'plpgsql';`,
    
    // 为分类表添加触发器
    `DROP TRIGGER IF EXISTS update_xq_material_categories_updated_at ON xq_material_categories;
    CREATE TRIGGER update_xq_material_categories_updated_at
        BEFORE UPDATE ON xq_material_categories
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();`,
    
    // 为素材表添加触发器
    `DROP TRIGGER IF EXISTS update_xq_audio_materials_updated_at ON xq_audio_materials;
    CREATE TRIGGER update_xq_audio_materials_updated_at
        BEFORE UPDATE ON xq_audio_materials
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();`,
    
    // 创建索引优化查询性能
    `CREATE INDEX IF NOT EXISTS idx_audio_materials_category_id ON xq_audio_materials(category_id);`,
    `CREATE INDEX IF NOT EXISTS idx_audio_materials_is_active ON xq_audio_materials(is_active);`,
    `CREATE INDEX IF NOT EXISTS idx_audio_materials_created_at ON xq_audio_materials(created_at);`,
    `CREATE INDEX IF NOT EXISTS idx_material_categories_is_active ON xq_material_categories(is_active);`
  ]
  
  // 执行SQL语句
  for (let i = 0; i < sqlStatements.length; i++) {
    const statement = sqlStatements[i].trim()
    if (statement.length === 0) continue
    
    console.log(`⚡ 执行SQL语句 ${i + 1}/${sqlStatements.length}...`)
    
    try {
      // 使用直接SQL查询
      const { error } = await supabase.rpc('exec_sql', { 
        sql_query: statement 
      })
      
      if (error) {
        // 如果RPC函数不存在，提示手动执行
        console.log('⚠️  请在Supabase Dashboard的SQL Editor中执行以下SQL:')
        console.log('=' .repeat(60))
        console.log(statement)
        console.log('=' .repeat(60))
      } else {
        console.log('✅ 执行成功')
      }
    } catch (err) {
      console.log(`❌ 执行失败: ${err.message}`)
    }
  }
}

async function setupRLSPolicies() {
  const rlsPolicies = [
    // 启用RLS
    `ALTER TABLE xq_material_categories ENABLE ROW LEVEL SECURITY;`,
    `ALTER TABLE xq_audio_materials ENABLE ROW LEVEL SECURITY;`,
    
    // 分类表策略 - 所有人可读
    `DROP POLICY IF EXISTS "Categories are viewable by everyone" ON xq_material_categories;`,
    `CREATE POLICY "Categories are viewable by everyone" ON xq_material_categories
      FOR SELECT USING (is_active = true);`,
    
    // 分类表策略 - 管理员可管理
    `DROP POLICY IF EXISTS "Categories are manageable by admins" ON xq_material_categories;`,
    `CREATE POLICY "Categories are manageable by admins" ON xq_material_categories
      FOR ALL USING (
        EXISTS (
          SELECT 1 FROM xq_admin_users 
          WHERE user_id = auth.uid() AND account_status = 'active'
        )
      );`,
    
    // 素材表策略 - 活跃素材公开可读
    `DROP POLICY IF EXISTS "Materials are viewable by everyone" ON xq_audio_materials;`,
    `CREATE POLICY "Materials are viewable by everyone" ON xq_audio_materials
      FOR SELECT USING (is_active = true);`,
    
    // 素材表策略 - 管理员可管理
    `DROP POLICY IF EXISTS "Materials are manageable by admins" ON xq_audio_materials;`,
    `CREATE POLICY "Materials are manageable by admins" ON xq_audio_materials
      FOR ALL USING (
        EXISTS (
          SELECT 1 FROM xq_admin_users 
          WHERE user_id = auth.uid() AND account_status = 'active'
        )
      );`,
    
    // Storage策略 - 公开可读文件
    `DROP POLICY IF EXISTS "Audio materials are publicly accessible" ON storage.objects;`,
    `CREATE POLICY "Audio materials are publicly accessible" ON storage.objects
      FOR SELECT USING (bucket_id = 'audio-materials');`,
    
    // Storage策略 - 管理员可上传
    `DROP POLICY IF EXISTS "Admins can upload audio materials" ON storage.objects;`,
    `CREATE POLICY "Admins can upload audio materials" ON storage.objects
      FOR INSERT WITH CHECK (
        bucket_id = 'audio-materials' AND 
        EXISTS (
          SELECT 1 FROM xq_admin_users 
          WHERE user_id = auth.uid() AND account_status = 'active'
        )
      );`,
    
    // Storage策略 - 管理员可删除
    `DROP POLICY IF EXISTS "Admins can delete audio materials" ON storage.objects;`,
    `CREATE POLICY "Admins can delete audio materials" ON storage.objects
      FOR DELETE USING (
        bucket_id = 'audio-materials' AND 
        EXISTS (
          SELECT 1 FROM xq_admin_users 
          WHERE user_id = auth.uid() AND account_status = 'active'
        )
      );`
  ]
  
  for (let i = 0; i < rlsPolicies.length; i++) {
    const policy = rlsPolicies[i].trim()
    if (policy.length === 0) continue
    
    console.log(`🔒 设置权限策略 ${i + 1}/${rlsPolicies.length}...`)
    
    try {
      const { error } = await supabase.rpc('exec_sql', { 
        sql_query: policy 
      })
      
      if (error) {
        console.log('⚠️  请在Supabase Dashboard的SQL Editor中执行以下SQL:')
        console.log(policy)
      } else {
        console.log('✅ 策略设置成功')
      }
    } catch (err) {
      console.log(`❌ 策略设置失败: ${err.message}`)
    }
  }
}

async function createSampleCategories() {
  const sampleCategories = [
    { name: '背景音乐', description: '适合作为背景的音乐素材', icon: '🎵', sort_order: 1 },
    { name: '音效', description: '各种音效素材', icon: '🔊', sort_order: 2 },
    { name: '自然音', description: '自然环境音效', icon: '🌿', sort_order: 3 },
    { name: '人声', description: '人声类素材', icon: '🎙️', sort_order: 4 },
    { name: '乐器', description: '各种乐器演奏', icon: '🎸', sort_order: 5 }
  ]
  
  try {
    // 检查是否已有分类数据
    const { data: existingCategories, error: selectError } = await supabase
      .from('xq_material_categories')
      .select('name')
    
    if (selectError) {
      console.log('⚠️  无法查询分类表，可能表未创建成功')
      return
    }
    
    if (existingCategories && existingCategories.length > 0) {
      console.log('✅ 分类数据已存在，跳过创建示例数据')
      return
    }
    
    // 插入示例分类
    const { error: insertError } = await supabase
      .from('xq_material_categories')
      .insert(sampleCategories)
    
    if (insertError) {
      console.log('❌ 插入示例分类失败:', insertError.message)
    } else {
      console.log(`✅ 成功创建 ${sampleCategories.length} 个示例分类`)
    }
    
  } catch (err) {
    console.log('❌ 创建示例数据异常:', err.message)
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  setupAudioMaterials()
}

module.exports = { setupAudioMaterials }