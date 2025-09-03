import React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { DocumentMetadata } from '../../types/document'
import MarkdownRenderer from './MarkdownRenderer'
import { Edit3, FileText, Calendar, HardDrive, AlertTriangle } from 'lucide-react'

interface DocumentViewerProps {
  content: string
  metadata: DocumentMetadata | null
  onEdit: () => void
  canEdit: boolean
  className?: string
}

export const DocumentViewer: React.FC<DocumentViewerProps> = ({
  content,
  metadata,
  onEdit,
  canEdit,
  className = ''
}) => {
  // 格式化文件大小
  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
  }

  // 格式化日期
  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date)
  }

  // 获取文档类型显示名称
  const getDocumentTypeName = (type: string) => {
    const typeNames = {
      'user-agreement': '用户协议',
      'privacy-policy': '隐私政策',
      'service-terms': '服务条款',
      'other': '其他文档'
    }
    return typeNames[type as keyof typeof typeNames] || '未知类型'
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* 文档头部信息 */}
      <Card>
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center space-x-2">
              <FileText size={20} />
              <span>{metadata?.fileName || '文档预览'}</span>
            </CardTitle>
            
            <button
              onClick={onEdit}
              disabled={!canEdit}
              className={`
                inline-flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium
                transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2
                ${canEdit
                  ? 'bg-primary text-primary-foreground hover:bg-primary/90'
                  : 'bg-muted text-muted-foreground cursor-not-allowed'
                }
              `}
              title={canEdit ? '编辑文档' : '无法编辑'}
            >
              <Edit3 size={16} />
              <span>编辑文档</span>
            </button>
          </div>
        </CardHeader>

        <CardContent className="pt-0">
          {/* 文档元数据 */}
          {metadata && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6 p-4 bg-muted/30 rounded-lg">
              <div className="flex items-center space-x-2 text-sm">
                <Calendar size={16} className="text-muted-foreground" />
                <div>
                  <div className="font-medium">最后修改</div>
                  <div className="text-muted-foreground">{formatDate(metadata.lastModified)}</div>
                </div>
              </div>

              <div className="flex items-center space-x-2 text-sm">
                <HardDrive size={16} className="text-muted-foreground" />
                <div>
                  <div className="font-medium">文件大小</div>
                  <div className="text-muted-foreground">{formatFileSize(metadata.fileSize)}</div>
                </div>
              </div>

              <div className="flex items-center space-x-2 text-sm">
                <FileText size={16} className="text-muted-foreground" />
                <div>
                  <div className="font-medium">文档类型</div>
                  <div className="text-muted-foreground">{getDocumentTypeName(metadata.documentType)}</div>
                </div>
              </div>
            </div>
          )}

          {/* 重要提醒 */}
          <div className="flex items-start space-x-3 p-4 bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800/30 rounded-lg mb-6">
            <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-amber-800 dark:text-amber-200 mb-1">
                重要提醒
              </h4>
              <p className="text-sm text-amber-700 dark:text-amber-300 leading-relaxed">
                对此文档的任何修改都将直接影响用户端显示的法律条款。请确保修改内容符合法律法规要求，
                并在发布前仔细审核。修改后的内容将立即对所有用户生效。
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 文档内容 */}
      <MarkdownRenderer 
        content={content}
        className="min-h-[500px]"
      />

      {/* 底部操作区域 */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <div className="flex items-center space-x-4">
              <span>字符数: {content.length}</span>
              <span>行数: {content.split('\n').length}</span>
              {metadata && (
                <span>路径: {metadata.filePath}</span>
              )}
            </div>
            
            <div className="flex items-center space-x-4">
              {metadata?.lastModified && (
                <span>
                  上次更新: {formatDate(metadata.lastModified)}
                </span>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default DocumentViewer