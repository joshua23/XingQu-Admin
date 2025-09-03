import React from 'react'
import { Card, CardContent } from '../ui/Card'

interface MarkdownRendererProps {
  content: string
  className?: string
}

// 简单的Markdown渲染器（避免引入额外依赖）
function parseMarkdown(content: string): string {
  let html = content
    // 标题处理
    .replace(/^### (.*$)/gm, '<h3 class="text-lg font-semibold mt-6 mb-3 text-foreground">$1</h3>')
    .replace(/^## (.*$)/gm, '<h2 class="text-xl font-semibold mt-8 mb-4 text-foreground">$1</h2>')
    .replace(/^# (.*$)/gm, '<h1 class="text-2xl font-bold mt-8 mb-6 text-foreground">$1</h1>')
    
    // 粗体和斜体
    .replace(/\*\*(.*?)\*\*/g, '<strong class="font-semibold">$1</strong>')
    .replace(/\*(.*?)\*/g, '<em class="italic">$1</em>')
    
    // 链接
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="text-primary hover:text-primary/80 underline" target="_blank" rel="noopener noreferrer">$1</a>')
    
    // 行内代码
    .replace(/`([^`]+)`/g, '<code class="bg-muted px-1.5 py-0.5 rounded text-sm font-mono">$1</code>')
    
    // 列表项
    .replace(/^\* (.+)$/gm, '<li class="mb-1">$1</li>')
    .replace(/^\d+\. (.+)$/gm, '<li class="mb-1">$1</li>')
    
    // 水平分割线
    .replace(/^---$/gm, '<hr class="my-6 border-border" />')
    
    // 段落处理（将连续的非HTML行包装为段落）
    .split('\n')
    .map(line => {
      const trimmedLine = line.trim()
      if (!trimmedLine) return '<br />'
      if (trimmedLine.startsWith('<')) return line
      if (trimmedLine.match(/^#{1,6}\s/)) return line
      if (trimmedLine.startsWith('* ') || trimmedLine.match(/^\d+\.\s/)) return line
      if (trimmedLine === '---') return line
      return `<p class="mb-3 text-foreground leading-relaxed">${line}</p>`
    })
    .join('\n')
    
    // 包装列表
    .replace(/(<li[^>]*>.*?<\/li>)\s*(?=<li|$)/gs, (match) => {
      return `<ul class="list-disc list-inside ml-4 mb-4 space-y-1">${match}</ul>`
    })

  return html
}

export const MarkdownRenderer: React.FC<MarkdownRendererProps> = ({
  content,
  className = ''
}) => {
  const htmlContent = parseMarkdown(content)

  return (
    <Card className={`overflow-hidden ${className}`}>
      <CardContent className="p-6">
        <div 
          className="prose prose-slate dark:prose-invert max-w-none
                     prose-headings:text-foreground prose-p:text-foreground
                     prose-strong:text-foreground prose-em:text-muted-foreground
                     prose-code:bg-muted prose-code:text-foreground prose-code:px-1 prose-code:py-0.5 prose-code:rounded
                     prose-a:text-primary prose-a:no-underline hover:prose-a:underline
                     prose-blockquote:border-l-border prose-blockquote:text-muted-foreground
                     prose-hr:border-border"
          dangerouslySetInnerHTML={{ __html: htmlContent }}
        />
      </CardContent>
    </Card>
  )
}

export default MarkdownRenderer