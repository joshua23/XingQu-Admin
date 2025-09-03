# 星趣App Web后台管理系统

## 🌟 概述

这是一个基于React + TypeScript + Vite构建的现代化web后台管理系统，为星趣App提供完整的数据分析、用户管理、内容审核等运营管理功能。

## 📋 分支说明

**当前分支**: `web-components-only`
**分支用途**: 独立的web后台管理系统项目，移除了所有Flutter相关代码
**项目状态**: ✅ 纯净的web项目，可直接部署使用

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

### 📚 Supabase 开发文档
- [Supabase 最佳实践文档](./docs/supabase-best-practices.md) - 全面的 Supabase 使用指南
- [项目专用 Supabase 指南](./docs/project-supabase-guide.md) - 本项目特定的配置和常见问题

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

# Claude 开发助手指南

## 🗄️ Supabase 数据库查询最佳实践

### 使用 Supabase CLI 查询数据库

当需要查询 Supabase 数据库信息时，**优先使用以下方法**，而不是通过 JavaScript API 猜测：

#### 1. 查询所有以 "xq_" 开头的表

**✅ 验证有效的连接方法** (2025-01-02 测试成功):

```bash
# 🎯 推荐方法1: 查询所有 xq_ 表及字段数
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT 
    table_name, 
    table_type, 
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_name = t.table_name AND table_schema = 'public') as column_count 
FROM information_schema.tables t 
WHERE table_schema = 'public' 
  AND table_name LIKE 'xq_%' 
ORDER BY table_name;
"

# 🎯 推荐方法2: 获取表行数统计
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT 
    schemaname, 
    relname as tablename, 
    n_live_tup as row_count 
FROM pg_stat_user_tables 
WHERE schemaname = 'public' 
  AND relname LIKE 'xq_%' 
ORDER BY n_live_tup DESC, relname;
"

# 🎯 推荐方法3: 简单列表查询
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'xq_%' 
ORDER BY table_name;
"
```

**🗂️ 已验证的表结构 (共12张表)**:
- ✅ **有数据**: xq_tracking_events(35行), xq_user_sessions(3行), xq_feedback(1行), xq_user_profiles(1行), xq_user_settings(1行)
- 🔶 **空表**: xq_account_deletion_requests, xq_agents, xq_avatars, xq_background_music, xq_fm_programs, xq_user_blacklist, xq_voices

#### 2. 查看特定表的结构

```bash
# ✅ 查看完整表结构 (推荐)
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "\d+ xq_user_profiles"

# ✅ 查看 AI 代理表结构 (重要表)
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "\d+ xq_agents"

# ✅ 查看行为追踪表结构 (数据最多的表)
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "\d+ xq_tracking_events"

# 获取列信息的标准查询
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'xq_user_profiles' 
  AND table_schema = 'public'
ORDER BY ordinal_position;
"
```

**💡 重要发现**:
- **xq_user_profiles**: 22个字段，包含完整的用户信息和社交功能
- **xq_agents**: 15个字段，AI代理系统，包含个性、头像、语音等
- **xq_tracking_events**: 8个字段，支持用户和访客行为追踪

#### 3. 查看表的数据量和示例数据

```bash
# ✅ 查看所有表的行数 (已验证有效)
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT 
    schemaname, 
    relname as tablename, 
    n_live_tup as row_count 
FROM pg_stat_user_tables 
WHERE schemaname = 'public' 
  AND relname LIKE 'xq_%' 
ORDER BY n_live_tup DESC, relname;
"

# ✅ 查看有数据的表的示例内容
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
-- 查看用户资料示例
SELECT id, user_id, nickname, account_status, is_member, created_at 
FROM xq_user_profiles 
LIMIT 2;
"

# ✅ 查看行为追踪数据示例 (数据最多的表)
psql "postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres" -c "
SELECT event_type, COUNT(*) as count 
FROM xq_tracking_events 
GROUP BY event_type 
ORDER BY count DESC;
"
```

**📊 实际数据分布** (已验证):
- **xq_tracking_events**: 35行 - 用户行为数据
- **xq_user_sessions**: 3行 - 会话记录  
- **xq_feedback**: 1行 - 用户反馈
- **xq_user_profiles**: 1行 - 用户资料
- **xq_user_settings**: 1行 - 用户设置

#### 4. 一键完整报告脚本

**✅ 已验证可用的完整查询脚本**:

