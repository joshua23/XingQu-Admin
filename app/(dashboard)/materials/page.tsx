'use client'

import { useState, useEffect } from 'react'
import { 
  Upload, 
  Music, 
  Search, 
  Plus, 
  Play, 
  Pause, 
  Download, 
  Trash2, 
  Edit,
  FolderOpen,
  Tag
} from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import AudioUpload from '@/components/AudioUpload'
import { 
  backgroundMusicService, 
  BackgroundMusic 
} from '@/lib/services/backgroundMusicService'

const MaterialsPage = () => {
  const [materials, setMaterials] = useState<BackgroundMusic[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [currentPlaying, setCurrentPlaying] = useState<string | null>(null)
  const [showUpload, setShowUpload] = useState(false)
  const [currentAudio, setCurrentAudio] = useState<HTMLAudioElement | null>(null)

  // 加载数据
  const loadData = async () => {
    setLoading(true)
    try {
      const { data, error } = await backgroundMusicService.getMaterials()
      
      if (data) {
        setMaterials(data)
      }
      
      if (error) {
        console.error('加载素材失败:', error)
      }
    } catch (error) {
      console.error('加载数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  const filteredMaterials = materials.filter(material => {
    const matchesSearch = material.name.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesSearch && !material.is_deleted
  })

  // 音频播放控制
  const handlePlayPause = async (material: BackgroundMusic) => {
    try {
      if (currentPlaying === material.id) {
        // 当前正在播放，暂停
        if (currentAudio) {
          currentAudio.pause()
          setCurrentPlaying(null)
        }
      } else {
        // 停止之前的音频
        if (currentAudio) {
          currentAudio.pause()
          currentAudio.currentTime = 0
        }
        
        // 播放新音频
        const audioUrl = backgroundMusicService.getDownloadUrl(material.audio_url)
        const audio = new Audio(audioUrl)
        
        // 设置音频事件监听
        audio.addEventListener('ended', () => {
          setCurrentPlaying(null)
          setCurrentAudio(null)
        })
        
        audio.addEventListener('error', (e) => {
          console.error('音频播放失败:', e)
          alert('音频播放失败，请检查文件是否存在或格式是否正确')
          setCurrentPlaying(null)
          setCurrentAudio(null)
        })
        
        // 开始播放
        await audio.play()
        setCurrentAudio(audio)
        setCurrentPlaying(material.id)
      }
    } catch (error) {
      console.error('播放音频失败:', error)
      alert('播放失败：' + (error instanceof Error ? error.message : '未知错误'))
      setCurrentPlaying(null)
    }
  }

  // 组件卸载时清理音频
  useEffect(() => {
    return () => {
      if (currentAudio) {
        currentAudio.pause()
        currentAudio.currentTime = 0
      }
    }
  }, [currentAudio])

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }


  const handleUploadComplete = (newMaterials: BackgroundMusic[]) => {
    // 添加新上传的素材到列表
    setMaterials(prev => [...newMaterials, ...prev])
    setShowUpload(false)
  }

  const handleDeleteMaterial = async (materialId: string) => {
    if (!window.confirm('确定要删除这个素材吗？此操作不可恢复。')) {
      return
    }

    try {
      const { error } = await backgroundMusicService.deleteMaterial(materialId)
      if (error) {
        console.error('删除素材失败:', error)
        alert('删除失败：' + error.message)
        return
      }

      // 从列表中移除
      setMaterials(prev => prev.filter(m => m.id !== materialId))
    } catch (error) {
      console.error('删除素材异常:', error)
      alert('删除失败，请稍后重试')
    }
  }

  const handleDownload = async (material: BackgroundMusic) => {
    try {
      // 获取文件URL并触发下载
      const fileUrl = backgroundMusicService.getDownloadUrl(material.audio_url)
      const link = document.createElement('a')
      link.href = fileUrl
      link.download = material.name + '.mp3'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    } catch (error) {
      console.error('下载失败:', error)
    }
  }

  if (loading) {
    return (
      <div className="flex-1 p-8">
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <Music className="h-12 w-12 animate-spin mx-auto text-primary" />
            <p className="mt-4 text-muted-foreground">正在加载素材库...</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 p-8 space-y-6">
      {/* 页面头部 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">音频素材管理</h1>
          <p className="text-muted-foreground mt-2">管理星趣App的背景音乐和音效素材</p>
        </div>
        <div className="flex items-center space-x-3">
          <Button
            variant="outline"
            onClick={() => setShowUpload(!showUpload)}
          >
            <Plus className="h-4 w-4 mr-2" />
            上传素材
          </Button>
          <Button>
            <FolderOpen className="h-4 w-4 mr-2" />
            管理分类
          </Button>
        </div>
      </div>

      {/* 统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">总素材数</CardTitle>
            <Music className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{materials.length}</div>
            <p className="text-xs text-muted-foreground">
              +2 比昨天
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">公开素材</CardTitle>
            <Tag className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{materials.filter(m => m.is_public && !m.is_deleted).length}</div>
            <p className="text-xs text-muted-foreground">
              对用户可见
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">私有素材</CardTitle>
            <Download className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {materials.filter(m => !m.is_public && !m.is_deleted).length}
            </div>
            <p className="text-xs text-muted-foreground">
              仅管理员可见
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">创建时间</CardTitle>
            <Upload className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {materials.filter(m => {
                const today = new Date()
                const created = new Date(m.created_at)
                const diffTime = Math.abs(today.getTime() - created.getTime())
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
                return diffDays <= 7 && !m.is_deleted
              }).length}
            </div>
            <p className="text-xs text-muted-foreground">
              近7天新增
            </p>
          </CardContent>
        </Card>
      </div>

      {/* 搜索和筛选 */}
      <div className="flex items-center space-x-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="搜索素材名称..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-9"
          />
        </div>
      </div>

      {/* 上传区域 */}
      {showUpload && (
        <AudioUpload
          onUploadComplete={handleUploadComplete}
          onClose={() => setShowUpload(false)}
        />
      )}

      {/* 素材列表 */}
      <Card>
        <CardHeader>
          <CardTitle>素材库</CardTitle>
          <CardDescription>
            共找到 {filteredMaterials.length} 个素材
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {filteredMaterials.map(material => (
              <div
                key={material.id}
                className="flex items-center justify-between p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center space-x-4 flex-1">
                  <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                    <Music className="h-6 w-6 text-primary" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium text-foreground truncate">
                      {material.name}
                    </h3>
                    <div className="flex items-center space-x-4 mt-1">
                      <span className="text-sm text-muted-foreground">
                        {material.is_public ? '🌍 公开' : '🔒 私有'}
                      </span>
                      <span className="text-sm text-muted-foreground">
                        {new Date(material.created_at).toLocaleDateString()}
                      </span>
                      <span className="text-sm text-muted-foreground">
                        {material.admin_id ? '管理员' : '系统'}
                      </span>
                    </div>
                    {material.description && (
                      <div className="flex items-center space-x-2 mt-2">
                        <Badge variant="secondary" className="text-xs">
                          {material.description}
                        </Badge>
                      </div>
                    )}
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => handlePlayPause(material)}
                  >
                    {currentPlaying === material.id ? (
                      <Pause className="h-4 w-4" />
                    ) : (
                      <Play className="h-4 w-4" />
                    )}
                  </Button>
                  <Button size="sm" variant="ghost" onClick={() => handleDownload(material)}>
                    <Download className="h-4 w-4" />
                  </Button>
                  <Button size="sm" variant="ghost">
                    <Edit className="h-4 w-4" />
                  </Button>
                  <Button 
                    size="sm" 
                    variant="ghost" 
                    className="text-destructive"
                    onClick={() => handleDeleteMaterial(material.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}
            {filteredMaterials.length === 0 && (
              <div className="text-center py-12">
                <Music className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                <h3 className="text-lg font-medium text-foreground mb-2">暂无素材</h3>
                <p className="text-muted-foreground mb-4">
                  {searchTerm
                    ? '没有找到匹配的素材，尝试调整搜索条件' 
                    : '还没有上传任何音频素材'}
                </p>
                <Button onClick={() => setShowUpload(true)}>
                  <Plus className="h-4 w-4 mr-2" />
                  上传第一个素材
                </Button>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default MaterialsPage