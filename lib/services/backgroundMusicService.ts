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

export const backgroundMusicService = {
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

  // 获取公开的背景音乐(供星趣App调用)
  async getPublicMaterials(): Promise<{ data: BackgroundMusic[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_background_music')
        .select('*')
        .eq('is_deleted', false)
        .eq('is_public', true)
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('获取公开背景音乐失败:', error)
      return { data: null, error }
    }
  },

  // 获取单个背景音乐详情
  async getMaterial(id: string): Promise<{ data: BackgroundMusic | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_background_music')
        .select('*')
        .eq('id', id)
        .eq('is_deleted', false)
        .single()

      return { data, error }
    } catch (error) {
      console.error('获取背景音乐详情失败:', error)
      return { data: null, error }
    }
  },

  // 上传背景音乐
  async uploadMaterial(material: BackgroundMusicUpload): Promise<{ data: BackgroundMusic | null; error: any }> {
    try {
      // 1. 上传文件到bgm bucket (使用现有的bgm bucket)
      const fileExt = material.file.name.split('.').pop()
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
      const filePath = `${fileName}`

      const { error: uploadError } = await supabase.storage
        .from('bgm')
        .upload(filePath, material.file)

      if (uploadError) {
        throw uploadError
      }

      // 2. 获取文件的公开URL
      const { data: { publicUrl } } = supabase.storage
        .from('bgm')
        .getPublicUrl(filePath)

      // 3. 获取当前用户信息 (admin_id)
      const { data: { user } } = await supabase.auth.getUser()
      const adminId = user?.id || null

      // 4. 保存背景音乐信息到数据库
      const { data, error } = await supabase
        .from('xq_background_music')
        .insert([{
          admin_id: adminId,
          name: material.name,
          audio_url: publicUrl,
          description: material.description || '',
          is_public: material.is_public ?? true,
        }])
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('上传背景音乐失败:', error)
      return { data: null, error }
    }
  },

  // 更新背景音乐信息
  async updateMaterial(id: string, updates: BackgroundMusicUpdate): Promise<{ data: BackgroundMusic | null; error: any }> {
    try {
      const updateData = {
        ...updates,
        updated_at: new Date().toISOString()
      }

      const { data, error } = await supabase
        .from('xq_background_music')
        .update(updateData)
        .eq('id', id)
        .eq('is_deleted', false)
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('更新背景音乐失败:', error)
      return { data: null, error }
    }
  },

  // 删除背景音乐(软删除)
  async deleteMaterial(id: string): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('xq_background_music')
        .update({ 
          is_deleted: true,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)

      return { error }
    } catch (error) {
      console.error('删除背景音乐失败:', error)
      return { error }
    }
  },

  // 切换公开状态
  async togglePublic(id: string, isPublic: boolean): Promise<{ data: BackgroundMusic | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_background_music')
        .update({ 
          is_public: isPublic,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('is_deleted', false)
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('切换公开状态失败:', error)
      return { data: null, error }
    }
  },

  // 搜索背景音乐
  async searchMaterials(query: string): Promise<{ data: BackgroundMusic[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_background_music')
        .select('*')
        .eq('is_deleted', false)
        .ilike('name', `%${query}%`)
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('搜索背景音乐失败:', error)
      return { data: null, error }
    }
  },

  // 获取文件下载URL
  getDownloadUrl(audioUrl: string): string {
    // 如果已经是完整URL，直接返回
    if (audioUrl.startsWith('http')) {
      return audioUrl
    }
    
    // 否则通过storage API获取
    const { data } = supabase.storage
      .from('bgm')
      .getPublicUrl(audioUrl)
    
    return data.publicUrl
  },

  // 获取统计信息
  async getStats(): Promise<{ 
    total: number, 
    public: number, 
    private: number, 
    recentCount: number 
  }> {
    try {
      const [totalResult, publicResult, privateResult, recentResult] = await Promise.all([
        supabase
          .from('xq_background_music')
          .select('id', { count: 'exact', head: true })
          .eq('is_deleted', false),
        
        supabase
          .from('xq_background_music')
          .select('id', { count: 'exact', head: true })
          .eq('is_deleted', false)
          .eq('is_public', true),
        
        supabase
          .from('xq_background_music')
          .select('id', { count: 'exact', head: true })
          .eq('is_deleted', false)
          .eq('is_public', false),
        
        supabase
          .from('xq_background_music')
          .select('id', { count: 'exact', head: true })
          .eq('is_deleted', false)
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      ])

      return {
        total: totalResult.count || 0,
        public: publicResult.count || 0,
        private: privateResult.count || 0,
        recentCount: recentResult.count || 0
      }
    } catch (error) {
      console.error('获取统计信息失败:', error)
      return {
        total: 0,
        public: 0,
        private: 0,
        recentCount: 0
      }
    }
  }
}

// 导出类型
export type {
  BackgroundMusic,
  BackgroundMusicUpload,
  BackgroundMusicUpdate
}