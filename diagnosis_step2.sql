-- ========== 第2步：检查likes表结构（如果存在） ==========
-- 只有在第1步显示likes表存在时才执行此查询

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'likes'
ORDER BY ordinal_position;