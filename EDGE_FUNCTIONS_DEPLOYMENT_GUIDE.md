# Edge Functions 部署指南

## 📋 部署前准备

### 1. 安装必要工具

#### 安装 Supabase CLI
```bash
# macOS (使用 Homebrew)
brew install supabase/tap/supabase

# 或使用 npm
npm install -g supabase

# 验证安装
supabase --version
```

#### 安装 Deno (用于本地测试)
```bash
# macOS
brew install deno

# 验证安装
deno --version
```

### 2. 获取必要的密钥

#### 2.1 获取 Supabase 密钥

1. 登录 [Supabase Dashboard](https://app.supabase.com)
2. 选择您的项目 (wqdpqhfqrxvssxifpmvt)
3. 进入 Settings → API
4. 复制以下密钥：
   - **Project URL**: `https://wqdpqhfqrxvssxifpmvt.supabase.co`
   - **Anon Key**: 公开密钥（客户端使用）
   - **Service Role Key**: 服务密钥（Edge Functions使用）⚠️ 保密

#### 2.2 获取火山引擎 API Key

1. 访问 [火山引擎控制台](https://console.volcengine.com)
2. 注册/登录账号
3. 进入「大模型服务」→「API管理」
4. 创建 API Key
5. 记录以下信息：
   - **API Key**: 您的API密钥
   - **API Endpoint**: `https://maas-api.volcengineapi.com/v3/chat/completions`
   - **Model ID**: `doubao-1.5-thinking-pro`

---

## 🔧 配置步骤

### Step 1: 克隆项目并进入函数目录

```bash
# 进入项目目录
cd /Volumes/wawa_outer_4T/Users/wawa002/Documents/XingQu

# 进入函数目录
cd supabase/functions
```

### Step 2: 配置环境变量

```bash
# 创建 .env 文件
cp .env.example .env

# 编辑 .env 文件
nano .env  # 或使用您喜欢的编辑器
```

在 `.env` 文件中填入实际值：
```env
# Supabase配置
SUPABASE_URL=https://wqdpqhfqrxvssxifpmvt.supabase.co
SUPABASE_SERVICE_ROLE_KEY=您的service_role_key

# 火山引擎API配置
VOLCANO_API_KEY=您的火山引擎API密钥
VOLCANO_API_URL=https://maas-api.volcengineapi.com/v3/chat/completions
VOLCANO_MODEL=doubao-1.5-thinking-pro

# CDN配置（可选）
CDN_BASE_URL=https://cdn.xingqu.app
```

### Step 3: 登录 Supabase CLI

```bash
# 登录 Supabase
supabase login

# 系统会打开浏览器，请授权登录
# 或者使用 Access Token 登录
supabase login --token YOUR_ACCESS_TOKEN
```

### Step 4: 链接到您的项目

```bash
# 链接项目
supabase link --project-ref wqdpqhfqrxvssxifpmvt

# 验证链接
supabase status
```

---

## 🚀 部署函数

### 方法一：使用部署脚本（推荐）

```bash
# 确保脚本有执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 方法二：手动部署每个函数

#### 部署 AI 对话函数
```bash
# 部署函数
supabase functions deploy ai-chat

# 设置环境变量
supabase secrets set VOLCANO_API_KEY="您的API密钥"
supabase secrets set VOLCANO_MODEL="doubao-1.5-thinking-pro"
```

#### 部署音频内容函数
```bash
# 部署函数
supabase functions deploy audio-content

# 设置CDN URL（如果有）
supabase secrets set CDN_BASE_URL="https://cdn.xingqu.app"
```

#### 部署用户权限函数
```bash
# 部署函数
supabase functions deploy user-permission
```

### 验证部署状态

```bash
# 查看所有已部署的函数
supabase functions list

# 查看函数日志
supabase functions logs ai-chat --tail
supabase functions logs audio-content --tail
supabase functions logs user-permission --tail
```

---

## 🧪 测试部署的函数

### Step 1: 获取测试用的 JWT Token

在您的 Flutter 应用中登录后，获取用户的 JWT Token：

```dart
// Flutter 代码示例
final session = supabase.auth.currentSession;
final token = session?.accessToken;
print('JWT Token: $token');
```

或者使用 Supabase Dashboard 的 SQL Editor：
```sql
-- 创建测试用户并获取 Token
-- 在 Authentication → Users 中创建用户
-- 然后使用该用户登录获取 Token
```

### Step 2: 测试 AI 对话函数

```bash
# 使用 curl 测试
curl -X POST \
  https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/ai-chat \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "你好，请介绍一下星趣APP",
    "stream": false
  }'
```

预期响应：
```json
{
  "sessionId": "uuid",
  "messageId": "uuid",
  "content": "星趣APP是一个...",
  "tokensUsed": 150,
  "cost": 0.0003
}
```

### Step 3: 测试音频内容函数

```bash
# 获取音频列表
curl -X POST \
  https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/audio-content \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "list",
    "category": "all",
    "page": 1,
    "pageSize": 10
  }'
