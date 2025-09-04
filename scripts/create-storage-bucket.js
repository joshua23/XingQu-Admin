const { createClient } = require('@supabase/supabase-js')

// 使用Service Role Key获得完整权限
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.HnHxsL2pZxHqJf7qZQKT_wXe7Y0aRoA1VSMHjgUP7JE'

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function createAudioMaterialsBucket() {
  console.log('🎵 开始创建音频素材Storage Bucket...')
  
  try {
    // 1. 检查bucket是否已存在
    console.log('🔍 检查现有buckets...')
    const { data: buckets, error: listError } = await supabase.storage.listBuckets()
    
    if (listError) {
      console.error('❌ 无法列出buckets:', listError)
      return
    }
    
    console.log('📋 现有buckets:', buckets.map(b => b.name))
    
    const bucketExists = buckets.some(bucket => bucket.name === 'audio-materials')
    
    if (bucketExists) {
      console.log('✅ Bucket "audio-materials" 已存在')
    } else {
      // 2. 创建新的bucket
      console.log('📦 创建新的 audio-materials bucket...')
      const { data, error } = await supabase.storage.createBucket('audio-materials', {
        public: false, // 私有bucket，通过RLS控制访问
        allowedMimeTypes: ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac'],
        fileSizeLimit: 50 * 1024 * 1024 // 50MB限制
      })
      
      if (error) {
        console.error('❌ 创建bucket失败:', error)
        return
      } else {
        console.log('✅ Bucket "audio-materials" 创建成功!')
        console.log('📊 Bucket配置:', data)
      }
    }
    
    // 3. 添加Storage RLS策略
    console.log('\n🔒 添加Storage RLS策略...')
    await addStoragePolicies()
    
    // 4. 测试bucket访问
    console.log('\n🧪 测试bucket访问权限...')
    const { data: testData, error: testError } = await supabase.storage
      .from('audio-materials')
      .list('')
    
    if (testError) {
      console.log('⚠️ Bucket访问测试:', testError.message)
    } else {
      console.log('✅ Bucket访问正常，当前文件数:', testData.length)
    }
    
    console.log('\n🎉 音频素材Storage配置完成!')
    
  } catch (error) {
    console.error('❌ Storage配置失败:', error.message)
  }
}

async function addStoragePolicies() {
  const policies = [
    {
      name: 'Public read access for audio materials',
      sql: `
        CREATE POLICY "Public read access for audio materials" 
        ON storage.objects
        FOR SELECT 
        TO public
        USING (bucket_id = 'audio-materials');
      `
    },
    {
      name: 'Authenticated upload access for audio materials',
      sql: `
        CREATE POLICY "Authenticated upload access for audio materials"
        ON storage.objects  
        FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'audio-materials');
      `
    },
    {
      name: 'Authenticated update access for audio materials',
      sql: `
        CREATE POLICY "Authenticated update access for audio materials"
        ON storage.objects
        FOR UPDATE
        TO authenticated
        USING (bucket_id = 'audio-materials')
        WITH CHECK (bucket_id = 'audio-materials');
      `
    },
    {
      name: 'Authenticated delete access for audio materials',
      sql: `
        CREATE POLICY "Authenticated delete access for audio materials"
        ON storage.objects
        FOR DELETE
        TO authenticated
        USING (bucket_id = 'audio-materials');
      `
    }
  ]
  
  for (let i = 0; i < policies.length; i++) {
    const policy = policies[i]
    console.log(`🔒 添加策略 ${i + 1}/${policies.length}: ${policy.name}`)
    
    try {
      // 先删除可能存在的同名策略
      const dropSql = `DROP POLICY IF EXISTS "${policy.name}" ON storage.objects;`
      await supabase.rpc('exec_sql', { sql_query: dropSql })
      
      // 添加新策略
      const { error } = await supabase.rpc('exec_sql', { sql_query: policy.sql.trim() })
      
      if (error) {
        console.log(`⚠️ 策略添加可能需要在Dashboard中手动执行: ${policy.name}`)
        console.log('SQL:', policy.sql.trim())
      } else {
        console.log(`✅ 策略添加成功: ${policy.name}`)
      }
    } catch (err) {
      console.log(`❌ 策略添加异常: ${err.message}`)
    }
  }
}

// 运行脚本
if (require.main === module) {
  createAudioMaterialsBucket()
}

module.exports = { createAudioMaterialsBucket }