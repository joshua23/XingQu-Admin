/**
 * 星趣后台管理系统 - 订阅管理Hook
 * 提供订阅计划管理和用户订阅操作功能的React Hook
 * Created: 2025-09-05
 */

import { useState, useCallback, useRef } from 'react'
import { subscriptionService } from '../services/subscriptionService'
import type { 
  SubscriptionPlan,
  UserSubscription,
  SubscriptionStatistics,
  SubscriptionFilters,
  UUID,
  SubscriptionPlanCreate,
  SubscriptionUpdate,
  BulkSubscriptionOperation
} from '../types/admin'

interface UseSubscriptionManagementResult {
  // 数据状态
  plans: SubscriptionPlan[]
  subscriptions: UserSubscription[]
  selectedSubscriptions: UserSubscription[]
  statistics: SubscriptionStatistics | null
  totalSubscriptions: number
  totalPages: number
  currentPage: number
  
  // 加载状态
  loading: boolean
  processing: boolean
  error: string | null
  
  // 计划管理
  loadPlans: (activeOnly?: boolean) => Promise<void>
  createPlan: (plan: SubscriptionPlanCreate) => Promise<void>
  updatePlan: (planId: UUID, updates: Partial<SubscriptionPlanCreate>) => Promise<void>
  deletePlan: (planId: UUID) => Promise<void>
  
  // 订阅管理
  loadSubscriptions: (filters?: SubscriptionFilters, page?: number, pageSize?: number) => Promise<void>
  createSubscription: (userId: UUID, planId: UUID, duration?: { months?: number; days?: number }) => Promise<void>
  updateSubscription: (subscriptionId: UUID, updates: SubscriptionUpdate) => Promise<void>
  bulkOperate: (operation: BulkSubscriptionOperation) => Promise<void>
  
  // 统计数据
  loadStatistics: () => Promise<void>
  
  // 选择管理
  selectSubscription: (subscription: UserSubscription) => void
  unselectSubscription: (subscriptionId: UUID) => void
  selectAllSubscriptions: () => void
  clearSelection: () => void
  toggleSubscriptionSelection: (subscription: UserSubscription) => void
  
  // 数据导出
  exportData: (filters?: SubscriptionFilters) => Promise<string>
  
  // 工具方法
  refreshData: () => Promise<void>
  clearError: () => void
}

