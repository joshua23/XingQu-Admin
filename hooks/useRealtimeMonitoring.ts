import { useState, useEffect, useRef, useCallback } from 'react'
import { useAutoRefresh } from './useAutoRefresh'

// 监控数据类型定义
interface SystemMetrics {
  cpuUsage: number
  memoryUsage: number
  diskUsage: number
  networkIn: number
  networkOut: number
  activeConnections: number
  responseTime: number
  errorRate: number
  throughput: number
}

interface BusinessMetrics {
  activeUsers: number
  totalSessions: number
  conversionRate: number
  revenue: number
  orderCount: number
  pageViews: number
}

interface MonitoringData {
  timestamp: Date
  system: SystemMetrics
  business: BusinessMetrics
  alerts: Alert[]
  health: {
    overall: number
    services: Record<string, number>
  }
}

interface Alert {
  id: string
  type: 'warning' | 'error' | 'info' | 'success'
  title: string
  message: string
  timestamp: Date
  acknowledged: boolean
  source: string
}

interface UseRealtimeMonitoringOptions {
  interval?: number
  retryAttempts?: number
  retryDelay?: number
  cacheTimeout?: number
  enabled?: boolean
  onError?: (error: Error) => void
  onDataUpdate?: (data: MonitoringData) => void
}

interface MonitoringState {
  data: MonitoringData | null
  loading: boolean
  error: string | null
  lastUpdated: Date | null
  connectionStatus: 'connected' | 'disconnected' | 'reconnecting'
  retryCount: number
}

