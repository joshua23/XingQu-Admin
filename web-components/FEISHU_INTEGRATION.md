# 飞书多维表格集成指南

## 📋 集成概述

星趣App后台管理系统已完全支持嵌入飞书多维表格，提供无缝的管理体验。

## 🚀 快速集成

### 1. 部署管理系统

首先确保管理系统已部署并可访问：

```bash
# 启动开发服务器
npm run dev

# 或构建生产版本
npm run build
```

系统将在 `http://localhost:3000` 运行，包含：
- `/dashboard` - 数据看板
- `/users` - 用户管理  
- `/moderation` - 内容审核

### 2. 在飞书中创建多维表格

1. **创建新的多维表格**
   - 打开飞书，进入文档
   - 插入 → 多维表格
   - 为表格命名（如"星趣App管理中心"）

2. **添加自定义视图**
   - 点击表格右上角的"+"添加视图
   - 选择"外部链接"或"嵌入网页"

### 3. 配置嵌入链接

使用以下URL格式嵌入管理系统：

#### 基础URL格式
```
https://your-domain.com/?feishu_user_id={USER_ID}&feishu_table_id={TABLE_ID}
```

#### 完整URL参数
```
https://your-domain.com/?
  feishu_user_id={USER_ID}&
  feishu_user_name={USER_NAME}&
  feishu_table_id={TABLE_ID}&
  permissions=admin,user_manage,content_review&
  locale=zh-CN&
  theme=light
```

### 4. URL参数说明

| 参数名 | 类型 | 必填 | 说明 | 示例 |
|--------|------|------|------|------|
| `feishu_user_id` | string | ✅ | 飞书用户唯一标识 | `123456789` |
| `feishu_user_name` | string | ❌ | 用户显示名称 | `张三` |
| `feishu_table_id` | string | ❌ | 表格唯一标识 | `tbl123abc` |
| `permissions` | string | ❌ | 权限列表（逗号分隔） | `admin,user_manage` |
| `locale` | string | ❌ | 语言设置 | `zh-CN` 或 `en-US` |
| `theme` | string | ❌ | 主题设置 | `light` 或 `dark` |

## 🔧 高级配置

### iframe嵌入设置

在飞书中配置iframe时，建议使用以下设置：

```html
<iframe 
  src="https://your-domain.com/?feishu_user_id=123456789"
  width="100%" 
  height="800px"
  frameborder="0"
  allowfullscreen="true"
  sandbox="allow-scripts allow-same-origin allow-forms">
</iframe>
```

### 安全配置

管理系统已配置以下安全策略：

- **X-Frame-Options**: `ALLOWALL`
- **Content-Security-Policy**: 允许飞书域名嵌入
- **CORS**: 支持跨域访问
- **PostMessage**: 安全的消息通信

### 权限配置

支持以下权限类型：

| 权限代码 | 权限名称 | 功能范围 |
|----------|----------|----------|
| `admin` | 超级管理员 | 所有功能 |
| `dashboard_view` | 数据看板查看 | 查看数据统计 |
| `user_manage` | 用户管理 | 用户增删改查 |
| `user_export` | 用户导出 | 导出用户数据 |
| `content_review` | 内容审核 | 审核用户内容 |
| `content_moderate` | 内容管理 | 批量内容操作 |

## 💬 消息通信机制

### 系统发送给飞书的消息

```typescript
// 组件就绪通知
{
  type: 'component_ready',
  componentType: 'admin_system',
  data: { height: 800, title: '星趣App后台管理系统' }
}

// 高度调整请求
{
  type: 'resize_iframe',
  height: 1200
}

// 错误报告
{
  type: 'component_error',
  error: { message: 'Error message', stack: '...' }
}

// 性能数据
{
  type: 'component_performance',
  metrics: { loadTime: 1200, timestamp: '...' }
}
```

### 飞书发送给系统的消息

```typescript
// 尺寸调整
{
  type: 'feishu_resize',
  data: { height: 600 }
}

// 主题切换
{
  type: 'feishu_theme_change', 
  data: { theme: 'dark' }
}

// 刷新请求
{
  type: 'feishu_refresh',
  data: {}
}
```

## 🎯 最佳实践

### 1. 用户身份验证

```javascript
// 在飞书应用中获取用户信息
const getUserInfo = async () => {
  const user = await tt.getUserInfo();
  return {
    userId: user.userId,
    userName: user.userName,
    permissions: await getUserPermissions(user.userId)
  };
};
```

### 2. 动态权限控制

```javascript
// 根据用户权限构建URL
const buildAdminUrl = (baseUrl, userInfo) => {
  const params = new URLSearchParams({
    feishu_user_id: userInfo.userId,
    feishu_user_name: userInfo.userName,
    permissions: userInfo.permissions.join(','),
    locale: 'zh-CN',
    theme: 'light'
  });
  
  return `${baseUrl}?${params.toString()}`;
};
```

### 3. 响应式布局

管理系统自动适配不同屏幕尺寸：

- **桌面端**: 侧边栏导航 + 主内容区
- **移动端**: 折叠式导航 + 全屏内容
- **飞书嵌入**: 优化的紧凑布局

## 📱 移动端支持

虽然主要针对桌面端设计，但系统也支持移动端访问：

```css
/* 移动端适配样式 */
@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }
  
  .sidebar.open {
    transform: translateX(0);
  }
}
```

## 🔍 故障排查

### 常见问题

1. **无法加载组件**
   - 检查URL参数是否正确
   - 确认域名已添加到飞书白名单
   - 验证CORS配置

2. **权限不足**
   - 确认用户权限参数
   - 检查后端权限验证逻辑
   - 查看控制台错误信息

3. **样式异常**
   - 确认主题参数设置
   - 检查CSS加载情况
   - 验证飞书环境检测

### 调试工具

在开发环境下，可以通过以下方式调试：

```javascript
// 开启调试模式
localStorage.setItem('debug', 'true');

// 查看飞书上下文
console.log('Feishu Context:', window.__FEISHU_CONTEXT__);

// 监听消息通信
window.addEventListener('message', (event) => {
  console.log('Received message:', event.data);
});
```

## 📞 技术支持

如遇到集成问题，请提供以下信息：

1. 飞书版本信息
2. 浏览器类型和版本
3. 错误控制台截图
4. 网络请求日志
5. 具体操作步骤

联系方式：
- GitHub Issues: [项目地址]/issues
- 技术文档: [文档地址]

---

**星趣App后台管理系统** - 让飞书协作更高效 🚀