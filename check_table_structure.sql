-- 检查现有user_analytics表的完整结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_analytics' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 检查表是否存在
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_name = 'user_analytics' 
    AND table_schema = 'public'
) as table_exists;