/**
 * 星趣后台管理系统 - 素材管理Hook
 * 提供素材上传、管理和分析的React Hook
 * Created: 2025-09-05
 */

import { useState, useCallback, useRef, useEffect } from 'react'
import { 
  materialService, 
  type Material, 
  type MaterialCategory, 
  type MaterialStats, 
  type MaterialFilters, 
  type MaterialUpload,
  type MaterialUpdate,
  type BulkMaterialOperation,
  type UUID 
} from '../services/materialService'

interface UseMaterialManagementResult {
  // 数据状态
  materials: Material[]
  categories: MaterialCategory[]
  selectedMaterials: Material[]
  stats: MaterialStats | null
  totalMaterials: number
  totalPages: number
  currentPage: number
  
  // 加载状态
  loading: boolean
  uploading: boolean
  processing: boolean
  error: string | null
  
  // 素材管理
  loadMaterials: (filters?: MaterialFilters, page?: number, pageSize?: number) => Promise<void>
  uploadMaterial: (materialData: MaterialUpload) => Promise<void>
  updateMaterial: (materialId: UUID, updates: MaterialUpdate) => Promise<void>
  deleteMaterial: (materialId: UUID) => Promise<void>
  bulkOperateMaterials: (operation: BulkMaterialOperation) => Promise<void>
  
  // 分类管理
  loadCategories: () => Promise<void>
  createCategory: (categoryData: { name: string; description?: string }) => Promise<void>
  updateCategory: (categoryId: UUID, updates: Partial<MaterialCategory>) => Promise<void>
  deleteCategory: (categoryId: UUID) => Promise<void>
  
  // 统计分析
  loadStats: () => Promise<void>
  getUsageAnalytics: (materialId?: UUID) => Promise<any>
  
  // 选择管理
  selectMaterial: (material: Material) => void
  unselectMaterial: (materialId: UUID) => void
  selectAllMaterials: () => void
  clearSelection: () => void
  toggleMaterialSelection: (material: Material) => void
  
  // 文件处理
  uploadFile: (file: File, folder?: string) => Promise<string>
  deleteFile: (fileUrl: string) => Promise<void>
  
  // 数据导出
  exportMaterials: (filters?: MaterialFilters) => Promise<string>
  
  // 工具方法
  refreshData: () => Promise<void>
  clearError: () => void
}

