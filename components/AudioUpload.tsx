'use client'

import { useState, useRef, useCallback } from 'react'
import { Upload, X, Music, AlertCircle, CheckCircle, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { backgroundMusicService, BackgroundMusic, BackgroundMusicUpload } from '@/lib/services/backgroundMusicService'

interface AudioUploadProps {
  onUploadComplete?: (materials: BackgroundMusic[]) => void
  onClose?: () => void
}

interface UploadFile {
  file: File
  id: string
  status: 'pending' | 'uploading' | 'success' | 'error'
  progress: number
  error?: string
  result?: any
}

const AudioUpload = ({ onUploadComplete, onClose }: AudioUploadProps) => {
  const [files, setFiles] = useState<UploadFile[]>([])
  const [isDragOver, setIsDragOver] = useState(false)
  const [isUploading, setIsUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // 默认上传配置
  const [uploadConfig, setUploadConfig] = useState({
    isPublic: true,
    description: ''
  })

  // 支持的文件类型
  const supportedTypes = ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac', 'audio/m4a']
  const maxFileSize = 50 * 1024 * 1024 // 50MB

  const validateFile = (file: File): string | null => {
    if (!supportedTypes.includes(file.type) && !file.name.toLowerCase().match(/\.(mp3|wav|ogg|aac|m4a)$/)) {
      return '不支持的文件格式，请上传 MP3、WAV、OGG、AAC 或 M4A 格式的音频文件'
    }
    if (file.size > maxFileSize) {
      return '文件大小超过 50MB 限制'
    }
    return null
  }

  const addFiles = useCallback((newFiles: FileList | File[]) => {
    const validFiles: UploadFile[] = []
    
    Array.from(newFiles).forEach(file => {
      const error = validateFile(file)
      if (error) {
        // 可以显示错误提示
        console.warn(`文件 ${file.name}: ${error}`)
        return
      }

      validFiles.push({
        file,
        id: Math.random().toString(36).substring(2) + Date.now().toString(),
        status: 'pending',
        progress: 0
      })
    })

    setFiles(prev => [...prev, ...validFiles])
  }, [])

  const removeFile = (id: string) => {
    setFiles(prev => prev.filter(f => f.id !== id))
  }

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
    
    if (e.dataTransfer.files) {
      addFiles(e.dataTransfer.files)
    }
  }, [addFiles])

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(true)
  }, [])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
  }, [])

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      addFiles(e.target.files)
    }
  }, [addFiles])

  // 简化的配置更新
  const updateDescription = (value: string) => {
    setUploadConfig(prev => ({
      ...prev,
      description: value
    }))
  }

  const togglePublic = () => {
    setUploadConfig(prev => ({
      ...prev,
      isPublic: !prev.isPublic
    }))
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      // TODO: 实现标签添加功能
      // addTag()
    }
  }

  const updateFileStatus = (id: string, updates: Partial<UploadFile>) => {
    setFiles(prev => prev.map(f => 
      f.id === id ? { ...f, ...updates } : f
    ))
  }

  const uploadFiles = async () => {
    if (files.length === 0) return

    setIsUploading(true)
    const results: BackgroundMusic[] = []

    for (const fileItem of files) {
      if (fileItem.status !== 'pending') continue

      updateFileStatus(fileItem.id, { status: 'uploading', progress: 0 })

      try {
        // 从文件名生成背景音乐名称
        const name = fileItem.file.name.replace(/\.[^/.]+$/, "").replace(/[_-]/g, ' ')

        const uploadData: BackgroundMusicUpload = {
          name,
          description: uploadConfig.description || `上传的背景音乐：${fileItem.file.name}`,
          is_public: uploadConfig.isPublic,
          file: fileItem.file
        }

        // 模拟上传进度
        const progressInterval = setInterval(() => {
          updateFileStatus(fileItem.id, { progress: Math.min(90, fileItem.progress + 10) })
        }, 200)

        const { data, error } = await backgroundMusicService.uploadMaterial(uploadData)

        clearInterval(progressInterval)

        if (error) {
          throw error
        }

        updateFileStatus(fileItem.id, { 
          status: 'success', 
          progress: 100,
          result: data
        })
        
        if (data) {
          results.push(data)
        }

      } catch (error) {
        updateFileStatus(fileItem.id, { 
          status: 'error', 
          progress: 0,
          error: error instanceof Error ? error.message : '上传失败'
        })
      }
    }

    setIsUploading(false)
    
    if (results.length > 0 && onUploadComplete) {
      onUploadComplete(results)
    }
  }

  const getStatusIcon = (status: UploadFile['status']) => {
    switch (status) {
      case 'pending':
        return <Music className="h-4 w-4 text-muted-foreground" />
      case 'uploading':
        return <Loader2 className="h-4 w-4 animate-spin text-primary" />
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />
      case 'error':
        return <AlertCircle className="h-4 w-4 text-red-500" />
    }
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const successCount = files.filter(f => f.status === 'success').length
  const errorCount = files.filter(f => f.status === 'error').length
  const pendingCount = files.filter(f => f.status === 'pending').length

  return (
    <Card className="w-full max-w-4xl mx-auto">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center">
              <Upload className="h-5 w-5 mr-2" />
              上传音频素材
            </CardTitle>
            <CardDescription>
              支持 MP3、WAV、OGG、AAC、M4A 格式，单个文件最大 50MB
            </CardDescription>
          </div>
          {onClose && (
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="h-4 w-4" />
            </Button>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* 上传配置 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="text-sm font-medium text-foreground mb-2 block">
              背景音乐描述
            </label>
            <Input
              placeholder="可选：为背景音乐添加描述"
              value={uploadConfig.description}
              onChange={(e) => updateDescription(e.target.value)}
              className="w-full"
            />
          </div>

          <div>
            <label className="text-sm font-medium text-foreground mb-2 block">
              公开设置
            </label>
            <div className="flex items-center space-x-3">
              <label className="flex items-center space-x-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={uploadConfig.isPublic}
                  onChange={togglePublic}
                  className="rounded border-border text-primary focus:ring-primary"
                />
                <span className="text-sm text-foreground">
                  公开 (星趣App用户可使用)
                </span>
              </label>
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              {uploadConfig.isPublic ? '该音乐将对所有用户可见' : '仅管理员可见'}
            </p>
          </div>
        </div>

        {/* 文件拖拽上传区域 */}
        <div
          className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
            isDragOver 
              ? 'border-primary bg-primary/5' 
              : 'border-border hover:border-border/60'
          }`}
          onDrop={handleDrop}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
        >
          <div className="space-y-4">
            <div className="flex justify-center">
              <div className={`w-16 h-16 rounded-full flex items-center justify-center ${
                isDragOver ? 'bg-primary/10' : 'bg-muted'
              }`}>
                <Upload className={`h-8 w-8 ${isDragOver ? 'text-primary' : 'text-muted-foreground'}`} />
              </div>
            </div>
            <div>
              <h3 className="text-lg font-medium text-foreground">
                拖拽音频文件到此处
              </h3>
              <p className="text-sm text-muted-foreground mt-1">
                或者点击下方按钮选择文件
              </p>
            </div>
            <Button 
              onClick={() => fileInputRef.current?.click()}
              disabled={isUploading}
            >
              <Upload className="h-4 w-4 mr-2" />
              选择文件
            </Button>
            <input
              ref={fileInputRef}
              type="file"
              multiple
              accept="audio/*,.mp3,.wav,.ogg,.aac,.m4a"
              onChange={handleFileSelect}
              className="hidden"
            />
          </div>
        </div>

        {/* 文件列表 */}
        {files.length > 0 && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-foreground">
                待上传文件 ({files.length})
              </h3>
              {successCount + errorCount > 0 && (
                <div className="text-sm text-muted-foreground">
                  成功: {successCount} | 失败: {errorCount} | 待处理: {pendingCount}
                </div>
              )}
            </div>

            <div className="space-y-3 max-h-64 overflow-y-auto">
              {files.map(fileItem => (
                <div
                  key={fileItem.id}
                  className="flex items-center justify-between p-3 border border-border rounded-lg"
                >
                  <div className="flex items-center space-x-3 flex-1 min-w-0">
                    {getStatusIcon(fileItem.status)}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-foreground truncate">
                        {fileItem.file.name}
                      </p>
                      <div className="flex items-center space-x-4 text-xs text-muted-foreground">
                        <span>{formatFileSize(fileItem.file.size)}</span>
                        <span>{fileItem.file.type}</span>
                        {fileItem.status === 'uploading' && (
                          <span>{fileItem.progress}%</span>
                        )}
                        {fileItem.error && (
                          <span className="text-red-500">{fileItem.error}</span>
                        )}
                      </div>
                      {fileItem.status === 'uploading' && (
                        <div className="w-full bg-muted rounded-full h-1 mt-2">
                          <div 
                            className="bg-primary h-1 rounded-full transition-all"
                            style={{ width: `${fileItem.progress}%` }}
                          />
                        </div>
                      )}
                    </div>
                  </div>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => removeFile(fileItem.id)}
                    disabled={fileItem.status === 'uploading'}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>

            <div className="flex items-center justify-between pt-4 border-t border-border">
              <div className="text-sm text-muted-foreground">
                {pendingCount > 0 && `${pendingCount} 个文件待上传`}
              </div>
              <div className="flex items-center space-x-2">
                <Button
                  variant="outline"
                  onClick={() => setFiles([])}
                  disabled={isUploading}
                >
                  清空列表
                </Button>
                <Button
                  onClick={uploadFiles}
                  disabled={pendingCount === 0 || isUploading}
                >
                  {isUploading ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      上传中...
                    </>
                  ) : (
                    <>
                      <Upload className="h-4 w-4 mr-2" />
                      开始上传 ({pendingCount})
                    </>
                  )}
                </Button>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export default AudioUpload