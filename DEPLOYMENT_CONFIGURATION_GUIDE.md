# 星趣App 部署配置指南

## 📋 配置清单

### ✅ 已完成配置

#### 1. Supabase项目信息
- **Project ID**: `wqdpqhfqrxvssxifpmvt`
- **Project URL**: `https://wqdpqhfqrxvssxifpmvt.supabase.co`
- **Anon Key**: 已配置在 `lib/config/supabase_config.dart`
- **Service Role Key**: 已配置在 `.env.functions`

#### 2. 火山引擎配置
- **API Key**: `30332b4d-603c-424c-b508-8653a8d8f2ad`
- **API URL**: `https://maas-api.volcengineapi.com/v3/chat/completions`
- **Model**: `doubao-1.5-thinking-pro`

### 🚀 部署步骤

## 第一步：安装 Supabase CLI

```bash
# macOS (使用 Homebrew)
brew install supabase/tap/supabase

# 或使用 npm
npm install -g supabase

# 验证安装
supabase --version
```

## 第二步：登录并链接项目

```bash
# 登录 Supabase
supabase login

# 链接到项目
supabase link --project-ref wqdpqhfqrxvssxifpmvt
```

## 第三步：部署 Edge Functions

### 方法1：使用批量部署脚本（推荐）

```bash
# 进入functions目录
cd supabase/functions

# 添加执行权限
chmod +x deploy_all.sh

# 执行部署脚本
./deploy_all.sh
```

### 方法2：手动部署单个函数

```bash
# 部署单个函数
supabase functions deploy ai-chat --project-ref wqdpqhfqrxvssxifpmvt
supabase functions deploy audio-content --project-ref wqdpqhfqrxvssxifpmvt
supabase functions deploy user-permission --project-ref wqdpqhfqrxvssxifpmvt
# ... 继续部署其他函数
```

## 第四步：设置环境变量

### 方法1：使用环境变量文件（推荐）

```bash
# 使用已创建的 .env.functions 文件
supabase secrets set --env-file .env.functions --project-ref wqdpqhfqrxvssxifpmvt
```

### 方法2：手动设置单个变量

```bash
# 设置火山引擎 API Key
supabase secrets set VOLCANO_API_KEY=30332b4d-603c-424c-b508-8653a8d8f2ad --project-ref wqdpqhfqrxvssxifpmvt

# 设置其他必要的环境变量
supabase secrets set VOLCANO_API_URL=https://maas-api.volcengineapi.com/v3/chat/completions --project-ref wqdpqhfqrxvssxifpmvt
supabase secrets set VOLCANO_MODEL=doubao-1.5-thinking-pro --project-ref wqdpqhfqrxvssxifpmvt
```

## 第五步：验证部署

### 1. 查看函数状态

```bash
# 查看所有函数
supabase functions list --project-ref wqdpqhfqrxvssxifpmvt

# 查看特定函数日志
supabase functions logs ai-chat --project-ref wqdpqhfqrxvssxifpmvt
```

### 2. 测试 API 端点

#### 测试 AI 对话服务

```bash
curl -X POST https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/ai-chat \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w" \
  -H "Content-Type: application/json" \
  -d '{"message": "你好，我是星趣App用户"}'
```

#### 测试音频内容服务

```bash
curl -X POST https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/audio-content \
  -H "Content-Type: application/json" \
  -d '{"action": "list", "category": "all", "page": 1, "pageSize": 10}'
```

## 📊 Edge Functions 列表

| 函数名 | 功能描述 | 状态 | 端点 |
|--------|----------|------|------|
| ai-chat | AI对话服务（火山引擎） | 待部署 | `/functions/v1/ai-chat` |
| audio-content | 音频内容管理 | 待部署 | `/functions/v1/audio-content` |
| user-permission | 用户权限验证 | 待部署 | `/functions/v1/user-permission` |
| analytics-metrics | 数据分析指标 | 待部署 | `/functions/v1/analytics-metrics` |
| analytics-processor | 分析数据处理 | 待部署 | `/functions/v1/analytics-processor` |
| recommendations | 推荐系统 | 待部署 | `/functions/v1/recommendations` |
| user-subscriptions | 订阅管理 | 待部署 | `/functions/v1/user-subscriptions` |
| interaction-menu | 交互菜单 | 待部署 | `/functions/v1/interaction-menu` |
| memory-manager | 记忆管理 | 待部署 | `/functions/v1/memory-manager` |

## 🔍 故障排查

### 问题1：函数部署失败

```bash
# 检查项目配置
supabase projects list

# 重新链接项目
supabase link --project-ref wqdpqhfqrxvssxifpmvt

# 查看详细错误
supabase functions deploy <function-name> --debug
```

### 问题2：环境变量未生效

```bash
# 列出所有secrets
supabase secrets list --project-ref wqdpqhfqrxvssxifpmvt

# 删除并重新设置
supabase secrets unset VOLCANO_API_KEY --project-ref wqdpqhfqrxvssxifpmvt
supabase secrets set VOLCANO_API_KEY=30332b4d-603c-424c-b508-8653a8d8f2ad --project-ref wqdpqhfqrxvssxifpmvt
```

### 问题3：API调用失败

1. 检查认证Token是否正确
2. 查看函数日志：`supabase functions logs <function-name>`
3. 验证火山引擎API Key是否有效
4. 确认数据库RLS策略是否正确配置

## 📝 注意事项

1. **安全性**：
   - 不要将 Service Role Key 暴露在客户端代码中
   - 定期轮换 API Keys
   - 使用环境变量管理敏感信息

2. **性能优化**：
   - Edge Functions 有冷启动时间，首次调用可能较慢
   - 考虑实现函数预热机制
   - 监控API调用量和成本

3. **监控**：
   - 定期查看函数执行日志
   - 设置异常告警
   - 监控火山引擎API使用量

## 🎯 下一步行动

1. ✅ 执行部署脚本
2. ✅ 验证所有函数部署成功
3. ✅ 测试核心API功能
4. ⏳ 集成到Flutter应用
5. ⏳ 配置生产环境监控

## 📞 支持

如遇到问题，请查看：
- [Supabase文档](https://supabase.com/docs)
- [火山引擎文档](https://www.volcengine.com/docs)
- 项目Issue追踪：GitHub Issues

---

*最后更新：2025年1月*