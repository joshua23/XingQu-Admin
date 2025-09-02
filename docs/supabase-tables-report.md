# 星趣App Supabase 数据库表结构报告

**生成时间**: 2025-01-02  
**项目**: 星趣App Web后台管理系统  
**数据库**: Supabase PostgreSQL  

---

## 📊 总览

**重大更新**: 经过正确的数据库查询，发现当前 Supabase 项目中共有 **12张** 以 `xq_` 开头的表：

### 有数据的表 (5张)
1. ✅ **xq_tracking_events** - 行为追踪表 (35行，8个字段)
2. ✅ **xq_user_sessions** - 用户会话表 (3行，16个字段)  
3. ✅ **xq_feedback** - 用户反馈表 (1行，11个字段)
4. ✅ **xq_user_profiles** - 用户配置表 (1行，22个字段)
5. ✅ **xq_user_settings** - 用户设置表 (1行，9个字段)

### 空表但结构完整 (7张)
6. 🔶 **xq_account_deletion_requests** - 账户删除请求表 (0行，7个字段)
7. 🔶 **xq_agents** - AI代理表 (0行，15个字段)
8. 🔶 **xq_avatars** - 头像资源表 (0行，8个字段)
9. 🔶 **xq_background_music** - 背景音乐表 (0行，10个字段)
10. 🔶 **xq_fm_programs** - FM节目表 (0行，11个字段)
11. 🔶 **xq_user_blacklist** - 用户黑名单表 (0行，7个字段)
12. 🔶 **xq_voices** - 语音资源表 (0行，12个字段)

**查询方式**: 使用 psql 直接连接数据库获得准确结果  
**连接字符串**: `postgresql://postgres.wqdpqhfqrxvssxifpmvt:PASSWORD@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres`

---

## 🗄️ 详细表结构

### 1. xq_user_profiles (用户配置表)

**状态**: ✅ 活跃使用中  
**行数**: 1条记录  
**字段数**: 22个字段  

#### 字段详情
```sql
-- 主要标识字段
id                    UUID      -- 主键
user_id               UUID      -- 关联 auth.users 表的用户ID

-- 基本信息字段  
nickname              TEXT      -- 用户昵称
avatar_url            TEXT      -- 头像URL
bio                   TEXT      -- 个人简介
gender                TEXT      -- 性别 ('male', 'female', 'other')

-- 微信集成字段
wechat_openid         TEXT      -- 微信OpenID
wechat_unionid        TEXT      -- 微信UnionID  
wechat_nickname       TEXT      -- 微信昵称
wechat_avatar_url     TEXT      -- 微信头像URL

-- Apple登录字段
apple_user_id         TEXT      -- Apple用户ID
apple_email           TEXT      -- Apple邮箱
apple_full_name       TEXT      -- Apple全名

-- 统计字段
likes_received_count  INTEGER   -- 收到的点赞数
agents_usage_count    INTEGER   -- AI代理使用次数

-- 账户状态字段
account_status        TEXT      -- 账户状态 ('active', 'inactive', 'suspended')
deactivated_at        TIMESTAMP -- 停用时间
violation_reason      TEXT      -- 违规原因

-- 会员信息字段
is_member             BOOLEAN   -- 是否为会员
membership_expires_at TIMESTAMP -- 会员到期时间

-- 审计字段
created_at            TIMESTAMP -- 创建时间
updated_at            TIMESTAMP -- 最后更新时间
```

#### 示例数据
```json
{
  "id": "18f630cb-e701-45e6-9c34-c26b51040048",
  "user_id": "9978cfbe-5871-4ec2-81ea-21cde3b06276", 
  "nickname": "Gen",
  "avatar_url": "https://wqdpqhfqrxvssxifpmvt.supabase.co/storage/v1/object/...",
  "bio": "",
  "account_status": "active",
  "is_member": false,
  "gender": "male",
  "likes_received_count": 0,
  "agents_usage_count": 0
}
```

### 2. xq_user_sessions (用户会话表)

**状态**: 🔧 已创建但暂无数据  
**行数**: 0条记录  
**用途**: 记录用户会话信息，用于分析用户活跃度和使用时长

**推测字段** (基于代码中的使用):
- `session_duration` - 会话时长
- `created_at` - 会话开始时间  
- `user_id` - 用户ID
- `session_end` - 会话结束时间

### 3. xq_tracking_events (行为追踪表)

**状态**: 🔧 已创建但暂无数据  
**行数**: 0条记录  
**用途**: 记录用户行为事件，用于数据分析和用户行为洞察

