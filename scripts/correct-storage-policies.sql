-- Supabase Storage 正确的RLS策略语法
-- 这些策略要在Supabase Dashboard的Storage > Policies中执行

-- 1. 公开读取策略 (所有人可以下载音频文件)
CREATE POLICY "Public read access for audio materials" 
ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'audio-materials');

-- 2. 认证用户上传策略 (登录的管理员可以上传)
CREATE POLICY "Authenticated upload access for audio materials"
ON storage.objects  
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'audio-materials'
);

-- 3. 认证用户更新策略 (允许覆盖文件)
CREATE POLICY "Authenticated update access for audio materials"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'audio-materials')
WITH CHECK (bucket_id = 'audio-materials');

-- 4. 认证用户删除策略 (管理员可以删除文件)
CREATE POLICY "Authenticated delete access for audio materials"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'audio-materials');

-- 注意：这些策略适用于所有认证用户
-- 如果需要更严格的权限控制（仅限管理员），可以添加额外的检查条件