export function useMaterialManagement(): UseMaterialManagementResult {
  // 数据状态
  const [materials, setMaterials] = useState<Material[]>([])
  const [categories, setCategories] = useState<MaterialCategory[]>([])
  const [selectedMaterials, setSelectedMaterials] = useState<Material[]>([])
  const [stats, setStats] = useState<MaterialStats | null>(null)
  const [totalMaterials, setTotalMaterials] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  
  // 加载状态
  const [loading, setLoading] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  // 引用管理
  const currentFiltersRef = useRef<MaterialFilters>({})
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
  // 素材管理方法
  // ============================================

  const loadMaterials = useCallback(async (
    filters: MaterialFilters = {},
    page = 1,
    pageSize = 50
  ) => {
    setLoading(true)
    clearError()

    try {
      currentFiltersRef.current = filters
      currentPageSizeRef.current = pageSize

      // 添加超时处理
      const timeout = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('素材数据加载超时')), 10000)
      )

      const result = await Promise.race([
        materialService.getMaterials(filters, page, pageSize),
        timeout
      ]) as Awaited<ReturnType<typeof materialService.getMaterials>>
      
      setMaterials(result.materials)
      setTotalMaterials(result.total)
      setTotalPages(result.totalPages)
      setCurrentPage(page)
    } catch (err) {
      handleError(err, '加载素材失败')
      // 确保即使出错也显示空状态而不是一直loading
      setMaterials([])
      setTotalMaterials(0)
      setTotalPages(0)
    } finally {
      setLoading(false)
    }
  }, [handleError, clearError])

  const uploadMaterial = useCallback(async (materialData: MaterialUpload) => {
    setUploading(true)
    clearError()

    try {
      const newMaterial = await materialService.uploadMaterial(materialData)
      setMaterials(prev => [newMaterial, ...prev])
      
      // 刷新统计数据
      await loadStats()
    } catch (err) {
      handleError(err, '素材上传失败')
      throw err
    } finally {
      setUploading(false)
    }
  }, [handleError, clearError])

  const updateMaterial = useCallback(async (
    materialId: UUID,
    updates: MaterialUpdate
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedMaterial = await materialService.updateMaterial(materialId, updates)
      
      setMaterials(prev => prev.map(material => 
        material.id === materialId ? updatedMaterial : material
      ))
      
      // 如果状态改变，刷新统计数据
      if (updates.is_active !== undefined) {
        await loadStats()
      }
    } catch (err) {
      handleError(err, '更新素材失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const deleteMaterial = useCallback(async (materialId: UUID) => {
    setProcessing(true)
    clearError()

    try {
      await materialService.deleteMaterial(materialId)
      
      setMaterials(prev => prev.filter(material => material.id !== materialId))
      setSelectedMaterials(prev => prev.filter(material => material.id !== materialId))
      
      // 刷新统计数据
      await loadStats()
    } catch (err) {
      handleError(err, '删除素材失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const bulkOperateMaterials = useCallback(async (operation: BulkMaterialOperation) => {
    if (selectedMaterials.length === 0 && operation.materialIds.length === 0) {
      throw new Error('请先选择要操作的素材')
    }

    setProcessing(true)
    clearError()

    try {
      const operationWithIds = {
        ...operation,
        materialIds: operation.materialIds.length > 0 
          ? operation.materialIds 
          : selectedMaterials.map(material => material.id)
      }

      const result = await materialService.bulkOperateMaterials(operationWithIds)
      
      // 刷新数据并清空选择
      await refreshData()
      clearSelection()
      
      // 如果有失败的操作，显示错误信息
      if (result.failed > 0) {
        const failedReasons = result.results
          .filter(r => !r.success)
          .map(r => r.error)
          .join(', ')
        handleError(new Error(`${result.failed} 个素材操作失败: ${failedReasons}`), '批量操作部分失败')
      }
    } catch (err) {
      handleError(err, '批量操作失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [selectedMaterials, handleError, clearError])

  // ============================================
  // 分类管理方法
  // ============================================

  const loadCategories = useCallback(async () => {
    try {
      const result = await materialService.getCategories()
      setCategories(result)
    } catch (err) {
      handleError(err, '加载分类失败')
    }
  }, [handleError])

  const createCategory = useCallback(async (categoryData: { name: string; description?: string }) => {
    setProcessing(true)
    clearError()

    try {
      const newCategory = await materialService.createCategory(categoryData)
      setCategories(prev => [...prev, newCategory])
    } catch (err) {
      handleError(err, '创建分类失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const updateCategory = useCallback(async (
    categoryId: UUID,
    updates: Partial<MaterialCategory>
  ) => {
    setProcessing(true)
    clearError()

    try {
      const updatedCategory = await materialService.updateCategory(categoryId, updates)
      setCategories(prev => prev.map(category => 
        category.id === categoryId ? updatedCategory : category
      ))
    } catch (err) {
      handleError(err, '更新分类失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  const deleteCategory = useCallback(async (categoryId: UUID) => {
    setProcessing(true)
    clearError()

    try {
      await materialService.deleteCategory(categoryId)
      setCategories(prev => prev.filter(category => category.id !== categoryId))
    } catch (err) {
      handleError(err, '删除分类失败')
      throw err
    } finally {
      setProcessing(false)
    }
  }, [handleError, clearError])

  // ============================================
  // 统计分析方法
  // ============================================

  const loadStats = useCallback(async () => {
    try {
      const result = await materialService.getMaterialStats()
      setStats(result)
    } catch (err) {
      handleError(err, '加载统计数据失败')
    }
  }, [handleError])

  const getUsageAnalytics = useCallback(async (materialId?: UUID) => {
    try {
      return await materialService.getUsageAnalytics(materialId)
    } catch (err) {
      handleError(err, '获取使用分析失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 选择管理方法
  // ============================================

  const selectMaterial = useCallback((material: Material) => {
    setSelectedMaterials(prev => {
      const exists = prev.find(m => m.id === material.id)
      return exists ? prev : [...prev, material]
    })
  }, [])

  const unselectMaterial = useCallback((materialId: UUID) => {
    setSelectedMaterials(prev => prev.filter(m => m.id !== materialId))
  }, [])

  const selectAllMaterials = useCallback(() => {
    setSelectedMaterials([...materials])
  }, [materials])

  const clearSelection = useCallback(() => {
    setSelectedMaterials([])
  }, [])

  const toggleMaterialSelection = useCallback((material: Material) => {
    setSelectedMaterials(prev => {
      const exists = prev.find(m => m.id === material.id)
      return exists 
        ? prev.filter(m => m.id !== material.id)
        : [...prev, material]
    })
  }, [])

  // ============================================
  // 文件处理方法
  // ============================================

  const uploadFile = useCallback(async (file: File, folder?: string): Promise<string> => {
    try {
      return await materialService.uploadFile(file, folder)
    } catch (err) {
      handleError(err, '文件上传失败')
      throw err
    }
  }, [handleError])

  const deleteFile = useCallback(async (fileUrl: string) => {
    try {
      await materialService.deleteFile(fileUrl)
    } catch (err) {
      handleError(err, '文件删除失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 数据导出方法
  // ============================================

  const exportMaterials = useCallback(async (filters?: MaterialFilters): Promise<string> => {
    try {
      const filtersToUse = filters || currentFiltersRef.current
      return await materialService.exportMaterials(filtersToUse)
    } catch (err) {
      handleError(err, '导出素材数据失败')
      throw err
    }
  }, [handleError])

  // ============================================
  // 工具方法
  // ============================================

  const refreshData = useCallback(async () => {
    await Promise.all([
      loadMaterials(
        currentFiltersRef.current,
        currentPage,
        currentPageSizeRef.current
      ),
      loadCategories(),
      loadStats()
    ])
  }, [loadMaterials, loadCategories, loadStats, currentPage])

  // ============================================
  // 生命周期管理
  // ============================================

  useEffect(() => {
    // 组件挂载时自动加载基础数据
    const initLoad = async () => {
      await Promise.all([
        loadMaterials(),
        loadCategories(),
        loadStats()
      ])
    }
    
    initLoad()
  }, [loadMaterials, loadCategories, loadStats])

  return {
    // 数据状态
    materials,
    categories,
    selectedMaterials,
    stats,
    totalMaterials,
    totalPages,
    currentPage,
    
    // 加载状态
    loading,
    uploading,
    processing,
    error,
    
    // 素材管理
    loadMaterials,
    uploadMaterial,
    updateMaterial,
    deleteMaterial,
    bulkOperateMaterials,
    
    // 分类管理
    loadCategories,
    createCategory,
    updateCategory,
    deleteCategory,
    
    // 统计分析
    loadStats,
    getUsageAnalytics,
    
    // 选择管理
    selectMaterial,
    unselectMaterial,
    selectAllMaterials,
    clearSelection,
    toggleMaterialSelection,
    
    // 文件处理
    uploadFile,
    deleteFile,
    
    // 数据导出
    exportMaterials,
    
    // 工具方法
    refreshData,
    clearError
  }
}

export type { UseMaterialManagementResult }