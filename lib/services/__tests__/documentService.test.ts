import { documentService } from '../documentService'
import * as fs from 'fs/promises'
import * as path from 'path'

// Mock fs module
jest.mock('fs/promises')

const mockFs = fs as jest.Mocked<typeof fs>

describe('DocumentService', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('loadDocument', () => {
    it('should load document successfully', async () => {
      const mockContent = '# Privacy Policy\n\nThis is a test document.'
      mockFs.readFile.mockResolvedValue(mockContent)
      
      const result = await documentService.loadDocument('/path/to/document.md')
      
      expect(result).toBe(mockContent)
      expect(mockFs.readFile).toHaveBeenCalledWith('/path/to/document.md', 'utf-8')
    })

    it('should throw error when file cannot be read', async () => {
      const error = new Error('File not found')
      mockFs.readFile.mockRejectedValue(error)
      
      await expect(documentService.loadDocument('/invalid/path.md'))
        .rejects.toThrow('Failed to load document: File not found')
    })
  })

  describe('saveDocument', () => {
    it('should save document successfully', async () => {
      const content = '# Updated Privacy Policy\n\nThis is updated content.'
      const filePath = '/path/to/document.md'
      
      mockFs.writeFile.mockResolvedValue()
      mockFs.mkdir.mockResolvedValue(undefined)
      
      await documentService.saveDocument(filePath, content)
      
      expect(mockFs.mkdir).toHaveBeenCalledWith(
        path.dirname(filePath), 
        { recursive: true }
      )
      expect(mockFs.writeFile).toHaveBeenCalledWith(filePath, content, 'utf-8')
    })

    it('should throw error when file cannot be saved', async () => {
      const error = new Error('Permission denied')
      mockFs.writeFile.mockRejectedValue(error)
      mockFs.mkdir.mockResolvedValue(undefined)
      
      await expect(documentService.saveDocument('/readonly/path.md', 'content'))
        .rejects.toThrow('Failed to save document: Permission denied')
    })
  })

  describe('getDocumentMetadata', () => {
    it('should return document metadata successfully', async () => {
      const mockStats = {
        size: 1024,
        mtime: new Date('2023-09-04T10:00:00Z'),
        isFile: () => true
      } as any
      
      mockFs.stat.mockResolvedValue(mockStats)
      
      const result = await documentService.getDocumentMetadata('/path/to/document.md')
      
      expect(result).toEqual({
        fileName: 'document.md',
        fileSize: 1024,
        lastModified: new Date('2023-09-04T10:00:00Z'),
        documentType: 'Privacy/User Agreement'
      })
    })

    it('should throw error when file stats cannot be retrieved', async () => {
      const error = new Error('File not found')
      mockFs.stat.mockRejectedValue(error)
      
      await expect(documentService.getDocumentMetadata('/invalid/path.md'))
        .rejects.toThrow('Failed to get document metadata: File not found')
    })

    it('should throw error for non-file paths', async () => {
      const mockStats = {
        isFile: () => false
      } as any
      
      mockFs.stat.mockResolvedValue(mockStats)
      
      await expect(documentService.getDocumentMetadata('/path/to/directory'))
        .rejects.toThrow('Path is not a file')
    })
  })

  describe('validateMarkdown', () => {
    it('should return true for valid markdown', () => {
      const validMarkdown = '# Title\n\nThis is valid markdown with **bold** text.'
      const result = documentService.validateMarkdown(validMarkdown)
      expect(result).toBe(true)
    })

    it('should return false for empty content', () => {
      const result = documentService.validateMarkdown('')
      expect(result).toBe(false)
    })

    it('should return false for whitespace-only content', () => {
      const result = documentService.validateMarkdown('   \n  \t  ')
      expect(result).toBe(false)
    })

    it('should return true for content with just text', () => {
      const result = documentService.validateMarkdown('Plain text content')
      expect(result).toBe(true)
    })
  })

  describe('updateDocumentDate', () => {
    it('should update last modified date in frontmatter', () => {
      const content = `---
title: Privacy Policy
lastModified: 2023-01-01T00:00:00Z
---

# Privacy Policy
Content here.`

      const result = documentService.updateDocumentDate(content)
      
      expect(result).toMatch(/lastModified: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(result).toContain('title: Privacy Policy')
      expect(result).toContain('# Privacy Policy')
    })

    it('should add frontmatter if not present', () => {
      const content = '# Privacy Policy\nContent here.'
      const result = documentService.updateDocumentDate(content)
      
      expect(result).toMatch(/^---\nlastModified: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(result).toContain('# Privacy Policy')
    })

    it('should handle empty content', () => {
      const result = documentService.updateDocumentDate('')
      expect(result).toMatch(/^---\nlastModified: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    })
  })

  describe('error handling', () => {
    it('should handle filesystem errors gracefully', async () => {
      const fsError = new Error('ENOENT: no such file or directory')
      mockFs.readFile.mockRejectedValue(fsError)
      
      await expect(documentService.loadDocument('/nonexistent.md'))
        .rejects.toThrow('Failed to load document')
    })

    it('should handle permission errors', async () => {
      const permissionError = new Error('EACCES: permission denied')
      mockFs.writeFile.mockRejectedValue(permissionError)
      mockFs.mkdir.mockResolvedValue(undefined)
      
      await expect(documentService.saveDocument('/protected/file.md', 'content'))
        .rejects.toThrow('Failed to save document')
    })
  })

  describe('integration scenarios', () => {
    it('should handle complete document workflow', async () => {
      // Mock loading
      const originalContent = '# Privacy Policy\nOriginal content.'
      mockFs.readFile.mockResolvedValue(originalContent)
      
      // Mock metadata
      const mockStats = {
        size: 512,
        mtime: new Date('2023-09-04T10:00:00Z'),
        isFile: () => true
      } as any
      mockFs.stat.mockResolvedValue(mockStats)
      
      // Mock saving
      mockFs.writeFile.mockResolvedValue()
      mockFs.mkdir.mockResolvedValue(undefined)
      
      const filePath = '/docs/privacy.md'
      
      // Load document
      const content = await documentService.loadDocument(filePath)
      expect(content).toBe(originalContent)
      
      // Get metadata
      const metadata = await documentService.getDocumentMetadata(filePath)
      expect(metadata.fileName).toBe('privacy.md')
      
      // Update and save
      const updatedContent = '# Privacy Policy\nUpdated content.'
      await documentService.saveDocument(filePath, updatedContent)
      
      expect(mockFs.writeFile).toHaveBeenCalledWith(filePath, updatedContent, 'utf-8')
    })
  })
})