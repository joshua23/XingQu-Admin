import { useState, useEffect, useCallback, useRef, useMemo } from 'react'
import { DocumentState } from '../types/document'
import { documentService } from '../services/documentService'

// localStorage键名
const DRAFT_STORAGE_KEY = 'document-draft-'
const AUTO_SAVE_INTERVAL = 5000 // 5秒自动保存草稿

interface UseDocumentStateOptions {
  filePath: string
  autoSave?: boolean
  autoSaveInterval?: number
}

interface UseDocumentStateReturn {
  state: DocumentState
  actions: {
    loadDocument: () => Promise<void>
    saveDocument: () => Promise<void>
    startEditing: () => void
    cancelEditing: () => void
    updateContent: (content: string) => void
    clearError: () => void
  }
  computed: {
    hasUnsavedChanges: boolean
    canSave: boolean
    canEdit: boolean
  }
}

export function useDocumentState(options: UseDocumentStateOptions): UseDocumentStateReturn {
  const { filePath, autoSave = true, autoSaveInterval = AUTO_SAVE_INTERVAL } = options
  
  // 文档状态
  const [state, setState] = useState<DocumentState>({
    content: '',
    originalContent: '',
    isEditing: false,
    isDirty: false,
    isLoading: false,
    error: null,
    metadata: null
  })

  // 自动保存定时器引用
  const autoSaveTimer = useRef<NodeJS.Timeout | null>(null)

  // 获取草稿存储键
  const getDraftKey = useCallback(() => `${DRAFT_STORAGE_KEY}${filePath}`, [filePath])

  // 从localStorage加载草稿
  const loadDraft = useCallback(() => {
    try {
      const draftContent = localStorage.getItem(getDraftKey())
      return draftContent || null
    } catch (error) {
      console.warn('Failed to load draft from localStorage:', error)
      return null
    }
  }, [getDraftKey])

  // 保存草稿到localStorage
  const saveDraft = useCallback((content: string) => {
    if (!autoSave) return
    
    try {
      localStorage.setItem(getDraftKey(), content)
    } catch (error) {
      console.warn('Failed to save draft to localStorage:', error)
    }
  }, [getDraftKey, autoSave])

  // 清除草稿
  const clearDraft = useCallback(() => {
    try {
      localStorage.removeItem(getDraftKey())
    } catch (error) {
      console.warn('Failed to clear draft from localStorage:', error)
    }
  }, [getDraftKey])

  // 设置自动保存定时器
  const setAutoSaveTimer = useCallback(() => {
    if (!autoSave || !state.isDirty || !state.isEditing) return

    if (autoSaveTimer.current) {
      clearTimeout(autoSaveTimer.current)
    }

    autoSaveTimer.current = setTimeout(() => {
      saveDraft(state.content)
    }, autoSaveInterval)
  }, [autoSave, state.isDirty, state.isEditing, state.content, saveDraft, autoSaveInterval])

  // 加载文档
  const loadDocument = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      const documentState = await documentService.loadDocument(filePath)
      
      // 检查是否有草稿
      const draft = loadDraft()
      const content = draft || documentState.content
      const isDirty = draft !== null && draft !== documentState.content

      setState({
        ...documentState,
        content,
        isDirty,
        isLoading: false
      })
    } catch (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : '加载文档失败'
      }))
    }
  }, [filePath, loadDraft])

  // 保存文档
  const saveDocument = useCallback(async () => {
    if (!state.isDirty || state.isLoading) return

    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      await documentService.saveDocument(filePath, state.content)
      
      // 更新状态
      setState(prev => ({
        ...prev,
        originalContent: prev.content,
        isDirty: false,
        isLoading: false,
        isEditing: false
      }))

      // 清除草稿
      clearDraft()
      
      // 清除自动保存定时器
      if (autoSaveTimer.current) {
        clearTimeout(autoSaveTimer.current)
        autoSaveTimer.current = null
      }
    } catch (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : '保存文档失败'
      }))
    }
  }, [filePath, state.content, state.isDirty, state.isLoading, clearDraft])

  // 开始编辑
  const startEditing = useCallback(() => {
    setState(prev => ({ ...prev, isEditing: true }))
  }, [])

  // 取消编辑
  const cancelEditing = useCallback(() => {
    setState(prev => ({
      ...prev,
      content: prev.originalContent,
      isEditing: false,
      isDirty: false
    }))
    
    // 清除草稿
    clearDraft()
    
    // 清除自动保存定时器
    if (autoSaveTimer.current) {
      clearTimeout(autoSaveTimer.current)
      autoSaveTimer.current = null
    }
  }, [clearDraft])

  // 更新内容
  const updateContent = useCallback((content: string) => {
    setState(prev => ({
      ...prev,
      content,
      isDirty: content !== prev.originalContent
    }))
  }, [])

  // 清除错误
  const clearError = useCallback(() => {
    setState(prev => ({ ...prev, error: null }))
  }, [])

  // 自动保存逻辑
  useEffect(() => {
    if (state.isEditing && state.isDirty) {
      setAutoSaveTimer()
    }
    
    return () => {
      if (autoSaveTimer.current) {
        clearTimeout(autoSaveTimer.current)
      }
    }
  }, [state.isEditing, state.isDirty, setAutoSaveTimer])

  // 初始加载
  useEffect(() => {
    if (filePath) {
      loadDocument()
    }
  }, [filePath, loadDocument])

  // 页面卸载时保存草稿
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (state.isDirty && state.isEditing) {
        saveDraft(state.content)
        // 显示确认对话框
        e.preventDefault()
        e.returnValue = '您有未保存的更改，确定要离开吗？'
        return '您有未保存的更改，确定要离开吗？'
      }
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    
    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload)
      // 保存草稿
      if (state.isDirty && state.isEditing) {
        saveDraft(state.content)
      }
    }
  }, [state.isDirty, state.isEditing, state.content, saveDraft])

  // 计算属性 - 移除未使用的变量

  // 使用 useMemo 优化 actions 和 computed 对象
  const actions = useMemo(() => ({
    loadDocument,
    saveDocument,
    startEditing,
    cancelEditing,
    updateContent,
    clearError
  }), [loadDocument, saveDocument, startEditing, cancelEditing, updateContent, clearError])

  const computedMemo = useMemo(() => ({
    hasUnsavedChanges: state.isDirty,
    canSave: state.isDirty && !state.isLoading && !state.error,
    canEdit: !state.isLoading && !state.error
  }), [state.isDirty, state.isLoading, state.error])

  return {
    state,
    actions,
    computed: computedMemo
  }
}