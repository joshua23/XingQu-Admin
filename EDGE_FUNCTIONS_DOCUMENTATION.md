# Edge Functions API 文档

## 概述

星趣APP Edge Functions 提供了三个核心API服务，用于处理AI对话、音频内容和用户权限验证。所有函数都部署在Supabase Edge Functions平台上，提供低延迟、高可用的服务。

## 基础信息

- **基础URL**: `https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1`
- **认证方式**: Bearer Token (JWT)
- **内容类型**: `application/json`

## API端点

### 1. AI对话服务

#### 端点
```
POST /ai-chat
```

#### 请求头
```http
Authorization: Bearer {user_jwt_token}
Content-Type: application/json
```

#### 请求体
```json
{
  "sessionId": "uuid (可选，不提供则创建新会话)",
  "message": "用户消息内容",
  "characterId": "AI角色ID (可选)",
  "stream": false,
  "temperature": 0.7,
  "maxTokens": 2048
}
```

#### 响应
```json
{
  "sessionId": "会话ID",
  "messageId": "消息ID",
  "content": "AI回复内容",
  "tokensUsed": 150,
  "cost": 0.0003
}
```

#### 流式响应
当 `stream: true` 时，返回 Server-Sent Events (SSE) 流：
```
data: {"content": "部分内容"}
data: {"content": "更多内容"}
data: [DONE]
```

#### 错误响应
```json
{
  "error": "错误信息",
  "details": {}
}
```

---

### 2. 音频内容服务

#### 端点
```
POST /audio-content
```

#### 请求头
```http
Authorization: Bearer {user_jwt_token} (可选，支持匿名访问)
Content-Type: application/json
```

#### 操作类型

##### 获取音频列表
```json
{
  "action": "list",
  "category": "music|podcast|audiobook|all",
  "page": 1,
  "pageSize": 20
}
```

响应：
```json
{
  "success": true,
  "data": {
    "contents": [
      {
        "id": "uuid",
        "title": "音频标题",
        "artist": "艺术家",
        "duration_seconds": 180,
        "thumbnail_url": "缩略图URL",
        "streamUrl": "流媒体URL",
        "playProgress": 30.5,
        "stats": {
          "totalPlayTime": 10000,
          "uniqueListeners": 500,
          "completionRate": 0.85
        }
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

##### 获取音频详情
```json
{
  "action": "detail",
  "audioId": "uuid"
}
```

响应：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "音频标题",
    "streamConfig": {
      "primaryUrl": "主流媒体URL",
      "backupUrl": "备用URL",
      "qualityLevels": [
        {"quality": "low", "bitrate": 64, "format": "mp3"},
        {"quality": "medium", "bitrate": 128, "format": "mp3"},
        {"quality": "high", "bitrate": 320, "format": "mp3"}
      ],
      "adaptiveStreaming": true,
      "cdnRegions": ["cn-north", "cn-east"]
    }
  }
}
```

##### 开始播放
```json
{
  "action": "play",
  "audioId": "uuid",
  "quality": "medium"
}
```

响应：
```json
{
  "success": true,
  "data": {
    "sessionId": "播放会话ID",
    "streamUrl": "带参数的流媒体URL",
    "backupUrl": "备用URL",
    "quality": {
      "bitrate": 128
    }
  }
}
```

##### 记录播放进度
```json
{
  "action": "record_play",
  "audioId": "uuid",
  "playPosition": 120,
  "completed": false
}
```

响应：
```json
{
  "success": true,
  "data": {
    "sessionId": "会话ID",
    "progress": 60.5,
    "completed": false
  }
}
```

---

### 3. 用户权限服务

#### 端点
```
POST /user-permission
```

#### 请求头
```http
Authorization: Bearer {user_jwt_token}
Content-Type: application/json
```

#### 操作类型

##### 检查权限
```json
{
  "action": "check",
  "apiType": "llm|tts|asr|image_gen"
}
```

响应：
```json
{
  "success": true,
  "allowed": true,
  "data": {
    "feature": true,
    "quota": {
      "allowed": true,
      "quota_remaining": 95,
      "quota_limit": 100,
      "quota_used": 5
    },
    "permissions": {
      "membership": {
        "planType": "premium",
        "status": "active",
        "expiresAt": "2025-12-31T23:59:59Z"
      },
      "features": {
        "aiChatUnlimited": true,
        "voiceInteraction": true,
        "imageGeneration": true,
        "customAgents": true,
        "premiumModels": true
      },
      "quotas": {
        "llm": {
          "limit": -1,
          "used": 150,
          "remaining": -1,
          "resetAt": "2025-01-08T00:00:00Z"
        }
      }
    }
  }
}
```

