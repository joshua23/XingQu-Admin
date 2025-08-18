#!/bin/bash

# 最简单的Edge Functions部署脚本
# 绕过配置文件问题，直接部署

echo "🚀 星趣App - 简化Edge Functions部署"
echo "=================================="
echo ""

# 项目配置
PROJECT_ID="wqdpqhfqrxvssxifpmvt"
PROJECT_URL="https://wqdpqhfqrxvssxifpmvt.supabase.co"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 检查Supabase CLI..."
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI 未安装${NC}"
    echo "请运行: brew install supabase/tap/supabase"
    exit 1
fi
echo -e "${GREEN}✅ Supabase CLI 已安装${NC}"

echo ""
echo "🔧 设置环境变量..."
echo "正在配置火山引擎API密钥..."

# 直接设置环境变量，不使用配置文件
supabase secrets set VOLCANO_API_KEY=30332b4d-603c-424c-b508-8653a8d8f2ad --project-ref $PROJECT_ID
supabase secrets set VOLCANO_API_URL=https://maas-api.volcengineapi.com/v3/chat/completions --project-ref $PROJECT_ID  
supabase secrets set VOLCANO_MODEL=doubao-1.5-thinking-pro --project-ref $PROJECT_ID

echo -e "${GREEN}✅ 环境变量设置完成${NC}"

# 函数列表 - 只部署确实存在的函数
functions=(
    "ai-chat"
    "audio-content"
    "user-permission"
)

# 部署统计
success_count=0
fail_count=0
failed_functions=()

echo ""
echo "📦 开始部署Edge Functions..."
echo "================================"

for func in "${functions[@]}"; do
    echo ""
    echo "🚀 部署: $func"
    
    # 检查函数文件是否存在
    if [ ! -f "supabase/functions/$func/index.ts" ]; then
        echo -e "${YELLOW}⚠️ 跳过 $func - 文件不存在${NC}"
        continue
    fi
    
    # 部署函数，使用最简参数
    if supabase functions deploy $func --project-ref $PROJECT_ID --no-verify-jwt 2>/dev/null; then
        echo -e "${GREEN}✅ $func 部署成功${NC}"
        ((success_count++))
    else
        # 尝试不带额外参数再次部署
        echo "🔄 重试部署 $func..."
        if supabase functions deploy $func --project-ref $PROJECT_ID; then
            echo -e "${GREEN}✅ $func 部署成功（重试）${NC}"
            ((success_count++))
        else
            echo -e "${RED}❌ $func 部署失败${NC}"
            ((fail_count++))
            failed_functions+=($func)
        fi
    fi
done

# 尝试部署其他函数（如果存在）
other_functions=(
    "analytics-metrics"
    "analytics-processor"
    "recommendations"
    "user-subscriptions"
    "interaction-menu"
    "memory-manager"
)

for func in "${other_functions[@]}"; do
    if [ -f "supabase/functions/$func/index.ts" ]; then
        echo ""
        echo "🚀 部署: $func"
        
        if supabase functions deploy $func --project-ref $PROJECT_ID; then
            echo -e "${GREEN}✅ $func 部署成功${NC}"
            ((success_count++))
        else
            echo -e "${RED}❌ $func 部署失败${NC}"
            ((fail_count++))
            failed_functions+=($func)
        fi
    fi
done

# 部署总结
echo ""
echo "=================================="
echo "📊 部署总结"
echo "=================================="
echo -e "${GREEN}✅ 成功: $success_count 个函数${NC}"
echo -e "${RED}❌ 失败: $fail_count 个函数${NC}"

if [ ${#failed_functions[@]} -gt 0 ]; then
    echo ""
    echo "失败的函数:"
    for failed in "${failed_functions[@]}"; do
        echo "  - $failed"
    done
fi

echo ""
echo "🌐 API端点列表:"
echo "=================================="
echo "AI对话: $PROJECT_URL/functions/v1/ai-chat"
echo "音频内容: $PROJECT_URL/functions/v1/audio-content"
echo "用户权限: $PROJECT_URL/functions/v1/user-permission"

echo ""
echo "🧪 测试命令:"
echo "--------------------------------"
echo "测试AI对话:"
echo "curl -X POST '$PROJECT_URL/functions/v1/ai-chat' \\"
echo "  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"message\": \"你好，请介绍星趣App\"}'"

echo ""
echo "🎉 部署脚本执行完成！"
echo ""

if [ $success_count -gt 0 ]; then
    echo -e "${GREEN}🎊 恭喜！已成功部署 $success_count 个Edge Functions${NC}"
    echo "您现在可以开始测试API功能了！"
else
    echo -e "${YELLOW}⚠️ 没有成功部署任何函数，请检查错误信息${NC}"
fi