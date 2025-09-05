/**
 * 星趣后台管理系统 - 内容审核页面
 * 集成增强内容审核管理面板
 * Created: 2025-09-05
 */

'use client'

import React from 'react'
import ContentModerationDashboard from '@/components/moderation/ContentModerationDashboard'

export default function ModerationPage() {
  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">内容审核</h1>
          <p className="text-muted-foreground">
            AI智能审核、人工复审和内容管理
          </p>
        </div>

        <ContentModerationDashboard />
      </div>
    </div>
  )
}