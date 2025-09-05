/**
 * 星趣后台管理系统 - 素材管理服务
 * 提供音频素材管理、存储和分析的核心服务
 * Created: 2025-09-05
 */

import { dataService } from './supabase'
import type { UUID } from '../types/admin'

export interface Material {
  id: UUID
  title: string
  description?: string
  file_url: string
  file_name: string
  file_size: number
  file_type: string
  duration?: number
  category: string
  tags: string[]
  creator_id: UUID
  created_at: string
  updated_at: string
  is_active: boolean
  usage_count: number
  rating_average?: number
  thumbnail_url?: string
}

export interface MaterialCategory {
  id: UUID
  name: string
  description?: string
  material_count: number
  created_at: string
  is_active: boolean
}

export interface MaterialUpload {
  title: string
  description?: string
  category: string
  tags: string[]
  file: File
}

export interface MaterialUpdate {
  title?: string
  description?: string
  category?: string
  tags?: string[]
  is_active?: boolean
}

export interface MaterialFilters {
  category?: string
  tags?: string[]
  creator_id?: UUID
  is_active?: boolean
  file_type?: string
  search?: string
  date_range?: {
    start: string
    end: string
  }
}

export interface MaterialStats {
  total_materials: number
  active_materials: number
  total_size_mb: number
  categories: MaterialCategory[]
  popular_tags: Array<{ tag: string; count: number }>
  file_type_distribution: Array<{ type: string; count: number; size_mb: number }>
  upload_trends: Array<{ date: string; count: number; size_mb: number }>
}

export interface BulkMaterialOperation {
  materialIds: UUID[]
  action: 'activate' | 'deactivate' | 'delete' | 'update_category' | 'add_tags' | 'remove_tags'
  data?: {
    category?: string
    tags?: string[]
    is_active?: boolean
  }
}

interface MaterialServiceInterface {
  // 素材管理
  getMaterials(filters?: MaterialFilters, page?: number, pageSize?: number): Promise<{
    materials: Material[]
    total: number
    totalPages: number
  }>
  getMaterialById(materialId: UUID): Promise<Material>
  uploadMaterial(materialData: MaterialUpload): Promise<Material>
  updateMaterial(materialId: UUID, updates: MaterialUpdate): Promise<Material>
  deleteMaterial(materialId: UUID): Promise<void>
  bulkOperateMaterials(operation: BulkMaterialOperation): Promise<{
    success: number
    failed: number
    results: Array<{ id: UUID; success: boolean; error?: string }>
  }>
  
  // 分类管理
  getCategories(): Promise<MaterialCategory[]>
  createCategory(categoryData: { name: string; description?: string }): Promise<MaterialCategory>
  updateCategory(categoryId: UUID, updates: Partial<MaterialCategory>): Promise<MaterialCategory>
  deleteCategory(categoryId: UUID): Promise<void>
  
  // 统计分析
  getMaterialStats(): Promise<MaterialStats>
  getUsageAnalytics(materialId?: UUID): Promise<any>
  
  // 文件管理
  uploadFile(file: File, folder?: string): Promise<string>
  deleteFile(fileUrl: string): Promise<void>
  generateThumbnail(fileUrl: string): Promise<string>
  
  // 数据导出
  exportMaterials(filters?: MaterialFilters): Promise<string>
}

class MaterialService implements MaterialServiceInterface {
  private static instance: MaterialService

  public static getInstance(): MaterialService {
    if (!MaterialService.instance) {
      MaterialService.instance = new MaterialService()
    }
    return MaterialService.instance
  }

  private constructor() {}

  // ============================================
  // 素材管理方法
  // ============================================

