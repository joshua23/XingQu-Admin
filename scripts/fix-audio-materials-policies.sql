-- 修复音频素材管理系统的RLS策略
-- 将user_id修改为正确的字段引用

-- 1. 修复分类表策略(管理员可管理) - 使用正确的email关联
DROP POLICY IF EXISTS "Categories are manageable by admins" ON xq_material_categories;
CREATE POLICY "Categories are manageable by admins" ON xq_material_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users 
            WHERE email = auth.email() AND account_status = 'active'
        )
    );

-- 2. 修复素材表策略(管理员可管理) - 使用正确的email关联  
DROP POLICY IF EXISTS "Materials are manageable by admins" ON xq_audio_materials;
CREATE POLICY "Materials are manageable by admins" ON xq_audio_materials
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users 
            WHERE email = auth.email() AND account_status = 'active'
        )
    );

-- 3. 验证策略创建
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('xq_material_categories', 'xq_audio_materials')
ORDER BY tablename, policyname;