-- XingQu App 数据库紧急修复脚本 - Phase 1
-- 基于深度架构分析的安全修复方案
-- ⚠️  执行前请先运行 database_diagnosis.sql 了解当前状态

-- ========== 安全检查与准备 ==========
-- 确保在事务中执行，出错时可以回滚
BEGIN;

-- 检查关键扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 创建备份表（如果原表存在数据）
DO $$
BEGIN
    -- 备份现有likes数据
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes') THEN
        DROP TABLE IF EXISTS likes_backup_emergency;
        CREATE TABLE likes_backup_emergency AS SELECT * FROM likes;
        RAISE NOTICE '✅ Backed up existing likes data to likes_backup_emergency';
    END IF;
    
    -- 备份现有comments数据  
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') THEN
        DROP TABLE IF EXISTS comments_backup_emergency;
        CREATE TABLE comments_backup_emergency AS SELECT * FROM comments;
        RAISE NOTICE '✅ Backed up existing comments data to comments_backup_emergency';
    END IF;
END $$;

-- ========== 1. 用户表确保存在 ==========
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE,
    nickname VARCHAR(50),
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 2. AI角色表 - 核心功能需求 ==========
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
    -- 注意：根据错误信息，暂不包含 is_active 字段，后续根据实际需求添加
    follower_count INTEGER DEFAULT 0,
    interaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 3. 通用点赞表 - 修复核心问题 ==========
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
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
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

-- ========== 6. 用户关注表（通用） ==========
CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK(follower_id != following_id)
);

-- ========== 7. 用户行为分析表 ==========
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

-- ========== 8. 数据迁移 - 恢复备份的数据 ==========
DO $$
BEGIN
    -- 迁移旧的likes数据（如果存在story_id字段）
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes_backup_emergency') THEN
        -- 检查备份表结构
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'likes_backup_emergency' AND column_name = 'story_id') THEN
            -- 从story-only格式迁移到通用格式
            INSERT INTO likes (user_id, target_type, target_id, created_at)
            SELECT user_id, 'story', story_id, created_at 
            FROM likes_backup_emergency
            ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Migrated % story likes from backup', (SELECT COUNT(*) FROM likes_backup_emergency);
        ELSE
            -- 如果已经是通用格式，直接恢复
            INSERT INTO likes SELECT * FROM likes_backup_emergency ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Restored % likes from backup', (SELECT COUNT(*) FROM likes_backup_emergency);
        END IF;
    END IF;
    
    -- 迁移旧的comments数据
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments_backup_emergency') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'comments_backup_emergency' AND column_name = 'story_id') THEN
            -- 从story-only格式迁移
            INSERT INTO comments (user_id, target_type, target_id, content, created_at)
            SELECT user_id, 'story', story_id, content, created_at 
            FROM comments_backup_emergency
            ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Migrated % story comments from backup', (SELECT COUNT(*) FROM comments_backup_emergency);
        ELSE
            -- 直接恢复通用格式
            INSERT INTO comments SELECT * FROM comments_backup_emergency ON CONFLICT DO NOTHING;
            RAISE NOTICE '✅ Restored % comments from backup', (SELECT COUNT(*) FROM comments_backup_emergency);
        END IF;
    END IF;
END $$;

-- ========== 9. 创建关键索引 ==========
-- 点赞表索引（性能关键）
CREATE INDEX idx_likes_target ON likes(target_type, target_id);
CREATE INDEX idx_likes_user ON likes(user_id);
CREATE INDEX idx_likes_created ON likes(created_at DESC);

