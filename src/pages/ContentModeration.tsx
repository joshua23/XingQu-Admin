import React, { useEffect, useState } from 'react'
import { Shield, Check, X, AlertTriangle, Eye, Clock } from 'lucide-react'

interface ContentItem {
  id: string
  type: 'text' | 'image' | 'audio' | 'video'
  title: string
  author: string
  status: 'pending' | 'approved' | 'rejected'
  submitted_at: string
  reviewed_at?: string
  reviewer?: string
  content: string
  risk_level: 'low' | 'medium' | 'high'
}

const ContentModeration: React.FC = () => {
  const [contents, setContents] = useState<ContentItem[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'pending' | 'approved' | 'rejected'>('pending')

  useEffect(() => {
    // 模拟加载内容数据
    const loadContents = async () => {
      try {
        setTimeout(() => {
          const mockContents: ContentItem[] = [
            {
              id: '1',
              type: 'text',
              title: 'AI创作的故事',
              author: '用户A',
              status: 'pending',
              submitted_at: '2024-01-20 10:30:00',
              content: '这是一个用户创作的故事内容...',
              risk_level: 'low'
            },
            {
              id: '2',
              type: 'image',
              title: '用户上传的图片',
              author: '用户B',
              status: 'pending',
              submitted_at: '2024-01-20 09:15:00',
              content: '图片描述：用户上传的创意图片',
              risk_level: 'medium'
            },
            {
              id: '3',
              type: 'audio',
              title: '语音内容',
              author: '用户C',
              status: 'approved',
              submitted_at: '2024-01-19 16:45:00',
              reviewed_at: '2024-01-19 17:00:00',
              reviewer: '审核员1',
              content: '音频内容：用户录制的语音',
              risk_level: 'low'
            }
          ]
          setContents(mockContents)
          setLoading(false)
        }, 1000)
      } catch (error) {
        console.error('加载内容数据失败:', error)
        setLoading(false)
      }
    }

    loadContents()
  }, [])

  const filteredContents = contents.filter(content => content.status === activeTab)

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { bg: 'bg-yellow-500', text: '待审核', icon: Clock },
      approved: { bg: 'bg-green-500', text: '已通过', icon: Check },
      rejected: { bg: 'bg-red-500', text: '已拒绝', icon: X }
    }
    const config = statusConfig[status as keyof typeof statusConfig]
    return (
      <span className={`px-3 py-1 text-xs rounded-full text-white ${config.bg} flex items-center`}>
        <config.icon size={12} className="mr-1" />
        {config.text}
      </span>
    )
  }

  const getRiskBadge = (level: string) => {
    const riskConfig = {
      low: { bg: 'bg-green-600', text: '低风险' },
      medium: { bg: 'bg-yellow-600', text: '中风险' },
      high: { bg: 'bg-red-600', text: '高风险' }
    }
    const config = riskConfig[level as keyof typeof riskConfig]
    return (
      <span className={`px-2 py-1 text-xs rounded-full text-white ${config.bg}`}>
        {config.text}
      </span>
    )
  }

  const getTypeIcon = (type: string) => {
    const typeConfig = {
      text: '📝',
      image: '🖼️',
      audio: '🎵',
      video: '🎥'
    }
    return typeConfig[type as keyof typeof typeConfig] || '📄'
  }

  const handleApprove = (id: string) => {
    setContents(prev =>
      prev.map(content =>
        content.id === id
          ? { ...content, status: 'approved' as const, reviewed_at: new Date().toISOString(), reviewer: '当前审核员' }
          : content
      )
    )
  }

  const handleReject = (id: string) => {
    setContents(prev =>
      prev.map(content =>
        content.id === id
          ? { ...content, status: 'rejected' as const, reviewed_at: new Date().toISOString(), reviewer: '当前审核员' }
          : content
      )
    )
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">内容审核</h1>
        <p className="text-gray-600 dark:text-gray-400 mt-1">审核和管理用户提交的内容</p>
      </div>

      {/* 统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
          <div className="flex items-center">
            <Clock className="text-yellow-500 mr-3" size={24} />
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">待审核</p>
              <p className="text-gray-900 dark:text-white text-2xl font-bold">
                {contents.filter(c => c.status === 'pending').length}
              </p>
            </div>
          </div>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
          <div className="flex items-center">
            <Check className="text-green-500 mr-3" size={24} />
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">已通过</p>
              <p className="text-gray-900 dark:text-white text-2xl font-bold">
                {contents.filter(c => c.status === 'approved').length}
              </p>
            </div>
          </div>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
          <div className="flex items-center">
            <X className="text-red-500 mr-3" size={24} />
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">已拒绝</p>
              <p className="text-gray-900 dark:text-white text-2xl font-bold">
                {contents.filter(c => c.status === 'rejected').length}
              </p>
            </div>
          </div>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
          <div className="flex items-center">
            <AlertTriangle className="text-orange-500 mr-3" size={24} />
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">高风险</p>
              <p className="text-gray-900 dark:text-white text-2xl font-bold">
                {contents.filter(c => c.risk_level === 'high').length}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* 标签页 */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <div className="border-b border-gray-200 dark:border-gray-700">
          <div className="flex">
            {[
              { key: 'pending', label: '待审核', count: contents.filter(c => c.status === 'pending').length },
              { key: 'approved', label: '已通过', count: contents.filter(c => c.status === 'approved').length },
              { key: 'rejected', label: '已拒绝', count: contents.filter(c => c.status === 'rejected').length }
            ].map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key as any)}
                className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === tab.key
                    ? 'border-primary-500 text-primary-500'
                    : 'border-transparent text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
                }`}
              >
                {tab.label} ({tab.count})
              </button>
            ))}
          </div>
        </div>

        {/* 内容列表 */}
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {filteredContents.map((content) => (
            <div key={content.id} className="p-6 hover:bg-gray-50 dark:hover:bg-gray-700">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <span className="text-2xl">{getTypeIcon(content.type)}</span>
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white">{content.title}</h3>
                    {getStatusBadge(content.status)}
                    {getRiskBadge(content.risk_level)}
                  </div>

                  <div className="text-gray-700 dark:text-gray-300 mb-2">{content.content}</div>

                  <div className="flex items-center space-x-4 text-sm text-gray-600 dark:text-gray-400">
                    <span>作者: {content.author}</span>
                    <span>提交时间: {content.submitted_at}</span>
                    {content.reviewed_at && (
                      <span>审核时间: {content.reviewed_at}</span>
                    )}
                    {content.reviewer && (
                      <span>审核员: {content.reviewer}</span>
                    )}
                  </div>
                </div>

                {content.status === 'pending' && (
                  <div className="flex space-x-2 ml-4">
                    <button
                      onClick={() => handleApprove(content.id)}
                      className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm flex items-center"
                    >
                      <Check size={16} className="mr-1" />
                      通过
                    </button>
                    <button
                      onClick={() => handleReject(content.id)}
                      className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm flex items-center"
                    >
                      <X size={16} className="mr-1" />
                      拒绝
                    </button>
                    <button className="px-4 py-2 bg-gray-200 dark:bg-gray-600 hover:bg-gray-300 dark:hover:bg-gray-700 text-gray-900 dark:text-white rounded-lg text-sm flex items-center">
                      <Eye size={16} className="mr-1" />
                      查看详情
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        {filteredContents.length === 0 && (
          <div className="p-12 text-center text-gray-600 dark:text-gray-400">
            <Shield size={48} className="mx-auto mb-4 opacity-50" />
            <p>暂无{activeTab === 'pending' ? '待审核' : activeTab === 'approved' ? '已通过' : '已拒绝'}的内容</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default ContentModeration
