/**
 * 星趣后台管理系统 - 内容审核管理面板
 * 提供AI智能审核、人工复审和规则管理功能
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
import { 
  Shield, 
  Eye, 
  CheckCircle, 
  XCircle, 
  Clock, 
  AlertTriangle,
  Search,
  Filter,
  Download,
  Settings,
  BarChart3,
  Flag,
  MessageSquare,
  Image,
  Video,
  Mic,
  FileText,
  Zap,
  Users,
  TrendingUp
} from 'lucide-react'
import { useContentModeration } from '@/lib/hooks/useContentModeration'
import type { ModerationRecord, ModerationFilters } from '@/lib/types/admin'

interface ContentModerationDashboardProps {
  className?: string
}

export default function ContentModerationDashboard({ className }: ContentModerationDashboardProps) {
  const {
    records,
    statistics,
    selectedRecords,
    totalRecords,
    loading,
    processing,
    error,
    loadRecords,
    loadStatistics,
    reviewContent,
    batchReview,
    selectRecord,
    unselectRecord,
    selectAllRecords,
    clearSelection,
    toggleRecordSelection,
    exportData,
    clearError
  } = useContentModeration()

  const [activeTab, setActiveTab] = useState<'pending' | 'reviewed' | 'statistics' | 'rules'>('pending')
  const [filters, setFilters] = useState<ModerationFilters>({})
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedContentType, setSelectedContentType] = useState<string>('all')
  const [selectedStatus, setSelectedStatus] = useState<string>('pending')

  // 页面初始化
  useEffect(() => {
    loadRecords({ status: ['pending'] })
    loadStatistics()
  }, [loadRecords, loadStatistics])

  // 处理搜索和过滤
  useEffect(() => {
    const newFilters: ModerationFilters = {}

    if (selectedStatus !== 'all') {
      newFilters.status = [selectedStatus]
    }

    if (selectedContentType !== 'all') {
      newFilters.contentType = [selectedContentType]
    }

    setFilters(newFilters)
    loadRecords(newFilters)
  }, [selectedStatus, selectedContentType, loadRecords])

  const getContentTypeIcon = (type: string) => {
    switch (type) {
      case 'text': return <MessageSquare size={16} />
      case 'image': return <Image size={16} />
      case 'video': return <Video size={16} />
      case 'audio': return <Mic size={16} />
      default: return <FileText size={16} />
    }
  }

  const getStatusBadge = (status: string) => {
    const styles = {
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
      approved: 'bg-green-100 text-green-800 border-green-200',
      rejected: 'bg-red-100 text-red-800 border-red-200',
      flagged: 'bg-orange-100 text-orange-800 border-orange-200'
    }
    const labels = {
      pending: '待审核',
      approved: '已通过',
      rejected: '已拒绝',
      flagged: '已标记'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles]}`}>
        {labels[status as keyof typeof labels]}
      </span>
    )
  }

  const getPriorityBadge = (priority: string) => {
    const styles = {
      low: 'bg-gray-100 text-gray-800',
      medium: 'bg-blue-100 text-blue-800',
      high: 'bg-orange-100 text-orange-800',
      urgent: 'bg-red-100 text-red-800'
    }
    const labels = {
      low: '低',
      medium: '中',
      high: '高',
      urgent: '紧急'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[priority as keyof typeof styles]}`}>
        {labels[priority as keyof typeof labels]}
      </span>
    )
  }

  const handleReview = async (record: ModerationRecord, decision: 'approved' | 'rejected') => {
    try {
      await reviewContent(record.id, decision)
      clearError()
    } catch (error) {
      console.error('审核失败:', error)
    }
  }

  const handleBatchReview = async (decision: 'approved' | 'rejected') => {
    if (selectedRecords.length === 0) return
    
    try {
      await batchReview(decision)
      clearError()
    } catch (error) {
      console.error('批量审核失败:', error)
    }
  }

  const handleExport = async () => {
    try {
      const csv = await exportData(filters)
      
      // 创建下载链接
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `moderation_records_${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    } catch (error) {
      console.error('导出失败:', error)
    }
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* 错误提示 */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertTriangle size={16} className="text-red-500" />
            <span className="text-red-800 text-sm">{error}</span>
            <button
              onClick={clearError}
              className="ml-auto text-red-500 hover:text-red-700"
            >
              <XCircle size={14} />
            </button>
          </div>
        </div>
      )}

      {/* 统计概览 */}
      {statistics && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <Clock size={24} className="text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{statistics.pendingCount}</p>
                <p className="text-sm text-gray-600">待审核</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle size={24} className="text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{statistics.approvedCount}</p>
                <p className="text-sm text-gray-600">已通过</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <XCircle size={24} className="text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{statistics.rejectedCount}</p>
                <p className="text-sm text-gray-600">已拒绝</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <Zap size={24} className="text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{(statistics.aiAccuracy * 100).toFixed(1)}%</p>
                <p className="text-sm text-gray-600">AI准确率</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 标签页 */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="flex border-b border-gray-200">
          <button
            onClick={() => setActiveTab('pending')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'pending'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <Clock size={16} />
              <span>待审核</span>
            </div>
          </button>

          <button
            onClick={() => setActiveTab('reviewed')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'reviewed'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <Shield size={16} />
              <span>审核历史</span>
            </div>
          </button>

          <button
            onClick={() => setActiveTab('statistics')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'statistics'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <BarChart3 size={16} />
              <span>统计分析</span>
            </div>
          </button>

          <button
            onClick={() => setActiveTab('rules')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'rules'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <Settings size={16} />
              <span>审核规则</span>
            </div>
          </button>
        </div>

        {/* 筛选和操作栏 */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
            {/* 搜索和筛选 */}
            <div className="flex flex-1 gap-4">
              <div className="relative">
                <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="搜索内容..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-64 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">所有状态</option>
                <option value="pending">待审核</option>
                <option value="approved">已通过</option>
                <option value="rejected">已拒绝</option>
                <option value="flagged">已标记</option>
              </select>

              <select
                value={selectedContentType}
                onChange={(e) => setSelectedContentType(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">所有类型</option>
                <option value="text">文本</option>
                <option value="image">图片</option>
                <option value="video">视频</option>
                <option value="audio">音频</option>
              </select>
            </div>

            {/* 操作按钮 */}
            <div className="flex items-center space-x-3">
              {selectedRecords.length > 0 && (
                <>
                  <button
                    onClick={() => handleBatchReview('approved')}
                    disabled={processing}
                    className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                  >
                    <CheckCircle size={16} />
                    <span>批量通过</span>
                  </button>
                  <button
                    onClick={() => handleBatchReview('rejected')}
                    disabled={processing}
                    className="flex items-center space-x-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                  >
                    <XCircle size={16} />
                    <span>批量拒绝</span>
                  </button>
                </>
              )}

              <button
                onClick={handleExport}
                className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <Download size={16} />
                <span>导出</span>
              </button>
            </div>
          </div>

          {selectedRecords.length > 0 && (
            <div className="mt-4 flex items-center justify-between bg-blue-50 rounded-lg p-3">
              <span className="text-sm text-blue-800">
                已选择 {selectedRecords.length} 条记录
              </span>
              <button
                onClick={clearSelection}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                清空选择
              </button>
            </div>
          )}
        </div>

        {/* 内容区域 */}
        <div className="p-6">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <span className="ml-3 text-gray-600">加载中...</span>
            </div>
          ) : (
            <div className="space-y-4">
              {records.map((record) => (
                <div
                  key={record.id}
                  className={`border rounded-lg p-4 transition-all ${
                    selectedRecords.some(r => r.id === record.id)
                      ? 'border-blue-300 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-start space-x-4">
                    <input
                      type="checkbox"
                      checked={selectedRecords.some(r => r.id === record.id)}
                      onChange={() => toggleRecordSelection(record)}
                      className="mt-1 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />

                    <div className="flex-1 space-y-3">
                      {/* 头部信息 */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          {getContentTypeIcon(record.content_type)}
                          <span className="text-sm font-medium text-gray-900">
                            {record.content_type.toUpperCase()}
                          </span>
                          {getStatusBadge(record.status)}
                          {getPriorityBadge(record.priority)}
                        </div>
                        <div className="flex items-center space-x-2 text-sm text-gray-500">
                          <span>{new Date(record.created_at).toLocaleString()}</span>
                          {record.ai_confidence && (
                            <span>AI置信度: {(record.ai_confidence * 100).toFixed(1)}%</span>
                          )}
                        </div>
                      </div>

                      {/* 内容预览 */}
                      <div className="bg-gray-50 rounded-lg p-3">
                        <p className="text-sm text-gray-700 line-clamp-2">
                          {record.content_text}
                        </p>
                      </div>

                      {/* 违规信息 */}
                      {record.violations && record.violations.length > 0 && (
                        <div className="flex flex-wrap gap-2">
                          {record.violations.map((violation, index) => (
                            <span
                              key={index}
                              className={`px-2 py-1 rounded-full text-xs ${
                                violation.severity === 'critical'
                                  ? 'bg-red-100 text-red-800'
                                  : violation.severity === 'high'
                                  ? 'bg-orange-100 text-orange-800'
                                  : 'bg-yellow-100 text-yellow-800'
                              }`}
                            >
                              {violation.type}: {violation.description}
                            </span>
                          ))}
                        </div>
                      )}

                      {/* 操作按钮 */}
                      {record.status === 'pending' && (
                        <div className="flex items-center space-x-2 pt-2">
                          <button
                            onClick={() => handleReview(record, 'approved')}
                            disabled={processing}
                            className="flex items-center space-x-1 px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 disabled:opacity-50"
                          >
                            <CheckCircle size={14} />
                            <span>通过</span>
                          </button>
                          <button
                            onClick={() => handleReview(record, 'rejected')}
                            disabled={processing}
                            className="flex items-center space-x-1 px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700 disabled:opacity-50"
                          >
                            <XCircle size={14} />
                            <span>拒绝</span>
                          </button>
                          <button className="flex items-center space-x-1 px-3 py-1 border border-gray-300 text-sm rounded hover:bg-gray-50">
                            <Eye size={14} />
                            <span>详情</span>
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}

              {records.length === 0 && (
                <div className="text-center py-12">
                  <Shield size={48} className="mx-auto text-gray-400 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">暂无审核记录</h3>
                  <p className="text-gray-500">当前筛选条件下没有找到任何记录</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}