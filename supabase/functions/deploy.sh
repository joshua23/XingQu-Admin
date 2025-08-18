#!/bin/bash

# Supabase Edge Functions 部署脚本
# 使用前请确保已安装 Supabase CLI

echo "🚀 开始部署 Supabase Edge Functions..."

# 检查 Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ 未找到 Supabase CLI，请先安装："
    echo "brew install supabase/tap/supabase"
    exit 1
fi

# 设置项目ID
PROJECT_ID="wqdpqhfqrxvssxifpmvt"

# 登录 Supabase
echo "📝 登录 Supabase..."
supabase login

# 链接项目
echo "🔗 链接项目..."
supabase link --project-ref $PROJECT_ID

# 部署函数
echo "📦 部署 AI 对话处理函数..."
supabase functions deploy ai-chat --no-verify-jwt

echo "📦 部署音频内容处理函数..."
supabase functions deploy audio-content --no-verify-jwt

echo "📦 部署用户权限验证函数..."
supabase functions deploy user-permission --no-verify-jwt

# 设置环境变量
echo "⚙️ 设置环境变量..."
supabase secrets set VOLCANO_API_KEY=your_volcano_api_key_here
supabase secrets set VOLCANO_API_URL=https://maas-api.volcengineapi.com/v3/chat/completions
supabase secrets set VOLCANO_MODEL=doubao-1.5-thinking-pro
supabase secrets set CDN_BASE_URL=https://cdn.xingqu.app

echo "✅ Edge Functions 部署完成!"
echo ""
echo "📚 函数访问地址："
echo "  - AI对话: https://$PROJECT_ID.supabase.co/functions/v1/ai-chat"
echo "  - 音频内容: https://$PROJECT_ID.supabase.co/functions/v1/audio-content"
echo "  - 权限验证: https://$PROJECT_ID.supabase.co/functions/v1/user-permission"
echo ""
echo "💡 提示："
echo "  1. 请确保已在 Supabase Dashboard 中配置了火山引擎 API Key"
echo "  2. 测试前请先获取有效的用户 JWT Token"
echo "  3. 可以使用 'supabase functions serve' 进行本地测试"