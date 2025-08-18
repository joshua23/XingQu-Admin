# 星趣APP - Supabase数据库结构文档

> 📅 **创建时间**: 2025-01-07  
> 🔄 **更新时间**: 2025-01-07  
> 📋 **版本**: v1.0  
> 🎯 **用途**: 为后续数据库开发提供完整的表结构、关系和约束信息

---

## 📋 目录

- [1. 数据库概览](#1-数据库概览)
- [2. 现有数据库表结构](#2-现有数据库表结构)
- [3. 外键关系](#3-外键关系)
- [4. 现有索引信息](#4-现有索引信息)
- [5. 核心业务表分析](#5-核心业务表分析)
- [6. 数据架构模式](#6-数据架构模式)
- [7. 开发建议](#7-开发建议)

---

## 1. 数据库概览

### 1.1 统计信息
- **总表数量**: 71个表
- **主要Schema**: `public` (46个表), `auth` (15个表), `storage` (5个表), `realtime` (5个表)
- **核心用户表**: `auth.users` + `public.users` (双表结构)
- **业务核心表**: AI角色、音频内容、用户互动、会员体系、支付系统

### 1.2 Schema分布
| Schema | 表数量 | 主要功能 |
|--------|---------|----------|
| `public` | 46 | 业务核心表、用户数据、内容管理 |
| `auth` | 15 | Supabase认证系统 |
| `storage` | 5 | 文件存储系统 |
| `realtime` | 5 | 实时消息系统 |
| 其他 | 5 | 扩展和工具表 |

---

## 2. 现有数据库表结构

### 2.1 所有表名列表

| table_name                    | table_schema       | 业务分类 |
| ----------------------------- | ------------------ | -------- |
| **核心业务表** |
| users                         | public             | 用户管理 |
| ai_characters                 | public             | AI角色 |
| audio_contents                | public             | 音频内容 |
| likes                         | public             | 用户互动 |
| comments                      | public             | 用户互动 |
| character_follows             | public             | 用户互动 |
| **会员与支付** |
| subscription_plans            | public             | 会员体系 |
| user_memberships              | public             | 会员体系 |
| payment_orders                | public             | 支付系统 |
| payment_callbacks             | public             | 支付系统 |
| membership_benefits           | public             | 会员体系 |
| membership_usage_logs         | public             | 会员体系 |
| user_active_benefits          | public             | 会员体系 |
| **智能推荐与个性化** |
| recommendation_algorithms     | public             | 推荐系统 |
| recommendation_configs        | public             | 推荐系统 |
| recommendation_feedback       | public             | 推荐系统 |
| user_recommendations          | public             | 推荐系统 |
| user_tab_preferences          | public             | 个性化 |
| user_ui_preferences           | public             | 个性化 |
| **AI与智能体** |
| custom_agents                 | public             | 自定义AI |
| agent_runtime_status          | public             | AI运行时 |
| agent_permissions             | public             | AI权限 |
| ai_agent_categories           | public             | AI分类 |
| ai_character_extensions       | public             | AI扩展 |
| **学习与挑战** |
| bilingual_contents            | public             | 双语学习 |
| user_bilingual_progress       | public             | 学习进度 |
| challenge_types               | public             | 挑战系统 |
| challenge_tasks               | public             | 挑战任务 |
| user_challenge_participations | public             | 挑战参与 |
| user_achievements             | public             | 成就系统 |
| **记忆与存储** |
| memory_types                  | public             | 记忆系统 |
| memory_items                  | public             | 记忆内容 |
| memory_search_vectors         | public             | 向量搜索 |
| **订阅与分组** |
| user_subscriptions            | public             | 用户订阅 |
| subscription_groups           | public             | 订阅分组 |
| subscription_group_items      | public             | 分组项目 |
| **系统与配置** |
| system_configs                | public             | 系统配置 |
| data_cache                    | public             | 数据缓存 |
| ui_decorations                | public             | UI装饰 |
| interaction_menu_configs      | public             | 交互配置 |
| interaction_logs              | public             | 交互日志 |
| user_analytics                | public             | 用户分析 |
| migration_logs                | public             | 迁移日志 |
| admin_users                   | public             | 管理员 |

### 2.2 核心表详细结构

#### 2.2.1 用户相关表

**users (public.users)**
- `id` (uuid, PK) - 用户唯一标识
- `phone` (varchar, UNIQUE) - 手机号码
- 与 `auth.users` 表关联，形成双表用户体系

**ai_characters**
- `id` (uuid, PK) - AI角色ID
- `creator_id` (uuid, FK → users.id) - 创建者
- `name`, `personality`, `description` - 角色基本信息
- `is_public`, `is_featured` - 可见性控制
- `follower_count`, `interaction_count` - 统计数据
- `is_professional_agent` - 专业智能体标识
- `professional_rating` (numeric) - 专业评分
- `category`, `tags` - 分类和标签

#### 2.2.2 内容表

**audio_contents**
- `id` (uuid, PK)
- `creator_id` (uuid, FK → users.id)
- `title`, `description`, `audio_url` - 基本信息
- `duration_seconds`, `play_count`, `like_count` - 统计信息

**bilingual_contents**
- 双语学习内容
- 支持主次语言、难度等级、音频等

#### 2.2.3 互动系统

**likes**
- 通用点赞表，支持多种目标类型
- `target_type`, `target_id` - 灵活的目标关联
- 已有复合唯一索引防重复

**comments**
- 支持嵌套评论 (`parent_id` 自引用)
- 通用评论系统

**character_follows**
- 用户关注AI角色的关系表

---

## 3. 外键关系

### 3.1 核心关系图
```
auth.users (Supabase认证)
    ↓
public.users (业务用户) ← 所有业务表的用户关联点
    ├── ai_characters (AI角色创建)
    ├── audio_contents (音频内容创建)
    ├── likes, comments (互动行为)
    ├── user_memberships (会员关系)
    ├── payment_orders (支付订单)
    ├── custom_agents (自定义AI)
    └── 其他用户相关表...
```

### 3.2 详细外键关系

| table_name                    | column_name       | foreign_table_name  | foreign_column_name | 关系说明 |
| ----------------------------- | ----------------- | ------------------- | ------------------- | -------- |
| **内容创建关系** |
| ai_characters                 | creator_id        | users               | id                  | 用户创建AI角色 |
| audio_contents                | creator_id        | users               | id                  | 用户创建音频 |
| bilingual_contents            | creator_id        | users               | id                  | 用户创建双语内容 |
| custom_agents                 | creator_id        | users               | id                  | 用户创建自定义AI |
| **用户行为关系** |
| likes                         | user_id           | users               | id                  | 用户点赞行为 |
| comments                      | user_id           | users               | id                  | 用户评论行为 |
| character_follows             | character_id      | ai_characters       | id                  | 关注AI角色 |
| **会员支付关系** |
| user_memberships              | user_id           | users               | id                  | 用户会员关系 |
| user_memberships              | plan_id           | subscription_plans  | id                  | 会员计划关联 |
| payment_orders                | user_id           | users               | id                  | 支付订单 |
| payment_orders                | plan_id           | subscription_plans  | id                  | 订单关联计划 |
| **学习进度关系** |
| user_bilingual_progress       | user_id           | users               | id                  | 双语学习进度 |
| user_bilingual_progress       | content_id        | bilingual_contents  | id                  | 学习内容关联 |
| user_challenge_participations | user_id           | users               | id                  | 挑战参与 |
| user_challenge_participations | challenge_id      | challenge_tasks     | id                  | 挑战任务关联 |

---

## 4. 现有索引信息

### 4.1 性能关键索引

#### 高频查询优化索引
- `idx_likes_compound` - 复合查询优化
- `idx_comments_target` - 评论目标查询
- `idx_ai_characters_category` - AI角色分类查询
- `idx_user_analytics_user` - 用户分析查询

#### 唯一性约束索引
- `users_phone_key` - 手机号唯一性
- `likes_user_id_target_type_target_id_key` - 防重复点赞
- `character_follows_user_id_character_id_key` - 防重复关注

#### 时间序列索引
- `idx_likes_created`, `idx_comments_created` - 按时间排序
- `idx_interaction_logs_created_at` - 交互日志时间查询
- `idx_user_analytics_created` - 分析数据时间查询

### 4.2 业务优化索引
- 支付相关: `idx_payment_orders_expires_at` (过期订单处理)
- 推荐相关: `idx_user_recommendations_expires_at` (推荐过期清理)
- 权限相关: `idx_agent_permissions_expires` (权限过期管理)

---

## 5. 核心业务表分析

### 5.1 用户体系 (双表模式)
- **auth.users**: Supabase原生认证表
- **public.users**: 业务扩展用户表
- **优势**: 认证与业务分离，安全性高
- **注意**: 需要保持两表数据一致性

### 5.2 内容体系
- **AI角色** (`ai_characters`): 核心内容实体
- **音频内容** (`audio_contents`): 多媒体内容
- **双语内容** (`bilingual_contents`): 学习材料

### 5.3 互动体系
- **通用点赞系统**: 支持多种内容类型
- **评论系统**: 支持嵌套回复
- **关注系统**: 用户对AI角色的关注

### 5.4 商业化体系
- **会员计划** → **用户会员** → **权益使用**
- **支付订单** → **支付回调** 完整支付闭环
- **使用日志** 详细记录会员权益使用

---

## 6. 数据架构模式

### 6.1 命名规范
- **表名**: 小写下划线分隔 (`user_memberships`)
- **ID字段**: 统一使用 `uuid` 类型
- **时间字段**: `created_at`, `updated_at` 标准命名
- **外键字段**: `{table}_id` 格式 (`user_id`, `plan_id`)

### 6.2 常用字段模式
- **创建者关联**: `creator_id UUID REFERENCES users(id)`
- **时间戳**: `created_at TIMESTAMPTZ DEFAULT now()`
- **软删除**: 部分表使用 `is_active BOOLEAN`
- **JSONB扩展**: 灵活存储结构化数据

### 6.3 索引策略
- **主键**: 自动UUID主键
- **外键**: 外键字段自动索引
- **查询优化**: 高频查询字段建立组合索引
- **时间序列**: 时间字段降序索引

---

## 7. 开发建议

### 7.1 新表设计原则
1. **复用现有关联**: 优先使用 `users.id` 作为用户关联
2. **遵循命名规范**: 保持与现有表一致的命名风格
3. **考虑索引性能**: 高频查询字段预建索引
4. **外键约束**: 明确设置外键关系保证数据一致性

### 7.2 避免重复创建
**已存在的功能模块**:
- ✅ 用户分析表 (`user_analytics`) - 已有基础分析
- ✅ 交互日志表 (`interaction_logs`) - 已有用户行为记录
- ✅ 系统配置表 (`system_configs`) - 已有配置管理
- ✅ 数据缓存表 (`data_cache`) - 已有缓存机制

### 7.3 扩展现有表 vs 新建表
**扩展现有表适用场景**:
- 在 `user_analytics` 基础上增加分析维度
- 在 `interaction_logs` 基础上扩展事件类型
- 在现有JSONB字段中增加新属性

**新建表适用场景**:
- 全新业务领域（如数据埋点分析）
- 需要特殊索引优化的大数据表
- 与现有表结构差异较大的功能

### 7.4 数据迁移注意事项
- **向前兼容**: 新字段设置默认值
- **索引创建**: 使用 `CONCURRENTLY` 避免锁表
- **分批处理**: 大表数据迁移分批执行
- **回滚准备**: 准备数据回滚脚本

---

## 📝 更新日志

| 版本 | 日期 | 更新内容 | 更新人 |
|------|------|----------|--------|
| v1.0 | 2025-01-07 | 初始版本，完整数据库结构梳理 | 后端开发工程师Agent |

---

**📞 使用说明**:
- 在创建新表前，请先查阅此文档避免重复
- 新增表结构后，请及时更新此文档
- 重大结构变更请在更新日志中记录

---

*本文档将随着数据库结构的演进持续更新*