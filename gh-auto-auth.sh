#!/bin/bash

# GitHub CLI 自动认证脚本
# 用于在新的Claude Code会话中快速认证GitHub CLI

# GH_TOKEN变量需要在环境中设置或手动配置
# 使用方法：export GH_TOKEN="your_github_token_here" 或直接配置gh auth
GH_TOKEN=${GH_TOKEN:-""}

echo "检查GitHub CLI认证状态..."
if gh auth status &> /dev/null; then
    echo "✅ GitHub CLI已认证"
    gh auth status
else
    echo "🔐 GitHub CLI未认证"
    if [ -n "$GH_TOKEN" ]; then
        echo "使用环境变量中的token进行认证..."
        echo "$GH_TOKEN" | gh auth login --with-token
        echo "✅ GitHub CLI认证完成"
    else
        echo "❌ 请先设置GH_TOKEN环境变量或运行 gh auth login"
        exit 1
    fi
fi

echo "🚀 现在可以使用 gh pr create 等命令了"