-- 检查首页-精选页埋点数据的SQL脚本
-- 请在Supabase SQL编辑器中执行

-- 1. 检查用户数据表状态
SELECT 
    '用户数据表状态' as check_item,
    COUNT(*) as total_count,
    COUNT(CASE WHEN phone IS NULL THEN 1 END) as null_phone_count,
    COUNT(CASE WHEN phone = '' THEN 1 END) as empty_phone_count
FROM users;

-- 2. 检查最近的埋点数据（最近10条）
SELECT 
    '最近埋点数据' as check_item,
    event_type,
    page_name,
    user_id,
    session_id,
    created_at,
    event_data
FROM user_analytics 
ORDER BY created_at DESC 
LIMIT 10;

-- 3. 按事件类型统计埋点数据
SELECT 
    '埋点事件统计' as check_item,
    event_type,
    COUNT(*) as event_count
FROM user_analytics 
GROUP BY event_type 
ORDER BY event_count DESC;

-- 4. 检查页面访问统计
SELECT 
    '页面访问统计' as check_item,
    page_name,
    COUNT(*) as visit_count
FROM user_analytics 
WHERE event_type = 'page_view'
GROUP BY page_name 
ORDER BY visit_count DESC;

-- 5. 检查社交互动统计
SELECT 
    '社交互动统计' as check_item,
    event_data->>'actionType' as action_type,
    event_data->>'targetType' as target_type,
    COUNT(*) as interaction_count
FROM user_analytics 
WHERE event_type = 'social_interaction'
GROUP BY event_data->>'actionType', event_data->>'targetType'
ORDER BY interaction_count DESC;

-- 6. 检查角色交互统计
SELECT 
    '角色交互统计' as check_item,
    event_data->>'interactionType' as interaction_type,
    event_data->>'character_name' as character_name,
    COUNT(*) as interaction_count
FROM user_analytics 
WHERE event_type = 'character_interaction'
GROUP BY event_data->>'interactionType', event_data->>'character_name'
ORDER BY interaction_count DESC;

-- 7. 检查点赞数据
SELECT 
    '点赞数据状态' as check_item,
    COUNT(*) as total_likes,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT target_id) as unique_targets
FROM likes;

-- 8. 检查关注数据
SELECT 
    '关注数据状态' as check_item,
    COUNT(*) as total_follows,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT character_id) as unique_characters
FROM character_follows;

-- 9. 检查评论数据
SELECT 
    '评论数据状态' as check_item,
    COUNT(*) as total_comments,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT target_id) as unique_targets
FROM comments;

-- 10. 检查特定用户的活动（替换为当前用户ID）
-- 注意：请将 'YOUR_USER_ID_HERE' 替换为实际的用户ID
SELECT 
    '特定用户活动' as check_item,
    event_type,
    page_name,
    event_data,
    created_at
FROM user_analytics 
WHERE user_id = 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d' -- 从日志中看到的用户ID
ORDER BY created_at DESC 
LIMIT 20;

-- 11. 检查首页-精选页的具体活动
SELECT 
    '首页精选页活动' as check_item,
    event_type,
    event_data,
    created_at,
    session_id
FROM user_analytics 
WHERE page_name = 'home_selection_page' 
   OR event_data->>'source' = 'featured_page'
ORDER BY created_at DESC 
LIMIT 20;

-- 12. 检查数据完整性
SELECT 
    '数据完整性检查' as check_item,
    'user_analytics表记录' as detail,
    COUNT(*) as count
FROM user_analytics
UNION ALL
SELECT 
    '数据完整性检查' as check_item,
    '有用户ID的埋点' as detail,
    COUNT(*) as count
FROM user_analytics ua
INNER JOIN users u ON ua.user_id = u.id
UNION ALL
SELECT 
    '数据完整性检查' as check_item,
    '外键约束正常' as detail,
    CASE 
        WHEN COUNT(*) = 0 THEN 1 
        ELSE 0 
    END as status
FROM user_analytics ua
LEFT JOIN users u ON ua.user_id = u.id
WHERE u.id IS NULL;

-- 13. 修复数据的SQL（如果需要）
-- 注意：只有在检查发现问题时才执行这部分

-- 创建缺失的用户记录（基于 auth.users）
INSERT INTO users (id, email, phone, created_at, updated_at)
SELECT 
    au.id,
    au.email,
    NULL, -- 匿名用户没有手机号
    au.created_at,
    au.updated_at
FROM auth.users au
LEFT JOIN users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 显示修复结果
SELECT 
    '修复结果' as result,
    COUNT(*) as users_in_public_table
FROM users;