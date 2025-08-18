-- 后台管理系统数据可见性修复脚本
-- 解决点赞、评论、关注数据在后台看不到的问题
-- 请在Supabase SQL编辑器中执行

-- ============================================================================
-- 1. 诊断当前状态
-- ============================================================================

-- 检查表的RLS状态
SELECT 
    '=== 当前RLS状态 ===' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments', 'user_analytics');

-- 检查现有策略
SELECT 
    '=== 现有RLS策略 ===' as info,
    tablename,
    policyname,
    cmd,
    permissive,
    roles
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments', 'user_analytics')
ORDER BY tablename, policyname;

-- ============================================================================
-- 2. 为后台管理系统添加service_role权限
-- ============================================================================

-- 删除可能冲突的旧策略
DO $$ 
BEGIN
    -- 如果存在过于严格的策略，先删除
    DROP POLICY IF EXISTS "Users can view their own likes" ON public.likes;
    DROP POLICY IF EXISTS "Users can view their own follows" ON public.character_follows;
    DROP POLICY IF EXISTS "Users can view their own comments" ON public.comments;
END $$;

-- 为likes表创建完整的策略组合
-- 1. 允许service_role（后台管理系统）完全访问
CREATE POLICY "Enable full access for service role" ON public.likes
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 2. 允许所有用户查看所有点赞数据
CREATE POLICY "Enable read for all users" ON public.likes
    FOR SELECT USING (true);

-- 3. 允许认证用户创建点赞
CREATE POLICY "Enable insert for authenticated users" ON public.likes
    FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- 4. 允许用户删除自己的点赞
CREATE POLICY "Enable delete for own likes" ON public.likes
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 为character_follows表创建策略
CREATE POLICY "Enable full access for service role" ON public.character_follows
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Enable read for all users" ON public.character_follows
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.character_follows
    FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable delete for own follows" ON public.character_follows
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 为comments表创建策略
CREATE POLICY "Enable full access for service role" ON public.comments
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Enable read for all users" ON public.comments
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.comments
    FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Enable update for own comments" ON public.comments
    FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable delete for own comments" ON public.comments
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 为user_analytics表创建策略（确保后台能看到埋点数据）
CREATE POLICY "Enable full access for service role" ON public.user_analytics
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Enable read for authenticated users" ON public.user_analytics
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users" ON public.user_analytics
    FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================================
-- 3. 创建用于后台管理系统的聚合视图
-- ============================================================================

-- 创建交互数据汇总视图
CREATE OR REPLACE VIEW public.interaction_summary AS
SELECT 
    'likes' as interaction_type,
    COUNT(*) as total_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT target_id) as unique_targets,
    DATE(created_at) as date,
    created_at::date as created_date
FROM public.likes
GROUP BY DATE(created_at), created_at::date
UNION ALL
SELECT 
    'follows' as interaction_type,
    COUNT(*) as total_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT character_id) as unique_targets,
    DATE(created_at) as date,
    created_at::date as created_date
FROM public.character_follows
GROUP BY DATE(created_at), created_at::date
UNION ALL
SELECT 
    'comments' as interaction_type,
    COUNT(*) as total_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT target_id) as unique_targets,
    DATE(created_at) as date,
    created_at::date as created_date
FROM public.comments
GROUP BY DATE(created_at), created_at::date
ORDER BY created_date DESC, interaction_type;

-- 为视图添加权限
GRANT SELECT ON public.interaction_summary TO anon, authenticated, service_role;

-- 创建实时交互监控视图
CREATE OR REPLACE VIEW public.realtime_interactions AS
SELECT 
    'like' as action_type,
    l.user_id,
    l.target_type,
    l.target_id,
    u.email as user_email,
    ac.name as character_name,
    l.created_at,
    l.created_at as timestamp
FROM public.likes l
LEFT JOIN public.users u ON l.user_id = u.id
LEFT JOIN public.ai_characters ac ON l.target_id = ac.id
WHERE l.created_at >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'follow' as action_type,
    cf.user_id,
    'character' as target_type,
    cf.character_id as target_id,
    u.email as user_email,
    ac.name as character_name,
    cf.created_at,
    cf.created_at as timestamp
FROM public.character_follows cf
LEFT JOIN public.users u ON cf.user_id = u.id
LEFT JOIN public.ai_characters ac ON cf.character_id = ac.id
WHERE cf.created_at >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'comment' as action_type,
    c.user_id,
    c.target_type,
    c.target_id,
    u.email as user_email,
    COALESCE(ac.name, 'Unknown') as character_name,
    c.created_at,
    c.created_at as timestamp
