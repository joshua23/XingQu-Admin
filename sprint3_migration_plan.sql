-- ============================================================================
-- 星趣App Sprint 3 数据迁移计划
-- 确保与现有Sprint 1-2数据的无缝集成和向后兼容性
-- ============================================================================

-- ============================================================================
-- 第一部分: 迁移前检查和备份
-- ============================================================================

-- 检查现有数据结构
DO $$
DECLARE
    table_count INTEGER;
    user_count INTEGER;
    character_count INTEGER;
BEGIN
    -- 检查核心表是否存在
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('users', 'characters', 'stories', 'user_subscriptions');
    
    IF table_count < 4 THEN
        RAISE EXCEPTION 'Missing core tables. Please ensure Sprint 1-2 is properly deployed.';
    END IF;
    
    -- 检查用户数据
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO character_count FROM characters;
    
    RAISE NOTICE '迁移前检查通过:';
    RAISE NOTICE '- 用户数量: %', user_count;
    RAISE NOTICE '- 角色数量: %', character_count;
    RAISE NOTICE '- 核心表完整性: 已验证';
END $$;

-- 创建备份表（可选，生产环境建议）
-- CREATE TABLE users_backup_sprint3 AS SELECT * FROM users;
-- CREATE TABLE characters_backup_sprint3 AS SELECT * FROM characters;

-- ============================================================================
-- 第二部分: 现有表结构扩展
-- ============================================================================

-- 扩展users表以支持会员功能
DO $$ 
BEGIN
    -- 添加会员相关字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'membership_tier') THEN
        ALTER TABLE users ADD COLUMN membership_tier VARCHAR(20) DEFAULT 'free';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'total_spent_cents') THEN
        ALTER TABLE users ADD COLUMN total_spent_cents INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'referral_code') THEN
        ALTER TABLE users ADD COLUMN referral_code VARCHAR(20) UNIQUE;
    END IF;
    
    -- 为现有用户生成推荐码
    UPDATE users 
    SET referral_code = 'XQ' || UPPER(SUBSTRING(id::TEXT, 1, 6))
    WHERE referral_code IS NULL;
END $$;

-- 扩展characters表以支持智能体功能
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'characters' AND column_name = 'character_type') THEN
        ALTER TABLE characters ADD COLUMN character_type VARCHAR(20) DEFAULT 'official';
        -- 'official' | 'custom' | 'community'
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'characters' AND column_name = 'access_level') THEN
        ALTER TABLE characters ADD COLUMN access_level VARCHAR(20) DEFAULT 'free';
        -- 'free' | 'basic' | 'premium' | 'exclusive'
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'characters' AND column_name = 'creator_id') THEN
        ALTER TABLE characters ADD COLUMN creator_id UUID REFERENCES users(id);
    END IF;
    
    -- 设置现有角色为官方角色
    UPDATE characters 
    SET character_type = 'official', 
        access_level = 'free',
        updated_at = NOW()
    WHERE character_type IS NULL;
END $$;

-- ============================================================================
-- 第三部分: 数据迁移脚本
-- ============================================================================

-- 1. 为现有用户创建免费会员记录
INSERT INTO user_memberships (user_id, plan_id, status, started_at, expires_at)
SELECT 
    u.id,
    sp.id,
    'active',
    COALESCE(u.created_at, NOW()),
    NULL -- 免费会员永不过期
FROM users u
CROSS JOIN subscription_plans sp
WHERE sp.plan_code = 'free'
  AND NOT EXISTS (
      SELECT 1 FROM user_memberships um 
      WHERE um.user_id = u.id AND um.status = 'active'
  );

-- 2. 为现有用户创建默认Tab偏好设置
INSERT INTO user_tab_preferences (user_id, default_tab, comprehensive_default_subtab)
SELECT 
    id,
    'comprehensive',
    'recommend'
FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM user_tab_preferences utp 
    WHERE utp.user_id = users.id
);