**推测字段** (基于代码中的使用):
- `user_id` - 用户ID
- `event_type` - 事件类型
- `event_name` - 事件名称
- `event_properties` - 事件属性 (JSON)
- `created_at` - 事件发生时间
- `session_id` - 会话ID
- `page_name` - 页面名称

### 4. xq_user_settings (用户设置表)

**状态**: 🔧 已创建但暂无数据  
**行数**: 0条记录  
**用途**: 存储用户个人设置和偏好

**推测用途**:
- 通知设置
- 隐私设置  
- 界面偏好
- 语言设置

### 5. xq_agents (AI代理表)

**状态**: 🔧 已创建但暂无数据  
**行数**: 0条记录  
**用途**: 存储AI代理相关信息

**推测用途**:
- AI代理配置
- 代理使用记录
- 代理性能数据
- 用户与代理的交互历史

---

## 🔍 项目代码中的表引用

### 当前使用的表
根据代码分析，项目主要使用以下表：

1. **xq_user_profiles** - ✅ 广泛使用
   - 用户管理页面
   - Dashboard 统计
   - 认证系统

2. **xq_user_sessions** - ✅ 部分使用  
   - Dashboard 会话统计
   - 分析页面数据源

3. **xq_tracking_events** - ✅ 部分使用
   - 行为分析
   - 活跃用户统计

4. **xq_user_settings** - ⚠️ 代码中未见明确使用

5. **xq_agents** - ⚠️ 新发现的表，代码中暂未使用

---

## 🚨 发现的问题与建议

### 1. 数据完整性问题
- **问题**: 4张表为空 (`xq_user_sessions`, `xq_tracking_events`, `xq_user_settings`, `xq_agents`)
- **影响**: Dashboard 和分析页面可能显示不准确的统计数据
- **建议**: 检查数据采集逻辑，确保事件和会话数据正常写入

### 2. 字段命名一致性
- **问题**: 之前代码中使用了不存在的字段名
- **解决**: 已更新代码使用正确的字段名
- **建议**: 严格按照实际数据库结构编写查询

### 3. 新发现的表
- **发现**: `xq_agents` 表存在但未在代码中使用
- **建议**: 确认该表的用途，是否需要在当前项目中集成

### 4. 表结构文档化
- **问题**: 空表无法推断完整结构
- **建议**: 
  - 在 Supabase 控制台中查看完整表结构
  - 创建表结构文档
  - 添加示例数据用于测试

### 5. 数据库资源优化
- **发现**: 通过暴力搜索测试了52个可能的表名，但实际只有5张表存在
- **建议**: 建立准确的数据库文档，避免不必要的查询和猜测

---

## 💡 开发建议

### 1. 数据库查询最佳实践
```typescript
// ✅ 正确的字段引用
const getUserData = async () => {
  const { data, error } = await supabase
    .from('xq_user_profiles')
    .select(`
      id,
      user_id,
      nickname,           // 不是 username
      account_status,     // 不是 is_active  
      is_member,          // 不是 subscription_type
      created_at,
      updated_at          // 不是 last_sign_in_at
    `)
}
```

### 2. 类型定义
```typescript
// 基于实际表结构的接口定义
interface XqUserProfile {
  id: string
  user_id: string
  nickname?: string
  avatar_url?: string
  account_status: 'active' | 'inactive' | 'suspended'
  is_member: boolean
  // ... 其他字段
}
```

### 3. 调试工具
使用 `debugTableStructure()` 函数检查表结构:
```javascript
// 检查任意表的字段结构
debugTableStructure('xq_user_profiles')
```

---

## 📋 后续行动项

### 短期 (1-2周)
- [ ] 检查并修复数据采集逻辑
- [ ] 为空表添加示例数据
- [ ] 完善表结构文档

### 中期 (1个月)  
- [ ] 优化数据库查询性能
- [ ] 实现数据备份策略
- [ ] 添加数据监控告警

### 长期 (3个月)
- [ ] 考虑添加更多业务表
- [ ] 实现数据分析dashboard
- [ ] 建立数据治理规范

---

## 📞 支持

如需了解更多信息或遇到问题，请参考：
- [项目专用 Supabase 指南](./project-supabase-guide.md)
- [Supabase 最佳实践文档](./supabase-best-practices.md)

---

**报告生成**: 自动化脚本检测  
**最后更新**: 2025-01-02  
**负责人**: 开发团队