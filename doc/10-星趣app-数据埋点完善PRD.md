# 星趣APP数据埋点体系完善 - 产品需求文档（PRD）

> 本文档基于现有数据埋点架构设计，明确实施优先级和验收标准，指导开发团队快速落地数据采集体系。

---

## 文档信息

- **文档版本**: v1.0.0
- **创建时间**: 2025年1月
- **产品经理**: 星趣产品团队
- **适用范围**: 开发团队、运营团队、数据分析团队
- **文档状态**: 已确认

---

## 1. 产品概述与目标

### 1.1 项目背景
星趣APP已有完整的数据埋点架构设计文档，但实际代码实施尚未完成。需要全面梳理现有文档，确保所有页面交互都有对应的数据埋点支持，并快速部署实施以支撑运营决策。

### 1.2 核心目标
- **短期目标**（1-2周）：完成基础埋点SDK集成，实现核心页面（启动页、登录注册、首页精选）的数据采集
- **中期目标**（3-4周）：实现会员体系、星川体系的完整埋点，建立实时监控机制  
- **长期目标**（1-2月）：构建完整的数据分析体系，支撑精细化运营和商业化决策

### 1.3 成功指标
- SDK集成完成率：100%
- 核心路径覆盖率：100%
- 数据上报成功率：>99%
- 实时数据延迟：<5分钟

---

## 2. 用户角色与使用场景

### 2.1 目标用户

| 用户角色 | 核心需求 | 使用场景 | 关注指标 |
|----------|----------|----------|----------|
| 产品运营团队 | 了解用户行为、优化产品体验 | 查看DAU/MAU、留存率、功能使用率等指标 | 海盗模型AARRR |
| 商业化团队 | 监控变现效率、优化收入策略 | 实时查看会员转化、付费漏斗、广告效果 | 付费转化率、ARPU、LTV |
| 产品经理 | 验证功能价值、指导迭代方向 | 分析功能使用路径、转化漏斗、用户反馈 | 功能渗透率、用户满意度 |
| 数据分析师 | 深度用户洞察、预测模型构建 | 用户分层分析、生命周期价值计算 | 用户分群、行为序列 |

### 2.2 典型使用场景

1. **日常运营监控**：每日查看核心指标变化，发现异常及时响应
2. **活动效果评估**：实时监控活动参与度、转化率，快速调整策略
3. **功能优化决策**：通过AB测试和数据分析，验证优化效果
4. **用户分层运营**：基于行为数据对用户分层，实施精准运营策略

---

## 3. 功能需求与优先级

### 3.1 P0 - 基础埋点实施（MVP）

| 功能模块 | 具体需求 | 关键事件 | 实施状态 |
|----------|----------|----------|----------|
| **SDK集成** | 集成友盟SDK + 神策SDK，创建统一AnalyticsService | - | ❌ 待实施 |
| **启动页埋点** | app_launch、首次启动识别、冷热启动区分 | app_launch, app_first_open | ❌ 待实施 |
| **登录注册埋点** | user_register、user_login、登录方式、耗时、成功率 | user_register, user_login | ❌ 待实施 |
| **首页精选埋点** | 点赞、关注、订阅、评论交互行为 | social_like, follow, subscribe, comment | ⚠️ 部分实施 |
| **页面浏览埋点** | page_view、页面停留时长、页面加载性能 | page_view, page_exit | ❌ 待实施 |

### 3.2 P1 - 业务埋点实施

| 功能模块 | 具体需求 | 商业价值 | 优先级理由 |
|----------|----------|----------|------------|
| **会员体系埋点** | 会员等级变化、购买转化漏斗、权益使用追踪 | 直接影响收入 | 商业化核心 |
| **星川体系埋点** | 星川获取、消耗、转化、交易行为 | 虚拟经济体系健康度 | 用户粘性关键 |
| **AI交互埋点** | 对话轮次、满意度、功能使用深度 | 核心功能价值验证 | 产品差异化 |
| **内容创作埋点** | 创作流程漏斗、发布成功率、内容质量 | UGC生态建设 | 内容供给 |

### 3.3 P2 - 高级分析功能

- 用户生命周期追踪（新手→活跃→付费→流失）
- 归因分析（渠道效果、功能贡献度）
- 预测模型（流失预警、付费倾向）
- 实时数据看板（自定义指标、多维分析）

