#!/bin/bash

# 执行后台数据可见性修复脚本
# 解决点赞、评论、关注数据在后台管理系统看不到的问题

echo "🔧 开始执行后台数据可见性修复..."
echo "============================================="

# 1. 检查必要的工具
echo "📋 检查环境..."
if ! command -v supabase &> /dev/null; then
    echo "❌ 错误: 未找到supabase CLI"
    echo "请先安装: https://supabase.com/docs/guides/cli"
    exit 1
fi

# 2. 检查是否在正确的项目目录中
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ 错误: 请在Supabase项目根目录中运行此脚本"
    exit 1
fi

echo "✅ 环境检查完成"

# 3. 执行数据库修复脚本
echo ""
echo "🔄 执行数据库RLS策略和权限修复..."
echo "--------------------------------------------"

# 执行SQL脚本
if supabase db reset --db-url $(grep SUPABASE_DB_URL .env.local | cut -d '=' -f2) --file BACKEND_DATA_VISIBILITY_FIX.sql; then
    echo "✅ 数据库修复脚本执行完成"
else
    echo "⚠️ 使用备用方法执行SQL脚本..."
    # 备用方法：直接执行SQL文件
    cat BACKEND_DATA_VISIBILITY_FIX.sql | supabase db reset --stdin
fi

# 4. 验证修复结果
echo ""
echo "🔍 验证修复结果..."
echo "--------------------------------------------"

# 创建验证脚本
cat > verify_fix.sql << 'EOF'
-- 验证修复结果
SELECT '=== RLS策略检查 ===' as info;
SELECT 
    tablename,
    policyname,
    cmd,
    roles
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('likes', 'character_follows', 'comments', 'user_analytics')
ORDER BY tablename, policyname;

SELECT '=== 数据统计 ===' as info;
SELECT 
    'likes' as table_name,
    COUNT(*) as total_records
FROM public.likes
UNION ALL
SELECT 
    'character_follows',
    COUNT(*)
FROM public.character_follows
UNION ALL
SELECT 
    'comments',
    COUNT(*)
FROM public.comments;

SELECT '=== 视图检查 ===' as info;
SELECT 
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'public'
AND viewname IN ('interaction_summary', 'realtime_interactions');
EOF

# 执行验证
if supabase db reset --db-url $(grep SUPABASE_DB_URL .env.local | cut -d '=' -f2) --file verify_fix.sql; then
    echo "✅ 数据库验证完成"
else
    echo "⚠️ 验证脚本执行遇到问题，请手动检查"
fi

# 清理临时文件
rm -f verify_fix.sql

# 5. 重新构建web组件
echo ""
echo "📦 重新构建web组件..."
echo "--------------------------------------------"

cd web-components
if [ -f "package.json" ]; then
    echo "安装依赖..."
    npm install
    
    echo "构建共享组件..."
    npm run build
    
    echo "✅ Web组件构建完成"
else
    echo "⚠️ 未找到web-components目录，跳过构建"
fi

cd ..

# 6. 重启后台管理系统
echo ""
echo "🔄 重启后台管理系统..."
echo "--------------------------------------------"

# 如果有运行中的后台服务，重启它们
if pgrep -f "web-components" > /dev/null; then
    echo "停止现有的web组件服务..."
    pkill -f "web-components"
    sleep 2
fi

# 重新启动web组件服务（如果存在启动脚本）
if [ -f "web-components/package.json" ] && grep -q "dev" web-components/package.json; then
    cd web-components
    echo "启动开发服务器..."
    npm run dev &
    WEB_COMPONENT_PID=$!
    echo "Web组件服务已启动 (PID: $WEB_COMPONENT_PID)"
    cd ..
fi

# 7. 测试Flutter应用连接
echo ""
echo "📱 重启Flutter应用以应用修复..."
echo "--------------------------------------------"

if pgrep -f "flutter" > /dev/null; then
    echo "检测到运行中的Flutter应用，建议重启以应用修复"
    echo "请在另一个终端运行: flutter run --hot-restart"
else
    echo "未检测到运行中的Flutter应用"
    echo "请启动Flutter应用: flutter run"
fi

# 8. 输出测试指南
echo ""
echo "✅ 修复执行完成！"
echo "============================================="
echo ""
echo "📝 测试指南："
echo "1. 启动Flutter应用: flutter run"
echo "2. 打开首页-精选页，测试点赞、评论、关注功能"
echo "3. 打开后台管理系统: http://localhost:3000"
echo "4. 查看移动端数据监控页面，确认实时数据显示"
echo ""
echo "🔍 如果问题仍然存在，请检查："
echo "- Supabase项目设置中的RLS策略"
echo "- 后台管理系统使用的API Key权限"
echo "- 浏览器开发者工具中的网络请求"
echo "- Supabase Dashboard中的实时日志"
echo ""
echo "📞 如需进一步协助，请查看 INTERACTION_ISSUE_ANALYSIS.md"
echo "============================================="