-- ==================================================
-- 星趣后台管理系统 - 素材管理系统数据表
-- 创建素材存储、分类和分析相关的表结构
-- 创建时间: 2025-09-05
-- ==================================================

-- 1. 创建素材分类表
CREATE TABLE IF NOT EXISTS xq_material_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    material_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建素材表
CREATE TABLE IF NOT EXISTS xq_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    duration INTEGER, -- 音频/视频时长（秒）
    category VARCHAR(100) NOT NULL,
    tags TEXT[] DEFAULT '{}',
    creator_id UUID,
    thumbnail_url TEXT,
    is_active BOOLEAN DEFAULT true,
    usage_count INTEGER DEFAULT 0,
    rating_average DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (creator_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 3. 创建素材使用记录表
CREATE TABLE IF NOT EXISTS xq_material_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_id UUID NOT NULL,
    user_id UUID,
    usage_type VARCHAR(50) DEFAULT 'view', -- view, download, use
    usage_context TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (material_id) REFERENCES xq_materials(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 4. 创建素材评价表
CREATE TABLE IF NOT EXISTS xq_material_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_id UUID NOT NULL,
    user_id UUID NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (material_id) REFERENCES xq_materials(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    UNIQUE(material_id, user_id)
);

-- ==================================================
-- 创建索引以提高查询性能
-- ==================================================

-- 素材表索引
CREATE INDEX IF NOT EXISTS idx_materials_category ON xq_materials(category);
CREATE INDEX IF NOT EXISTS idx_materials_creator ON xq_materials(creator_id);
CREATE INDEX IF NOT EXISTS idx_materials_created ON xq_materials(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_materials_active ON xq_materials(is_active);
CREATE INDEX IF NOT EXISTS idx_materials_file_type ON xq_materials(file_type);
CREATE INDEX IF NOT EXISTS idx_materials_tags ON xq_materials USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_materials_title_search ON xq_materials USING GIN(to_tsvector('simple', title));
CREATE INDEX IF NOT EXISTS idx_materials_description_search ON xq_materials USING GIN(to_tsvector('simple', description));

-- 使用记录索引
CREATE INDEX IF NOT EXISTS idx_usage_material ON xq_material_usage(material_id);
CREATE INDEX IF NOT EXISTS idx_usage_user ON xq_material_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_created ON xq_material_usage(created_at DESC);

-- 评价表索引
CREATE INDEX IF NOT EXISTS idx_ratings_material ON xq_material_ratings(material_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user ON xq_material_ratings(user_id);

-- ==================================================
-- 创建触发器维护数据一致性
-- ==================================================

-- 更新素材的updated_at字段
CREATE OR REPLACE FUNCTION update_materials_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_materials_timestamp
    BEFORE UPDATE ON xq_materials
    FOR EACH ROW
    EXECUTE FUNCTION update_materials_timestamp();

-- 更新分类中的素材数量
CREATE OR REPLACE FUNCTION update_category_count()
RETURNS TRIGGER AS $$
BEGIN
    -- 当插入新素材时
    IF TG_OP = 'INSERT' THEN
        UPDATE xq_material_categories 
        SET material_count = material_count + 1
        WHERE name = NEW.category;
        RETURN NEW;
    END IF;
    
    -- 当删除素材时
    IF TG_OP = 'DELETE' THEN
        UPDATE xq_material_categories 
        SET material_count = material_count - 1
        WHERE name = OLD.category;
        RETURN OLD;
    END IF;
    
    -- 当更新素材分类时
    IF TG_OP = 'UPDATE' AND OLD.category != NEW.category THEN
        UPDATE xq_material_categories 
        SET material_count = material_count - 1
        WHERE name = OLD.category;
        
        UPDATE xq_material_categories 
        SET material_count = material_count + 1
        WHERE name = NEW.category;
        RETURN NEW;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_category_count
    AFTER INSERT OR DELETE OR UPDATE ON xq_materials
    FOR EACH ROW
    EXECUTE FUNCTION update_category_count();

-- 更新素材平均评分
CREATE OR REPLACE FUNCTION update_material_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- 计算新的平均评分
    UPDATE xq_materials
    SET rating_average = (
        SELECT ROUND(AVG(rating)::numeric, 2)
        FROM xq_material_ratings
        WHERE material_id = COALESCE(NEW.material_id, OLD.material_id)
    )
    WHERE id = COALESCE(NEW.material_id, OLD.material_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_material_rating
    AFTER INSERT OR UPDATE OR DELETE ON xq_material_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_material_rating();

-- ==================================================
-- 插入默认分类数据
-- ==================================================

INSERT INTO xq_material_categories (name, description) VALUES
('音频素材', '各类音频文件，包括音效、背景音乐等'),
('视频素材', '视频文件，包括短片、动画、教学视频等'),
('图片素材', '图片文件，包括图标、背景图、插画等'),
('文档模板', '各类文档模板和资源'),
('其他资源', '其他类型的素材资源')
ON CONFLICT (name) DO NOTHING;

-- ==================================================
-- 设置行级安全策略（RLS）
-- ==================================================

ALTER TABLE xq_material_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_material_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE xq_material_ratings ENABLE ROW LEVEL SECURITY;

-- 分类表访问策略（管理员可以操作）
CREATE POLICY "管理员可以查看所有分类" ON xq_material_categories FOR SELECT
TO authenticated USING (true);

CREATE POLICY "管理员可以管理分类" ON xq_material_categories FOR ALL
TO authenticated USING (true);

-- 素材表访问策略
CREATE POLICY "所有用户可以查看活跃素材" ON xq_materials FOR SELECT
TO authenticated USING (is_active = true);

CREATE POLICY "创建者和管理员可以管理素材" ON xq_materials FOR ALL
TO authenticated USING (true);

-- 使用记录策略
CREATE POLICY "用户可以查看自己的使用记录" ON xq_material_usage FOR SELECT
TO authenticated USING (user_id = auth.uid());

CREATE POLICY "用户可以创建使用记录" ON xq_material_usage FOR INSERT
TO authenticated WITH CHECK (user_id = auth.uid());

-- 评价策略
CREATE POLICY "用户可以查看所有评价" ON xq_material_ratings FOR SELECT
TO authenticated USING (true);

CREATE POLICY "用户可以管理自己的评价" ON xq_material_ratings FOR ALL
TO authenticated USING (user_id = auth.uid());

-- ==================================================
-- 创建存储过程用于复杂查询
-- ==================================================

-- 获取热门素材
CREATE OR REPLACE FUNCTION get_popular_materials(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    category VARCHAR,
    usage_count INTEGER,
    rating_average DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.title, m.category, m.usage_count, m.rating_average
    FROM xq_materials m
    WHERE m.is_active = true
    ORDER BY m.usage_count DESC, m.rating_average DESC NULLS LAST
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 获取用户素材统计
CREATE OR REPLACE FUNCTION get_user_material_stats(user_uuid UUID)
RETURNS TABLE (
    total_materials BIGINT,
    active_materials BIGINT,
    total_usage BIGINT,
    avg_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_materials,
        COUNT(*) FILTER (WHERE is_active = true) as active_materials,
        COALESCE(SUM(usage_count), 0) as total_usage,
        ROUND(AVG(rating_average), 2) as avg_rating
    FROM xq_materials
    WHERE creator_id = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- 完成素材管理系统表创建
COMMENT ON TABLE xq_material_categories IS '素材分类表';
COMMENT ON TABLE xq_materials IS '素材主表';
COMMENT ON TABLE xq_material_usage IS '素材使用记录表';
COMMENT ON TABLE xq_material_ratings IS '素材评价表';

-- 授予必要权限
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;