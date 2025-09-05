/**
 * 星趣后台管理系统 - 智能推荐管理Hook
 * 提供推荐算法管理、数据分析和实时监控的React Hook
 * Created: 2025-09-05
 */

import { useState, useCallback, useRef, useEffect } from 'react'
import { recommendationService, type Agent, type RecommendationResult } from '../services/recommendationService'

interface RecommendationStats {
  total_agents: number
  active_agents: number
  categories: Array<{ name: string; count: number }>
  top_tags: Array<{ tag: string; count: number }>
}

interface RecommendationAnalytics {
  algorithm_performance: Record<string, number>
  user_engagement_rate: number
  success_rate: number
  daily_stats: Array<{
    date: string
    recommendations: number
    clicks: number
    conversions: number
  }>
}

interface RecommendationFilters {
  algorithm?: string
  category?: string
  dateRange?: {
    start: string
    end: string
  }
  minScore?: number
}

interface UseRecommendationManagementResult {
  // 数据状态
  agents: Agent[]
  recommendations: RecommendationResult[]
  trendingRecs: RecommendationResult[]
  personalizedRecs: RecommendationResult[]
  searchRecs: RecommendationResult[]
  stats: RecommendationStats | null
  analytics: RecommendationAnalytics | null
  
  // 加载状态
  loading: boolean
  processing: boolean
  error: string | null
  
  // 推荐管理
  loadStats: () => Promise<void>
  loadTrendingRecommendations: (limit?: number) => Promise<void>
  loadPersonalizedRecommendations: (userId: string, limit?: number) => Promise<void>
  searchRecommendations: (query: string, limit?: number) => Promise<void>
  refreshRecommendations: () => Promise<void>
  
  // 算法分析
  loadAnalytics: (filters?: RecommendationFilters) => Promise<void>
  testAlgorithm: (algorithm: string, sampleSize?: number) => Promise<RecommendationResult[]>
  
  // 实时监控
  startMonitoring: () => void
  stopMonitoring: () => void
  monitoringActive: boolean
  
  // 工具方法
  clearError: () => void
  exportRecommendationData: (filters?: RecommendationFilters) => Promise<string>
}