##### 获取使用统计
```json
{
  "action": "get_usage"
}
```

响应：
```json
{
  "success": true,
  "data": {
    "today": {
      "apiCalls": 25,
      "totalCost": 0.05,
      "tokensUsed": 25000
    },
    "thisMonth": {
      "apiCalls": 500,
      "totalCost": 1.20,
      "tokensUsed": 600000
    },
    "byApiType": {
      "llm": {
        "requests": 400,
        "tokens": 500000,
        "cost": 1.00
      },
      "tts": {
        "requests": 100,
        "tokens": 100000,
        "cost": 0.20
      }
    }
  }
}
```

##### 验证功能
```json
{
  "action": "verify_feature",
  "feature": "custom_agents"
}
```

响应：
```json
{
  "success": true,
  "allowed": true,
  "data": {
    "feature": "custom_agents",
    "membershipType": "premium",
    "planName": "高级会员",
    "hasAccess": true,
    "expiresAt": "2025-12-31T23:59:59Z"
  }
}
```

## 错误代码

| 状态码 | 说明 |
|-------|------|
| 200 | 成功 |
| 401 | 未授权，Token无效或缺失 |
| 429 | 超出API配额限制 |
| 500 | 服务器内部错误 |

## 使用示例

### JavaScript/TypeScript
```typescript
// AI对话示例
const response = await fetch('https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/ai-chat', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${userToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    message: '你好，星趣',
    stream: false
  })
})

const data = await response.json()
console.log('AI回复:', data.content)
```

### Flutter/Dart
```dart
// 音频播放示例
final response = await http.post(
  Uri.parse('https://wqdpqhfqrxvssxifpmvt.supabase.co/functions/v1/audio-content'),
  headers: {
    'Authorization': 'Bearer $userToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'action': 'play',
    'audioId': audioId,
    'quality': 'high',
  }),
);

final data = jsonDecode(response.body);
final streamUrl = data['data']['streamUrl'];
```

## 本地开发

### 运行本地服务
```bash
# 启动所有函数
supabase functions serve

# 启动特定函数
supabase functions serve ai-chat --env-file .env.local
```

### 测试
```bash
# 运行测试脚本
deno run --allow-net test-functions.ts
```

## 部署

### 部署到生产环境
```bash
# 部署所有函数
./deploy.sh

# 部署单个函数
supabase functions deploy ai-chat
```

### 设置环境变量
```bash
supabase secrets set VOLCANO_API_KEY=your_api_key
supabase secrets set CDN_BASE_URL=https://cdn.xingqu.app
```

## 监控和日志

### 查看函数日志
```bash
supabase functions logs ai-chat --tail
```

### 监控指标
- 请求数量
- 响应时间
- 错误率
- Token使用量
- API成本

## 安全注意事项

1. **认证验证**: 所有需要用户身份的操作都必须验证JWT Token
2. **配额控制**: 严格执行API配额限制，防止滥用
3. **成本监控**: 实时跟踪API使用成本，设置预警阈值
4. **内容审核**: AI生成内容需要经过内容安全审核
5. **数据隔离**: 使用RLS确保用户数据完全隔离

## 性能优化

1. **缓存策略**: 音频内容使用CDN缓存
2. **流式响应**: AI对话支持流式输出，减少等待时间
3. **连接池**: 复用数据库连接，提高响应速度
4. **异步处理**: 非关键操作异步处理，不阻塞主流程

## 故障处理

### 常见问题

#### 1. Token验证失败
- 检查Token是否过期
- 确认Token格式正确
- 验证Supabase项目配置

#### 2. API配额超限
- 检查用户配额设置
- 验证会员权限
- 重置配额计数器

#### 3. 火山引擎API错误
- 检查API Key配置
- 验证模型可用性
- 查看API余额

## 支持和反馈

- GitHub Issues: [https://github.com/joshua23/XingQu/issues](https://github.com/joshua23/XingQu/issues)
- 技术支持邮箱: support@xingqu.app
- 文档更新: 2025年1月7日