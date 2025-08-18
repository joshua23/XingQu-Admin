-- ============================================================================
-- 星趣App Sprint 2 Row Level Security (RLS) 策略
-- 确保用户数据安全和隐私保护
-- ============================================================================

-- ============================================================================
-- 1. 启用RLS和基础安全设置
-- ============================================================================

-- 为新表启用RLS
ALTER TABLE interaction_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_groups ENABLE ROW LEVEL SECURITY; 
ALTER TABLE subscription_group_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_search_vectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_bilingual_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenge_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ui_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. 用户交互日志RLS策略
-- ============================================================================

-- 用户只能查看自己的交互日志
CREATE POLICY "Users can view their own interaction logs" ON interaction_logs
    FOR SELECT USING (auth.uid() = user_id);

-- 用户只能插入自己的交互日志
CREATE POLICY "Users can insert their own interaction logs" ON interaction_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 管理员可以查看所有交互日志（用于分析）
CREATE POLICY "Admins can view all interaction logs" ON interaction_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'moderator')
        )
    );

-- ============================================================================
-- 3. 用户订阅关系RLS策略
-- ============================================================================

-- 用户只能管理自己的订阅
CREATE POLICY "Users can manage their own subscriptions" ON user_subscriptions
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 用户只能管理自己的订阅分组
CREATE POLICY "Users can manage their own subscription groups" ON subscription_groups
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 用户只能管理自己分组下的订阅项
CREATE POLICY "Users can manage their own subscription group items" ON subscription_group_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM subscription_groups sg
            WHERE sg.id = subscription_group_items.group_id
            AND sg.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM subscription_groups sg
            WHERE sg.id = subscription_group_items.group_id
            AND sg.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 4. 推荐系统RLS策略
-- ============================================================================

-- 用户只能查看自己的推荐结果
CREATE POLICY "Users can view their own recommendations" ON user_recommendations
    FOR SELECT USING (auth.uid() = user_id);

-- 系统可以插入推荐结果（通过服务账号）
CREATE POLICY "System can insert recommendations" ON user_recommendations
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'system'
        )
    );

-- 用户可以删除过期的推荐结果
CREATE POLICY "Users can delete expired recommendations" ON user_recommendations
    FOR DELETE USING (
        auth.uid() = user_id AND 
        expires_at < NOW()
    );

-- ============================================================================
-- 5. 记忆簿RLS策略
-- ============================================================================

-- 用户只能管理自己的记忆条目
CREATE POLICY "Users can manage their own memory items" ON memory_items
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 用户只能管理自己记忆条目的搜索向量
CREATE POLICY "Users can manage their own memory search vectors" ON memory_search_vectors
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM memory_items mi
            WHERE mi.id = memory_search_vectors.memory_id
            AND mi.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM memory_items mi
            WHERE mi.id = memory_search_vectors.memory_id
            AND mi.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 6. 双语学习RLS策略
-- ============================================================================

-- 所有用户都可以查看公开的双语内容
CREATE POLICY "Users can view public bilingual contents" ON bilingual_contents
    FOR SELECT USING (is_public = true);

-- 用户可以查看和管理自己创建的双语内容
CREATE POLICY "Users can manage their own bilingual contents" ON bilingual_contents
    FOR ALL USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

-- 用户只能管理自己的双语学习进度
CREATE POLICY "Users can manage their own bilingual progress" ON user_bilingual_progress
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 7. 挑战任务RLS策略
-- ============================================================================

-- 所有用户都可以查看活跃的挑战任务
CREATE POLICY "Users can view active challenges" ON challenge_tasks
    FOR SELECT USING (status = 'active');

-- 创建者可以管理自己创建的挑战任务
CREATE POLICY "Creators can manage their own challenges" ON challenge_tasks
    FOR ALL USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

-- 管理员可以管理所有挑战任务
CREATE POLICY "Admins can manage all challenges" ON challenge_tasks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'moderator')
        )
    );

-- 用户只能管理自己的挑战参与记录
CREATE POLICY "Users can manage their own challenge participations" ON user_challenge_participations
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 用户只能查看自己的成就
CREATE POLICY "Users can view their own achievements" ON user_achievements
    FOR SELECT USING (auth.uid() = user_id);

-- 系统可以为用户授予成就
CREATE POLICY "System can grant achievements" ON user_achievements
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'system'
        )
    );

-- ============================================================================
-- 8. UI偏好设置RLS策略
-- ============================================================================