---

## 4. 与现有功能集成

### 4.1 现有功能适配

| 现有功能 | 埋点补充需求 | 预期效果 |
|----------|-------------|----------|
| AI聊天 | 对话质量评分、用户满意度、功能使用深度 | 优化对话体验，提升满意度 |
| 故事创作 | 创作流程漏斗、素材使用、发布成功率 | 降低创作门槛，提升完成率 |
| 发现页 | 推荐点击率、停留时长、内容互动率 | 优化推荐算法，提升内容分发效率 |
| 音频FM | 播放完成率、跳出时间点、重播行为 | 优化内容质量，提升收听体验 |

### 4.2 数据打通方案

```typescript
// 统一用户标识体系
interface UserIdentity {
  user_id: string;          // Supabase用户ID
  device_id: string;        // 设备唯一标识
  session_id: string;       // 会话ID
  tracking_id: string;      // 第三方SDK追踪ID
}

// 用户属性同步
interface UserAttributes {
  // 基础属性
  registration_date: Date;
  membership_level: string;
  star_points: number;
  
  // 行为属性
  total_sessions: number;
  total_duration: number;
  last_active_date: Date;
  
  // 商业属性
  is_paying_user: boolean;
  total_payment: number;
  first_payment_date?: Date;
}
```

---

## 5. 技术实现方案

### 5.1 前端实施架构

```dart
// Flutter统一埋点服务
class AnalyticsService {
  // 单例模式
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  
  // SDK实例
  late final UmengAnalytics umeng;
  late final SensorsAnalytics sensors;
  late final SupabaseClient supabase;
  
  // 初始化
  Future<void> initialize() async {
    await umeng.init(appKey: UMENG_APP_KEY);
    await sensors.init(serverUrl: SENSORS_SERVER_URL);
    // 设置公共属性
    await setCommonProperties();
  }
  
  // 统一事件上报
  void track(String eventName, Map<String, dynamic> properties) {
    // 添加通用属性
    final enrichedProps = {
      ...commonProperties,
      ...properties,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // 多端上报
    umeng.track(eventName, enrichedProps);
    sensors.track(eventName, enrichedProps);
    
    // 异步存储到Supabase（可选）
    _storeToSupabase(eventName, enrichedProps);
  }
  
  // 页面追踪
  void trackPageView(String pageName, {Map<String, dynamic>? properties}) {
    track('page_view', {
      'page_name': pageName,
      'page_path': ModalRoute.of(context)?.settings.name,
      ...?properties,
    });
  }
}
```

### 5.2 后端数据架构

```sql
-- 用户事件表
CREATE TABLE user_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  session_id VARCHAR(255) NOT NULL,
  event_name VARCHAR(100) NOT NULL,
  event_category VARCHAR(50),
  properties JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 索引优化
  INDEX idx_user_events_user_id (user_id),
  INDEX idx_user_events_event_name (event_name),
  INDEX idx_user_events_created_at (created_at)
);

-- 用户会话表
CREATE TABLE user_sessions (
  id VARCHAR(255) PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  duration INTEGER,
  page_views INTEGER DEFAULT 0,
  events_count INTEGER DEFAULT 0,
  device_info JSONB,
  
  INDEX idx_sessions_user_id (user_id),
  INDEX idx_sessions_start_time (start_time)
);

-- 实时聚合视图
CREATE MATERIALIZED VIEW daily_metrics AS
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as dau,
  COUNT(*) as total_events,
  COUNT(DISTINCT session_id) as sessions
FROM user_events
GROUP BY DATE(created_at);
```

### 5.3 实时数据处理

```typescript
// Supabase Edge Function - 实时数据处理
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { event_name, properties, user_id } = await req.json()
  
  // 实时指标计算
  if (event_name === 'membership_purchase_complete') {
    // 更新商业化指标
    await updateRevenueMetrics(user_id, properties)
    // 发送实时通知
    await notifyRevenueAlert(properties.amount)
  }
  
  // 用户分层更新
  if (event_name === 'user_lifecycle_change') {
    await updateUserSegment(user_id, properties.new_stage)
  }
  
  return new Response(JSON.stringify({ success: true }))
})
```

