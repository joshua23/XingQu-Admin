-- ============================================================================
-- 星趣App Sprint 2 完整部署脚本 (经过全面检查和修复)
-- 在Supabase SQL Editor中一次性执行
-- ============================================================================

-- ============================================================================
-- 第一部分: 迁移计划和准备工作
-- ============================================================================

-- 创建迁移日志表
CREATE TABLE IF NOT EXISTS migration_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    migration_name VARCHAR(100) NOT NULL,
    migration_version VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    rollback_sql TEXT
);

-- 记录迁移开始
INSERT INTO migration_logs (migration_name, migration_version, status) 
VALUES ('Sprint 2 Complete Deployment', '2.0.1', 'running');

-- 扩展现有用户表（如果不存在）
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'experience_points') THEN
        ALTER TABLE users ADD COLUMN experience_points INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'user_level') THEN
        ALTER TABLE users ADD COLUMN user_level INTEGER DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'preferences') THEN
        ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}';
    END IF;
END $$;

-- ============================================================================
-- 第二部分: 创建所有新表
-- ============================================================================

-- 1. 交互菜单配置表
CREATE TABLE IF NOT EXISTS interaction_menu_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_type VARCHAR(50) NOT NULL,
    menu_items JSONB NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 用户交互行为日志表
CREATE TABLE IF NOT EXISTS interaction_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    page_type VARCHAR(50) NOT NULL,
    interaction_type VARCHAR(50) NOT NULL,
    target_type VARCHAR(50),
    target_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 用户订阅关系表
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
    subscription_type VARCHAR(20) DEFAULT 'standard',
    tags TEXT[],
    priority INTEGER DEFAULT 0,
    notifications_enabled BOOLEAN DEFAULT true,
    last_accessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 订阅分组表
CREATE TABLE IF NOT EXISTS subscription_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    group_name VARCHAR(100) NOT NULL,
    group_color VARCHAR(7),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 订阅分组关系表
CREATE TABLE IF NOT EXISTS subscription_group_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES subscription_groups(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, subscription_id)
);

-- 6. 推荐算法配置表
CREATE TABLE IF NOT EXISTS recommendation_algorithms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    algorithm_name VARCHAR(100) NOT NULL,
    algorithm_type VARCHAR(50) NOT NULL,
    config_params JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. 用户推荐结果缓存表
CREATE TABLE IF NOT EXISTS user_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL,
    recommended_items JSONB NOT NULL,
    algorithm_version VARCHAR(20),
    confidence_score DECIMAL(5,4),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. 智能体分类表
CREATE TABLE IF NOT EXISTS ai_agent_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) NOT NULL,
    category_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. AI角色扩展属性表
CREATE TABLE IF NOT EXISTS ai_character_extensions (
    character_id UUID PRIMARY KEY,
    agent_category_id UUID REFERENCES ai_agent_categories(id),
    professional_skills TEXT[],
    service_types TEXT[],
    expertise_level INTEGER DEFAULT 1,
    usage_statistics JSONB,
    performance_metrics JSONB,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. 记忆类型配置表
CREATE TABLE IF NOT EXISTS memory_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    icon_name VARCHAR(50),
    color_hex VARCHAR(7),
    description TEXT,
    is_system BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. 用户记忆条目表
CREATE TABLE IF NOT EXISTS memory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    memory_type_id UUID REFERENCES memory_types(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    tags TEXT[],
    related_character_id UUID,
    related_conversation_id UUID,
    metadata JSONB,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. 记忆搜索向量表
CREATE TABLE IF NOT EXISTS memory_search_vectors (
    memory_id UUID PRIMARY KEY REFERENCES memory_items(id) ON DELETE CASCADE,
    search_vector TSVECTOR,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. 双语内容表
CREATE TABLE IF NOT EXISTS bilingual_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(50) NOT NULL,
    primary_language VARCHAR(10) NOT NULL,
    secondary_language VARCHAR(10) NOT NULL,
    primary_text TEXT NOT NULL,
    secondary_text TEXT NOT NULL,
    difficulty_level VARCHAR(20),
    category VARCHAR(50),
    audio_url TEXT,
    phonetic_notation TEXT,
    usage_example TEXT,
    tags TEXT[],
    is_public BOOLEAN DEFAULT true,
    creator_id UUID REFERENCES users(id),
    like_count INTEGER DEFAULT 0,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. 用户双语学习进度表
CREATE TABLE IF NOT EXISTS user_bilingual_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID REFERENCES bilingual_contents(id) ON DELETE CASCADE,
    mastery_level INTEGER DEFAULT 0,
    practice_count INTEGER DEFAULT 0,
    last_practiced_at TIMESTAMPTZ,
    is_favorite BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, content_id)
);

-- 15. 挑战任务类型表
CREATE TABLE IF NOT EXISTS challenge_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50),
    color_hex VARCHAR(7),
    default_duration_days INTEGER DEFAULT 7,
    max_participants INTEGER,
    reward_config JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. 挑战任务表
