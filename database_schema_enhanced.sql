-- 星趣App增强版数据库架构
-- 支持AI角色、音频内容、创作中心、发现页面等全部功能
-- 在Supabase SQL编辑器中执行此脚本

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- 全文搜索支持

-- ============================================================================
-- 用户系统表
-- ============================================================================

-- 用户表 (增强版)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,           -- 手机号码（登录用）
    nickname VARCHAR(50) NOT NULL,               -- 用户昵称
    avatar_url TEXT,                             -- 头像URL
    bio TEXT,                                    -- 个人简介
    gender VARCHAR(10),                          -- 性别: male/female/other
    birthday DATE,                               -- 生日
    location VARCHAR(100),                       -- 地理位置
    level INTEGER DEFAULT 1,                     -- 用户等级
    experience_points INTEGER DEFAULT 0,         -- 经验值
    is_verified BOOLEAN DEFAULT FALSE,           -- 是否认证用户
    is_creator BOOLEAN DEFAULT FALSE,            -- 是否为创作者
    preferences JSONB,                           -- 用户偏好设置
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户会话表
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(100),                      -- 设备标识
    device_type VARCHAR(50),                     -- 设备类型
    app_version VARCHAR(20),                     -- 应用版本
    login_ip INET,                              -- 登录IP
    expires_at TIMESTAMP WITH TIME ZONE,        -- 会话过期时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- AI角色系统表
-- ============================================================================

-- AI角色表
CREATE TABLE IF NOT EXISTS ai_characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,                  -- 角色名称
    avatar_url TEXT,                             -- 角色头像
    personality TEXT NOT NULL,                   -- 性格描述
    description TEXT,                            -- 角色描述
    background_story TEXT,                       -- 背景故事
    greeting_message TEXT,                       -- 问候语
    example_conversations JSONB,                 -- 示例对话
    tags TEXT[],                                -- 标签数组
    category VARCHAR(50),                       -- 分类
    age_range VARCHAR(20),                      -- 适用年龄
    language VARCHAR(10) DEFAULT 'zh-CN',      -- 语言
    is_public BOOLEAN DEFAULT TRUE,             -- 是否公开
    is_featured BOOLEAN DEFAULT FALSE,          -- 是否精选
    is_active BOOLEAN DEFAULT TRUE,             -- 是否激活
    follower_count INTEGER DEFAULT 0,          -- 关注者数量
    conversation_count INTEGER DEFAULT 0,       -- 对话次数
    rating DECIMAL(3,2) DEFAULT 0.00,          -- 评分
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI角色关注表
CREATE TABLE IF NOT EXISTS character_follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, character_id)
);

-- AI对话记录表
CREATE TABLE IF NOT EXISTS character_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE,
    messages JSONB NOT NULL,                    -- 对话消息数组
    session_id UUID,                           -- 会话ID
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 音频内容系统表
-- ============================================================================

-- 音频内容表
CREATE TABLE IF NOT EXISTS audio_contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,                -- 音频标题
    description TEXT,                           -- 音频描述
    cover_url TEXT,                             -- 封面图片
    audio_url TEXT NOT NULL,                    -- 音频文件URL
    duration_seconds INTEGER,                   -- 时长（秒）
    file_size BIGINT,                          -- 文件大小（字节）
    category VARCHAR(50),                       -- 分类
    tags TEXT[],                               -- 标签
    transcript TEXT,                           -- 文字稿
    is_public BOOLEAN DEFAULT TRUE,            -- 是否公开
    is_featured BOOLEAN DEFAULT FALSE,         -- 是否精选
    play_count INTEGER DEFAULT 0,             -- 播放次数
    like_count INTEGER DEFAULT 0,             -- 点赞数
    download_count INTEGER DEFAULT 0,         -- 下载次数
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 音频播放记录表
CREATE TABLE IF NOT EXISTS audio_play_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    audio_id UUID NOT NULL REFERENCES audio_contents(id) ON DELETE CASCADE,
    play_position INTEGER DEFAULT 0,           -- 播放位置（秒）
    completed BOOLEAN DEFAULT FALSE,           -- 是否播放完成
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 音频频道表
CREATE TABLE IF NOT EXISTS audio_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,                -- 频道名称
    description TEXT,                          -- 频道描述
    cover_url TEXT,                            -- 频道封面
    category VARCHAR(50),                      -- 分类
    is_active BOOLEAN DEFAULT TRUE,           -- 是否激活
    subscriber_count INTEGER DEFAULT 0,       -- 订阅者数量
    total_plays INTEGER DEFAULT 0,            -- 总播放次数
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 频道音频关联表
CREATE TABLE IF NOT EXISTS channel_audios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES audio_channels(id) ON DELETE CASCADE,
    audio_id UUID NOT NULL REFERENCES audio_contents(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,             -- 排序
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(channel_id, audio_id)
);

-- ============================================================================
-- 创作中心系统表
-- ============================================================================

