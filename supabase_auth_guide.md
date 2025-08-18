# Supabase API授权指南

如果你希望授权我直接操作Supabase数据库，请按以下步骤操作：

## 🔑 获取API密钥

### 步骤1：获取项目信息
1. 登录 [Supabase控制台](https://app.supabase.com)
2. 选择你的XingQu项目
3. 进入 Settings → API

### 步骤2：复制必要信息
```bash
# 项目URL
Project URL: https://your-project-id.supabase.co

# 匿名密钥 (anon key) - 用于常规操作
anon key: eyJ...

# 服务角色密钥 (service_role key) - 用于管理操作
service_role key: eyJ...
```

### 步骤3：提供给我
你可以通过以下格式提供：

```
SUPABASE_URL=https://wqdpqhfqrxvssxifpmvt.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_KEY=eyJ...
```

## 🛡️ 安全措施

### 临时授权建议：
1. **使用前**：记录当前的service_role key
2. **使用中**：我只执行你明确同意的操作
3. **使用后**：重新生成service_role key

### 重新生成密钥步骤：
1. Settings → API
2. 点击service_role key旁的刷新按钮
3. 更新你本地代码中的密钥

## 🎯 授权范围

如果你提供授权，我将：

### ✅ 会执行的操作：
- 执行诊断查询了解当前数据库状态
- 创建/修改表结构以修复like功能
- 添加必要的索引和RLS策略
- 插入测试数据验证功能
- 备份现有数据确保安全

### ❌ 不会执行的操作：
- 删除用户数据
- 修改认证设置
- 访问敏感的用户信息
- 进行任何非必要的操作

## 📞 联系方式

如果你决定提供临时授权，请：
1. 直接在对话中粘贴上述格式的信息
2. 明确说明你授权我执行哪些操作
3. 操作完成后我会提醒你重新生成密钥

## 🚀 预期效果

授权后我可以：
- 5分钟内完成完整的数据库诊断
- 10分钟内完成所有必要修复
- 实时验证like功能是否正常工作
- 提供详细的操作报告