-- ============================================================================
-- 星趣App Sprint 2 数据库架构设计
-- 新增功能：通用交互菜单、综合页六大子模块、星形动效和品牌元素
-- ============================================================================

-- ============================================================================
-- 1. 通用交互功能相关表
-- ============================================================================

-- 交互菜单配置表
CREATE TABLE interaction_menu_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_type VARCHAR(50) NOT NULL, -- 'ai_interaction' | 'grid_recommendation'
    menu_items JSONB NOT NULL, -- 菜单项配置JSON
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户交互行为日志表
CREATE TABLE interaction_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    page_type VARCHAR(50) NOT NULL,
    interaction_type VARCHAR(50) NOT NULL, -- 'reload', 'voice_call', 'image', etc.
    target_type VARCHAR(50), -- 'character', 'audio', 'content'
    target_id UUID,
    metadata JSONB, -- 额外的交互数据
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_interaction_logs_user_id ON interaction_logs(user_id);
CREATE INDEX idx_interaction_logs_created_at ON interaction_logs(created_at);
CREATE INDEX idx_interaction_logs_interaction_type ON interaction_logs(interaction_type);

-- ============================================================================
-- 2. 综合页订阅模块
-- ============================================================================

-- 用户订阅关系表（扩展现有character_follows）
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL, -- 'character', 'audio_channel', 'creator'
    target_id UUID NOT NULL,
    subscription_type VARCHAR(20) DEFAULT 'standard', -- 'standard', 'premium'
    tags TEXT[], -- 用户自定义标签
    priority INTEGER DEFAULT 0, -- 订阅优先级
    notifications_enabled BOOLEAN DEFAULT true,
    last_accessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 订阅分组表
CREATE TABLE subscription_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    group_name VARCHAR(100) NOT NULL,
    group_color VARCHAR(7), -- HEX color code
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 订阅分组关系表
CREATE TABLE subscription_group_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES subscription_groups(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, subscription_id)
);

-- 创建索引
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_target ON user_subscriptions(target_type, target_id);
CREATE INDEX idx_subscription_groups_user_id ON subscription_groups(user_id);

-- ============================================================================
-- 3. 推荐算法和智能体模块
-- ============================================================================

-- 推荐算法配置表
CREATE TABLE recommendation_algorithms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    algorithm_name VARCHAR(100) NOT NULL,
    algorithm_type VARCHAR(50) NOT NULL, -- 'collaborative', 'content_based', 'hybrid'
    config_params JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户推荐结果缓存表
CREATE TABLE user_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL, -- 'character', 'audio', 'creation'
    recommended_items JSONB NOT NULL, -- 推荐结果JSON数组
    algorithm_version VARCHAR(20),
    confidence_score DECIMAL(5,4),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 智能体分类表
CREATE TABLE ai_agent_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) NOT NULL,
    category_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI角色扩展属性（专业智能体）
