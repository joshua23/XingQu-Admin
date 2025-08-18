-- =============================================
-- 星趣APP数据埋点系统 - 部署步骤1: 现有表扩展
-- 创建时间: 2025-01-07
-- 版本: v2.1.0 (拆分版本)
-- 用途: 在Supabase Dashboard SQL Editor中执行
-- =============================================

-- 开始执行提示
DO $$ 
BEGIN
    RAISE NOTICE '🚀 开始执行步骤1: 现有表安全扩展...';
    RAISE NOTICE '📅 执行时间: %', NOW();
    RAISE NOTICE '⚠️  这是最安全的步骤，不会影响现有功能';
END $$;

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================
-- 扩展 interaction_logs 表
-- =============================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interaction_logs' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ 发现interaction_logs表，开始安全扩展...';
        
        -- 使用IF NOT EXISTS确保安全执行
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'session_id';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN session_id VARCHAR(255);
            RAISE NOTICE '  ✓ 添加session_id字段';
        ELSE
            RAISE NOTICE '  - session_id字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'event_properties';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN event_properties JSONB DEFAULT '{}';
            RAISE NOTICE '  ✓ 添加event_properties字段';
        ELSE
            RAISE NOTICE '  - event_properties字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'target_object_type';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN target_object_type VARCHAR(50);
            RAISE NOTICE '  ✓ 添加target_object_type字段';
        ELSE
            RAISE NOTICE '  - target_object_type字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'target_object_id';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN target_object_id UUID;
            RAISE NOTICE '  ✓ 添加target_object_id字段';
        ELSE
            RAISE NOTICE '  - target_object_id字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'page_context';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN page_context JSONB DEFAULT '{}';
            RAISE NOTICE '  ✓ 添加page_context字段';
        ELSE
            RAISE NOTICE '  - page_context字段已存在，跳过';
        END IF;
        
        PERFORM 1 FROM information_schema.columns WHERE table_name = 'interaction_logs' AND column_name = 'device_info';
        IF NOT FOUND THEN
            ALTER TABLE interaction_logs ADD COLUMN device_info JSONB DEFAULT '{}';
            RAISE NOTICE '  ✓ 添加device_info字段';
        ELSE
            RAISE NOTICE '  - device_info字段已存在，跳过';
        END IF;
        
    ELSE
        RAISE WARNING '❌ 未找到interaction_logs表，跳过扩展';
    END IF;
END $$;

-- =============================================
-- 为扩展字段创建索引
-- =============================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interaction_logs' AND table_schema = 'public') THEN
        -- 检查索引是否存在，不存在则创建
        PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_interaction_logs_session_id_enhanced';
        IF NOT FOUND THEN
            CREATE INDEX idx_interaction_logs_session_id_enhanced ON interaction_logs (session_id);
            RAISE NOTICE '  ✓ 创建session_id索引';
        ELSE
            RAISE NOTICE '  - session_id索引已存在，跳过';
        END IF;
        
        PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_interaction_logs_target_enhanced';
        IF NOT FOUND THEN
            CREATE INDEX idx_interaction_logs_target_enhanced ON interaction_logs (target_object_type, target_object_id);
            RAISE NOTICE '  ✓ 创建目标对象索引';
        ELSE
            RAISE NOTICE '  - 目标对象索引已存在，跳过';
        END IF;
        
        PERFORM 1 FROM pg_indexes WHERE indexname = 'idx_interaction_logs_properties_gin_enhanced';
        IF NOT FOUND THEN
            CREATE INDEX idx_interaction_logs_properties_gin_enhanced ON interaction_logs USING GIN (event_properties);
            RAISE NOTICE '  ✓ 创建属性GIN索引';
        ELSE
            RAISE NOTICE '  - 属性GIN索引已存在，跳过';
        END IF;
    END IF;
END $$;

-- =============================================
-- 创建向后兼容视图
-- =============================================

CREATE OR REPLACE VIEW interaction_logs_legacy AS
SELECT 
    id, 
    user_id, 
    interaction_type, 
    created_at
FROM interaction_logs;

-- =============================================
-- 完成检查
-- =============================================

DO $$
DECLARE
    new_columns_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO new_columns_count
    FROM information_schema.columns 
    WHERE table_name = 'interaction_logs' 
      AND column_name IN ('session_id', 'event_properties', 'target_object_type', 'target_object_id', 'page_context', 'device_info');
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 步骤1完成! 成功扩展interaction_logs表，新增%个字段', new_columns_count;
    RAISE NOTICE '✅ 现有功能完全不受影响，可以立即开始使用扩展的埋点功能';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 下一步：请执行 SCRIPT2_CORE_TABLES.sql';
END $$;