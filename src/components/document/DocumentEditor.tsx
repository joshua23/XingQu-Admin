import React, { useState } from 'react'
import { Card, CardContent } from '../ui/Card'
import { DocumentMetadata } from '../../types/document'
import MarkdownEditor from './MarkdownEditor'
import EditorToolbar from './EditorToolbar'
import { AlertTriangle, CheckCircle } from 'lucide-react'

interface DocumentEditorProps {
  content: string
  originalContent: string
  metadata: DocumentMetadata | null
  onChange: (content: string) => void
  onSave: () => Promise<void>
  onCancel: () => void
  isSaving: boolean
  error: string | null
  hasUnsavedChanges: boolean
  className?: string
}

export const DocumentEditor: React.FC<DocumentEditorProps> = ({
  content,
  originalContent,
  metadata,
  onChange,
  onSave,
  onCancel,
  isSaving,
  error,
  hasUnsavedChanges,
  className = ''
}) => {
  const [showPreview, setShowPreview] = useState(false)
  const [saveSuccess, setSaveSuccess] = useState(false)
  const [lastSaved, setLastSaved] = useState<Date | null>(null)

  // 处理保存操作
  const handleSave = async () => {
    try {
      setSaveSuccess(false)
      await onSave()
      setLastSaved(new Date())
      setSaveSuccess(true)
      
      // 3秒后隐藏成功提示
      setTimeout(() => setSaveSuccess(false), 3000)
    } catch (error) {
      console.error('保存失败:', error)
      // 错误处理由父组件通过error prop处理
    }
  }

  // 处理取消编辑
  const handleCancel = () => {
    if (hasUnsavedChanges) {
      const confirmed = window.confirm(
        '您有未保存的更改，确定要取消编辑吗？所有更改将会丢失。'
      )
      if (confirmed) {
        onCancel()
      }
    } else {
      onCancel()
    }
  }

  // 切换预览模式
  const handleTogglePreview = () => {
    setShowPreview(prev => !prev)
  }

  // 计算编辑器属性
  const canSave = hasUnsavedChanges && !isSaving && !error

  return (
    <div className={`space-y-4 ${className}`}>
      {/* 成功提示 */}
      {saveSuccess && (
        <div className="flex items-center space-x-2 p-3 bg-green-50 dark:bg-green-950/20 border border-green-200 dark:border-green-800/30 rounded-lg text-green-800 dark:text-green-200">
          <CheckCircle size={16} />
          <span className="text-sm">文档保存成功！</span>
        </div>
      )}

      {/* 错误提示 */}
      {error && (
        <div className="flex items-start space-x-2 p-3 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800/30 rounded-lg text-red-800 dark:text-red-200">
          <AlertTriangle size={16} className="mt-0.5 flex-shrink-0" />
          <div>
            <div className="text-sm font-medium">保存失败</div>
            <div className="text-sm mt-1">{error}</div>
          </div>
        </div>
      )}

      {/* 编辑器主体 */}
      <Card className="overflow-hidden">
        <CardContent className="p-0">
          {/* 工具栏 */}
          <EditorToolbar
            onSave={handleSave}
            onCancel={handleCancel}
            onTogglePreview={handleTogglePreview}
            canSave={canSave}
            isSaving={isSaving}
            hasUnsavedChanges={hasUnsavedChanges}
            showPreview={showPreview}
            lastSaved={lastSaved}
          />

          {/* 编辑器 */}
          <div className="relative">
            {/* 加载遮罩 */}
            {isSaving && (
              <div className="absolute inset-0 bg-background/50 backdrop-blur-sm z-10 flex items-center justify-center">
                <div className="flex items-center space-x-2 bg-background border border-border rounded-lg px-4 py-2 shadow-lg">
                  <div className="animate-spin rounded-full h-4 w-4 border-2 border-primary border-top-transparent"></div>
                  <span className="text-sm">正在保存文档...</span>
                </div>
              </div>
            )}

            {/* Markdown 编辑器 */}
            <MarkdownEditor
              value={content}
              onChange={onChange}
              placeholder="开始编辑您的文档内容..."
              rows={25}
              disabled={isSaving}
            />
          </div>
        </CardContent>
      </Card>

      {/* 编辑提示信息 */}
      <div className="flex items-start space-x-3 p-4 bg-blue-50 dark:bg-blue-950/20 border border-blue-200 dark:border-blue-800/30 rounded-lg">
        <AlertTriangle size={20} className="text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
        <div className="text-sm text-blue-800 dark:text-blue-200">
          <div className="font-medium mb-1">编辑提醒</div>
          <ul className="space-y-1 text-blue-700 dark:text-blue-300">
            <li>• 支持标准 Markdown 语法，包括标题、粗体、斜体、链接等</li>
            <li>• 使用 <kbd className="px-1 bg-blue-100 dark:bg-blue-900 rounded">Ctrl+S</kbd> 快速保存，<kbd className="px-1 bg-blue-100 dark:bg-blue-900 rounded">Ctrl+P</kbd> 切换预览</li>
            <li>• 内容会自动保存草稿到本地，避免意外丢失</li>
            <li>• 保存时会自动更新文档顶部的"更新日期"字段</li>
          </ul>
        </div>
      </div>

      {/* 文档统计信息 */}
      {metadata && (
        <Card>
          <CardContent className="py-3">
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <div className="flex items-center space-x-4">
                <span>原始内容: {originalContent.length} 字符</span>
                <span>当前内容: {content.length} 字符</span>
                <span>变化: {content.length - originalContent.length > 0 ? '+' : ''}{content.length - originalContent.length}</span>
              </div>
              <div className="flex items-center space-x-4">
                <span>文件: {metadata.fileName}</span>
                {hasUnsavedChanges && (
                  <span className="text-amber-600 dark:text-amber-400 font-medium">● 未保存</span>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

export default DocumentEditor