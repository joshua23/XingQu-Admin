'use client'

import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { supabase } from '@/lib/services/supabase'
import { 
  Activity, 
  AlertCircle, 
  TrendingUp, 
  Users, 
  Clock,
  Zap,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Info
} from 'lucide-react'

interface RealtimeMetric {
  id: string
  name: string
  value: number | string
  unit?: string
  status: 'normal' | 'warning' | 'critical' | 'info'
  trend?: 'up' | 'down' | 'stable'
  threshold?: {
    warning: number
    critical: number
  }
  lastUpdated: Date
}

interface SystemAlert {
  id: string
  type: 'warning' | 'error' | 'info' | 'success'
  title: string
  message: string
  metric?: string
  value?: number
  threshold?: number
  timestamp: Date
  acknowledged: boolean
}

export const RealtimeMonitor = () => {
  const [metrics, setMetrics] = useState<RealtimeMetric[]>([])
  const [alerts, setAlerts] = useState<SystemAlert[]>([])
  const [connectionStatus, setConnectionStatus] = useState<'connected' | 'connecting' | 'disconnected'>('connecting')

  // 初始化实时指标
  useEffect(() => {
    initializeMetrics()
    setupRealtimeSubscription()
    
    // 每5秒更新一次指标
    const interval = setInterval(updateMetrics, 5000)
    
    return () => {
      clearInterval(interval)
      supabase.removeAllChannels()
    }
  }, [])

  // 初始化监控指标
  const initializeMetrics = () => {
    const initialMetrics: RealtimeMetric[] = [
      {
        id: 'online_users',
        name: '在线用户数',
        value: 0,
        unit: '人',
        status: 'normal',
        trend: 'stable',
        threshold: { warning: 5000, critical: 10000 },
        lastUpdated: new Date()
      },
      {
        id: 'api_response_time',
        name: 'API响应时间',
        value: 0,
        unit: 'ms',
        status: 'normal',
        trend: 'stable',
        threshold: { warning: 200, critical: 500 },
        lastUpdated: new Date()
      },
      {
        id: 'error_rate',
        name: '错误率',
        value: 0,
        unit: '%',
        status: 'normal',
        trend: 'stable',
        threshold: { warning: 1, critical: 5 },
        lastUpdated: new Date()
      },
      {
        id: 'ai_usage',
        name: 'AI服务调用量',
        value: 0,
        unit: '次/分',
        status: 'normal',
        trend: 'up',
        threshold: { warning: 1000, critical: 2000 },
        lastUpdated: new Date()
      },
      {
        id: 'db_connections',
        name: '数据库连接数',
        value: 0,
        unit: '个',
        status: 'normal',
        trend: 'stable',
        threshold: { warning: 150, critical: 190 },
        lastUpdated: new Date()
      },
      {
        id: 'memory_usage',
        name: '内存使用率',
        value: 0,
        unit: '%',
        status: 'normal',
        trend: 'stable',
        threshold: { warning: 70, critical: 90 },
        lastUpdated: new Date()
      }
    ]
    
    setMetrics(initialMetrics)
  }

  // 设置实时订阅
  const setupRealtimeSubscription = async () => {
    try {
      // 订阅用户活动变化
      const channel = supabase
        .channel('realtime-monitor')
        .on('postgres_changes', 
          { 
            event: '*', 
            schema: 'public', 
            table: 'xq_tracking_events' 
          },
          (payload) => {
            handleRealtimeEvent(payload)
          }
        )
        .subscribe((status) => {
          if (status === 'SUBSCRIBED') {
            setConnectionStatus('connected')
          } else if (status === 'CHANNEL_ERROR') {
            setConnectionStatus('disconnected')
          }
        })
    } catch (error) {
      console.error('实时订阅设置失败:', error)
      setConnectionStatus('disconnected')
    }
  }

  // 处理实时事件
  const handleRealtimeEvent = (payload: any) => {
    // 更新在线用户数
    if (payload.eventType === 'INSERT') {
      updateMetricValue('online_users', (prev) => {
        const newValue = typeof prev === 'number' ? prev + 1 : 1
        checkThresholdAndAlert('online_users', newValue)
        return newValue
      })
    }
  }

  // 更新指标数据
  const updateMetrics = async () => {
    try {
      // 获取实时数据
      const now = new Date()
      const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000)

      // 获取在线用户数
      const { data: activeUsers } = await supabase
        .from('xq_tracking_events')
        .select('user_id')
        .gte('created_at', fiveMinutesAgo.toISOString())
        .not('user_id', 'is', null)

      const onlineUserCount = new Set(activeUsers?.map(u => u.user_id) || []).size
      updateMetricValue('online_users', onlineUserCount)

      // 模拟其他指标（实际应用中从真实数据源获取）
      updateMetricValue('api_response_time', Math.floor(Math.random() * 150) + 50)
      updateMetricValue('error_rate', Math.random() * 2)
      updateMetricValue('ai_usage', Math.floor(Math.random() * 500) + 100)
      updateMetricValue('db_connections', Math.floor(Math.random() * 50) + 30)
      updateMetricValue('memory_usage', Math.floor(Math.random() * 30) + 40)

    } catch (error) {
      console.error('更新指标失败:', error)
      createAlert({
        type: 'error',
        title: '数据更新失败',
        message: '无法获取最新的监控数据'
      })
    }
  }

  // 更新单个指标值
  const updateMetricValue = (metricId: string, value: number | ((prev: number | string) => number)) => {
    setMetrics(prev => prev.map(metric => {
      if (metric.id === metricId) {
        const newValue = typeof value === 'function' 
          ? value(metric.value)
          : value

        // 计算趋势
        const oldValue = typeof metric.value === 'number' ? metric.value : 0
        const numValue = typeof newValue === 'number' ? newValue : 0
        
        let trend: 'up' | 'down' | 'stable' = 'stable'
        if (numValue > oldValue * 1.05) trend = 'up'
        else if (numValue < oldValue * 0.95) trend = 'down'

        // 检查阈值
        const status = checkThreshold(metric, numValue)
        
        if (status !== metric.status && status !== 'normal') {
          checkThresholdAndAlert(metricId, numValue)
        }

        return {
          ...metric,
          value: typeof newValue === 'number' ? Math.round(newValue * 100) / 100 : newValue,
          trend,
          status,
          lastUpdated: new Date()
        }
      }
      return metric
    }))
  }

  // 检查阈值
  const checkThreshold = (metric: RealtimeMetric, value: number): RealtimeMetric['status'] => {
    if (!metric.threshold) return 'normal'
    
    if (value >= metric.threshold.critical) return 'critical'
    if (value >= metric.threshold.warning) return 'warning'
    return 'normal'
  }

  // 检查阈值并生成告警
  const checkThresholdAndAlert = (metricId: string, value: number) => {
    const metric = metrics.find(m => m.id === metricId)
    if (!metric || !metric.threshold) return

    if (value >= metric.threshold.critical) {
      createAlert({
        type: 'error',
        title: `${metric.name}超过临界值`,
        message: `当前值: ${value}${metric.unit || ''}, 临界值: ${metric.threshold.critical}${metric.unit || ''}`,
        metric: metricId,
        value,
        threshold: metric.threshold.critical
      })
    } else if (value >= metric.threshold.warning) {
      createAlert({
        type: 'warning',
        title: `${metric.name}接近警戒值`,
        message: `当前值: ${value}${metric.unit || ''}, 警戒值: ${metric.threshold.warning}${metric.unit || ''}`,
        metric: metricId,
        value,
        threshold: metric.threshold.warning
      })
    }
  }

  // 创建告警
  const createAlert = (alert: Omit<SystemAlert, 'id' | 'timestamp' | 'acknowledged'>) => {
    const newAlert: SystemAlert = {
      ...alert,
      id: `alert_${Date.now()}_${Math.random()}`,
      timestamp: new Date(),
      acknowledged: false
    }

    setAlerts(prev => [newAlert, ...prev].slice(0, 10)) // 最多保留10条告警
  }

  // 确认告警
  const acknowledgeAlert = (alertId: string) => {
    setAlerts(prev => prev.map(alert => 
      alert.id === alertId ? { ...alert, acknowledged: true } : alert
    ))
  }

  // 获取状态图标
  const getStatusIcon = (status: RealtimeMetric['status']) => {
    switch (status) {
      case 'critical':
        return <XCircle className="w-4 h-4 text-destructive" />
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-warning" />
      case 'info':
        return <Info className="w-4 h-4 text-primary" />
      default:
        return <CheckCircle className="w-4 h-4 text-success" />
    }
  }

  // 获取告警图标
  const getAlertIcon = (type: SystemAlert['type']) => {
    switch (type) {
      case 'error':
        return <XCircle className="w-4 h-4" />
      case 'warning':
        return <AlertTriangle className="w-4 h-4" />
      case 'success':
        return <CheckCircle className="w-4 h-4" />
      default:
        return <Info className="w-4 h-4" />
    }
  }

  return (
    <div className="space-y-6">
      {/* 连接状态 */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">实时监控</h2>
        <div className="flex items-center gap-2">
          <div className={`w-2 h-2 rounded-full ${
            connectionStatus === 'connected' ? 'bg-success animate-pulse' :
            connectionStatus === 'connecting' ? 'bg-warning animate-pulse' :
            'bg-destructive'
          }`} />
          <span className="text-sm text-muted-foreground">
            {connectionStatus === 'connected' ? '已连接' :
             connectionStatus === 'connecting' ? '连接中' :
             '已断开'}
          </span>
        </div>
      </div>

      {/* 实时指标网格 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {metrics.map(metric => (
          <Card key={metric.id} className={`
            border-l-4 transition-all duration-300
            ${metric.status === 'critical' ? 'border-l-destructive bg-destructive/5' :
              metric.status === 'warning' ? 'border-l-warning bg-warning/5' :
              'border-l-primary'}
          `}>
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  {metric.name}
                </CardTitle>
                <div className="flex items-center gap-2">
                  {getStatusIcon(metric.status)}
                  {metric.trend && (
                    <TrendingUp 
                      className={`w-4 h-4 ${
                        metric.trend === 'up' ? 'text-success rotate-0' :
                        metric.trend === 'down' ? 'text-destructive rotate-180' :
                        'text-muted-foreground'
                      }`}
                    />
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="flex items-baseline justify-between">
                <span className="text-2xl font-bold">
                  {typeof metric.value === 'number' ? metric.value.toLocaleString() : metric.value}
                </span>
                {metric.unit && (
                  <span className="text-sm text-muted-foreground ml-1">
                    {metric.unit}
                  </span>
                )}
              </div>
              <div className="flex items-center gap-2 mt-2">
                <Clock className="w-3 h-3 text-muted-foreground" />
                <span className="text-xs text-muted-foreground">
                  更新于 {metric.lastUpdated.toLocaleTimeString()}
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* 告警列表 */}
      {alerts.length > 0 && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <AlertCircle className="w-5 h-5 text-warning" />
                系统告警
              </CardTitle>
              <Badge variant="secondary">
                {alerts.filter(a => !a.acknowledged).length} 未确认
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {alerts.map(alert => (
                <div
                  key={alert.id}
                  className={`
                    flex items-start gap-3 p-3 rounded-lg border
                    ${alert.acknowledged ? 'bg-muted/30 opacity-60' : 
                      alert.type === 'error' ? 'bg-destructive/10 border-destructive/30' :
                      alert.type === 'warning' ? 'bg-warning/10 border-warning/30' :
                      alert.type === 'success' ? 'bg-success/10 border-success/30' :
                      'bg-primary/10 border-primary/30'}
                  `}
                >
                  <div className={`
                    ${alert.type === 'error' ? 'text-destructive' :
                      alert.type === 'warning' ? 'text-warning' :
                      alert.type === 'success' ? 'text-success' :
                      'text-primary'}
                  `}>
                    {getAlertIcon(alert.type)}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-sm">{alert.title}</h4>
                      <span className="text-xs text-muted-foreground">
                        {alert.timestamp.toLocaleTimeString()}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground mt-1">
                      {alert.message}
                    </p>
                  </div>
                  {!alert.acknowledged && (
                    <button
                      onClick={() => acknowledgeAlert(alert.id)}
                      className="text-xs text-primary hover:text-primary/80 transition-colors"
                    >
                      确认
                    </button>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}