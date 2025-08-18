# 🚀 星趣App Sprint 3 Supabase部署指南

## 📋 部署前准备清单

### ✅ 环境检查
- [ ] 确认Supabase项目已创建并可访问
- [ ] 确认具有Supabase项目的管理员权限
- [ ] 确认Sprint 1-2的数据库已部署完成
- [ ] 建议在非生产环境先测试部署流程

### ✅ 数据备份（生产环境必须）
- [ ] 备份现有 `users` 表数据
- [ ] 备份现有 `characters` 表数据
- [ ] 备份现有 `stories` 表数据
- [ ] 记录当前数据库schema版本

## 🎯 部署执行步骤

### 第一步：登录Supabase控制台
1. 访问 [Supabase Dashboard](https://app.supabase.com)
2. 选择您的星趣项目
3. 进入 `SQL Editor` 页面

### 第二步：执行部署脚本
1. 打开文件 `sprint3_supabase_deployment.sql`
2. **完整复制**所有SQL内容到Supabase SQL Editor
3. 点击 **"RUN"** 按钮执行脚本
4. 等待执行完成（预计2-5分钟）

### 第三步：验证部署结果
执行完成后，查看执行结果中的验证信息：

```
==========================================
Sprint 3 Supabase部署完成验证
==========================================
✅ 数据表创建: 12 / 12
✅ 索引创建: 15 个
✅ RLS策略: 24 个
✅ 业务函数: 4 / 4
✅ 默认数据: 4 个套餐
🎉 Sprint 3 Supabase部署成功完成！
==========================================
```

如果看到 `🎉 Sprint 3 Supabase部署成功完成！`，说明部署成功。

## 📊 部署内容详情

### 🗃️ 新增数据表 (12个)

| 表名 | 用途 | 重要性 |
|------|------|--------|
| `subscription_plans` | 订阅套餐配置 | 🔥 核心商业 |
| `user_memberships` | 用户会员状态 | 🔥 核心商业 |
| `payment_orders` | 支付订单管理 | 🔥 核心商业 |
| `payment_callbacks` | 支付回调记录 | 🔒 安全关键 |
| `recommendation_configs` | 推荐算法配置 | ⭐ 个性化 |
| `recommendation_feedback` | 用户反馈数据 | ⭐ 个性化 |
| `custom_agents` | 自定义智能体 | 🤖 生态核心 |
| `agent_runtime_status` | 智能体运行状态 | 🤖 生态管理 |
| `agent_permissions` | 智能体权限 | 🔒 安全管理 |
| `membership_benefits` | 会员权益配置 | 💎 权益管理 |
| `membership_usage_logs` | 权益使用记录 | 📊 统计分析 |
| `user_tab_preferences` | Tab偏好设置 | 🎨 用户体验 |

### 🔒 安全策略 (24个RLS策略)

- **数据隔离**: 用户只能访问自己的数据
- **权限分级**: 创建者/管理员/普通用户权限分离
- **商业安全**: 支付数据严格保护
- **功能权限**: 基于会员等级的功能访问控制

### ⚡ 性能优化 (15个索引)

- 用户查询优化索引
- 支付订单快速检索
- 智能体权限快速验证
- 推荐算法性能优化

### 🔧 业务函数 (4个核心函数)

- `check_user_membership_level()` - 会员等级检查
- `generate_order_number()` - 订单号生成
- `update_user_membership_on_payment()` - 支付成功处理
- `update_agent_usage_stats()` - 智能体使用统计

## 🔍 部署后验证

### 1. 数据完整性检查
在SQL Editor中执行以下查询验证：

```sql
-- 检查套餐数据
SELECT plan_name, plan_type, price_cents, is_active FROM subscription_plans ORDER BY display_order;

-- 检查用户会员状态
SELECT COUNT(*) as total_users, 
       COUNT(um.id) as users_with_membership
FROM users u
LEFT JOIN user_memberships um ON u.id = um.user_id AND um.status = 'active';

-- 检查权益配置
SELECT benefit_name, applicable_plans, is_active FROM membership_benefits ORDER BY display_order;
```

### 2. API访问测试
使用Supabase客户端测试基本API访问：

```javascript
// 测试套餐查询
const { data: plans } = await supabase
  .from('subscription_plans')
  .select('*')
  .eq('is_active', true);

// 测试用户会员状态查询
const { data: membership } = await supabase
  .from('user_memberships')
  .select(`
    *,
    subscription_plans(*)
  `)
  .eq('user_id', user.id)
  .eq('status', 'active')
  .single();
```

### 3. RLS策略验证
确认用户只能访问自己有权限的数据：

```sql
-- 以特定用户身份测试（在应用中测试）
-- 用户应该只能看到自己的订单
SELECT * FROM payment_orders; -- 应该只返回当前用户的订单

-- 用户应该只能看到公开的智能体或自己创建的
SELECT * FROM custom_agents; -- 应该返回公开+自己创建的智能体
```

## ⚠️ 常见问题处理

### 问题1: 执行失败 - 权限不足
**解决方案**: 确保使用项目管理员账号，或具有完整数据库权限

### 问题2: 部分表创建失败
**解决方案**: 
1. 检查是否存在表名冲突
2. 逐个执行CREATE TABLE语句定位问题
3. 检查外键引用的表是否存在

### 问题3: RLS策略创建失败
**解决方案**:
1. 确认表已成功创建
2. 检查用户权限函数是否正确创建
3. 逐个执行策略创建语句

### 问题4: 数据插入失败
**解决方案**:
1. 检查JSON格式是否正确
2. 确认外键引用数据存在
3. 检查唯一约束冲突

## 🔄 回滚方案

如果部署出现问题，可以执行以下回滚操作：

```sql
-- 1. 删除新创建的表（按依赖关系逆序）
DROP TABLE IF EXISTS user_tab_preferences CASCADE;
DROP TABLE IF EXISTS membership_usage_logs CASCADE;
-- ... 其他表

-- 2. 恢复备份数据（如果有备份）
-- 根据具体备份策略执行恢复

-- 3. 更新迁移状态
UPDATE migration_logs 
SET status = 'rolled_back' 
WHERE migration_name = 'Sprint 3 Supabase Deployment';
```

## 📞 技术支持

如遇到部署问题，请提供以下信息：
- Supabase项目ID
- 错误信息截图
- 执行失败的具体SQL语句
- 当前数据库schema状态

## 🎉 部署成功确认

部署成功后，您将获得：
- ✅ 完整的商业化订阅系统
- ✅ 个性化推荐算法基础
- ✅ 智能体生态管理平台
- ✅ 会员权益管理系统
- ✅ 安全的支付处理流程
- ✅ 高性能的数据查询支持

**下一步**: 执行 **/API测试** 开始API开发和测试阶段。