/**
 * 星趣后台管理系统 - 支付订单管理Hook
 * 提供支付订单处理、退款管理功能的React Hook
 * Created: 2025-09-05
 */

import { useState, useCallback, useRef } from 'react'
import { paymentService } from '../services/paymentService'
import type { 
  PaymentOrder,
  PaymentStatistics,
  RefundRequest,
  PaymentFilters,
  PaymentOrderCreate,
  PaymentUpdate,
  BulkPaymentOperation,
  UUID
} from '../types/admin'

interface UsePaymentManagementResult {
  // 数据状态
  orders: PaymentOrder[]
  refunds: RefundRequest[]
  selectedOrders: PaymentOrder[]
  statistics: PaymentStatistics | null
  totalOrders: number
  totalPages: number
  currentPage: number
  
  // 加载状态
  loading: boolean
  processing: boolean
  error: string | null
  
  // 订单管理
  loadOrders: (filters?: PaymentFilters, page?: number, pageSize?: number) => Promise<void>
  createOrder: (orderData: PaymentOrderCreate) => Promise<void>
  updateOrder: (orderId: UUID, updates: PaymentUpdate) => Promise<void>
  bulkOperate: (operation: BulkPaymentOperation) => Promise<void>
  
  // 退款管理
  loadRefunds: (filters?: any, page?: number, pageSize?: number) => Promise<void>
  processRefund: (orderId: UUID, refundData: { refund_reason?: string; refund_amount?: number }) => Promise<void>
  
  // 统计数据
  loadStatistics: () => Promise<void>
  
  // 选择管理
  selectOrder: (order: PaymentOrder) => void
  unselectOrder: (orderId: UUID) => void
  selectAllOrders: () => void
  clearSelection: () => void
  toggleOrderSelection: (order: PaymentOrder) => void
  
  // 数据导出
  exportData: (filters?: PaymentFilters) => Promise<string>
  
  // 工具方法
  refreshData: () => Promise<void>
  clearError: () => void
}

