import { renderHook, act } from '@testing-library/react'
import { useDocumentState } from '../useDocumentState'

// Mock localStorage
const mockLocalStorage = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn()
}

Object.defineProperty(window, 'localStorage', {
  value: mockLocalStorage
})

describe('useDocumentState', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should initialize with default state', () => {
    const { result } = renderHook(() => useDocumentState())
    
    expect(result.current.state).toBe('idle')
    expect(result.current.content).toBe('')
    expect(result.current.originalContent).toBe('')
    expect(result.current.hasUnsavedChanges).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('should load document content', async () => {
    const mockContent = '# Test Document\nContent here'
    const { result } = renderHook(() => useDocumentState())
    
    await act(async () => {
      await result.current.loadDocument(mockContent)
    })
    
    expect(result.current.state).toBe('loaded')
    expect(result.current.content).toBe(mockContent)
    expect(result.current.originalContent).toBe(mockContent)
    expect(result.current.hasUnsavedChanges).toBe(false)
  })

  it('should handle loading errors', async () => {
    const { result } = renderHook(() => useDocumentState())
    
    await act(async () => {
      try {
        throw new Error('Load failed')
      } catch (error) {
        result.current.setError(error as Error)
      }
    })
    
    expect(result.current.state).toBe('error')
    expect(result.current.error?.message).toBe('Load failed')
  })

  it('should update content and track changes', () => {
    const { result } = renderHook(() => useDocumentState())
    const originalContent = '# Original'
    const newContent = '# Modified'
    
    act(() => {
      result.current.loadDocument(originalContent)
    })
    
    act(() => {
      result.current.updateContent(newContent)
    })
    
    expect(result.current.content).toBe(newContent)
    expect(result.current.hasUnsavedChanges).toBe(true)
  })

  it('should save document and update state', async () => {
    const { result } = renderHook(() => useDocumentState())
    const content = '# Test Document'
    
    await act(async () => {
      await result.current.loadDocument(content)
    })
    
    act(() => {
      result.current.updateContent('# Modified Document')
    })
    
    await act(async () => {
      await result.current.saveDocument()
    })
    
    expect(result.current.state).toBe('saved')
    expect(result.current.hasUnsavedChanges).toBe(false)
    expect(result.current.originalContent).toBe('# Modified Document')
  })

  it('should handle save errors', async () => {
    const { result } = renderHook(() => useDocumentState())
    
    await act(async () => {
      await result.current.loadDocument('# Test')
    })
    
    act(() => {
      result.current.updateContent('# Modified')
    })
    
    await act(async () => {
      try {
        throw new Error('Save failed')
      } catch (error) {
        result.current.setError(error as Error)
      }
    })
    
    expect(result.current.state).toBe('error')
    expect(result.current.error?.message).toBe('Save failed')
  })

  it('should cancel editing and revert changes', () => {
    const { result } = renderHook(() => useDocumentState())
    const originalContent = '# Original'
    
    act(() => {
      result.current.loadDocument(originalContent)
    })
    
    act(() => {
      result.current.updateContent('# Modified')
    })
    
    expect(result.current.hasUnsavedChanges).toBe(true)
    
    act(() => {
      result.current.cancelEdit()
    })
    
    expect(result.current.content).toBe(originalContent)
    expect(result.current.hasUnsavedChanges).toBe(false)
    expect(result.current.state).toBe('loaded')
  })

  it('should clear error state', () => {
    const { result } = renderHook(() => useDocumentState())
    
    act(() => {
      result.current.setError(new Error('Test error'))
    })
    
    expect(result.current.error).toBeTruthy()
    expect(result.current.state).toBe('error')
    
    act(() => {
      result.current.clearError()
    })
    
    expect(result.current.error).toBeNull()
    expect(result.current.state).toBe('idle')
  })

  it('should persist drafts to localStorage', () => {
    const { result } = renderHook(() => useDocumentState())
    const draftKey = 'document-draft'
    
    act(() => {
      result.current.loadDocument('# Original')
    })
    
    act(() => {
      result.current.updateContent('# Draft content')
    })
    
    // Simulate draft saving
    act(() => {
      result.current.saveDraft(draftKey)
    })
    
    expect(mockLocalStorage.setItem).toHaveBeenCalledWith(
      draftKey,
      '# Draft content'
    )
  })

  it('should load drafts from localStorage', () => {
    const draftKey = 'document-draft'
    const draftContent = '# Draft content'
    
    mockLocalStorage.getItem.mockReturnValue(draftContent)
    
    const { result } = renderHook(() => useDocumentState())
    
    act(() => {
      result.current.loadDraft(draftKey)
    })
    
    expect(result.current.content).toBe(draftContent)
    expect(mockLocalStorage.getItem).toHaveBeenCalledWith(draftKey)
  })

  it('should clear drafts from localStorage', () => {
    const draftKey = 'document-draft'
    const { result } = renderHook(() => useDocumentState())
    
    act(() => {
      result.current.clearDraft(draftKey)
    })
    
    expect(mockLocalStorage.removeItem).toHaveBeenCalledWith(draftKey)
  })

  it('should handle state transitions correctly', async () => {
    const { result } = renderHook(() => useDocumentState())
    
    // idle -> loading -> loaded
    expect(result.current.state).toBe('idle')
    
    await act(async () => {
      await result.current.loadDocument('# Test')
    })
    
    expect(result.current.state).toBe('loaded')
    
    // loaded -> editing -> saving -> saved
    act(() => {
      result.current.updateContent('# Modified')
    })
    
    expect(result.current.state).toBe('editing')
    
    await act(async () => {
      await result.current.saveDocument()
    })
    
    expect(result.current.state).toBe('saved')
  })
})