// 文档管理相关类型定义

// 文档类型枚举
export type DocumentType = 'user-agreement' | 'privacy-policy' | 'service-terms' | 'other'

// 文档元数据接口
export interface DocumentMetadata {
  fileName: string           // 文件名
  filePath: string          // 完整文件路径
  fileSize: number          // 文件大小（字节）
  lastModified: Date        // 最后修改时间
  createdAt: Date          // 创建时间
  documentType: DocumentType // 文档类型
}

// 文档状态接口
export interface DocumentState {
  content: string           // 当前内容
  originalContent: string   // 原始内容（用于检测是否有修改）
  isEditing: boolean       // 是否处于编辑状态
  isDirty: boolean         // 是否有未保存的修改
  isLoading: boolean       // 是否正在加载
  error: string | null     // 错误信息
  metadata: DocumentMetadata | null // 文档元数据
}

// Markdown验证结果接口
export interface ValidationResult {
  isValid: boolean         // 是否验证通过
  errors: string[]         // 错误信息列表
  warnings: string[]       // 警告信息列表
}

// 文档服务接口
export interface DocumentService {
  // 加载文档
  loadDocument(filePath: string): Promise<DocumentState>
  
  // 保存文档
  saveDocument(filePath: string, content: string): Promise<void>
  
  // 获取文档元数据
  getDocumentMetadata(filePath: string): Promise<DocumentMetadata>
  
  // 验证Markdown内容
  validateMarkdown(content: string): ValidationResult
  
  // 更新文档中的日期字段
  updateDocumentDate(content: string): string
}

// 编辑器配置接口
export interface EditorConfig {
  enablePreview: boolean    // 是否启用预览
  autoSave: boolean        // 是否自动保存
  saveInterval: number     // 自动保存间隔（毫秒）
  enableShortcuts: boolean // 是否启用键盘快捷键
}

// 文档操作事件接口
export interface DocumentEvent {
  type: 'load' | 'save' | 'edit' | 'cancel' | 'error'
  timestamp: Date
  filePath: string
  success?: boolean
  error?: string
}