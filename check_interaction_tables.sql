-- 检查交互相关表结构和RLS策略
-- 用于排查点赞、关注、评论功能的问题

-- 1. 检查表是否存在
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('likes', 'character_follows', 'comments', 'ai_characters', 'users');

-- 2. 检查likes表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'likes'
ORDER BY ordinal_position;

-- 3. 检查character_follows表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'character_follows'
ORDER BY ordinal_position;

-- 4. 检查comments表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'comments'
ORDER BY ordinal_position;

-- 5. 检查约束（唯一键、外键等）
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('likes', 'character_follows', 'comments')
ORDER BY tc.table_name, tc.constraint_type;

-- 6. 检查RLS是否启用
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments', 'ai_characters', 'users');

-- 7. 检查RLS策略
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

-- 8. 检查最近的错误数据（如果有）
-- 检查likes表最近的数据
SELECT * FROM likes 
ORDER BY created_at DESC 
LIMIT 5;

-- 检查character_follows表最近的数据
SELECT * FROM character_follows 
ORDER BY created_at DESC 
LIMIT 5;

-- 检查comments表最近的数据
SELECT * FROM comments 
ORDER BY created_at DESC 
LIMIT 5;

-- 9. 检查ai_characters表是否有测试数据
SELECT id, name, created_at 
FROM ai_characters 
WHERE name LIKE '%寂文泽%' OR name LIKE '%测试%'
LIMIT 10;

-- 10. 检查用户表最近的匿名用户
SELECT id, phone, nickname, created_at 
FROM users 
WHERE phone = '' OR phone IS NULL
ORDER BY created_at DESC 
LIMIT 5;