-- ============================================================================
-- 星趣App Sprint 2 一键部署脚本
-- 请在Supabase SQL编辑器中按顺序执行以下三个部分
-- ============================================================================

-- ============================================================================
-- 第一部分: 迁移计划执行
-- 复制migration_plan_sprint2.sql的全部内容到此处执行
-- ============================================================================

-- 注意：请先执行migration_plan_sprint2.sql文件的全部内容

-- ============================================================================
-- 第二部分: 数据库架构创建
-- 复制database_schema_sprint2.sql的全部内容到此处执行
-- ============================================================================

-- 注意：请在第一部分成功后执行database_schema_sprint2.sql文件的全部内容

-- ============================================================================
-- 第三部分: RLS安全策略配置
-- 复制rls_policies_sprint2.sql的全部内容到此处执行
-- ============================================================================

-- 注意：请在第二部分成功后执行rls_policies_sprint2.sql文件的全部内容

-- ============================================================================
-- 部署验证脚本
-- ============================================================================

-- 1. 验证所有新表是否创建成功
SELECT 
    table_name,
    CASE 
        WHEN table_name IN (
            'interaction_menu_configs', 'interaction_logs', 'user_subscriptions',
            'subscription_groups', 'subscription_group_items', 'recommendation_algorithms',
            'user_recommendations', 'ai_agent_categories', 'ai_character_extensions',
            'memory_types', 'memory_items', 'memory_search_vectors',
            'bilingual_contents', 'user_bilingual_progress', 'challenge_types',
            'challenge_tasks', 'user_challenge_participations', 'user_achievements',
            'ui_decorations', 'user_ui_preferences', 'system_configs', 'data_cache'
        ) THEN '✅ Sprint 2 新表'
        ELSE '📋 已有表'
    END as table_status
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY 
    CASE WHEN table_name IN (
        'interaction_menu_configs', 'interaction_logs', 'user_subscriptions',
        'subscription_groups', 'subscription_group_items', 'recommendation_algorithms',
        'user_recommendations', 'ai_agent_categories', 'ai_character_extensions',
        'memory_types', 'memory_items', 'memory_search_vectors',
        'bilingual_contents', 'user_bilingual_progress', 'challenge_types',
        'challenge_tasks', 'user_challenge_participations', 'user_achievements',
        'ui_decorations', 'user_ui_preferences', 'system_configs', 'data_cache'
    ) THEN 1 ELSE 2 END,
    table_name;

-- 2. 验证RLS策略配置
SELECT 
    tablename,
    COUNT(*) as policy_count,
    array_agg(policyname) as policies
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN (
    'interaction_logs', 'user_subscriptions', 'subscription_groups',
    'user_recommendations', 'memory_items', 'memory_search_vectors',
    'user_bilingual_progress', 'user_challenge_participations',
    'user_achievements', 'user_ui_preferences'
  )
GROUP BY tablename
ORDER BY tablename;

-- 3. 验证初始数据是否插入成功
SELECT 'memory_types' as table_name, COUNT(*) as record_count FROM memory_types
UNION ALL
SELECT 'ai_agent_categories' as table_name, COUNT(*) as record_count FROM ai_agent_categories  
UNION ALL
SELECT 'challenge_types' as table_name, COUNT(*) as record_count FROM challenge_types
UNION ALL
SELECT 'interaction_menu_configs' as table_name, COUNT(*) as record_count FROM interaction_menu_configs
UNION ALL
SELECT 'ui_decorations' as table_name, COUNT(*) as record_count FROM ui_decorations
UNION ALL
SELECT 'system_configs' as table_name, COUNT(*) as record_count FROM system_configs
ORDER BY table_name;

-- 4. 运行数据完整性检查
SELECT * FROM check_data_integrity_sprint2();

-- 5. 验证迁移日志
SELECT 
    migration_name,
    migration_version,
    status,
    started_at,
    completed_at,
    CASE 
        WHEN status = 'completed' THEN '✅ 完成'
        WHEN status = 'running' THEN '🔄 运行中'
        WHEN status = 'failed' THEN '❌ 失败'
        ELSE '⏳ 待处理'
    END as status_display
FROM migration_logs 
ORDER BY started_at DESC;

-- ============================================================================
-- 部署成功确认
-- ============================================================================

-- 如果以上所有查询都返回预期结果，说明Sprint 2数据库模型部署成功！
-- 您现在可以开始使用新的功能模块了。

SELECT 
    '🎉 恭喜！Sprint 2数据库模型部署完成！' as message,
    '数据库现在支持通用交互菜单、综合页六大子模块、星形动效等新功能' as description,
    NOW() as deployment_completed_at;