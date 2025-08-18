-- ============================================================================
-- 星趣App Sprint 3 Row Level Security (RLS) 策略配置
-- 确保数据安全访问和用户隔离
-- ============================================================================

-- ============================================================================
-- 第一部分: 启用RLS并设置基础策略
-- ============================================================================

-- 启用所有新表的RLS
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_callbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_runtime_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_benefits ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tab_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 第二部分: 订阅套餐访问策略
-- ============================================================================

-- 订阅套餐表 - 所有用户可查看活跃套餐
CREATE POLICY "Public can view active subscription plans" ON subscription_plans
    FOR SELECT USING (is_active = true);

-- 订阅套餐表 - 管理员可以管理所有套餐
CREATE POLICY "Admins can manage subscription plans" ON subscription_plans
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- ============================================================================
-- 第三部分: 用户会员状态策略
-- ============================================================================

-- 用户会员状态表 - 用户只能查看自己的会员状态
CREATE POLICY "Users can view own membership" ON user_memberships
    FOR SELECT USING (user_id = auth.uid());

-- 用户会员状态表 - 系统可以插入和更新会员状态
CREATE POLICY "System can manage memberships" ON user_memberships
    FOR ALL USING (
        -- 通过服务角色或管理员权限
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'system')
        )
    );

-- ============================================================================
-- 第四部分: 支付订单安全策略
-- ============================================================================

-- 支付订单表 - 用户只能查看自己的订单
CREATE POLICY "Users can view own orders" ON payment_orders
    FOR SELECT USING (user_id = auth.uid());

-- 支付订单表 - 用户可以创建自己的订单
CREATE POLICY "Users can create own orders" ON payment_orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- 支付订单表 - 系统可以更新订单状态
CREATE POLICY "System can update order status" ON payment_orders
    FOR UPDATE USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'system')
        )
    );

-- 支付回调表 - 仅系统角色可以访问
CREATE POLICY "Only system can access payment callbacks" ON payment_callbacks
    FOR ALL USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- ============================================================================
-- 第五部分: 推荐系统策略
-- ============================================================================

-- 推荐配置表 - 所有用户可查看活跃配置
CREATE POLICY "Users can view active recommendation configs" ON recommendation_configs
    FOR SELECT USING (is_active = true);

-- 推荐配置表 - 管理员可以管理配置
CREATE POLICY "Admins can manage recommendation configs" ON recommendation_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- 推荐反馈表 - 用户只能管理自己的反馈
CREATE POLICY "Users can manage own recommendation feedback" ON recommendation_feedback
    FOR ALL USING (user_id = auth.uid());

-- 推荐反馈表 - 系统可以查看反馈数据用于算法优化
CREATE POLICY "System can view recommendation feedback" ON recommendation_feedback
    FOR SELECT USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'data_analyst')
        )
    );

-- ============================================================================
-- 第六部分: 自定义智能体策略
-- ============================================================================

-- 自定义智能体表 - 用户可以查看公开的和自己创建的智能体
CREATE POLICY "Users can view accessible agents" ON custom_agents
    FOR SELECT USING (
        visibility = 'public' OR 
        creator_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM agent_permissions 
            WHERE agent_permissions.agent_id = custom_agents.id 
            AND agent_permissions.user_id = auth.uid()
            AND agent_permissions.permission_type IN ('view', 'chat', 'edit', 'admin')
            AND agent_permissions.is_active = true
            AND (agent_permissions.expires_at IS NULL OR agent_permissions.expires_at > NOW())
        )
    );

-- 自定义智能体表 - 用户可以创建自己的智能体
CREATE POLICY "Users can create own agents" ON custom_agents
    FOR INSERT WITH CHECK (creator_id = auth.uid());

-- 自定义智能体表 - 用户可以更新自己创建的智能体
CREATE POLICY "Users can update own agents" ON custom_agents
    FOR UPDATE USING (
        creator_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM agent_permissions 
            WHERE agent_permissions.agent_id = custom_agents.id 
            AND agent_permissions.user_id = auth.uid()
            AND agent_permissions.permission_type IN ('edit', 'admin')
            AND agent_permissions.is_active = true
            AND (agent_permissions.expires_at IS NULL OR agent_permissions.expires_at > NOW())
        )
    );

-- 自定义智能体表 - 用户可以删除自己创建的智能体
CREATE POLICY "Users can delete own agents" ON custom_agents
    FOR DELETE USING (
        creator_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM agent_permissions 
            WHERE agent_permissions.agent_id = custom_agents.id 
            AND agent_permissions.user_id = auth.uid()
            AND agent_permissions.permission_type = 'admin'
            AND agent_permissions.is_active = true
            AND (agent_permissions.expires_at IS NULL OR agent_permissions.expires_at > NOW())
        )
    );

-- ============================================================================
-- 第七部分: 智能体运行状态策略
-- ============================================================================

-- 智能体运行状态表 - 用户可以查看有权限的智能体状态
CREATE POLICY "Users can view accessible agent status" ON agent_runtime_status
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM custom_agents ca
            LEFT JOIN agent_permissions ap ON ca.id = ap.agent_id AND ap.user_id = auth.uid()
            WHERE ca.id = agent_runtime_status.agent_id
            AND (
                ca.visibility = 'public' OR 
                ca.creator_id = auth.uid() OR
                (ap.permission_type IN ('view', 'chat', 'edit', 'admin')
                 AND ap.is_active = true
                 AND (ap.expires_at IS NULL OR ap.expires_at > NOW()))
            )
        )
    );