  async getMaterials(
    filters: MaterialFilters = {}, 
    page = 1, 
    pageSize = 50
  ): Promise<{ materials: Material[]; total: number; totalPages: number }> {
    try {
      let query = dataService.supabase
        .from('xq_materials')
        .select('*', { count: 'exact' })

      // 应用过滤条件
      if (filters.category) {
        query = query.eq('category', filters.category)
      }
      if (filters.creator_id) {
        query = query.eq('creator_id', filters.creator_id)
      }
      if (filters.is_active !== undefined) {
        query = query.eq('is_active', filters.is_active)
      }
      if (filters.file_type) {
        query = query.eq('file_type', filters.file_type)
      }
      if (filters.search) {
        query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
      }
      if (filters.tags && filters.tags.length > 0) {
        query = query.contains('tags', filters.tags)
      }
      if (filters.date_range) {
        query = query
          .gte('created_at', filters.date_range.start)
          .lte('created_at', filters.date_range.end)
      }

      // 分页和排序
      const offset = (page - 1) * pageSize
      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + pageSize - 1)

      const { data, error, count } = await query

      if (error) throw error

      const totalPages = Math.ceil((count || 0) / pageSize)

      return {
        materials: data || [],
        total: count || 0,
        totalPages
      }
    } catch (error) {
      console.error('获取素材列表失败:', error)
      throw error
    }
  }

  async getMaterialById(materialId: UUID): Promise<Material> {
    const { data, error } = await dataService.supabase
      .from('xq_materials')
      .select('*')
      .eq('id', materialId)
      .single()

    if (error) throw error
    return data
  }

  async uploadMaterial(materialData: MaterialUpload): Promise<Material> {
    try {
      // 1. 上传文件
      const fileUrl = await this.uploadFile(materialData.file, 'materials')
      
      // 2. 生成缩略图(如果是视频或图片)
      let thumbnailUrl: string | undefined
      if (materialData.file.type.startsWith('video/') || materialData.file.type.startsWith('image/')) {
        try {
          thumbnailUrl = await this.generateThumbnail(fileUrl)
        } catch (error) {
          console.warn('缩略图生成失败:', error)
        }
      }

      // 3. 获取文件信息
      const duration = materialData.file.type.startsWith('audio/') ? 
        await this.getAudioDuration(materialData.file) : undefined

      // 4. 保存到数据库
      const { data, error } = await dataService.supabase
        .from('xq_materials')
        .insert({
          title: materialData.title,
          description: materialData.description,
          file_url: fileUrl,
          file_name: materialData.file.name,
          file_size: materialData.file.size,
          file_type: materialData.file.type,
          duration: duration,
          category: materialData.category,
          tags: materialData.tags,
          creator_id: (await dataService.getCurrentUser())?.id,
          thumbnail_url: thumbnailUrl,
          is_active: true,
          usage_count: 0
        })
        .select()
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('素材上传失败:', error)
      throw error
    }
  }

  async updateMaterial(materialId: UUID, updates: MaterialUpdate): Promise<Material> {
    const { data, error } = await dataService.supabase
      .from('xq_materials')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', materialId)
      .select()
      .single()

    if (error) throw error
    return data
  }

  async deleteMaterial(materialId: UUID): Promise<void> {
    // 1. 获取素材信息
    const material = await this.getMaterialById(materialId)
    
    // 2. 删除文件
    await this.deleteFile(material.file_url)
    if (material.thumbnail_url) {
      await this.deleteFile(material.thumbnail_url)
    }
    
    // 3. 删除数据库记录
    const { error } = await dataService.supabase
      .from('xq_materials')
      .delete()
      .eq('id', materialId)

    if (error) throw error
  }

  async bulkOperateMaterials(operation: BulkMaterialOperation): Promise<{
    success: number
    failed: number
    results: Array<{ id: UUID; success: boolean; error?: string }>
  }> {
    const results = []
    let success = 0
    let failed = 0

    for (const materialId of operation.materialIds) {
      try {
        switch (operation.action) {
          case 'activate':
            await this.updateMaterial(materialId, { is_active: true })
            break
          case 'deactivate':
            await this.updateMaterial(materialId, { is_active: false })
            break
          case 'delete':
            await this.deleteMaterial(materialId)
            break
          case 'update_category':
            if (operation.data?.category) {
              await this.updateMaterial(materialId, { category: operation.data.category })
            }
            break
          case 'add_tags':
            if (operation.data?.tags) {
              const material = await this.getMaterialById(materialId)
              const newTags = [...new Set([...material.tags, ...operation.data.tags])]
              await this.updateMaterial(materialId, { tags: newTags })
            }
            break
          case 'remove_tags':
            if (operation.data?.tags) {
              const material = await this.getMaterialById(materialId)
              const newTags = material.tags.filter(tag => !operation.data!.tags!.includes(tag))
              await this.updateMaterial(materialId, { tags: newTags })
            }
            break
        }
        
        results.push({ id: materialId, success: true })
        success++
      } catch (error) {
        results.push({ 
          id: materialId, 
          success: false, 
          error: error instanceof Error ? error.message : '操作失败' 
        })
        failed++
      }
    }

    return { success, failed, results }
  }

  // ============================================
  // 分类管理方法
  // ============================================

  async getCategories(): Promise<MaterialCategory[]> {
    const { data, error } = await dataService.supabase
      .from('xq_material_categories')
      .select('*')
      .order('name')

    if (error) throw error
    return data || []
  }

  async createCategory(categoryData: { name: string; description?: string }): Promise<MaterialCategory> {
    const { data, error } = await dataService.supabase
      .from('xq_material_categories')
      .insert({
        ...categoryData,
        material_count: 0,
        is_active: true
      })
      .select()
      .single()

    if (error) throw error
    return data
  }

  async updateCategory(categoryId: UUID, updates: Partial<MaterialCategory>): Promise<MaterialCategory> {
    const { data, error } = await dataService.supabase
      .from('xq_material_categories')
      .update(updates)
      .eq('id', categoryId)
      .select()
      .single()

    if (error) throw error
    return data
  }

  async deleteCategory(categoryId: UUID): Promise<void> {
    const { error } = await dataService.supabase
      .from('xq_material_categories')
      .delete()
      .eq('id', categoryId)

    if (error) throw error
  }

  // ============================================
  // 统计分析方法
  // ============================================

  async getMaterialStats(): Promise<MaterialStats> {
    try {
      // 获取素材统计
      const { data: materials, error: materialError } = await dataService.supabase
        .from('xq_materials')
        .select('id, file_size, file_type, tags, category, created_at, is_active')

      if (materialError) throw materialError

      const totalMaterials = materials?.length || 0
      const activeMaterials = materials?.filter(m => m.is_active).length || 0
      const totalSizeMb = Math.round((materials?.reduce((sum, m) => sum + m.file_size, 0) || 0) / (1024 * 1024))

      // 获取分类统计
      const categories = await this.getCategories()

      // 统计标签
      const tagCount = new Map<string, number>()
      materials?.forEach(material => {
        material.tags?.forEach(tag => {
          tagCount.set(tag, (tagCount.get(tag) || 0) + 1)
        })
      })

      const popularTags = Array.from(tagCount.entries())
        .map(([tag, count]) => ({ tag, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 20)

      // 统计文件类型
      const typeCount = new Map<string, { count: number; size: number }>()
      materials?.forEach(material => {
        const type = material.file_type.split('/')[0] // 取主类型
        const existing = typeCount.get(type) || { count: 0, size: 0 }
        typeCount.set(type, {
          count: existing.count + 1,
          size: existing.size + material.file_size
        })
      })

      const fileTypeDistribution = Array.from(typeCount.entries())
        .map(([type, data]) => ({
          type,
          count: data.count,
          size_mb: Math.round(data.size / (1024 * 1024))
        }))

      // 生成上传趋势（模拟）
      const uploadTrends = this.generateUploadTrends(30)

      return {
        total_materials: totalMaterials,
        active_materials: activeMaterials,
        total_size_mb: totalSizeMb,
        categories: categories,
        popular_tags: popularTags,
        file_type_distribution: fileTypeDistribution,
        upload_trends: uploadTrends
      }
    } catch (error) {
      console.error('获取素材统计失败:', error)
      throw error
    }
  }

  async getUsageAnalytics(materialId?: UUID): Promise<any> {
    // 模拟使用分析数据
    return {
      total_usage: 1250,
      unique_users: 320,
      average_rating: 4.3,
      usage_by_day: this.generateUsageTrends(30)
    }
  }

  // ============================================
  // 文件管理方法
  // ============================================

  async uploadFile(file: File, folder = 'materials'): Promise<string> {
    try {
      const fileName = `${folder}/${Date.now()}_${file.name}`
      
      const { data, error } = await dataService.supabase.storage
        .from('materials')
        .upload(fileName, file)

      if (error) throw error

      const { data: urlData } = dataService.supabase.storage
        .from('materials')
        .getPublicUrl(fileName)

      return urlData.publicUrl
    } catch (error) {
      console.error('文件上传失败:', error)
      throw error
    }
  }

  async deleteFile(fileUrl: string): Promise<void> {
    try {
      const fileName = fileUrl.split('/').pop()
      if (!fileName) return

      const { error } = await dataService.supabase.storage
        .from('materials')
        .remove([fileName])

      if (error) throw error
    } catch (error) {
      console.error('文件删除失败:', error)
      throw error
    }
  }

  async generateThumbnail(fileUrl: string): Promise<string> {
    // 这里应该集成实际的缩略图生成服务
    // 暂时返回原始URL
    return fileUrl
  }

  // ============================================
  // 数据导出方法
  // ============================================

  async exportMaterials(filters?: MaterialFilters): Promise<string> {
    try {
      const { materials } = await this.getMaterials(filters, 1, 10000)
      
      let csvContent = 'data:text/csv;charset=utf-8,'
      csvContent += '素材ID,标题,描述,分类,文件类型,文件大小(MB),时长,标签,创建时间,状态,使用次数\n'
      
      materials.forEach(material => {
        csvContent += [
          material.id,
          material.title,
          material.description || '',
          material.category,
          material.file_type,
          Math.round(material.file_size / (1024 * 1024)),
          material.duration || '',
          material.tags.join(';'),
          material.created_at,
          material.is_active ? '活跃' : '禁用',
          material.usage_count
        ].join(',') + '\n'
      })
      
      return encodeURI(csvContent)
    } catch (error) {
      console.error('导出素材数据失败:', error)
      throw error
    }
  }

  // ============================================
  // 私有辅助方法
  // ============================================

  private async getAudioDuration(file: File): Promise<number> {
    return new Promise((resolve) => {
      const audio = new Audio()
      audio.preload = 'metadata'
      
      audio.onloadedmetadata = () => {
        resolve(Math.round(audio.duration))
      }
      
      audio.onerror = () => {
        resolve(0)
      }
      
      audio.src = URL.createObjectURL(file)
    })
  }

  private generateUploadTrends(days: number): Array<{ date: string; count: number; size_mb: number }> {
    const trends = []
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      trends.push({
        date: date.toISOString().split('T')[0],
        count: Math.floor(Math.random() * 50) + 10,
        size_mb: Math.floor(Math.random() * 500) + 100
      })
    }
    return trends
  }

  private generateUsageTrends(days: number): Array<{ date: string; usage: number }> {
    const trends = []
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      trends.push({
        date: date.toISOString().split('T')[0],
        usage: Math.floor(Math.random() * 200) + 50
      })
    }
    return trends
  }
}

export const materialService = MaterialService.getInstance()
export type { MaterialServiceInterface }