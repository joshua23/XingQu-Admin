/**
 * 星趣后台管理系统 - 内容审核Hook
 * 提供内容审核管理功能的React Hook
 * Created: 2025-09-05
 */

import { useState, useCallback, useRef } from 'react'
import { moderationService } from '../services/moderationService'
import type { 
  ModerationRecord,
  ModerationRule,
  ContentReport,
  ModerationStatistics,
  ModerationFilters,
  ModerationRequest,
  ModerationResult,
  UUID
} from '../types/admin'

interface UseContentModerationResult {
  // 数据状态
  records: ModerationRecord[]
  rules: ModerationRule[]
  reports: ContentReport[]
  statistics: ModerationStatistics | null
  selectedRecords: ModerationRecord[]
  totalRecords: number
  totalPages: number
  currentPage: number
  
  // 加载状态
  loading: boolean
  submitting: boolean
  processing: boolean
  error: string | null
  
  // 数据操作
  loadRecords: (filters?: ModerationFilters, page?: number, pageSize?: number) => Promise<void>
  loadRules: () => Promise<void>
  loadReports: (filters?: any, page?: number, pageSize?: number) => Promise<void>
  loadStatistics: () => Promise<void>
  
  // 内容审核
  submitContent: (request: ModerationRequest) => Promise<ModerationResult>
  reviewContent: (recordId: UUID, decision: 'approved' | 'rejected', reason?: string) => Promise<void>
  batchReview: (decision: 'approved' | 'rejected', reason?: string) => Promise<void>
  
  // 规则管理
  createRule: (rule: Omit<ModerationRule, 'id' | 'created_at' | 'updated_at'>) => Promise<void>
  updateRule: (ruleId: UUID, updates: Partial<ModerationRule>) => Promise<void>
  deleteRule: (ruleId: UUID) => Promise<void>
  
  // 举报处理
  handleReport: (reportId: UUID, action: 'dismiss' | 'warn' | 'suspend' | 'ban', reason?: string) => Promise<void>
  
  // 选择管理
  selectRecord: (record: ModerationRecord) => void
  unselectRecord: (recordId: UUID) => void
  selectAllRecords: () => void
  clearSelection: () => void
  toggleRecordSelection: (record: ModerationRecord) => void
  
  // 数据导出
  exportData: (filters?: ModerationFilters) => Promise<string>
  
  // 工具方法
  refreshData: () => Promise<void>
  clearError: () => void
}

