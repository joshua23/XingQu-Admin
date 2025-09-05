/**
 * 星趣后台管理系统 - 实时监控仪表板组件
 * 显示系统实时监控数据、告警和状态概览
 * Created: 2025-09-05
 */

'use client'

import React, { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Separator } from '@/components/ui/separator'
import { useRealtimeMonitoring } from '@/lib/hooks/useRealtimeMonitoring'
import { 
  Activity, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  Database, 
  RefreshCw, 
  Server, 
  TrendingUp, 
  TrendingDown, 
  Minus,
  Wifi,
  WifiOff
} from 'lucide-react'
import type { RealtimeMetric, SystemAlert } from '@/lib/types/admin'

export default function RealtimeMonitoringDashboard() {
  const [autoRefresh, setAutoRefresh] = useState(true)
  
  const {
    metrics,
    systemStatus,
    activeAlerts,
    isLoading,
    isConnected,
    error,
    lastUpdated,
    startMonitoring,
    stopMonitoring,
    acknowledgeAlert,
    resolveAlert,
    refreshData
  } = useRealtimeMonitoring({
    interval: 5000,
    enabled: autoRefresh,
    onAlert: (alert) => {
      // 可以在这里添加告警通知逻辑
      console.log('新告警:', alert)
    },
    onError: (err) => {
      console.error('监控错误:', err)
    }
  })

  // 渲染连接状态
  const renderConnectionStatus = () => (
    <div className="flex items-center gap-2 text-sm">
      {isConnected ? (
        <>
          <Wifi className="h-4 w-4 text-green-500" />
          <span className="text-green-600">已连接</span>
        </>
      ) : (
        <>
          <WifiOff className="h-4 w-4 text-red-500" />
          <span className="text-red-600">未连接</span>
        </>
      )}
      {lastUpdated && (
        <span className="text-muted-foreground">
          · 更新于 {lastUpdated.toLocaleTimeString()}
        </span>
      )}
    </div>
  )

  // 渲染指标卡片
  const renderMetricCard = (metric: RealtimeMetric) => {
    const getStatusColor = (status: string) => {
      switch (status) {
        case 'normal': return 'text-green-600 bg-green-50 border-green-200'
        case 'warning': return 'text-yellow-600 bg-yellow-50 border-yellow-200'
        case 'critical': return 'text-red-600 bg-red-50 border-red-200'
        case 'info': return 'text-blue-600 bg-blue-50 border-blue-200'
        default: return 'text-gray-600 bg-gray-50 border-gray-200'
      }
    }

    const getTrendIcon = (trend?: string) => {
      switch (trend) {
        case 'up': return <TrendingUp className="h-4 w-4 text-green-500" />
        case 'down': return <TrendingDown className="h-4 w-4 text-red-500" />
        default: return <Minus className="h-4 w-4 text-gray-400" />
      }
    }

    return (
      <Card key={metric.id} className={`border-2 ${getStatusColor(metric.status)}`}>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">{metric.name}</CardTitle>
          <div className="flex items-center gap-1">
            {getTrendIcon(metric.trend)}
            <Badge variant={metric.status === 'normal' ? 'default' : 'destructive'}>
              {metric.status}
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            {metric.value} {metric.unit}
          </div>
          {metric.threshold && (
            <p className="text-xs text-muted-foreground mt-1">
              警告: {metric.threshold.warning}{metric.unit} | 
              严重: {metric.threshold.critical}{metric.unit}
            </p>
          )}
          <p className="text-xs text-muted-foreground">
            更新: {new Date(metric.lastUpdated).toLocaleTimeString()}
          </p>
        </CardContent>
      </Card>
    )
  }

  // 渲染告警项
  const renderAlert = (alert: SystemAlert) => {
    const getAlertIcon = (type: string) => {
      switch (type) {
        case 'error': return <AlertTriangle className="h-4 w-4 text-red-500" />
        case 'warning': return <AlertTriangle className="h-4 w-4 text-yellow-500" />
        case 'success': return <CheckCircle className="h-4 w-4 text-green-500" />
        default: return <Activity className="h-4 w-4 text-blue-500" />
      }
    }

    const getAlertColor = (type: string) => {
      switch (type) {
        case 'error': return 'border-red-200 bg-red-50'
        case 'warning': return 'border-yellow-200 bg-yellow-50'
        case 'success': return 'border-green-200 bg-green-50'
        default: return 'border-blue-200 bg-blue-50'
      }
    }

    return (
      <Alert key={alert.id} className={`mb-3 ${getAlertColor(alert.type)}`}>
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-2">
            {getAlertIcon(alert.type)}
            <div className="flex-1">
              <h4 className="text-sm font-medium">{alert.title}</h4>
              <AlertDescription className="text-xs mt-1">
                {alert.message}
              </AlertDescription>
              {alert.metricName && (
                <div className="text-xs text-muted-foreground mt-1">
                  指标: {alert.metricName}
                  {alert.currentValue && alert.thresholdValue && (
                    <span> | 当前: {alert.currentValue} | 阈值: {alert.thresholdValue}</span>
                  )}
                </div>
              )}
              <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1">
                <Clock className="h-3 w-3" />
                {new Date(alert.timestamp).toLocaleString()}
                <Badge variant="outline" className="text-xs">
                  {alert.status}
                </Badge>
              </div>
            </div>
          </div>
          <div className="flex gap-1 ml-2">
            {alert.status === 'active' && (
              <>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-6 px-2 text-xs"
                  onClick={() => acknowledgeAlert(alert.id)}
                >
                  确认
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-6 px-2 text-xs"
                  onClick={() => resolveAlert(alert.id)}
                >
                  解决
                </Button>
              </>
            )}
          </div>
        </div>
      </Alert>
    )
  }

  // 渲染系统状态
  const renderSystemStatus = () => {
    if (!systemStatus) return null

    const getStatusColor = (status: string) => {
      switch (status) {
        case 'healthy': return 'text-green-600'
        case 'warning': return 'text-yellow-600'
        case 'critical': return 'text-red-600'
        default: return 'text-gray-600'
      }
    }

    const getStatusIcon = (status: string) => {
      switch (status) {
        case 'healthy': return <CheckCircle className="h-5 w-5 text-green-500" />
        case 'warning': return <AlertTriangle className="h-5 w-5 text-yellow-500" />
        case 'critical': return <AlertTriangle className="h-5 w-5 text-red-500" />
        default: return <Activity className="h-5 w-5 text-gray-500" />
      }
    }

    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            {getStatusIcon(systemStatus.overall)}
            <span className={getStatusColor(systemStatus.overall)}>
              系统状态 - {systemStatus.overall.toUpperCase()}
            </span>
          </CardTitle>
          <CardDescription>
            活跃告警: {systemStatus.activeAlerts} | 严重告警: {systemStatus.criticalAlerts}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <h4 className="text-sm font-medium">服务状态</h4>
            {Object.entries(systemStatus.services).map(([serviceName, service]) => (
              <div key={serviceName} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                <div className="flex items-center gap-2">
                  {serviceName === 'database' && <Database className="h-4 w-4" />}
                  {serviceName === 'api' && <Server className="h-4 w-4" />}
                  {serviceName === 'cache' && <Activity className="h-4 w-4" />}
                  <span className="text-sm font-medium">{serviceName}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Badge 
                    variant={service.status === 'online' ? 'default' : 'destructive'}
                    className="text-xs"
                  >
                    {service.status}
                  </Badge>
                  {service.responseTime && (
                    <span className="text-xs text-muted-foreground">
                      {service.responseTime}ms
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* 头部控制区域 */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">实时监控</h2>
          <p className="text-muted-foreground">
            系统实时状态监控和告警管理
          </p>
        </div>
        <div className="flex items-center gap-2">
          {renderConnectionStatus()}
          <Separator orientation="vertical" className="h-6" />
          <Button
            variant="outline"
            size="sm"
            onClick={() => setAutoRefresh(!autoRefresh)}
          >
            {autoRefresh ? '暂停刷新' : '开始刷新'}
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={refreshData}
            disabled={isLoading}
          >
            <RefreshCw className={`h-4 w-4 mr-1 ${isLoading ? 'animate-spin' : ''}`} />
            刷新
          </Button>
        </div>
      </div>

      {/* 错误提示 */}
      {error && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {/* 系统状态总览 */}
      {systemStatus && renderSystemStatus()}

      {/* 监控指标网格 */}
      <div>
        <h3 className="text-lg font-medium mb-4">监控指标</h3>
        {isLoading && metrics.length === 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {[...Array(6)].map((_, i) => (
              <Card key={i} className="animate-pulse">
                <CardHeader>
                  <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                </CardHeader>
                <CardContent>
                  <div className="h-8 bg-gray-200 rounded w-1/2 mb-2"></div>
                  <div className="h-3 bg-gray-200 rounded w-full"></div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {metrics.map(renderMetricCard)}
          </div>
        )}
      </div>

      {/* 活跃告警 */}
      <div>
        <h3 className="text-lg font-medium mb-4">活跃告警 ({activeAlerts.length})</h3>
        {activeAlerts.length === 0 ? (
          <Card>
            <CardContent className="flex items-center justify-center py-8">
              <div className="text-center">
                <CheckCircle className="h-12 w-12 text-green-500 mx-auto mb-4" />
                <h4 className="text-lg font-medium text-green-600 mb-2">系统正常运行</h4>
                <p className="text-muted-foreground">当前没有活跃的告警</p>
              </div>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-2">
            {activeAlerts.slice(0, 10).map(renderAlert)}
            {activeAlerts.length > 10 && (
              <Card className="text-center py-4">
                <CardContent>
                  <p className="text-muted-foreground">
                    还有 {activeAlerts.length - 10} 个告警未显示
                  </p>
                  <Button variant="outline" size="sm" className="mt-2">
                    查看全部告警
                  </Button>
                </CardContent>
              </Card>
            )}
          </div>
        )}
      </div>
    </div>
  )
}