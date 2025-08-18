-- 数据库诊断脚本 - 在执行修复前先运行此脚本了解当前状态
-- 在Supabase SQL编辑器中执行，查看实际的数据库结构

-- ========== 1. 检查所有表是否存在 ==========
SELECT 
    'Table Existence Check' as check_type,
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = t.table_name
        ) 
        THEN '✅ EXISTS' 
        ELSE '❌ MISSING' 
    END as status
FROM (VALUES 
    ('users'),
    ('stories'), 
    ('likes'),
    ('comments'),
    ('follows'),
    ('character_follows'),
    ('ai_characters'),
    ('user_analytics'),
    ('audio_contents'),
    ('creation_items')
) as t(table_name)
ORDER BY table_name;

-- ========== 2. 检查likes表的实际结构 ==========
SELECT 
    'Likes Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'likes'
ORDER BY ordinal_position;

-- ========== 3. 检查comments表的实际结构 ==========
SELECT 
    'Comments Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'comments'
ORDER BY ordinal_position;

-- ========== 4. 检查ai_characters表的实际结构 ==========
SELECT 
    'AI Characters Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'ai_characters'
ORDER BY ordinal_position;

-- ========== 5. 检查RLS策略状态 ==========
SELECT 
    'RLS Status Check' as check_type,
    schemaname,
    tablename,
    CASE WHEN rowsecurity THEN '✅ ENABLED' ELSE '❌ DISABLED' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('likes', 'comments', 'follows', 'character_follows', 'ai_characters', 'user_analytics')
ORDER BY tablename;

-- ========== 6. 检查现有策略 ==========
SELECT 
    'RLS Policies Check' as check_type,
    tablename,
    policyname,
    cmd as policy_type,
    permissive
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ========== 7. 检查外键约束 ==========
SELECT 
    'Foreign Key Check' as check_type,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('likes', 'comments', 'follows', 'character_follows')
ORDER BY tc.table_name, tc.constraint_name;

-- ========== 8. 检查索引状态 ==========
SELECT 
    'Index Check' as check_type,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public' 
  AND tablename IN ('likes', 'comments', 'follows', 'character_follows', 'ai_characters')
ORDER BY tablename, indexname;

-- ========== 9. 统计现有数据 ==========
DO $$
DECLARE
    table_record RECORD;
    table_count INTEGER;
    result_text TEXT := '';
BEGIN
    result_text := 'Data Count Check:' || E'\n';
    
    FOR table_record IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('users', 'stories', 'likes', 'comments', 'ai_characters')
    LOOP
        EXECUTE 'SELECT COUNT(*) FROM ' || table_record.table_name INTO table_count;
        result_text := result_text || table_record.table_name || ': ' || table_count || ' rows' || E'\n';
    END LOOP;
    
    RAISE NOTICE '%', result_text;
END $$;

-- ========== 10. 扩展检查 ==========
SELECT 
    'Extensions Check' as check_type,
    extname as extension_name,
    CASE WHEN extname IS NOT NULL THEN '✅ INSTALLED' ELSE '❌ MISSING' END as status
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pgcrypto')
UNION ALL
SELECT 
    'Extensions Check' as check_type,
    'uuid-ossp' as extension_name,
    CASE WHEN NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') 
         THEN '❌ MISSING' ELSE '✅ INSTALLED' END as status;

-- 诊断完成提示
SELECT '🎯 Diagnosis Complete! Review the results above to understand current database state.' as diagnosis_status;