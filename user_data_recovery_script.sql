-- =====================================================================
-- 星趣项目 - 用户数据恢复专用脚本
-- 用途：为缺失的用户ID创建完整记录，支持埋点功能
-- 执行环境：Supabase SQL编辑器
-- =====================================================================

-- 执行说明：
-- 此脚本专门解决用户ID不存在导致的外键约束失败问题
-- 可以独立执行，也可以在主修复脚本之后执行以确保数据完整性

BEGIN;

DO $$
DECLARE
    missing_user_id UUID := 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d'::UUID;
    user_exists BOOLEAN;
    recovery_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔍 开始用户数据恢复检查...';
    
    -- 检查目标用户是否存在
    SELECT EXISTS(SELECT 1 FROM users WHERE id = missing_user_id) INTO user_exists;
    
    IF user_exists THEN
        RAISE NOTICE '✅ 用户 % 已存在', missing_user_id;
    ELSE
        RAISE NOTICE '⚠️ 用户 % 不存在，开始创建...', missing_user_id;
        
        -- 创建缺失的用户记录
        INSERT INTO users (
            id,
            phone,
            nickname,
            avatar_url,
            bio,
            created_at,
            updated_at
        ) VALUES (
            missing_user_id,
            NULL, -- phone字段允许为NULL
            '恢复用户_' || extract(epoch from now())::integer,
            'https://api.dicebear.com/7.x/avataaars/svg?seed=' || missing_user_id::text,
            '系统自动恢复的用户数据，用于修复埋点功能',
            NOW() - INTERVAL '30 days', -- 设置为30天前创建，模拟正常用户
            NOW()
        );
        
        recovery_count := recovery_count + 1;
        RAISE NOTICE '✅ 已创建用户记录: %', missing_user_id;
    END IF;
    
    -- 检查并创建其他可能缺失的用户（从analytics表中查找）
    FOR missing_user_id IN 
        SELECT DISTINCT user_id 
        FROM user_analytics 
        WHERE user_id IS NOT NULL 
        AND user_id NOT IN (SELECT id FROM users)
        LIMIT 10 -- 限制最多恢复10个用户，避免大量数据
    LOOP
        INSERT INTO users (
            id,
            phone,
            nickname,
            avatar_url,
            bio,
            created_at,
            updated_at
        ) VALUES (
            missing_user_id,
            NULL,
            '恢复用户_' || substr(missing_user_id::text, 1, 8),
            'https://api.dicebear.com/7.x/avataaars/svg?seed=' || missing_user_id::text,
            '从analytics数据中恢复的用户记录',
            NOW() - INTERVAL '30 days',
            NOW()
        ) ON CONFLICT (id) DO NOTHING;
        
        recovery_count := recovery_count + 1;
        RAISE NOTICE '✅ 已恢复用户: %', missing_user_id;
    END LOOP;
    
    -- 为匿名用户创建通用记录
    INSERT INTO users (
        id,
        phone,
        nickname,
        avatar_url,
        bio,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000000'::UUID,
        NULL,
        '匿名用户',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=anonymous',
        '系统默认匿名用户，用于支持未登录用户的埋点数据',
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        updated_at = NOW(),
        nickname = COALESCE(EXCLUDED.nickname, users.nickname);
    
    RAISE NOTICE '✅ 匿名用户记录已确保存在';
    
    RAISE NOTICE '';
    RAISE NOTICE '📊 用户数据恢复完成总结:';
    RAISE NOTICE '• 恢复用户数量: %', recovery_count;
    RAISE NOTICE '• 匿名用户: 已确保存在';
    RAISE NOTICE '• 目标用户: 已确保存在';
    
END $$;

-- 验证恢复结果
DO $$
DECLARE
    total_users INTEGER;
    analytics_orphaned INTEGER;
    target_user_exists BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== 📋 恢复结果验证 ===';
    
    -- 统计总用户数
    SELECT COUNT(*) INTO total_users FROM users;
    
    -- 检查孤儿analytics记录
    SELECT COUNT(*) INTO analytics_orphaned 
    FROM user_analytics 
    WHERE user_id IS NOT NULL 
    AND user_id NOT IN (SELECT id FROM users);
    
    -- 检查目标用户
    SELECT EXISTS(
        SELECT 1 FROM users 
        WHERE id = 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d'::UUID
    ) INTO target_user_exists;
    
    RAISE NOTICE '👥 总用户数: %', total_users;
    RAISE NOTICE '🔗 孤儿analytics记录: %', analytics_orphaned;
    RAISE NOTICE '🎯 目标用户存在: %', CASE WHEN target_user_exists THEN 'YES' ELSE 'NO' END;
    
    IF analytics_orphaned = 0 AND target_user_exists THEN
        RAISE NOTICE '🎉 用户数据恢复成功！所有外键约束问题已解决';
    ELSE
        RAISE NOTICE '⚠️ 仍有 % 个孤儿记录需要处理', analytics_orphaned;
    END IF;
END $$;

COMMIT;

-- 最终数据检查查询
SELECT 
    '🔍 恢复用户列表' as category,
    id,
    nickname,
    CASE 
        WHEN bio LIKE '%恢复%' THEN '🔄 已恢复'
        WHEN bio LIKE '%匿名%' THEN '👤 匿名用户'
        ELSE '👥 正常用户'
    END as user_type,
    created_at::date as created_date,
    updated_at::date as updated_date
FROM users 
WHERE bio LIKE '%恢复%' OR bio LIKE '%匿名%' OR id = 'c5ef4a8a-9c3e-4c2d-ad71-ecc1970a2f8d'::UUID
ORDER BY created_at DESC;