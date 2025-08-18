-- ========== 第3步：检查数据库扩展 ==========
-- 检查必要的UUID扩展是否安装

SELECT 
    extname as extension_name,
    '✅ INSTALLED' as status
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pgcrypto')
UNION ALL
SELECT 
    'uuid-ossp' as extension_name,
    '❌ MISSING' as status
WHERE NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp')
UNION ALL
SELECT 
    'pgcrypto' as extension_name,
    '❌ MISSING' as status
WHERE NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto');