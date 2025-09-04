-- 清理之前创建的音频素材表，改用xq_background_music

-- 1. 删除相关的RLS策略
DROP POLICY IF EXISTS "enable_read_access_for_all_users" ON xq_material_categories;
DROP POLICY IF EXISTS "enable_all_access_for_authenticated_users" ON xq_material_categories;
DROP POLICY IF EXISTS "Admin users can manage categories" ON xq_material_categories;
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON xq_material_categories;
DROP POLICY IF EXISTS "Categories are manageable by admins" ON xq_material_categories;

DROP POLICY IF EXISTS "enable_read_access_for_all_users" ON xq_audio_materials;
DROP POLICY IF EXISTS "enable_all_access_for_authenticated_users" ON xq_audio_materials;
DROP POLICY IF EXISTS "Admin users can manage materials" ON xq_audio_materials;
DROP POLICY IF EXISTS "Materials are viewable by everyone" ON xq_audio_materials;
DROP POLICY IF EXISTS "Materials are manageable by admins" ON xq_audio_materials;

-- 2. 删除触发器
DROP TRIGGER IF EXISTS update_xq_material_categories_updated_at ON xq_material_categories;
DROP TRIGGER IF EXISTS update_xq_audio_materials_updated_at ON xq_audio_materials;

-- 3. 删除表（由于有外键，需要先删除子表）
DROP TABLE IF EXISTS xq_audio_materials CASCADE;
DROP TABLE IF EXISTS xq_material_categories CASCADE;

-- 4. 删除相关的函数（如果创建了的话）
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- 5. 检查清理结果
SELECT 'Tables dropped successfully' as status;

-- 6. 确认xq_background_music表存在且有数据
SELECT 
    'xq_background_music table:' as info,
    COUNT(*) as record_count,
    COUNT(CASE WHEN is_deleted = false THEN 1 END) as active_records
FROM xq_background_music;