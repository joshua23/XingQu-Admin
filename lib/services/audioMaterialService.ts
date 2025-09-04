import { supabase } from './supabase'

// 基于xq_background_music表结构的接口定义
export interface BackgroundMusic {
  id: string
  admin_id: string | null
  name: string
  audio_url: string
  description: string | null
  cover_image_url: string | null
  is_public: boolean
  created_at: string
  updated_at: string
  is_deleted: boolean
}

export interface BackgroundMusicUpload {
  name: string
  description?: string
  is_public?: boolean
  file: File
}

export interface BackgroundMusicUpdate {
  name?: string
  description?: string
  is_public?: boolean
}

export const audioMaterialService = {
  // 获取所有背景音乐
  async getMaterials(): Promise<{ data: BackgroundMusic[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_background_music')
        .select('*')
        .eq('is_deleted', false)
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('获取背景音乐失败:', error)
      return { data: null, error }
    }
  },

  async createCategory(category: CategoryCreate): Promise<{ data: MaterialCategory | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_material_categories')
        .insert([category])
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('创建分类失败:', error)
      return { data: null, error }
    }
  },

  async updateCategory(id: string, updates: CategoryUpdate): Promise<{ data: MaterialCategory | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_material_categories')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('更新分类失败:', error)
      return { data: null, error }
    }
  },

  async deleteCategory(id: string): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('xq_material_categories')
        .update({ is_active: false })
        .eq('id', id)

      return { error }
    } catch (error) {
      console.error('删除分类失败:', error)
      return { error }
    }
  },

  // 素材管理
  async getMaterials(categoryId?: string): Promise<{ data: AudioMaterial[] | null; error: any }> {
    try {
      let query = supabase
        .from('xq_audio_materials')
        .select(`
          *,
          category:xq_material_categories(*)
        `)
        .eq('is_active', true)
        .order('created_at', { ascending: false })

      if (categoryId) {
        query = query.eq('category_id', categoryId)
      }

      const { data, error } = await query

      return { data, error }
    } catch (error) {
      console.error('获取素材失败:', error)
      return { data: null, error }
    }
  },

  async getMaterial(id: string): Promise<{ data: AudioMaterial | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_audio_materials')
        .select(`
          *,
          category:xq_material_categories(*)
        `)
        .eq('id', id)
        .single()

      return { data, error }
    } catch (error) {
      console.error('获取素材详情失败:', error)
      return { data: null, error }
    }
  },

  async uploadMaterial(material: AudioMaterialUpload): Promise<{ data: AudioMaterial | null; error: any }> {
    try {
      // 1. 上传文件到Storage
      const fileExt = material.file.name.split('.').pop()
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
      const filePath = `audio/${fileName}`

      const { error: uploadError } = await supabase.storage
        .from('audio-materials')
        .upload(filePath, material.file)

      if (uploadError) {
        throw uploadError
      }

      // 2. 获取文件的公开URL
      const { data: { publicUrl } } = supabase.storage
        .from('audio-materials')
        .getPublicUrl(filePath)

      // 3. 获取音频文件时长（如果浏览器支持）
      let duration = 0
      if (material.file.type.startsWith('audio/')) {
        try {
          duration = await getAudioDuration(material.file)
        } catch (e) {
          console.warn('无法获取音频时长:', e)
        }
      }

      // 4. 保存素材信息到数据库
      const { data, error } = await supabase
        .from('xq_audio_materials')
        .insert([{
          title: material.title,
          description: material.description || '',
          file_name: material.file.name,
          file_path: filePath,
          file_size: material.file.size,
          duration_seconds: Math.round(duration),
          category_id: material.category_id,
          tags: material.tags || [],
        }])
        .select(`
          *,
          category:xq_material_categories(*)
        `)
        .single()

      return { data, error }
    } catch (error) {
      console.error('上传素材失败:', error)
      return { data: null, error }
    }
  },

  async updateMaterial(id: string, updates: AudioMaterialUpdate): Promise<{ data: AudioMaterial | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_audio_materials')
        .update(updates)
        .eq('id', id)
        .select(`
          *,
          category:xq_material_categories(*)
        `)
        .single()

      return { data, error }
    } catch (error) {
      console.error('更新素材失败:', error)
      return { data: null, error }
    }
  },

  async deleteMaterial(id: string): Promise<{ error: any }> {
    try {
      // 1. 获取素材信息
      const { data: material, error: fetchError } = await supabase
        .from('xq_audio_materials')
        .select('file_path')
        .eq('id', id)
        .single()

      if (fetchError || !material) {
        throw fetchError || new Error('素材不存在')
      }

      // 2. 删除存储文件
      const { error: deleteFileError } = await supabase.storage
        .from('audio-materials')
        .remove([material.file_path])

      if (deleteFileError) {
        console.warn('删除文件失败:', deleteFileError)
      }

      // 3. 软删除数据库记录
      const { error } = await supabase
        .from('xq_audio_materials')
        .update({ is_active: false })
        .eq('id', id)

      return { error }
    } catch (error) {
      console.error('删除素材失败:', error)
      return { error }
    }
  },

  async incrementDownloadCount(id: string): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('xq_audio_materials')
        .update({ 
          download_count: supabase.rpc('increment_download_count', { material_id: id })
        })
        .eq('id', id)

      return { error }
    } catch (error) {
      console.error('增加下载次数失败:', error)
      return { error }
    }
  },

  // 获取素材文件的公开URL
  getFileUrl(filePath: string): string {
    const { data } = supabase.storage
      .from('audio-materials')
      .getPublicUrl(filePath)
    
    return data.publicUrl
  },

  // 搜索素材
  async searchMaterials(query: string, categoryId?: string): Promise<{ data: AudioMaterial[] | null; error: any }> {
    try {
      let baseQuery = supabase
        .from('xq_audio_materials')
        .select(`
          *,
          category:xq_material_categories(*)
        `)
        .eq('is_active', true)

      if (categoryId) {
        baseQuery = baseQuery.eq('category_id', categoryId)
      }

      // 使用PostgreSQL的全文搜索或简单的LIKE搜索
      const { data, error } = await baseQuery
        .or(`title.ilike.%${query}%, tags.cs.{${query}}`)
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('搜索素材失败:', error)
      return { data: null, error }
    }
  }
}

// 辅助函数：获取音频文件时长
function getAudioDuration(file: File): Promise<number> {
  return new Promise((resolve, reject) => {
    const audio = new Audio()
    const objectUrl = URL.createObjectURL(file)
    
    audio.addEventListener('loadedmetadata', () => {
      URL.revokeObjectURL(objectUrl)
      resolve(audio.duration)
    })
    
    audio.addEventListener('error', (e) => {
      URL.revokeObjectURL(objectUrl)
      reject(e)
    })
    
    audio.src = objectUrl
  })
}

// 导出类型
export type {
  MaterialCategory,
  AudioMaterial,
  AudioMaterialUpload,
  AudioMaterialUpdate,
  CategoryCreate,
  CategoryUpdate
}