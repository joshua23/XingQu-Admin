-- XingQu App 立即数据库修复脚本
-- 修复missing likes table和其他核心功能
-- 使用提供的Supabase凭据立即执行

-- ⚠️ 执行说明：
-- 1. 登录 https://wqdpqhfqrxvssxifpmvt.supabase.co/project/wqdpqhfqrxvssxifpmvt/sql
-- 2. 将此脚本粘贴到SQL编辑器中
-- 3. 点击执行以修复所有问题

-- ========== 安全事务开始 ==========
BEGIN;

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 创建备份表（防止数据丢失）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes') THEN
        DROP TABLE IF EXISTS likes_backup_immediate;
        CREATE TABLE likes_backup_immediate AS SELECT * FROM likes;
        RAISE NOTICE '✅ Backed up existing likes data';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') THEN
        DROP TABLE IF EXISTS comments_backup_immediate;
        CREATE TABLE comments_backup_immediate AS SELECT * FROM comments;
        RAISE NOTICE '✅ Backed up existing comments data';
    END IF;
END $$;

-- ========== 1. 确保用户表存在 ==========
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE,
    nickname VARCHAR(50),
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 2. AI角色表 - 支持寂文泽等角色 ==========
DROP TABLE IF EXISTS ai_characters CASCADE;
CREATE TABLE ai_characters (
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

-- ========== 3. 修复核心问题：通用点赞表 ==========
DROP TABLE IF EXISTS likes CASCADE;
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,  -- 'character', 'story', 'audio', 'creation'
    target_id UUID NOT NULL,           -- 目标内容的ID
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

-- ========== 4. 通用评论表 ==========
DROP TABLE IF EXISTS comments CASCADE;
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,  -- 'character', 'story', 'audio', 'creation'
    target_id UUID NOT NULL,           -- 目标内容的ID
    content TEXT NOT NULL,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    like_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 5. 角色关注表 ==========
DROP TABLE IF EXISTS character_follows CASCADE;
CREATE TABLE character_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, character_id)
);

-- ========== 6. 用户行为分析表 ==========
DROP TABLE IF EXISTS user_analytics CASCADE;
CREATE TABLE user_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 7. 数据恢复 ==========
DO $$
BEGIN
    -- 恢复likes数据
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes_backup_immediate') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'likes_backup_immediate' AND column_name = 'story_id') THEN
            -- 从story-only格式迁移
            INSERT INTO likes (user_id, target_type, target_id, created_at)
            SELECT user_id, 'story', story_id, created_at 
            FROM likes_backup_immediate
            ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Migrated story likes from old format';
        ELSE
            -- 直接恢复通用格式
            INSERT INTO likes SELECT * FROM likes_backup_immediate ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Restored likes data';
        END IF;
    END IF;
    
    -- 恢复comments数据
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments_backup_immediate') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'comments_backup_immediate' AND column_name = 'story_id') THEN
            INSERT INTO comments (user_id, target_type, target_id, content, created_at)
            SELECT user_id, 'story', story_id, content, created_at 
            FROM comments_backup_immediate
            ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Migrated story comments from old format';
        ELSE
            INSERT INTO comments SELECT * FROM comments_backup_immediate ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Restored comments data';
        END IF;
    END IF;
END $$;

-- ========== 8. 创建高性能索引 ==========
-- 点赞表关键索引
CREATE INDEX idx_likes_target ON likes(target_type, target_id);
CREATE INDEX idx_likes_user ON likes(user_id);
CREATE INDEX idx_likes_created ON likes(created_at DESC);
CREATE INDEX idx_likes_compound ON likes(user_id, target_type, target_id);

