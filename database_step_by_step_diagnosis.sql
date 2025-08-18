-- 分步数据库诊断 - 请逐个执行以下SQL语句，每次只运行一个

-- ========== 第1步：检查关键表是否存在 ==========
-- 请执行此查询并告诉我结果
SELECT 
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
    ('ai_characters'),
    ('character_follows'),
    ('user_analytics')
) as t(table_name)
ORDER BY table_name;