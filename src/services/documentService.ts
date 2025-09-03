import { DocumentState, DocumentMetadata, DocumentType, ValidationResult, DocumentService } from '../types/document'

// 文档路径映射
const DOCUMENT_PATHS = {
  'user-agreement': '/docs/用户协议.md',
  'privacy-policy': '/docs/隐私政策.md',
  'service-terms': '/docs/服务条款.md'
} as const

// 获取文档类型
function getDocumentType(filePath: string): DocumentType {
  if (filePath.includes('用户协议') || filePath.includes('user-agreement')) {
    return 'user-agreement'
  }
  if (filePath.includes('隐私政策') || filePath.includes('privacy-policy')) {
    return 'privacy-policy'
  }
  if (filePath.includes('服务条款') || filePath.includes('service-terms')) {
    return 'service-terms'
  }
  return 'other'
}

// 验证Markdown内容
function validateMarkdown(content: string): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  // 检查基本结构
  if (!content.trim()) {
    errors.push('文档内容不能为空')
    return { isValid: false, errors, warnings }
  }

  // 检查是否有标题
  if (!content.includes('#')) {
    warnings.push('建议添加标题结构')
  }

  // 检查日期格式
  const dateRegex = /更新日期[:：]\s*\d{4}年\d{1,2}月\d{1,2}日/
  if (!dateRegex.test(content)) {
    warnings.push('建议添加或更新"更新日期"字段')
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  }
}

// 更新文档中的日期
function updateDocumentDate(content: string): string {
  const today = new Date()
  const dateString = `${today.getFullYear()}年${today.getMonth() + 1}月${today.getDate()}日`
  
  // 替换现有日期格式
  const dateRegex = /更新日期[:：]\s*\d{4}年\d{1,2}月\d{1,2}日/
  if (dateRegex.test(content)) {
    return content.replace(dateRegex, `更新日期：${dateString}`)
  }
  
  // 如果没有日期字段，在开头添加
  const lines = content.split('\n')
  if (lines.length > 0 && lines[0].startsWith('#')) {
    lines.splice(1, 0, '', `更新日期：${dateString}`)
    return lines.join('\n')
  }
  
  return `更新日期：${dateString}\n\n${content}`
}

// 模拟文件系统操作（在实际项目中需要根据具体环境调整）
class DocumentServiceImpl implements DocumentService {
  private cache = new Map<string, string>()

  async loadDocument(filePath: string): Promise<DocumentState> {
    try {
      // 在Web环境中，我们需要通过HTTP请求获取文档内容
      // 这里先模拟从缓存或API获取
      let content = this.cache.get(filePath)
      
      if (!content) {
        // 尝试从public目录加载文件
        const response = await fetch(filePath)
        if (!response.ok) {
          throw new Error(`无法加载文档: ${response.statusText}`)
        }
        content = await response.text()
        this.cache.set(filePath, content)
      }

      const metadata = await this.getDocumentMetadata(filePath)

      return {
        content,
        originalContent: content,
        isEditing: false,
        isDirty: false,
        isLoading: false,
        error: null,
        metadata
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '加载文档失败'
      
      return {
        content: '',
        originalContent: '',
        isEditing: false,
        isDirty: false,
        isLoading: false,
        error: errorMessage,
        metadata: null
      }
    }
  }

  async saveDocument(filePath: string, content: string): Promise<void> {
    try {
      // 验证内容
      const validation = this.validateMarkdown(content)
      if (!validation.isValid) {
        throw new Error(`文档验证失败: ${validation.errors.join(', ')}`)
      }

      // 更新日期
      const updatedContent = this.updateDocumentDate(content)

      // 在Web环境中，保存操作需要通过API端点
      // 这里先更新缓存
      this.cache.set(filePath, updatedContent)


    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '保存文档失败'
      throw new Error(errorMessage)
    }
  }

  async getDocumentMetadata(filePath: string): Promise<DocumentMetadata> {
    const fileName = filePath.split('/').pop() || 'unknown'
    const content = this.cache.get(filePath) || ''
    
    return {
      fileName,
      filePath,
      fileSize: new Blob([content]).size,
      lastModified: new Date(),
      createdAt: new Date('2025-01-01'), // 默认创建时间
      documentType: getDocumentType(filePath)
    }
  }

  validateMarkdown(content: string): ValidationResult {
    return validateMarkdown(content)
  }

  updateDocumentDate(content: string): string {
    return updateDocumentDate(content)
  }

  // 获取可用文档列表
  getAvailableDocuments(): Array<{ type: DocumentType; path: string; name: string }> {
    return [
      { type: 'user-agreement', path: DOCUMENT_PATHS['user-agreement'], name: '用户协议' },
      { type: 'privacy-policy', path: DOCUMENT_PATHS['privacy-policy'], name: '隐私政策' },
      { type: 'service-terms', path: DOCUMENT_PATHS['service-terms'], name: '服务条款' }
    ]
  }

  // 预加载用户协议文档（从现有文件）
  async preloadUserAgreement(): Promise<void> {
    try {
      // 从docs文件夹预加载用户协议内容
      const userAgreementPath = DOCUMENT_PATHS['user-agreement']
      
      // 在实际应用中，这里应该从服务器获取文件内容
      // 目前我们从已知的文档内容开始
      const content = `星趣用户协议

更新日期：2025年9月1日
欢迎您使用星趣！

特别提示

为了更好地为您提供服务，请您在开始使用星趣产品和服务之前，认真阅读并充分理解《星趣用户协议》（"本协议"或"用户协议"）及《星趣隐私政策》（"隐私政策"），特别是涉及免除或者限制责任的条款、权利许可和信息使用的条款、同意开通和使用特殊单项服务的条款、法律适用和争议解决条款等。该等内容将以加粗和/或划线形式提示您注意，您应重点阅读。

您点击确认本协议、以其他方式同意本协议或实际使用星趣产品和服务的，即表示您同意、接受并承诺遵守本协议的全部内容。`

      this.cache.set(userAgreementPath, content)
    } catch (error) {
      console.warn('预加载用户协议失败:', error)
    }
  }
}

// 导出单例实例
export const documentService = new DocumentServiceImpl()

// 初始化时预加载用户协议
documentService.preloadUserAgreement()

export default documentService