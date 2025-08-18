-- ============================================================================
-- Sprint 3 订阅套餐API测试脚本
-- 验证订阅相关的所有API端点功能
-- ============================================================================

-- 测试1: 获取所有可用订阅套餐
SELECT 
    'TEST 1: 获取可用订阅套餐' as test_name,
    COUNT(*) as plan_count,
    COUNT(*) FILTER (WHERE is_active = true) as active_plans,
    COUNT(*) FILTER (WHERE is_recommended = true) as recommended_plans
FROM subscription_plans;

-- 预期结果: 应该有4个套餐，全部active，1个recommended

-- 测试2: 验证套餐数据完整性
SELECT 
    'TEST 2: 套餐数据完整性检查' as test_name,
    plan_code,
    plan_name,
    plan_type,
    price_cents,
    CASE 
        WHEN features IS NOT NULL AND jsonb_typeof(features) = 'object' THEN '✓'
        ELSE '✗'
    END as features_valid,
    CASE 
        WHEN limits IS NOT NULL AND jsonb_typeof(limits) = 'object' THEN '✓'
        ELSE '✗'
    END as limits_valid
FROM subscription_plans
ORDER BY display_order;

-- 测试3: 验证价格计算逻辑
SELECT 
    'TEST 3: 价格计算验证' as test_name,
    plan_code,
    price_cents,
    original_price_cents,
    CASE 
        WHEN original_price_cents IS NULL THEN '无折扣'
        ELSE ROUND((original_price_cents - price_cents)::DECIMAL / original_price_cents * 100, 1)::TEXT || '%折扣'
    END as discount_rate
FROM subscription_plans
WHERE is_active = true;

-- 测试4: 模拟创建用户会员状态
DO $$
DECLARE
    test_user_id UUID;
    basic_plan_id UUID;  
    test_membership_id UUID;
BEGIN
    -- 创建测试用户（如果不存在）
    INSERT INTO users (phone, nickname, avatar_url) 
    VALUES ('13800000001', 'API测试用户', 'https://example.com/avatar.png')
    ON CONFLICT (phone) DO NOTHING
    RETURNING id INTO test_user_id;
    
    -- 如果用户已存在，获取其ID
    IF test_user_id IS NULL THEN
        SELECT id INTO test_user_id FROM users WHERE phone = '13800000001';
    END IF;
    
    -- 获取基础套餐ID
    SELECT id INTO basic_plan_id FROM subscription_plans WHERE plan_code = 'basic_monthly';
    
    -- 清理现有会员状态
    DELETE FROM user_memberships WHERE user_id = test_user_id;
    
    -- 创建测试会员状态
    INSERT INTO user_memberships (
        user_id, 
        plan_id, 
        status, 
        started_at, 
        expires_at,
        usage_stats
    ) VALUES (
        test_user_id,
        basic_plan_id,
        'active',
        NOW(),
        NOW() + INTERVAL '30 days',
        '{"ai_chat_used": 50, "storage_used_mb": 200}'::jsonb
    ) RETURNING id INTO test_membership_id;
    
    RAISE NOTICE 'TEST 4: 创建会员状态成功 - 用户ID: %, 会员ID: %', test_user_id, test_membership_id;
END $$;

-- 测试5: 查询用户会员状态API
SELECT 
    'TEST 5: 用户会员状态查询' as test_name,
    u.nickname,
    sp.plan_name,
    sp.plan_type,
    um.status,
    um.started_at,
    um.expires_at,
    CASE 
        WHEN um.expires_at > NOW() THEN '有效'
        ELSE '已过期'
    END as validity_status,
    um.usage_stats
FROM users u
JOIN user_memberships um ON u.id = um.user_id
JOIN subscription_plans sp ON um.plan_id = sp.id
WHERE u.phone = '13800000001'
  AND um.status = 'active';

-- 测试6: 会员权益查询API
SELECT 
    'TEST 6: 会员权益查询' as test_name,
    mb.benefit_name,
    mb.benefit_category,
    CASE 
        WHEN 'basic' = ANY(mb.applicable_plans) THEN '✓可用'
        ELSE '✗不可用'
    END as basic_member_access,
    mb.limit_config
FROM membership_benefits mb
WHERE mb.is_active = true
ORDER BY mb.display_order;

-- 测试7: 创建支付订单API
DO $$
DECLARE
    test_user_id UUID;
    premium_plan_id UUID;
    test_order_id UUID;
    order_number TEXT;
