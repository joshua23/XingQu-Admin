-- =====================================================
-- 星趣App 最终修复脚本 - 解决所有列缺失问题
-- =====================================================

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========== 第1步：完整修复AI角色表结构 ==========
DO $$
BEGIN
    -- 添加所有可能缺失的列
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'category') THEN
        ALTER TABLE ai_characters ADD COLUMN category VARCHAR(50) DEFAULT 'general';
        RAISE NOTICE '✅ 添加了 category 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'follower_count') THEN
        ALTER TABLE ai_characters ADD COLUMN follower_count INTEGER DEFAULT 0;
        RAISE NOTICE '✅ 添加了 follower_count 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'interaction_count') THEN
        ALTER TABLE ai_characters ADD COLUMN interaction_count INTEGER DEFAULT 0;
        RAISE NOTICE '✅ 添加了 interaction_count 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'is_public') THEN
        ALTER TABLE ai_characters ADD COLUMN is_public BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ 添加了 is_public 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'tags') THEN
        ALTER TABLE ai_characters ADD COLUMN tags TEXT[];
        RAISE NOTICE '✅ 添加了 tags 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'updated_at') THEN
        ALTER TABLE ai_characters ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE '✅ 添加了 updated_at 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'personality') THEN
        ALTER TABLE ai_characters ADD COLUMN personality TEXT;
        RAISE NOTICE '✅ 添加了 personality 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'background_story') THEN
        ALTER TABLE ai_characters ADD COLUMN background_story TEXT;
        RAISE NOTICE '✅ 添加了 background_story 列';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'greeting_message') THEN
        ALTER TABLE ai_characters ADD COLUMN greeting_message TEXT;
        RAISE NOTICE '✅ 添加了 greeting_message 列';
    END IF;
END $$;

-- ========== 第2步：创建通用点赞表（核心修复）==========
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,  -- 'character', 'story', 'audio', 'creation'
    target_id UUID NOT NULL,           -- 目标内容的ID
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

-- ========== 第3步：创建评论表 ==========
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

-- ========== 第4步：创建角色关注表 ==========
CREATE TABLE IF NOT EXISTS character_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, character_id)
);

