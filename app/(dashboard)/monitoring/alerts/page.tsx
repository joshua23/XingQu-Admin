/**
 * 星趣后台管理系统 - 告警管理页面
 * 专门的告警管理和历史查看页面
 * Created: 2025-09-05
 */

'use client'

import React from 'react'
import AlertManager from '@/components/monitoring/AlertManager'
import { useRealtimeMonitoring } from '@/lib/hooks/useRealtimeMonitoring'

export default function AlertsPage() {
  const {
    activeAlerts,
    acknowledgeAlert,
    resolveAlert,
    isLoading
  } = useRealtimeMonitoring({
    interval: 10000, // 告警页面可以更新频率稍低一些
    enabled: true
  })

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">告警管理</h1>
          <p className="text-muted-foreground">
            查看和管理系统告警，确保系统稳定运行
          </p>
        </div>

        <AlertManager
          alerts={activeAlerts}
          onAcknowledge={acknowledgeAlert}
          onResolve={resolveAlert}
          loading={isLoading}
        />
      </div>
    </div>
  )
}