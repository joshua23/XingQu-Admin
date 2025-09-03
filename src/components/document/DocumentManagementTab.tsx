import React, { useEffect, useState } from 'react'
import { useDocumentState } from '../../hooks/useDocumentState'
import { documentService } from '../../services/documentService'
import DocumentViewer from './DocumentViewer'
import DocumentEditor from './DocumentEditor'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { FileText, AlertCircle, Loader2, RefreshCw } from 'lucide-react'

const DOCUMENT_PATH = '/docs/用户协议.md'

export const DocumentManagementTab: React.FC = () => {
  const [error, setError] = useState<string | null>(null)
  const [isInitializing, setIsInitializing] = useState(true)
  const [hasInitialized, setHasInitialized] = useState(false)

  // 使用文档状态管理Hook
  const { state, actions, computed } = useDocumentState({
    filePath: DOCUMENT_PATH,
    autoSave: true,
    autoSaveInterval: 5000
  })

  // 延迟初始化，只在组件实际需要时才加载
  useEffect(() => {
    if (hasInitialized) return

    const initialize = async () => {
      try {
        setIsInitializing(true)
        setError(null)
        
        // 预加载用户协议
        await documentService.preloadUserAgreement()
        
        // 加载文档
        await actions.loadDocument()
        
        setHasInitialized(true)
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : '初始化失败'
        setError(errorMessage)
        console.error('文档管理初始化失败:', err)
      } finally {
        setIsInitializing(false)
      }
    }

    // 延迟100ms再初始化，给UI时间渲染
    const timer = setTimeout(initialize, 100)
    return () => clearTimeout(timer)
  }, [actions.loadDocument, hasInitialized])

  // 处理编辑模式切换
  const handleStartEdit = () => {
    actions.clearError()
    actions.startEditing()
  }

  const handleCancelEdit = () => {
    actions.cancelEditing()
  }

  const handleSave = async () => {
    try {
      await actions.saveDocument()
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '保存失败'
      setError(errorMessage)
    }
  }

  const handleContentChange = (content: string) => {
    actions.updateContent(content)
  }

  const handleRetry = () => {
    setError(null)
    actions.clearError()
    actions.loadDocument()
  }

  // 如果正在初始化，显示加载状态
  if (isInitializing) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <div className="flex flex-col items-center space-y-4">
            <Loader2 size={32} className="animate-spin text-primary" />
            <div className="text-center">
              <div className="text-lg font-medium">正在加载文档管理</div>
              <div className="text-sm text-muted-foreground mt-1">
                正在初始化用户协议文档...
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  // 如果有初始化错误，显示错误状态
  if (error && !state.content && !state.isEditing) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2 text-destructive">
            <AlertCircle size={20} />
            <span>文档加载失败</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
              <p className="text-sm text-destructive">{error}</p>
            </div>
            
            <div className="flex items-center space-x-3">
              <button
                onClick={handleRetry}
                className="inline-flex items-center space-x-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
              >
                <RefreshCw size={16} />
                <span>重新加载</span>
              </button>
              
              <p className="text-sm text-muted-foreground">
                请检查文档文件是否存在于 docs/用户协议.md
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-primary/10 rounded-lg">
            <FileText size={24} className="text-primary" />
          </div>
          <div>
            <h2 className="text-xl font-semibold">隐私/用户协议管理</h2>
            <p className="text-sm text-muted-foreground">
              在线编辑和管理法律文档，修改将实时生效
            </p>
          </div>
        </div>

        {/* 状态指示器 */}
        <div className="flex items-center space-x-4 text-sm">
          {state.isLoading && (
            <div className="flex items-center space-x-2 text-muted-foreground">
              <Loader2 size={16} className="animate-spin" />
              <span>处理中...</span>
            </div>
          )}
          
          {computed.hasUnsavedChanges && !state.isLoading && (
            <div className="flex items-center space-x-2 text-amber-600 dark:text-amber-400">
              <div className="w-2 h-2 bg-amber-600 dark:bg-amber-400 rounded-full animate-pulse"></div>
              <span>有未保存的更改</span>
            </div>
          )}
          
          {!state.isEditing && !computed.hasUnsavedChanges && !state.isLoading && (
            <div className="flex items-center space-x-2 text-green-600 dark:text-green-400">
              <div className="w-2 h-2 bg-green-600 dark:bg-green-400 rounded-full"></div>
              <span>已同步</span>
            </div>
          )}
        </div>
      </div>

      {/* 文档内容区域 */}
      {state.isEditing ? (
        <DocumentEditor
          content={state.content}
          originalContent={state.originalContent}
          metadata={state.metadata}
          onChange={handleContentChange}
          onSave={handleSave}
          onCancel={handleCancelEdit}
          isSaving={state.isLoading}
          error={state.error}
          hasUnsavedChanges={computed.hasUnsavedChanges}
        />
      ) : (
        <DocumentViewer
          content={state.content}
          metadata={state.metadata}
          onEdit={handleStartEdit}
          canEdit={computed.canEdit}
        />
      )}

      {/* 功能说明 */}
      {!state.isEditing && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">功能说明</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div className="space-y-2">
                <h4 className="font-medium">支持的功能：</h4>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• 实时Markdown编辑和预览</li>
                  <li>• 自动保存草稿到本地</li>
                  <li>• 快捷键支持 (Ctrl+S, Ctrl+P)</li>
                  <li>• 文档版本信息显示</li>
                </ul>
              </div>
              <div className="space-y-2">
                <h4 className="font-medium">使用提醒：</h4>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• 修改将直接影响用户端显示</li>
                  <li>• 保存前请仔细检查内容</li>
                  <li>• 建议在重要修改前备份原文</li>
                  <li>• 支持标准Markdown语法</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

export default DocumentManagementTab