/**
 * 星趣后台管理系统 - 实时监控Hook
 * 提供实时监控数据订阅和管理功能
 * Created: 2025-09-05
 */

import { useState, useEffect, useCallback, useRef } from 'react'
import { monitoringService } from '../services/monitoringService'
import type { 
  RealtimeMetric, 
  SystemAlert, 
  SystemStatus,
  UseRealtimeMonitoringOptions 
} from '../types/admin'

interface UseRealtimeMonitoringResult {
  // 监控数据
  metrics: RealtimeMetric[]
  systemStatus: SystemStatus | null
  activeAlerts: SystemAlert[]
  
  // 状态
  isLoading: boolean
  isConnected: boolean
  error: string | null
  lastUpdated: Date | null
  
  // 操作方法
  startMonitoring: () => void
  stopMonitoring: () => void
  acknowledgeAlert: (alertId: string) => Promise<void>
  resolveAlert: (alertId: string) => Promise<void>
  refreshData: () => Promise<void>
}

const DEFAULT_OPTIONS: UseRealtimeMonitoringOptions = {
  interval: 5000,
  enabled: true
}

export function useRealtimeMonitoring(
  options: UseRealtimeMonitoringOptions = {}
): UseRealtimeMonitoringResult {
  const opts = { ...DEFAULT_OPTIONS, ...options }
  
  // 状态管理
  const [metrics, setMetrics] = useState<RealtimeMetric[]>([])
  const [systemStatus, setSystemStatus] = useState<SystemStatus | null>(null)
  const [activeAlerts, setActiveAlerts] = useState<SystemAlert[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isConnected, setIsConnected] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  
  // 引用管理
  const unsubscribeMetrics = useRef<(() => void) | null>(null)
  const unsubscribeAlerts = useRef<(() => void) | null>(null)
  const isMonitoringRef = useRef(false)

  // 开始监控
  const startMonitoring = useCallback(() => {
    if (isMonitoringRef.current || !opts.enabled) return

    isMonitoringRef.current = true
    setIsLoading(true)
    setError(null)

    try {
      // 订阅指标数据
      unsubscribeMetrics.current = monitoringService.subscribeToMetrics((newMetrics) => {
        setMetrics(newMetrics)
        setLastUpdated(new Date())
        setIsLoading(false)
        setIsConnected(true)
        setError(null)

        if (opts.onError && error) {
          setError(null)
        }
      })

      // 订阅告警数据
      unsubscribeAlerts.current = monitoringService.subscribeToAlerts((alert) => {
        setActiveAlerts(prev => {
          // 避免重复添加
          const exists = prev.some(a => a.id === alert.id)
          if (exists) return prev
          
          const updated = [alert, ...prev].slice(0, 50) // 限制最多显示50个告警
          
          // 通知回调
          if (opts.onAlert) {
            opts.onAlert(alert)
          }
          
          return updated
        })
      })

      // 启动实时监控
      monitoringService.startRealtimeMonitoring(opts.interval)

    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : '启动监控失败'
      setError(errorMsg)
      setIsLoading(false)
      setIsConnected(false)
      
      if (opts.onError) {
        opts.onError(new Error(errorMsg))
      }
    }
  }, [opts.enabled, opts.interval, opts.onAlert, opts.onError, error])

  // 停止监控
  const stopMonitoring = useCallback(() => {
    if (!isMonitoringRef.current) return

    isMonitoringRef.current = false

    // 取消订阅
    if (unsubscribeMetrics.current) {
      unsubscribeMetrics.current()
      unsubscribeMetrics.current = null
    }

    if (unsubscribeAlerts.current) {
      unsubscribeAlerts.current()
      unsubscribeAlerts.current = null
    }

    // 停止监控服务
    monitoringService.stopRealtimeMonitoring()
    
    setIsConnected(false)
    setIsLoading(false)
  }, [])

  // 确认告警
  const acknowledgeAlert = useCallback(async (alertId: string) => {
    try {
      // 这里需要获取当前管理员ID，实际项目中从认证上下文获取
      const adminId = 'current-admin-id' // TODO: 从认证上下文获取
      
      await monitoringService.acknowledgeAlert(alertId, adminId)
      
      // 更新本地状态
      setActiveAlerts(prev => 
        prev.map(alert => 
          alert.id === alertId 
            ? { ...alert, status: 'acknowledged', acknowledgedAt: new Date().toISOString() }
            : alert
        )
      )
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : '确认告警失败'
      setError(errorMsg)
      
      if (opts.onError) {
        opts.onError(new Error(errorMsg))
      }
    }
  }, [opts.onError])

  // 解决告警
  const resolveAlert = useCallback(async (alertId: string) => {
    try {
      // 这里需要获取当前管理员ID
      const adminId = 'current-admin-id' // TODO: 从认证上下文获取
      
      await monitoringService.resolveAlert(alertId, adminId)
      
      // 从本地状态中移除
      setActiveAlerts(prev => prev.filter(alert => alert.id !== alertId))
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : '解决告警失败'
      setError(errorMsg)
      
      if (opts.onError) {
        opts.onError(new Error(errorMsg))
      }
    }
  }, [opts.onError])

  // 刷新数据
  const refreshData = useCallback(async () => {
    if (!isMonitoringRef.current) return

    setIsLoading(true)
    setError(null)

    try {
      // 添加超时处理
      const timeout = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('监控数据加载超时')), 10000)
      )

      await Promise.race([
        Promise.all([
          // 获取系统状态
          monitoringService.getSystemStatus().then(status => setSystemStatus(status)),
          // 获取活跃告警
          monitoringService.getActiveAlerts(20).then(alerts => setActiveAlerts(alerts))
        ]),
        timeout
      ])

      setLastUpdated(new Date())
      setError(null)
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : '刷新数据失败'
      setError(errorMsg)
      
      if (opts.onError) {
        opts.onError(new Error(errorMsg))
      }
    } finally {
      setIsLoading(false)
    }
  }, [opts.onError])

  // 生命周期管理
  useEffect(() => {
    if (opts.enabled) {
      startMonitoring()
    }

    return () => {
      stopMonitoring()
    }
  }, [opts.enabled, startMonitoring, stopMonitoring])

  // 定期刷新系统状态
  useEffect(() => {
    if (!opts.enabled || !isMonitoringRef.current) return

    const statusInterval = setInterval(async () => {
      try {
        const status = await monitoringService.getSystemStatus()
        setSystemStatus(status)
      } catch (err) {
        console.warn('获取系统状态失败:', err)
      }
    }, opts.interval * 2) // 系统状态刷新频率为监控数据的一半

    return () => clearInterval(statusInterval)
  }, [opts.enabled, opts.interval])

  return {
    // 监控数据
    metrics,
    systemStatus,
    activeAlerts,
    
    // 状态
    isLoading,
    isConnected,
    error,
    lastUpdated,
    
    // 操作方法
    startMonitoring,
    stopMonitoring,
    acknowledgeAlert,
    resolveAlert,
    refreshData
  }
}

// 导出类型
export type { UseRealtimeMonitoringResult }