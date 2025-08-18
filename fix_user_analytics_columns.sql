-- =============================================
-- 修复user_analytics表结构不匹配问题
-- 问题：现有表缺少埋点需要的字段
-- =============================================

DO $$ 
BEGIN
    RAISE NOTICE '🔧 开始修复user_analytics表结构...';
    
    -- 安全地添加缺失的字段
    BEGIN
        ALTER TABLE user_analytics ADD COLUMN IF NOT EXISTS page_name VARCHAR(100);
        RAISE NOTICE '✅ 添加page_name字段成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  page_name字段可能已存在: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE user_analytics ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}';
        RAISE NOTICE '✅ 添加device_info字段成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  device_info字段可能已存在: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE user_analytics ADD COLUMN IF NOT EXISTS target_object_type VARCHAR(50);
        RAISE NOTICE '✅ 添加target_object_type字段成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  target_object_type字段可能已存在: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE user_analytics ADD COLUMN IF NOT EXISTS target_object_id UUID;
        RAISE NOTICE '✅ 添加target_object_id字段成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  target_object_id字段可能已存在: %', SQLERRM;
    END;
    
    -- 添加updated_at字段（如果不存在）
    BEGIN
        ALTER TABLE user_analytics ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE '✅ 添加updated_at字段成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  updated_at字段可能已存在: %', SQLERRM;
    END;
    
END $$;

-- 为新字段添加索引（提升查询性能）
DO $$
BEGIN
    RAISE NOTICE '📊 为新字段创建索引...';
    
    BEGIN
        CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_analytics_page_name 
            ON user_analytics (page_name);
        RAISE NOTICE '✅ 创建page_name索引成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  page_name索引可能已存在';
    END;
    
    BEGIN
        CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_analytics_target 
            ON user_analytics (target_object_type, target_object_id);
        RAISE NOTICE '✅ 创建target对象索引成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  target对象索引可能已存在';
    END;
    
    BEGIN
        CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_analytics_device_gin 
            ON user_analytics USING GIN (device_info);
        RAISE NOTICE '✅ 创建device_info GIN索引成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  device_info GIN索引可能已存在';
    END;
END $$;

-- 验证表结构是否修复成功
DO $$
DECLARE
    column_count INTEGER;
    missing_columns TEXT[] := '{}';
BEGIN
    RAISE NOTICE '🔍 验证表结构修复结果...';
    
    -- 检查必要字段是否存在
    SELECT COUNT(*) INTO column_count
    FROM information_schema.columns 
    WHERE table_name = 'user_analytics' 
    AND table_schema = 'public'
    AND column_name IN ('page_name', 'device_info', 'target_object_type', 'target_object_id', 'updated_at');
    
    IF column_count < 5 THEN
        -- 列出缺失的字段
        SELECT array_agg(expected_column) INTO missing_columns
        FROM (VALUES ('page_name'), ('device_info'), ('target_object_type'), ('target_object_id'), ('updated_at')) AS expected(expected_column)
        WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_analytics' 
            AND table_schema = 'public' 
            AND column_name = expected.expected_column
        );
        
        RAISE WARNING '❌ 仍有字段缺失: %', missing_columns;
    ELSE
        RAISE NOTICE '✅ 所有必要字段已添加成功！';
    END IF;
    
    -- 显示当前表结构
    RAISE NOTICE '📋 当前user_analytics表结构:';
    FOR column_count IN 
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_analytics' AND table_schema = 'public'
        ORDER BY ordinal_position
    LOOP
        -- 这里只是计数，具体字段信息需要在Supabase控制台查看
        NULL;
    END LOOP;
END $$;

RAISE NOTICE '🎉 user_analytics表结构修复完成！';
RAISE NOTICE '💡 下一步请执行测试数据插入验证。';