-- 修复后的脚本 - 解决category列不存在的问题
-- 复制到 Supabase SQL 编辑器执行

-- 启用扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 检查并修复ai_characters表结构
DO $$
BEGIN
    -- 添加缺失的列（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'category') THEN
        ALTER TABLE ai_characters ADD COLUMN category VARCHAR(50) DEFAULT 'general';
        RAISE NOTICE '✅ Added category column to ai_characters';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'follower_count') THEN
        ALTER TABLE ai_characters ADD COLUMN follower_count INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Added follower_count column to ai_characters';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'interaction_count') THEN
        ALTER TABLE ai_characters ADD COLUMN interaction_count INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Added interaction_count column to ai_characters';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'is_public') THEN
        ALTER TABLE ai_characters ADD COLUMN is_public BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Added is_public column to ai_characters';
    END IF;
END $$;

-- 创建通用点赞表（核心修复）
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,  -- 'character', 'story', 'audio', 'creation'
    target_id UUID NOT NULL,           -- 目标内容的ID
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

-- 创建评论表
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
    content TEXT NOT NULL,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    like_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建角色关注表
CREATE TABLE IF NOT EXISTS character_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, character_id)
);

-- 创建用户分析表
CREATE TABLE IF NOT EXISTS user_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    session_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_likes_target ON likes(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_user ON character_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_character ON character_follows(character_id);

-- 启用RLS
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- 删除可能存在的旧策略
DROP POLICY IF EXISTS "Anyone can view likes" ON likes;
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can manage own comments" ON comments;
DROP POLICY IF EXISTS "Anyone can view character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can manage own character follows" ON character_follows;
DROP POLICY IF EXISTS "Anyone can view public characters" ON ai_characters;
DROP POLICY IF EXISTS "Users can insert analytics" ON user_analytics;

-- 创建RLS策略
CREATE POLICY "Anyone can view likes" ON likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON likes FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view comments" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can manage own comments" ON comments FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view character follows" ON character_follows FOR SELECT USING (true);
CREATE POLICY "Users can manage own character follows" ON character_follows FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view public characters" ON ai_characters FOR SELECT USING (is_public = true);

CREATE POLICY "Users can insert analytics" ON user_analytics FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- 插入或更新寂文泽角色（使用现有列）
INSERT INTO ai_characters (
    id,
    name, 
    description,
    personality,
    avatar_url,
    category,
    is_public
) VALUES (
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::UUID,
    '寂文泽',
    '21岁，有占有欲，霸道，只对你撒娇。该角色仅支持文字交流，不支持图片和语音',
    '21岁，有占有欲，霸道，只对你撒娇',
    'https://example.com/avatar/jiwenze.jpg',
    'romance',
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    personality = EXCLUDED.personality,
    category = EXCLUDED.category,
    is_public = EXCLUDED.is_public,
    updated_at = NOW();

-- 验证结果
DO $$
DECLARE
    likes_exists BOOLEAN;
    character_exists BOOLEAN;
    policies_count INTEGER;
BEGIN
    -- 检查likes表
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'likes'
    ) INTO likes_exists;
    
    -- 检查寂文泽角色
    SELECT EXISTS (
        SELECT 1 FROM ai_characters 
        WHERE name = '寂文泽'
    ) INTO character_exists;
    
    -- 检查RLS策略数量
    SELECT COUNT(*) INTO policies_count 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('likes', 'comments', 'character_follows', 'ai_characters');
    
    RAISE NOTICE '=== 🎉 修复完成！ ===';
    RAISE NOTICE '✅ likes表存在: %', CASE WHEN likes_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '✅ 寂文泽角色存在: %', CASE WHEN character_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '✅ RLS策略数量: %', policies_count;
    RAISE NOTICE '🚀 现在可以测试点赞功能了！';
END $$;

-- 最终检查
SELECT 'Database setup completed successfully! ✅' as status;

-- 显示AI角色
SELECT name, category, is_public, created_at::date as created 
FROM ai_characters 
WHERE name = '寂文泽';