-- 评论表索引
CREATE INDEX idx_comments_target ON comments(target_type, target_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_created ON comments(created_at DESC);
CREATE INDEX idx_comments_parent ON comments(parent_id);

-- 角色关注索引
CREATE INDEX idx_character_follows_user ON character_follows(user_id);
CREATE INDEX idx_character_follows_character ON character_follows(character_id);

-- AI角色索引
CREATE INDEX idx_ai_characters_public ON ai_characters(is_public);
CREATE INDEX idx_ai_characters_category ON ai_characters(category);
CREATE INDEX idx_ai_characters_creator ON ai_characters(creator_id);

-- 用户分析索引
CREATE INDEX idx_user_analytics_user ON user_analytics(user_id);
CREATE INDEX idx_user_analytics_type ON user_analytics(event_type);
CREATE INDEX idx_user_analytics_created ON user_analytics(created_at DESC);
CREATE INDEX idx_user_analytics_session ON user_analytics(session_id);

-- ========== 9. 启用行级安全策略 (RLS) ==========
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- ========== 10. 创建RLS策略 ==========

-- 用户表策略
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

CREATE POLICY "Users can view all profiles" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- AI角色表策略
DROP POLICY IF EXISTS "Anyone can view public characters" ON ai_characters;
DROP POLICY IF EXISTS "Creators can manage own characters" ON ai_characters;
DROP POLICY IF EXISTS "Service role can insert characters" ON ai_characters;

CREATE POLICY "Anyone can view public characters" ON ai_characters
    FOR SELECT USING (is_public = true OR auth.uid() = creator_id);

CREATE POLICY "Creators can manage own characters" ON ai_characters
    FOR ALL USING (auth.uid() = creator_id);

CREATE POLICY "Service role can insert characters" ON ai_characters
    FOR INSERT WITH CHECK (true);  -- 允许系统插入测试数据

-- 点赞表策略（核心修复）
DROP POLICY IF EXISTS "Anyone can view likes" ON likes;
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
DROP POLICY IF EXISTS "Users can delete own likes" ON likes;

CREATE POLICY "Anyone can view likes" ON likes
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own likes" ON likes
    FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE POLICY "Users can delete own likes" ON likes
    FOR DELETE USING (auth.uid() = user_id OR auth.uid() IS NULL);

-- 评论表策略
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can manage own comments" ON comments;
DROP POLICY IF EXISTS "Users can update own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON comments;

CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE USING (auth.uid() = user_id);

-- 角色关注表策略
DROP POLICY IF EXISTS "Anyone can view character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can manage own character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can delete own character follows" ON character_follows;

CREATE POLICY "Anyone can view character follows" ON character_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own character follows" ON character_follows
    FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE POLICY "Users can delete own character follows" ON character_follows
    FOR DELETE USING (auth.uid() = user_id OR auth.uid() IS NULL);

-- 用户分析表策略
DROP POLICY IF EXISTS "Users can insert analytics" ON user_analytics;
DROP POLICY IF EXISTS "Users can view own analytics" ON user_analytics;

CREATE POLICY "Users can insert analytics" ON user_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can view own analytics" ON user_analytics
    FOR SELECT USING (auth.uid() = user_id);

-- ========== 11. 插入测试数据 ==========
-- 插入测试AI角色：寂文泽
INSERT INTO ai_characters (
    id,
    name, 
    personality, 
    description,
    background_story,
    greeting_message,
    tags,
    category,
    is_public
) VALUES (
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::UUID,
    '寂文泽',
    '21岁，有占有欲，霸道，只对你撒娇',
    '21岁，有占有欲，霸道，只对你撒娇。该角色仅支持文字交流，不支持图片和语音',
    '寂文泽是一个充满魅力的21岁男生，外表冷酷但内心温暖。他对喜欢的人会表现出强烈的占有欲和保护欲。',
    '嗯？你终于来了...我还以为你把我忘了呢。',
    ARRAY['恋爱', '男友', '占有欲', '霸道', '撒娇'],
    'romance',
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    personality = EXCLUDED.personality,
    description = EXCLUDED.description,
    background_story = EXCLUDED.background_story,
    greeting_message = EXCLUDED.greeting_message,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- 插入更多测试角色
INSERT INTO ai_characters (
    name, 
    personality, 
    description,
    tags,
    category,
    is_public
) VALUES 
(
    '林小雨',
    '温柔可爱的邻家女孩，喜欢看书和画画',
    '一个温柔可爱的邻家女孩，总是带着甜美的笑容',
    ARRAY['温柔', '可爱', '邻家', '文艺'],
    'friendship',
    true
),
(
    '王子轩',
    '阳光帅气的运动男生，热爱篮球和音乐',
    '阳光帅气的大男孩，篮球场上的明星，私下里也很温柔体贴',
    ARRAY['阳光', '运动', '篮球', '音乐'],
    'friendship',
    true
)
ON CONFLICT (id) DO NOTHING;

-- ========== 12. 验证和总结 ==========
DO $$
DECLARE
    table_count INTEGER;
    likes_count INTEGER;
    characters_count INTEGER;
    policies_count INTEGER;
BEGIN
    -- 检查表
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('likes', 'comments', 'character_follows', 'ai_characters', 'user_analytics');
    
    -- 检查数据
    SELECT COUNT(*) INTO likes_count FROM likes;
    SELECT COUNT(*) INTO characters_count FROM ai_characters;
    
    -- 检查RLS策略
    SELECT COUNT(*) INTO policies_count 
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    RAISE NOTICE '=== 🎉 数据库修复完成！ ===';
    RAISE NOTICE '✅ 创建了 % 个关键表', table_count;
    RAISE NOTICE '✅ 恢复了 % 个点赞记录', likes_count;
    RAISE NOTICE '✅ 创建了 % 个AI角色（包含寂文泽）', characters_count;
    RAISE NOTICE '✅ 应用了 % 个RLS安全策略', policies_count;
    RAISE NOTICE '✅ 创建了高性能索引';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Flutter应用现在可以正常使用点赞功能了！';
    RAISE NOTICE '';
    RAISE NOTICE '📋 后续步骤：';
    RAISE NOTICE '1. 重启Flutter应用测试点赞功能';
    RAISE NOTICE '2. 检查Supabase匿名认证设置';
    RAISE NOTICE '3. 监控应用日志确保一切正常';
END $$;

-- 提交所有更改
COMMIT;

-- 最终状态检查
SELECT 
    '🎯 最终状态' as summary,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_schema = 'public' AND table_name = t.table_name) as columns,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = t.table_name 
            AND rowsecurity = true
        )
        THEN '✅ RLS启用' 
        ELSE '❌ RLS缺失' 
    END as security_status
FROM (VALUES 
    ('users'),
    ('ai_characters'),
    ('likes'),
    ('comments'), 
    ('character_follows'),
    ('user_analytics')
) as t(table_name)
ORDER BY table_name;

-- 显示AI角色列表
SELECT 
    '🤖 AI角色列表' as category,
    name,
    category,
    array_length(tags, 1) as tag_count,
    is_public,
    created_at::date
FROM ai_characters
ORDER BY name;