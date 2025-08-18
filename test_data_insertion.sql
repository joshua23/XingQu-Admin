-- =============================================
-- 测试修复后的数据插入功能
-- 验证user_analytics表是否可以正常写入埋点数据
-- =============================================

-- 第一步：检查表结构是否完整
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_analytics' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 第二步：测试数据插入（使用现有用户）
DO $$
DECLARE
    test_user_id UUID;
    test_success BOOLEAN := false;
    error_msg TEXT;
BEGIN
    -- 获取一个现有用户ID进行测试
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE '⚠️  未找到测试用户，创建匿名用户进行测试';
        -- 如果没有用户，创建一个测试用户
        INSERT INTO users (id, email, created_at) 
        VALUES (gen_random_uuid(), 'test@example.com', NOW())
        RETURNING id INTO test_user_id;
    END IF;
    
    RAISE NOTICE '🧪 开始测试数据插入，测试用户ID: %', test_user_id;
    
    -- 尝试插入完整的埋点数据（包含所有新字段）
    BEGIN
        INSERT INTO user_analytics (
            user_id, 
            event_type, 
            event_data, 
            session_id,
            page_name,
            device_info,
            target_object_type,
            target_object_id,
            created_at,
            updated_at
        ) VALUES (
            test_user_id,
            'test_featured_page_like',
            '{"source": "featured_page", "action": "like", "character_name": "寂文泽"}',
            'test_session_' || extract(epoch from now()),
            'home_selection_page',
            '{"platform": "ios", "device_model": "iPhone 15", "app_version": "1.0.0"}',
            'character',
            gen_random_uuid(),
            NOW(),
            NOW()
        );
        
        test_success := true;
        RAISE NOTICE '✅ 完整埋点数据插入测试成功！';
        
    EXCEPTION WHEN OTHERS THEN
        test_success := false;
        error_msg := SQLERRM;
        RAISE NOTICE '❌ 完整数据插入失败: %', error_msg;
    END;
    
    -- 如果完整插入失败，尝试基础字段插入
    IF NOT test_success THEN
        BEGIN
            INSERT INTO user_analytics (
                user_id, 
                event_type, 
                event_data, 
                session_id,
                created_at
            ) VALUES (
                test_user_id,
                'test_basic_event',
                '{"source": "test", "type": "basic"}',
                'basic_test_session',
                NOW()
            );
            
            RAISE NOTICE '✅ 基础埋点数据插入成功';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ 基础数据插入也失败: %', SQLERRM;
        END;
    END IF;
    
    -- 验证数据是否成功写入
    DECLARE
        record_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO record_count 
        FROM user_analytics 
        WHERE user_id = test_user_id 
        AND event_type LIKE 'test_%';
        
        RAISE NOTICE '📊 测试数据记录数: %', record_count;
        
        -- 显示插入的测试数据
        IF record_count > 0 THEN
            RAISE NOTICE '📝 测试数据详情:';
            -- 注意：由于RAISE NOTICE的限制，这里不能直接查询显示
            -- 请在Supabase控制台手动执行查询查看详情
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 无法查询测试数据: %', SQLERRM;
    END;
    
    -- 清理测试数据
    BEGIN
        DELETE FROM user_analytics 
        WHERE user_id = test_user_id 
        AND event_type LIKE 'test_%';
        
        RAISE NOTICE '🧹 测试数据清理完成';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  测试数据清理失败，请手动清理';
    END;
    
END $$;

-- 第三步：测试Flutter应用实际使用的数据格式
-- 模拟首页-精选页的点赞埋点数据
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '🎯 测试Flutter应用实际埋点格式...';
        
        -- 模拟trackSocialInteraction方法的数据格式
        INSERT INTO user_analytics (
            user_id,
            event_type,
            event_data,
            session_id
        ) VALUES (
            test_user_id,
            'social_interaction',
            jsonb_build_object(
                'actionType', 'like',
                'targetType', 'character',
                'targetId', gen_random_uuid(),
                'additionalData', jsonb_build_object(
                    'character_name', '寂文泽',
                    'source', 'featured_page'
                ),
                'timestamp', NOW()
            ),
            'flutter_session_' || extract(epoch from now())
        );
        
        RAISE NOTICE '✅ Flutter格式埋点数据插入成功';
        
        -- 立即清理
        DELETE FROM user_analytics 
        WHERE user_id = test_user_id 
        AND event_type = 'social_interaction'
        AND (event_data->>'actionType') = 'like';
        
        RAISE NOTICE '🧹 Flutter测试数据已清理';
    END IF;
END $$;

-- 输出测试总结
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 数据插入功能验证完成！';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 如果上述所有测试都显示成功，说明：';
    RAISE NOTICE '  1. user_analytics表结构已修复';
    RAISE NOTICE '  2. 数据插入功能正常';
    RAISE NOTICE '  3. Flutter埋点数据格式兼容';
    RAISE NOTICE '';
    RAISE NOTICE '📱 下一步请在Flutter应用中触发首页-精选页交互';
    RAISE NOTICE '   然后检查后台管理系统是否显示实时数据';
END $$;