CREATE TABLE ai_character_extensions (
    character_id UUID PRIMARY KEY REFERENCES ai_characters(id) ON DELETE CASCADE,
    agent_category_id UUID REFERENCES ai_agent_categories(id),
    professional_skills TEXT[], -- 专业技能标签
    service_types TEXT[], -- 服务类型
    expertise_level INTEGER DEFAULT 1, -- 1-5专业程度
    usage_statistics JSONB, -- 使用统计数据
    performance_metrics JSONB, -- 性能指标
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_user_recommendations_user_id ON user_recommendations(user_id);
CREATE INDEX idx_user_recommendations_expires_at ON user_recommendations(expires_at);
CREATE INDEX idx_ai_character_extensions_category ON ai_character_extensions(agent_category_id);

-- ============================================================================
-- 4. 记忆簿模块
-- ============================================================================

-- 记忆类型配置表
CREATE TABLE memory_types (
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

-- 用户记忆条目表
CREATE TABLE memory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    memory_type_id UUID REFERENCES memory_types(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    tags TEXT[],
    related_character_id UUID REFERENCES ai_characters(id),
    related_conversation_id UUID, -- 关联的对话ID
    metadata JSONB, -- 扩展元数据
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 记忆搜索向量（使用PostgreSQL全文搜索）
CREATE TABLE memory_search_vectors (
    memory_id UUID PRIMARY KEY REFERENCES memory_items(id) ON DELETE CASCADE,
    search_vector TSVECTOR,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建全文搜索索引
CREATE INDEX idx_memory_search_vectors ON memory_search_vectors USING GIN(search_vector);
CREATE INDEX idx_memory_items_user_id ON memory_items(user_id);
CREATE INDEX idx_memory_items_type ON memory_items(memory_type_id);
CREATE INDEX idx_memory_items_created_at ON memory_items(created_at DESC);

-- ============================================================================
-- 5. 双语学习模块
-- ============================================================================

-- 双语内容表
CREATE TABLE bilingual_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(50) NOT NULL, -- 'dialogue', 'phrase', 'sentence'
    primary_language VARCHAR(10) NOT NULL, -- 'zh', 'en'
    secondary_language VARCHAR(10) NOT NULL,
    primary_text TEXT NOT NULL,
    secondary_text TEXT NOT NULL,
    difficulty_level VARCHAR(20), -- 'beginner', 'intermediate', 'advanced'
    category VARCHAR(50), -- 'daily', 'business', 'academic'
    audio_url TEXT, -- 语音文件URL
    phonetic_notation TEXT, -- 音标
    usage_example TEXT,
    tags TEXT[],
    is_public BOOLEAN DEFAULT true,
    creator_id UUID REFERENCES users(id),
    like_count INTEGER DEFAULT 0,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户双语学习进度表
CREATE TABLE user_bilingual_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID REFERENCES bilingual_contents(id) ON DELETE CASCADE,
    mastery_level INTEGER DEFAULT 0, -- 0-5掌握程度
    practice_count INTEGER DEFAULT 0,
    last_practiced_at TIMESTAMPTZ,
    is_favorite BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, content_id)
);

-- 创建索引
CREATE INDEX idx_bilingual_contents_languages ON bilingual_contents(primary_language, secondary_language);
CREATE INDEX idx_bilingual_contents_difficulty ON bilingual_contents(difficulty_level);
CREATE INDEX idx_user_bilingual_progress_user_id ON user_bilingual_progress(user_id);

-- ============================================================================
-- 6. 挑战任务模块
-- ============================================================================

-- 挑战任务类型表
CREATE TABLE challenge_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50),
    color_hex VARCHAR(7),
    default_duration_days INTEGER DEFAULT 7,
    max_participants INTEGER,
    reward_config JSONB, -- 奖励配置
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 挑战任务表
CREATE TABLE challenge_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_type_id UUID REFERENCES challenge_types(id),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    requirements JSONB NOT NULL, -- 完成要求
    rewards JSONB, -- 奖励配置
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    difficulty_level INTEGER DEFAULT 1, -- 1-5难度等级
    is_featured BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'active', -- 'draft', 'active', 'completed', 'cancelled'
    creator_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户挑战参与记录表
CREATE TABLE user_challenge_participations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES challenge_tasks(id) ON DELETE CASCADE,
    progress_data JSONB, -- 进度数据
    completion_percentage INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'abandoned'
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    rewards_claimed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

-- 用户成就表
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url TEXT,
    points_awarded INTEGER DEFAULT 0,
    badge_level VARCHAR(20), -- 'bronze', 'silver', 'gold', 'platinum'
    metadata JSONB, -- 成就相关数据
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    is_featured BOOLEAN DEFAULT false
);

-- 创建索引
CREATE INDEX idx_challenge_tasks_status ON challenge_tasks(status);
CREATE INDEX idx_challenge_tasks_dates ON challenge_tasks(start_date, end_date);
CREATE INDEX idx_user_challenge_participations_user_id ON user_challenge_participations(user_id);
CREATE INDEX idx_user_challenge_participations_status ON user_challenge_participations(status);
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);

-- ============================================================================
-- 7. UI装饰和品牌元素
-- ============================================================================