export function useRecommendationManagement(): UseRecommendationManagementResult {
  // 数据状态
  const [agents, setAgents] = useState<Agent[]>([])
  const [recommendations, setRecommendations] = useState<RecommendationResult[]>([])
  const [trendingRecs, setTrendingRecs] = useState<RecommendationResult[]>([])
  const [personalizedRecs, setPersonalizedRecs] = useState<RecommendationResult[]>([])
  const [searchRecs, setSearchRecs] = useState<RecommendationResult[]>([])
  const [stats, setStats] = useState<RecommendationStats | null>(null)
  const [analytics, setAnalytics] = useState<RecommendationAnalytics | null>(null)
  
  // 加载状态
  const [loading, setLoading] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [monitoringActive, setMonitoringActive] = useState(false)
  
  // 引用管理
  const monitoringIntervalRef = useRef<NodeJS.Timeout | null>(null)
  
  // 错误处理
  const handleError = useCallback((err: unknown, defaultMessage: string) => {
    const message = err instanceof Error ? err.message : defaultMessage
    setError(message)
    console.error(defaultMessage, err)
  }, [])

  const clearError = useCallback(() => {
    setError(null)
  }, [])

  // ============================================
  // 数据加载方法
  // ============================================

  const loadStats = useCallback(async () => {
    try {
      const result = await recommendationService.getRecommendationStats()
      setStats(result)
    } catch (err) {
      handleError(err, '加载推荐统计失败')
    }
  }, [handleError])

  const loadTrendingRecommendations = useCallback(async (limit = 8) => {
    try {
      const result = await recommendationService.getTrendingRecommendations(limit)
      setTrendingRecs(result)
    } catch (err) {
      handleError(err, '加载趋势推荐失败')
    }
  }, [handleError])

  const loadPersonalizedRecommendations = useCallback(async (userId: string, limit = 8) => {
    try {
      const result = await recommendationService.getPersonalizedRecommendations(userId, limit)
      setPersonalizedRecs(result)
    } catch (err) {
      handleError(err, '加载个性化推荐失败')
    }
  }, [handleError])

  const searchRecommendations = useCallback(async (query: string, limit = 8) => {
    if (!query.trim()) {
      setSearchRecs([])
      return
    }

    setProcessing(true)
    clearError()

    try {
      const result = await recommendationService.getSearchRecommendations(query, limit)
      setSearchRecs(result)
    } catch (err) {
      handleError(err, '搜索推荐失败')
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const refreshRecommendations = useCallback(async () => {
    setLoading(true)
    clearError()

    try {
      await Promise.all([
        loadStats(),
        loadTrendingRecommendations()
      ])
    } catch (err) {
      handleError(err, '刷新推荐数据失败')
    } finally {
      setLoading(false)
    }
  }, [loadStats, loadTrendingRecommendations, handleError, clearError])

  // ============================================
  // 算法分析方法
  // ============================================

  const loadAnalytics = useCallback(async (filters?: RecommendationFilters) => {
    try {
      // 模拟分析数据加载
      const mockAnalytics: RecommendationAnalytics = {
        algorithm_performance: {
          'trending': 0.85,
          'personalized': 0.88,
          'category_based': 0.75,
          'content_based': 0.72,
          'collaborative': 0.82
        },
        user_engagement_rate: 0.65,
        success_rate: 0.78,
        daily_stats: generateMockDailyStats(30)
      }
      
      setAnalytics(mockAnalytics)
    } catch (err) {
      handleError(err, '加载分析数据失败')
    }
  }, [handleError])

  const testAlgorithm = useCallback(async (algorithm: string, sampleSize = 10): Promise<RecommendationResult[]> => {
    setProcessing(true)
    clearError()

    try {
      let results: RecommendationResult[] = []
      
      switch (algorithm) {
        case 'trending':
          results = await recommendationService.getTrendingRecommendations(sampleSize)
          break
        case 'category_based':
          results = await recommendationService.getCategoryRecommendations('工作助手', sampleSize)
          break
        case 'content_based':
          results = await recommendationService.getSearchRecommendations('助手', sampleSize)
          break
        case 'personalized':
          results = await recommendationService.getPersonalizedRecommendations('test-user', sampleSize)
          break
        default:
          throw new Error('不支持的算法类型')
      }
      
      return results
    } catch (err) {
      handleError(err, `测试${algorithm}算法失败`)
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  // ============================================
  // 实时监控方法
  // ============================================

  const startMonitoring = useCallback(() => {
    if (monitoringIntervalRef.current) return

    setMonitoringActive(true)
    monitoringIntervalRef.current = setInterval(async () => {
      try {
        await loadStats()
      } catch (error) {
        console.error('监控更新失败:', error)
      }
    }, 15000) // 15秒更新一次
  }, [loadStats])

  const stopMonitoring = useCallback(() => {
    if (monitoringIntervalRef.current) {
      clearInterval(monitoringIntervalRef.current)
      monitoringIntervalRef.current = null
    }
    setMonitoringActive(false)
  }, [])

  // ============================================
  // 数据导出方法
  // ============================================

  const exportRecommendationData = useCallback(async (filters?: RecommendationFilters): Promise<string> => {
    try {
      const currentStats = stats || await recommendationService.getRecommendationStats()
      
      // 生成CSV格式的数据
      let csvContent = 'data:text/csv;charset=utf-8,'
      csvContent += '推荐系统数据导出报告\n\n'
      csvContent += `总智能体数量,${currentStats.total_agents}\n`
      csvContent += `活跃智能体数量,${currentStats.active_agents}\n\n`
      
      csvContent += '分类分布:\n'
      csvContent += '分类名称,数量\n'
      currentStats.categories.forEach(cat => {
        csvContent += `${cat.name},${cat.count}\n`
      })
      
      csvContent += '\n热门标签:\n'
      csvContent += '标签名称,使用次数\n'
      currentStats.top_tags.forEach(tag => {
        csvContent += `${tag.tag},${tag.count}\n`
      })
      
      return encodeURI(csvContent)
    } catch (err) {
      handleError(err, '导出推荐数据失败')
      throw err
    }
  }, [stats, handleError])

  // ============================================
  // 生命周期管理
  // ============================================

  useEffect(() => {
    // 组件挂载时自动加载基础数据
    refreshRecommendations()
    
    // 组件卸载时清理监控
    return () => {
      stopMonitoring()
    }
  }, [refreshRecommendations, stopMonitoring])

  return {
    // 数据状态
    agents,
    recommendations,
    trendingRecs,
    personalizedRecs,
    searchRecs,
    stats,
    analytics,
    
    // 加载状态
    loading,
    processing,
    error,
    
    // 推荐管理
    loadStats,
    loadTrendingRecommendations,
    loadPersonalizedRecommendations,
    searchRecommendations,
    refreshRecommendations,
    
    // 算法分析
    loadAnalytics,
    testAlgorithm,
    
    // 实时监控
    startMonitoring,
    stopMonitoring,
    monitoringActive,
    
    // 工具方法
    clearError,
    exportRecommendationData
  }
}

// ============================================
// 辅助函数
// ============================================

function generateMockDailyStats(days: number) {
  const stats = []
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date()
    date.setDate(date.getDate() - i)
    stats.push({
      date: date.toISOString().split('T')[0],
      recommendations: Math.floor(Math.random() * 5000) + 3000,
      clicks: Math.floor(Math.random() * 800) + 400,
      conversions: Math.floor(Math.random() * 150) + 50
    })
  }
  return stats
}

export type { UseRecommendationManagementResult, RecommendationStats, RecommendationAnalytics, RecommendationFilters }