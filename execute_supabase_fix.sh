#!/bin/bash

# 直接通过curl执行Supabase数据库修复
# 使用你提供的凭证

SUPABASE_URL="https://wqdpqhfqrxvssxifpmvt.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.A632wk9FONoPgb6QEnqqU-C5oVGzqkhAXLEOo4X6WnQ"

echo "🚀 开始执行Supabase数据库修复..."

# 1. 创建likes表
echo "📋 创建likes表..."
curl -X POST "${SUPABASE_URL}/rest/v1/rpc/exec" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -d '{
    "sql": "CREATE TABLE IF NOT EXISTS likes (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, target_type VARCHAR(50) NOT NULL, target_id UUID NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(user_id, target_type, target_id));"
  }'

# 2. 创建角色关注表  
echo "📋 创建character_follows表..."
curl -X POST "${SUPABASE_URL}/rest/v1/rpc/exec" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -d '{
    "sql": "CREATE TABLE IF NOT EXISTS character_follows (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, character_id UUID NOT NULL REFERENCES ai_characters(id) ON DELETE CASCADE, created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(user_id, character_id));"
  }'

# 3. 启用RLS
echo "🔒 启用行级安全策略..."
curl -X POST "${SUPABASE_URL}/rest/v1/rpc/exec" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -d '{
    "sql": "ALTER TABLE likes ENABLE ROW LEVEL SECURITY; CREATE POLICY \"Anyone can view likes\" ON likes FOR SELECT USING (true); CREATE POLICY \"Users can manage own likes\" ON likes FOR ALL USING (auth.uid() = user_id);"
  }'

# 4. 检查结果
echo "✅ 检查修复结果..."
curl -X POST "${SUPABASE_URL}/rest/v1/rpc/exec" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -d '{
    "sql": "SELECT tablename FROM pg_tables WHERE schemaname = \"public\" AND tablename = \"likes\";"
  }'

echo ""
echo "🎉 数据库修复脚本执行完成！"
echo "请重启Flutter应用测试点赞功能"