CREATE TABLE IF NOT EXISTS challenge_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_type_id UUID REFERENCES challenge_types(id),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    requirements JSONB NOT NULL,
    rewards JSONB,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    difficulty_level INTEGER DEFAULT 1,
    is_featured BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'active',
    creator_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. 用户挑战参与记录表
CREATE TABLE IF NOT EXISTS user_challenge_participations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES challenge_tasks(id) ON DELETE CASCADE,
    progress_data JSONB,
    completion_percentage INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    rewards_claimed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

-- 18. 用户成就表
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url TEXT,
    points_awarded INTEGER DEFAULT 0,
    badge_level VARCHAR(20),
    metadata JSONB,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    is_featured BOOLEAN DEFAULT false
);

-- 19. UI装饰元素配置表
CREATE TABLE IF NOT EXISTS ui_decorations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decoration_type VARCHAR(50) NOT NULL,
    element_name VARCHAR(100) NOT NULL,
    config_data JSONB NOT NULL,
    target_pages TEXT[],
    is_active BOOLEAN DEFAULT true,
    display_conditions JSONB,
    animation_config JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. 用户UI偏好设置表
CREATE TABLE IF NOT EXISTS user_ui_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    theme_preference VARCHAR(20) DEFAULT 'dark',
    animation_enabled BOOLEAN DEFAULT true,
    particle_effects_enabled BOOLEAN DEFAULT true,
    accessibility_mode BOOLEAN DEFAULT false,
    custom_decorations JSONB,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 21. 系统配置表
