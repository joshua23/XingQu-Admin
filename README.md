# 星趣App Web后台管理系统

## 🌟 概述

这是一个基于React + TypeScript + Vite构建的现代化web后台管理系统，为星趣App提供完整的数据分析、用户管理、内容审核等运营管理功能。

## 🚀 快速开始

### 环境要求
- Node.js 18+
- npm 或 yarn
- Supabase账户（用于数据连接）

### 安装依赖
```bash
npm install
```

### 启动开发服务器
```bash
npm run dev
```

访问地址：`http://localhost:3001`

### 生产构建
```bash
npm run build
npm run preview
```

## 📊 功能模块

### 🏠 数据总览
- 实时用户指标监控
- 收入数据统计
- 用户增长趋势分析
- 系统健康状态监控

### 👥 用户管理
- 用户信息查看和编辑
- 会员等级管理
- 用户状态控制（正常/禁用/未激活）
- 批量操作功能

### 🛡️ 内容审核
- AI内容自动审核
- 人工复审工作台
- 违规内容管理
- 审核统计报表

### 📈 数据分析
- 用户行为分析
- 收入数据统计
- 产品销售分析
- 数据导出功能

### ⚙️ 系统设置
- 基本系统配置
- API接口设置
- 安全策略配置
- 通知设置管理

## 🔧 技术栈

- **前端框架**: React 18 + TypeScript
- **构建工具**: Vite
- **UI框架**: Tailwind CSS
- **图标库**: Lucide React
- **状态管理**: React Context + Hooks
- **图表库**: Recharts
- **后端服务**: Supabase
- **代码质量**: ESLint

## 🏗️ 项目结构

```
xingqu-admin/
├── src/                   # 源代码目录
│   ├── components/        # 可复用组件
│   │   ├── Header.tsx    # 顶部导航栏
│   │   ├── Sidebar.tsx   # 侧边栏导航
│   │   └── ProtectedRoute.tsx # 路由保护
│   ├── contexts/         # React Context
│   │   ├── AuthContext.tsx     # 认证上下文
│   │   └── SidebarContext.tsx  # 侧边栏上下文
│   ├── hooks/            # 自定义Hooks
│   │   └── useAutoRefresh.ts  # 自动刷新Hook
│   ├── pages/           # 页面组件
│   │   ├── Dashboard.tsx       # 数据总览
│   │   ├── UserManagement.tsx  # 用户管理
│   │   ├── ContentModeration.tsx # 内容审核
│   │   ├── Analytics.tsx       # 数据分析
│   │   ├── Settings.tsx        # 系统设置
│   │   └── Login.tsx          # 登录页面
│   ├── services/        # 服务层
│   │   └── supabase.ts  # Supabase客户端
│   ├── types/           # TypeScript类型定义
│   │   └── index.ts     # 全局类型
│   ├── utils/           # 工具函数目录
│   ├── App.tsx          # 主应用组件
│   ├── main.tsx         # 应用入口
│   └── index.css        # 全局样式
├── node_modules/        # 依赖包（已忽略）
├── index.html           # HTML入口文件
├── package.json         # 项目配置
├── package-lock.json    # 依赖锁定文件
├── vite.config.ts       # Vite构建配置
├── tailwind.config.js   # Tailwind CSS配置
├── postcss.config.js    # PostCSS配置
├── tsconfig.json        # TypeScript配置
├── tsconfig.node.json   # Node.js TypeScript配置
├── .gitignore          # Git忽略文件
└── README.md           # 项目说明文档
```

## 🔐 认证系统

系统使用Supabase进行用户认证：

- **默认账户**: `admin@example.com`
- **默认密码**: `admin123`
- **支持功能**: 登录/登出、会话管理、权限验证

## 🎨 UI设计

- **主题**: 深色主题，符合星趣App品牌调性
- **色彩**: 主色调为金色(#FFD700)，辅助色为蓝色和绿色
- **布局**: 响应式设计，支持桌面端和移动端
- **组件**: 现代化卡片式布局，流畅的交互动画

## 📱 浏览器支持

- ✅ Chrome 90+
- ✅ Firefox 85+
- ✅ Safari 14+
- ✅ Edge 90+

## 🚀 部署说明

### 开发环境
```bash
npm run dev
```

### 生产环境
```bash
npm run build
npm run preview
```

### Docker部署
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3001
CMD ["npm", "run", "preview"]
```

## 🔧 配置说明

### Supabase配置
在 `src/services/supabase.ts` 中配置：
```typescript
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'your-supabase-url'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key'
```

### 环境变量
创建 `.env` 文件：
```env
VITE_SUPABASE_URL=your-supabase-project-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

## 📈 性能优化

- **代码分割**: 按路由进行代码分割
- **懒加载**: 组件和页面的懒加载
- **缓存策略**: 静态资源缓存优化
- **压缩**: Gzip压缩和资源优化

## 🛠️ 开发命令

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 预览生产构建
npm run preview

# 代码检查
npm run lint
```

## 📞 技术支持

如有问题或建议，请通过以下方式联系：

- 📧 邮箱: support@starfun.com
- 🐛 问题反馈: GitHub Issues
- 📚 文档: 项目Wiki

---

**Made with ❤️ for 星趣App**