```bash
#!/bin/bash
# 星趣App数据库完整报告生成器 (已验证 2025-01-02)

DB_URL="postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres"

echo "🔍 星趣App Supabase 数据库完整报告"
echo "==========================================="
echo "生成时间: $(date)"
echo "项目: 星趣App (wqdpqhfqrxvssxifpmvt)"
echo

echo "📋 1. 所有 xq_ 表概览:"
psql "$DB_URL" -c "
SELECT 
    table_name, 
    table_type, 
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_name = t.table_name AND table_schema = 'public') as column_count 
FROM information_schema.tables t 
WHERE table_schema = 'public' 
  AND table_name LIKE 'xq_%' 
ORDER BY table_name;
"

echo -e "\n📊 2. 数据统计 (按数据量排序):"
psql "$DB_URL" -c "
SELECT 
    schemaname, 
    relname as tablename, 
    n_live_tup as row_count 
FROM pg_stat_user_tables 
WHERE schemaname = 'public' 
  AND relname LIKE 'xq_%' 
ORDER BY n_live_tup DESC, relname;
"

echo -e "\n🏗️  3. 核心表详细结构:"
echo "--- xq_user_profiles (用户资料) ---"
psql "$DB_URL" -c "\d+ xq_user_profiles"

echo -e "\n--- xq_agents (AI代理) ---"
psql "$DB_URL" -c "\d+ xq_agents"

echo -e "\n--- xq_tracking_events (行为追踪) ---"
psql "$DB_URL" -c "\d+ xq_tracking_events"

echo -e "\n💡 4. 数据示例:"
psql "$DB_URL" -c "
SELECT '=== 行为追踪事件类型统计 ===' as info;
SELECT event_type, COUNT(*) as count 
FROM xq_tracking_events 
GROUP BY event_type 
ORDER BY count DESC;
"

echo -e "\n✅ 报告生成完成"
echo "📁 将此报告保存到文档: docs/supabase-tables-report.md"
```

**快速使用**:
```bash
# 保存为文件并运行
cat > supabase-report.sh << 'EOF'
[上面的脚本内容]
EOF
chmod +x supabase-report.sh
./supabase-report.sh
```

### 🚫 避免的方法 (经验教训)

**❌ 绝对不要再使用以下错误方法**：
- **JavaScript API 暴力枚举**: 之前用 JS 猜测了52个表名，实际只有12个
- **错误的连接字符串**: `db.wqdpqhfqrxvssxifpmvt.supabase.co` DNS解析失败
- **API 权限猜测**: 通过 `supabase.from(tableName)` 返回误导性结果
- **创建临时脚本**: 浪费时间且结果不准确

**⚠️ 为什么这些方法失败**:
- API 查询受 RLS 策略限制，无法获得准确的表存在性
- DNS 解析问题导致直连失败
- JavaScript 客户端查询不等同于数据库管理查询

### ⚠️ 重要提醒

**每当需要查询 Supabase 数据库结构时**：

1. **优先使用** psql 命令行或 Supabase Dashboard SQL Editor
2. **获取准确信息** 后再更新代码和文档
3. **避免猜测** 表名、字段名或数据结构
4. **记录结果** 到相应的文档文件中

**数据库连接信息**：
- 项目ID: wqdpqhfqrxvssxifpmvt
- 数据库密码: 7232527xyznByEp
- ✅ **工作的连接字符串**: `postgresql://postgres.wqdpqhfqrxvssxifpmvt:7232527xyznByEp@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres`
- ❌ 不工作的连接: `db.wqdpqhfqrxvssxifpmvt.supabase.co` (DNS解析失败)

**✅ Supabase API 配置**：
- **项目URL**: `https://your-project-ref.supabase.co`
- **API Key**: 请使用环境变量中的 VITE_SUPABASE_ANON_KEY
- **角色**: anon (匿名用户)
- **验证状态**: ✅ 已测试，可正常访问所有 xq_ 开头的表
- **注意**: API key已在 .env 文件和 supabase.ts 中配置

**快速验证 API Key 的命令**：
```bash
# 测试API连接是否正常
curl -s -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY" \
     -H "apikey: $VITE_SUPABASE_ANON_KEY" \
     "$VITE_SUPABASE_URL/rest/v1/xq_user_profiles?select=*&limit=1"

# 预期结果: 返回JSON数组而不是401错误
# 如果返回 {"message":"Invalid API key"} 说明key有问题
```
**成功验证**: 2025-01-02 查询结果显示共有 **12张** `xq_` 开头的表，其中5张有数据。

### 📝 文档更新流程

每次查询数据库结构后，更新以下文档：
1. `docs/supabase-tables-report.md` - 表结构报告
2. `docs/project-supabase-guide.md` - 项目特定指南
3. `src/types/index.ts` - TypeScript 接口定义

---

## 🛠️ 其他开发工具和命令

### 项目构建和测试

```bash
# 启动开发服务器
npm run dev

# 构建项目
npm run build

# 代码检查
npm run lint

# TypeScript 检查
npx tsc --noEmit
```

### Git 工作流

```bash
# 检查状态
git status

# 提交更改
git add .
git commit -m "描述: 具体修改内容"

# 推送到远程
git push origin main
```

---

**最后更新**: 2025-01-02  
**适用项目**: 星趣App Web后台管理系统

---

**Made with ❤️ for 星趣App**
