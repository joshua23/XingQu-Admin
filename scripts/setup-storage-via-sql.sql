-- 通过SQL直接设置Storage相关配置
-- 这些命令将直接在PostgreSQL中执行

-- 1. 检查storage schema是否存在
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'storage';

-- 2. 检查storage.buckets表
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'storage' AND table_name = 'buckets';

-- 3. 查看现有buckets
SELECT id, name, public, created_at FROM storage.buckets;

-- 4. 创建audio-materials bucket (如果不存在)
INSERT INTO storage.buckets (id, name, public, created_at, updated_at)
VALUES ('audio-materials', 'audio-materials', false, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 5. 验证bucket创建
SELECT id, name, public, created_at FROM storage.buckets WHERE name = 'audio-materials';

-- 6. 检查storage.objects表的RLS状态
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'storage' AND tablename = 'objects';

-- 7. 启用storage.objects的RLS (如果未启用)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 8. 检查现有的storage policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
AND policyname LIKE '%audio-materials%';

-- 9. 创建Storage RLS策略

-- 删除可能存在的旧策略
DROP POLICY IF EXISTS "Public read access for audio materials" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload access for audio materials" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update access for audio materials" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete access for audio materials" ON storage.objects;

-- 创建新的策略

-- 公开读取访问
CREATE POLICY "Public read access for audio materials" 
ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'audio-materials');

-- 认证用户上传权限
CREATE POLICY "Authenticated upload access for audio materials"
ON storage.objects  
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'audio-materials');

-- 认证用户更新权限
CREATE POLICY "Authenticated update access for audio materials"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'audio-materials')
WITH CHECK (bucket_id = 'audio-materials');

-- 认证用户删除权限
CREATE POLICY "Authenticated delete access for audio materials"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'audio-materials');

-- 10. 验证策略创建结果
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%audio materials%'
ORDER BY policyname;

-- 11. 最终验证
SELECT 
    'Storage bucket created:' as status,
    COUNT(*) as bucket_count
FROM storage.buckets 
WHERE name = 'audio-materials'

UNION ALL

SELECT 
    'Storage policies created:' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%audio materials%';