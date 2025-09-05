/**
 * 星趣后台管理系统 - 用户管理Hook
 * 提供用户批量操作和管理功能的React Hook
 * Created: 2025-09-05
 */

import { useState, useCallback, useRef } from 'react'
import { userService } from '../services/userService'
import type { 
  UserProfile, 
  UserFilters,
  UserStatistics,
  UserBatchUpdate,
  BatchOperation,
  UUID,
  UseBatchOperationsResult
} from '../types/admin'

interface UseUserManagementResult {
  // 用户数据
  users: UserProfile[]
  selectedUsers: UserProfile[]
  totalUsers: number
  totalPages: number
  currentPage: number
  statistics: UserStatistics | null
  
  // 状态
  loading: boolean
  error: string | null
  
  // 批量操作
  batchOperations: BatchOperation[]
  isProcessingBatch: boolean
  
  // 操作方法
  loadUsers: (filters?: UserFilters, page?: number, pageSize?: number) => Promise<void>
  searchUsers: (query: string) => Promise<UserProfile[]>
  getUserById: (userId: UUID) => Promise<UserProfile | null>
  loadStatistics: () => Promise<void>
  
  // 批量选择
  selectUser: (user: UserProfile) => void
  unselectUser: (userId: UUID) => void
  selectAllUsers: () => void
  clearSelection: () => void
  toggleUserSelection: (user: UserProfile) => void
  
  // 批量操作
  batchUpdate: (updates: UserBatchUpdate) => Promise<BatchOperation>
  batchDelete: (reason?: string) => Promise<BatchOperation>
  exportUsers: (filters?: UserFilters) => Promise<string>
  
  // 单用户操作
  banUser: (userId: UUID, reason: string, duration?: number) => Promise<void>
  unbanUser: (userId: UUID) => Promise<void>
  updateUserTags: (userId: UUID, tags: string[]) => Promise<void>
  resetUserPassword: (email: string) => Promise<void>
  
  // 工具方法
  refreshData: () => Promise<void>
  clearError: () => void
}