-- UI装饰元素配置表
CREATE TABLE ui_decorations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decoration_type VARCHAR(50) NOT NULL, -- 'star_animation', 'particle_effect', 'brand_element'
    element_name VARCHAR(100) NOT NULL,
    config_data JSONB NOT NULL, -- 装饰元素配置
    target_pages TEXT[], -- 应用的页面
    is_active BOOLEAN DEFAULT true,
    display_conditions JSONB, -- 显示条件
    animation_config JSONB, -- 动画配置
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户UI偏好设置表
CREATE TABLE user_ui_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    theme_preference VARCHAR(20) DEFAULT 'dark', -- 'dark', 'light', 'auto'
    animation_enabled BOOLEAN DEFAULT true,
    particle_effects_enabled BOOLEAN DEFAULT true,
    accessibility_mode BOOLEAN DEFAULT false,
    custom_decorations JSONB, -- 用户自定义装饰
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 创建索引
CREATE INDEX idx_ui_decorations_type ON ui_decorations(decoration_type);
CREATE INDEX idx_ui_decorations_active ON ui_decorations(is_active);

-- ============================================================================
-- 8. 系统配置和缓存表
-- ============================================================================

-- 系统配置表
CREATE TABLE system_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false, -- 是否可被客户端访问
    updated_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 数据缓存表（用于提高性能）
CREATE TABLE data_cache (
    cache_key VARCHAR(200) PRIMARY KEY,
    cache_data JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_data_cache_expires_at ON data_cache(expires_at);

-- ============================================================================
-- 9. 插入初始化数据
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
('personal_diary', '个人日记', 'edit', '#EC4899', '个人心情和日记', true, 8);

-- 插入AI智能体分类初始数据
INSERT INTO ai_agent_categories (category_name, category_code, description, display_order) VALUES
('编程助手', 'programming', '专业的编程和技术开发助手', 1),
('写作助手', 'writing', '文章创作和内容写作助手', 2),
('学习导师', 'education', '各学科的学习指导助手', 3),
('商务顾问', 'business', '商业咨询和策略建议助手', 4),
('创意设计', 'design', '设计创意和视觉艺术助手', 5),
('生活助理', 'lifestyle', '日常生活管理和建议助手', 6);

-- 插入挑战类型初始数据
INSERT INTO challenge_types (type_name, display_name, description, icon_name, color_hex, default_duration_days) VALUES
('vocabulary', '每日词汇挑战', '提升语言词汇量的每日挑战', 'vocabulary', '#3B82F6', 7),
('coding', '编程练习挑战', '提升编程技能的算法挑战', 'code', '#10B981', 14),
('writing', '创意写作挑战', '激发创意写作能力的挑战', 'edit', '#8B5CF6', 7),
('fitness', '健康生活挑战', '养成健康生活习惯的挑战', 'fitness', '#EF4444', 30);

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
]', 2, true);

-- 插入UI装饰配置初始数据
INSERT INTO ui_decorations (decoration_type, element_name, config_data, target_pages, is_active) VALUES
('star_animation', '星形旋转动效', '{"size": 16, "color": "#FFC542", "duration": "3s", "rotation": true, "pulse": true}', ARRAY['home_selection', 'home_fm'], true),
('particle_effect', '星形粒子效果', '{"particle_count": 8, "duration": "3s", "colors": ["#FFC542", "#F5DFAF"], "spawn_rate": 0.5}', ARRAY['home_selection'], true),
('brand_element', '品牌星形装饰', '{"type": "decoration", "size": 12, "color": "#FFC542", "glow": true}', ARRAY['all'], true);

-- 插入系统配置初始数据
INSERT INTO system_configs (config_key, config_value, description, is_public) VALUES
('recommendation_refresh_interval', '{"hours": 6}', '推荐内容刷新间隔', false),
('challenge_max_participants', '{"default": 1000}', '挑战任务最大参与人数', false),
('ui_animation_settings', '{"enable_particles": true, "enable_star_effects": true}', 'UI动画设置', true),
('memory_search_config', '{"max_results": 50, "highlight_keywords": true}', '记忆搜索配置', false);