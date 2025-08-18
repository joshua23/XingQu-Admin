#!/bin/bash

# Supabase Edge Functions 批量部署脚本
# 使用方法: 从项目根目录运行 ./supabase/functions/deploy_all.sh

echo "🚀 开始部署 Supabase Edge Functions..."

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 切换到项目根目录
cd "$SCRIPT_DIR/../.." || exit 1

echo "📍 当前工作目录: $(pwd)"

# 设置项目ID
PROJECT_ID="wqdpqhfqrxvssxifpmvt"

# 检查是否安装了 Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ 错误: Supabase CLI 未安装"
    echo "请先安装 Supabase CLI: https://supabase.com/docs/guides/cli"
    exit 1
fi

# 检查是否已经链接项目
if [ ! -f ".supabase/project-ref" ] || [ "$(cat .supabase/project-ref 2>/dev/null)" != "$PROJECT_ID" ]; then
    echo "📝 正在链接 Supabase 项目..."
    supabase link --project-ref $PROJECT_ID
else
    echo "✅ 项目已链接: $PROJECT_ID"
fi

# 需要部署的函数列表
functions=(
    "ai-chat"
    "audio-content"
    "user-permission"
    "analytics-metrics"
    "analytics-processor"
    "recommendations"
    "user-subscriptions"
    "interaction-menu"
    "memory-manager"
)

# 成功和失败计数
success_count=0
fail_count=0
failed_functions=()

# 部署每个函数
for function in "${functions[@]}"; do
    echo ""
    echo "📦 正在部署: $function"
    echo "----------------------------------------"
    
    # 部署函数
    if supabase functions deploy $function --project-ref $PROJECT_ID; then
        echo "✅ $function 部署成功"
        ((success_count++))
    else
        echo "❌ $function 部署失败"
        ((fail_count++))
        failed_functions+=($function)
    fi
done

# 设置环境变量
echo ""
echo "🔧 正在设置环境变量..."
echo "----------------------------------------"

# 读取环境变量文件
if [ -f ".env.functions" ]; then
    # 设置环境变量 (只需要设置一次，所有函数共享)
    echo "设置环境变量..."
    supabase secrets set --env-file .env.functions --project-ref $PROJECT_ID
    echo "✅ 环境变量设置完成"
else
    echo "⚠️ 警告: .env.functions 文件不存在，请手动设置环境变量"
fi

# 部署总结
echo ""
echo "========================================="
echo "📊 部署总结"
echo "========================================="
echo "✅ 成功部署: $success_count 个函数"
echo "❌ 部署失败: $fail_count 个函数"

if [ ${#failed_functions[@]} -gt 0 ]; then
    echo ""
    echo "失败的函数:"
    for failed in "${failed_functions[@]}"; do
        echo "  - $failed"
    done
    echo ""
    echo "💡 提示: 可以使用以下命令单独部署失败的函数:"
    echo "supabase functions deploy <function-name> --project-ref $PROJECT_ID"
fi

echo ""
echo "🎉 部署脚本执行完成!"
echo ""
echo "📝 后续步骤:"
echo "1. 访问 Supabase Dashboard 查看函数状态"
echo "2. 使用 API 测试工具测试各个函数"
echo "3. 查看函数日志: supabase functions logs <function-name> --project-ref $PROJECT_ID"