export const useRealtimeMonitoring = (options: UseRealtimeMonitoringOptions = {}) => {
  const {
    interval = 30000, // 30秒更新间隔
    retryAttempts = 3,
    retryDelay = 5000,
    cacheTimeout = 60000, // 1分钟缓存
    enabled = true,
    onError,
    onDataUpdate
  } = options

  // 状态管理
  const [state, setState] = useState<MonitoringState>({
    data: null,
    loading: true,
    error: null,
    lastUpdated: null,
    connectionStatus: 'disconnected',
    retryCount: 0
  })

  // 缓存和重试管理
  const cacheRef = useRef<{ data: MonitoringData; timestamp: number } | null>(null)
  const retryTimeoutRef = useRef<NodeJS.Timeout>()
  const abortControllerRef = useRef<AbortController>()

  // 生成模拟数据（实际环境中会从API获取）
  const generateMockData = useCallback((): MonitoringData => {
    const now = new Date()
    const baseMetrics = {
      cpuUsage: 45 + Math.random() * 30,
      memoryUsage: 60 + Math.random() * 20,
      diskUsage: 35 + Math.random() * 15,
      networkIn: Math.random() * 1000,
      networkOut: Math.random() * 800,
      activeConnections: Math.floor(100 + Math.random() * 200),
      responseTime: 80 + Math.random() * 100,
      errorRate: Math.random() * 2,
      throughput: 50 + Math.random() * 100
    }

    const businessMetrics = {
      activeUsers: Math.floor(150 + Math.random() * 300),
      totalSessions: Math.floor(800 + Math.random() * 500),
      conversionRate: 2.5 + Math.random() * 3,
      revenue: Math.floor(1000 + Math.random() * 5000),
      orderCount: Math.floor(20 + Math.random() * 80),
      pageViews: Math.floor(5000 + Math.random() * 10000)
    }

    const alerts: Alert[] = []
    
    // 生成随机告警
    if (baseMetrics.cpuUsage > 70) {
      alerts.push({
        id: `cpu-${now.getTime()}`,
        type: 'warning',
        title: 'CPU使用率过高',
        message: `当前CPU使用率为${baseMetrics.cpuUsage.toFixed(1)}%，建议检查系统负载`,
        timestamp: now,
        acknowledged: false,
        source: 'system-monitor'
      })
    }

    if (baseMetrics.errorRate > 1) {
      alerts.push({
        id: `error-${now.getTime()}`,
        type: 'error',
        title: '错误率异常',
        message: `系统错误率达到${baseMetrics.errorRate.toFixed(2)}%，超过正常阈值`,
        timestamp: now,
        acknowledged: false,
        source: 'error-tracker'
      })
    }

    return {
      timestamp: now,
      system: baseMetrics,
      business: businessMetrics,
      alerts,
      health: {
        overall: Math.max(0, 100 - baseMetrics.cpuUsage * 0.5 - baseMetrics.errorRate * 10),
        services: {
          'api-server': 95 + Math.random() * 5,
          'database': 90 + Math.random() * 8,
          'cache': 98 + Math.random() * 2,
          'cdn': 99 + Math.random() * 1,
          'message-queue': 92 + Math.random() * 6
        }
      }
    }
  }, [])

  // 获取监控数据
  const fetchMonitoringData = useCallback(async (attempt = 0): Promise<MonitoringData> => {
    // 检查缓存
    if (cacheRef.current && Date.now() - cacheRef.current.timestamp < cacheTimeout) {
      return cacheRef.current.data
    }

    // 取消之前的请求
    if (abortControllerRef.current) {
      abortControllerRef.current.abort()
    }

    abortControllerRef.current = new AbortController()

    try {
      setState(prev => ({ 
        ...prev, 
        loading: attempt === 0 ? true : prev.loading,
        connectionStatus: attempt > 0 ? 'reconnecting' : 'connected',
        retryCount: attempt
      }))

      // 模拟API延迟
      await new Promise(resolve => setTimeout(resolve, Math.random() * 1000 + 500))

      // 模拟网络错误（5%概率）
      if (Math.random() < 0.05 && attempt === 0) {
        throw new Error('网络连接超时')
      }

      const data = generateMockData()

      // 更新缓存
      cacheRef.current = {
        data,
        timestamp: Date.now()
      }

      setState(prev => ({
        ...prev,
        data,
        loading: false,
        error: null,
        lastUpdated: new Date(),
        connectionStatus: 'connected',
        retryCount: 0
      }))

      // 触发数据更新回调
      if (onDataUpdate) {
        onDataUpdate(data)
      }

      return data

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '获取监控数据失败'

      // 重试机制
      if (attempt < retryAttempts) {
        console.warn(`监控数据获取失败，${retryDelay/1000}秒后重试 (${attempt + 1}/${retryAttempts})`)
        
        retryTimeoutRef.current = setTimeout(() => {
          fetchMonitoringData(attempt + 1)
        }, retryDelay)

        setState(prev => ({
          ...prev,
          connectionStatus: 'reconnecting',
          retryCount: attempt + 1
        }))

        throw error
      } else {
        setState(prev => ({
          ...prev,
          loading: false,
          error: errorMessage,
          connectionStatus: 'disconnected',
          retryCount: attempt
        }))

        if (onError) {
          onError(error instanceof Error ? error : new Error(errorMessage))
        }

        throw error
      }
    }
  }, [cacheTimeout, retryAttempts, retryDelay, generateMockData, onDataUpdate, onError])

  // 手动刷新
  const refresh = useCallback(() => {
    if (retryTimeoutRef.current) {
      clearTimeout(retryTimeoutRef.current)
    }
    return fetchMonitoringData(0)
  }, [fetchMonitoringData])

  // 确认告警
  const acknowledgeAlert = useCallback((alertId: string) => {
    setState(prev => {
      if (!prev.data) return prev

      const updatedAlerts = prev.data.alerts.map(alert =>
        alert.id === alertId ? { ...alert, acknowledged: true } : alert
      )

      return {
        ...prev,
        data: {
          ...prev.data,
          alerts: updatedAlerts
        }
      }
    })
  }, [])

  // 获取特定指标的历史趋势
  const getMetricTrend = useCallback((metricPath: string, timeRange: number = 300000) => {
    // 实际环境中会从时序数据库获取历史数据
    const points = 20
    const trend = []
    const now = Date.now()
    
    for (let i = points; i >= 0; i--) {
      const timestamp = now - (i * timeRange / points)
      const value = Math.random() * 100 // 模拟数据
      trend.push({ timestamp: new Date(timestamp), value })
    }
    
    return trend
  }, [])

  // 获取系统健康评分
  const getHealthScore = useCallback(() => {
    if (!state.data) return 0
    return state.data.health.overall
  }, [state.data])

  // 获取活跃告警数量
  const getActiveAlertsCount = useCallback(() => {
    if (!state.data) return 0
    return state.data.alerts.filter(alert => !alert.acknowledged).length
  }, [state.data])

  // 自动刷新
  const { cleanup } = useAutoRefresh(
    () => {
      if (enabled) {
        fetchMonitoringData(0).catch(() => {
          // 错误已在fetchMonitoringData中处理
        })
      }
    },
    {
      interval,
      enabled,
      immediate: true
    }
  )

  // 清理函数
  useEffect(() => {
    return () => {
      cleanup()
      if (retryTimeoutRef.current) {
        clearTimeout(retryTimeoutRef.current)
      }
      if (abortControllerRef.current) {
        abortControllerRef.current.abort()
      }
    }
  }, [cleanup])

  return {
    // 状态
    data: state.data,
    loading: state.loading,
    error: state.error,
    lastUpdated: state.lastUpdated,
    connectionStatus: state.connectionStatus,
    retryCount: state.retryCount,
    
    // 方法
    refresh,
    acknowledgeAlert,
    getMetricTrend,
    getHealthScore,
    getActiveAlertsCount,
    
    // 快速访问的数据
    systemMetrics: state.data?.system,
    businessMetrics: state.data?.business,
    alerts: state.data?.alerts || [],
    healthScore: state.data?.health.overall || 0,
    serviceHealth: state.data?.health.services || {}
  }
}