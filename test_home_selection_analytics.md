# 📊 首页-精选页埋点数据流测试指南

## 🎯 测试目标
验证首页-精选页的所有用户行为埋点能够正确收集、存储和流转到后台管理系统，特别是：
- 页面访问埋点
- 点赞行为埋点  
- 关注行为埋点
- 评论行为埋点

## 🔧 前置条件

### 1. 执行数据库修复脚本
在Supabase SQL编辑器中执行 `fix_user_constraints.sql`：

```sql
-- 完整执行此脚本内容
-- 这将修复用户表约束问题，确保埋点功能正常工作
```

### 2. 确认Flutter应用正常运行
确保应用已成功启动并可以正常访问首页-精选页。

## 📋 测试步骤

### 步骤1: 测试页面访问埋点
1. **操作**: 启动Flutter应用，导航到首页-精选页
2. **预期结果**: 
   - 控制台输出: `✅ 页面访问埋点已发送: 首页-精选页`
   - 数据库中应有 `page_view` 事件记录

### 步骤2: 测试点赞功能埋点
1. **操作**: 在首页-精选页点击角色的"心形"点赞按钮
2. **预期结果**: 
   - UI显示点赞状态变化
   - 控制台输出: `✅ Liked character: [角色ID] by user: [用户ID]`
   - 数据库中应有 `social_interaction` 类型的点赞事件

### 步骤3: 测试关注功能埋点  
1. **操作**: 在首页-精选页点击角色的"关注"按钮
2. **预期结果**:
   - UI显示关注状态变化
   - 控制台输出: `✅ Followed character: [角色ID] by user: [用户ID]`
   - 数据库中应有 `character_interaction` 类型的关注事件

### 步骤4: 测试评论功能埋点
1. **操作**: 在首页-精选页点击评论按钮，输入评论内容并提交
2. **预期结果**:
   - 评论成功提交
   - 数据库中应有 `social_interaction` 类型的评论事件

### 步骤5: 验证用户档案自动创建
1. **操作**: 使用匿名登录或新用户访问页面
2. **预期结果**:
   - 控制台输出: `✅ 用户档案确保存在: [用户ID]`
   - 不再出现外键约束错误

## 🔍 数据验证SQL查询

### 查询页面访问记录
```sql
-- 查看首页-精选页的访问记录
SELECT * FROM user_analytics 
WHERE page_name = 'home_selection_page' 
ORDER BY created_at DESC 
LIMIT 10;
```

### 查询社交互动记录
```sql
-- 查看点赞和评论记录
SELECT 
    event_type,
    event_data->>'actionType' as action_type,
    event_data->>'targetType' as target_type,
    event_data->>'source' as source,
    created_at
FROM user_analytics 
WHERE event_type = 'social_interaction'
AND event_data->>'source' = 'featured_page'
ORDER BY created_at DESC 
LIMIT 10;
```

### 查询角色交互记录
```sql
-- 查看关注记录
SELECT 
    event_type,
    event_data->>'interactionType' as interaction_type,
    event_data->>'source' as source,
    event_data->>'character_name' as character_name,
    created_at
FROM user_analytics 
WHERE event_type = 'character_interaction'
AND event_data->>'source' = 'featured_page'
ORDER BY created_at DESC 
LIMIT 10;
```

### 查询用户档案创建记录
```sql
-- 查看用户档案确保记录
SELECT 
    event_type,
    event_data->>'source' as source,
    event_data->>'method' as method,
    created_at
FROM user_analytics 
WHERE event_type = 'user_profile_ensured'
ORDER BY created_at DESC 
LIMIT 10;
```

## 📊 后台管理系统验证

### 1. 访问后台管理系统
打开后台管理系统的"移动端数据监控"页面

### 2. 检查实时数据流
应该能看到以下数据：
- **页面访问数据**: 首页-精选页的访问次数
- **社交互动数据**: 点赞、评论行为统计
- **角色交互数据**: 关注行为统计
- **用户活跃度**: 实时用户行为流

### 3. 验证数据完整性
确认后台显示的数据与实际操作一致：
- 操作时间匹配
- 操作类型正确
- 用户ID和角色ID准确

## 🐛 常见问题排查

### 问题1: 外键约束错误
**症状**: `violates foreign key constraint "likes_user_id_fkey"`
**解决**: 确保已执行 `fix_user_constraints.sql` 脚本

### 问题2: 埋点数据未发送
**症状**: 控制台无埋点日志
**解决**: 检查 `AnalyticsService` 初始化和网络连接

### 问题3: 后台无数据显示  
**症状**: 操作成功但后台无数据
**解决**: 
1. 检查后台监听的表名和字段
2. 验证数据库权限设置
3. 确认实时订阅功能正常

### 问题4: 用户档案创建失败
**症状**: `duplicate key value violates unique constraint "users_phone_key"`
**解决**: 数据库脚本会自动修复此问题

## ✅ 测试完成标准

### 基础功能测试通过
- [ ] 页面访问埋点正常发送
- [ ] 点赞功能埋点正常发送
- [ ] 关注功能埋点正常发送  
- [ ] 评论功能埋点正常发送

### 数据流验证通过
- [ ] Supabase数据库正确存储埋点数据
- [ ] 数据格式符合规范
- [ ] 时间戳准确记录

### 后台系统展示正常
- [ ] 实时数据流正常显示
- [ ] 数据统计准确
- [ ] 用户行为轨迹完整

### 错误处理健壮
- [ ] 网络异常不影响主功能
- [ ] 数据库约束问题已解决
- [ ] 匿名用户操作正常

## 🎉 测试成功标志

当看到以下现象时，说明首页-精选页埋点功能已经完全正常：

1. **Flutter控制台日志**:
   ```
   ✅ 页面访问埋点已发送: 首页-精选页
   ✅ 用户档案确保存在: [用户ID]
   ✅ Liked character: [角色ID] by user: [用户ID]
   ✅ Followed character: [角色ID] by user: [用户ID]
   ```

2. **Supabase数据库**:
   - `user_analytics` 表有相应的记录
   - 数据格式正确，字段完整

3. **后台管理系统**:
   - 实时显示用户行为数据
   - 统计数据准确更新
   - 无延迟，数据流畅

---

**测试时间**: ___________  
**测试人员**: ___________  
**测试结果**: ___________  
**备注**: ___________