-- 创作项目表
CREATE TABLE IF NOT EXISTS creation_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,               -- 项目标题
    description TEXT,                          -- 项目描述
    content_type VARCHAR(50) NOT NULL,         -- 内容类型: character/story/audio/game
    content JSONB,                             -- 项目内容（JSON格式）
    thumbnail_url TEXT,                        -- 缩略图
    status VARCHAR(20) DEFAULT 'draft',        -- 状态: draft/published/reviewing/archived
    tags TEXT[],                              -- 标签
    is_public BOOLEAN DEFAULT FALSE,          -- 是否公开
    view_count INTEGER DEFAULT 0,            -- 查看次数
    like_count INTEGER DEFAULT 0,            -- 点赞数
    fork_count INTEGER DEFAULT 0,            -- 分支数（被其他人复制）
    collaborators UUID[],                     -- 协作者用户ID数组
    version INTEGER DEFAULT 1,               -- 版本号
    published_at TIMESTAMP WITH TIME ZONE,   -- 发布时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创作模板表
CREATE TABLE IF NOT EXISTS creation_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,               -- 模板名称
    description TEXT,                         -- 模板描述
    content_type VARCHAR(50) NOT NULL,        -- 内容类型
    template_data JSONB NOT NULL,            -- 模板数据
    preview_url TEXT,                        -- 预览图
    category VARCHAR(50),                     -- 分类
    difficulty_level INTEGER DEFAULT 1,      -- 难度等级 1-5
    usage_count INTEGER DEFAULT 0,           -- 使用次数
    is_official BOOLEAN DEFAULT FALSE,       -- 是否官方模板
    is_active BOOLEAN DEFAULT TRUE,          -- 是否可用
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 发现和内容系统表
-- ============================================================================

-- 发现内容表
CREATE TABLE IF NOT EXISTS discovery_contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL,        -- 内容类型
    content_id UUID,                          -- 关联内容ID
    title VARCHAR(200) NOT NULL,             -- 标题
    description TEXT,                         -- 描述
    thumbnail_url TEXT,                       -- 缩略图
    tags TEXT[],                             -- 标签
    category VARCHAR(50),                     -- 分类
    difficulty_level INTEGER,                -- 难度等级
    target_audience VARCHAR(50),             -- 目标受众
    is_featured BOOLEAN DEFAULT FALSE,       -- 是否精选
    is_trending BOOLEAN DEFAULT FALSE,       -- 是否热门
    weight INTEGER DEFAULT 0,                -- 权重（用于排序）
    view_count INTEGER DEFAULT 0,           -- 查看次数
    like_count INTEGER DEFAULT 0,           -- 点赞数
    share_count INTEGER DEFAULT 0,          -- 分享次数
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 内容收藏表
CREATE TABLE IF NOT EXISTS content_bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL,        -- 内容类型
    content_id UUID NOT NULL,                 -- 内容ID
    folder_name VARCHAR(50),                  -- 收藏夹名称
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, content_type, content_id)
);

-- ============================================================================
-- 社交系统表
-- ============================================================================

-- 关注表 (增强版)
CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    follow_type VARCHAR(20) DEFAULT 'user',   -- 关注类型: user/creator
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK(follower_id != following_id)
);

-- 点赞表 (通用)
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,         -- 目标类型: story/character/audio/creation
    target_id UUID NOT NULL,                  -- 目标ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

-- 评论表 (通用)
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,         -- 目标类型
    target_id UUID NOT NULL,                  -- 目标ID
    content TEXT NOT NULL,                    -- 评论内容
    parent_id UUID REFERENCES comments(id),   -- 父评论ID（用于回复）
    is_pinned BOOLEAN DEFAULT FALSE,         -- 是否置顶
    like_count INTEGER DEFAULT 0,           -- 点赞数
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 消息表
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,                    -- 消息内容
    message_type VARCHAR(20) DEFAULT 'text', -- 消息类型: text/image/audio/system
    is_read BOOLEAN DEFAULT FALSE,           -- 是否已读
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 系统配置和统计表
-- ============================================================================

-- 系统配置表
CREATE TABLE IF NOT EXISTS system_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,  -- 配置键
    config_value TEXT,                        -- 配置值
    description TEXT,                         -- 描述
    is_active BOOLEAN DEFAULT TRUE,          -- 是否激活
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户行为统计表
CREATE TABLE IF NOT EXISTS user_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,          -- 事件类型
    event_data JSONB,                         -- 事件数据
    session_id UUID,                          -- 会话ID
    ip_address INET,                          -- IP地址
    user_agent TEXT,                          -- 用户代理
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 创建索引提高查询性能
-- ============================================================================

-- 用户表索引
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_nickname ON users(nickname);
CREATE INDEX IF NOT EXISTS idx_users_is_creator ON users(is_creator);

