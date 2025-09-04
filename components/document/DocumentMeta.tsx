import React from 'react'
import { AlertTriangle, FileText, Calendar, HardDrive } from 'lucide-react'

interface DocumentMetaProps {
  fileName: string
  fileSize: number
  lastModified: Date
  documentType: string
  isEditing?: boolean
}

export function DocumentMeta({ 
  fileName, 
  fileSize, 
  lastModified, 
  documentType,
  isEditing = false 
}: DocumentMetaProps) {
  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }

  const formatDate = (date: Date): string => {
    return new Intl.DateTimeFormat('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date)
  }

  return (
    <div className="bg-card border border-border rounded-lg p-6 space-y-4">
      <h3 className="text-lg font-semibold text-foreground">文档信息</h3>
      
      <div className="space-y-3">
        <div className="flex items-center space-x-3 text-sm">
          <FileText className="w-4 h-4 text-muted-foreground" />
          <span className="text-muted-foreground">文件名:</span>
          <span className="text-foreground font-medium">{fileName}</span>
        </div>

        <div className="flex items-center space-x-3 text-sm">
          <HardDrive className="w-4 h-4 text-muted-foreground" />
          <span className="text-muted-foreground">文件大小:</span>
          <span className="text-foreground font-medium">{formatFileSize(fileSize)}</span>
        </div>

        <div className="flex items-center space-x-3 text-sm">
          <Calendar className="w-4 h-4 text-muted-foreground" />
          <span className="text-muted-foreground">最后修改:</span>
          <span className="text-foreground font-medium">{formatDate(lastModified)}</span>
        </div>

        <div className="flex items-center space-x-3 text-sm">
          <FileText className="w-4 h-4 text-muted-foreground" />
          <span className="text-muted-foreground">文档类型:</span>
          <span className="text-foreground font-medium">{documentType}</span>
        </div>
      </div>

      {isEditing && (
        <div className="bg-warning/10 border border-warning/20 rounded-lg p-4 mt-4">
          <div className="flex items-start space-x-3">
            <AlertTriangle className="w-5 h-5 text-warning mt-0.5" />
            <div className="flex-1">
              <h4 className="font-medium text-warning mb-1">重要提示</h4>
              <p className="text-sm text-warning/80">
                修改隐私协议或用户协议将影响所有用户。请确保修改内容符合法律法规要求。
                建议在修改前备份原文档。
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}