export function useSubscriptionManagement(): UseSubscriptionManagementResult {
  // 状态管理
  const [plans, setPlans] = useState<SubscriptionPlan[]>([])
  const [subscriptions, setSubscriptions] = useState<UserSubscription[]>([])
  const [selectedSubscriptions, setSelectedSubscriptions] = useState<UserSubscription[]>([])
  const [statistics, setStatistics] = useState<SubscriptionStatistics | null>(null)
  const [totalSubscriptions, setTotalSubscriptions] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  
  const [loading, setLoading] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // 引用管理
  const currentFiltersRef = useRef<SubscriptionFilters>({})
  const currentPageSizeRef = useRef(50)

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
  // 计划管理方法
  // ============================================

  const loadPlans = useCallback(async (activeOnly = false) => {
    try {
      const plansList = await subscriptionService.getSubscriptionPlans(activeOnly)
      setPlans(plansList)
    } catch (err) {
      handleError(err, '加载订阅计划失败')
    }
  }, [handleError])

  const createPlan = useCallback(async (plan: SubscriptionPlanCreate) => {
    setProcessing(true)
    clearError()

    try {
      const newPlan = await subscriptionService.createSubscriptionPlan(plan)
      setPlans(prev => [newPlan, ...prev])
    } catch (err) {
      handleError(err, '创建订阅计划失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const updatePlan = useCallback(async (
    planId: UUID,
    updates: Partial<SubscriptionPlanCreate>
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedPlan = await subscriptionService.updateSubscriptionPlan(planId, updates)
      setPlans(prev => prev.map(plan => 
        plan.id === planId ? updatedPlan : plan
      ))
    } catch (err) {
      handleError(err, '更新订阅计划失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const deletePlan = useCallback(async (planId: UUID) => {
    setProcessing(true)
    clearError()

    try {
      await subscriptionService.deleteSubscriptionPlan(planId)
      setPlans(prev => prev.filter(plan => plan.id !== planId))
    } catch (err) {
      handleError(err, '删除订阅计划失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  // ============================================
  // 订阅管理方法
  // ============================================

  const loadSubscriptions = useCallback(async (
    filters: SubscriptionFilters = {},
    page = 1,
    pageSize = 50
  ) => {
    setLoading(true)
    clearError()

    try {
      currentFiltersRef.current = filters
      currentPageSizeRef.current = pageSize

      const result = await subscriptionService.getUserSubscriptions(filters, page, pageSize)
      
      setSubscriptions(result.subscriptions)
      setTotalSubscriptions(result.total)
      setTotalPages(result.totalPages)
      setCurrentPage(page)
    } catch (err) {
      handleError(err, '加载用户订阅失败')
    } finally {
      setLoading(false)
    }
  }, [handleError, clearError])

  const createSubscription = useCallback(async (
    userId: UUID,
    planId: UUID,
    duration?: { months?: number; days?: number }
  ) => {
    setProcessing(true)
    clearError()

    try {
      const newSubscription = await subscriptionService.createUserSubscription(
        userId,
        planId,
        duration
      )
      
      setSubscriptions(prev => [newSubscription, ...prev])
      // 刷新统计数据
      await loadStatistics()
    } catch (err) {
      handleError(err, '创建用户订阅失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const updateSubscription = useCallback(async (
    subscriptionId: UUID,
    updates: SubscriptionUpdate
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedSubscription = await subscriptionService.updateUserSubscription(
        subscriptionId,
        updates
      )
      
      setSubscriptions(prev => prev.map(sub => 
        sub.id === subscriptionId ? updatedSubscription : sub
      ))
    } catch (err) {
      handleError(err, '更新用户订阅失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const bulkOperate = useCallback(async (operation: BulkSubscriptionOperation) => {
    if (selectedSubscriptions.length === 0) {
      throw new Error('请先选择要操作的订阅')
    }

    setProcessing(true)
    clearError()

    try {
      const operationWithIds = {
        ...operation,
        subscriptionIds: operation.subscriptionIds.length > 0 
          ? operation.subscriptionIds 
          : selectedSubscriptions.map(sub => sub.id)
      }

      const result = await subscriptionService.bulkOperateSubscriptions(operationWithIds)
      
      // 刷新数据并清空选择
      await refreshData()
      clearSelection()
      
      // 如果有失败的操作，显示错误信息
      if (result.failed > 0) {
        const failedReasons = result.results
          .filter(r => !r.success)
          .map(r => r.error)
          .join(', ')
        handleError(new Error(`${result.failed} 个订阅操作失败: ${failedReasons}`), '批量操作部分失败')
      }
    } catch (err) {
      handleError(err, '批量操作失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [selectedSubscriptions, handleError, clearError])

  // ============================================
  // 统计数据方法
  // ============================================

  const loadStatistics = useCallback(async () => {
    try {
      const stats = await subscriptionService.getSubscriptionStatistics()
      setStatistics(stats)
    } catch (err) {
      handleError(err, '加载订阅统计失败')
    }
  }, [handleError])

  // ============================================
  // 选择管理方法
  // ============================================

  const selectSubscription = useCallback((subscription: UserSubscription) => {
    setSelectedSubscriptions(prev => {
      const exists = prev.find(s => s.id === subscription.id)
      return exists ? prev : [...prev, subscription]
    })
  }, [])

  const unselectSubscription = useCallback((subscriptionId: UUID) => {
    setSelectedSubscriptions(prev => prev.filter(s => s.id !== subscriptionId))
  }, [])

  const selectAllSubscriptions = useCallback(() => {
    setSelectedSubscriptions([...subscriptions])
  }, [subscriptions])

  const clearSelection = useCallback(() => {
    setSelectedSubscriptions([])
  }, [])

  const toggleSubscriptionSelection = useCallback((subscription: UserSubscription) => {
    setSelectedSubscriptions(prev => {
      const exists = prev.find(s => s.id === subscription.id)
      return exists 
        ? prev.filter(s => s.id !== subscription.id)
        : [...prev, subscription]
    })
  }, [])

  // ============================================
  // 数据导出方法
  // ============================================

  const exportData = useCallback(async (filters?: SubscriptionFilters): Promise<string> => {
    try {
      const filtersToUse = filters || currentFiltersRef.current
      return await subscriptionService.exportSubscriptionData(filtersToUse)
    } catch (err) {
      handleError(err, '导出订阅数据失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 工具方法
  // ============================================

  const refreshData = useCallback(async () => {
    await Promise.all([
      loadSubscriptions(
        currentFiltersRef.current,
        currentPage,
        currentPageSizeRef.current
      ),
      loadPlans(),
      loadStatistics()
    ])
  }, [loadSubscriptions, loadPlans, loadStatistics, currentPage])

  return {
    // 数据状态
    plans,
    subscriptions,
    selectedSubscriptions,
    statistics,
    totalSubscriptions,
    totalPages,
    currentPage,
    
    // 加载状态
    loading,
    processing,
    error,
    
    // 计划管理
    loadPlans,
    createPlan,
    updatePlan,
    deletePlan,
    
    // 订阅管理
    loadSubscriptions,
    createSubscription,
    updateSubscription,
    bulkOperate,
    
    // 统计数据
    loadStatistics,
    
    // 选择管理
    selectSubscription,
    unselectSubscription,
    selectAllSubscriptions,
    clearSelection,
    toggleSubscriptionSelection,
    
    // 数据导出
    exportData,
    
    // 工具方法
    refreshData,
    clearError
  }
}

// 导出类型
export type { UseSubscriptionManagementResult }