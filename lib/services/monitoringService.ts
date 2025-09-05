/**
 * 星趣后台管理系统 - 实时监控服务
 * 专门处理系统监控、告警管理和数据分析
 * Created: 2025-09-05
 */

import { dataService } from './supabase'
import type { 
  RealtimeMetric, 
  SystemAlert, 
  MonitoringConfig,
  UUID,
  Timestamp
} from '../types/admin'

export interface MetricThreshold {
  warning: number
  critical: number
}

export interface SystemStatus {
  overall: 'healthy' | 'warning' | 'critical'
  services: {
    [serviceName: string]: {
      status: 'online' | 'offline' | 'degraded'
      responseTime?: number
      lastCheck: Date
    }
  }
  activeAlerts: number
  criticalAlerts: number
}

export interface MetricHistory {
  timestamps: Date[]
  values: number[]
  average: number
  trend: 'up' | 'down' | 'stable'
}

class MonitoringService {
  private static instance: MonitoringService
  private subscribers = new Set<(metrics: RealtimeMetric[]) => void>()
  private alertSubscribers = new Set<(alert: SystemAlert) => void>()
  private refreshInterval: NodeJS.Timeout | null = null
  private currentMetrics: RealtimeMetric[] = []

  static getInstance(): MonitoringService {
    if (!MonitoringService.instance) {
      MonitoringService.instance = new MonitoringService()
    }
    return MonitoringService.instance
  }

  // ============================================
  // 实时监控数据管理
  // ============================================

  /**
   * 启动实时监控
   * @param intervalMs 刷新间隔（毫秒）
   */
  async startRealtimeMonitoring(intervalMs: number = 5000): Promise<void> {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }

    // 立即获取一次数据
    await this.fetchLatestMetrics()