export function useContentModeration(): UseContentModerationResult {
  // 状态管理
  const [records, setRecords] = useState<ModerationRecord[]>([])
  const [rules, setRules] = useState<ModerationRule[]>([])
  const [reports, setReports] = useState<ContentReport[]>([])
  const [statistics, setStatistics] = useState<ModerationStatistics | null>(null)
  const [selectedRecords, setSelectedRecords] = useState<ModerationRecord[]>([])
  const [totalRecords, setTotalRecords] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  
  const [loading, setLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // 引用管理
  const currentFiltersRef = useRef<ModerationFilters>({})
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
  // 数据加载方法
  // ============================================

  const loadRecords = useCallback(async (
    filters: ModerationFilters = {},
    page = 1,
    pageSize = 50
  ) => {
    setLoading(true)
    clearError()

    try {
      currentFiltersRef.current = filters
      currentPageSizeRef.current = pageSize

      const result = await moderationService.getModerationRecords(filters, page, pageSize)
      
      setRecords(result.records)
      setTotalRecords(result.total)
      setTotalPages(result.totalPages)
      setCurrentPage(page)
    } catch (err) {
      handleError(err, '加载审核记录失败')
    } finally {
      setLoading(false)
    }
  }, [handleError, clearError])

  const loadRules = useCallback(async () => {
    try {
      const rulesList = await moderationService.getModerationRules()
      setRules(rulesList)
    } catch (err) {
      handleError(err, '加载审核规则失败')
    }
  }, [handleError])

  const loadReports = useCallback(async (
    filters: any = {},
    page = 1,
    pageSize = 50
  ) => {
    try {
      const result = await moderationService.getUserReports(filters, page, pageSize)
      setReports(result.reports)
    } catch (err) {
      handleError(err, '加载用户举报失败')
    }
  }, [handleError])

  const loadStatistics = useCallback(async () => {
    try {
      const stats = await moderationService.getModerationStatistics()
      setStatistics(stats)
    } catch (err) {
      handleError(err, '加载审核统计失败')
    }
  }, [handleError])

  // ============================================
  // 内容审核方法
  // ============================================

  const submitContent = useCallback(async (request: ModerationRequest): Promise<ModerationResult> => {
    setSubmitting(true)
    clearError()

    try {
      const result = await moderationService.submitForModeration(request)
      
      // 刷新记录列表
      await refreshData()
      
      return result
    } catch (err) {
      handleError(err, '提交内容审核失败')
      throw err
    } finally {
      setSubmitting(false)
    }
  }, [handleError, clearError])

  const reviewContent = useCallback(async (
    recordId: UUID,
    decision: 'approved' | 'rejected',
    reason?: string
  ) => {
    setProcessing(true)
    clearError()

    try {
      await moderationService.reviewContent(recordId, decision, reason)
      
      // 更新本地状态
      setRecords(prev => prev.map(record => 
        record.id === recordId
          ? { 
              ...record, 
              status: decision,
              human_decision: decision,
              reason,
              reviewed_at: new Date().toISOString()
            }
          : record
      ))
    } catch (err) {
      handleError(err, '审核处理失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const batchReview = useCallback(async (
    decision: 'approved' | 'rejected',
    reason?: string
  ) => {
    if (selectedRecords.length === 0) {
      throw new Error('请先选择要审核的记录')
    }

    setProcessing(true)
    clearError()

    try {
      const recordIds = selectedRecords.map(record => record.id)
      await moderationService.batchReview(recordIds, decision, reason)
      
      // 刷新数据并清空选择
      await refreshData()
      clearSelection()
    } catch (err) {
      handleError(err, '批量审核失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [selectedRecords, handleError, clearError])

  // ============================================
  // 规则管理方法
  // ============================================

  const createRule = useCallback(async (
    rule: Omit<ModerationRule, 'id' | 'created_at' | 'updated_at'>
  ) => {
    setProcessing(true)
    clearError()

    try {
      const newRule = await moderationService.createModerationRule(rule)
      setRules(prev => [newRule, ...prev])
    } catch (err) {
      handleError(err, '创建审核规则失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const updateRule = useCallback(async (
    ruleId: UUID,
    updates: Partial<ModerationRule>
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedRule = await moderationService.updateModerationRule(ruleId, updates)
      setRules(prev => prev.map(rule => 
        rule.id === ruleId ? updatedRule : rule
      ))
    } catch (err) {
      handleError(err, '更新审核规则失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const deleteRule = useCallback(async (ruleId: UUID) => {
    setProcessing(true)
    clearError()

    try {
      await moderationService.updateModerationRule(ruleId, { is_active: false })
      setRules(prev => prev.filter(rule => rule.id !== ruleId))
    } catch (err) {
      handleError(err, '删除审核规则失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  // ============================================
  // 举报处理方法
  // ============================================

  const handleReport = useCallback(async (
    reportId: UUID,
    action: 'dismiss' | 'warn' | 'suspend' | 'ban',
    reason?: string
  ) => {
    setProcessing(true)
    clearError()

    try {
      await moderationService.handleReport(reportId, action, reason)
      
      // 更新本地状态
      setReports(prev => prev.map(report => 
        report.id === reportId
          ? { 
              ...report, 
              status: 'resolved',
              resolution: action,
              resolution_reason: reason,
              resolved_at: new Date().toISOString()
            }
          : report
      ))
    } catch (err) {
      handleError(err, '处理举报失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  // ============================================
  // 选择管理方法
  // ============================================

  const selectRecord = useCallback((record: ModerationRecord) => {
    setSelectedRecords(prev => {
      const exists = prev.find(r => r.id === record.id)
      return exists ? prev : [...prev, record]
    })
  }, [])

  const unselectRecord = useCallback((recordId: UUID) => {
    setSelectedRecords(prev => prev.filter(r => r.id !== recordId))
  }, [])

  const selectAllRecords = useCallback(() => {
    setSelectedRecords([...records])
  }, [records])

  const clearSelection = useCallback(() => {
    setSelectedRecords([])
  }, [])

  const toggleRecordSelection = useCallback((record: ModerationRecord) => {
    setSelectedRecords(prev => {
      const exists = prev.find(r => r.id === record.id)
      return exists 
        ? prev.filter(r => r.id !== record.id)
        : [...prev, record]
    })
  }, [])

  // ============================================
  // 数据导出方法
  // ============================================

  const exportData = useCallback(async (filters?: ModerationFilters): Promise<string> => {
    try {
      const filtersToUse = filters || currentFiltersRef.current
      return await moderationService.exportModerationData(filtersToUse)
    } catch (err) {
      handleError(err, '导出审核数据失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 工具方法
  // ============================================

  const refreshData = useCallback(async () => {
    await loadRecords(
      currentFiltersRef.current,
      currentPage,
      currentPageSizeRef.current
    )
  }, [loadRecords, currentPage])

  return {
    // 数据状态
    records,
    rules,
    reports,
    statistics,
    selectedRecords,
    totalRecords,
    totalPages,
    currentPage,
    
    // 加载状态
    loading,
    submitting,
    processing,
    error,
    
    // 数据操作
    loadRecords,
    loadRules,
    loadReports,
    loadStatistics,
    
    // 内容审核
    submitContent,
    reviewContent,
    batchReview,
    
    // 规则管理
    createRule,
    updateRule,
    deleteRule,
    
    // 举报处理
    handleReport,
    
    // 选择管理
    selectRecord,
    unselectRecord,
    selectAllRecords,
    clearSelection,
    toggleRecordSelection,
    
    // 数据导出
    exportData,
    
    // 工具方法
    refreshData,
    clearError
  }
}

// 导出类型
export type { UseContentModerationResult }