BEGIN
    -- 获取测试用户和套餐
    SELECT id INTO test_user_id FROM users WHERE phone = '13800000001';
    SELECT id INTO premium_plan_id FROM subscription_plans WHERE plan_code = 'premium_yearly';
    
    -- 生成订单号
    SELECT generate_order_number() INTO order_number;
    
    -- 创建支付订单
    INSERT INTO payment_orders (
        order_number,
        user_id,
        plan_id,
        status,
        amount_cents,
        discount_cents,
        final_amount_cents,
        currency,
        expires_at,
        metadata
    ) VALUES (
        order_number,
        test_user_id,
        premium_plan_id,
        'pending',
        24000,
        0,
        24000,
        'CNY',
        NOW() + INTERVAL '30 minutes',
        '{"source": "api_test", "payment_method": "alipay"}'::jsonb
    ) RETURNING id INTO test_order_id;
    
    RAISE NOTICE 'TEST 7: 创建支付订单成功 - 订单号: %, 订单ID: %', order_number, test_order_id;
END $$;

-- 测试8: 查询支付订单API
SELECT 
    'TEST 8: 支付订单查询' as test_name,
    po.order_number,
    u.nickname as user_name,
    sp.plan_name,
    po.status,
    po.amount_cents / 100.0 as amount_yuan,
    po.final_amount_cents / 100.0 as final_amount_yuan,
    po.expires_at,
    CASE 
        WHEN po.expires_at > NOW() THEN '有效'
        ELSE '已过期'
    END as order_validity,
    po.metadata
FROM payment_orders po
JOIN users u ON po.user_id = u.id
JOIN subscription_plans sp ON po.plan_id = sp.id
WHERE u.phone = '13800000001'
ORDER BY po.created_at DESC
LIMIT 1;

-- 测试9: 模拟支付成功回调
DO $$
DECLARE
    test_order_id UUID;
BEGIN
    -- 获取刚创建的订单
    SELECT po.id INTO test_order_id 
    FROM payment_orders po
    JOIN users u ON po.user_id = u.id
    WHERE u.phone = '13800000001'
      AND po.status = 'pending'
    ORDER BY po.created_at DESC
    LIMIT 1;
    
    -- 模拟支付成功
    UPDATE payment_orders 
    SET 
        status = 'paid',
        paid_at = NOW(),
        payment_method = 'alipay',
        payment_provider = 'alipay',
        provider_transaction_id = 'alipay_' || EXTRACT(EPOCH FROM NOW())::TEXT,
        updated_at = NOW()
    WHERE id = test_order_id;
    
    RAISE NOTICE 'TEST 9: 模拟支付成功 - 订单ID: %', test_order_id;
END $$;

-- 测试10: 验证支付成功后会员状态自动更新
SELECT 
    'TEST 10: 支付后会员状态验证' as test_name,
    u.nickname,
    COUNT(um.*) as membership_count,
    STRING_AGG(sp.plan_name || '(' || um.status || ')', ', ') as memberships
FROM users u
LEFT JOIN user_memberships um ON u.id = um.user_id
LEFT JOIN subscription_plans sp ON um.plan_id = sp.id
WHERE u.phone = '13800000001'
GROUP BY u.id, u.nickname;

-- 测试11: API性能测试 - 批量查询
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    sp.plan_name,
    sp.price_cents,
    sp.features,
    COUNT(um.id) as subscriber_count
FROM subscription_plans sp
LEFT JOIN user_memberships um ON sp.id = um.plan_id AND um.status = 'active'
WHERE sp.is_active = true
GROUP BY sp.id, sp.plan_name, sp.price_cents, sp.features
ORDER BY sp.display_order;

-- 测试12: 清理测试数据
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- 获取测试用户ID
    SELECT id INTO test_user_id FROM users WHERE phone = '13800000001';
    
    -- 清理支付订单
    DELETE FROM payment_orders WHERE user_id = test_user_id;
    
    -- 清理会员状态
    DELETE FROM user_memberships WHERE user_id = test_user_id;
    
    -- 清理测试用户
    DELETE FROM users WHERE phone = '13800000001';
    
    RAISE NOTICE 'TEST 12: 测试数据清理完成';
END $$;

-- ============================================================================
-- 订阅API测试总结
-- ============================================================================
SELECT 
    'API测试总结' as summary,
    'subscription_plans表' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE is_active = true) as active_records
FROM subscription_plans

UNION ALL

SELECT 
    'API测试总结' as summary,
    'membership_benefits表' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE is_active = true) as active_records
FROM membership_benefits;