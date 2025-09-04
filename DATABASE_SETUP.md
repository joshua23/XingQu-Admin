# 星趣后台管理系统 - 数据库设置指南

## 🗄️ 数据库表结构

### xq_admin_users 表（后台管理员用户）

这个表专门用于存储后台管理系统的管理员用户信息。

#### 表结构

| 字段名 | 类型 | 描述 | 约束 |
|-------|------|------|------|
| id | UUID | 主键 | PRIMARY KEY, AUTO |
| email | VARCHAR(255) | 邮箱地址 | UNIQUE, NOT NULL |
| nickname | VARCHAR(100) | 用户昵称 | NOT NULL |
| avatar_url | TEXT | 头像URL | 可选 |
| phone | VARCHAR(20) | 手机号码 | 可选 |
| role | VARCHAR(50) | 用户角色 | admin/super_admin/moderator |
| account_status | VARCHAR(20) | 账户状态 | active/inactive/banned |
| permissions | JSONB | 权限列表 | JSON数组 |
| last_login | TIMESTAMP | 最后登录时间 | 可选 |
| created_at | TIMESTAMP | 创建时间 | 自动生成 |
| updated_at | TIMESTAMP | 更新时间 | 自动更新 |
| created_by | UUID | 创建者ID | 可选 |
| agreement_accepted | BOOLEAN | 是否同意协议 | 默认false |
| agreement_version | VARCHAR(10) | 协议版本 | 默认v1.0 |

## 🚀 数据库初始化

### 方法一：自动脚本（推荐用于了解结构）

```bash
node scripts/setup-database.js
```

### 方法二：手动创建（推荐）

1. 打开 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择你的项目
3. 进入 SQL Editor
4. 复制并执行 `scripts/init-admin-users-table.sql` 中的SQL语句

## 📝 初始化后的默认数据

系统会自动创建以下测试用户：

| 邮箱 | 昵称 | 角色 | 状态 |
|------|------|------|------|
| admin@xingqu.com | 系统管理员 | super_admin | active |
| moderator@xingqu.com | 内容审核员 | moderator | active |
| user@xingqu.com | 普通管理员 | admin | active |

## 🛠️ 权限系统

### 权限类型

- `read`: 查看权限
- `write`: 编辑权限  
- `delete`: 删除权限
- `manage_users`: 用户管理权限
- `manage_content`: 内容管理权限

### 角色说明

- **super_admin**: 超级管理员，拥有所有权限
- **admin**: 普通管理员，基础读写权限
- **moderator**: 内容审核员，内容管理权限

## 🔧 功能使用说明

### 添加用户功能

1. 登录后台管理系统
2. 进入"用户管理"页面
3. 点击"添加用户"按钮
4. 填写用户信息：
   - 邮箱地址（必填）
   - 用户昵称（必填）
   - 手机号码（可选）
   - 用户角色
   - 权限设置
5. 点击"创建用户"完成

### 用户管理功能

- **查看用户列表**: 显示所有后台管理员用户
- **搜索用户**: 按昵称、邮箱、手机号搜索
- **筛选用户**: 按账户状态筛选
- **用户操作**:
  - 激活/停用账户
  - 封禁账户
  - 查看用户详情
  - 编辑用户信息

### 退出登录功能

点击右下角用户菜单中的"退出登录"按钮即可安全退出系统。

## 🔒 安全特性

- **行级安全(RLS)**: 启用了行级安全策略
- **权限控制**: 基于角色的权限管理
- **数据验证**: 严格的数据约束和验证
- **安全退出**: 完整清理会话信息

## 📊 数据统计

系统提供了 `xq_admin_users_stats` 视图用于快速获取用户统计信息：

```sql
SELECT * FROM xq_admin_users_stats;
```

统计信息包括：
- 总用户数
- 各状态用户数量
- 各角色用户数量  
- 协议同意用户数量

## 🐛 故障排除

### 数据库连接问题
检查 `.env` 文件中的 Supabase 配置：
```
NEXT_PUBLIC_SUPABASE_URL=你的supabase地址
NEXT_PUBLIC_SUPABASE_ANON_KEY=你的匿名key
```

### 表不存在问题
手动在 Supabase Dashboard 中执行 SQL 创建表。

### 权限问题
确保 Supabase 项目的 RLS 政策配置正确。

---

## 🎉 完成！

按照以上步骤完成后，你的星趣后台管理系统就具备了完整的用户管理功能！