export function useUserManagement(): UseUserManagementResult {
  // 状态管理
  const [users, setUsers] = useState<UserProfile[]>([])
  const [selectedUsers, setSelectedUsers] = useState<UserProfile[]>([])
  const [totalUsers, setTotalUsers] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  const [statistics, setStatistics] = useState<UserStatistics | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [batchOperations, setBatchOperations] = useState<BatchOperation[]>([])
  const [isProcessingBatch, setIsProcessingBatch] = useState(false)

  // 引用管理
  const currentFiltersRef = useRef<UserFilters>({})
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

  const loadUsers = useCallback(async (
    filters: UserFilters = {}, 
    page = 1, 
    pageSize = 50
  ) => {
    setLoading(true)
    clearError()

    try {
      currentFiltersRef.current = filters
      currentPageSizeRef.current = pageSize

      const result = await userService.getUsers(filters, page, pageSize)
      
      setUsers(result.users)
      setTotalUsers(result.total)
      setTotalPages(result.totalPages)
      setCurrentPage(page)
    } catch (err) {
      handleError(err, '加载用户列表失败')
    } finally {
      setLoading(false)
    }
  }, [handleError, clearError])

  const searchUsers = useCallback(async (query: string): Promise<UserProfile[]> => {
    try {
      return await userService.searchUsers(query)
    } catch (err) {
      handleError(err, '搜索用户失败')
      return []
    }
  }, [handleError])

  const getUserById = useCallback(async (userId: UUID): Promise<UserProfile | null> => {
    try {
      return await userService.getUserById(userId)
    } catch (err) {
      handleError(err, '获取用户详情失败')
      return null
    }
  }, [handleError])

  const loadStatistics = useCallback(async () => {
    try {
      const stats = await userService.getUserStatistics()
      setStatistics(stats)
    } catch (err) {
      handleError(err, '加载用户统计失败')
    }
  }, [handleError])

  // ============================================
  // 批量选择方法
  // ============================================

  const selectUser = useCallback((user: UserProfile) => {
    setSelectedUsers(prev => {
      const exists = prev.find(u => u.id === user.id)
      return exists ? prev : [...prev, user]
    })
  }, [])

  const unselectUser = useCallback((userId: UUID) => {
    setSelectedUsers(prev => prev.filter(u => u.id !== userId))
  }, [])

  const selectAllUsers = useCallback(() => {
    setSelectedUsers([...users])
  }, [users])

  const clearSelection = useCallback(() => {
    setSelectedUsers([])
  }, [])

  const toggleUserSelection = useCallback((user: UserProfile) => {
    setSelectedUsers(prev => {
      const exists = prev.find(u => u.id === user.id)
      return exists 
        ? prev.filter(u => u.id !== user.id)
        : [...prev, user]
    })
  }, [])

  // ============================================
  // 批量操作方法
  // ============================================

  const batchUpdate = useCallback(async (updates: UserBatchUpdate): Promise<BatchOperation> => {
    if (selectedUsers.length === 0) {
      throw new Error('请先选择要更新的用户')
    }

    setIsProcessingBatch(true)

    try {
      const userIds = selectedUsers.map(u => u.id)
      const operation = await userService.batchUpdateUsers(userIds, updates)
      
      setBatchOperations(prev => [operation, ...prev.slice(0, 9)]) // 保持最近10个操作

      // 刷新当前页面数据
      await refreshData()
      clearSelection()

      return operation
    } catch (err) {
      handleError(err, '批量更新用户失败')
      throw err
    } finally {
      setIsProcessingBatch(false)
    }
  }, [selectedUsers, handleError])

  const batchDelete = useCallback(async (reason?: string): Promise<BatchOperation> => {
    if (selectedUsers.length === 0) {
      throw new Error('请先选择要删除的用户')
    }

    setIsProcessingBatch(true)

    try {
      const userIds = selectedUsers.map(u => u.id)
      const operation = await userService.batchDeleteUsers(userIds, reason)
      
      setBatchOperations(prev => [operation, ...prev.slice(0, 9)])

      // 刷新当前页面数据
      await refreshData()
      clearSelection()

      return operation
    } catch (err) {
      handleError(err, '批量删除用户失败')
      throw err
    } finally {
      setIsProcessingBatch(false)
    }
  }, [selectedUsers, handleError])

  const exportUsers = useCallback(async (filters?: UserFilters): Promise<string> => {
    try {
      const filtersToUse = filters || currentFiltersRef.current
      return await userService.exportUsers(filtersToUse)
    } catch (err) {
      handleError(err, '导出用户数据失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 单用户操作方法
  // ============================================

  const banUser = useCallback(async (userId: UUID, reason: string, duration?: number) => {
    try {
      await userService.banUser(userId, reason, duration)
      
      // 更新本地状态
      setUsers(prev => prev.map(user => 
        user.id === userId 
          ? { 
              ...user, 
              is_active: false, 
              banned_until: duration 
                ? new Date(Date.now() + duration * 24 * 60 * 60 * 1000).toISOString()
                : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
              ban_reason: reason
            }
          : user
      ))
    } catch (err) {
      handleError(err, '封禁用户失败')
      throw err
    }
  }, [handleError])

  const unbanUser = useCallback(async (userId: UUID) => {
    try {
      await userService.unbanUser(userId)
      
      // 更新本地状态
      setUsers(prev => prev.map(user => 
        user.id === userId 
          ? { ...user, is_active: true, banned_until: undefined, ban_reason: undefined }
          : user
      ))
    } catch (err) {
      handleError(err, '解封用户失败')
      throw err
    }
  }, [handleError])

  const updateUserTags = useCallback(async (userId: UUID, tags: string[]) => {
    try {
      await userService.updateUserTags(userId, tags)
      
      // 更新本地状态
      setUsers(prev => prev.map(user => 
        user.id === userId ? { ...user, tags } : user
      ))
    } catch (err) {
      handleError(err, '更新用户标签失败')
      throw err
    }
  }, [handleError])

  const resetUserPassword = useCallback(async (email: string) => {
    try {
      await userService.resetUserPassword(email)
    } catch (err) {
      handleError(err, '重置用户密码失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 工具方法
  // ============================================

  const refreshData = useCallback(async () => {
    await loadUsers(
      currentFiltersRef.current,
      currentPage,
      currentPageSizeRef.current
    )
  }, [loadUsers, currentPage])

  return {
    // 用户数据
    users,
    selectedUsers,
    totalUsers,
    totalPages,
    currentPage,
    statistics,
    
    // 状态
    loading,
    error,
    
    // 批量操作
    batchOperations,
    isProcessingBatch,
    
    // 操作方法
    loadUsers,
    searchUsers,
    getUserById,
    loadStatistics,
    
    // 批量选择
    selectUser,
    unselectUser,
    selectAllUsers,
    clearSelection,
    toggleUserSelection,
    
    // 批量操作
    batchUpdate,
    batchDelete,
    exportUsers,
    
    // 单用户操作
    banUser,
    unbanUser,
    updateUserTags,
    resetUserPassword,
    
    // 工具方法
    refreshData,
    clearError
  }
}

// 导出类型
export type { UseUserManagementResult }