-- AI角色表索引
CREATE INDEX IF NOT EXISTS idx_ai_characters_creator_id ON ai_characters(creator_id);
CREATE INDEX IF NOT EXISTS idx_ai_characters_category ON ai_characters(category);
CREATE INDEX IF NOT EXISTS idx_ai_characters_is_public ON ai_characters(is_public);
CREATE INDEX IF NOT EXISTS idx_ai_characters_is_featured ON ai_characters(is_featured);
CREATE INDEX IF NOT EXISTS idx_ai_characters_tags ON ai_characters USING gin(tags);

-- 音频内容表索引
CREATE INDEX IF NOT EXISTS idx_audio_contents_creator_id ON audio_contents(creator_id);
CREATE INDEX IF NOT EXISTS idx_audio_contents_category ON audio_contents(category);
CREATE INDEX IF NOT EXISTS idx_audio_contents_is_public ON audio_contents(is_public);
CREATE INDEX IF NOT EXISTS idx_audio_contents_tags ON audio_contents USING gin(tags);

-- 创作项目表索引
CREATE INDEX IF NOT EXISTS idx_creation_items_creator_id ON creation_items(creator_id);
CREATE INDEX IF NOT EXISTS idx_creation_items_content_type ON creation_items(content_type);
CREATE INDEX IF NOT EXISTS idx_creation_items_status ON creation_items(status);

-- 发现内容表索引
CREATE INDEX IF NOT EXISTS idx_discovery_contents_category ON discovery_contents(category);
CREATE INDEX IF NOT EXISTS idx_discovery_contents_is_featured ON discovery_contents(is_featured);
CREATE INDEX IF NOT EXISTS idx_discovery_contents_tags ON discovery_contents USING gin(tags);

-- 社交系统索引
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_target ON likes(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_comments_target ON comments(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);

-- 全文搜索索引
CREATE INDEX IF NOT EXISTS idx_ai_characters_search ON ai_characters USING gin(to_tsvector('simple', name || ' ' || description));
CREATE INDEX IF NOT EXISTS idx_audio_contents_search ON audio_contents USING gin(to_tsvector('simple', title || ' ' || description));
CREATE INDEX IF NOT EXISTS idx_discovery_contents_search ON discovery_contents USING gin(to_tsvector('simple', title || ' ' || description));

-- ============================================================================
-- 创建触发器和函数
-- ============================================================================

-- 更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有需要的表添加更新时间戳触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_characters_updated_at BEFORE UPDATE ON ai_characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audio_contents_updated_at BEFORE UPDATE ON audio_contents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_creation_items_updated_at BEFORE UPDATE ON creation_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 统计计数器更新函数
CREATE OR REPLACE FUNCTION update_character_follower_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE ai_characters 
        SET follower_count = follower_count + 1 
        WHERE id = NEW.character_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ai_characters 
        SET follower_count = follower_count - 1 
        WHERE id = OLD.character_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- 角色关注计数触发器
CREATE TRIGGER character_follow_count_trigger
    AFTER INSERT OR DELETE ON character_follows
    FOR EACH ROW EXECUTE FUNCTION update_character_follower_count();

-- ============================================================================
-- 插入初始配置数据
-- ============================================================================

-- 系统配置初始数据
INSERT INTO system_configs (config_key, config_value, description) VALUES
('app_version', '1.0.0', '当前应用版本'),
('maintenance_mode', 'false', '维护模式开关'),
('max_upload_size', '50MB', '最大上传文件大小'),
('supported_audio_formats', '["mp3", "wav", "m4a"]', '支持的音频格式'),
('featured_content_limit', '10', '精选内容数量限制'),
('search_result_limit', '50', '搜索结果数量限制')
ON CONFLICT (config_key) DO NOTHING;

-- ============================================================================
-- 创建RLS策略 (Row Level Security)
-- ============================================================================

-- 启用RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE creation_items ENABLE ROW LEVEL SECURITY;

-- 用户只能查看和编辑自己的数据
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 公开AI角色可以被所有人查看
CREATE POLICY "Public characters are viewable by everyone" ON ai_characters
    FOR SELECT USING (is_public = true);

-- 创作者可以管理自己的角色
CREATE POLICY "Creators can manage own characters" ON ai_characters
    FOR ALL USING (auth.uid() = creator_id);

-- 公开音频内容可以被所有人查看
CREATE POLICY "Public audio content is viewable by everyone" ON audio_contents
    FOR SELECT USING (is_public = true);

-- 创作者可以管理自己的音频内容
CREATE POLICY "Creators can manage own audio content" ON audio_contents
    FOR ALL USING (auth.uid() = creator_id);

-- 公开创作项目可以被所有人查看
CREATE POLICY "Public creations are viewable by everyone" ON creation_items
    FOR SELECT USING (is_public = true);

-- 创作者和协作者可以管理创作项目
CREATE POLICY "Creators can manage own creations" ON creation_items
    FOR ALL USING (auth.uid() = creator_id OR auth.uid() = ANY(collaborators));