-- 3. 迁移现有推荐数据（如果存在user_recommendations表）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_recommendations') THEN
        -- 将现有推荐转换为反馈数据
        INSERT INTO recommendation_feedback (
            user_id, content_type, content_id, feedback_type, 
            feedback_value, session_id, created_at
        )
        SELECT 
            user_id,
            'character' as content_type,
            character_id as content_id,
            CASE 
                WHEN rating >= 4 THEN 'like'
                WHEN rating <= 2 THEN 'dislike'
                ELSE 'view'
            END as feedback_type,
            LEAST(rating / 5.0, 1.0) as feedback_value,
            gen_random_uuid() as session_id,
            created_at
        FROM user_recommendations
        WHERE character_id IS NOT NULL;
        
        RAISE NOTICE '已迁移现有推荐数据到新的反馈系统';
    END IF;
END $$;

-- 4. 为现有角色创建智能体运行状态记录
INSERT INTO agent_runtime_status (agent_id, status, last_activity_at, health_check_status)
SELECT 
    c.id,
    'stopped' as status,
    NOW() as last_activity_at,
    'healthy' as health_check_status
FROM characters c
WHERE c.character_type = 'custom'
  AND NOT EXISTS (
      SELECT 1 FROM agent_runtime_status ars 
      WHERE ars.agent_id = c.id
  );

-- ============================================================================
-- 第四部分: 数据一致性检查
-- ============================================================================

-- 创建数据一致性检查函数
CREATE OR REPLACE FUNCTION verify_sprint3_migration()
RETURNS TABLE(check_name TEXT, status TEXT, details TEXT) AS $$
BEGIN
    -- 检查1: 用户会员状态一致性
    RETURN QUERY
    SELECT 
        'user_membership_consistency' as check_name,
        CASE 
            WHEN COUNT(*) = 0 THEN 'PASS'
            ELSE 'FAIL'
        END as status,
        'Users without active membership: ' || COUNT(*)::TEXT as details
    FROM users u
    LEFT JOIN user_memberships um ON u.id = um.user_id AND um.status = 'active'
    WHERE um.id IS NULL;
    
    -- 检查2: Tab偏好设置完整性
    RETURN QUERY
    SELECT 
        'tab_preferences_completeness' as check_name,
        CASE 
            WHEN COUNT(*) = 0 THEN 'PASS'
            ELSE 'FAIL'
        END as status,
        'Users without tab preferences: ' || COUNT(*)::TEXT as details
    FROM users u
    LEFT JOIN user_tab_preferences utp ON u.id = utp.user_id
    WHERE utp.id IS NULL;
    
    -- 检查3: 订阅套餐配置完整性
    RETURN QUERY
    SELECT 
        'subscription_plans_integrity' as check_name,
        CASE 
            WHEN COUNT(*) >= 4 THEN 'PASS'
            ELSE 'FAIL'
        END as status,
        'Active subscription plans: ' || COUNT(*)::TEXT as details
    FROM subscription_plans
    WHERE is_active = true;
    
    -- 检查4: 智能体数据完整性
    RETURN QUERY
    SELECT 
        'agent_data_integrity' as check_name,
        CASE 
            WHEN inconsistent_count = 0 THEN 'PASS'
            ELSE 'FAIL'
        END as status,
        'Characters without runtime status: ' || inconsistent_count::TEXT as details
    FROM (
        SELECT COUNT(*) as inconsistent_count
        FROM characters c
        LEFT JOIN agent_runtime_status ars ON c.id = ars.agent_id
        WHERE c.character_type = 'custom' AND ars.id IS NULL
    ) sub;
    
    -- 检查5: RLS策略启用状态
    RETURN QUERY
    SELECT 
        'rls_policies_enabled' as check_name,
        CASE 
            WHEN COUNT(*) >= 12 THEN 'PASS'
            ELSE 'FAIL'
        END as status,
        'Tables with RLS enabled: ' || COUNT(*)::TEXT as details
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relrowsecurity = true
      AND c.relname IN (
          'subscription_plans', 'user_memberships', 'payment_orders',
          'payment_callbacks', 'recommendation_configs', 'recommendation_feedback',
          'custom_agents', 'agent_runtime_status', 'agent_permissions',
          'membership_benefits', 'membership_usage_logs', 'user_tab_preferences'
      );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 第五部分: 清理和优化