export function usePaymentManagement(): UsePaymentManagementResult {
  // 状态管理
  const [orders, setOrders] = useState<PaymentOrder[]>([])
  const [refunds, setRefunds] = useState<RefundRequest[]>([])
  const [selectedOrders, setSelectedOrders] = useState<PaymentOrder[]>([])
  const [statistics, setStatistics] = useState<PaymentStatistics | null>(null)
  const [totalOrders, setTotalOrders] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  
  const [loading, setLoading] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // 引用管理
  const currentFiltersRef = useRef<PaymentFilters>({})
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
  // 订单管理方法
  // ============================================

  const loadOrders = useCallback(async (
    filters: PaymentFilters = {},
    page = 1,
    pageSize = 50
  ) => {
    setLoading(true)
    clearError()

    try {
      currentFiltersRef.current = filters
      currentPageSizeRef.current = pageSize

      const result = await paymentService.getPaymentOrders(filters, page, pageSize)
      
      setOrders(result.orders)
      setTotalOrders(result.total)
      setTotalPages(result.totalPages)
      setCurrentPage(page)
    } catch (err) {
      handleError(err, '加载支付订单失败')
    } finally {
      setLoading(false)
    }
  }, [handleError, clearError])

  const createOrder = useCallback(async (orderData: PaymentOrderCreate) => {
    setProcessing(true)
    clearError()

    try {
      const newOrder = await paymentService.createPaymentOrder(orderData)
      setOrders(prev => [newOrder, ...prev])
      
      // 刷新统计数据
      await loadStatistics()
    } catch (err) {
      handleError(err, '创建支付订单失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const updateOrder = useCallback(async (
    orderId: UUID,
    updates: PaymentUpdate
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedOrder = await paymentService.updatePaymentOrder(orderId, updates)
      
      setOrders(prev => prev.map(order => 
        order.id === orderId ? updatedOrder : order
      ))
      
      // 如果订单状态改变，刷新统计数据
      if (updates.status) {
        await loadStatistics()
      }
    } catch (err) {
      handleError(err, '更新支付订单失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const bulkOperate = useCallback(async (operation: BulkPaymentOperation) => {
    if (selectedOrders.length === 0) {
      throw new Error('请先选择要操作的订单')
    }

    setProcessing(true)
    clearError()

    try {
      const operationWithIds = {
        ...operation,
        orderIds: operation.orderIds.length > 0 
          ? operation.orderIds 
          : selectedOrders.map(order => order.id)
      }

      const result = await paymentService.bulkOperateOrders(operationWithIds)
      
      // 刷新数据并清空选择
      await refreshData()
      clearSelection()
      
      // 如果有失败的操作，显示错误信息
      if (result.failed > 0) {
        const failedReasons = result.results
          .filter(r => !r.success)
          .map(r => r.error)
          .join(', ')
        handleError(new Error(`${result.failed} 个订单操作失败: ${failedReasons}`), '批量操作部分失败')
      }
    } catch (err) {
      handleError(err, '批量操作失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [selectedOrders, handleError, clearError])

  // ============================================
  // 退款管理方法
  // ============================================

  const loadRefunds = useCallback(async (
    filters: any = {},
    page = 1,
    pageSize = 50
  ) => {
    try {
      const result = await paymentService.getRefundRequests(filters, page, pageSize)
      setRefunds(result.refunds)
    } catch (err) {
      handleError(err, '加载退款记录失败')
    }
  }, [handleError])

  const processRefund = useCallback(async (
    orderId: UUID,
    refundData: { refund_reason?: string; refund_amount?: number }
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedOrder = await paymentService.processRefund(orderId, refundData)
      
      setOrders(prev => prev.map(order => 
        order.id === orderId ? updatedOrder : order
      ))
      
      // 刷新退款记录和统计数据
      await Promise.all([loadRefunds(), loadStatistics()])
    } catch (err) {
      handleError(err, '处理退款失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError, loadRefunds])

  // ============================================
  // 统计数据方法
  // ============================================

  const loadStatistics = useCallback(async () => {
    try {
      const stats = await paymentService.getPaymentStatistics()
      setStatistics(stats)
    } catch (err) {
      handleError(err, '加载支付统计失败')
    }
  }, [handleError])

  // ============================================
  // 选择管理方法
  // ============================================

  const selectOrder = useCallback((order: PaymentOrder) => {
    setSelectedOrders(prev => {
      const exists = prev.find(o => o.id === order.id)
      return exists ? prev : [...prev, order]
    })
  }, [])

  const unselectOrder = useCallback((orderId: UUID) => {
    setSelectedOrders(prev => prev.filter(o => o.id !== orderId))
  }, [])

  const selectAllOrders = useCallback(() => {
    setSelectedOrders([...orders])
  }, [orders])

  const clearSelection = useCallback(() => {
    setSelectedOrders([])
  }, [])

  const toggleOrderSelection = useCallback((order: PaymentOrder) => {
    setSelectedOrders(prev => {
      const exists = prev.find(o => o.id === order.id)
      return exists 
        ? prev.filter(o => o.id !== order.id)
        : [...prev, order]
    })
  }, [])

  // ============================================
  // 数据导出方法
  // ============================================

  const exportData = useCallback(async (filters?: PaymentFilters): Promise<string> => {
    try {
      const filtersToUse = filters || currentFiltersRef.current
      return await paymentService.exportPaymentData(filtersToUse)
    } catch (err) {
      handleError(err, '导出支付数据失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 工具方法
  // ============================================

  const refreshData = useCallback(async () => {
    await Promise.all([
      loadOrders(
        currentFiltersRef.current,
        currentPage,
        currentPageSizeRef.current
      ),
      loadStatistics()
    ])
  }, [loadOrders, loadStatistics, currentPage])

  return {
    // 数据状态
    orders,
    refunds,
    selectedOrders,
    statistics,
    totalOrders,
    totalPages,
    currentPage,
    
    // 加载状态
    loading,
    processing,
    error,
    
    // 订单管理
    loadOrders,
    createOrder,
    updateOrder,
    bulkOperate,
    
    // 退款管理
    loadRefunds,
    processRefund,
    
    // 统计数据
    loadStatistics,
    
    // 选择管理
    selectOrder,
    unselectOrder,
    selectAllOrders,
    clearSelection,
    toggleOrderSelection,
    
    // 数据导出
    exportData,
    
    // 工具方法
    refreshData,
    clearError
  }
}

// 导出类型
export type { UsePaymentManagementResult }