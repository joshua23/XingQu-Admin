'use client'

import React, { useState, useEffect } from 'react'
import { X, Save, Eye, AlertCircle } from 'lucide-react'

interface AgreementEditModalProps {
  isOpen: boolean
  onClose: () => void
  initialContent: string
  version: string
  onSave: (newContent: string, newVersion: string) => Promise<boolean>
}

export function AgreementEditModal({
  isOpen,
  onClose,
  initialContent,
  version,
  onSave
}: AgreementEditModalProps) {
  const [content, setContent] = useState('')
  const [newVersion, setNewVersion] = useState('')
  const [isPreview, setIsPreview] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (isOpen) {
      setContent(initialContent)
      setNewVersion(version)
      setIsPreview(false)
      setError('')
    }
  }, [isOpen, initialContent, version])

  const handleSave = async () => {
    if (!content.trim()) {
      setError('协议内容不能为空')
      return
    }
    
    if (!newVersion.trim()) {
      setError('版本号不能为空')
      return
    }

    setSaving(true)
    setError('')

    try {
      const success = await onSave(content, newVersion)
      if (success) {
        onClose()
      } else {
        setError('保存失败，请重试')
      }
    } catch (err) {
      setError('保存过程中出现错误')
    } finally {
      setSaving(false)
    }
  }

  const formatPreviewContent = (content: string) => {
    if (!content) return ''
    
    // 处理原始文本内容，去掉行号前缀
    const cleanContent = content
      .split('\n')
      .map(line => {
        // 去掉行号前缀（例如 "1→"）
        return line.replace(/^\s*\d+→/, '').trim()
      })
      .join('\n')

    return cleanContent
      .split('\n')
      .map(line => {
        const trimmedLine = line.trim()
        
        if (!trimmedLine) {
          return '<div class="mb-2"></div>'
        }
        
        // 处理主标题
        if (trimmedLine === '星趣用户协议') {
          return `<h1 class="text-2xl font-bold text-foreground mb-4 text-center border-b-2 border-primary pb-3">${trimmedLine}</h1>`
        }
        
        // 处理更新日期
        if (trimmedLine.startsWith('更新日期：')) {
          return `<p class="text-center text-muted-foreground mb-6 font-medium">${trimmedLine}</p>`
        }
        
        // 处理"欢迎您使用星趣！"
        if (trimmedLine === '欢迎您使用星趣！') {
          return `<p class="text-center text-lg text-foreground mb-6 font-semibold">${trimmedLine}</p>`
        }
        
        // 处理章节标题（一、二、三、四...）
        if (trimmedLine.match(/^[一二三四五六七八九十]+、/)) {
          return `<h2 class="text-xl font-bold text-foreground mt-8 mb-4 border-l-4 border-primary pl-4 bg-primary/5 py-2">${trimmedLine}</h2>`
        }
        
        // 处理子标题
        if (trimmedLine === '特别提示' || trimmedLine === '平台自律公约' || trimmedLine === '星趣倡导的行为' || trimmedLine === '星趣禁止的行为') {
          return `<h3 class="text-lg font-bold text-foreground mt-6 mb-3 text-primary">${trimmedLine}</h3>`
        }
        
        // 处理编号小标题（1.1、1.3、2.1等）
        if (trimmedLine.match(/^\d+\.\d+/)) {
          return `<h4 class="text-base font-semibold text-foreground mt-4 mb-2 text-blue-600">${trimmedLine}</h4>`
        }
        
        // 处理列表项（(1)、(2)等）
        if (trimmedLine.match(/^（[一二三四五六七八九十\d]+）/) || trimmedLine.match(/^\(\d+\)/)) {
          const match = trimmedLine.match(/^（[^）]+）|^\([^)]+\)/)
          if (match) {
            return `<div class="ml-4 mb-2 text-sm leading-relaxed text-foreground"><span class="font-medium text-primary">${match[0]}</span> ${trimmedLine.replace(/^（[^）]+）|^\([^)]+\)\s*/, '')}</div>`
          }
        }
        
        // 处理普通段落
        if (trimmedLine.length > 0) {
          return `<p class="text-sm leading-relaxed text-foreground mb-3 text-justify">${trimmedLine}</p>`
        }
        
        return ''
      })
      .filter(line => line.length > 0)
      .join('')
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999] p-4">
      <div className="bg-card border border-border rounded-lg max-w-6xl w-full max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="p-6 border-b border-border flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-foreground">编辑用户协议</h2>
            <p className="text-sm text-muted-foreground mt-1">
              当前版本: {version} | 编辑后版本: {newVersion}
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setIsPreview(!isPreview)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors flex items-center space-x-2 ${
                isPreview 
                  ? 'bg-muted text-muted-foreground' 
                  : 'bg-primary text-primary-foreground hover:bg-primary/90'
              }`}
            >
              <Eye size={16} />
              <span>{isPreview ? '编辑模式' : '预览模式'}</span>
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-lg hover:bg-muted transition-colors"
            >
              <X size={20} className="text-muted-foreground" />
            </button>
          </div>
        </div>

        {/* Version Input */}
        <div className="p-6 border-b border-border">
          <div className="flex items-center space-x-4">
            <div className="flex-1">
              <label className="block text-sm font-medium text-foreground mb-2">
                新版本号
              </label>
              <input
                type="text"
                value={newVersion}
                onChange={(e) => setNewVersion(e.target.value)}
                placeholder="例如: v2.2"
                className="w-full px-3 py-2 bg-background border border-input rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
              />
            </div>
            {error && (
              <div className="flex items-center space-x-2 text-red-500 text-sm">
                <AlertCircle size={16} />
                <span>{error}</span>
              </div>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-hidden flex">
          {isPreview ? (
            /* Preview Mode */
            <div className="flex-1 overflow-y-auto p-6">
              <div className="prose prose-sm max-w-none">
                <div 
                  className="agreement-content"
                  dangerouslySetInnerHTML={{ 
                    __html: formatPreviewContent(content) 
                  }}
                />
              </div>
            </div>
          ) : (
            /* Edit Mode */
            <div className="flex-1 p-6">
              <label className="block text-sm font-medium text-foreground mb-3">
                协议内容 (支持纯文本格式)
              </label>
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="请输入协议内容..."
                className="w-full h-full resize-none bg-background border border-input rounded-lg p-4 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors font-mono text-sm"
                style={{ minHeight: '400px' }}
              />
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 border-t border-border flex items-center justify-between">
          <div className="text-sm text-muted-foreground">
            {isPreview ? '预览模式 - 查看协议最终显示效果' : '编辑模式 - 修改协议内容'}
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={onClose}
              disabled={saving}
              className="px-4 py-2 text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50"
            >
              取消
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 flex items-center space-x-2"
            >
              {saving ? (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              ) : (
                <Save size={16} />
              )}
              <span>{saving ? '保存中...' : '保存协议'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}