FROM public.comments c
LEFT JOIN public.users u ON c.user_id = u.id
LEFT JOIN public.ai_characters ac ON c.target_id = ac.id
WHERE c.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

-- 为实时视图添加权限
GRANT SELECT ON public.realtime_interactions TO anon, authenticated, service_role;

-- ============================================================================
-- 4. 启用Realtime功能
-- ============================================================================

-- 为需要实时监控的表启用realtime
ALTER publication supabase_realtime ADD TABLE public.likes;
ALTER publication supabase_realtime ADD TABLE public.character_follows;
ALTER publication supabase_realtime ADD TABLE public.comments;
ALTER publication supabase_realtime ADD TABLE public.user_analytics;

-- ============================================================================
-- 5. 测试数据插入和查询
-- ============================================================================

-- 插入测试数据来验证修复
DO $$ 
DECLARE
    test_user_id UUID;
    test_character_id UUID;
BEGIN
    -- 获取现有用户或创建测试用户
    SELECT id INTO test_user_id FROM public.users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        INSERT INTO auth.users (id, email, raw_user_meta_data, created_at, updated_at, email_confirmed_at)
        VALUES (
            gen_random_uuid(),
            'backend-test@xingqu.app',
            '{"provider":"email","providers":["email"]}',
            NOW(),
            NOW(),
            NOW()
        ) RETURNING id INTO test_user_id;
        
        INSERT INTO public.users (id, email, created_at, updated_at)
        VALUES (test_user_id, 'backend-test@xingqu.app', NOW(), NOW());
    END IF;
    
    -- 确保测试角色存在
    INSERT INTO public.ai_characters (id, name, description, created_at, updated_at)
    VALUES (
        '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
        '寂文泽',
        '后台测试角色',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET 
        updated_at = NOW();
    
    test_character_id := '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid;
    
    -- 插入测试交互数据
    INSERT INTO public.likes (user_id, target_type, target_id, created_at)
    VALUES (test_user_id, 'character', test_character_id, NOW())
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.character_follows (user_id, character_id, created_at)
    VALUES (test_user_id, test_character_id, NOW())
    ON CONFLICT DO NOTHING;
    
    INSERT INTO public.comments (user_id, target_type, target_id, content, created_at)
    VALUES (test_user_id, 'character', test_character_id, '后台测试评论', NOW())
    ON CONFLICT DO NOTHING;
    
    -- 插入测试埋点数据
    INSERT INTO public.user_analytics (user_id, event_type, page_name, event_data, session_id, created_at)
    VALUES (
        test_user_id,
        'social_interaction',
        'home_selection_page',
        '{"actionType": "like", "targetType": "character", "character_name": "寂文泽"}',
        'backend-test-session',
        NOW()
    )
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE '✅ 测试数据插入完成';
    RAISE NOTICE '测试用户ID: %', test_user_id;
    RAISE NOTICE '测试角色ID: %', test_character_id;
END $$;

-- ============================================================================
-- 6. 验证修复结果
-- ============================================================================

-- 查询验证数据是否可见
SELECT '=== 验证结果 ===' as info;

-- 检查交互数据
SELECT 
    'likes' as table_name,
    COUNT(*) as total_records,
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

-- 检查汇总视图
SELECT 
    '=== 汇总数据 ===' as info,
    interaction_type,
    SUM(total_count) as total_interactions,
    COUNT(DISTINCT date) as active_days
FROM public.interaction_summary
GROUP BY interaction_type
ORDER BY total_interactions DESC;

-- 检查最新交互
SELECT 
    '=== 最新交互 ===' as info,
    action_type,
    character_name,
    timestamp
FROM public.realtime_interactions
ORDER BY timestamp DESC
LIMIT 10;

-- 最终状态检查
SELECT 
    '=== 最终策略状态 ===' as info,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments', 'user_analytics')
GROUP BY tablename
ORDER BY tablename;

DO $$ 
BEGIN 
    RAISE NOTICE '==========================================';
    RAISE NOTICE '✅ 后台数据可见性修复完成！';
    RAISE NOTICE '✅ Service Role现在可以访问所有交互数据';
    RAISE NOTICE '✅ 已创建汇总视图供后台管理系统使用';
    RAISE NOTICE '✅ 已启用Realtime功能';
    RAISE NOTICE '==========================================';
END $$;