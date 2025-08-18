-- 复制这个完整脚本到Supabase SQL编辑器执行
-- https://supabase.com/dashboard/project/wqdpqhfqrxvssxifpmvt/sql

-- 启用扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 创建AI角色表
CREATE TABLE IF NOT EXISTS ai_characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    personality TEXT,
    avatar_url TEXT,
    description TEXT,
    background_story TEXT,
    greeting_message TEXT,
    tags TEXT[],
    category VARCHAR(50) DEFAULT 'general',
    is_public BOOLEAN DEFAULT true,
    follower_count INTEGER DEFAULT 0,
    interaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

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

-- RLS策略
CREATE POLICY "Anyone can view likes" ON likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON likes FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view comments" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can manage own comments" ON comments FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view character follows" ON character_follows FOR SELECT USING (true);
CREATE POLICY "Users can manage own character follows" ON character_follows FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view public characters" ON ai_characters FOR SELECT USING (is_public = true);

CREATE POLICY "Users can insert analytics" ON user_analytics FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- 插入寂文泽角色
INSERT INTO ai_characters (
    id,
    name, 
    personality, 
    description,
    tags,
    category,
    is_public
) VALUES (
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::UUID,
    '寂文泽',
    '21岁，有占有欲，霸道，只对你撒娇',
    '21岁，有占有欲，霸道，只对你撒娇。该角色仅支持文字交流，不支持图片和语音',
    ARRAY['恋爱', '男友', '占有欲', '霸道'],
    'romance',
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

-- 验证结果
SELECT 'Database setup completed! Like functionality should now work.' as result;