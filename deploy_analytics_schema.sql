-- =============================================
-- 星趣APP数据埋点分析系统 - 部署脚本
-- 执行前请备份数据库
-- 建议在非高峰时段执行
-- =============================================

-- 检查现有表，避免重复创建
DO $$ 
BEGIN
    -- 检查是否已存在分析系统表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_events') THEN
        RAISE NOTICE '检测到user_events表已存在，跳过创建...';
    ELSE
        RAISE NOTICE '开始创建数据埋点分析系统...';
    END IF;
END $$;

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- 检查auth.users表是否存在
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        RAISE EXCEPTION 'auth.users表不存在，请确认Supabase Auth已启用';
    END IF;
END $$;

-- 检查stories表是否存在（如果不存在则创建引用为可选）
CREATE TABLE IF NOT EXISTS stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 执行完整的分析系统schema
\i supabase/migrations/20250107_analytics_schema.sql

-- 验证表创建成功
DO $$ 
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_name IN ('user_events', 'user_sessions', 'user_attributes', 'daily_metrics', 'realtime_metrics', 'funnel_analysis', 'user_segments');
    
    IF table_count = 7 THEN
        RAISE NOTICE '✅ 分析系统部署成功！已创建7个核心表';
    ELSE
        RAISE WARNING '❌ 部署可能存在问题，仅创建了%个表', table_count;
    END IF;
END $$;

-- 插入测试数据以验证系统运行
INSERT INTO user_events (user_id, session_id, event_name, event_category, properties) 
VALUES (
    (SELECT id FROM auth.users LIMIT 1), 
    'test_session_001', 
    'system_health_check', 
    'system', 
    '{"deploy_time": "2025-01-07", "version": "v1.0.0"}'
) ON CONFLICT DO NOTHING;

RAISE NOTICE '🎉 数据埋点分析系统部署完成！';
RAISE NOTICE '📊 可开始使用实时分析和运营看板功能';