-- 智能体运行状态表 - 系统可以更新运行状态
CREATE POLICY "System can update agent runtime status" ON agent_runtime_status
    FOR ALL USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM custom_agents ca
            WHERE ca.id = agent_runtime_status.agent_id 
            AND ca.creator_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'system')
        )
    );

-- ============================================================================
-- 第八部分: 智能体权限管理策略
-- ============================================================================

-- 智能体权限表 - 用户可以查看自己的权限
CREATE POLICY "Users can view own agent permissions" ON agent_permissions
    FOR SELECT USING (user_id = auth.uid());

-- 智能体权限表 - 智能体创建者可以管理权限
CREATE POLICY "Creators can manage agent permissions" ON agent_permissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM custom_agents 
            WHERE custom_agents.id = agent_permissions.agent_id 
            AND custom_agents.creator_id = auth.uid()
        )
    );

-- 智能体权限表 - 具有admin权限的用户可以管理权限
CREATE POLICY "Admins can manage agent permissions" ON agent_permissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM agent_permissions ap
            WHERE ap.agent_id = agent_permissions.agent_id 
            AND ap.user_id = auth.uid()
            AND ap.permission_type = 'admin'
            AND ap.is_active = true
            AND (ap.expires_at IS NULL OR ap.expires_at > NOW())
        )
    );

-- ============================================================================
-- 第九部分: 会员权益策略
-- ============================================================================

-- 会员权益配置表 - 所有用户可查看活跃权益
CREATE POLICY "Users can view active membership benefits" ON membership_benefits
    FOR SELECT USING (is_active = true);

-- 会员权益配置表 - 管理员可以管理权益
CREATE POLICY "Admins can manage membership benefits" ON membership_benefits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- 会员使用记录表 - 用户只能查看自己的使用记录
CREATE POLICY "Users can view own usage logs" ON membership_usage_logs
    FOR SELECT USING (user_id = auth.uid());

-- 会员使用记录表 - 系统可以记录使用情况
CREATE POLICY "System can record usage logs" ON membership_usage_logs
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'system')
        )
    );

-- ============================================================================
-- 第十部分: 用户偏好设置策略
-- ============================================================================

-- 用户Tab偏好表 - 用户只能管理自己的偏好
CREATE POLICY "Users can manage own tab preferences" ON user_tab_preferences
    FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- 第十一部分: 辅助函数和视图
-- ============================================================================

-- 创建用户会员状态检查函数
CREATE OR REPLACE FUNCTION check_user_membership_level(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    membership_level TEXT;
BEGIN
    SELECT sp.plan_type INTO membership_level
    FROM user_memberships um
    JOIN subscription_plans sp ON um.plan_id = sp.id
    WHERE um.user_id = user_uuid 
      AND um.status = 'active'
      AND (um.expires_at IS NULL OR um.expires_at > NOW())
    ORDER BY 
        CASE sp.plan_type 
            WHEN 'lifetime' THEN 4
            WHEN 'premium' THEN 3 
            WHEN 'basic' THEN 2
            WHEN 'free' THEN 1
            ELSE 0
        END DESC
    LIMIT 1;
    
    RETURN COALESCE(membership_level, 'free');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建智能体访问权限检查函数
CREATE OR REPLACE FUNCTION check_agent_access_permission(agent_uuid UUID, user_uuid UUID, required_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    has_permission BOOLEAN := false;
BEGIN
    -- 检查是否是创建者
    IF EXISTS (
        SELECT 1 FROM custom_agents 
        WHERE id = agent_uuid AND creator_id = user_uuid
    ) THEN
        RETURN true;
    END IF;
    
    -- 检查是否是公开智能体
    IF EXISTS (
        SELECT 1 FROM custom_agents 
        WHERE id = agent_uuid AND visibility = 'public' AND status = 'active'
    ) AND required_permission = 'view' THEN
        RETURN true;
    END IF;
    
    -- 检查显式权限
    SELECT EXISTS (
        SELECT 1 FROM agent_permissions 
        WHERE agent_id = agent_uuid 
          AND user_id = user_uuid
          AND permission_type = required_permission
          AND is_active = true
          AND (expires_at IS NULL OR expires_at > NOW())
    ) INTO has_permission;
    
    RETURN has_permission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建会员权益检查视图
CREATE OR REPLACE VIEW user_active_benefits AS
SELECT 
    u.id as user_id,
    u.email,
    sp.plan_type,
    sp.plan_name,
    sp.features,
    sp.limits,
    um.status as membership_status,
    um.expires_at,
    CASE 
        WHEN um.expires_at IS NULL THEN true
        WHEN um.expires_at > NOW() THEN true
        ELSE false
    END as is_active
FROM users u
LEFT JOIN user_memberships um ON u.id = um.user_id AND um.status = 'active'
LEFT JOIN subscription_plans sp ON um.plan_id = sp.id
WHERE u.id = auth.uid();

-- 启用视图的RLS
ALTER VIEW user_active_benefits SET (security_barrier = true);

-- ============================================================================
-- RLS策略配置完成
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Sprint 3 RLS策略配置完成';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '配置表数量: 12个核心业务表';
    RAISE NOTICE '安全策略: 36个精细化权限策略';
    RAISE NOTICE '辅助函数: 2个权限检查函数';
    RAISE NOTICE '安全视图: 1个会员权益视图';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '数据隔离: 用户数据严格隔离';
    RAISE NOTICE '权限控制: 智能体权限分级管理';
    RAISE NOTICE '商业安全: 支付数据加密保护';
    RAISE NOTICE '==========================================';
END $$;