-- ============================================================================

-- 清理临时数据和重复记录
DO $$
BEGIN
    -- 清理重复的会员记录（保留最新的）
    DELETE FROM user_memberships um1
    WHERE EXISTS (
        SELECT 1 FROM user_memberships um2
        WHERE um2.user_id = um1.user_id
          AND um2.status = um1.status
          AND um2.created_at > um1.created_at
    );
    
    -- 清理过期的pending订单
    UPDATE payment_orders 
    SET status = 'cancelled', 
        cancelled_at = NOW()
    WHERE status = 'pending' 
      AND expires_at < NOW();
      
    RAISE NOTICE '数据清理完成';
END $$;

-- 更新统计信息
ANALYZE users;
ANALYZE characters;
ANALYZE subscription_plans;
ANALYZE user_memberships;
ANALYZE payment_orders;
ANALYZE custom_agents;
ANALYZE recommendation_feedback;

-- ============================================================================
-- 第六部分: 向后兼容性保证
-- ============================================================================

-- 创建兼容性视图，确保现有API继续工作
CREATE OR REPLACE VIEW characters_with_access AS
SELECT 
    c.*,
    CASE 
        WHEN c.access_level = 'free' THEN true
        WHEN c.access_level = 'basic' AND check_user_membership_level(auth.uid()) IN ('basic', 'premium', 'lifetime') THEN true
        WHEN c.access_level = 'premium' AND check_user_membership_level(auth.uid()) IN ('premium', 'lifetime') THEN true
        ELSE false
    END as user_has_access
FROM characters c
WHERE c.is_active = true;

-- 创建用户会员信息视图
CREATE OR REPLACE VIEW user_membership_info AS
SELECT 
    u.id as user_id,
    u.email,
    u.membership_tier,
    sp.plan_name,
    sp.plan_type,
    sp.features,
    sp.limits,
    um.status as membership_status,
    um.started_at as membership_started,
    um.expires_at as membership_expires,
    CASE 
        WHEN um.expires_at IS NULL THEN true
        WHEN um.expires_at > NOW() THEN true
        ELSE false
    END as is_membership_active
FROM users u
LEFT JOIN user_memberships um ON u.id = um.user_id AND um.status = 'active'
LEFT JOIN subscription_plans sp ON um.plan_id = sp.id;

-- ============================================================================
-- 第七部分: 迁移完成验证
-- ============================================================================

-- 执行完整性检查
DO $$
DECLARE
    check_result RECORD;
    all_passed BOOLEAN := true;
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Sprint 3 数据迁移完整性检查';
    RAISE NOTICE '==========================================';
    
    FOR check_result IN SELECT * FROM verify_sprint3_migration() LOOP
        RAISE NOTICE '% : % - %', check_result.check_name, check_result.status, check_result.details;
        
        IF check_result.status = 'FAIL' THEN
            all_passed := false;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==========================================';
    
    IF all_passed THEN
        RAISE NOTICE '✅ 所有检查通过，迁移成功完成！';
        
        -- 更新迁移日志
        UPDATE migration_logs 
        SET status = 'completed', 
            completed_at = NOW() 
        WHERE migration_name = 'Sprint 3 Complete Database Extension' 
          AND migration_version = '3.0.0';
    ELSE
        RAISE NOTICE '❌ 部分检查失败，请检查上述问题';
        
        -- 更新迁移日志
        UPDATE migration_logs 
        SET status = 'partial_failure', 
            error_message = 'Some integrity checks failed' 
        WHERE migration_name = 'Sprint 3 Complete Database Extension' 
          AND migration_version = '3.0.0';
    END IF;
    
    RAISE NOTICE '==========================================';
END $$;

-- ============================================================================
-- 迁移计划完成
-- ============================================================================