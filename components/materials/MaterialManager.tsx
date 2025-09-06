/**
 * 星趣后台管理系统 - 素材管理组件
 * 提供素材上传、管理、分类和统计分析的完整界面
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useRef } from 'react'
import { 
  Music, 
  Upload, 
  Search, 
  Filter,
  RefreshCw,
  Eye,
  Edit,
  Trash2,
  Download,
  Play,
  Pause,
  Volume2,
  Image,
  Video,
  FileText,
  Folder,
  Tag,
  Calendar,
  BarChart3,
  Settings,
  AlertTriangle,
  CheckCircle,
  Clock,
  Users,
  TrendingUp
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Progress } from '@/components/ui/progress'
import { useMaterialManagement } from '@/lib/hooks/useMaterialManagement'
import { cn } from '@/lib/utils'
import type { Material, MaterialFilters } from '@/lib/services/materialService'

const MaterialManager: React.FC = () => {
  const {
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
    createCategory,
    updateCategory,
    deleteCategory,
    
    // 选择管理
    selectMaterial,
    unselectMaterial,
    selectAllMaterials,
    clearSelection,
    toggleMaterialSelection,
    
    // 数据导出
    exportMaterials,
    
    // 工具方法
    refreshData,
    clearError
  } = useMaterialManagement()

  // 本地状态
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('')
  const [selectedFileType, setSelectedFileType] = useState('')
  const [showUploadDialog, setShowUploadDialog] = useState(false)
  const [showCategoryDialog, setShowCategoryDialog] = useState(false)
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [playingMaterial, setPlayingMaterial] = useState<string | null>(null)

  // 文件上传引用
  const fileInputRef = useRef<HTMLInputElement>(null)

  // 搜索和过滤处理
  const handleSearch = async () => {
    const filters: MaterialFilters = {}
    
    if (searchQuery.trim()) {
      filters.search = searchQuery.trim()
    }
    if (selectedCategory) {
      filters.category = selectedCategory
    }
    if (selectedFileType) {
      filters.file_type = selectedFileType
    }
    
    await loadMaterials(filters, 1, 50)
  }

  // 文件上传处理
  const handleFileUpload = async (files: FileList | null) => {
    if (!files || files.length === 0) return

    for (let i = 0; i < files.length; i++) {
      const file = files[i]
      
      try {
        await uploadMaterial({
          title: file.name.replace(/\.[^/.]+$/, ""), // 移除文件扩展名
          description: `上传的${getFileTypeDisplay(file.type)}文件`,
          category: selectedCategory || '未分类',
          tags: [getFileTypeDisplay(file.type)],
          file: file
        })
      } catch (error) {
        console.error(`上传文件 ${file.name} 失败:`, error)
      }
    }
  }

  // 批量操作处理
  const handleBulkAction = async (action: string) => {
    if (selectedMaterials.length === 0) {
      alert('请先选择要操作的素材')
      return
    }

    try {
      switch (action) {
        case 'activate':
          await bulkOperateMaterials({
            materialIds: selectedMaterials.map(m => m.id),
            action: 'activate'
          })
          break
        case 'deactivate':
          await bulkOperateMaterials({
            materialIds: selectedMaterials.map(m => m.id),
            action: 'deactivate'
          })
          break
        case 'delete':
          if (confirm(`确定要删除选中的 ${selectedMaterials.length} 个素材吗？`)) {
            await bulkOperateMaterials({
              materialIds: selectedMaterials.map(m => m.id),
              action: 'delete'
            })
          }
          break
      }
    } catch (error) {
      console.error('批量操作失败:', error)
    }
  }

  // 数据导出处理
  const handleExportData = async () => {
    try {
      const csvUrl = await exportMaterials()
      const link = document.createElement('a')
      link.href = csvUrl
      link.download = `materials_data_${new Date().toISOString().split('T')[0]}.csv`
      link.click()
    } catch (error) {
      console.error('数据导出失败:', error)
    }
  }

  // 获取文件类型显示名称
  const getFileTypeDisplay = (fileType: string): string => {
    const typeMap: Record<string, string> = {
      'audio': '音频',
      'video': '视频',
      'image': '图片',
      'application': '文档',
      'text': '文本'
    }
    return typeMap[fileType.split('/')[0]] || '其他'
  }

  // 获取文件类型图标
  const getFileTypeIcon = (fileType: string) => {
    const mainType = fileType.split('/')[0]
    switch (mainType) {
      case 'audio':
        return <Volume2 className="h-4 w-4" />
      case 'video':
        return <Video className="h-4 w-4" />
      case 'image':
        return <Image className="h-4 w-4" />
      default:
        return <FileText className="h-4 w-4" />
    }
  }

  // 格式化文件大小
  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  // 格式化时长
  const formatDuration = (seconds: number): string => {
    if (!seconds) return ''
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  if (loading && materials.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 错误提示 */}
      {error && (
        <div className="flex items-center justify-between p-4 bg-red-50 border border-red-200 rounded-lg">
          <div className="flex items-center space-x-2">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <span className="text-red-700">{error}</span>
          </div>
          <Button variant="ghost" size="sm" onClick={clearError}>
            ✕
          </Button>
        </div>
      )}

      {/* 页面标题和控制按钮 */}
      <div className="flex items-start justify-between">
        <div className="max-w-2xl">
          <h1 className="text-3xl font-bold text-foreground">素材管理</h1>
          <p className="text-muted-foreground mt-2">
            管理音频、视频和图片素材，支持上传、分类和批量操作
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <Button
            variant="secondary"
            onClick={refreshData}
            disabled={loading}
            className="flex items-center space-x-2"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>刷新</span>
          </Button>
          
          <Button
            variant="outline"
            onClick={handleExportData}
            className="flex items-center space-x-2"
          >
            <Download size={16} />
            <span>导出</span>
          </Button>
          
          <Button
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="flex items-center space-x-2"
          >
            <Upload size={16} />
            <span>{uploading ? '上传中...' : '上传素材'}</span>
          </Button>
          
          <input
            ref={fileInputRef}
            type="file"
            multiple
            accept="audio/*,video/*,image/*"
            className="hidden"
            onChange={(e) => handleFileUpload(e.target.files)}
          />
        </div>
      </div>

      {/* 统计卡片 */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">素材总数</CardTitle>
              <Music className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total_materials}</div>
              <p className="text-xs text-muted-foreground">
                活跃: {stats.active_materials}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">存储空间</CardTitle>
              <BarChart3 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total_size_mb} MB</div>
              <p className="text-xs text-muted-foreground">
                总存储使用量
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">分类数量</CardTitle>
              <Folder className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.categories.length}</div>
              <p className="text-xs text-muted-foreground">
                活跃分类
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">热门标签</CardTitle>
              <Tag className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.popular_tags.length}</div>
              <p className="text-xs text-muted-foreground">
                常用标签数量
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* 主要功能标签页 */}
      <Tabs defaultValue="materials" className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="materials">素材库</TabsTrigger>
          <TabsTrigger value="categories">分类管理</TabsTrigger>
          <TabsTrigger value="analytics">数据分析</TabsTrigger>
          <TabsTrigger value="settings">设置</TabsTrigger>
        </TabsList>

        {/* 素材库标签页 */}
        <TabsContent value="materials" className="space-y-6">
          {/* 搜索和筛选 */}
          <Card>
            <CardHeader>
              <CardTitle>搜索和筛选</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">搜索关键词</label>
                  <div className="flex space-x-2">
                    <Input
                      placeholder="搜索素材标题..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                    />
                    <Button onClick={handleSearch} disabled={loading}>
                      <Search className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">分类</label>
                  <select 
                    className="w-full p-2 border rounded-md"
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                  >
                    <option value="">全部分类</option>
                    {categories.map(category => (
                      <option key={category.id} value={category.name}>
                        {category.name}
                      </option>
                    ))}
                  </select>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">文件类型</label>
                  <select 
                    className="w-full p-2 border rounded-md"
                    value={selectedFileType}
                    onChange={(e) => setSelectedFileType(e.target.value)}
                  >
                    <option value="">全部类型</option>
                    <option value="audio">音频</option>
                    <option value="video">视频</option>
                    <option value="image">图片</option>
                  </select>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">操作</label>
                  <div className="flex space-x-2">
                    <Button 
                      variant="outline" 
                      onClick={() => setViewMode(viewMode === 'grid' ? 'list' : 'grid')}
                    >
                      {viewMode === 'grid' ? '列表' : '网格'}
                    </Button>
                    <Button 
                      variant="outline"
                      onClick={selectedMaterials.length > 0 ? clearSelection : selectAllMaterials}
                    >
                      {selectedMaterials.length > 0 ? '取消选择' : '全选'}
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* 批量操作 */}
          {selectedMaterials.length > 0 && (
            <Card className="bg-blue-50 border-blue-200">
              <CardContent className="pt-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <span className="text-sm font-medium">
                      已选择 {selectedMaterials.length} 个素材
                    </span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => handleBulkAction('activate')}
                      disabled={processing}
                    >
                      启用
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => handleBulkAction('deactivate')}
                      disabled={processing}
                    >
                      禁用
                    </Button>
                    <Button 
                      size="sm" 
                      variant="destructive"
                      onClick={() => handleBulkAction('delete')}
                      disabled={processing}
                    >
                      删除
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* 素材列表 */}
          <div className={cn(
            viewMode === 'grid' 
              ? "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4"
              : "space-y-4"
          )}>
            {materials.map((material) => (
              <Card 
                key={material.id} 
                className={cn(
                  "hover:shadow-md transition-shadow cursor-pointer",
                  selectedMaterials.find(m => m.id === material.id) && "ring-2 ring-primary"
                )}
              >
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        checked={!!selectedMaterials.find(m => m.id === material.id)}
                        onChange={() => toggleMaterialSelection(material)}
                        className="rounded"
                      />
                      {getFileTypeIcon(material.file_type)}
                    </div>
                    <div className="flex items-center space-x-1">
                      <Badge variant={material.is_active ? "default" : "secondary"}>
                        {material.is_active ? '活跃' : '禁用'}
                      </Badge>
                    </div>
                  </div>
                  <div>
                    <CardTitle className="text-sm line-clamp-1">{material.title}</CardTitle>
                    <CardDescription className="text-xs line-clamp-2">
                      {material.description}
                    </CardDescription>
                  </div>
                </CardHeader>
                
                <CardContent className="space-y-2">
                  <div className="flex items-center justify-between text-xs text-muted-foreground">
                    <span>{getFileTypeDisplay(material.file_type)}</span>
                    <span>{formatFileSize(material.file_size)}</span>
                  </div>
                  
                  {material.duration && (
                    <div className="flex items-center justify-between text-xs">
                      <span>时长: {formatDuration(material.duration)}</span>
                      <span>使用: {material.usage_count}</span>
                    </div>
                  )}
                  
                  <div className="flex flex-wrap gap-1">
                    {material.tags.slice(0, 3).map((tag, index) => (
                      <Badge key={index} variant="outline" className="text-xs">
                        {tag}
                      </Badge>
                    ))}
                    {material.tags.length > 3 && (
                      <Badge variant="outline" className="text-xs">
                        +{material.tags.length - 3}
                      </Badge>
                    )}
                  </div>
                  
                  <div className="flex items-center justify-between pt-2">
                    <span className="text-xs text-muted-foreground">
                      {material.category}
                    </span>
                    <div className="flex items-center space-x-1">
                      <Button size="sm" variant="ghost">
                        <Eye className="h-3 w-3" />
                      </Button>
                      <Button size="sm" variant="ghost">
                        <Edit className="h-3 w-3" />
                      </Button>
                      {material.file_type.startsWith('audio/') && (
                        <Button 
                          size="sm" 
                          variant="ghost"
                          onClick={() => setPlayingMaterial(
                            playingMaterial === material.id ? null : material.id
                          )}
                        >
                          {playingMaterial === material.id ? (
                            <Pause className="h-3 w-3" />
                          ) : (
                            <Play className="h-3 w-3" />
                          )}
                        </Button>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* 分页 */}
          {totalPages > 1 && (
            <div className="flex items-center justify-center space-x-2">
              <Button
                variant="outline"
                disabled={currentPage <= 1}
                onClick={() => loadMaterials({}, currentPage - 1)}
              >
                上一页
              </Button>
              <span className="text-sm text-muted-foreground">
                第 {currentPage} 页，共 {totalPages} 页
              </span>
              <Button
                variant="outline"
                disabled={currentPage >= totalPages}
                onClick={() => loadMaterials({}, currentPage + 1)}
              >
                下一页
              </Button>
            </div>
          )}
        </TabsContent>

        {/* 分类管理标签页 */}
        <TabsContent value="categories" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>素材分类</CardTitle>
                <CardDescription>管理素材分类和层级结构</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {categories.map(category => (
                  <div key={category.id} className="flex items-center justify-between p-3 border rounded-lg">
                    <div>
                      <div className="font-medium">{category.name}</div>
                      <div className="text-sm text-muted-foreground">
                        {category.description || '暂无描述'}
                      </div>
                      <div className="text-xs text-muted-foreground mt-1">
                        素材数量: {category.material_count}
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button size="sm" variant="ghost">
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button size="sm" variant="ghost">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>添加分类</CardTitle>
                <CardDescription>创建新的素材分类</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">分类名称</label>
                  <Input placeholder="输入分类名称" />
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">描述</label>
                  <textarea 
                    className="w-full p-2 border rounded-md" 
                    rows={3}
                    placeholder="输入分类描述(可选)"
                  />
                </div>
                
                <Button className="w-full" disabled={processing}>
                  <Folder className="h-4 w-4 mr-2" />
                  添加分类
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* 数据分析标签页 */}
        <TabsContent value="analytics" className="space-y-6">
          {stats && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* 文件类型分布 */}
              <Card>
                <CardHeader>
                  <CardTitle>文件类型分布</CardTitle>
                  <CardDescription>不同类型文件的数量和大小统计</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {stats.file_type_distribution.map((type, index) => (
                      <div key={index} className="space-y-2">
                        <div className="flex justify-between items-center">
                          <span className="text-sm font-medium capitalize">{type.type}</span>
                          <span className="text-sm text-muted-foreground">
                            {type.count} 个文件 ({type.size_mb} MB)
                          </span>
                        </div>
                        <Progress value={(type.count / stats.total_materials) * 100} className="h-2" />
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              {/* 热门标签 */}
              <Card>
                <CardHeader>
                  <CardTitle>热门标签</CardTitle>
                  <CardDescription>最常用的素材标签</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-wrap gap-2">
                    {stats.popular_tags.slice(0, 20).map((tag, index) => (
                      <Badge key={index} variant="secondary" className="text-xs">
                        {tag.tag} ({tag.count})
                      </Badge>
                    ))}
                  </div>
                </CardContent>
              </Card>

              {/* 上传趋势 */}
              <Card className="lg:col-span-2">
                <CardHeader>
                  <CardTitle>上传趋势</CardTitle>
                  <CardDescription>最近30天的素材上传统计</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="h-64 flex items-center justify-center text-muted-foreground">
                    <div className="text-center">
                      <TrendingUp className="h-12 w-12 mx-auto mb-4 opacity-50" />
                      <p>趋势图表功能即将上线</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </TabsContent>

        {/* 设置标签页 */}
        <TabsContent value="settings" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>存储设置</CardTitle>
                <CardDescription>管理文件存储和限制</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">单文件大小限制</label>
                  <select className="w-full p-2 border rounded-md">
                    <option value="10">10 MB</option>
                    <option value="50">50 MB</option>
                    <option value="100">100 MB</option>
                    <option value="500">500 MB</option>
                  </select>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">支持的文件类型</label>
                  <div className="space-y-2">
                    <label className="flex items-center space-x-2">
                      <input type="checkbox" defaultChecked />
                      <span className="text-sm">音频文件 (MP3, WAV, AAC)</span>
                    </label>
                    <label className="flex items-center space-x-2">
                      <input type="checkbox" defaultChecked />
                      <span className="text-sm">视频文件 (MP4, AVI, MOV)</span>
                    </label>
                    <label className="flex items-center space-x-2">
                      <input type="checkbox" defaultChecked />
                      <span className="text-sm">图片文件 (JPG, PNG, GIF)</span>
                    </label>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>自动化设置</CardTitle>
                <CardDescription>配置自动化处理选项</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <label className="flex items-center space-x-2">
                  <input type="checkbox" defaultChecked />
                  <span className="text-sm">自动生成缩略图</span>
                </label>
                <label className="flex items-center space-x-2">
                  <input type="checkbox" />
                  <span className="text-sm">自动提取音频元数据</span>
                </label>
                <label className="flex items-center space-x-2">
                  <input type="checkbox" />
                  <span className="text-sm">自动病毒扫描</span>
                </label>
                <label className="flex items-center space-x-2">
                  <input type="checkbox" />
                  <span className="text-sm">自动内容审核</span>
                </label>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default MaterialManager