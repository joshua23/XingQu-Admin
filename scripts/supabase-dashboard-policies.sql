-- Supabase Dashboard 中要执行的RLS策略
-- 这些策略专门为Supabase的认证系统设计

-- 1. 更精确的管理员策略（基于Supabase auth）
DROP POLICY IF EXISTS "enable_all_access_for_authenticated_users" ON xq_material_categories;
CREATE POLICY "Admin users can manage categories" ON xq_material_categories
FOR ALL USING (
  -- 检查当前认证用户是否为管理员
  EXISTS (
    SELECT 1 FROM auth.users au
    JOIN xq_admin_users admin ON admin.email = au.email
    WHERE au.id = auth.uid() 
    AND admin.account_status = 'active'
  )
);

DROP POLICY IF EXISTS "enable_all_access_for_authenticated_users" ON xq_audio_materials;
CREATE POLICY "Admin users can manage materials" ON xq_audio_materials
FOR ALL USING (
  -- 检查当前认证用户是否为管理员
  EXISTS (
    SELECT 1 FROM auth.users au
    JOIN xq_admin_users admin ON admin.email = au.email
    WHERE au.id = auth.uid() 
    AND admin.account_status = 'active'
  )
);

-- 2. Storage策略（在Supabase Dashboard的Storage > Policies中执行）

-- 公开读取策略
-- CREATE POLICY "Public read access for audio materials" ON storage.objects
-- FOR SELECT USING (bucket_id = 'audio-materials');

-- 管理员上传策略  
-- CREATE POLICY "Admin upload access for audio materials" ON storage.objects
-- FOR INSERT WITH CHECK (
--   bucket_id = 'audio-materials' AND
--   EXISTS (
--     SELECT 1 FROM auth.users au
--     JOIN xq_admin_users admin ON admin.email = au.email
--     WHERE au.id = auth.uid() 
--     AND admin.account_status = 'active'
--   )
-- );

-- 管理员删除策略
-- CREATE POLICY "Admin delete access for audio materials" ON storage.objects
-- FOR DELETE USING (
--   bucket_id = 'audio-materials' AND
--   EXISTS (
--     SELECT 1 FROM auth.users au
--     JOIN xq_admin_users admin ON admin.email = au.email
--     WHERE au.id = auth.uid() 
--     AND admin.account_status = 'active'
--   )
-- );