-- ============================================================================
-- 星趣App Sprint 2 Supabase执行脚本
-- 请在Supabase控制台 > SQL Editor 中按顺序执行以下部分
-- ============================================================================

-- ============================================================================
-- 执行说明
-- ============================================================================
/*
请按以下步骤在Supabase控制台执行：

1. 登录 Supabase 控制台: https://supabase.com/dashboard
2. 选择项目: wqdpqhfqrxvssxifpmvt
3. 点击左侧菜单 "SQL Editor"
4. 新建查询，按顺序执行以下三个部分

注意：每个部分执行完成后，请检查是否有错误，然后再执行下一部分
*/

-- ============================================================================
-- 第一部分：迁移计划执行 (migration_plan_sprint2.sql)
-- ============================================================================
-- 请复制粘贴 migration_plan_sprint2.sql 文件的全部内容到这里执行

-- ============================================================================
-- 第二部分：数据库架构创建 (database_schema_sprint2.sql) 
-- ============================================================================
-- 请复制粘贴 database_schema_sprint2.sql 文件的全部内容到这里执行

-- ============================================================================
-- 第三部分：RLS安全策略配置 (rls_policies_sprint2.sql)
-- ============================================================================
-- 请复制粘贴 rls_policies_sprint2.sql 文件的全部内容到这里执行

-- ============================================================================
-- 第四部分：部署验证查询
-- ============================================================================

-- 1. 验证新表创建成功
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

-- 3. 验证初始数据插入
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

-- 4. 验证迁移日志
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

-- 5. 部署成功确认
SELECT 
    '🎉 恭喜！Sprint 2数据库模型部署完成！' as message,
    '数据库现在支持通用交互菜单、综合页六大子模块、星形动效等新功能' as description,
    NOW() as deployment_completed_at;

-- ============================================================================
-- 结束
-- ============================================================================

/*
如果所有查询都成功执行并返回预期结果，说明Sprint 2数据库部署完成！

预期结果：
- 第1个查询应该显示22个新表标记为"✅ Sprint 2 新表"
- 第2个查询应该显示各表的RLS策略数量
- 第3个查询应该显示各配置表的初始数据条数
- 第4个查询应该显示迁移状态为"✅ 完成"
- 第5个查询显示成功消息

如果有任何查询失败，请检查错误信息并联系技术支持。
*/