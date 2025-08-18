-- ============================================================================
-- 星趣App Sprint 2 数据迁移计划 (修复版)
-- 确保向后兼容性和数据一致性
-- ============================================================================

-- ============================================================================
-- 1. 迁移前准备和备份
-- ============================================================================

-- 创建迁移日志表
CREATE TABLE IF NOT EXISTS migration_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    migration_name VARCHAR(100) NOT NULL,
    migration_version VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    rollback_sql TEXT
);

-- 记录迁移开始
INSERT INTO migration_logs (migration_name, migration_version, status) 
VALUES ('Sprint 2 Feature Tables', '2.0.0', 'running');

-- ============================================================================
-- 2. 扩展现有表结构（保持向后兼容）
-- ============================================================================

-- 为现有用户表添加新字段（如果不存在）
DO $$ 
BEGIN
    -- 添加经验值字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'experience_points') THEN
        ALTER TABLE users ADD COLUMN experience_points INTEGER DEFAULT 0;
    END IF;
    
    -- 添加用户等级字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'user_level') THEN
        ALTER TABLE users ADD COLUMN user_level INTEGER DEFAULT 1;
    END IF;
    
    -- 添加用户偏好设置字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'preferences') THEN
        ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}';
    END IF;
END $$;

-- 为AI角色表添加新字段（如果不存在）
DO $$ 
BEGIN
    -- 添加角色标签字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'tags') THEN
        ALTER TABLE ai_characters ADD COLUMN tags TEXT[];
    END IF;
    
    -- 添加是否为专业智能体字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'is_professional_agent') THEN
        ALTER TABLE ai_characters ADD COLUMN is_professional_agent BOOLEAN DEFAULT false;
    END IF;
    
    -- 添加专业评分字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ai_characters' AND column_name = 'professional_rating') THEN
        ALTER TABLE ai_characters ADD COLUMN professional_rating DECIMAL(3,2) DEFAULT 0.0;
    END IF;
END $$;

-- ============================================================================
-- 3. 创建新表的安全迁移
-- ============================================================================

-- 检查并创建新表（避免重复创建）
DO $$ 
BEGIN
    -- 创建交互菜单配置表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'interaction_menu_configs') THEN
        CREATE TABLE interaction_menu_configs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            page_type VARCHAR(50) NOT NULL,
            menu_items JSONB NOT NULL,
            display_order INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
    
    -- 创建交互日志表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'interaction_logs') THEN
        CREATE TABLE interaction_logs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES users(id) ON DELETE CASCADE,
            page_type VARCHAR(50) NOT NULL,
            interaction_type VARCHAR(50) NOT NULL,
            target_type VARCHAR(50),
            target_id UUID,
            metadata JSONB,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
END $$;

-- ============================================================================
-- 4. 数据迁移和初始化
-- ============================================================================

-- 迁移现有character_follows数据到新的user_subscriptions表
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'character_follows') 
       AND EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'user_subscriptions') THEN
        
        INSERT INTO user_subscriptions (user_id, target_type, target_id, created_at)
        SELECT 
            user_id,
            'character' as target_type,
            character_id as target_id,
            created_at
        FROM character_follows cf
        WHERE NOT EXISTS (
            SELECT 1 FROM user_subscriptions us 
            WHERE us.user_id = cf.user_id 
            AND us.target_type = 'character' 
            AND us.target_id = cf.character_id
        );
    END IF;
END $$;

-- 为现有用户创建默认记忆分组
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'subscription_groups') THEN
        INSERT INTO subscription_groups (user_id, group_name, group_color, display_order)
        SELECT 
            id as user_id,
            '默认分组' as group_name,
            '#3B82F6' as group_color,
            0 as display_order
        FROM users u
        WHERE NOT EXISTS (
            SELECT 1 FROM subscription_groups sg 
            WHERE sg.user_id = u.id
        );
    END IF;
END $$;

-- ============================================================================
-- 5. 创建触发器和自动化函数
-- ============================================================================

-- 创建更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为新表添加更新时间戳触发器
DO $$ 
DECLARE
    tbl_name TEXT;
    tables_with_updated_at TEXT[] := ARRAY[
        'interaction_menu_configs',
        'user_subscriptions', 
        'recommendation_algorithms',
        'memory_items',
        'bilingual_contents',
        'user_bilingual_progress',
        'challenge_tasks',
        'user_challenge_participations',
        'ui_decorations',
        'system_configs'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY tables_with_updated_at
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = tbl_name) THEN
            EXECUTE format('
                DROP TRIGGER IF EXISTS update_%s_updated_at ON %s;
                CREATE TRIGGER update_%s_updated_at
                    BEFORE UPDATE ON %s
                    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
            ', tbl_name, tbl_name, tbl_name, tbl_name);
        END IF;
    END LOOP;
END $$;

-- ============================================================================
-- 6. 创建必要的索引
-- ============================================================================

-- 为新表创建性能优化索引
DO $$ 
BEGIN
    -- 交互日志索引
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'interaction_logs') THEN
        CREATE INDEX IF NOT EXISTS idx_interaction_logs_user_id ON interaction_logs(user_id);
        CREATE INDEX IF NOT EXISTS idx_interaction_logs_created_at ON interaction_logs(created_at);
        CREATE INDEX IF NOT EXISTS idx_interaction_logs_interaction_type ON interaction_logs(interaction_type);
    END IF;
    
    -- 用户订阅索引
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'user_subscriptions') THEN
        CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_subscriptions_target ON user_subscriptions(target_type, target_id);
    END IF;
    
    -- 推荐结果索引
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'user_recommendations') THEN
        CREATE INDEX IF NOT EXISTS idx_user_recommendations_user_id ON user_recommendations(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_recommendations_expires_at ON user_recommendations(expires_at);
    END IF;
    
    -- 记忆条目索引
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'memory_items') THEN
        CREATE INDEX IF NOT EXISTS idx_memory_items_user_id ON memory_items(user_id);
        CREATE INDEX IF NOT EXISTS idx_memory_items_type ON memory_items(memory_type_id);
        CREATE INDEX IF NOT EXISTS idx_memory_items_created_at ON memory_items(created_at DESC);
    END IF;
