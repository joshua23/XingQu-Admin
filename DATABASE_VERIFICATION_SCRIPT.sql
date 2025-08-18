-- =============================================
-- 星趣APP数据库完整性验证脚本
-- 用途: 检查Sprint2和Sprint3的所有关键表是否存在
-- 执行: 在Supabase Dashboard SQL Editor中运行
-- =============================================

DO $$
DECLARE
    missing_tables TEXT := '';
    table_count INTEGER;
BEGIN
    RAISE NOTICE '🔍 开始验证星趣APP数据库模型完整性...';
    RAISE NOTICE '';

    -- =============================================
    -- 第一部分: 基础核心功能表验证
    -- =============================================
    
    RAISE NOTICE '📋 第一部分: 基础核心功能表验证';
    
    -- 检查用户互动基础表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ likes (用户点赞表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM likes;
        RAISE NOTICE '✅ likes 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ comments (用户评论表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM comments;
        RAISE NOTICE '✅ comments 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'character_follows' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ character_follows (角色关注表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM character_follows;
        RAISE NOTICE '✅ character_follows 表存在 (%条记录)', table_count;
    END IF;
    
    RAISE NOTICE '';
    
    -- =============================================
    -- 第二部分: Sprint2功能表验证
    -- =============================================
    
    RAISE NOTICE '📋 第二部分: Sprint2功能表验证';
    
    -- 推荐系统表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recommendation_algorithms' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ recommendation_algorithms (推荐算法表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM recommendation_algorithms;
        RAISE NOTICE '✅ recommendation_algorithms 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_recommendations' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ user_recommendations (用户推荐表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM user_recommendations;
        RAISE NOTICE '✅ user_recommendations 表存在 (%条记录)', table_count;
    END IF;
    
    -- 记忆系统表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'memory_types' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ memory_types (记忆类型表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM memory_types;
        RAISE NOTICE '✅ memory_types 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'memory_items' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ memory_items (记忆项目表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM memory_items;
        RAISE NOTICE '✅ memory_items 表存在 (%条记录)', table_count;
    END IF;
    
    -- 学习系统表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bilingual_contents' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ bilingual_contents (双语内容表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM bilingual_contents;
        RAISE NOTICE '✅ bilingual_contents 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'challenge_types' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ challenge_types (挑战类型表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM challenge_types;
        RAISE NOTICE '✅ challenge_types 表存在 (%条记录)', table_count;
    END IF;
    
    RAISE NOTICE '';
    
    -- =============================================
    -- 第三部分: Sprint3商业化功能表验证
    -- =============================================
    
    RAISE NOTICE '📋 第三部分: Sprint3商业化功能表验证';
    
    -- 订阅和支付表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_plans' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ subscription_plans (订阅套餐表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM subscription_plans;
        RAISE NOTICE '✅ subscription_plans 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_memberships' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ user_memberships (用户会员表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM user_memberships;
        RAISE NOTICE '✅ user_memberships 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_orders' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ payment_orders (支付订单表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM payment_orders;
        RAISE NOTICE '✅ payment_orders 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'membership_benefits' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ membership_benefits (会员权益表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM membership_benefits;
        RAISE NOTICE '✅ membership_benefits 表存在 (%条记录)', table_count;
    END IF;
    
    -- AI智能体表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'custom_agents' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ custom_agents (自定义智能体表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM custom_agents;
        RAISE NOTICE '✅ custom_agents 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agent_permissions' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ agent_permissions (智能体权限表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM agent_permissions;
        RAISE NOTICE '✅ agent_permissions 表存在 (%条记录)', table_count;
    END IF;
    
    RAISE NOTICE '';
    
    -- =============================================
    -- 第四部分: 数据埋点系统表验证
    -- =============================================
    
    RAISE NOTICE '📋 第四部分: 数据埋点系统表验证';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_tracking_events' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ app_tracking_events (应用事件追踪表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM app_tracking_events;
        RAISE NOTICE '✅ app_tracking_events 表存在 (%条记录)', table_count;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_behavior_summary' AND table_schema = 'public') THEN
        missing_tables := missing_tables || '❌ user_behavior_summary (用户行为汇总表)' || E'\n';
    ELSE
        SELECT COUNT(*) INTO table_count FROM user_behavior_summary;
        RAISE NOTICE '✅ user_behavior_summary 表存在 (%条记录)', table_count;
    END IF;
    
    RAISE NOTICE '';
    
    -- =============================================
    -- 总结报告
    -- =============================================
    
    IF LENGTH(missing_tables) = 0 THEN
        RAISE NOTICE '🎉🎉🎉 数据库模型验证完成! 所有关键表都已正确部署! 🎉🎉🎉';
        RAISE NOTICE '';
        RAISE NOTICE '✅ Sprint2功能表: 完整部署';
        RAISE NOTICE '✅ Sprint3商业化功能表: 完整部署';
        RAISE NOTICE '✅ 数据埋点系统表: 完整部署';
        RAISE NOTICE '✅ 基础核心功能表: 完整部署';
        RAISE NOTICE '';
        RAISE NOTICE '🚀 可以开始开发API和Edge Functions了!';
    ELSE
        RAISE NOTICE '⚠️⚠️⚠️ 发现缺失的表! 需要立即修复! ⚠️⚠️⚠️';
        RAISE NOTICE '';
        RAISE NOTICE '缺失的表:';
        RAISE NOTICE '%', missing_tables;
        RAISE NOTICE '';
        RAISE NOTICE '🔧 建议修复步骤:';
        RAISE NOTICE '1. 执行 FINAL_FIXED_SCRIPT.sql';
        RAISE NOTICE '2. 执行 sprint3_deployment_fixed.sql';  
        RAISE NOTICE '3. 重新运行此验证脚本';
    END IF;
    
    RAISE NOTICE '';
    
END $$;

-- =============================================
-- 额外信息: 显示所有public表的统计
-- =============================================

SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN schemaname = 'public' THEN '📊 业务表'
        WHEN schemaname = 'auth' THEN '🔐 认证表' 
        WHEN schemaname = 'storage' THEN '📁 存储表'
        ELSE '🔧 系统表'
    END as table_type
FROM pg_tables 
WHERE schemaname IN ('public', 'auth', 'storage')
ORDER BY schemaname, tablename;