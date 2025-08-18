-- 星趣App数据库完整修复脚本
-- 解决点赞、评论、关注功能失败的问题
-- 在Supabase SQL编辑器中执行此脚本

-- ========== 1. 确保扩展存在 ==========
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========== 2. 检查并处理旧的likes表 ==========
-- 如果存在旧的likes表（只支持story），先备份然后删除
DO $$
BEGIN
    -- 检查是否存在旧的likes表（story_id字段）
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'likes' AND column_name = 'story_id') THEN
        -- 备份旧数据（如果需要）
        CREATE TABLE IF NOT EXISTS likes_backup_story AS SELECT * FROM likes;
        -- 删除旧表
        DROP TABLE IF EXISTS likes CASCADE;
        RAISE NOTICE 'Old likes table backed up and dropped';
    END IF;
END $$;

-- ========== 3. 创建通用点赞表 ==========
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,         -- 目标类型: story/character/audio/creation
    target_id UUID NOT NULL,                  -- 目标ID (不使用外键约束，因为目标可能在不同表中)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

-- ========== 4. 创建通用评论表 ==========
-- 检查并处理旧的comments表
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'comments' AND column_name = 'story_id') THEN
        CREATE TABLE IF NOT EXISTS comments_backup_story AS SELECT * FROM comments;
        DROP TABLE IF EXISTS comments CASCADE;
        RAISE NOTICE 'Old comments table backed up and dropped';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,         -- 目标类型
    target_id UUID NOT NULL,                  -- 目标ID
    content TEXT NOT NULL,                    -- 评论内容
    parent_id UUID REFERENCES comments(id),   -- 父评论ID（用于回复）
    is_pinned BOOLEAN DEFAULT FALSE,         -- 是否置顶
    like_count INTEGER DEFAULT 0,           -- 点赞数
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========== 5. 创建角色关注表 ==========
CREATE TABLE IF NOT EXISTS character_follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL,               -- AI角色ID (指向ai_characters表)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, character_id)
);

-- ========== 6. 创建AI角色表（如果不存在） ==========
CREATE TABLE IF NOT EXISTS ai_characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    personality TEXT,
    avatar_url TEXT,
    description TEXT,
    background_story TEXT,
    greeting_message TEXT,
    tags TEXT[],
    category VARCHAR(50),
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    follower_count INTEGER DEFAULT 0,
    interaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========== 7. 创建用户分析表（如果不存在） ==========
CREATE TABLE IF NOT EXISTS user_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    session_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========== 8. 创建性能索引 ==========
-- 点赞表索引
CREATE INDEX IF NOT EXISTS idx_likes_target ON likes(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_created ON likes(created_at DESC);

-- 评论表索引
CREATE INDEX IF NOT EXISTS idx_comments_target ON comments(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created ON comments(created_at DESC);

-- 角色关注表索引
CREATE INDEX IF NOT EXISTS idx_character_follows_user ON character_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_character ON character_follows(character_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_created ON character_follows(created_at DESC);

-- AI角色表索引
CREATE INDEX IF NOT EXISTS idx_ai_characters_public ON ai_characters(is_public, is_active);
CREATE INDEX IF NOT EXISTS idx_ai_characters_creator ON ai_characters(creator_id);

-- 用户分析表索引
CREATE INDEX IF NOT EXISTS idx_user_analytics_user ON user_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_type ON user_analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_user_analytics_created ON user_analytics(created_at DESC);

-- ========== 9. 启用行级安全 (RLS) ==========
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- ========== 10. 创建RLS策略 ==========

-- 点赞表策略
DROP POLICY IF EXISTS "Anyone can view likes" ON likes;
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
DROP POLICY IF EXISTS "Anonymous users can manage likes" ON likes;

CREATE POLICY "Anyone can view likes" ON likes
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own likes" ON likes
    FOR ALL USING (auth.uid() = user_id);

-- 评论表策略
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can manage own comments" ON comments;

CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own comments" ON comments
    FOR ALL USING (auth.uid() = user_id);

-- 角色关注表策略
DROP POLICY IF EXISTS "Anyone can view character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can manage own character follows" ON character_follows;

CREATE POLICY "Anyone can view character follows" ON character_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own character follows" ON character_follows
    FOR ALL USING (auth.uid() = user_id);

-- AI角色表策略
DROP POLICY IF EXISTS "Anyone can view public characters" ON ai_characters;
DROP POLICY IF EXISTS "Creators can manage own characters" ON ai_characters;

CREATE POLICY "Anyone can view public characters" ON ai_characters
    FOR SELECT USING (is_public = true AND is_active = true);

CREATE POLICY "Creators can manage own characters" ON ai_characters
    FOR ALL USING (auth.uid() = creator_id);

-- 用户分析表策略（允许插入，限制查看）
DROP POLICY IF EXISTS "Users can insert own analytics" ON user_analytics;
DROP POLICY IF EXISTS "Users can view own analytics" ON user_analytics;

CREATE POLICY "Users can insert own analytics" ON user_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can view own analytics" ON user_analytics
    FOR SELECT USING (auth.uid() = user_id);

-- ========== 11. 插入测试数据 ==========
-- 插入一个测试AI角色（寂文泽）
INSERT INTO ai_characters (
    id,
    name, 
    personality, 
    description,
    tags,
    category,
    is_public,
    is_active
) VALUES (
    'jiweize_001'::UUID,
    '寂文泽',
    '21岁，有占有欲，霸道，只对你撒娇',
    '21岁，有占有欲，霸道，只对你撒娇',
    ARRAY['恋爱', '男友', '占有欲', '霸道'],
    'romance',
    true,
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    personality = EXCLUDED.personality,
    description = EXCLUDED.description,
    updated_at = NOW();

-- ========== 12. 验证脚本 ==========
-- 验证表是否正确创建
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_name IN ('likes', 'comments', 'character_follows', 'ai_characters', 'user_analytics');
    
    RAISE NOTICE 'Created tables count: %', table_count;
    
    -- 验证likes表结构
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'likes' AND column_name = 'target_type') THEN
        RAISE NOTICE '✅ Likes table has correct structure (target_type, target_id)';
    ELSE
        RAISE NOTICE '❌ Likes table structure is incorrect';
    END IF;
    
    -- 验证RLS是否启用
    IF EXISTS (SELECT 1 FROM pg_tables 
               WHERE tablename = 'likes' AND rowsecurity = true) THEN
        RAISE NOTICE '✅ RLS enabled on likes table';
    ELSE
        RAISE NOTICE '❌ RLS not enabled on likes table';
    END IF;
END $$;

-- 显示创建的策略
SELECT tablename, policyname, cmd, permissive 
FROM pg_policies 
WHERE tablename IN ('likes', 'comments', 'character_follows', 'ai_characters')
ORDER BY tablename, policyname;