---

## 6. 数据指标体系

### 6.1 海盗模型（AARRR）指标

| 阶段 | 核心指标 | 计算方式 | 目标值 | 监控频率 |
|------|----------|----------|--------|----------|
| **获取** | 新用户数 | COUNT(DISTINCT user_id) WHERE first_open | 日新增>1000 | T+1 |
| **获取** | 获客成本(CAC) | 营销费用 / 新用户数 | <10元 | T+1 |
| **激活** | 注册转化率 | 注册用户 / 新用户 | >30% | T+1 |
| **激活** | 新手任务完成率 | 完成用户 / 新注册用户 | >50% | T+1 |
| **留存** | 次日留存率 | D1活跃 / D0新增 | >40% | T+1 |
| **留存** | 7日留存率 | D7活跃 / D0新增 | >20% | T+1 |
| **收入** | 付费转化率 | 付费用户 / 活跃用户 | >5% | 实时 |
| **收入** | ARPU | 总收入 / 活跃用户 | >2元 | 实时 |
| **推荐** | 分享率 | 分享用户 / 活跃用户 | >10% | T+1 |
| **推荐** | K因子 | 邀请注册数 / 分享用户数 | >1 | T+1 |

### 6.2 商业化核心指标

| 指标类别 | 指标名称 | 实时监控 | 告警阈值 |
|----------|----------|----------|----------|
| **会员指标** | 订阅转化率 | ✅ 是 | <3%触发告警 |
| **会员指标** | 月续费率 | ✅ 是 | <70%触发告警 |
| **会员指标** | 会员ARPU | ✅ 是 | 环比下降>10% |
| **星川指标** | 日均交易额 | ✅ 是 | <预期50% |
| **星川指标** | 活跃交易用户 | ❌ 否 | - |
| **广告指标** | eCPM | ✅ 是 | <5元告警 |
| **广告指标** | 填充率 | ✅ 是 | <80%告警 |

---

## 7. 数据看板设计

### 7.1 运营看板（T+1更新）

#### 7.1.1 核心指标看板
- **用户规模**：DAU/MAU趋势图、新增用户趋势
- **用户质量**：留存率漏斗、用户生命周期分布
- **功能使用**：TOP10功能使用率、功能渗透率矩阵
- **用户路径**：核心路径转化漏斗、页面流转桑基图

#### 7.1.2 用户分层看板
- **新手用户**：注册→激活转化漏斗
- **活跃用户**：使用深度分布、功能偏好
- **付费用户**：付费频次、客单价分布
- **流失用户**：流失原因分析、召回效果

### 7.2 商业化实时看板

#### 7.2.1 收入监控
- **实时收入**：分钟级收入曲线、同比环比
- **付费漏斗**：浏览→点击→支付转化率
- **会员分布**：各等级会员占比、升降级流向

#### 7.2.2 告警机制
- 收入异常：5分钟收入为0
- 转化异常：转化率低于阈值
- 技术异常：支付失败率>5%

---

## 8. 隐私合规要求

### 8.1 数据收集原则

| 原则 | 具体要求 | 实施方式 |
|------|----------|----------|
| 最小化原则 | 仅收集业务必需数据 | 数据字段审核机制 |
| 透明化原则 | 明确告知数据用途 | 隐私政策弹窗 |
| 可控制原则 | 用户可关闭/删除 | 设置页数据管理入口 |
| 安全性原则 | 加密传输和存储 | HTTPS + AES加密 |

### 8.2 合规清单

- [x] 隐私政策更新（包含埋点说明）
- [x] 用户授权弹窗（首次启动）
- [ ] 数据开关功能（设置页）
- [ ] 数据导出功能（GDPR要求）
- [ ] 数据删除功能（注销账号）

---

## 9. 实施计划

### Phase 1：基础实施（第1-2周）