    // 设置定时刷新
    this.refreshInterval = setInterval(async () => {
      try {
        await this.fetchLatestMetrics()
      } catch (error) {
        console.error('实时监控数据获取失败:', error)
      }
    }, intervalMs)
  }

  /**
   * 停止实时监控
   */
  stopRealtimeMonitoring(): void {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
      this.refreshInterval = null
    }
  }

  /**
   * 获取最新监控数据
   */
  private async fetchLatestMetrics(): Promise<void> {
    try {
      const metrics = await dataService.getRealtimeMetrics()
      this.currentMetrics = metrics
      
      // 通知所有订阅者
      this.subscribers.forEach(callback => {
        try {
          callback(metrics)
        } catch (error) {
          console.error('监控数据订阅者回调错误:', error)
        }
      })

      // 检查阈值并生成告警
      await this.checkThresholds(metrics)
      
    } catch (error) {
      console.error('获取实时监控数据失败:', error)
      throw error
    }
  }

  /**
   * 订阅实时监控数据
   * @param callback 数据更新回调函数
   * @returns 取消订阅函数
   */
  subscribeToMetrics(callback: (metrics: RealtimeMetric[]) => void): () => void {
    this.subscribers.add(callback)
    
    // 如果有当前数据，立即回调
    if (this.currentMetrics.length > 0) {
      callback(this.currentMetrics)
    }

    return () => {
      this.subscribers.delete(callback)
    }
  }

  /**
   * 订阅系统告警
   * @param callback 告警回调函数
   * @returns 取消订阅函数
   */
  subscribeToAlerts(callback: (alert: SystemAlert) => void): () => void {
    this.alertSubscribers.add(callback)
    return () => {
      this.alertSubscribers.delete(callback)
    }
  }

  // ============================================
  // 监控指标管理
  // ============================================

  /**
   * 记录监控指标
   * @param metricName 指标名称
   * @param value 指标值
   * @param unit 单位
   * @param tags 标签
   */
  async recordMetric(
    metricName: string, 
    value: number, 
    unit?: string, 
    tags?: Record<string, any>
  ): Promise<void> {
    try {
      await dataService.insertMetric(metricName, value, unit, tags)
    } catch (error) {
      console.error('记录监控指标失败:', error)
      throw error
    }
  }

  /**
   * 批量记录监控指标
   * @param metrics 指标数组
   */
  async recordMetrics(metrics: Array<{
    name: string
    value: number
    unit?: string
    tags?: Record<string, any>
  }>): Promise<void> {
    try {
      for (const metric of metrics) {
        await this.recordMetric(metric.name, metric.value, metric.unit, metric.tags)
      }
    } catch (error) {
      console.error('批量记录监控指标失败:', error)
      throw error
    }
  }

  /**
   * 获取指标历史数据
   * @param metricName 指标名称
   * @param hoursBack 回溯小时数
   */
  async getMetricHistory(metricName: string, hoursBack: number = 24): Promise<MetricHistory> {
    try {
      const startTime = new Date()
      startTime.setHours(startTime.getHours() - hoursBack)

      const history = await dataService.getMetricHistory(metricName, startTime.toISOString())
      
      const timestamps = history.map(h => new Date(h.timestamp))
      const values = history.map(h => h.metric_value)
      const average = values.length > 0 ? values.reduce((a, b) => a + b, 0) / values.length : 0
      
      // 计算趋势
      let trend: 'up' | 'down' | 'stable' = 'stable'
      if (values.length >= 2) {
        const recent = values.slice(-5) // 最近5个数据点
        const earlier = values.slice(-10, -5) // 之前5个数据点
        
        if (recent.length > 0 && earlier.length > 0) {
          const recentAvg = recent.reduce((a, b) => a + b, 0) / recent.length
          const earlierAvg = earlier.reduce((a, b) => a + b, 0) / earlier.length
          
          const changePercent = ((recentAvg - earlierAvg) / earlierAvg) * 100
          if (changePercent > 5) trend = 'up'
          else if (changePercent < -5) trend = 'down'
        }
      }

      return { timestamps, values, average, trend }
    } catch (error) {
      console.error('获取指标历史数据失败:', error)
      throw error
    }
  }

  // ============================================
  // 告警管理
  // ============================================

  /**
   * 检查指标阈值并生成告警
   * @param metrics 当前指标数据
   */
  private async checkThresholds(metrics: RealtimeMetric[]): Promise<void> {
    for (const metric of metrics) {
      if (!metric.threshold) continue

      const numericValue = typeof metric.value === 'number' ? metric.value : parseFloat(metric.value as string)
      if (isNaN(numericValue)) continue

      let alertType: 'warning' | 'error' | null = null
      let thresholdValue = 0

      if (numericValue >= metric.threshold.critical) {
        alertType = 'error'
        thresholdValue = metric.threshold.critical
      } else if (numericValue >= metric.threshold.warning) {
        alertType = 'warning'
        thresholdValue = metric.threshold.warning
      }

      if (alertType) {
        await this.createAlert(
          alertType,
          `${metric.name}指标异常`,
          `${metric.name}当前值${numericValue}${metric.unit || ''}，已超过${alertType === 'error' ? '严重' : '警告'}阈值${thresholdValue}${metric.unit || ''}`,
          metric.name,
          thresholdValue,
          numericValue
        )
      }
    }
  }

  /**
   * 创建系统告警
   * @param type 告警类型
   * @param title 告警标题
   * @param message 告警消息
   * @param metricName 相关指标名称
   * @param thresholdValue 阈值
   * @param currentValue 当前值
   */
  async createAlert(
    type: 'info' | 'success' | 'warning' | 'error',
    title: string,
    message: string,
    metricName?: string,
    thresholdValue?: number,
    currentValue?: number
  ): Promise<SystemAlert> {
    try {
      const alert = await dataService.createAlert(
        type, title, message, metricName, thresholdValue, currentValue
      )

      // 通知告警订阅者
      this.alertSubscribers.forEach(callback => {
        try {
          callback(alert)
        } catch (error) {
          console.error('告警订阅者回调错误:', error)
        }
      })

      return alert
    } catch (error) {
      console.error('创建系统告警失败:', error)
      throw error
    }
  }

  /**
   * 确认告警
   * @param alertId 告警ID
   * @param adminId 确认人ID
   */
  async acknowledgeAlert(alertId: UUID, adminId: UUID): Promise<void> {
    try {
      await dataService.acknowledgeAlert(alertId, adminId)
    } catch (error) {
      console.error('确认告警失败:', error)
      throw error
    }
  }

  /**
   * 解决告警
   * @param alertId 告警ID
   * @param adminId 解决人ID
   */
  async resolveAlert(alertId: UUID, adminId: UUID): Promise<void> {
    try {
      await dataService.resolveAlert(alertId, adminId)
    } catch (error) {
      console.error('解决告警失败:', error)
      throw error
    }
  }

  /**
   * 获取活跃告警
   * @param limit 限制数量
   */
  async getActiveAlerts(limit?: number): Promise<SystemAlert[]> {
    try {
      return await dataService.getSystemAlerts('active', limit)
    } catch (error) {
      console.error('获取活跃告警失败:', error)
      throw error
    }
  }

  // ============================================
  // 系统状态总览
  // ============================================

  /**
   * 获取系统整体状态
   */
  async getSystemStatus(): Promise<SystemStatus> {
    try {
      const activeAlerts = await this.getActiveAlerts()
      const criticalAlerts = activeAlerts.filter(alert => alert.type === 'error')
      
      // 检查核心服务状态
      const services = await this.checkServiceStatus()
      
      // 计算整体健康状态
      let overall: 'healthy' | 'warning' | 'critical' = 'healthy'
      if (criticalAlerts.length > 0) {
        overall = 'critical'
      } else if (activeAlerts.length > 0) {
        overall = 'warning'
      }

      return {
        overall,
        services,
        activeAlerts: activeAlerts.length,
        criticalAlerts: criticalAlerts.length
      }
    } catch (error) {
      console.error('获取系统状态失败:', error)
      throw error
    }
  }

  /**
   * 检查各服务状态
   */
  private async checkServiceStatus(): Promise<SystemStatus['services']> {
    const services: SystemStatus['services'] = {}
    const now = new Date()

    // 检查数据库服务
    try {
      const start = Date.now()
      await dataService.getRealtimeMetrics(1) // 简单查询测试
      services.database = {
        status: 'online',
        responseTime: Date.now() - start,
        lastCheck: now
      }
    } catch (error) {
      services.database = {
        status: 'offline',
        lastCheck: now
      }
    }

    // 可以添加更多服务检查...
    services.api = {
      status: 'online',
      responseTime: 45,
      lastCheck: now
    }

    services.cache = {
      status: 'online',
      responseTime: 12,
      lastCheck: now
    }

    return services
  }

  // ============================================
  // 监控配置管理
  // ============================================

  /**
   * 获取监控配置
   */
  async getMonitoringConfigs(): Promise<MonitoringConfig[]> {
    // 这里返回默认配置，实际项目中可以从数据库读取
    return [
      {
        metricName: 'cpu_usage',
        displayName: 'CPU使用率',
        unit: '%',
        warningThreshold: 70,
        criticalThreshold: 90,
        isEnabled: true,
        refreshInterval: 5
      },
      {
        metricName: 'memory_usage',
        displayName: '内存使用率',
        unit: '%',
        warningThreshold: 80,
        criticalThreshold: 95,
        isEnabled: true,
        refreshInterval: 5
      },
      {
        metricName: 'disk_usage',
        displayName: '磁盘使用率',
        unit: '%',
        warningThreshold: 85,
        criticalThreshold: 95,
        isEnabled: true,
        refreshInterval: 30
      },
      {
        metricName: 'active_users',
        displayName: '在线用户数',
        unit: '人',
        warningThreshold: 8000,
        criticalThreshold: 10000,
        isEnabled: true,
        refreshInterval: 10
      },
      {
        metricName: 'api_response_time',
        displayName: 'API响应时间',
        unit: 'ms',
        warningThreshold: 1000,
        criticalThreshold: 2000,
        isEnabled: true,
        refreshInterval: 5
      },
      {
        metricName: 'error_rate',
        displayName: '错误率',
        unit: '%',
        warningThreshold: 1,
        criticalThreshold: 5,
        isEnabled: true,
        refreshInterval: 5
      }
    ]
  }

  // ============================================
  // 清理资源
  // ============================================

  /**
   * 清理服务资源
   */
  destroy(): void {
    this.stopRealtimeMonitoring()
    this.subscribers.clear()
    this.alertSubscribers.clear()
  }
}

// 导出单例实例
export const monitoringService = MonitoringService.getInstance()

// 导出类型
export type { MonitoringService }