-- 修复音频素材管理系统的RLS策略
-- 使用简化的策略，避免auth函数问题

-- 1. 删除所有现有的策略
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON xq_material_categories;
DROP POLICY IF EXISTS "Categories are manageable by admins" ON xq_material_categories;
DROP POLICY IF EXISTS "Materials are viewable by everyone" ON xq_audio_materials;
DROP POLICY IF EXISTS "Materials are manageable by admins" ON xq_audio_materials;

-- 2. 暂时禁用RLS以便管理员可以正常操作
ALTER TABLE xq_material_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE xq_audio_materials DISABLE ROW LEVEL SECURITY;

-- 3. 为后续在Supabase Dashboard中配置RLS做准备，创建一个简单的策略
-- 这些策略将在通过Supabase客户端访问时生效

-- 先启用RLS
ALTER TABLE xq_material_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_audio_materials ENABLE ROW LEVEL SECURITY;

-- 创建允许所有读取的策略（公开访问活跃内容）
CREATE POLICY "enable_read_access_for_all_users" ON xq_material_categories
FOR SELECT USING (is_active = true);

CREATE POLICY "enable_read_access_for_all_users" ON xq_audio_materials  
FOR SELECT USING (is_active = true);

-- 创建允许认证用户管理的策略（通过Supabase auth时生效）
CREATE POLICY "enable_all_access_for_authenticated_users" ON xq_material_categories
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "enable_all_access_for_authenticated_users" ON xq_audio_materials
FOR ALL USING (auth.role() = 'authenticated');

-- 4. 验证策略创建结果
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd 
FROM pg_policies 
WHERE tablename IN ('xq_material_categories', 'xq_audio_materials')
ORDER BY tablename, policyname;

-- 5. 测试数据访问
SELECT 'Testing categories access:' as test_step;
SELECT COUNT(*) as category_count FROM xq_material_categories;

SELECT 'Testing materials access:' as test_step;  
SELECT COUNT(*) as material_count FROM xq_audio_materials;