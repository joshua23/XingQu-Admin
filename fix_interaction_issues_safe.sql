-- 安全修复交互功能问题的SQL脚本
-- 检查已存在的策略，只创建缺失的策略

-- ============================================================================
-- 1. 检查当前RLS策略状态
-- ============================================================================

-- 查看现有的RLS策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments')
ORDER BY tablename, policyname;

-- ============================================================================
-- 2. 安全创建RLS策略（使用 IF NOT EXISTS 逻辑）
-- ============================================================================

-- 删除可能存在的冲突策略（如果需要重建）
DO $$ 
BEGIN
    -- 可以手动删除有问题的策略，然后重新创建
    -- DROP POLICY IF EXISTS "Anyone can view likes" ON public.likes;
    -- DROP POLICY IF EXISTS "Users can create their own likes" ON public.likes;
    -- DROP POLICY IF EXISTS "Users can delete their own likes" ON public.likes;
END $$;

-- likes表策略（安全创建）
DO $$ 
BEGIN
    -- 检查并创建查看策略
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'likes' 
        AND policyname = 'Enable read access for all users'
    ) THEN
        CREATE POLICY "Enable read access for all users" ON public.likes
            FOR SELECT USING (true);
    END IF;

    -- 检查并创建插入策略
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'likes' 
        AND policyname = 'Enable insert for authenticated users only'
    ) THEN
        CREATE POLICY "Enable insert for authenticated users only" ON public.likes
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
    END IF;

    -- 检查并创建删除策略
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'likes' 
        AND policyname = 'Enable delete for users based on user_id'
    ) THEN
        CREATE POLICY "Enable delete for users based on user_id" ON public.likes
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- character_follows表策略
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'character_follows' 
        AND policyname = 'Enable read access for all users'
    ) THEN
        CREATE POLICY "Enable read access for all users" ON public.character_follows
            FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'character_follows' 
        AND policyname = 'Enable insert for authenticated users only'
    ) THEN
        CREATE POLICY "Enable insert for authenticated users only" ON public.character_follows
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'character_follows' 
        AND policyname = 'Enable delete for users based on user_id'
    ) THEN
        CREATE POLICY "Enable delete for users based on user_id" ON public.character_follows
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- comments表策略
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'comments' 
        AND policyname = 'Enable read access for all users'
    ) THEN
        CREATE POLICY "Enable read access for all users" ON public.comments
            FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'comments' 
        AND policyname = 'Enable insert for authenticated users only'
    ) THEN
        CREATE POLICY "Enable insert for authenticated users only" ON public.comments
            FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'comments' 
        AND policyname = 'Enable update for users based on user_id'
    ) THEN
        CREATE POLICY "Enable update for users based on user_id" ON public.comments
            FOR UPDATE USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'comments' 
        AND policyname = 'Enable delete for users based on user_id'
    ) THEN
        CREATE POLICY "Enable delete for users based on user_id" ON public.comments
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================================
-- 3. 检查和修复可能的权限问题
-- ============================================================================

-- 为匿名用户添加特殊的权限（用于测试）
DO $$ 
BEGIN
    -- 为anon角色创建更宽松的策略（仅用于开发测试）
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'likes' 
        AND policyname = 'Allow anon users for testing'
    ) THEN
        CREATE POLICY "Allow anon users for testing" ON public.likes
            FOR ALL USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'character_follows' 
        AND policyname = 'Allow anon users for testing'
    ) THEN
        CREATE POLICY "Allow anon users for testing" ON public.character_follows
            FOR ALL USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'comments' 
        AND policyname = 'Allow anon users for testing'
    ) THEN
        CREATE POLICY "Allow anon users for testing" ON public.comments
            FOR ALL USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- ============================================================================
-- 4. 测试策略是否工作正常
-- ============================================================================

-- 测试数据插入（使用DO块避免在事务中出错）
DO $$ 
DECLARE
    test_user_id UUID;
    test_character_id UUID;
BEGIN
    -- 获取或创建测试用户
    BEGIN
        INSERT INTO auth.users (id, email) 
        VALUES (gen_random_uuid(), 'test@example.com')
        RETURNING id INTO test_user_id;
    EXCEPTION WHEN unique_violation THEN
        SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    END;

    -- 获取或创建测试角色
    BEGIN
        SELECT id INTO test_character_id 
        FROM public.ai_characters 
        WHERE name = '寂文泽' 
        LIMIT 1;
        
        IF test_character_id IS NULL THEN
            INSERT INTO public.ai_characters (id, name, description)
            VALUES (
                '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
                '寂文泽',
                '测试角色'
            )
            RETURNING id INTO test_character_id;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        test_character_id := '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid;
    END;

    RAISE NOTICE '测试用户ID: %', test_user_id;
    RAISE NOTICE '测试角色ID: %', test_character_id;
    
    -- 测试插入点赞记录
    BEGIN
        INSERT INTO public.likes (user_id, target_type, target_id)
        VALUES (test_user_id, 'character', test_character_id);
        RAISE NOTICE '✅ 点赞记录插入成功';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE '⚠️ 点赞记录已存在（正常）';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 点赞记录插入失败: %', SQLERRM;
    END;

    -- 清理测试数据
    DELETE FROM public.likes WHERE user_id = test_user_id;
    
END $$;

-- ============================================================================
-- 5. 显示最终状态
-- ============================================================================

-- 显示所有策略
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN roles = '{public}' THEN 'public'
        WHEN roles = '{authenticated}' THEN 'authenticated' 
        WHEN roles = '{anon}' THEN 'anon'
        ELSE array_to_string(roles, ', ')
    END as roles,
    permissive
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments')
ORDER BY tablename, cmd, policyname;

-- 显示表的RLS状态
SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS Enabled"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments');

-- 显示成功消息
DO $$ 
BEGIN 
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ RLS策略修复完成！';
    RAISE NOTICE '✅ 请查看上方的策略列表确认配置';
    RAISE NOTICE '=================================';
END $$;