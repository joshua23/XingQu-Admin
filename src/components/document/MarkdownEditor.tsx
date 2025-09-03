import React, { useState, useRef, useEffect } from 'react'
import { Card, CardContent } from '../ui/Card'
import MarkdownRenderer from './MarkdownRenderer'
import { Eye, EyeOff, Type } from 'lucide-react'

interface MarkdownEditorProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
  disabled?: boolean
  rows?: number
}

export const MarkdownEditor: React.FC<MarkdownEditorProps> = ({
  value,
  onChange,
  placeholder = '开始编辑文档...',
  className = '',
  disabled = false,
  rows = 20
}) => {
  const [showPreview, setShowPreview] = useState(false)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  // 处理键盘快捷键
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (disabled) return

      // Ctrl/Cmd + S 保存（由父组件处理）
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault()
        // 触发自定义保存事件
        window.dispatchEvent(new CustomEvent('editor:save'))
      }

      // Ctrl/Cmd + P 切换预览
      if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
        e.preventDefault()
        setShowPreview(prev => !prev)
      }

      // F11 全屏切换
      if (e.key === 'F11') {
        e.preventDefault()
        setIsFullscreen(prev => !prev)
      }

      // Esc 退出全屏
      if (e.key === 'Escape' && isFullscreen) {
        setIsFullscreen(false)
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [disabled, isFullscreen])

  // 插入Markdown语法的辅助函数
  const insertMarkdown = (before: string, after: string = '') => {
    const textarea = textareaRef.current
    if (!textarea || disabled) return

    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const selectedText = value.substring(start, end)
    
    const newText = value.substring(0, start) + 
                   before + selectedText + after + 
                   value.substring(end)
    
    onChange(newText)

    // 恢复光标位置
    setTimeout(() => {
      textarea.focus()
      const newCursorPos = start + before.length + selectedText.length
      textarea.setSelectionRange(newCursorPos, newCursorPos)
    }, 0)
  }

  // 工具栏按钮组件
  const ToolbarButton: React.FC<{
    icon: React.ReactNode
    title: string
    onClick: () => void
    active?: boolean
  }> = ({ icon, title, onClick, active = false }) => (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      title={title}
      className={`p-2 rounded-md transition-colors ${
        active 
          ? 'bg-primary text-primary-foreground' 
          : 'hover:bg-muted text-muted-foreground hover:text-foreground'
      } disabled:opacity-50 disabled:cursor-not-allowed`}
    >
      {icon}
    </button>
  )

  const editorContent = (
    <>
      {/* 工具栏 */}
      <div className="flex items-center justify-between p-3 border-b border-border bg-muted/30">
        <div className="flex items-center space-x-1">
          <ToolbarButton
            icon={<Type size={16} />}
            title="标题 (Ctrl+1)"
            onClick={() => insertMarkdown('# ', '')}
          />
          <ToolbarButton
            icon={<strong>B</strong>}
            title="粗体 (Ctrl+B)"
            onClick={() => insertMarkdown('**', '**')}
          />
          <ToolbarButton
            icon={<em>I</em>}
            title="斜体 (Ctrl+I)"
            onClick={() => insertMarkdown('*', '*')}
          />
          <div className="w-px h-6 bg-border mx-2" />
          <ToolbarButton
            icon={showPreview ? <EyeOff size={16} /> : <Eye size={16} />}
            title={`${showPreview ? '隐藏' : '显示'}预览 (Ctrl+P)`}
            onClick={() => setShowPreview(!showPreview)}
            active={showPreview}
          />
        </div>
        
        <div className="flex items-center space-x-2 text-xs text-muted-foreground">
          <span>{value.length} 字符</span>
          <span>•</span>
          <span>{value.split('\n').length} 行</span>
        </div>
      </div>

      {/* 编辑区域 */}
      <div className={`flex h-full ${showPreview ? 'divide-x divide-border' : ''}`}>
        {/* 编辑器 */}
        <div className={`${showPreview ? 'w-1/2' : 'w-full'} flex flex-col`}>
          <textarea
            ref={textareaRef}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder={placeholder}
            disabled={disabled}
            rows={rows}
            className="flex-1 p-4 bg-transparent border-none outline-none resize-none
                     text-foreground placeholder-muted-foreground
                     font-mono text-sm leading-relaxed
                     focus:ring-0 focus:outline-none
                     disabled:cursor-not-allowed disabled:opacity-50"
            style={{
              minHeight: `${rows * 1.5}em`
            }}
          />
        </div>

        {/* 预览区域 */}
        {showPreview && (
          <div className="w-1/2 overflow-y-auto">
            <div className="p-4">
              <div className="prose prose-sm max-w-none">
                <MarkdownRenderer content={value} />
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  )

  if (isFullscreen) {
    return (
      <div className="fixed inset-0 z-50 bg-background">
        <Card className="h-full rounded-none border-0">
          <CardContent className="h-full p-0 flex flex-col">
            {editorContent}
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <Card className={`${className}`}>
      <CardContent className="p-0">
        <div className="h-96 flex flex-col">
          {editorContent}
        </div>
      </CardContent>
    </Card>
  )
}

export default MarkdownEditor