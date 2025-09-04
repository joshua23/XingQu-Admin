#!/bin/bash

# GitHub 自动认证和创建SQL脚本
echo "🚀 创建数据库初始化助手..."

# 获取当前目录下的SQL文件
SQL_FILE="./scripts/init-admin-users-table.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo "❌ SQL文件不存在: $SQL_FILE"
    exit 1
fi

echo "📝 SQL文件已找到: $SQL_FILE"

# 创建一个更简洁的执行指南
cat << 'EOF' > ./SUPABASE_SETUP.md
# 📋 Supabase 数据库设置指南

## 🎯 目标
为星趣后台管理系统创建 `xq_admin_users` 表并插入初始数据。

## 📋 执行步骤

### 1. 打开 Supabase Dashboard
访问: https://supabase.com/dashboard

### 2. 选择项目
项目ID: `wqdpqhfqrxvssxifpmvt`

### 3. 进入 SQL Editor
在左侧菜单中找到并点击 **SQL Editor**

### 4. 执行SQL脚本
复制 `scripts/init-admin-users-table.sql` 文件中的全部内容，粘贴到SQL Editor中，然后点击 **Run** 按钮。

### 5. 验证结果
执行成功后，你将看到:
- ✅ 表 `xq_admin_users` 创建成功
- ✅ 3个初始管理员用户插入成功
- ✅ 索引和RLS策略配置完成

## 🔧 初始用户账户

| 邮箱 | 昵称 | 角色 | 状态 |
|------|------|------|------|
| admin@xingqu.com | 系统管理员 | super_admin | active |
| moderator@xingqu.com | 内容审核员 | moderator | active |
| user@xingqu.com | 普通管理员 | admin | active |

## ✅ 完成验证

执行完成后:
1. 刷新应用页面 (http://localhost:3001)
2. 进入用户管理页面 (/users)
3. 查看是否显示真实的用户数据而不是Mock数据

如果仍显示Mock数据，请检查:
- 数据库连接配置 (.env文件)
- SQL执行是否成功
- Supabase项目是否正确
EOF

echo "✅ 设置指南已创建: SUPABASE_SETUP.md"

# 显示SQL文件内容预览
echo ""
echo "📄 SQL文件内容预览 (前10行):"
echo "==============================================="
head -n 10 "$SQL_FILE"
echo "==============================================="
echo "... (完整内容请查看 $SQL_FILE)"

echo ""
echo "🎉 准备完成！请按照 SUPABASE_SETUP.md 中的指南执行数据库初始化。"