| 任务 | 负责人 | 开始时间 | 结束时间 | 状态 |
|------|--------|----------|----------|------|
| 集成友盟SDK | 前端开发 | Day 1 | Day 2 | 待开始 |
| 集成神策SDK | 前端开发 | Day 2 | Day 3 | 待开始 |
| 封装AnalyticsService | 前端开发 | Day 3 | Day 4 | 待开始 |
| 实施启动页埋点 | 前端开发 | Day 4 | Day 5 | 待开始 |
| 实施登录注册埋点 | 前端开发 | Day 5 | Day 6 | 待开始 |
| 修复首页埋点 | 前端开发 | Day 6 | Day 7 | 待开始 |
| 创建Supabase数据表 | 后端开发 | Day 1 | Day 3 | 待开始 |
| 部署Edge Functions | 后端开发 | Day 3 | Day 5 | 待开始 |
| 基础指标验证 | QA测试 | Day 7 | Day 10 | 待开始 |

### Phase 2：业务埋点（第3-4周）

| 任务 | 优先级 | 预计工时 | 依赖项 |
|------|--------|----------|--------|
| 会员体系埋点 | P0 | 3天 | Phase 1完成 |
| 星川体系埋点 | P0 | 2天 | Phase 1完成 |
| AI交互埋点 | P1 | 2天 | Phase 1完成 |
| 内容创作埋点 | P1 | 2天 | Phase 1完成 |
| 实时监控搭建 | P0 | 3天 | 埋点完成 |

### Phase 3：数据应用（第5-6周）

- 搭建Grafana/Tableau数据看板
- 配置自动化告警规则
- 用户分层模型训练
- 数据质量监控上线

---

## 10. 验收标准

### 10.1 技术验收

| 验收项 | 验收标准 | 验收方法 |
|--------|----------|----------|
| SDK集成 | 无崩溃，性能影响<1% | 压力测试 |
| 数据上报 | 成功率>99% | 日志分析 |
| 数据延迟 | 实时类<5分钟 | 延迟测试 |
| 数据准确性 | 误差<5% | 抽样校验 |

### 10.2 业务验收

| 验收项 | 验收标准 | 责任人 |
|--------|----------|--------|
| 路径覆盖 | 100%核心路径 | 产品经理 |
| 指标完整性 | AARRR指标齐全 | 运营团队 |
| 看板可用性 | 自主查看数据 | 运营团队 |
| 实时监控 | 商业指标实时可见 | 商业化团队 |

### 10.3 交付物清单

- [ ] AnalyticsService源代码
- [ ] 埋点事件文档（Excel格式）
- [ ] 数据看板访问地址
- [ ] 操作使用手册
- [ ] 数据字典文档

---

## 11. 风险与应对

| 风险类型 | 风险描述 | 应对措施 |
|----------|----------|----------|
| 技术风险 | SDK冲突或性能问题 | 提前POC验证，准备降级方案 |
| 数据风险 | 数据丢失或不准确 | 多端数据校验，建立补采机制 |
| 合规风险 | 隐私政策不合规 | 法务审核，用户授权机制 |
| 进度风险 | 开发延期 | 分阶段交付，MVP优先 |

---

## 12. 参考资料

- 星趣APP数据埋点文档 v1.0.0
- 友盟SDK集成文档
- 神策SDK Flutter插件指南
- 星野APP产品分析报告
- GDPR/CCPA合规指南

---

## 附录A：核心埋点事件列表

| 事件名称 | 事件说明 | 触发时机 | 必要属性 |
|----------|----------|----------|----------|
| app_launch | 应用启动 | 应用被打开时 | launch_type, is_first |
| user_register | 用户注册 | 注册成功时 | register_method, channel |
| user_login | 用户登录 | 登录成功时 | login_method, is_auto |
| page_view | 页面浏览 | 进入新页面 | page_name, from_page |
| social_like | 点赞行为 | 点击点赞按钮 | target_type, target_id |
| membership_purchase | 会员购买 | 支付成功时 | plan_type, amount |
| ai_chat_start | AI对话开始 | 发起对话 | agent_id, entry_point |

---

## 附录B：数据上报格式示例

```json
{
  "event_name": "page_view",
  "event_time": "2025-01-21T10:30:00Z",
  "user_id": "user_123456",
  "session_id": "session_abc123",
  "properties": {
    "page_name": "home_selection",
    "page_title": "精选推荐",
    "from_page": "main_tab",
    "load_time": 320,
    "network_type": "wifi",
    "device_model": "iPhone 13"
  }
}
```

---

*本PRD文档已确认，可进入设计和开发阶段。*