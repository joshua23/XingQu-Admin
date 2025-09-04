-- 音频素材管理系统数据库初始化脚本
-- 项目: 星趣后台管理系统
-- 创建时间: 2025-09-04

-- 1. 创建音频素材分类表
CREATE TABLE IF NOT EXISTS xq_material_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name)
);

-- 2. 创建音频素材表
CREATE TABLE IF NOT EXISTS xq_audio_materials (
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
    -- 唯一约束
    UNIQUE(file_path)
);

-- 3. 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. 为分类表添加更新触发器
DROP TRIGGER IF EXISTS update_xq_material_categories_updated_at ON xq_material_categories;
CREATE TRIGGER update_xq_material_categories_updated_at
    BEFORE UPDATE ON xq_material_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. 为素材表添加更新触发器
DROP TRIGGER IF EXISTS update_xq_audio_materials_updated_at ON xq_audio_materials;
CREATE TRIGGER update_xq_audio_materials_updated_at
    BEFORE UPDATE ON xq_audio_materials
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 6. 创建索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_audio_materials_category_id ON xq_audio_materials(category_id);
CREATE INDEX IF NOT EXISTS idx_audio_materials_is_active ON xq_audio_materials(is_active);
CREATE INDEX IF NOT EXISTS idx_audio_materials_created_at ON xq_audio_materials(created_at);
CREATE INDEX IF NOT EXISTS idx_material_categories_is_active ON xq_material_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_material_categories_sort_order ON xq_material_categories(sort_order);

-- 7. 启用行级安全(RLS)
ALTER TABLE xq_material_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_audio_materials ENABLE ROW LEVEL SECURITY;

-- 8. 创建RLS策略 - 分类表策略(所有人可读活跃分类)
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON xq_material_categories;
CREATE POLICY "Categories are viewable by everyone" ON xq_material_categories
    FOR SELECT USING (is_active = true);

-- 9. 分类表策略(管理员可管理)
DROP POLICY IF EXISTS "Categories are manageable by admins" ON xq_material_categories;
CREATE POLICY "Categories are manageable by admins" ON xq_material_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users 
            WHERE user_id = auth.uid() AND account_status = 'active'
        )
    );

-- 10. 素材表策略(活跃素材公开可读)
DROP POLICY IF EXISTS "Materials are viewable by everyone" ON xq_audio_materials;
CREATE POLICY "Materials are viewable by everyone" ON xq_audio_materials
    FOR SELECT USING (is_active = true);

-- 11. 素材表策略(管理员可管理)
DROP POLICY IF EXISTS "Materials are manageable by admins" ON xq_audio_materials;
CREATE POLICY "Materials are manageable by admins" ON xq_audio_materials
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM xq_admin_users 
            WHERE user_id = auth.uid() AND account_status = 'active'
        )
    );

-- 12. 插入示例分类数据
INSERT INTO xq_material_categories (name, description, icon, sort_order) VALUES
('背景音乐', '适合作为背景的音乐素材', '🎵', 1),
('音效', '各种音效素材', '🔊', 2),
('自然音', '自然环境音效', '🌿', 3),
('人声', '人声类素材', '🎙️', 4),
('乐器', '各种乐器演奏', '🎸', 5)
ON CONFLICT (name) DO NOTHING;

-- 13. 验证创建结果
SELECT 
    'xq_material_categories' as table_name,
    COUNT(*) as record_count
FROM xq_material_categories
UNION ALL
SELECT 
    'xq_audio_materials' as table_name,
    COUNT(*) as record_count
FROM xq_audio_materials;