```

### Step 4: 测试权限验证函数

```bash
# 检查用户权限
curl -X POST \
  https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/user-permission \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "check",
    "apiType": "llm"
  }'
```

### Step 5: 使用测试脚本

```bash
# 修改测试脚本中的 Token
nano test-functions.ts

# 更新以下变量
const TEST_USER_TOKEN = 'your_actual_jwt_token'

# 运行测试
deno run --allow-net test-functions.ts
```

---

## 📊 监控和日志

### 实时查看日志

```bash
# 查看所有函数日志
supabase functions logs --tail

# 查看特定函数日志
supabase functions logs ai-chat --tail --limit 100

# 查看错误日志
supabase functions logs ai-chat --tail | grep ERROR
```

### 在 Dashboard 中查看

1. 登录 Supabase Dashboard
2. 进入 Edge Functions 页面
3. 查看每个函数的：
   - 调用次数
   - 错误率
   - 响应时间
   - 日志输出

---

## 🔒 安全配置

### 1. 设置 CORS 策略

如果需要自定义 CORS，修改 `_shared/cors.ts`：

```typescript
export const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://your-domain.com', // 限制域名
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Max-Age': '86400',
}
```

### 2. 设置速率限制

在 Supabase Dashboard 中配置：
1. Settings → Edge Functions
2. 设置每个函数的速率限制
3. 推荐设置：
   - ai-chat: 10 requests/minute
   - audio-content: 30 requests/minute
   - user-permission: 50 requests/minute

### 3. 配置预算警报

在火山引擎控制台设置：
1. 费用中心 → 预算管理
2. 创建预算警报
3. 设置阈值（如 80% 时发送警报）

---

## 🐛 故障排查

### 常见问题和解决方案

#### 1. 函数部署失败
```bash
# 检查 Supabase CLI 版本
supabase --version

# 更新到最新版本
brew upgrade supabase

# 重新登录
supabase logout
supabase login
```

#### 2. JWT Token 验证失败
- 确认 Token 未过期
- 检查 Token 格式（应以 "Bearer " 开头）
- 验证项目 URL 和 Anon Key 配置正确

#### 3. 火山引擎 API 调用失败
- 检查 API Key 是否正确
- 验证账户余额充足
- 确认模型 ID 正确
- 查看 API 调用限制

#### 4. 函数超时
```bash
# 增加函数超时时间（默认 10 秒）
supabase functions deploy ai-chat --timeout 30
```

#### 5. 查看详细错误
```bash
# 获取函数的详细错误信息
supabase functions logs ai-chat --tail --limit 50 | grep -A 5 -B 5 ERROR
```

---

## ✅ 部署验证清单

完成部署后，请验证以下项目：

- [ ] Supabase CLI 已安装并登录
- [ ] 项目已正确链接
- [ ] 所有环境变量已设置
- [ ] 三个函数都已成功部署
- [ ] AI 对话函数测试通过
- [ ] 音频内容函数测试通过
- [ ] 权限验证函数测试通过
- [ ] 日志正常输出
- [ ] 无错误警告
- [ ] 响应时间 < 2秒

---

## 📈 性能优化建议

### 1. 启用函数预热
```bash
# 在部署时启用预热
supabase functions deploy ai-chat --keep-warm
```

### 2. 使用区域部署
选择离用户最近的区域：
- 中国用户：选择 Singapore (ap-southeast-1)
- 美国用户：选择 US East (us-east-1)

### 3. 优化冷启动
- 减少依赖包大小
- 使用轻量级库
- 预加载常用数据

---

## 🔄 更新和回滚

### 更新函数
```bash
# 修改代码后重新部署
supabase functions deploy ai-chat

# 部署特定版本
supabase functions deploy ai-chat --version v2
```

### 回滚到上一版本
```bash
# 查看部署历史
supabase functions list --all-versions

# 回滚到指定版本
supabase functions rollback ai-chat --version v1
```

---

## 📞 获取帮助

如果遇到问题：

1. **查看官方文档**: [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
2. **GitHub Issues**: [提交问题](https://github.com/joshua23/XingQu/issues)
3. **社区支持**: [Supabase Discord](https://discord.supabase.com)
4. **错误日志**: 始终先查看函数日志获取详细错误信息

---

## 🎉 部署成功标志

当您看到以下信息时，表示部署成功：

```
✅ Edge Functions 部署完成!

📚 函数访问地址：
  - AI对话: https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/ai-chat
  - 音频内容: https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/audio-content
  - 权限验证: https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/user-permission
```

恭喜！您的 Edge Functions 已经成功部署并可以使用了！🚀