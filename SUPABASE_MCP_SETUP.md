# Supabase MCP 配置指南

## 🚀 快速开始

### 1. 前置要求
- Node.js 已安装（用于运行 npx 命令）
- Supabase 个人访问令牌已创建

### 2. 配置信息
- **项目引用**: `wqdpqhfqrxvssxifpmvt`
- **个人访问令牌**: `sbp_bcc6e34f6bd3ab10f2a10dd027c6102d385ac20d`
- **启用功能**: database（数据库）, docs（文档）, debug（调试）
- **模式**: 只读模式（安全）

### 3. 安装步骤

#### 对于 Claude Desktop (macOS)
```bash
# 1. 创建配置目录（如果不存在）
mkdir -p ~/Library/Application\ Support/Claude

# 2. 复制配置文件
cp mcp_config.json ~/Library/Application\ Support/Claude/claude_desktop_config.json

# 3. 重启 Claude Desktop
```

#### 对于 Claude Desktop (Windows)
```cmd
# 1. 创建配置目录（如果不存在）
mkdir "%APPDATA%\Claude"

# 2. 复制配置文件
copy mcp_config.json "%APPDATA%\Claude\claude_desktop_config.json"

# 3. 重启 Claude Desktop
```

#### 对于 Cursor
```bash
# 1. 创建配置目录
mkdir -p ~/.cursor/mcp

# 2. 复制配置文件
cp mcp_config.json ~/.cursor/mcp/mcp_config.json

# 3. 重启 Cursor
```

### 4. 验证安装

重启 AI 工具后，您应该能够：
1. 在对话中询问 Supabase 数据库相关问题
2. 执行只读 SQL 查询
3. 获取表结构信息
4. 查看数据库文档

### 5. 可用命令示例

配置成功后，您可以在 AI 助手中使用以下命令：

```
"显示所有数据库表"
"查询 users 表的结构"
"获取 subscription_plans 表的数据"
"帮我分析数据库架构"
```

## 🔒 安全配置

当前配置采用了以下安全措施：
- ✅ 只读模式 - 防止意外修改数据
- ✅ 项目范围限制 - 只访问指定项目
- ✅ 最小权限原则 - 只启用必要功能

## 📊 启用的功能

- **database**: 数据库查询和架构访问
- **docs**: Supabase 文档访问
- **debug**: 调试信息和日志

## ⚠️ 注意事项

1. **不要在生产环境使用** - 这是开发工具
2. **定期轮换令牌** - 建议每 3-6 个月更新一次
3. **监控使用情况** - 在 Supabase Dashboard 查看 API 使用

## 🔧 故障排查

### 问题：MCP 服务器无法启动
```bash
# 检查 Node.js 是否安装
node --version

# 手动测试 MCP 服务器
npx @supabase/mcp-server-supabase@latest --version
```

### 问题：权限错误
- 确认个人访问令牌是否有效
- 检查项目引用是否正确
- 验证网络连接

### 问题：功能不可用
- 检查 --features 参数是否正确
- 某些功能可能需要付费计划

## 📚 更多功能

如需启用更多功能，修改 `--features` 参数：
```
--features=database,docs,debug,functions,storage,branching
```

可用功能组：
- `account` - 账户管理
- `database` - 数据库操作
- `docs` - 文档访问
- `debug` - 调试工具
- `development` - 开发工具
- `functions` - Edge Functions
- `storage` - 文件存储
- `branching` - 分支功能（需付费计划）

## 🔗 相关资源

- [Supabase MCP 文档](https://supabase.com/docs/guides/getting-started/mcp)
- [MCP 协议规范](https://modelcontextprotocol.io)
- [Supabase Dashboard](https://app.supabase.com)

---

配置完成时间：2025年1月
配置版本：@supabase/mcp-server-supabase@latest