END $$;

-- ============================================================================
-- 7. 数据完整性检查
-- ============================================================================

-- 创建数据完整性检查函数
CREATE OR REPLACE FUNCTION check_data_integrity_sprint2()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    issue_count BIGINT,
    description TEXT
) AS $$
BEGIN
    -- 检查用户订阅数据完整性
    RETURN QUERY
    SELECT 
        'user_subscriptions_integrity'::TEXT as check_name,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status,
        COUNT(*) as issue_count,
        '检查用户订阅是否引用了有效的用户ID'::TEXT as description
    FROM user_subscriptions us
    LEFT JOIN users u ON us.user_id = u.id
    WHERE u.id IS NULL;
    
    -- 检查记忆条目数据完整性
    RETURN QUERY
    SELECT 
        'memory_items_integrity'::TEXT as check_name,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status,
        COUNT(*) as issue_count,
        '检查记忆条目是否引用了有效的用户ID'::TEXT as description
    FROM memory_items mi
    LEFT JOIN users u ON mi.user_id = u.id
    WHERE u.id IS NULL;
    
    -- 检查挑战参与记录完整性
    RETURN QUERY
    SELECT 
        'challenge_participations_integrity'::TEXT as check_name,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status,
        COUNT(*) as issue_count,
        '检查挑战参与记录的用户和挑战ID是否有效'::TEXT as description
    FROM user_challenge_participations ucp
    LEFT JOIN users u ON ucp.user_id = u.id
    LEFT JOIN challenge_tasks ct ON ucp.challenge_id = ct.id
    WHERE u.id IS NULL OR ct.id IS NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. 迁移完成和清理
-- ============================================================================

-- 更新迁移状态
UPDATE migration_logs 
SET status = 'completed', completed_at = NOW() 
WHERE migration_name = 'Sprint 2 Feature Tables' AND migration_version = '2.0.0';

-- 创建迁移回滚脚本（紧急情况使用）
CREATE OR REPLACE FUNCTION rollback_sprint2_migration()
RETURNS TEXT AS $$
DECLARE
    rollback_script TEXT := '';
BEGIN
    rollback_script := '
-- 紧急回滚脚本 - 仅在必要时使用
-- 注意：这将删除Sprint 2的所有新表和数据

DROP TABLE IF EXISTS ui_decorations CASCADE;
DROP TABLE IF EXISTS user_ui_preferences CASCADE;
DROP TABLE IF EXISTS data_cache CASCADE;
DROP TABLE IF EXISTS system_configs CASCADE;
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS user_challenge_participations CASCADE;  
DROP TABLE IF EXISTS challenge_tasks CASCADE;
DROP TABLE IF EXISTS challenge_types CASCADE;
DROP TABLE IF EXISTS user_bilingual_progress CASCADE;
DROP TABLE IF EXISTS bilingual_contents CASCADE;
DROP TABLE IF EXISTS memory_search_vectors CASCADE;
DROP TABLE IF EXISTS memory_items CASCADE;
DROP TABLE IF EXISTS memory_types CASCADE; 
DROP TABLE IF EXISTS ai_character_extensions CASCADE;
DROP TABLE IF EXISTS ai_agent_categories CASCADE;
DROP TABLE IF EXISTS user_recommendations CASCADE;
DROP TABLE IF EXISTS recommendation_algorithms CASCADE;
DROP TABLE IF EXISTS subscription_group_items CASCADE;
DROP TABLE IF EXISTS subscription_groups CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS interaction_logs CASCADE;
DROP TABLE IF EXISTS interaction_menu_configs CASCADE;

-- 移除新添加的列
ALTER TABLE users DROP COLUMN IF EXISTS experience_points;
ALTER TABLE users DROP COLUMN IF EXISTS user_level;
ALTER TABLE users DROP COLUMN IF EXISTS preferences;
ALTER TABLE ai_characters DROP COLUMN IF EXISTS tags;
ALTER TABLE ai_characters DROP COLUMN IF EXISTS is_professional_agent;
ALTER TABLE ai_characters DROP COLUMN IF EXISTS professional_rating;

-- 清理触发器
DROP TRIGGER IF EXISTS update_interaction_menu_configs_updated_at ON interaction_menu_configs;
-- ... 其他触发器清理

-- 清理函数
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS check_data_integrity_sprint2() CASCADE;
DROP FUNCTION IF EXISTS rollback_sprint2_migration() CASCADE;
    ';
    
    RETURN rollback_script;
END;
$$ LANGUAGE plpgsql;

-- 记录迁移完成
INSERT INTO migration_logs (migration_name, migration_version, status, completed_at) 
VALUES ('Sprint 2 Migration Completed', '2.0.0', 'completed', NOW());