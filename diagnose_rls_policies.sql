-- 诊断当前RLS策略状态
-- 帮助理解为什么交互功能可能不工作

-- ============================================================================
-- 1. 检查表的RLS状态
-- ============================================================================
SELECT 
    '=== 表的RLS状态 ===' as info;

SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS_Enabled",
    CASE 
        WHEN rowsecurity THEN '✅ 已启用'
        ELSE '❌ 未启用'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments', 'ai_characters', 'users');

-- ============================================================================
-- 2. 查看所有现有策略
-- ============================================================================
SELECT 
    '=== 现有RLS策略 ===' as info;

SELECT 
    tablename,
    policyname,
    cmd,
    permissive,
    CASE 
        WHEN roles = '{public}' THEN 'public'
        WHEN 'authenticated' = ANY(roles) THEN 'authenticated'
        WHEN 'anon' = ANY(roles) THEN 'anon'
        ELSE array_to_string(roles, ', ')
    END as target_roles,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments')
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- 3. 检查可能有问题的策略
-- ============================================================================
SELECT 
    '=== 检查策略问题 ===' as info;

-- 检查是否有过于严格的策略
SELECT 
    tablename,
    policyname,
    cmd,
    qual as using_condition,
    CASE 
        WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%IS NOT NULL%' THEN '⚠️ 可能阻止匿名用户'
        WHEN qual = 'false' THEN '❌ 完全阻止访问'
        WHEN qual = 'true' THEN '✅ 允许所有访问'
        ELSE '🔍 需要检查'
    END as potential_issue
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments')
ORDER BY tablename, cmd;

-- ============================================================================
-- 4. 测试策略（模拟匿名用户访问）
-- ============================================================================
SELECT 
    '=== 策略测试建议 ===' as info;

-- 显示建议的测试查询
SELECT 
    'likes' as table_name,
    'SELECT * FROM likes LIMIT 1;' as test_select_query,
    'INSERT INTO likes (user_id, target_type, target_id) VALUES (auth.uid(), ''character'', ''6ba7b810-9dad-11d1-80b4-00c04fd430c8'');' as test_insert_query
UNION ALL
SELECT 
    'character_follows',
    'SELECT * FROM character_follows LIMIT 1;',
    'INSERT INTO character_follows (user_id, character_id) VALUES (auth.uid(), ''6ba7b810-9dad-11d1-80b4-00c04fd430c8'');'
UNION ALL
SELECT 
    'comments',
    'SELECT * FROM comments LIMIT 1;',
    'INSERT INTO comments (user_id, target_type, target_id, content) VALUES (auth.uid(), ''character'', ''6ba7b810-9dad-11d1-80b4-00c04fd430c8'', ''测试评论'');';

-- ============================================================================
-- 5. 检查相关表的数据
-- ============================================================================
SELECT 
    '=== 数据检查 ===' as info;

-- 检查ai_characters表中是否存在测试角色
SELECT 
    'ai_characters' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN id = '6ba7b810-9dad-11d1-80b4-00c04fd430c8' THEN 1 END) as test_character_exists
FROM ai_characters;

-- 检查用户表
SELECT 
    'users' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN phone = '' OR phone IS NULL THEN 1 END) as anonymous_users
FROM users;

-- 检查交互数据
SELECT 
    'likes' as table_name,
    COUNT(*) as total_records,
    MAX(created_at) as latest_record
FROM likes
UNION ALL
SELECT 
    'character_follows',
    COUNT(*),
    MAX(created_at)
FROM character_follows
UNION ALL
SELECT 
    'comments',
    COUNT(*),
    MAX(created_at)
FROM comments;

-- ============================================================================
-- 6. 权限检查
-- ============================================================================
SELECT 
    '=== 权限检查 ===' as info;

-- 检查表级权限
SELECT 
    schemaname,
    tablename,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name IN ('likes', 'character_follows', 'comments')
AND grantee IN ('anon', 'authenticated', 'public')
ORDER BY table_name, grantee, privilege_type;

-- ============================================================================
-- 7. 修复建议
-- ============================================================================
SELECT 
    '=== 修复建议 ===' as info;

SELECT 
    '如果看到策略阻止匿名用户访问，请执行以下步骤：' as step_1,
    '1. 删除过于严格的策略' as step_1_detail,
    '2. 创建允许匿名用户的测试策略' as step_2,
    '3. 确保目标角色存在于ai_characters表中' as step_3,
    '4. 测试插入、查询、删除操作' as step_4;