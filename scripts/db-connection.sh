#!/bin/bash

# Supabase 数据库连接配置
# 项目: 星趣后台管理系统

# 连接参数
export DB_HOST="aws-0-ap-southeast-1.pooler.supabase.com"
export DB_PORT="5432"
export DB_NAME="postgres"
export DB_USER="postgres.wqdpqhfqrxvssxifpmvt"
export DB_PASSWORD="7232527xyznByEp"

# 连接函数
connect_db() {
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" "$@"
}

# 使用示例
echo "📊 星趣后台管理系统 - 数据库连接工具"
echo "================================================"
echo ""
echo "使用方法:"
echo "  ./db-connection.sh                  # 进入交互式SQL终端"
echo "  ./db-connection.sh -c 'SQL命令'     # 执行单个SQL命令"
echo "  ./db-connection.sh -f file.sql      # 执行SQL文件"
echo ""
echo "示例:"
echo "  ./db-connection.sh -c 'SELECT * FROM xq_admin_users;'"
echo ""

# 如果有参数，执行命令；否则进入交互模式
if [ $# -eq 0 ]; then
    echo "进入交互式SQL终端..."
    connect_db
else
    connect_db "$@"
fi