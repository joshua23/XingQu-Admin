# 星趣App后台管理系统 - Web组件

基于React + TypeScript + Supabase的组件化后台管理系统，支持嵌入飞书多维表格。

## 📋 项目概述

本项目采用微前端架构，将后台管理功能拆分为独立的React组件，每个组件可以独立开发、测试和部署，并支持嵌入飞书多维表格中使用。

### 🏗️ 技术架构

- **前端框架**: React 18 + TypeScript
- **构建工具**: Vite + SWC
- **样式方案**: Tailwind CSS (Feishu适配主题)
- **数据层**: Supabase (PostgreSQL + Real-time + Auth)
- **状态管理**: SWR (数据获取和缓存)
- **包管理**: npm workspaces (monorepo)

### 🎯 设计原则

1. **组件化**: 每个功能模块独立封装
2. **嵌入友好**: 优化飞书多维表格集成体验
3. **响应式**: 自适应不同屏幕尺寸
4. **实时性**: 基于Supabase实时订阅
5. **轻量级**: 最小化包体积和依赖

## 📦 功能模块

### 🎯 统一管理入口
- **访问地址**: `http://localhost:3000`
- **路由结构**:
  - `/dashboard` - 实时数据看板
  - `/users` - 用户管理中心  
  - `/moderation` - 内容审核中心

### 1. 实时数据看板 (Dashboard)
- **路径**: `/dashboard`
- **功能**: 用户增长、收入分析、内容统计等实时指标
- **特色**: 图表可视化、自动刷新、趋势分析

### 2. 用户管理中心 (User Management)
- **路径**: `/users`
- **功能**: 用户CRUD、会员等级管理、批量操作
- **特色**: 高级筛选、数据导出、操作日志

### 3. 内容审核中心 (Content Moderation)
- **路径**: `/moderation`
- **功能**: 内容审核工作流、AI评分、批量审核
- **特色**: 优先级管理、多媒体预览、审核历史

## 🚀 快速开始

### 环境要求
- Node.js >= 16
- npm >= 7

### 安装依赖
```bash
npm install
```

### 环境配置
创建 `.env` 文件并配置Supabase连接:
```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 开发模式
```bash
# 启动统一后台管理系统
npm run dev

# 访问地址: http://localhost:3000
# - 包含侧边栏导航
# - 支持路由切换
# - 完整的管理功能

# 可选：单独启动组件（开发调试用）
npm run dev:components     # 启动所有独立组件
npm run dev:dashboard      # 仅启动数据看板 (端口3001)
npm run dev:user-mgmt      # 仅启动用户管理 (端口3002)
npm run dev:moderation     # 仅启动内容审核 (端口3003)
```

### 构建生产版本
```bash
npm run build
```

## 🔧 项目结构

```
web-components/
├── components/                 # 独立组件
│   ├── dashboard/             # 数据看板组件
│   │   ├── src/
│   │   │   ├── DashboardComponent.tsx
│   │   │   └── main.tsx      # 组件入口
│   │   ├── package.json
│   │   ├── vite.config.ts
│   │   └── index.html
│   ├── user-management/       # 用户管理组件
│   └── content-moderation/    # 内容审核组件
├── shared/                    # 共享库
│   ├── src/
│   │   ├── components/        # 通用UI组件
│   │   ├── services/          # Supabase服务层
│   │   ├── types/            # TypeScript类型定义
│   │   └── styles/           # 全局样式
│   └── tailwind.config.js    # Feishu适配主题
└── package.json              # 根配置文件
```

## 🎨 设计系统

### 主题配置
项目采用Light主题，适配飞书多维表格风格：

- **主色调**: Tech Green `#00b96b`
- **背景色**: `#ffffff` / `#f7f8fa` 
- **文本色**: `#1f2329` / `#646a73` / `#8b949f`
- **边框色**: `#e3e6ea` / `#d0d7de`

### 组件规范
- 统一的间距系统 (4px基准)
- 标准化的圆角 (6px/8px/12px)
- 一致的阴影效果
- 响应式断点设计

## 🔌 飞书集成

### 嵌入方式
每个组件都支持通过iframe嵌入飞书多维表格：

```html
<iframe 
  src="https://your-domain.com/dashboard?feishu_user_id=123&feishu_table_id=456"
  width="100%" 
  height="600"
  frameborder="0">
</iframe>
```

### 上下文参数
- `feishu_user_id`: 飞书用户ID
- `feishu_user_name`: 用户昵称
- `feishu_table_id`: 表格ID
- `permissions`: 权限列表
- `locale`: 语言设置 (`zh-CN`/`en-US`)
- `theme`: 主题设置 (`light`/`dark`)

### 消息通信
组件与飞书通过PostMessage API通信：

```typescript
// 发送给飞书
window.parent.postMessage({
  type: 'component_ready',
  data: { height: 600, title: '组件标题' }
}, '*');

// 接收飞书消息
window.addEventListener('message', (event) => {
  const { type, data } = event.data;
  // 处理消息
});
```

## 📊 数据层架构

### Supabase集成
- **Database**: PostgreSQL with Row Level Security
- **Auth**: 用户认证和权限管理
- **Realtime**: WebSocket实时数据订阅
- **Edge Functions**: 服务端逻辑处理

### 数据服务
共享的数据服务层 (`@xingqu/shared/services/supabase`):

```typescript
import { dataService } from '@xingqu/shared/src/services/supabase';

// 获取组件数据
const data = await dataService.getComponentData('dashboard', { 
  dateRange: '7d' 
});

// 实时订阅
const subscription = dataService.subscribeToTable(
  'users', 
  (payload) => console.log(payload)
);
```

## 🧪 测试和质量

### 测试策略
- **单元测试**: Vitest + Testing Library
- **集成测试**: 组件间数据流测试
- **E2E测试**: Playwright (飞书嵌入场景)

### 代码质量
- **TypeScript**: 严格类型检查
- **ESLint**: 代码规范检查
- **Prettier**: 代码格式化

### 性能优化
- **代码分割**: 按需加载
- **缓存策略**: SWR智能缓存
- **包体积**: Bundle analyzer监控

## 📈 部署和运维

### 部署方式
- **Vercel**: 推荐的部署平台
- **Docker**: 容器化部署
- **CDN**: 静态资源分发

### 监控和日志
- **组件使用**: Supabase Analytics
- **错误追踪**: 飞书消息通知
- **性能监控**: Web Vitals

## 🔒 安全考虑

- **CSP策略**: 内容安全策略配置
- **CORS**: 跨域请求限制  
- **RLS**: 数据库行级安全
- **输入验证**: Zod Schema验证

## 🤝 贡献指南

1. Fork本仓库
2. 创建feature分支
3. 遵循代码规范
4. 编写测试用例
5. 提交Pull Request

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

**星趣App后台管理系统** - 让管理更简单，让数据更清晰 ✨