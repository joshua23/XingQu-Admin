import { supabase } from './supabase'

// 基于xq_materials表的背景音乐接口定义（统一素材管理）
export interface BackgroundMusic {
  id: string
  title: string
  description: string | null
  file_url: string
  file_name: string
  file_size: number
  file_type: string
  duration: number | null
  category: string
  tags: string[]
  creator_id: string | null
  thumbnail_url: string | null
  is_active: boolean
  usage_count: number
  rating_average: number | null
  created_at: string
  updated_at: string
}

export interface BackgroundMusicUpload {
  title: string
  description?: string
  file: File
  tags?: string[]
}

export interface BackgroundMusicUpdate {
  title?: string
  description?: string
  is_active?: boolean
  tags?: string[]
}

export const backgroundMusicService = {
  // 获取所有背景音乐（从统一素材表）
  async getMaterials(): Promise<{ data: BackgroundMusic[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_materials')
        .select('*')
        .eq('category', '背景音乐')
        .eq('is_active', true)
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
        .from('xq_materials')
        .select('*')
        .eq('category', '背景音乐')
        .eq('is_active', true)
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
        .from('xq_materials')
        .select('*')
        .eq('id', id)
        .eq('category', '背景音乐')
        .eq('is_active', true)
        .single()

      return { data, error }
    } catch (error) {
      console.error('获取背景音乐详情失败:', error)
      return { data: null, error }
    }
  },

  // 上传背景音乐（统一到素材表）
  async uploadMaterial(material: BackgroundMusicUpload): Promise<{ data: BackgroundMusic | null; error: any }> {
    try {
      // 1. 上传文件到materials bucket
      const fileExt = material.file.name.split('.').pop()
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
      const filePath = `background-music/${fileName}`

      const { error: uploadError } = await supabase.storage
        .from('materials')
        .upload(filePath, material.file)

      if (uploadError) {
        throw uploadError
      }

      // 2. 获取文件的公开URL
      const { data: { publicUrl } } = supabase.storage
        .from('materials')
        .getPublicUrl(filePath)

      // 3. 获取当前用户信息
      const { data: { user } } = await supabase.auth.getUser()
      const creatorId = user?.id || null

      // 4. 保存背景音乐信息到统一素材表
      const { data, error } = await supabase
        .from('xq_materials')
        .insert([{
          title: material.title,
          description: material.description || '',
          file_url: publicUrl,
          file_name: fileName,
          file_size: material.file.size,
          file_type: material.file.type,
          category: '背景音乐',
          tags: material.tags || ['背景音乐', '音频'],
          creator_id: creatorId,
          is_active: true,
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
        .from('xq_materials')
        .update(updateData)
        .eq('id', id)
        .eq('category', '背景音乐')
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
        .from('xq_materials')
        .update({ 
          is_active: false,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('category', '背景音乐')

      return { error }
    } catch (error) {
      console.error('删除背景音乐失败:', error)
      return { error }
    }
  },

  // 切换活跃状态（原public状态改为active状态）
  async toggleActive(id: string, isActive: boolean): Promise<{ data: BackgroundMusic | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_materials')
        .update({ 
          is_active: isActive,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('category', '背景音乐')
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('切换活跃状态失败:', error)
      return { data: null, error }
    }
  },

  // 搜索背景音乐
  async searchMaterials(query: string): Promise<{ data: BackgroundMusic[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_materials')
        .select('*')
        .eq('category', '背景音乐')
        .eq('is_active', true)
        .ilike('title', `%${query}%`)
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