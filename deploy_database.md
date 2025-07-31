# 星趣App数据库部署指南

## 🎯 **立即执行：Supabase数据库部署**

### 📍 **您的Supabase项目信息**
- **项目URL**: `https://wqdpqhfqrxvssxifpmvt.supabase.co`
- **项目ID**: `wqdpqhfqrxvssxifpmvt`
- **配置状态**: ✅ 已更新到应用中

---

## 🚀 **步骤1: 访问Supabase SQL编辑器**

1. **打开链接**: [Supabase Dashboard](https://app.supabase.com/project/wqdpqhfqrxvssxifpmvt)
2. **登录您的账户**
3. **进入SQL编辑器**: 左侧菜单 → SQL Editor → New Query

---

## 🗄️ **步骤2: 执行数据库架构**

### **2.1 创建增强版数据库结构**

**复制以下SQL到编辑器并执行：**

```sql
-- 星趣App增强版数据库架构
-- 支持AI角色、音频内容、创作中心、发现页面等全部功能

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

-- 社交功能表
CREATE TABLE IF NOT EXISTS character_follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, character_id)
);

CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL,         -- 目标类型: story/character/audio/creation
    target_id UUID NOT NULL,                  -- 目标ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

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

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_ai_characters_is_public ON ai_characters(is_public);
CREATE INDEX IF NOT EXISTS idx_ai_characters_is_featured ON ai_characters(is_featured);
CREATE INDEX IF NOT EXISTS idx_audio_contents_is_public ON audio_contents(is_public);
CREATE INDEX IF NOT EXISTS idx_creation_items_creator_id ON creation_items(creator_id);
CREATE INDEX IF NOT EXISTS idx_discovery_contents_is_featured ON discovery_contents(is_featured);
```

### **2.2 创建数据库函数**

**继续执行以下SQL：**

```sql
-- 数据库函数和触发器

-- 更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为表添加更新时间戳触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_characters_updated_at BEFORE UPDATE ON ai_characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audio_contents_updated_at BEFORE UPDATE ON audio_contents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 增加播放次数函数
CREATE OR REPLACE FUNCTION increment_play_count(audio_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE audio_contents 
    SET play_count = play_count + 1 
    WHERE id = audio_id;
END;
$$ LANGUAGE plpgsql;

-- 角色关注计数器函数
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

-- 创建角色关注计数触发器
CREATE TRIGGER character_follow_count_trigger
    AFTER INSERT OR DELETE ON character_follows
    FOR EACH ROW EXECUTE FUNCTION update_character_follower_count();
```

---

## 🔐 **步骤3: 配置安全策略**

**执行以下RLS策略：**

```sql
-- 启用行级安全
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE creation_items ENABLE ROW LEVEL SECURITY;

-- 用户表策略
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- AI角色策略
CREATE POLICY "Public characters are viewable by everyone" ON ai_characters
    FOR SELECT USING (is_public = true);

CREATE POLICY "Creators can manage own characters" ON ai_characters
    FOR ALL USING (auth.uid() = creator_id);

-- 音频内容策略
CREATE POLICY "Public audio content is viewable by everyone" ON audio_contents
    FOR SELECT USING (is_public = true);

CREATE POLICY "Creators can manage own audio content" ON audio_contents
    FOR ALL USING (auth.uid() = creator_id);
```

---

## 📱 **步骤4: 配置存储桶**

**在Supabase Storage中创建存储桶：**

1. **进入Storage页面**
2. **创建以下存储桶：**
   - `avatars` (用户头像)
   - `audios` (音频文件)
   - `thumbnails` (缩略图)

**或者执行SQL：**

```sql
INSERT INTO storage.buckets (id, name, public) VALUES 
('avatars', 'avatars', true),
('audios', 'audios', true),
('thumbnails', 'thumbnails', true);
```

---

## ✅ **步骤5: 验证部署**

**执行以下查询验证部署成功：**

```sql
-- 检查表是否创建成功
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 检查函数是否创建成功
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';
```

**如果看到表和函数列表，说明部署成功！** ✅

---

## 🎉 **完成！下一步**

数据库部署完成后，请告诉我，我将：

1. **测试API连接** 🔌
2. **创建测试数据** 📊
3. **验证前端功能** 📱
4. **开始真实数据对接** 🚀

**现在就可以在Supabase中执行这些SQL了！** 💪