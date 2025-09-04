'use client'

import React, { useState } from 'react'
import { FileText, X, Edit } from 'lucide-react'
import { AgreementEditModal } from '@/components/modals/AgreementEditModal'

interface UserAgreementTooltipProps {
  agreementContent: string
  version?: string
  accepted?: boolean
  onContentUpdate?: (newContent: string, newVersion: string) => void
}

export function UserAgreementTooltip({ 
  agreementContent, 
  version = 'v2.1', 
  accepted = true,
  onContentUpdate
}: UserAgreementTooltipProps) {
  const [isVisible, setIsVisible] = useState(false)
  const [showFullModal, setShowFullModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)

  const formatAgreementContent = (content: string, isPreview: boolean = false) => {
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
          return isPreview ? '' : '<div class="mb-2"></div>'
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
        
        // 处理子标题（特别提示、平台自律公约等）
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
          const className = isPreview 
            ? "text-xs leading-relaxed text-foreground mb-2" 
            : "text-sm leading-relaxed text-foreground mb-3 text-justify"
          return `<p class="${className}">${trimmedLine}</p>`
        }
        
        return ''
      })
      .filter(line => line.length > 0)
      .join('')
  }

  const handleEdit = () => {
    setShowFullModal(false)
    setIsVisible(false)
    setShowEditModal(true)
  }

  const handleSaveAgreement = async (newContent: string, newVersion: string) => {
    try {
      if (onContentUpdate) {
        onContentUpdate(newContent, newVersion)
      }
      return true
    } catch (error) {
      console.error('Error saving agreement:', error)
      return false
    }
  }

  return (
    <div className="relative inline-block">
      <div
        className="inline-flex items-center cursor-pointer"
        onMouseEnter={() => setIsVisible(true)}
        onMouseLeave={() => setIsVisible(false)}
        onClick={() => setShowFullModal(true)}
      >
        <div className="flex items-center space-x-1">
          {accepted ? (
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-success/10 text-success border border-success/20">
              已同意 {version}
            </span>
          ) : (
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-warning/10 text-warning border border-warning/20">
              未同意
            </span>
          )}
          <FileText size={14} className="text-primary hover:text-primary/80 transition-colors" />
        </div>
      </div>

      {/* 悬浮预览 */}
      {isVisible && (
        <div 
          className="absolute z-50 left-0 top-full mt-2 w-80 bg-card border border-border rounded-lg shadow-xl p-4 max-h-96 overflow-y-auto transform transition-all duration-200 ease-out"
          style={{ 
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            zIndex: 1000 
          }}
          onMouseEnter={() => setIsVisible(true)}
          onMouseLeave={() => setIsVisible(false)}
        >
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center space-x-2">
              <FileText size={16} className="text-primary" />
              <span className="font-medium text-foreground">用户协议预览</span>
            </div>
            <button
              onClick={() => setShowFullModal(true)}
              className="text-xs text-primary hover:text-primary/80 transition-colors"
            >
              查看完整内容
            </button>
          </div>
          
          <div className="text-xs text-muted-foreground mb-3">
            版本: {version} | 状态: {accepted ? '已同意' : '未同意'}
          </div>
          
          <div className="prose prose-sm max-w-none">
            <div 
              className="text-xs leading-relaxed"
              dangerouslySetInnerHTML={{ 
                __html: formatAgreementContent(agreementContent.substring(0, 800) + '...', true) 
              }}
            />
          </div>
          
          <div className="mt-3 pt-2 border-t border-border">
            <button
              onClick={() => setShowFullModal(true)}
              className="text-xs text-primary hover:text-primary/80 font-medium"
            >
              点击查看完整协议内容 →
            </button>
          </div>
        </div>
      )}

      {/* 完整协议模态框 */}
      {showFullModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4" style={{ zIndex: 9999 }}>
          <div className="bg-card border border-border rounded-lg max-w-4xl w-full max-h-[90vh] flex flex-col">
            {/* Header */}
            <div className="p-6 border-b border-border flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-foreground">星趣用户协议</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  版本: {version} | 更新日期: 2025年9月1日 | 状态: {accepted ? '已同意' : '未同意'}
                </p>
              </div>
              <button
                onClick={() => setShowFullModal(false)}
                className="p-2 rounded-lg hover:bg-muted transition-colors"
              >
                <X size={20} className="text-muted-foreground" />
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-6">
              <div className="prose prose-sm max-w-none">
                <div 
                  className="agreement-content"
                  dangerouslySetInnerHTML={{ 
                    __html: formatAgreementContent(agreementContent, false) 
                  }}
                />
              </div>
            </div>

            {/* Footer */}
            <div className="p-6 border-t border-border flex items-center justify-between">
              <div className="text-sm text-muted-foreground">
                如对本协议内容有任何疑问，请发送邮件至 report@xingquai.com
              </div>
              <div className="flex items-center space-x-3">
                <button
                  onClick={() => setShowFullModal(false)}
                  className="px-4 py-2 text-muted-foreground hover:text-foreground transition-colors"
                >
                  关闭
                </button>
                <button className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
                  打印协议
                </button>
                <button 
                  onClick={handleEdit}
                  className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors flex items-center space-x-2"
                >
                  <Edit size={16} />
                  <span>编辑文档</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 编辑模态框 */}
      <AgreementEditModal
        isOpen={showEditModal}
        onClose={() => setShowEditModal(false)}
        initialContent={agreementContent}
        version={version}
        onSave={handleSaveAgreement}
      />
    </div>
  )
}