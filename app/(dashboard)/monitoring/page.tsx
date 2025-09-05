/**
 * 星趣后台管理系统 - 实时监控页面
 * 主监控仪表板页面
 * Created: 2025-09-05
 */

import React from 'react'
import { Metadata } from 'next'
import RealtimeMonitoringDashboard from '@/components/monitoring/RealtimeMonitoringDashboard'

export const metadata: Metadata = {
  title: '实时监控 - 星趣后台管理系统',
  description: '系统实时状态监控和告警管理',
}

export default function MonitoringPage() {
  return (
    <div className="container mx-auto py-6">
      <RealtimeMonitoringDashboard />
    </div>
  )
}