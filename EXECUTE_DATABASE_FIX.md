# 立即执行数据库修复

## 🚨 紧急修复步骤

### 方法1：Supabase Web界面（推荐）

1. **访问Supabase SQL编辑器**
   ```
   https://wqdpqhfqrxvssxifpmvt.supabase.co/project/wqdpqhfqrxvssxifpmvt/sql
   ```

2. **复制并执行SQL脚本**
   - 打开文件：`immediate_database_fix.sql`
   - 全选复制所有内容
   - 粘贴到Supabase SQL编辑器
   - 点击"RUN"按钮执行

3. **确认结果**
   - 查看执行日志确认无错误
   - 应该看到"🎉 数据库修复完成！"消息

### 方法2：使用Supabase CLI

```bash
# 如果你有Supabase CLI
npx supabase login
npx supabase db reset --db-url "postgresql://postgres:[SERVICE_ROLE_KEY]@db.wqdpqhfqrxvssxifpmvt.supabase.co:5432/postgres"
npx supabase db push
```

### 方法3：直接PostgreSQL连接

```bash
# 使用psql直接连接
psql "postgresql://postgres:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.A632wk9FONoPgb6QEnqqU-C5oVGzqkhAXLEOo4X6WnQ@db.wqdpqhfqrxvssxifpmvt.supabase.co:5432/postgres"

# 然后执行
\i immediate_database_fix.sql
```

## ✅ 修复内容

此脚本将：

1. **修复missing likes table** - 创建通用点赞表支持多种内容类型
2. **创建AI角色表** - 包含寂文泽等测试角色
3. **创建评论系统** - 支持嵌套评论
4. **创建关注功能** - 用户可关注AI角色
5. **创建分析表** - 跟踪用户行为
6. **应用安全策略** - RLS保护所有敏感数据
7. **优化性能** - 创建关键索引
8. **插入测试数据** - 包含寂文泽角色

## 🔍 验证修复

执行后应该看到：
- ✅ 创建了 5 个关键表
- ✅ 创建了 3+ 个AI角色（包含寂文泽）
- ✅ 应用了 15+ 个RLS安全策略
- ✅ 创建了高性能索引

## 🚀 测试Flutter应用

修复后立即测试：
1. 重启Flutter应用
2. 尝试点赞功能
3. 检查AI角色列表
4. 验证评论功能

## ⚠️ 如果遇到问题

1. **权限错误**: 确认使用Service Role Key
2. **连接失败**: 检查网络和凭据
3. **执行错误**: 查看错误日志并联系支持

## 📞 获得帮助

如果执行过程中遇到任何问题：
1. 截图错误信息
2. 检查Supabase项目状态
3. 验证凭据是否正确