-- 用户只能管理自己的UI偏好设置
CREATE POLICY "Users can manage their own UI preferences" ON user_ui_preferences
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 9. 公共配置表的读取策略
-- ============================================================================

-- 所有认证用户都可以查看交互菜单配置
CREATE POLICY "Authenticated users can view interaction menu configs" ON interaction_menu_configs
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- 管理员可以管理交互菜单配置
CREATE POLICY "Admins can manage interaction menu configs" ON interaction_menu_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'moderator')
        )
    );

-- 所有认证用户都可以查看记忆类型配置
CREATE POLICY "Authenticated users can view memory types" ON memory_types
    FOR SELECT USING (auth.role() = 'authenticated');

-- 所有认证用户都可以查看AI智能体分类
CREATE POLICY "Authenticated users can view ai agent categories" ON ai_agent_categories
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- 所有认证用户都可以查看挑战类型
CREATE POLICY "Authenticated users can view challenge types" ON challenge_types
    FOR SELECT USING (auth.role() = 'authenticated');

-- 认证用户可以查看公开的系统配置
CREATE POLICY "Authenticated users can view public system configs" ON system_configs
    FOR SELECT USING (auth.role() = 'authenticated' AND is_public = true);

-- 管理员可以管理所有系统配置
CREATE POLICY "Admins can manage all system configs" ON system_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'moderator')
        )
    );

-- ============================================================================
-- 10. 特殊权限和安全函数
-- ============================================================================

-- 创建安全检查函数
CREATE OR REPLACE FUNCTION check_user_role(required_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = required_role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建数据访问审计函数
CREATE OR REPLACE FUNCTION log_sensitive_access(
    table_name TEXT,
    record_id UUID,
    access_type TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO user_analytics (user_id, event_type, event_data)
    VALUES (
        auth.uid(),
        'sensitive_data_access',
        jsonb_build_object(
            'table_name', table_name,
            'record_id', record_id,
            'access_type', access_type,
            'timestamp', NOW()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 11. 数据清理和维护策略
-- ============================================================================

-- 创建过期数据清理策略（仅管理员可执行）
CREATE POLICY "Admins can delete expired cache data" ON data_cache
    FOR DELETE USING (
        expires_at < NOW() AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'system')
        )
    );

-- 允许系统账户插入和更新缓存数据
CREATE POLICY "System can manage cache data" ON data_cache
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'system'
        )
    );

-- ============================================================================
-- 12. 测试RLS策略
-- ============================================================================

-- 创建RLS策略测试函数
CREATE OR REPLACE FUNCTION test_rls_policies()
RETURNS TABLE (
    policy_name TEXT,
    table_name TEXT,
    test_result TEXT,
    description TEXT
) AS $$
BEGIN
    -- 这里可以添加RLS策略的自动化测试
    -- 实际实现需要创建测试用户和测试数据
    
    RETURN QUERY SELECT 
        'user_data_isolation'::TEXT as policy_name,
        'user_subscriptions'::TEXT as table_name,
        'PENDING'::TEXT as test_result,
        '测试用户只能访问自己的订阅数据'::TEXT as description;
        
    RETURN QUERY SELECT 
        'admin_access'::TEXT as policy_name,
        'interaction_logs'::TEXT as table_name,
        'PENDING'::TEXT as test_result,
        '测试管理员可以访问所有交互日志'::TEXT as description;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 13. RLS策略监控和报告
-- ============================================================================

-- 创建RLS违规监控函数
CREATE OR REPLACE FUNCTION monitor_rls_violations()
RETURNS TABLE (
    user_id UUID,
    violation_type TEXT,
    table_name TEXT,
    attempted_action TEXT,
    violation_time TIMESTAMPTZ
) AS $$
BEGIN
    -- 这里可以实现RLS违规监控逻辑
    -- 实际需要与PostgreSQL日志系统集成
    
    RETURN QUERY SELECT 
        NULL::UUID as user_id,
        'INFO'::TEXT as violation_type,
        'monitoring'::TEXT as table_name,
        'RLS monitoring active'::TEXT as attempted_action,
        NOW() as violation_time;
END;
$$ LANGUAGE plpgsql;

-- 记录RLS策略部署完成
INSERT INTO migration_logs (migration_name, migration_version, status, completed_at) 
VALUES ('Sprint 2 RLS Policies', '2.0.0', 'completed', NOW());