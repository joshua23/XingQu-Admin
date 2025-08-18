#!/bin/bash
# Supabase 查询脚本
# 使用方法: ./supabase_query.sh <表名> [查询参数]

SUPABASE_URL="https://wqdpqhfqrxvssxifpmvt.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w"

TABLE=$1
QUERY=${2:-"*"}

if [ -z "$TABLE" ]; then
    echo "用法: $0 <表名> [查询参数]"
    echo "示例: $0 users 'id,email'"
    echo "      $0 subscription_plans '*&limit=5'"
    exit 1
fi

echo "查询表: $TABLE"
echo "参数: $QUERY"
echo "---"

curl -X GET "$SUPABASE_URL/rest/v1/$TABLE?select=$QUERY" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  | python3 -m json.tool

echo ""