# 星趣App API&数据契约规范

> 本文档整合了星趣App的所有API接口规范、数据契约定义、第三方SDK集成规范，为开发团队提供完整的技术对接指南。

---

## 文档信息

- **文档版本**: v1.0.0
- **创建时间**: 2025年1月21日
- **最后更新**: 2025年1月21日
- **适用范围**: 星趣App开发团队、第三方集成商
- **文档状态**: 正式发布

---

## 目录

1. [概述](#1-概述)
2. [API接口规范](#2-api接口规范)
3. [数据契约定义](#3-数据契约定义)
4. [第三方SDK集成](#4-第三方sdk集成)
5. [安全与隐私](#5-安全与隐私)
6. [错误处理规范](#6-错误处理规范)
7. [性能与限制](#7-性能与限制)
8. [开发指南](#8-开发指南)

---

## 1. 概述

### 1.1 项目背景

星趣App是一个基于AI技术的社交娱乐平台，集成了多种AI能力：
- **AI角色对话**: 个性化角色扮演与上下文感知对话
- **语音交互**: 语音转文字、文字转语音、声音复刻
- **虚拟形象**: AI生成个性化虚拟形象
- **内容创作**: 智能创作辅助工具

### 1.2 技术架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端应用层     │    │   后端服务层     │    │   第三方服务层   │
│                 │    │                 │    │                 │
│ • Flutter App   │◄──►│ • Supabase      │◄──►│ • 火山引擎      │
│ • 响应式UI      │    │ • 实时数据库    │    │ • 大语言模型    │
│ • 状态管理      │    │ • 认证服务      │    │ • 语音服务      │
│ • 本地存储      │    │ • 文件存储      │    │ • 图像生成      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1.3 核心功能模块

| 模块 | 主要功能 | 技术栈 | 状态 |
|------|----------|--------|------|
| AI对话 | 角色扮演、上下文对话 | 火山引擎大模型 | ✅ 已完成 |
| 语音处理 | ASR/TTS/声音复刻 | 火山引擎语音服务 | ✅ 已完成 |
| 虚拟形象 | AI图像生成 | 火山引擎图像模型 | ✅ 已完成 |
| 用户系统 | 登录认证、用户管理 | Supabase Auth | ✅ 已完成 |
| 内容管理 | 对话历史、创作内容 | Supabase Database | ✅ 已完成 |

---

## 2. API接口规范

### 2.1 通用规范

#### 2.1.1 请求格式
```json
{
  "version": "1.0.0",
  "timestamp": 1640995200000,
  "request_id": "req_123456789",
  "data": {
    // 具体业务数据
  }
}
```

#### 2.1.2 响应格式
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    // 响应数据
  },
  "timestamp": 1640995200000,
  "request_id": "req_123456789"
}
```

#### 2.1.3 状态码定义

| 状态码 | 说明 | 处理建议 |
|--------|------|----------|
| 0 | 成功 | 正常处理 |
| 1001 | 参数错误 | 检查请求参数 |
| 1002 | 认证失败 | 重新获取token |
| 1003 | 权限不足 | 检查用户权限 |
| 2001 | 服务异常 | 稍后重试 |
| 2002 | 限流 | 降低请求频率 |
| 2003 | 维护中 | 等待服务恢复 |

### 2.2 AI对话接口

#### 2.2.1 接口信息
- **接口名称**: 角色扮演对话
- **请求地址**: `POST /api/v1/chat/roleplay`
- **服务平台**: 火山引擎大语言模型
- **推荐模型**: doubao-1.5-thinking-pro、doubao-1.5-pro-32k

#### 2.2.2 请求参数

```json
{
  "messages": [
    {
      "role": "system",
      "content": "你是一个温柔的AI女友。"
    },
    {
      "role": "user", 
      "content": "你好，可以和我聊聊吗？"
    }
  ],
  "role_profile": "温柔体贴的AI女友",
  "user_id": "user_123456",
  "temperature": 1.0,
  "max_tokens": 2048,
  "stream": false
}
```

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| messages | array | 是 | 对话历史 |
| role_profile | string | 否 | 角色设定 |
| user_id | string | 否 | 用户唯一标识 |
| temperature | float | 否 | 创意度(0-2) |
| max_tokens | int | 否 | 回复最大长度 |
| stream | bool | 否 | 是否流式返回 |

#### 2.2.3 响应示例

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "choices": [
      {
        "role": "assistant",
        "content": "你好呀，我是你的专属AI女友，有什么想聊的吗？"
      }
    ],
    "usage": {
      "prompt_tokens": 32,
      "completion_tokens": 64,
      "total_tokens": 96
    }
  }
}
```

### 2.3 语音处理接口

#### 2.3.1 语音转文字(ASR)

**请求地址**: `POST /api/v1/speech/asr`

```json
{
  "audio": "data:audio/wav;base64,UklGRiQAAABXQVZFZm10...",
  "format": "wav",
  "language": "zh-CN",
  "sample_rate": 16000
}
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "success", 
  "data": {
    "text": "你好，欢迎使用星趣App在线聊天功能。"
  }
}
```

#### 2.3.2 文字转语音(TTS)

**请求地址**: `POST /api/v1/speech/tts`

```json
{
  "text": "你好，欢迎使用星趣App！",
  "voice": "xiaoyan",
  "language": "zh-CN",
  "speed": 1.0,
  "pitch": 1.0,
  "volume": 1.0
}
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "audio": "data:audio/wav;base64,UklGRiQAAABXQVZFZm10..."
  }
}
```

#### 2.3.3 声音复刻

**请求地址**: `POST /api/v1/speech/clone`

```json
{
  "audio_sample": "data:audio/wav;base64,UklGRiQAAABXQVZFZm10...",
  "speaker_name": "小明-温柔女声",
  "style": "温柔",
  "accent": "普通话",
  "description": "用户自定义音色"
}
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "voice_id": "spk_abc123456",
    "status": "processing"
  }
}
```

### 2.4 虚拟形象生成接口

#### 2.4.1 接口信息
- **请求地址**: `POST /api/v1/image/generate`
- **模型ID**: doubao-t2idrawing

#### 2.4.2 请求参数

```json
{
  "prompt": "未来感少女，绿色短发，科技风，黑白主色调",
  "reference_img": "data:image/png;base64,iVBORw0KGgo...",
  "style": "二次元",
  "seed": 12345,
  "width": 512,
  "height": 512,
  "user_id": "user_123456"
}
```

#### 2.4.3 响应示例

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "image_url": "https://xxx/your_image.png",
    "task_id": "abc123456"
  }
}
```

---

## 3. 数据契约定义

### 3.1 用户数据模型

```typescript
interface User {
  id: string;                    // 用户唯一标识
  phone: string;                 // 手机号
  nickname: string;              // 昵称
  avatar: string;                // 头像URL
  gender: 'male' | 'female' | 'unknown'; // 性别
  birthday?: string;             // 生日
  location?: string;             // 位置
  bio?: string;                  // 个人简介
  vip_level: number;             // VIP等级
  created_at: string;            // 创建时间
  updated_at: string;            // 更新时间
}
```

### 3.2 AI角色数据模型

```typescript
interface AICharacter {
  id: string;                    // 角色唯一标识
  name: string;                  // 角色名称
  avatar: string;                // 角色头像
  description: string;           // 角色描述
  personality: string;           // 性格设定
  voice_id?: string;             // 关联音色ID
  creator_id: string;            // 创建者ID
  is_public: boolean;            // 是否公开
  tags: string[];                // 标签
  usage_count: number;           // 使用次数
  rating: number;                // 评分
  created_at: string;            // 创建时间
}
```

### 3.3 对话数据模型

```typescript
interface Conversation {
  id: string;                    // 对话唯一标识
  user_id: string;               // 用户ID
  character_id: string;          // AI角色ID
  title: string;                 // 对话标题
  messages: Message[];           // 消息列表
  created_at: string;            // 创建时间
  updated_at: string;            // 更新时间
  is_archived: boolean;          // 是否归档
}

interface Message {
  id: string;                    // 消息唯一标识
  conversation_id: string;       // 对话ID
  role: 'user' | 'assistant';   // 消息角色
  content: string;               // 消息内容
  content_type: 'text' | 'voice' | 'image'; // 内容类型
  timestamp: string;             // 时间戳
  metadata?: any;                // 元数据
}
```

### 3.4 创作内容数据模型

```typescript
interface CreativeContent {
  id: string;                    // 内容唯一标识
  user_id: string;               // 创建者ID
  title: string;                 // 标题
  content: string;               // 内容
  type: 'story' | 'poem' | 'script' | 'other'; // 内容类型
  tags: string[];                // 标签
  is_public: boolean;            // 是否公开
  likes_count: number;           // 点赞数
  comments_count: number;        // 评论数
  created_at: string;            // 创建时间
  updated_at: string;            // 更新时间
}
```

---

## 4. 第三方SDK集成

### 4.1 SDK分类汇总

| 分类 | SDK数量 | 主要厂商 | 用途 |
|------|---------|----------|------|
| 广告投放 | 2 | 腾讯、快手 | 广告展示与监测 |
| 登录认证 | 2 | 阿里、腾讯 | 一键登录、社交登录 |
| 支付服务 | 1 | 支付宝 | 在线支付 |
| 推送消息 | 4 | OPPO、华为、VIVO、小米 | 消息推送 |
| 音频通信 | 1 | 声网 | 语音通话 |
| 数据统计 | 3 | 神策、友盟 | 用户行为分析 |
| 云服务 | 1 | 阿里云 | 风险控制 |

### 4.2 广告投放类SDK

#### 4.2.1 优量汇SDK
```json
{
  "sdk_name": "优量汇SDK",
  "provider": "深圳市腾讯计算机系统有限公司",
  "purpose": "广告投放、广告监测、广告归因、反作弊",
  "permissions": ["位置权限", "存储权限"],
  "personal_info": [
    "粗略位置信息",
    "设备信息(设备制造商、设备型号、操作系统版本等)",
    "设备标识符(AndroidID、OAID、IDFA等)",
    "应用信息(宿主应用的包名、版本号)",
    "广告数据(如曝光)"
  ],
  "privacy_policy": "https://e.qq.com/dev/help_detail.html?cid=2005&p"
}
```

#### 4.2.2 快手联盟SDK
```json
{
  "sdk_name": "快手联盟SDK",
  "provider": "北京快手广告有限公司",
  "purpose": "广告推送、监测归因、反作弊、应用下载广告投放",
  "permissions": [
    "读取手机设备信息权限",
    "获取位置功能权限",
    "允许应用程序访问有关WI-Fi网络权限",
    "允许应用程序写/读权限",
    "获取应用软件列表权限"
  ],
  "personal_info": [
    "设备序列号",
    "设备品牌",
    "设备型号"
  ]
}
```

### 4.3 登录认证类SDK

#### 4.3.1 阿里一键登录
```json
{
  "sdk_name": "阿里一键登录",
  "provider": "阿里云计算有限公司",
  "purpose": "登录功能",
  "scenario": "手机号一键登录",
  "shared_info": "设备识别信息",
  "privacy_policy": "https://help.aliyun.com/document_detail/84540.html"
}
```

#### 4.3.2 微信SDK
```json
{
  "sdk_name": "微信SDK",
  "provider": "深圳市腾讯计算机系统有限公司",
  "purpose": "微信授权登录、微信分享、微信支付",
  "scenario": "微信相关功能",
  "shared_info": ["MAC地址", "唯一设备识别码"],
  "privacy_policy": "https://openweixin.qq.com/cgi-bin/frame?t=news/protocol_developer_tmpl"
}
```

### 4.4 推送消息类SDK

#### 4.4.1 厂商推送SDK配置

| 厂商 | SDK名称 | 权限要求 | 隐私政策 |
|------|---------|----------|----------|
| OPPO | OPPO PUSH SDK | 网络、WIFI、手机状态、存储、安装权限、前台服务 | https://open.cppomobile.com/wiki/doc#id=10196 |
| 华为 | 华为 PUSH SDK | 网络、WIFI、手机状态、存储、安装权限、前台服务 | https://developer.huawei.com/consumer/cn/doc/development/HMSCore-Guides/sdk-data-security-0000001050042177 |
| VIVO | VIVO PUSH SDK | 网络、WIFI、手机状态、存储、安装权限、前台服务 | https://dev.vivo.com.cn/documentcenter/doc/366 |
| 小米 | 小米 PUSH SDK | 网络、WIFI、手机状态、存储、安装权限、前台服务 | https://dev.mi.com/console/doc/detail?pld=182 |

### 4.5 数据统计分析类SDK

#### 4.5.1 神策SDK
```json
{
  "sdk_name": "神策SDK",
  "provider": "神策网络科技(北京)有限公司",
  "purpose": "埋点上报，用户来源归因",
  "scenario": "用户使用应用期间的交互",
  "shared_info": "设备信息(OAID/IMEI/Mac/AndroidID/IDFA/OPENUDID/GUID/SIM卡IMSI)",
  "privacy_policy": "https://www.sensorsdata.cn/compliance/privacy.html"
}
```

#### 4.5.2 友盟SDK
```json
{
  "sdk_name": "友盟SDK",
  "provider": "友盟同欣(北京)科技有限公司",
  "purpose": "推送消息、埋点上报、性能监控、个人信息认证、社会化分享",
  "scenario": "向用户推送通知，用户行为埋点记录，应用性能监控，一键登录手机认证，分享内容到第三方",
  "shared_info": "设备信息(IMEI/Mac/AndroidID/IDFA/OPENUDID/GUID/SIM卡IMSI)",
  "privacy_policy": "https://www.umeng.com/page/policy"
}
```

---

## 5. 安全与隐私

### 5.1 数据安全规范

#### 5.1.1 数据传输安全
- 所有API接口必须使用HTTPS协议
- 敏感数据必须加密传输
- 实现请求签名验证机制
- 支持API Key认证

#### 5.1.2 数据存储安全
- 用户密码必须加密存储
- 敏感信息脱敏处理
- 定期数据备份
- 实现数据访问权限控制

#### 5.1.3 隐私保护措施
- 最小化数据收集原则
- 用户数据删除权
- 数据使用透明度
- 定期隐私政策更新

### 5.2 权限管理

#### 5.2.1 应用权限清单
```json
{
  "required_permissions": [
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.READ_PHONE_STATE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.READ_EXTERNAL_STORAGE"
  ],
  "optional_permissions": [
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO"
  ]
}
```

#### 5.2.2 权限使用说明
- **网络权限**: 用于API接口调用、文件下载
- **存储权限**: 用于缓存数据、保存文件
- **位置权限**: 用于个性化推荐、广告投放
- **相机权限**: 用于头像拍摄、图片上传
- **录音权限**: 用于语音输入、声音复刻

### 5.3 个人信息保护

#### 5.3.1 收集的个人信息类型
```json
{
  "basic_info": [
    "手机号码",
    "昵称",
    "头像",
    "性别",
    "生日"
  ],
  "device_info": [
    "设备标识符",
    "设备型号",
    "操作系统版本",
    "应用版本号"
  ],
  "usage_info": [
    "使用记录",
    "偏好设置",
    "互动数据"
  ]
}
```

#### 5.3.2 数据使用目的
- 提供核心功能服务
- 个性化推荐
- 安全防护
- 产品优化
- 客户服务

---

## 6. 错误处理规范

### 6.1 错误码定义

| 错误码 | 错误类型 | 错误描述 | 处理建议 |
|--------|----------|----------|----------|
| 1001 | 参数错误 | 请求参数格式错误或缺失 | 检查参数格式和必填项 |
| 1002 | 认证失败 | Token无效或已过期 | 重新获取认证Token |
| 1003 | 权限不足 | 用户权限不足 | 检查用户权限等级 |
| 1004 | 资源不存在 | 请求的资源不存在 | 检查资源ID是否正确 |
| 2001 | 服务异常 | 服务器内部错误 | 稍后重试或联系技术支持 |
| 2002 | 限流 | 请求频率超限 | 降低请求频率 |
| 2003 | 维护中 | 服务正在维护 | 等待服务恢复 |
| 3001 | 网络错误 | 网络连接异常 | 检查网络连接 |
| 3002 | 超时 | 请求超时 | 增加超时时间或重试 |

### 6.2 错误响应格式

```json
{
  "code": 1001,
  "msg": "参数错误",
  "data": {
    "field": "user_id",
    "reason": "用户ID不能为空"
  },
  "timestamp": 1640995200000,
  "request_id": "req_123456789"
}
```

### 6.3 异常处理建议

#### 6.3.1 客户端处理
- 网络异常时显示重试按钮
- 认证失败时跳转登录页面
- 权限不足时显示升级提示
- 服务异常时显示友好错误信息

#### 6.3.2 服务端处理
- 记录详细错误日志
- 实现优雅降级机制
- 提供错误监控告警
- 定期错误统计分析

---

## 7. 性能与限制

### 7.1 API限制

| 接口类型 | 频率限制 | 并发限制 | 数据大小限制 |
|----------|----------|----------|--------------|
| AI对话 | 100次/分钟 | 10并发 | 4KB/请求 |
| 语音转文字 | 50次/分钟 | 5并发 | 10MB/文件 |
| 文字转语音 | 100次/分钟 | 10并发 | 500字符/请求 |
| 图像生成 | 20次/分钟 | 3并发 | 2MB/请求 |
| 声音复刻 | 5次/小时 | 1并发 | 50MB/文件 |

### 7.2 性能优化建议

#### 7.2.1 客户端优化
- 实现请求缓存机制
- 使用图片懒加载
- 压缩上传文件
- 实现断点续传

#### 7.2.2 服务端优化
- 使用CDN加速
- 实现数据缓存
- 异步处理耗时操作
- 数据库查询优化

### 7.3 监控指标

#### 7.3.1 性能指标
- API响应时间 < 2秒
- 成功率 > 99%
- 并发处理能力 > 1000 QPS
- 系统可用性 > 99.9%

#### 7.3.2 业务指标
- 日活跃用户数
- 用户留存率
- 功能使用频率
- 用户满意度

---

## 8. 开发指南

### 8.1 开发环境配置

#### 8.1.1 必需工具
- Flutter SDK 3.0+
- Android Studio / VS Code
- Git版本控制
- Postman API测试工具

#### 8.1.2 开发依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^1.0.0
  dio: ^5.0.0
  shared_preferences: ^2.0.0
  image_picker: ^0.8.0
  permission_handler: ^10.0.0
```

### 8.2 代码规范

#### 8.2.1 命名规范
- 类名使用PascalCase
- 变量名使用camelCase
- 常量使用UPPER_SNAKE_CASE
- 文件名使用snake_case

#### 8.2.2 注释规范
```dart
/// 用户服务类
/// 提供用户相关的API调用功能
class UserService {
  /// 用户登录
  /// [phone] 手机号
  /// [code] 验证码
  /// 返回登录结果
  Future<LoginResult> login(String phone, String code) async {
    // 实现代码
  }
}
```

### 8.3 测试规范

#### 8.3.1 单元测试
- 核心业务逻辑必须编写单元测试
- 测试覆盖率 > 80%
- 使用Mock对象模拟外部依赖

#### 8.3.2 集成测试
- API接口集成测试
- 第三方SDK集成测试
- 端到端功能测试

### 8.4 部署规范

#### 8.4.1 版本管理
- 使用语义化版本号
- 维护更新日志
- 支持热更新机制

#### 8.4.2 发布流程
1. 代码审查
2. 自动化测试
3. 预发布验证
4. 灰度发布
5. 全量发布

---

## 附录

### A. 常用工具链接

- [火山引擎官方文档](https://www.volcengine.com/docs/)
- [Supabase官方文档](https://supabase.com/docs)
- [Flutter官方文档](https://flutter.dev/docs)
- [星趣App设计规范](星趣app-UI风格指南.md)

### B. 联系方式

- **技术支持**: tech-support@starfun.com
- **产品反馈**: feedback@starfun.com
- **商务合作**: business@starfun.com

### C. 更新日志

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0.0 | 2025-01-21 | 初始版本，整合所有API文档 |

---

> 本文档将持续更新，请关注最新版本。
> 如有疑问，请联系技术支持团队。 