CREATE TABLE IF NOT EXISTS system_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 22. 数据缓存表
CREATE TABLE IF NOT EXISTS data_cache (
    cache_key VARCHAR(200) PRIMARY KEY,
    cache_data JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 第三部分: 创建索引
-- ============================================================================

-- 交互日志索引
CREATE INDEX IF NOT EXISTS idx_interaction_logs_user_id ON interaction_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_interaction_logs_created_at ON interaction_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_interaction_logs_interaction_type ON interaction_logs(interaction_type);

-- 用户订阅索引
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_target ON user_subscriptions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_subscription_groups_user_id ON subscription_groups(user_id);

-- 推荐系统索引
CREATE INDEX IF NOT EXISTS idx_user_recommendations_user_id ON user_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_recommendations_expires_at ON user_recommendations(expires_at);
CREATE INDEX IF NOT EXISTS idx_ai_character_extensions_category ON ai_character_extensions(agent_category_id);

-- 记忆系统索引
CREATE INDEX IF NOT EXISTS idx_memory_search_vectors ON memory_search_vectors USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_memory_items_user_id ON memory_items(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_items_type ON memory_items(memory_type_id);
CREATE INDEX IF NOT EXISTS idx_memory_items_created_at ON memory_items(created_at DESC);

-- 双语学习索引
CREATE INDEX IF NOT EXISTS idx_bilingual_contents_languages ON bilingual_contents(primary_language, secondary_language);
CREATE INDEX IF NOT EXISTS idx_bilingual_contents_difficulty ON bilingual_contents(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_user_bilingual_progress_user_id ON user_bilingual_progress(user_id);

-- 挑战系统索引
CREATE INDEX IF NOT EXISTS idx_challenge_tasks_status ON challenge_tasks(status);
CREATE INDEX IF NOT EXISTS idx_challenge_tasks_dates ON challenge_tasks(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_user_challenge_participations_user_id ON user_challenge_participations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_challenge_participations_status ON user_challenge_participations(status);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);

-- UI系统索引
CREATE INDEX IF NOT EXISTS idx_ui_decorations_type ON ui_decorations(decoration_type);
CREATE INDEX IF NOT EXISTS idx_ui_decorations_active ON ui_decorations(is_active);

-- 缓存索引
CREATE INDEX IF NOT EXISTS idx_data_cache_expires_at ON data_cache(expires_at);

-- ============================================================================
-- 第四部分: 插入初始化数据
-- ============================================================================

-- 插入记忆类型初始数据
INSERT INTO memory_types (type_name, display_name, icon_name, color_hex, description, is_system, display_order) VALUES
('work_record', '工作记录', 'work', '#3B82F6', '工作相关的记录和笔记', true, 1),
('study_notes', '学习笔记', 'school', '#10B981', '学习过程中的重要笔记', true, 2),
('life_record', '生活记录', 'home', '#F59E0B', '日常生活的记录和感悟', true, 3),
('inspiration', '灵感收集', 'lightbulb', '#8B5CF6', '创意灵感和想法收集', true, 4),
('reading_notes', '阅读摘录', 'book', '#EF4444', '阅读过程中的精彩摘录', true, 5),
('meeting_notes', '会议纪要', 'meeting_room', '#14B8A6', '会议记录和要点', true, 6),
('project_plan', '项目规划', 'assignment', '#6366F1', '项目计划和管理', true, 7),
('personal_diary', '个人日记', 'edit', '#EC4899', '个人心情和日记', true, 8)
ON CONFLICT (type_name) DO NOTHING;

-- 插入AI智能体分类初始数据
INSERT INTO ai_agent_categories (category_name, category_code, description, display_order) VALUES
('编程助手', 'programming', '专业的编程和技术开发助手', 1),
('写作助手', 'writing', '文章创作和内容写作助手', 2),
('学习导师', 'education', '各学科的学习指导助手', 3),
('商务顾问', 'business', '商业咨询和策略建议助手', 4),
('创意设计', 'design', '设计创意和视觉艺术助手', 5),
('生活助理', 'lifestyle', '日常生活管理和建议助手', 6)
ON CONFLICT (category_code) DO NOTHING;

-- 插入挑战类型初始数据
INSERT INTO challenge_types (type_name, display_name, description, icon_name, color_hex, default_duration_days) VALUES
('vocabulary', '每日词汇挑战', '提升语言词汇量的每日挑战', 'vocabulary', '#3B82F6', 7),
('coding', '编程练习挑战', '提升编程技能的算法挑战', 'code', '#10B981', 14),
('writing', '创意写作挑战', '激发创意写作能力的挑战', 'edit', '#8B5CF6', 7),
('fitness', '健康生活挑战', '养成健康生活习惯的挑战', 'fitness', '#EF4444', 30)
ON CONFLICT (type_name) DO NOTHING;

-- 插入交互菜单配置初始数据
INSERT INTO interaction_menu_configs (page_type, menu_items, display_order, is_active) VALUES
('ai_interaction', '[
    {"type": "reload", "icon": "refresh", "label": "重新加载"},
    {"type": "voice_call", "icon": "call", "label": "语音通话"},
    {"type": "image", "icon": "image", "label": "图片"},
    {"type": "camera", "icon": "camera_alt", "label": "相机"},
    {"type": "gift", "icon": "card_giftcard", "label": "礼物"},
    {"type": "share", "icon": "share", "label": "分享"}
]', 1, true),
('grid_recommendation', '[
    {"type": "reload", "icon": "refresh", "label": "刷新"},
    {"type": "image", "icon": "image", "label": "图片"},
    {"type": "link", "icon": "link", "label": "链接"},
    {"type": "share", "icon": "share", "label": "分享"},
    {"type": "file", "icon": "folder", "label": "文件"},
    {"type": "report", "icon": "flag", "label": "举报"}
]', 2, true)
ON CONFLICT DO NOTHING;

-- 插入UI装饰配置初始数据
INSERT INTO ui_decorations (decoration_type, element_name, config_data, target_pages, is_active) VALUES
('star_animation', '星形旋转动效', '{"size": 16, "color": "#FFC542", "duration": "3s", "rotation": true, "pulse": true}', ARRAY['home_selection', 'home_fm'], true),
('particle_effect', '星形粒子效果', '{"particle_count": 8, "duration": "3s", "colors": ["#FFC542", "#F5DFAF"], "spawn_rate": 0.5}', ARRAY['home_selection'], true),
('brand_element', '品牌星形装饰', '{"type": "decoration", "size": 12, "color": "#FFC542", "glow": true}', ARRAY['all'], true)
ON CONFLICT DO NOTHING;

-- 插入系统配置初始数据
INSERT INTO system_configs (config_key, config_value, description, is_public) VALUES
('recommendation_refresh_interval', '{"hours": 6}', '推荐内容刷新间隔', false),
('challenge_max_participants', '{"default": 1000}', '挑战任务最大参与人数', false),
('ui_animation_settings', '{"enable_particles": true, "enable_star_effects": true}', 'UI动画设置', true),
('memory_search_config', '{"max_results": 50, "highlight_keywords": true}', '记忆搜索配置', false)
ON CONFLICT (config_key) DO NOTHING;

-- ============================================================================
-- 第五部分: 创建触发器和函数
-- ============================================================================

-- 创建更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为有updated_at字段的表创建触发器
DO $$ 
DECLARE
    tbl_name TEXT;
    tables_with_updated_at TEXT[] := ARRAY[
        'interaction_menu_configs',
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
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%s_updated_at ON %s;
            CREATE TRIGGER update_%s_updated_at
                BEFORE UPDATE ON %s
                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        ', tbl_name, tbl_name, tbl_name, tbl_name);
    END LOOP;
END $$;

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
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 第六部分: 启用RLS安全策略
-- ============================================================================

-- 为需要RLS保护的表启用RLS
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

-- 基础RLS策略（用户只能访问自己的数据）
CREATE POLICY "Users can manage their own interaction logs" ON interaction_logs
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own subscriptions" ON user_subscriptions
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own subscription groups" ON subscription_groups
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own memory items" ON memory_items
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own bilingual progress" ON user_bilingual_progress
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own challenge participations" ON user_challenge_participations
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own achievements" ON user_achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own UI preferences" ON user_ui_preferences
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 公共数据访问策略
CREATE POLICY "Authenticated users can view public configs" ON interaction_menu_configs
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

CREATE POLICY "Authenticated users can view memory types" ON memory_types
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view ai agent categories" ON ai_agent_categories
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

CREATE POLICY "Authenticated users can view challenge types" ON challenge_types
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can view public bilingual contents" ON bilingual_contents
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view active challenges" ON challenge_tasks
    FOR SELECT USING (status = 'active');

CREATE POLICY "Authenticated users can view public system configs" ON system_configs
    FOR SELECT USING (auth.role() = 'authenticated' AND is_public = true);

-- ============================================================================
-- 第七部分: 完成部署和验证
-- ============================================================================

-- 更新迁移状态
UPDATE migration_logs 
SET status = 'completed', completed_at = NOW() 
WHERE migration_name = 'Sprint 2 Complete Deployment' AND migration_version = '2.0.1';

-- 验证部署结果
SELECT 
    '🎉 Sprint 2数据库部署完成！' as message,
    COUNT(*) as new_tables_created
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'interaction_menu_configs', 'interaction_logs', 'user_subscriptions',
    'subscription_groups', 'subscription_group_items', 'recommendation_algorithms',
    'user_recommendations', 'ai_agent_categories', 'ai_character_extensions',
    'memory_types', 'memory_items', 'memory_search_vectors',
    'bilingual_contents', 'user_bilingual_progress', 'challenge_types',
    'challenge_tasks', 'user_challenge_participations', 'user_achievements',
    'ui_decorations', 'user_ui_preferences', 'system_configs', 'data_cache'
  );

-- 验证初始数据
SELECT 'Initial Data Check' as check_type,
       'memory_types: ' || (SELECT COUNT(*) FROM memory_types) ||
       ', ai_agent_categories: ' || (SELECT COUNT(*) FROM ai_agent_categories) ||
       ', challenge_types: ' || (SELECT COUNT(*) FROM challenge_types) ||
       ', interaction_menu_configs: ' || (SELECT COUNT(*) FROM interaction_menu_configs) as summary;

-- 最终确认
SELECT 
    '✅ 部署成功！数据库现在支持Sprint 2的所有新功能' as status,
    NOW() as completed_at;