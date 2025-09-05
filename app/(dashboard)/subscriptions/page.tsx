/**
 * 星趣后台管理系统 - 订阅管理页面
 * 集成订阅管理组件
 * Created: 2025-09-05
 */

'use client'

import React from 'react'
import SubscriptionManager from '@/components/subscription/SubscriptionManager'

export default function SubscriptionsPage() {
  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">订阅管理</h1>
          <p className="text-muted-foreground">
            管理订阅计划、用户订阅和统计分析
          </p>
        </div>

        <SubscriptionManager />
      </div>
    </div>
  )
}