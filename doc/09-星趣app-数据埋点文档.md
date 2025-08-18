# 星趣App 数据埋点文档

> 本文档详细描述星趣App的数据埋点策略、事件定义、指标体系和技术实现方案，为数据驱动的产品优化和运营决策提供完整的数据基础。

---

## 文档信息

- **文档版本**: v1.0.0
- **创建时间**: 2025年1月21日
- **最后更新**: 2025年1月21日
- **适用范围**: 星趣App产品团队、开发团队、数据分析团队
- **文档状态**: 正式发布

---

## 目录

1. [概述](#1-概述)
2. [埋点架构设计](#2-埋点架构设计)
3. [核心事件定义](#3-核心事件定义)
4. [会员体系埋点](#4-会员体系埋点)
5. [星川体系埋点](#5-星川体系埋点)
6. [业务流程埋点](#6-业务流程埋点)
7. [用户行为分析](#7-用户行为分析)
8. [技术实现方案](#8-技术实现方案)
9. [数据指标体系](#9-数据指标体系)
10. [隐私合规](#10-隐私合规)

---

## 1. 概述

### 1.1 埋点目标

**业务目标**：
- 实现数据驱动的产品迭代和用户体验优化
- 构建完整的用户行为分析体系
- 支撑精准的运营决策和商业化策略
- 建立科学的用户价值评估体系

**技术目标**：
- 建立统一的数据采集标准和规范
- 实现实时数据处理和分析能力
- 保证数据质量和一致性
- 满足隐私合规要求

### 1.2 数据分层架构

```
用户行为数据 (User Behavior Data)
├── 基础行为层 (Basic Actions)
│   ├── 页面访问、点击、滑动
│   ├── 应用生命周期事件
│   └── 设备和环境信息
├── 业务交互层 (Business Interactions)
│   ├── AI对话交互
│   ├── 音频播放行为
│   ├── 创作发布行为
│   └── 社交互动行为
├── 商业化行为层 (Monetization)
│   ├── 会员相关行为
│   ├── 虚拟货币交易
│   ├── 广告互动
│   └── 支付流程
└── 增长留存层 (Growth & Retention)
    ├── 用户生命周期管理
    ├── 留存和流失分析
    ├── 渠道归因分析
    └── 用户价值计算
```

### 1.3 核心数据指标

| 指标类别 | 核心指标 | 业务价值 |
|----------|----------|----------|
| 用户规模 | DAU/MAU/新用户数 | 产品规模和增长趋势 |
| 用户活跃 | 使用时长/会话数/互动频次 | 用户粘性和参与度 |
| 功能使用 | 各功能使用率/转化漏斗 | 功能价值和优化方向 |
| 商业化 | 付费转化率/ARPU/LTV | 商业价值和收入潜力 |
| 用户体验 | 加载速度/崩溃率/满意度 | 产品质量和用户体验 |

---

## 2. 埋点架构设计

### 2.1 技术架构

#### 2.1.1 数据采集层

```typescript
// 数据采集架构
interface TrackingArchitecture {
  // 客户端采集
  clientSide: {
    // Flutter客户端埋点SDK
    flutterSDK: "神策SDK + 友盟SDK",
    // 本地缓存机制
    localStorage: "事件缓存和批量上报",
    // 实时上报
    realTimeReport: "关键事件实时上报"
  },
  
  // 服务端采集
  serverSide: {
    // API调用日志
    apiLogs: "Supabase API调用记录",
    // 业务事件触发
    businessEvents: "服务端业务逻辑触发",
    // 第三方服务数据
    thirdPartyData: "火山引擎AI服务使用数据"
  },
  
  // 数据传输
  dataTransmission: {
    // 数据格式
    format: "JSON标准格式",
    // 传输协议
    protocol: "HTTPS加密传输",
    // 数据压缩
    compression: "gzip压缩优化"
  }
}
```

#### 2.1.2 数据存储层

```sql
-- 事件数据表结构
CREATE TABLE user_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    event_category VARCHAR(100) NOT NULL,
    event_properties JSONB DEFAULT '{}',
    user_properties JSONB DEFAULT '{}',
    device_info JSONB DEFAULT '{}',
    app_version VARCHAR(50),
    platform VARCHAR(50),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户会话表
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER,
    page_views INTEGER DEFAULT 0,
    event_count INTEGER DEFAULT 0,
    is_new_user BOOLEAN DEFAULT FALSE,
    referrer VARCHAR(500),
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户属性表
CREATE TABLE user_attributes (
    user_id UUID PRIMARY KEY,
    first_seen_at TIMESTAMPTZ NOT NULL,
    last_seen_at TIMESTAMPTZ NOT NULL,
    total_sessions INTEGER DEFAULT 0,
    total_events INTEGER DEFAULT 0,
    membership_level VARCHAR(50) DEFAULT 'free',
    membership_start_date TIMESTAMPTZ,
    membership_end_date TIMESTAMPTZ,
    total_spent DECIMAL(10,2) DEFAULT 0,
    star_points_balance INTEGER DEFAULT 0,
    star_river_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.2 事件命名规范

#### 2.2.1 命名规则

**基本格式**: `{业务域}_{动作}_{对象}`

**示例**:
- `user_login_success` - 用户登录成功
- `ai_chat_start` - AI对话开始
- `membership_purchase_complete` - 会员购买完成
- `star_river_draw_single` - 星川单次抽取

#### 2.2.2 事件分类

| 分类 | 前缀 | 说明 | 示例 |
|------|------|------|------|
| 用户行为 | `user_` | 用户基础操作 | `user_register`, `user_login` |
| 页面访问 | `page_` | 页面浏览事件 | `page_home_view`, `page_discovery_view` |
| AI交互 | `ai_` | AI相关交互 | `ai_chat_message`, `ai_voice_call` |
| 音频播放 | `audio_` | 音频相关行为 | `audio_play_start`, `audio_play_complete` |
| 创作行为 | `create_` | 内容创作 | `create_character_start`, `create_content_publish` |
| 社交互动 | `social_` | 社交功能 | `social_like`, `social_comment` |
| 会员相关 | `membership_` | 会员体系 | `membership_upgrade`, `membership_renew` |
| 星川体系 | `star_river_` | 星川功能 | `star_river_draw`, `star_river_trade` |
| 支付相关 | `payment_` | 支付流程 | `payment_start`, `payment_success` |
| 搜索行为 | `search_` | 搜索功能 | `search_query`, `search_result_click` |

---

## 3. 核心事件定义

### 3.1 应用生命周期事件

#### 3.1.1 应用启动事件

```typescript
// 应用启动
interface AppLaunchEvent {
  event_name: "app_launch";
  event_category: "lifecycle";
  properties: {
    launch_type: "cold_start" | "warm_start" | "hot_start";
    previous_session_duration?: number; // 上次会话时长(秒)
    time_since_last_session?: number; // 距离上次会话时间(秒)
    install_source?: string; // 安装来源
    app_version: string;
    is_first_launch: boolean;
    device_info: {
      platform: "ios" | "android";
      os_version: string;
      device_model: string;
      screen_resolution: string;
      network_type: "wifi" | "cellular" | "unknown";
    };
  };
}

// 应用退出
interface AppExitEvent {
  event_name: "app_exit";
  event_category: "lifecycle";
  properties: {
    session_duration: number; // 会话时长(秒)
    page_views: number; // 页面浏览次数
    total_events: number; // 总事件数
    exit_type: "normal" | "crash" | "forced";
    last_page: string; // 最后访问页面
  };
}
```

#### 3.1.2 页面访问事件

```typescript
// 页面浏览
interface PageViewEvent {
  event_name: "page_view";
  event_category: "navigation";
  properties: {
    page_name: string; // 页面名称
    page_category: "home" | "messages" | "creation" | "discovery" | "profile";
    previous_page?: string; // 来源页面
    load_time: number; // 页面加载时间(ms)
    referrer?: string; // 外部来源
    tab_index?: number; // Tab索引(如果是Tab页)
  };
}

// 页面停留时长
interface PageDurationEvent {
  event_name: "page_duration";
  event_category: "engagement";
  properties: {
    page_name: string;
    duration: number; // 停留时长(秒)
    scroll_depth: number; // 滚动深度百分比
    interactions: number; // 页面内交互次数
  };
}
```

### 3.2 用户认证事件

```typescript
// 用户注册
interface UserRegisterEvent {
  event_name: "user_register";
  event_category: "authentication";
  properties: {
    register_method: "phone" | "wechat" | "apple" | "google";
    register_source: "organic" | "ad" | "referral" | "social";
    utm_source?: string;
    utm_medium?: string;
    utm_campaign?: string;
    success: boolean;
    error_code?: string; // 如果注册失败
    time_cost: number; // 注册耗时(秒)
  };
}

// 用户登录
interface UserLoginEvent {
  event_name: "user_login";
  event_category: "authentication";
  properties: {
    login_method: "phone_otp" | "wechat" | "apple" | "google" | "auto";
    success: boolean;
    error_code?: string; // 如果登录失败
    time_cost: number; // 登录耗时(秒)
    is_returning_user: boolean;
    days_since_last_login?: number;
  };
}
```

---

## 4. 会员体系埋点

### 4.1 会员状态跟踪

#### 4.1.1 会员等级变化

```typescript
// 会员等级变更事件
interface MembershipLevelChangeEvent {
  event_name: "membership_level_change";
  event_category: "membership";
  properties: {
    previous_level: "free" | "basic" | "premium" | "lifetime";
    new_level: "free" | "basic" | "premium" | "lifetime";
    change_type: "upgrade" | "downgrade" | "expire" | "cancel";
    change_reason: "purchase" | "expire" | "admin_action" | "promotion";
    days_in_previous_level?: number; // 在上一等级停留天数
    payment_method?: "alipay" | "wechat_pay" | "apple_pay" | "google_pay";
    order_amount?: number; // 订单金额
    discount_amount?: number; // 折扣金额
    promotion_code?: string; // 促销代码
  };
}

// 会员权益使用
interface MembershipBenefitUsageEvent {
  event_name: "membership_benefit_usage";
  event_category: "membership";
  properties: {
    benefit_type: "ai_chat_unlimited" | "voice_call" | "advanced_templates" | 
                  "custom_voice" | "unlimited_image_gen" | "star_river_bonus" | 
                  "ad_free" | "priority_support";
    usage_count: number; // 使用次数
    remaining_quota?: number; // 剩余额度
    membership_level: string;
    is_benefit_exhausted?: boolean; // 权益是否用尽
  };
}
```

#### 4.1.2 会员购买流程

```typescript
// 会员套餐浏览
interface MembershipPlanViewEvent {
  event_name: "membership_plan_view";
  event_category: "membership";
  properties: {
    entry_point: "settings" | "paywall" | "promotion" | "notification";
    plans_shown: string[]; // 展示的套餐列表
    current_membership_level: string;
    days_remaining?: number; // 当前会员剩余天数
    trigger_feature?: string; // 触发查看的功能
  };
}

// 会员购买开始
interface MembershipPurchaseStartEvent {
  event_name: "membership_purchase_start";
  event_category: "membership";
  properties: {
    plan_id: string; // 套餐ID
    plan_type: "weekly" | "monthly" | "quarterly" | "yearly" | "lifetime";
    plan_name: string; // 套餐名称
    original_price: number; // 原价
    actual_price: number; // 实付价格
    discount_percentage?: number; // 折扣百分比
    payment_method: string;
    from_page: string; // 来源页面
    promotion_code?: string;
  };
}

// 会员购买完成
interface MembershipPurchaseCompleteEvent {
  event_name: "membership_purchase_complete";
  event_category: "membership";
  properties: {
    plan_id: string;
    plan_type: string;
    order_id: string; // 订单ID
    transaction_id: string; // 交易ID
    amount_paid: number; // 实际支付金额
    payment_method: string;
    purchase_duration: number; // 购买流程耗时(秒)
    success: boolean;
    error_code?: string; // 支付失败错误码
    previous_membership_level: string;
    new_membership_level: string;
    effective_date: string; // 生效日期
    expiry_date: string; // 到期日期
  };
}
```

### 4.2 会员行为分析

#### 4.2.1 付费转化分析

```typescript
// 付费意向事件
interface PaymentIntentEvent {
  event_name: "payment_intent";
  event_category: "conversion";
  properties: {
    trigger_feature: string; // 触发付费的功能
    trigger_action: string; // 具体触发动作
    paywall_type: "hard" | "soft"; // 付费墙类型
    user_tenure: number; // 用户注册天数
    session_count: number; // 累计会话数
    feature_usage_count: number; // 该功能使用次数
    current_quota_usage: number; // 当前配额使用情况
    shown_plan_options: string[]; // 展示的套餐选项
  };
}

// 付费转化漏斗
interface ConversionFunnelEvent {
  event_name: "conversion_funnel";
  event_category: "conversion";
  properties: {
    funnel_step: "awareness" | "interest" | "consideration" | "purchase" | "retention";
    step_action: string; // 具体动作
    funnel_session_id: string; // 漏斗会话ID
    time_in_step: number; // 在该步骤停留时间
    drop_reason?: "price" | "feature" | "payment_method" | "technical" | "other";
  };
}
```

---

## 5. 星川体系埋点

### 5.1 星川获取与消费

#### 5.1.1 星川抽取事件

```typescript
// 星川抽取事件
interface StarRiverDrawEvent {
  event_name: "star_river_draw";
  event_category: "star_river";
  properties: {
    draw_type: "single" | "ten_draw" | "free_daily";
    cost_star_points: number; // 消耗星点数量
    cost_type: "star_points" | "free_quota" | "membership_bonus";
    result_rarity: "common" | "rare" | "epic" | "legendary";
    result_star_river_id: string; // 获得的星川ID
    result_character_id?: string; // 相关AI角色ID
    user_star_points_before: number; // 抽取前星点余额
    user_star_points_after: number; // 抽取后星点余额
    daily_free_quota_used: number; // 已使用免费次数
    daily_free_quota_total: number; // 每日免费总次数
    membership_bonus_used: boolean; // 是否使用会员奖励
    is_guaranteed?: boolean; // 是否保底
    pity_counter?: number; // 保底计数器
  };
}

// 星川收藏事件
interface StarRiverCollectEvent {
  event_name: "star_river_collect";
  event_category: "star_river";
  properties: {
    star_river_id: string;
    rarity: string;
    character_id?: string;
    source: "draw" | "trade" | "gift" | "reward";
    collection_size_before: number; // 收藏前数量
    collection_size_after: number; // 收藏后数量
    is_duplicate: boolean; // 是否重复获得
    duplicate_reward?: number; // 重复奖励星点
  };
}
```

#### 5.1.2 星川交易事件

```typescript
// 星川交易发起
interface StarRiverTradeStartEvent {
  event_name: "star_river_trade_start";
  event_category: "star_river";
  properties: {
    trade_type: "sell" | "buy";
    star_river_id: string;
    rarity: string;
    listed_price?: number; // 挂牌价格
    market_average_price?: number; // 市场均价
    user_star_points_balance: number;
    listing_duration_hours?: number; // 挂牌时长
  };
}

// 星川交易完成
interface StarRiverTradeCompleteEvent {
  event_name: "star_river_trade_complete";
  event_category: "star_river";
  properties: {
    trade_type: "sell" | "buy";
    star_river_id: string;
    rarity: string;
    final_price: number; // 成交价格
    seller_id: string;
    buyer_id: string;
    platform_fee: number; // 平台手续费
    creator_royalty?: number; // 创作者版税
    seller_revenue: number; // 卖家收入
    trade_duration: number; // 交易耗时(秒)
    user_star_points_before: number;
    user_star_points_after: number;
  };
}

// 星川使用事件
interface StarRiverUsageEvent {
  event_name: "star_river_usage";
  event_category: "star_river";
  properties: {
    star_river_id: string;
    usage_type: "chat_background" | "profile_display" | "share" | "download";
    character_id?: string; // 如果用作聊天背景
    intimacy_boost?: number; // 亲密度提升
    is_premium_feature: boolean; // 是否高级功能
  };
}
```

### 5.2 星川亲密度系统

```typescript
// 亲密度变化事件
interface IntimacyChangeEvent {
  event_name: "intimacy_change";
  event_category: "star_river";
  properties: {
    character_id: string;
    character_name: string;
    previous_intimacy_level: number;
    new_intimacy_level: number;
    intimacy_points_gained: number;
    gain_source: "chat" | "star_river_usage" | "gift" | "daily_bonus";
    total_intimacy_points: number;
    membership_bonus_applied?: boolean;
    next_level_points_required?: number;
    milestone_reached?: string; // 达成的里程碑
  };
}

// 亲密度里程碑事件
interface IntimacyMilestoneEvent {
  event_name: "intimacy_milestone";
  event_category: "star_river";
  properties: {
    character_id: string;
    milestone_type: "level_up" | "special_unlock" | "exclusive_content";
    milestone_value: number | string;
    reward_type?: "star_points" | "star_river" | "special_feature";
    reward_value?: number;
    days_to_achieve: number; // 达成天数
    total_interactions: number; // 总互动次数
  };
}
```

---

## 6. 业务流程埋点

### 6.1 AI对话交互

#### 6.1.1 对话会话管理

```typescript
// 对话开始事件
interface ChatSessionStartEvent {
  event_name: "chat_session_start";
  event_category: "ai_interaction";
  properties: {
    character_id: string;
    character_name: string;
    character_category: string;
    session_type: "new" | "continue";
    previous_session_id?: string;
    time_since_last_chat?: number; // 距离上次对话时间(秒)
    user_membership_level: string;
    intimacy_level: number;
    entry_point: "character_list" | "home_recommendation" | "search" | "notification";
  };
}

// 对话消息事件
interface ChatMessageEvent {
  event_name: "chat_message";
  event_category: "ai_interaction";
  properties: {
    session_id: string;
    character_id: string;
    message_type: "text" | "voice" | "image";
    message_length?: number; // 文本长度或音频时长
    input_method: "keyboard" | "voice" | "image_upload";
    response_time: number; // AI响应时间(ms)
    user_satisfaction?: 1 | 2 | 3 | 4 | 5; // 用户满意度评分
    contains_sensitive_content?: boolean;
    trigger_content_filter?: boolean;
    message_sequence_in_session: number;
    ai_model_used?: string; // 使用的AI模型
    tokens_consumed?: number; // 消耗的token数量
  };
}

// 对话结束事件
interface ChatSessionEndEvent {
  event_name: "chat_session_end";
  event_category: "ai_interaction";
  properties: {
    session_id: string;
    character_id: string;
    session_duration: number; // 会话时长(秒)
    total_messages: number;
    user_messages: number;
    ai_messages: number;
    average_response_time: number;
    end_reason: "user_initiated" | "inactivity" | "quota_exceeded" | "error";
    intimacy_points_gained: number;
    user_satisfaction_rating?: number;
  };
}
```

#### 6.1.2 语音交互

```typescript
// 语音通话事件
interface VoiceCallEvent {
  event_name: "voice_call";
  event_category: "ai_interaction";
  properties: {
    character_id: string;
    call_type: "start" | "end" | "pause" | "resume";
    call_duration?: number; // 通话时长(秒)
    voice_quality: "low" | "medium" | "high";
    user_membership_level: string;
    is_premium_feature: boolean;
    network_type: string;
    audio_interruptions?: number; // 音频中断次数
    user_satisfaction?: number;
  };
}

// 声音复刻事件
interface VoiceCloneEvent {
  event_name: "voice_clone";
  event_category: "ai_interaction";
  properties: {
    clone_type: "create" | "update" | "delete" | "use";
    voice_sample_duration?: number; // 样本时长(秒)
    processing_time?: number; // 处理时间(秒)
    success: boolean;
    error_code?: string;
    clone_quality_score?: number; // 音色质量评分
    user_membership_level: string;
    is_premium_feature: boolean;
  };
}
```

### 6.2 内容创作流程

#### 6.2.1 创作项目管理

```typescript
// 创作开始事件
interface CreationStartEvent {
  event_name: "creation_start";
  event_category: "content_creation";
  properties: {
    creation_type: "character" | "audio" | "story" | "image" | "other";
    template_used?: string; // 使用的模板
    creation_tool: string; // 创作工具
    user_membership_level: string;
    is_premium_template?: boolean;
    entry_point: "creation_center" | "home" | "inspiration";
  };
}

// 创作过程事件
interface CreationProcessEvent {
  event_name: "creation_process";
  event_category: "content_creation";
  properties: {
    creation_id: string;
    action: "edit" | "preview" | "save_draft" | "use_ai_assist" | "add_media";
    time_spent: number; // 操作耗时(秒)
    ai_assistance_used?: boolean;
    media_added_count?: number;
    word_count?: number; // 文字创作字数
    revision_count: number; // 修订次数
  };
}

// 创作完成事件
interface CreationCompleteEvent {
  event_name: "creation_complete";
  event_category: "content_creation";
  properties: {
    creation_id: string;
    creation_type: string;
    total_creation_time: number; // 总创作时间(秒)
    total_revisions: number;
    ai_assistance_usage: number; // AI辅助使用次数
    final_word_count?: number;
    media_count?: number;
    publish_immediately: boolean;
    is_public: boolean;
    tags_added: string[];
    estimated_quality_score?: number;
  };
}
```

#### 6.2.2 内容发布与互动

```typescript
// 内容发布事件
interface ContentPublishEvent {
  event_name: "content_publish";
  event_category: "content_creation";
  properties: {
    content_id: string;
    content_type: string;
    publish_platform: "internal" | "social_share" | "export";
    visibility: "public" | "friends" | "private";
    content_length?: number;
    media_count?: number;
    tags: string[];
    expected_audience_size?: number;
    monetization_enabled?: boolean;
  };
}

// 内容互动事件
interface ContentInteractionEvent {
  event_name: "content_interaction";
  event_category: "social";
  properties: {
    content_id: string;
    content_type: string;
    content_creator_id: string;
    interaction_type: "like" | "comment" | "share" | "collect" | "report";
    comment_length?: number; // 评论长度
    share_platform?: string; // 分享平台
    is_creator_interaction: boolean; // 是否是创作者本人互动
  };
}
```

### 6.3 音频播放行为

#### 6.3.1 音频播放跟踪

```typescript
// 音频播放事件
interface AudioPlayEvent {
  event_name: "audio_play";
  event_category: "audio";
  properties: {
    audio_id: string;
    audio_title: string;
    creator_id: string;
    audio_category: string;
    audio_duration: number; // 音频总时长(秒)
    play_source: "recommendation" | "search" | "playlist" | "direct_link";
    play_position: number; // 开始播放位置(秒)
    user_membership_level: string;
    is_offline_play: boolean; // 是否离线播放
    audio_quality: "low" | "medium" | "high";
  };
}

// 音频播放进度事件
interface AudioProgressEvent {
  event_name: "audio_progress";
  event_category: "audio";
  properties: {
    audio_id: string;
    current_position: number; // 当前播放位置(秒)
    total_duration: number;
    progress_percentage: number; // 播放进度百分比
    play_speed: number; // 播放倍速
    milestone: "25%" | "50%" | "75%" | "100%"; // 播放里程碑
  };
}

// 音频播放完成事件
interface AudioCompleteEvent {
  event_name: "audio_complete";
  event_category: "audio";
  properties: {
    audio_id: string;
    total_listen_time: number; // 实际收听时长(秒)
    completion_rate: number; // 完成度百分比
    skip_count: number; // 跳跃次数
    pause_count: number; // 暂停次数
    replay_count: number; // 重播次数
    user_rating?: number; // 用户评分
    listening_satisfaction?: number;
  };
}
```

---

## 7. 用户行为分析

### 7.1 用户生命周期跟踪

#### 7.1.1 用户成长阶段

```typescript
// 用户成长阶段变化
interface UserGrowthStageEvent {
  event_name: "user_growth_stage";
  event_category: "user_lifecycle";
  properties: {
    previous_stage: "new" | "exploring" | "engaged" | "power_user" | "at_risk" | "churned";
    new_stage: "new" | "exploring" | "engaged" | "power_user" | "at_risk" | "churned";
    stage_criteria: string; // 判断标准
    days_in_previous_stage: number;
    trigger_action: string; // 触发阶段变化的行为
    user_tenure_days: number; // 用户注册天数
    total_sessions: number;
    total_time_spent: number; // 总使用时长(秒)
    feature_adoption_score: number; // 功能采用度评分
  };
}

// 用户参与度评分
interface UserEngagementScoreEvent {
  event_name: "user_engagement_score";
  event_category: "user_lifecycle";
  properties: {
    current_score: number; // 当前参与度评分(0-100)
    previous_score?: number;
    score_change: number; // 评分变化
    calculation_period: "daily" | "weekly" | "monthly";
    contributing_factors: {
      session_frequency: number;
      session_duration: number;
      feature_usage_diversity: number;
      content_creation: number;
      social_interaction: number;
      payment_behavior: number;
    };
    risk_level: "low" | "medium" | "high"; // 流失风险等级
  };
}
```

#### 7.1.2 留存分析

```typescript
// 用户留存事件
interface UserRetentionEvent {
  event_name: "user_retention";
  event_category: "retention";
  properties: {
    retention_type: "day_1" | "day_3" | "day_7" | "day_14" | "day_30" | "day_90";
    is_retained: boolean;
    days_since_registration: number;
    days_since_last_session: number;
    total_sessions_in_period: number;
    total_time_in_period: number; // 周期内总使用时长
    key_actions_completed: string[]; // 完成的关键行为
    membership_status: string;
    push_notifications_received: number; // 收到的推送通知数
    push_notification_opens: number; // 打开的推送通知数
  };
}

// 用户回访事件
interface UserReturnEvent {
  event_name: "user_return";
  event_category: "retention";
  properties: {
    return_type: "organic" | "push_notification" | "email" | "social_share" | "ad";
    days_inactive: number; // 不活跃天数
    return_trigger?: string; // 回访触发因素
    previous_churn_risk?: "low" | "medium" | "high";
    comeback_campaign_id?: string; // 召回活动ID
    first_action_after_return: string; // 回访后首个行为
  };
}
```

### 7.2 功能使用分析

#### 7.2.1 功能采用度

```typescript
// 功能首次使用
interface FeatureFirstUseEvent {
  event_name: "feature_first_use";
  event_category: "feature_adoption";
  properties: {
    feature_name: string;
    feature_category: "core" | "social" | "creation" | "premium" | "experimental";
    days_since_registration: number; // 注册后多少天首次使用
    sessions_since_registration: number; // 注册后多少次会话首次使用
    discovery_method: "navigation" | "recommendation" | "tutorial" | "accident" | "promotion";
    user_membership_level: string;
    is_premium_feature: boolean;
    tutorial_completed?: boolean; // 是否完成了功能教程
  };
}

// 功能使用频次
interface FeatureUsageFrequencyEvent {
  event_name: "feature_usage_frequency";
  event_category: "feature_adoption";
  properties: {
    feature_name: string;
    usage_count_this_session: number;
    usage_count_today: number;
    usage_count_this_week: number;
    usage_count_this_month: number;
    average_session_usage: number; // 平均每次会话使用次数
    usage_trend: "increasing" | "stable" | "decreasing"; // 使用趋势
    feature_stickiness: number; // 功能粘性评分(0-1)
  };
}

// 功能放弃事件
interface FeatureAbandonmentEvent {
  event_name: "feature_abandonment";
  event_category: "feature_adoption";
  properties: {
    feature_name: string;
    abandonment_stage: "initial_try" | "learning" | "regular_use";
    usage_count_before_abandon: number;
    days_used: number; // 使用该功能的天数
    last_usage_days_ago: number; // 最后使用距今天数
    abandonment_reason?: "complexity" | "lack_value" | "better_alternative" | "technical_issues";
    user_feedback?: string;
  };
}
```

---

## 8. 技术实现方案

### 8.1 Flutter客户端实现

#### 8.1.1 埋点SDK集成

```dart
// 埋点服务类
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // 神策分析实例
  late SensorsAnalyticsFlutterPlugin _sensorsAnalytics;
  // 友盟统计实例
  late UmengCommonSdk _umengAnalytics;

  /// 初始化埋点服务
  Future<void> initialize() async {
    // 初始化神策分析
    await _sensorsAnalytics.init(
      serverUrl: 'YOUR_SENSORS_SERVER_URL',
      debugMode: kDebugMode,
    );

    // 初始化友盟统计
    await _umengAnalytics.initCommon(
      androidKey: 'YOUR_UMENG_ANDROID_KEY',
      iosKey: 'YOUR_UMENG_IOS_KEY',
      channel: 'default',
    );

    // 设置用户属性
    await _setUserProperties();
  }

  /// 跟踪事件
  Future<void> track(String eventName, Map<String, dynamic> properties) async {
    // 添加通用属性
    final enrichedProperties = await _enrichProperties(properties);
    
    try {
      // 神策分析埋点
      await _sensorsAnalytics.track(eventName, enrichedProperties);
      
      // 友盟统计埋点
      await _umengAnalytics.onEvent(eventName, enrichedProperties);
      
      // 本地缓存(用于离线上报)
      await _cacheEventLocally(eventName, enrichedProperties);
      
      // 开发环境打印日志
      if (kDebugMode) {
        print('Analytics Event: $eventName');
        print('Properties: $enrichedProperties');
      }
    } catch (e) {
      print('Analytics tracking error: $e');
      // 错误处理和重试机制
      await _handleTrackingError(eventName, enrichedProperties, e);
    }
  }

  /// 设置用户属性
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await _sensorsAnalytics.profileSet(properties);
    await _umengAnalytics.onProfileSignIn(properties['user_id']?.toString() ?? '');
  }

  /// 页面访问跟踪
  Future<void> trackPageView(String pageName, {Map<String, dynamic>? properties}) async {
    final pageProperties = {
      'page_name': pageName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?properties,
    };

    await track('page_view', pageProperties);
    
    // 神策自动页面跟踪
    await _sensorsAnalytics.trackViewScreen(pageName, properties);
  }

  /// 丰富事件属性
  Future<Map<String, dynamic>> _enrichProperties(Map<String, dynamic> properties) async {
    final deviceInfo = await _getDeviceInfo();
    final userInfo = await _getCurrentUserInfo();
    final appInfo = await _getAppInfo();

    return {
      ...properties,
      // 设备信息
      'platform': deviceInfo['platform'],
      'os_version': deviceInfo['os_version'],
      'device_model': deviceInfo['device_model'],
      'screen_resolution': deviceInfo['screen_resolution'],
      'network_type': deviceInfo['network_type'],
      
      // 用户信息
      'user_id': userInfo['user_id'],
      'membership_level': userInfo['membership_level'],
      'user_tenure_days': userInfo['tenure_days'],
      
      // 应用信息
      'app_version': appInfo['app_version'],
      'build_number': appInfo['build_number'],
      
      // 会话信息
      'session_id': _getCurrentSessionId(),
      'timestamp': DateTime.now().toIso8601String(),
      
      // 实验信息
      'ab_test_groups': await _getABTestGroups(),
    };
  }

  /// 本地事件缓存
  Future<void> _cacheEventLocally(String eventName, Map<String, dynamic> properties) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedEvents = prefs.getStringList('cached_events') ?? [];
    
    final eventData = {
      'event_name': eventName,
      'properties': properties,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    cachedEvents.add(json.encode(eventData));
    await prefs.setStringList('cached_events', cachedEvents);
    
    // 定期清理缓存
    if (cachedEvents.length > 1000) {
      await _uploadCachedEvents();
    }
  }

  /// 上传缓存事件
  Future<void> _uploadCachedEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedEvents = prefs.getStringList('cached_events') ?? [];
    
    if (cachedEvents.isEmpty) return;
    
    try {
      // 批量上传到服务器
      await _batchUploadEvents(cachedEvents);
      
      // 清理本地缓存
      await prefs.remove('cached_events');
    } catch (e) {
      print('Failed to upload cached events: $e');
    }
  }
}
```

#### 8.1.2 事件跟踪扩展

```dart
// 专门的事件跟踪类
class EventTracker {
  static final AnalyticsService _analytics = AnalyticsService();

  /// 应用生命周期事件
  static Future<void> trackAppLaunch({
    required String launchType,
    int? previousSessionDuration,
    int? timeSinceLastSession,
    required bool isFirstLaunch,
  }) async {
    await _analytics.track('app_launch', {
      'launch_type': launchType,
      'previous_session_duration': previousSessionDuration,
      'time_since_last_session': timeSinceLastSession,
      'is_first_launch': isFirstLaunch,
    });
  }

  /// 会员相关事件
  static Future<void> trackMembershipLevelChange({
    required String previousLevel,
    required String newLevel,
    required String changeType,
    String? paymentMethod,
    double? orderAmount,
  }) async {
    await _analytics.track('membership_level_change', {
      'previous_level': previousLevel,
      'new_level': newLevel,
      'change_type': changeType,
      'payment_method': paymentMethod,
      'order_amount': orderAmount,
    });
  }

  /// 星川抽取事件
  static Future<void> trackStarRiverDraw({
    required String drawType,
    required int costStarPoints,
    required String resultRarity,
    required String resultStarRiverId,
    required int userStarPointsBefore,
    required int userStarPointsAfter,
  }) async {
    await _analytics.track('star_river_draw', {
      'draw_type': drawType,
      'cost_star_points': costStarPoints,
      'result_rarity': resultRarity,
      'result_star_river_id': resultStarRiverId,
      'user_star_points_before': userStarPointsBefore,
      'user_star_points_after': userStarPointsAfter,
    });
  }

  /// AI对话事件
  static Future<void> trackChatMessage({
    required String sessionId,
    required String characterId,
    required String messageType,
    int? messageLength,
    required String inputMethod,
    required int responseTime,
    required int messageSequence,
  }) async {
    await _analytics.track('chat_message', {
      'session_id': sessionId,
      'character_id': characterId,
      'message_type': messageType,
      'message_length': messageLength,
      'input_method': inputMethod,
      'response_time': responseTime,
      'message_sequence_in_session': messageSequence,
    });
  }

  /// 音频播放事件
  static Future<void> trackAudioPlay({
    required String audioId,
    required String audioTitle,
    required String creatorId,
    required String playSource,
    required int audioDuration,
    required bool isOfflinePlay,
  }) async {
    await _analytics.track('audio_play', {
      'audio_id': audioId,
      'audio_title': audioTitle,
      'creator_id': creatorId,
      'play_source': playSource,
      'audio_duration': audioDuration,
      'is_offline_play': isOfflinePlay,
    });
  }
}
```

### 8.2 Supabase后端实现

#### 8.2.1 事件接收与存储

```sql
-- 创建事件接收函数
CREATE OR REPLACE FUNCTION receive_analytics_event(
  p_user_id UUID,
  p_session_id VARCHAR(255),
  p_event_name VARCHAR(255),
  p_event_category VARCHAR(100),
  p_event_properties JSONB DEFAULT '{}',
  p_user_properties JSONB DEFAULT '{}',
  p_device_info JSONB DEFAULT '{}',
  p_app_version VARCHAR(50) DEFAULT NULL,
  p_platform VARCHAR(50) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  event_id UUID;
BEGIN
  -- 插入事件记录
  INSERT INTO user_events (
    user_id, session_id, event_name, event_category,
    event_properties, user_properties, device_info,
    app_version, platform
  ) VALUES (
    p_user_id, p_session_id, p_event_name, p_event_category,
    p_event_properties, p_user_properties, p_device_info,
    p_app_version, p_platform
  ) RETURNING id INTO event_id;
  
  -- 更新用户属性表
  INSERT INTO user_attributes (user_id, last_seen_at, total_events)
  VALUES (p_user_id, NOW(), 1)
  ON CONFLICT (user_id) DO UPDATE SET
    last_seen_at = NOW(),
    total_events = user_attributes.total_events + 1;
  
  -- 更新会话信息
  INSERT INTO user_sessions (user_id, session_id, start_time, event_count)
  VALUES (p_user_id, p_session_id, NOW(), 1)
  ON CONFLICT (session_id) DO UPDATE SET
    event_count = user_sessions.event_count + 1,
    end_time = NOW();
  
  RETURN event_id;
END;
$$ LANGUAGE plpgsql;

-- 创建实时数据处理函数
CREATE OR REPLACE FUNCTION process_analytics_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- 根据事件类型执行特定逻辑
  CASE NEW.event_name
    WHEN 'membership_purchase_complete' THEN
      -- 更新用户会员状态
      UPDATE user_attributes SET
        membership_level = NEW.event_properties->>'new_membership_level',
        membership_start_date = NOW(),
        membership_end_date = (NOW() + INTERVAL '1 month')
      WHERE user_id = NEW.user_id;
    
    WHEN 'star_river_draw' THEN
      -- 更新用户星川数量
      UPDATE user_attributes SET
        star_river_count = COALESCE(star_river_count, 0) + 1
      WHERE user_id = NEW.user_id;
    
    WHEN 'chat_session_end' THEN
      -- 更新总聊天时长
      UPDATE user_attributes SET
        total_chat_duration = COALESCE(total_chat_duration, 0) + 
          COALESCE((NEW.event_properties->>'session_duration')::INTEGER, 0)
      WHERE user_id = NEW.user_id;
  END CASE;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER analytics_event_trigger
  AFTER INSERT ON user_events
  FOR EACH ROW
  EXECUTE FUNCTION process_analytics_trigger();
```

#### 8.2.2 实时指标计算

```sql
-- 创建实时指标计算函数
CREATE OR REPLACE FUNCTION calculate_real_time_metrics()
RETURNS TABLE (
  metric_name VARCHAR,
  metric_value DECIMAL,
  calculation_time TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    'dau'::VARCHAR as metric_name,
    COUNT(DISTINCT user_id)::DECIMAL as metric_value,
    NOW() as calculation_time
  FROM user_events
  WHERE DATE(timestamp) = CURRENT_DATE
  
  UNION ALL
  
  SELECT 
    'active_sessions'::VARCHAR,
    COUNT(DISTINCT session_id)::DECIMAL,
    NOW()
  FROM user_sessions
  WHERE start_time >= NOW() - INTERVAL '1 hour'
  
  UNION ALL
  
  SELECT 
    'membership_conversion_rate'::VARCHAR,
    (COUNT(CASE WHEN event_name = 'membership_purchase_complete' THEN 1 END) * 100.0 / 
     NULLIF(COUNT(CASE WHEN event_name = 'membership_plan_view' THEN 1 END), 0))::DECIMAL,
    NOW()
  FROM user_events
  WHERE DATE(timestamp) = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- 创建用户行为汇总视图
CREATE OR REPLACE VIEW user_behavior_summary AS
SELECT 
  ua.user_id,
  ua.membership_level,
  ua.total_sessions,
  ua.total_events,
  ua.first_seen_at,
  ua.last_seen_at,
  EXTRACT(EPOCH FROM (ua.last_seen_at - ua.first_seen_at)) / 86400 as tenure_days,
  
  -- 活跃度指标
  COUNT(CASE WHEN ue.event_category = 'ai_interaction' THEN 1 END) as ai_interactions,
  COUNT(CASE WHEN ue.event_category = 'audio' THEN 1 END) as audio_interactions,
  COUNT(CASE WHEN ue.event_category = 'star_river' THEN 1 END) as star_river_interactions,
  COUNT(CASE WHEN ue.event_category = 'membership' THEN 1 END) as membership_interactions,
  
  -- 最近活动
  MAX(CASE WHEN ue.event_category = 'ai_interaction' THEN ue.timestamp END) as last_ai_interaction,
  MAX(CASE WHEN ue.event_category = 'audio' THEN ue.timestamp END) as last_audio_interaction,
  MAX(CASE WHEN ue.event_category = 'star_river' THEN ue.timestamp END) as last_star_river_interaction,
  
  -- 用户分群
  CASE 
    WHEN ua.total_sessions >= 30 AND ua.membership_level != 'free' THEN 'power_user'
    WHEN ua.total_sessions >= 10 AND ua.membership_level != 'free' THEN 'engaged_user'
    WHEN ua.total_sessions >= 5 THEN 'regular_user'
    WHEN ua.total_sessions >= 1 THEN 'new_user'
    ELSE 'inactive_user'
  END as user_segment

FROM user_attributes ua
LEFT JOIN user_events ue ON ua.user_id = ue.user_id
WHERE ue.timestamp >= NOW() - INTERVAL '30 days'
GROUP BY ua.user_id, ua.membership_level, ua.total_sessions, ua.total_events, 
         ua.first_seen_at, ua.last_seen_at;
```

---

## 9. 数据指标体系

### 9.1 核心KPI指标

#### 9.1.1 用户增长指标

```sql
-- DAU/MAU/WAU 计算
CREATE OR REPLACE VIEW growth_metrics AS
SELECT 
  -- 日活跃用户
  (SELECT COUNT(DISTINCT user_id) 
   FROM user_events 
   WHERE DATE(timestamp) = CURRENT_DATE) as dau,
  
  -- 周活跃用户  
  (SELECT COUNT(DISTINCT user_id) 
   FROM user_events 
   WHERE timestamp >= DATE_TRUNC('week', CURRENT_DATE)) as wau,
  
  -- 月活跃用户
  (SELECT COUNT(DISTINCT user_id) 
   FROM user_events 
   WHERE timestamp >= DATE_TRUNC('month', CURRENT_DATE)) as mau,
  
  -- 新用户注册
  (SELECT COUNT(*) 
   FROM user_attributes 
   WHERE DATE(first_seen_at) = CURRENT_DATE) as new_users_today,
  
  -- 用户留存率(次日留存)
  (SELECT 
    COUNT(CASE WHEN return_users.user_id IS NOT NULL THEN 1 END) * 100.0 / 
    NULLIF(COUNT(new_users.user_id), 0)
   FROM 
    (SELECT user_id FROM user_attributes WHERE DATE(first_seen_at) = CURRENT_DATE - INTERVAL '1 day') new_users
   LEFT JOIN 
    (SELECT DISTINCT user_id FROM user_events WHERE DATE(timestamp) = CURRENT_DATE) return_users
   ON new_users.user_id = return_users.user_id) as day1_retention_rate;
```

#### 9.1.2 商业化指标

```sql
-- 商业化关键指标
CREATE OR REPLACE VIEW monetization_metrics AS
SELECT 
  -- 付费用户数
  COUNT(DISTINCT user_id) FILTER (WHERE membership_level != 'free') as paying_users,
  
  -- 付费转化率
  COUNT(DISTINCT user_id) FILTER (WHERE membership_level != 'free') * 100.0 / 
  NULLIF(COUNT(DISTINCT user_id), 0) as conversion_rate,
  
  -- ARPU (Average Revenue Per User)
  AVG(total_spent) as arpu,
  
  -- ARPPU (Average Revenue Per Paying User)
  AVG(total_spent) FILTER (WHERE membership_level != 'free') as arppu,
  
  -- 会员分布
  COUNT(*) FILTER (WHERE membership_level = 'basic') as basic_members,
  COUNT(*) FILTER (WHERE membership_level = 'premium') as premium_members,
  COUNT(*) FILTER (WHERE membership_level = 'lifetime') as lifetime_members,
  
  -- LTV估算 (简化版本)
  AVG(total_spent * EXTRACT(EPOCH FROM (COALESCE(membership_end_date, NOW()) - membership_start_date)) / 86400 / 30) 
  FILTER (WHERE membership_level != 'free') as estimated_ltv

FROM user_attributes
WHERE last_seen_at >= NOW() - INTERVAL '30 days';
```

### 9.2 功能使用指标

#### 9.2.1 核心功能使用率

```sql
-- 功能使用情况分析
CREATE OR REPLACE VIEW feature_usage_metrics AS
SELECT 
  event_category,
  event_name,
  COUNT(*) as total_events,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(DISTINCT session_id) as unique_sessions,
  
  -- 使用率 (相对于总用户数)
  COUNT(DISTINCT user_id) * 100.0 / 
  (SELECT COUNT(DISTINCT user_id) FROM user_events WHERE timestamp >= NOW() - INTERVAL '7 days') as adoption_rate,
  
  -- 平均每用户使用次数
  COUNT(*)::DECIMAL / NULLIF(COUNT(DISTINCT user_id), 0) as avg_usage_per_user,
  
  -- 功能粘性 (使用该功能的用户占DAU的比例)
  COUNT(DISTINCT user_id) * 100.0 / 
  (SELECT COUNT(DISTINCT user_id) FROM user_events WHERE DATE(timestamp) = CURRENT_DATE) as stickiness_rate

FROM user_events
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY event_category, event_name
ORDER BY total_events DESC;
```

#### 9.2.2 会员体系指标

```sql
-- 会员体系详细指标
CREATE OR REPLACE VIEW membership_detailed_metrics AS
WITH membership_funnel AS (
  SELECT 
    COUNT(CASE WHEN event_name = 'membership_plan_view' THEN 1 END) as plan_views,
    COUNT(CASE WHEN event_name = 'membership_purchase_start' THEN 1 END) as purchase_starts,
    COUNT(CASE WHEN event_name = 'membership_purchase_complete' AND 
               event_properties->>'success' = 'true' THEN 1 END) as successful_purchases,
    COUNT(CASE WHEN event_name = 'membership_purchase_complete' AND 
               event_properties->>'success' = 'false' THEN 1 END) as failed_purchases
  FROM user_events
  WHERE event_category = 'membership' 
    AND timestamp >= NOW() - INTERVAL '30 days'
)
SELECT 
  *,
  -- 转化漏斗计算
  purchase_starts * 100.0 / NULLIF(plan_views, 0) as view_to_start_rate,
  successful_purchases * 100.0 / NULLIF(purchase_starts, 0) as start_to_complete_rate,
  successful_purchases * 100.0 / NULLIF(plan_views, 0) as overall_conversion_rate,
  
  -- 支付成功率
  successful_purchases * 100.0 / 
  NULLIF(successful_purchases + failed_purchases, 0) as payment_success_rate

FROM membership_funnel;
```

#### 9.2.3 星川体系指标

```sql
-- 星川体系核心指标
CREATE OR REPLACE VIEW star_river_metrics AS
WITH star_river_stats AS (
  SELECT 
    COUNT(CASE WHEN event_name = 'star_river_draw' THEN 1 END) as total_draws,
    COUNT(CASE WHEN event_name = 'star_river_draw' AND 
               event_properties->>'draw_type' = 'free_daily' THEN 1 END) as free_draws,
    COUNT(CASE WHEN event_name = 'star_river_draw' AND 
               event_properties->>'draw_type' IN ('single', 'ten_draw') THEN 1 END) as paid_draws,
    
    COUNT(CASE WHEN event_name = 'star_river_trade_complete' THEN 1 END) as trades_completed,
    SUM((event_properties->>'final_price')::INTEGER) FILTER (WHERE event_name = 'star_river_trade_complete') as total_trade_volume,
    
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'star_river_draw') as active_collectors,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'star_river_trade_complete') as active_traders,
    
    AVG((event_properties->>'cost_star_points')::INTEGER) FILTER (WHERE event_name = 'star_river_draw' AND event_properties->>'draw_type' != 'free_daily') as avg_draw_cost,
    AVG((event_properties->>'final_price')::INTEGER) FILTER (WHERE event_name = 'star_river_trade_complete') as avg_trade_price

  FROM user_events
  WHERE event_category = 'star_river'
    AND timestamp >= NOW() - INTERVAL '30 days'
)
SELECT 
  *,
  -- 付费抽取率
  paid_draws * 100.0 / NULLIF(total_draws, 0) as paid_draw_rate,
  
  -- 交易参与率
  active_traders * 100.0 / NULLIF(active_collectors, 0) as trader_participation_rate,
  
  -- 人均抽取次数
  total_draws::DECIMAL / NULLIF(active_collectors, 0) as avg_draws_per_user,
  
  -- 人均交易额
  total_trade_volume::DECIMAL / NULLIF(active_traders, 0) as avg_trade_volume_per_trader

FROM star_river_stats;
```

---

## 10. 隐私合规

### 10.1 数据收集原则

#### 10.1.1 最小化原则

**收集范围**：
- 仅收集为提供服务所必需的数据
- 明确告知用户数据收集的目的和用途
- 用户可选择性地提供非必要信息
- 定期审查和清理不必要的数据收集

**数据分类**：
```typescript
interface DataClassification {
  necessary: {
    description: "提供核心功能必需的数据";
    examples: ["用户ID", "会话信息", "基础设备信息"];
    retention_period: "用户注销后30天";
  };
  
  functional: {
    description: "改善用户体验的功能性数据";
    examples: ["使用偏好", "功能使用统计", "性能数据"];
    retention_period: "2年";
    user_control: "用户可选择关闭";
  };
  
  analytical: {
    description: "产品优化和分析数据";
    examples: ["行为路径", "使用时长", "功能点击率"];
    retention_period: "1年";
    anonymization: "去标识化处理";
  };
  
  marketing: {
    description: "营销和推荐相关数据";
    examples: ["广告互动", "推荐点击", "转化数据"];
    retention_period: "6个月";
    user_control: "用户可完全关闭";
  };
}
```

#### 10.1.2 透明度原则

**隐私政策要求**：
- 清楚描述收集的数据类型和用途
- 说明数据处理的法律依据
- 明确数据保留期限
- 提供用户权利行使方式

**用户通知机制**：
```dart
// 隐私设置页面
class PrivacySettingsPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('隐私设置')),
      body: Column(
        children: [
          // 数据收集开关
          SwitchListTile(
            title: Text('功能改进数据收集'),
            subtitle: Text('帮助我们改善App功能和用户体验'),
            value: _functionalDataEnabled,
            onChanged: (value) => _updateDataCollectionSetting('functional', value),
          ),
          
          SwitchListTile(
            title: Text('个性化推荐'),
            subtitle: Text('基于您的使用习惯提供个性化内容推荐'),
            value: _personalizationEnabled,
            onChanged: (value) => _updateDataCollectionSetting('personalization', value),
          ),
          
          SwitchListTile(
            title: Text('营销分析'),
            subtitle: Text('用于广告效果分析和产品营销优化'),
            value: _marketingAnalyticsEnabled,
            onChanged: (value) => _updateDataCollectionSetting('marketing', value),
          ),
          
          // 数据下载和删除
          ListTile(
            title: Text('下载我的数据'),
            subtitle: Text('获取您的个人数据副本'),
            trailing: Icon(Icons.download),
            onTap: _requestDataExport,
          ),
          
          ListTile(
            title: Text('删除我的账户'),
            subtitle: Text('永久删除您的账户和所有数据'),
            trailing: Icon(Icons.delete),
            onTap: _requestAccountDeletion,
          ),
        ],
      ),
    );
  }
}
```

### 10.2 数据安全措施

#### 10.2.1 数据加密和传输

```dart
// 数据安全服务
class DataSecurityService {
  static const String _encryptionKey = 'YOUR_ENCRYPTION_KEY';
  
  /// 敏感数据加密
  static String encryptSensitiveData(String data) {
    final encrypter = Encrypter(AES(Key.fromBase64(_encryptionKey)));
    final encrypted = encrypter.encrypt(data);
    return encrypted.base64;
  }
  
  /// 数据去标识化处理
  static Map<String, dynamic> anonymizeUserData(Map<String, dynamic> userData) {
    final anonymizedData = Map<String, dynamic>.from(userData);
    
    // 移除直接标识符
    anonymizedData.remove('user_id');
    anonymizedData.remove('phone');
    anonymizedData.remove('email');
    
    // 替换为匿名标识符
    anonymizedData['anonymous_id'] = _generateAnonymousId();
    
    // 模糊化敏感信息
    if (anonymizedData.containsKey('birthday')) {
      final birthday = DateTime.parse(anonymizedData['birthday']);
      anonymizedData['age_group'] = _getAgeGroup(birthday);
      anonymizedData.remove('birthday');
    }
    
    if (anonymizedData.containsKey('location')) {
      anonymizedData['region'] = _getRegionFromLocation(anonymizedData['location']);
      anonymizedData.remove('location');
    }
    
    return anonymizedData;
  }
  
  /// 数据传输安全
  static Map<String, String> getSecureHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'StarFun-App/1.0',
      'X-Request-Signature': _generateRequestSignature(),
      'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}
```

#### 10.2.2 访问控制和审计

```sql
-- 数据访问审计表
CREATE TABLE data_access_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    admin_user_id UUID,
    access_type VARCHAR(50), -- 'view', 'export', 'delete', 'modify'
    data_category VARCHAR(100), -- 'profile', 'events', 'analytics'
    access_reason TEXT,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 数据保留策略执行函数
CREATE OR REPLACE FUNCTION execute_data_retention_policy()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER := 0;
BEGIN
  -- 删除超过保留期的分析事件
  DELETE FROM user_events 
  WHERE event_category = 'analytical' 
    AND timestamp < NOW() - INTERVAL '1 year';
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- 删除超过保留期的营销数据
  DELETE FROM user_events 
  WHERE event_category = 'marketing' 
    AND timestamp < NOW() - INTERVAL '6 months';
  GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
  
  -- 匿名化长期保留的数据
  UPDATE user_events SET
    user_id = NULL,
    user_properties = '{}'
  WHERE timestamp < NOW() - INTERVAL '2 years'
    AND user_id IS NOT NULL;
  
  -- 记录清理日志
  INSERT INTO data_retention_log (cleaned_records, execution_time)
  VALUES (deleted_count, NOW());
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 创建定时任务执行数据保留策略
SELECT cron.schedule('data-retention-cleanup', '0 2 * * 0', 'SELECT execute_data_retention_policy();');
```

### 10.3 用户权利保障

#### 10.3.1 数据主体权利

```dart
// 用户数据权利服务
class UserDataRightsService {
  static final SupabaseService _supabase = SupabaseService.instance;
  
  /// 数据导出请求
  static Future<String> requestDataExport(String userId) async {
    try {
      // 收集用户所有数据
      final userData = await _collectUserData(userId);
      
      // 生成导出文件
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profile_data': userData['profile'],
        'usage_analytics': userData['analytics'],
        'content_data': userData['content'],
        'transaction_history': userData['transactions'],
      };
      
      // 上传到临时存储
      final exportFile = await _generateExportFile(exportData);
      final fileUrl = await _supabase.uploadFile(
        bucket: 'data-exports',
        fileName: 'user_data_export_${userId}_${DateTime.now().millisecondsSinceEpoch}.json',
        fileBytes: utf8.encode(jsonEncode(exportData)),
        contentType: 'application/json',
      );
      
      // 记录导出请求
      await _recordDataExportRequest(userId, fileUrl);
      
      return fileUrl;
    } catch (e) {
      throw Exception('数据导出失败: $e');
    }
  }
  
  /// 账户删除请求
  static Future<void> requestAccountDeletion(String userId) async {
    try {
      // 标记账户为待删除状态
      await _supabase.client
          .from('user_attributes')
          .update({
            'deletion_requested_at': DateTime.now().toIso8601String(),
            'account_status': 'pending_deletion'
          })
          .eq('user_id', userId);
      
      // 停用所有会员服务
      await _supabase.client
          .from('user_attributes')
          .update({
            'membership_level': 'free',
            'membership_end_date': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId);
      
      // 创建删除任务
      await _scheduleAccountDeletion(userId);
      
      // 发送确认邮件
      await _sendDeletionConfirmationEmail(userId);
      
    } catch (e) {
      throw Exception('账户删除请求失败: $e');
    }
  }
  
  /// 数据更正请求
  static Future<void> requestDataCorrection(String userId, Map<String, dynamic> corrections) async {
    try {
      // 验证更正数据的合法性
      final validatedCorrections = await _validateDataCorrections(corrections);
      
      // 创建数据更正请求
      await _supabase.client.from('data_correction_requests').insert({
        'user_id': userId,
        'requested_changes': validatedCorrections,
        'status': 'pending_review',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // 通知管理员审核
      await _notifyAdminForDataCorrection(userId, validatedCorrections);
      
    } catch (e) {
      throw Exception('数据更正请求失败: $e');
    }
  }
}
```

---

## 附录

### A. 事件字典

#### A.1 完整事件列表

| 事件名称 | 事件分类 | 描述 | 关键属性 |
|----------|----------|------|----------|
| app_launch | lifecycle | 应用启动 | launch_type, is_first_launch |
| app_exit | lifecycle | 应用退出 | session_duration, exit_type |
| page_view | navigation | 页面浏览 | page_name, load_time |
| user_register | authentication | 用户注册 | register_method, success |
| user_login | authentication | 用户登录 | login_method, success |
| membership_level_change | membership | 会员等级变化 | previous_level, new_level |
| membership_purchase_complete | membership | 会员购买完成 | plan_type, amount_paid |
| star_river_draw | star_river | 星川抽取 | draw_type, result_rarity |
| star_river_trade_complete | star_river | 星川交易完成 | final_price, trade_type |
| chat_message | ai_interaction | AI对话消息 | character_id, message_type |
| audio_play | audio | 音频播放 | audio_id, play_source |
| content_publish | content_creation | 内容发布 | content_type, visibility |
| social_like | social | 点赞行为 | target_type, target_id |

### B. 数据字典

#### B.1 用户属性字段

| 字段名 | 数据类型 | 描述 | 示例值 |
|--------|----------|------|--------|
| user_id | UUID | 用户唯一标识 | 550e8400-e29b-41d4-a716-446655440000 |
| membership_level | VARCHAR(50) | 会员等级 | free, basic, premium, lifetime |
| total_sessions | INTEGER | 总会话数 | 127 |
| total_events | INTEGER | 总事件数 | 1548 |
| star_points_balance | INTEGER | 星点余额 | 2500 |
| star_river_count | INTEGER | 星川收藏数量 | 45 |

### C. 隐私合规检查清单

- [ ] 数据收集最小化原则落实
- [ ] 用户同意机制实现
- [ ] 数据传输加密配置
- [ ] 数据保留期限设置
- [ ] 用户权利行使功能
- [ ] 数据泄露应急预案
- [ ] 第三方SDK合规审查
- [ ] 跨境数据传输合规

### D. 技术实现清单

- [ ] Flutter埋点SDK集成
- [ ] Supabase后端函数部署
- [ ] 实时数据处理配置
- [ ] 数据可视化面板
- [ ] 自动化报表生成
- [ ] 异常监控告警
- [ ] 数据质量检验
- [ ] 性能优化配置

---

> 本文档将根据产品迭代和业务需求持续更新，请关注最新版本。
> 如有疑问，请联系产品数据团队。

**文档维护**: 产品经理 & 数据分析师  
**技术支持**: 开发团队 & 数据工程师  
**合规审查**: 法务团队 & 隐私保护官