-- ========== 第5步：创建用户分析表 ==========
CREATE TABLE IF NOT EXISTS user_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 第6步：创建性能索引 ==========
-- 点赞表索引
CREATE INDEX IF NOT EXISTS idx_likes_target ON likes(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_created ON likes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_likes_compound ON likes(user_id, target_type, target_id);

-- 评论表索引
CREATE INDEX IF NOT EXISTS idx_comments_target ON comments(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created ON comments(created_at DESC);

-- 角色关注表索引
CREATE INDEX IF NOT EXISTS idx_character_follows_user ON character_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_character ON character_follows(character_id);

-- AI角色表索引
CREATE INDEX IF NOT EXISTS idx_ai_characters_public ON ai_characters(is_public);
CREATE INDEX IF NOT EXISTS idx_ai_characters_category ON ai_characters(category);

-- 用户分析表索引
CREATE INDEX IF NOT EXISTS idx_user_analytics_user ON user_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_type ON user_analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_user_analytics_created ON user_analytics(created_at DESC);

-- ========== 第7步：启用行级安全策略 (RLS) ==========
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE character_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- ========== 第8步：清理旧策略 ==========
DROP POLICY IF EXISTS "Anyone can view likes" ON likes;
DROP POLICY IF EXISTS "Users can manage own likes" ON likes;
DROP POLICY IF EXISTS "Users can insert own likes" ON likes;
DROP POLICY IF EXISTS "Users can delete own likes" ON likes;

DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can manage own comments" ON comments;
DROP POLICY IF EXISTS "Users can insert own comments" ON comments;
DROP POLICY IF EXISTS "Users can update own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON comments;

DROP POLICY IF EXISTS "Anyone can view character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can manage own character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can insert own character follows" ON character_follows;
DROP POLICY IF EXISTS "Users can delete own character follows" ON character_follows;

DROP POLICY IF EXISTS "Anyone can view public characters" ON ai_characters;
DROP POLICY IF EXISTS "Creators can manage own characters" ON ai_characters;

DROP POLICY IF EXISTS "Users can insert analytics" ON user_analytics;
DROP POLICY IF EXISTS "Users can view own analytics" ON user_analytics;

-- ========== 第9步：创建新的RLS策略 ==========

-- 点赞表策略（支持匿名用户）
CREATE POLICY "Anyone can view likes" ON likes
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own likes" ON likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes" ON likes
    FOR DELETE USING (auth.uid() = user_id);

-- 评论表策略
CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE USING (auth.uid() = user_id);

-- 角色关注表策略
CREATE POLICY "Anyone can view character follows" ON character_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own character follows" ON character_follows
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own character follows" ON character_follows
    FOR DELETE USING (auth.uid() = user_id);

-- AI角色表策略
CREATE POLICY "Anyone can view public characters" ON ai_characters
    FOR SELECT USING (is_public = true);

CREATE POLICY "Creators can manage own characters" ON ai_characters
    FOR ALL USING (auth.uid() = creator_id);

-- 用户分析表策略
CREATE POLICY "Users can insert analytics" ON user_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can view own analytics" ON user_analytics
    FOR SELECT USING (auth.uid() = user_id);

-- ========== 第10步：插入测试数据（安全版本）==========

-- 先检查并创建寂文泽角色
DO $$
BEGIN
    -- 检查寂文泽是否已存在
    IF NOT EXISTS (SELECT 1 FROM ai_characters WHERE name = '寂文泽') THEN
        INSERT INTO ai_characters (
            id,
            name, 
            description,
            personality,
            avatar_url,
            category,
            is_public,
            tags,
            background_story,
            greeting_message
        ) VALUES (
            '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::UUID,
            '寂文泽',
            '21岁，有占有欲，霸道，只对你撒娇。该角色仅支持文字交流，不支持图片和语音',
            '21岁，有占有欲，霸道，只对你撒娇',
            'https://example.com/avatar/jiwenze.jpg',
            'romance',
            true,
            ARRAY['恋爱', '男友', '占有欲', '霸道'],
            '寂文泽是一个充满魅力的21岁男生，外表冷酷但内心温暖。他对喜欢的人会表现出强烈的占有欲和保护欲。',
            '嗯？你终于来了...我还以为你把我忘了呢。'
        );
        RAISE NOTICE '✅ 创建了寂文泽角色';
    ELSE
        -- 如果存在，更新信息
        UPDATE ai_characters SET
            description = '21岁，有占有欲，霸道，只对你撒娇。该角色仅支持文字交流，不支持图片和语音',
            personality = '21岁，有占有欲，霸道，只对你撒娇',
            category = 'romance',
            is_public = true,
            tags = ARRAY['恋爱', '男友', '占有欲', '霸道'],
            background_story = '寂文泽是一个充满魅力的21岁男生，外表冷酷但内心温暖。他对喜欢的人会表现出强烈的占有欲和保护欲。',
            greeting_message = '嗯？你终于来了...我还以为你把我忘了呢。',
            updated_at = NOW()
        WHERE name = '寂文泽';
        RAISE NOTICE '✅ 更新了寂文泽角色信息';
    END IF;
END $$;

-- ========== 第11步：验证修复结果 ==========
DO $$
DECLARE
    likes_exists BOOLEAN;
    comments_exists BOOLEAN;
    follows_exists BOOLEAN;
    analytics_exists BOOLEAN;
    character_count INTEGER;
    policies_count INTEGER;
    jiwenze_exists BOOLEAN;
BEGIN
    -- 检查关键表
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes') INTO likes_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') INTO comments_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'character_follows') INTO follows_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_analytics') INTO analytics_exists;
    
    -- 检查AI角色
    SELECT COUNT(*) INTO character_count FROM ai_characters;
    SELECT EXISTS (SELECT 1 FROM ai_characters WHERE name = '寂文泽') INTO jiwenze_exists;
    
    -- 检查RLS策略数量
    SELECT COUNT(*) INTO policies_count 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('likes', 'comments', 'character_follows', 'ai_characters', 'user_analytics');
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '🎉 数据库修复完成！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ likes表: %', CASE WHEN likes_exists THEN '已创建' ELSE '失败' END;
    RAISE NOTICE '✅ comments表: %', CASE WHEN comments_exists THEN '已创建' ELSE '失败' END;
    RAISE NOTICE '✅ character_follows表: %', CASE WHEN follows_exists THEN '已创建' ELSE '失败' END;
    RAISE NOTICE '✅ user_analytics表: %', CASE WHEN analytics_exists THEN '已创建' ELSE '失败' END;
    RAISE NOTICE '✅ 寂文泽角色: %', CASE WHEN jiwenze_exists THEN '已存在' ELSE '未找到' END;
    RAISE NOTICE '✅ AI角色总数: %', character_count;
    RAISE NOTICE '✅ RLS策略数量: %', policies_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE '🚀 Flutter应用现在可以使用点赞功能了！';
    RAISE NOTICE '📱 请重启Flutter应用测试功能';
    RAISE NOTICE '❤️ 点击寂文泽的点赞按钮试试看';
    RAISE NOTICE '========================================';
END $$;

-- ========== 最终检查 ==========
SELECT 
    '数据库修复完成! ✅' as status,
    'likes表已创建，支持character点赞' as like_system,
    '寂文泽角色已准备好测试' as test_character,
    '请重启Flutter应用测试功能' as next_step;

-- 显示AI角色
SELECT 
    name as 角色名称,
    category as 分类,
    CASE WHEN is_public THEN '公开' ELSE '私有' END as 可见性,
    created_at::date as 创建日期
FROM ai_characters
ORDER BY name;