-- 评论表索引
CREATE INDEX idx_comments_target ON comments(target_type, target_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_created ON comments(created_at DESC);

-- 角色关注索引
CREATE INDEX idx_character_follows_user ON character_follows(user_id);
CREATE INDEX idx_character_follows_character ON character_follows(character_id);

-- 用户分析索引
CREATE INDEX idx_user_analytics_user ON user_analytics(user_id);
CREATE INDEX idx_user_analytics_type ON user_analytics(event_type);
CREATE INDEX idx_user_analytics_created ON user_analytics(created_at DESC);
CREATE INDEX idx_user_analytics_session ON user_analytics(session_id);

-- ========== 10. 启用行级安全策略 (RLS) ==========
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- ========== 11. 创建RLS策略 ==========

-- 用户表策略
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

CREATE POLICY "Users can view all profiles" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- AI角色表策略
DROP POLICY IF EXISTS "Anyone can view public characters" ON ai_characters;
DROP POLICY IF EXISTS "Creators can manage own characters" ON ai_characters;

CREATE POLICY "Anyone can view public characters" ON ai_characters
    FOR SELECT USING (is_public = true);

CREATE POLICY "Creators can manage own characters" ON ai_characters
    FOR ALL USING (auth.uid() = creator_id);

-- 点赞表策略（核心修复）
DROP POLICY IF EXISTS "Anyone can view likes" ON likes;
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;

CREATE POLICY "Anyone can view likes" ON likes
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own likes" ON likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes" ON likes
    FOR DELETE USING (auth.uid() = user_id);

-- 评论表策略
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can manage own comments" ON comments;

CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE USING (auth.uid() = user_id);

-- 角色关注表策略
DROP POLICY IF EXISTS "Anyone can view character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can manage own character follows" ON character_follows;

CREATE POLICY "Anyone can view character follows" ON character_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own character follows" ON character_follows
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own character follows" ON character_follows
    FOR DELETE USING (auth.uid() = user_id);

-- 用户分析表策略
DROP POLICY IF EXISTS "Users can insert analytics" ON user_analytics;
DROP POLICY IF EXISTS "Users can view own analytics" ON user_analytics;

CREATE POLICY "Users can insert analytics" ON user_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can view own analytics" ON user_analytics
    FOR SELECT USING (auth.uid() = user_id);

-- ========== 12. 插入测试数据 ==========
-- 插入测试AI角色：寂文泽
INSERT INTO ai_characters (
    id,
    name, 
    personality, 
    description,
    tags,
    category,
    is_public
) VALUES (
    'jiweize_001'::UUID,
    '寂文泽',
    '21岁，有占有欲，霸道，只对你撒娇',
    '21岁，有占有欲，霸道，只对你撒娇。该角色仅支持文字交流，不支持图片和语音',
    ARRAY['恋爱', '男友', '占有欲', '霸道'],
    'romance',
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    personality = EXCLUDED.personality,
    description = EXCLUDED.description,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ========== 13. 验证修复结果 ==========
DO $$
DECLARE
    table_count INTEGER;
    likes_count INTEGER;
    characters_count INTEGER;
BEGIN
    -- 检查关键表
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('likes', 'comments', 'character_follows', 'ai_characters', 'user_analytics');
    
    SELECT COUNT(*) INTO likes_count FROM likes;
    SELECT COUNT(*) INTO characters_count FROM ai_characters;
    
    RAISE NOTICE '=== PHASE 1 EMERGENCY FIX COMPLETED ===';
    RAISE NOTICE '✅ Created tables: %', table_count;
    RAISE NOTICE '✅ Restored likes: %', likes_count;
    RAISE NOTICE '✅ AI characters: %', characters_count;
    RAISE NOTICE '✅ RLS policies: Applied';
    RAISE NOTICE '✅ Performance indexes: Created';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 NEXT STEPS:';
    RAISE NOTICE '1. Test like functionality in Flutter app';
    RAISE NOTICE '2. Enable anonymous authentication in Supabase dashboard';
    RAISE NOTICE '3. Monitor for any remaining issues';
    RAISE NOTICE '4. Plan Phase 2 enhancements if needed';
END $$;

-- 提交事务
COMMIT;

-- 最终检查 - 显示新表结构
SELECT 
    '🎉 Phase 1 Fix Summary' as status,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_schema = 'public' AND table_name = t.table_name) as column_count,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables 
                     WHERE schemaname = 'public' 
                     AND tablename = t.table_name 
                     AND rowsecurity = true)
         THEN '✅ RLS Enabled' 
         ELSE '❌ RLS Missing' 
    END as rls_status
FROM (VALUES 
    ('likes'),
    ('comments'), 
    ('character_follows'),
    ('ai_characters'),
    ('user_analytics')
) as t(table_name)
ORDER BY table_name;