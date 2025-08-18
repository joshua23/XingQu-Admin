#!/bin/bash

# 简化的Edge Functions部署脚本
# 从项目根目录运行: ./deploy_functions.sh

echo "🚀 星趣App Edge Functions 部署脚本"
echo "===================================="
echo ""

# 项目配置
PROJECT_ID="wqdpqhfqrxvssxifpmvt"
PROJECT_URL="https://wqdpqhfqrxvssxifpmvt.supabase.co"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Supabase CLI
echo "🔍 检查环境..."
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI 未安装${NC}"
    echo "请运行: brew install supabase/tap/supabase"
    exit 1
fi
echo -e "${GREEN}✅ Supabase CLI 已安装${NC}"

# 确保在正确的目录
if [ ! -d "supabase/functions" ]; then
    echo -e "${RED}❌ 请从项目根目录运行此脚本${NC}"
    exit 1
fi

# 初始化Supabase项目（如果需要）
if [ ! -f "supabase/.gitignore" ]; then
    echo "📦 初始化Supabase项目..."
    supabase init --with-intellij-settings=false
fi

# 链接到远程项目
echo ""
echo "🔗 链接到Supabase项目..."
if [ -f ".supabase/project-ref" ] && [ "$(cat .supabase/project-ref 2>/dev/null)" = "$PROJECT_ID" ]; then
    echo -e "${GREEN}✅ 项目已链接${NC}"
else
    echo "请输入数据库密码（可以在Supabase Dashboard的Settings > Database中找到）："
    supabase link --project-ref $PROJECT_ID
fi

# 设置环境变量
echo ""
echo "🔧 配置环境变量..."
if [ -f ".env.functions" ]; then
    echo "正在设置火山引擎和其他API密钥..."
    
    # 手动设置每个环境变量（避免SUPABASE_前缀的问题）
    supabase secrets set VOLCANO_API_KEY=30332b4d-603c-424c-b508-8653a8d8f2ad --project-ref $PROJECT_ID
    supabase secrets set VOLCANO_API_URL=https://maas-api.volcengineapi.com/v3/chat/completions --project-ref $PROJECT_ID  
    supabase secrets set VOLCANO_MODEL=doubao-1.5-thinking-pro --project-ref $PROJECT_ID
    
    echo -e "${GREEN}✅ 环境变量设置完成${NC}"
else
    echo -e "${YELLOW}⚠️ .env.functions 文件不存在${NC}"
fi

# 函数列表
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

# 部署统计
success_count=0
fail_count=0
failed_functions=()

# 部署每个函数
echo ""
echo "📦 开始部署Edge Functions..."
echo "===================================="

for func in "${functions[@]}"; do
    echo ""
    echo "🚀 部署: $func"
    
    # 检查函数文件是否存在
    if [ ! -f "supabase/functions/$func/index.ts" ]; then
        echo -e "${YELLOW}⚠️ 文件不存在: supabase/functions/$func/index.ts${NC}"
        echo "跳过 $func"
        ((fail_count++))
        failed_functions+=($func)
        continue
    fi
    
    # 部署函数
    if supabase functions deploy $func --project-ref $PROJECT_ID --no-verify-jwt; then
        echo -e "${GREEN}✅ $func 部署成功${NC}"
        ((success_count++))
    else
        echo -e "${RED}❌ $func 部署失败${NC}"
        ((fail_count++))
        failed_functions+=($func)
    fi
done

# 部署总结
echo ""
echo "===================================="
echo "📊 部署总结"
echo "===================================="
echo -e "${GREEN}✅ 成功: $success_count 个函数${NC}"
echo -e "${RED}❌ 失败: $fail_count 个函数${NC}"

if [ ${#failed_functions[@]} -gt 0 ]; then
    echo ""
    echo "失败的函数:"
    for failed in "${failed_functions[@]}"; do
        echo "  - $failed"
    done
fi

# 显示函数URL
if [ $success_count -gt 0 ]; then
    echo ""
    echo "🌐 函数访问URL:"
    echo "===================================="
    for func in "${functions[@]}"; do
        echo "$PROJECT_URL/functions/v1/$func"
    done
fi

echo ""
echo "📝 测试命令示例:"
echo "curl -X POST $PROJECT_URL/functions/v1/ai-chat \\"
echo "  -H 'Authorization: Bearer YOUR_ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"message\": \"Hello\"}'"

echo ""
echo "🎉 部署脚本执行完成！"