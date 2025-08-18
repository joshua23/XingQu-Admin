-- 修复交互功能（点赞、关注、评论）的数据库问题
-- 执行日期：2025-08-09

-- ============================================================================
-- 1. 创建缺失的表（如果不存在）
-- ============================================================================

-- 创建likes表（如果不存在）
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, target_type, target_id)
);

-- 创建character_follows表（如果不存在）
CREATE TABLE IF NOT EXISTS public.character_follows (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, character_id)
);

-- 创建comments表（如果不存在）
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. 添加缺失的索引
-- ============================================================================

-- likes表索引
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_target ON public.likes(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON public.likes(created_at DESC);

-- character_follows表索引
CREATE INDEX IF NOT EXISTS idx_character_follows_user_id ON public.character_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_character_id ON public.character_follows(character_id);
CREATE INDEX IF NOT EXISTS idx_character_follows_created_at ON public.character_follows(created_at DESC);

-- comments表索引
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_target ON public.comments(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at DESC);

-- ============================================================================
-- 3. 启用RLS（行级安全）
-- ============================================================================

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.character_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. 创建RLS策略
-- ============================================================================

-- likes表策略
-- 允许所有认证用户查看点赞
CREATE POLICY "Anyone can view likes" ON public.likes
    FOR SELECT USING (true);

-- 允许用户创建自己的点赞
CREATE POLICY "Users can create their own likes" ON public.likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 允许用户删除自己的点赞
CREATE POLICY "Users can delete their own likes" ON public.likes
    FOR DELETE USING (auth.uid() = user_id);

-- character_follows表策略
-- 允许所有认证用户查看关注关系
CREATE POLICY "Anyone can view follows" ON public.character_follows
    FOR SELECT USING (true);

-- 允许用户创建自己的关注
CREATE POLICY "Users can create their own follows" ON public.character_follows
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 允许用户删除自己的关注
CREATE POLICY "Users can delete their own follows" ON public.character_follows
    FOR DELETE USING (auth.uid() = user_id);

-- comments表策略
-- 允许所有认证用户查看评论
CREATE POLICY "Anyone can view comments" ON public.comments
    FOR SELECT USING (true);

-- 允许用户创建自己的评论
CREATE POLICY "Users can create their own comments" ON public.comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 允许用户更新自己的评论
CREATE POLICY "Users can update their own comments" ON public.comments
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 允许用户删除自己的评论
CREATE POLICY "Users can delete their own comments" ON public.comments
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 5. 创建或更新触发器函数
-- ============================================================================

-- 自动更新updated_at字段的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为comments表添加更新触发器
DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at 
    BEFORE UPDATE ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. 插入测试数据（测试角色）
-- ============================================================================

-- 插入测试AI角色（如果不存在）
INSERT INTO public.ai_characters (id, name, description, personality, avatar_url, created_at)
VALUES (
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
    '寂文泽',
    '21岁，有占有欲，霸道，只对你撒娇',
    '霸道总裁型，对外人冷漠，只对特定的人温柔',
    'https://example.com/avatar/jiwenze.jpg',
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description;

-- ============================================================================
-- 7. 验证修复结果
-- ============================================================================

-- 显示表结构
DO $$ 
BEGIN 
    RAISE NOTICE '=== 表结构验证 ===';
    RAISE NOTICE 'likes表: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'likes');
    RAISE NOTICE 'character_follows表: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'character_follows');
    RAISE NOTICE 'comments表: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'comments');
    
    RAISE NOTICE '=== RLS策略验证 ===';
    RAISE NOTICE 'likes表策略数: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'likes');
    RAISE NOTICE 'character_follows表策略数: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'character_follows');
    RAISE NOTICE 'comments表策略数: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'comments');
END $$;

-- ============================================================================
-- 8. 清理可能的问题数据
-- ============================================================================

-- 删除user_id为空的异常数据
DELETE FROM public.likes WHERE user_id IS NULL;
DELETE FROM public.character_follows WHERE user_id IS NULL;
DELETE FROM public.comments WHERE user_id IS NULL;

-- 删除target_id为空的异常数据
DELETE FROM public.likes WHERE target_id IS NULL;
DELETE FROM public.character_follows WHERE character_id IS NULL;
DELETE FROM public.comments WHERE target_id IS NULL;

-- ============================================================================
-- 9. 授予必要的权限
-- ============================================================================

-- 授予anon角色基本权限
GRANT SELECT ON public.likes TO anon;
GRANT INSERT, DELETE ON public.likes TO anon;

GRANT SELECT ON public.character_follows TO anon;
GRANT INSERT, DELETE ON public.character_follows TO anon;

GRANT SELECT ON public.comments TO anon;
GRANT INSERT, UPDATE, DELETE ON public.comments TO anon;

-- 授予authenticated角色完整权限
GRANT ALL ON public.likes TO authenticated;
GRANT ALL ON public.character_follows TO authenticated;
GRANT ALL ON public.comments TO authenticated;

-- ============================================================================
-- 10. 最终验证
-- ============================================================================

-- 显示修复后的统计信息
SELECT 
    'likes' as table_name,
    COUNT(*) as row_count,
    MAX(created_at) as latest_record
FROM public.likes
UNION ALL
SELECT 
    'character_follows',
    COUNT(*),
    MAX(created_at)
FROM public.character_follows
UNION ALL
SELECT 
    'comments',
    COUNT(*),
    MAX(created_at)
FROM public.comments;

-- 显示测试角色信息
SELECT id, name, description
FROM public.ai_characters
WHERE name = '寂文泽';

-- 输出成功消息
DO $$ 
BEGIN 
    RAISE NOTICE '✅ 交互功能数据库修复完成！';
    RAISE NOTICE '✅ 请重新测试点赞、关注、评论功能。';
END $$;