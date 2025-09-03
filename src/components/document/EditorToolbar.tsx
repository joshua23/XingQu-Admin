import React, { useEffect } from 'react'
import { Save, X, Eye, EyeOff, AlertCircle, Clock } from 'lucide-react'

interface EditorToolbarProps {
  onSave: () => void
  onCancel: () => void
  onTogglePreview: () => void
  canSave: boolean
  isSaving: boolean
  hasUnsavedChanges: boolean
  showPreview: boolean
  lastSaved?: Date | null
  className?: string
}

export const EditorToolbar: React.FC<EditorToolbarProps> = ({
  onSave,
  onCancel,
  onTogglePreview,
  canSave,
  isSaving,
  hasUnsavedChanges,
  showPreview,
  lastSaved,
  className = ''
}) => {
  // 监听键盘快捷键
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ctrl/Cmd + S 保存
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault()
        if (canSave && !isSaving) {
          onSave()
        }
      }

      // Ctrl/Cmd + P 切换预览
      if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
        e.preventDefault()
        onTogglePreview()
      }

      // Esc 取消编辑
      if (e.key === 'Escape') {
        if (hasUnsavedChanges) {
          const confirmed = window.confirm('您有未保存的更改，确定要取消编辑吗？')
          if (confirmed) {
            onCancel()
          }
        } else {
          onCancel()
        }
      }
    }

    // 监听自定义保存事件（从编辑器触发）
    const handleSaveEvent = () => {
      if (canSave && !isSaving) {
        onSave()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    window.addEventListener('editor:save', handleSaveEvent)

    return () => {
      window.removeEventListener('keydown', handleKeyDown)
      window.removeEventListener('editor:save', handleSaveEvent)
    }
  }, [canSave, isSaving, hasUnsavedChanges, onSave, onCancel, onTogglePreview])

  // 格式化最后保存时间
  const formatLastSaved = (date: Date | null) => {
    if (!date) return ''
    
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const minutes = Math.floor(diff / 60000)
    
    if (minutes < 1) return '刚刚保存'
    if (minutes === 1) return '1分钟前保存'
    if (minutes < 60) return `${minutes}分钟前保存`
    
    const hours = Math.floor(minutes / 60)
    if (hours === 1) return '1小时前保存'
    if (hours < 24) return `${hours}小时前保存`
    
    return date.toLocaleDateString()
  }

  return (
    <div className={`flex items-center justify-between p-3 bg-muted/30 border-b border-border ${className}`}>
      {/* 左侧控制按钮 */}
      <div className="flex items-center space-x-2">
        {/* 保存按钮 */}
        <button
          onClick={onSave}
          disabled={!canSave || isSaving}
          className={`
            inline-flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium
            transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2
            ${canSave && !isSaving
              ? 'bg-primary text-primary-foreground hover:bg-primary/90'
              : 'bg-muted text-muted-foreground cursor-not-allowed'
            }
          `}
          title="保存文档 (Ctrl+S)"
        >
          <Save size={16} className={isSaving ? 'animate-pulse' : ''} />
          <span>{isSaving ? '保存中...' : '保存'}</span>
        </button>

        {/* 取消按钮 */}
        <button
          onClick={onCancel}
          className="inline-flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium
                   bg-secondary text-secondary-foreground hover:bg-secondary/80
                   transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
          title="取消编辑 (Esc)"
        >
          <X size={16} />
          <span>取消</span>
        </button>

        {/* 分割线 */}
        <div className="w-px h-6 bg-border mx-2" />

        {/* 预览切换按钮 */}
        <button
          onClick={onTogglePreview}
          className={`
            inline-flex items-center space-x-2 px-3 py-2 rounded-md text-sm font-medium
            transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2
            ${showPreview
              ? 'bg-primary text-primary-foreground'
              : 'bg-secondary text-secondary-foreground hover:bg-secondary/80'
            }
          `}
          title={`${showPreview ? '隐藏' : '显示'}预览 (Ctrl+P)`}
        >
          {showPreview ? <EyeOff size={16} /> : <Eye size={16} />}
          <span>{showPreview ? '隐藏预览' : '显示预览'}</span>
        </button>
      </div>

      {/* 右侧状态信息 */}
      <div className="flex items-center space-x-4 text-sm text-muted-foreground">
        {/* 未保存更改提示 */}
        {hasUnsavedChanges && (
          <div className="flex items-center space-x-1 text-amber-600 dark:text-amber-400">
            <AlertCircle size={14} />
            <span>有未保存的更改</span>
          </div>
        )}

        {/* 最后保存时间 */}
        {lastSaved && (
          <div className="flex items-center space-x-1">
            <Clock size={14} />
            <span>{formatLastSaved(lastSaved)}</span>
          </div>
        )}

        {/* 键盘快捷键提示 */}
        <div className="hidden md:flex items-center space-x-3 text-xs">
          <span><kbd className="px-1.5 py-0.5 bg-muted rounded text-muted-foreground">Ctrl+S</kbd> 保存</span>
          <span><kbd className="px-1.5 py-0.5 bg-muted rounded text-muted-foreground">Ctrl+P</kbd> 预览</span>
          <span><kbd className="px-1.5 py-0.5 bg-muted rounded text-muted-foreground">Esc</kbd> 取消</span>
        </div>
      </div>
    </div>
  )
}

export default EditorToolbar