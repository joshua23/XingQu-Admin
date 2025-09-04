'use client'

import React, { useState } from 'react'
import { Shield, Flag, Search, Filter, CheckCircle, XCircle, Eye, MessageSquare, Image, Video, FileText, Clock, User } from 'lucide-react'

interface ContentItem {
  id: string
  type: 'post' | 'comment' | 'image' | 'video'
  content: string
  author: {
    id: string
    nickname: string
    avatar?: string
  }
  status: 'pending' | 'approved' | 'rejected'
  reportCount: number
  createdAt: string
  reviewedAt?: string
  reviewer?: string
  reason?: string
  priority: 'low' | 'medium' | 'high' | 'urgent'
}

const mockContent: ContentItem[] = [
  {
    id: '1',
    type: 'post',
    content: '这是一条需要审核的帖子内容，可能包含敏感信息...',
    author: {
      id: '1',
      nickname: '张三'
    },
    status: 'pending',
    reportCount: 3,
    createdAt: '2024-01-20 14:30',
    priority: 'high'
  },
  {
    id: '2',
    type: 'comment',
    content: '这是一条评论内容，用户举报为不当言论',
    author: {
      id: '2',
      nickname: '李四'
    },
    status: 'pending',
    reportCount: 1,
    createdAt: '2024-01-20 13:45',
    priority: 'medium'
  },
  {
    id: '3',
    type: 'image',
    content: '用户上传的图片内容',
    author: {
      id: '3',
      nickname: '王五'
    },
    status: 'approved',
    reportCount: 0,
    createdAt: '2024-01-20 12:15',
    reviewedAt: '2024-01-20 12:20',
    reviewer: '审核员A',
    priority: 'low'
  },
  {
    id: '4',
    type: 'post',
    content: '涉嫌违规的帖子内容，已被多人举报',
    author: {
      id: '4',
      nickname: '赵六'
    },
    status: 'rejected',
    reportCount: 5,
    createdAt: '2024-01-20 11:30',
    reviewedAt: '2024-01-20 11:45',
    reviewer: '审核员B',
    reason: '含有不当内容',
    priority: 'urgent'
  }
]

export default function ModerationPage() {
  const [content, setContent] = useState<ContentItem[]>(mockContent)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [typeFilter, setTypeFilter] = useState<string>('all')
  const [priorityFilter, setPriorityFilter] = useState<string>('all')

  const filteredContent = content.filter(item => {
    const matchesSearch = item.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.author.nickname.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || item.status === statusFilter
    const matchesType = typeFilter === 'all' || item.type === typeFilter
    const matchesPriority = priorityFilter === 'all' || item.priority === priorityFilter
    
    return matchesSearch && matchesStatus && matchesType && matchesPriority
  })

  const getStatusBadge = (status: ContentItem['status']) => {
    const styles = {
      pending: 'bg-warning/10 text-warning border-warning/20',
      approved: 'bg-success/10 text-success border-success/20',
      rejected: 'bg-destructive/10 text-destructive border-destructive/20'
    }
    const labels = {
      pending: '待审核',
      approved: '已通过',
      rejected: '已拒绝'
    }
    return (
      <span className={`px-3 py-1 rounded-full text-xs font-medium border ${styles[status]}`}>
        {labels[status]}
      </span>
    )
  }

  const getPriorityBadge = (priority: ContentItem['priority']) => {
    const styles = {
      low: 'bg-muted text-muted-foreground border-border',
      medium: 'bg-primary/10 text-primary border-primary/20',
      high: 'bg-warning/10 text-warning border-warning/20',
      urgent: 'bg-destructive/10 text-destructive border-destructive/20'
    }
    const labels = {
      low: '低',
      medium: '中',
      high: '高',
      urgent: '紧急'
    }
    return (
      <span className={`px-2 py-1 rounded text-xs font-medium border ${styles[priority]}`}>
        {labels[priority]}
      </span>
    )
  }

  const getTypeIcon = (type: ContentItem['type']) => {
    const iconProps = { size: 16, className: "text-muted-foreground" }
    switch (type) {
      case 'post': return <FileText {...iconProps} />
      case 'comment': return <MessageSquare {...iconProps} />
      case 'image': return <Image {...iconProps} />
      case 'video': return <Video {...iconProps} />
      default: return <FileText {...iconProps} />
    }
  }

  const handleContentAction = (itemId: string, action: 'approve' | 'reject', reason?: string) => {
    setContent(prevContent => 
      prevContent.map(item => {
        if (item.id === itemId) {
          return {
            ...item,
            status: action === 'approve' ? 'approved' : 'rejected',
            reviewedAt: new Date().toLocaleString('zh-CN'),
            reviewer: '当前审核员',
            reason: reason
          }
        }
        return item
      })
    )
  }

  // 统计数据
  const stats = {
    total: content.length,
    pending: content.filter(item => item.status === 'pending').length,
    approved: content.filter(item => item.status === 'approved').length,
    rejected: content.filter(item => item.status === 'rejected').length,
    urgent: content.filter(item => item.priority === 'urgent').length
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">内容审核</h1>
          <p className="text-sm text-muted-foreground">管理和审核用户发布的内容</p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2 text-sm">
            <Clock size={16} className="text-muted-foreground" />
            <span className="text-muted-foreground">待审核: {stats.pending}</span>
          </div>
          <div className="flex items-center space-x-2 text-sm">
            <Flag size={16} className="text-destructive" />
            <span className="text-destructive">紧急: {stats.urgent}</span>
          </div>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-3 mt-3">
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-foreground">{stats.total}</div>
          <div className="text-sm text-muted-foreground">总内容数</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-warning">{stats.pending}</div>
          <div className="text-sm text-muted-foreground">待审核</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-success">{stats.approved}</div>
          <div className="text-sm text-muted-foreground">已通过</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-destructive">{stats.rejected}</div>
          <div className="text-sm text-muted-foreground">已拒绝</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-destructive">{stats.urgent}</div>
          <div className="text-sm text-muted-foreground">紧急处理</div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-card border border-border rounded-lg p-6 mt-3">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="搜索内容或作者..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            />
          </div>
          
          {/* Filters */}
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center space-x-2">
              <Filter size={16} className="text-muted-foreground" />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
              >
                <option value="all">所有状态</option>
                <option value="pending">待审核</option>
                <option value="approved">已通过</option>
                <option value="rejected">已拒绝</option>
              </select>
            </div>

            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            >
              <option value="all">所有类型</option>
              <option value="post">帖子</option>
              <option value="comment">评论</option>
              <option value="image">图片</option>
              <option value="video">视频</option>
            </select>

            <select
              value={priorityFilter}
              onChange={(e) => setPriorityFilter(e.target.value)}
              className="px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            >
              <option value="all">所有优先级</option>
              <option value="urgent">紧急</option>
              <option value="high">高</option>
              <option value="medium">中</option>
              <option value="low">低</option>
            </select>
          </div>
        </div>
      </div>

      {/* Content Table */}
      <div className="bg-card border border-border rounded-lg overflow-hidden mt-3">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50 border-b border-border">
              <tr>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">内容</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">作者</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">类型</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">状态</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">优先级</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">举报次数</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">发布时间</th>
                <th className="text-center py-4 px-6 font-medium text-sm text-muted-foreground">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filteredContent.map((item) => (
                <tr key={item.id} className="hover:bg-muted/30 transition-colors">
                  <td className="py-4 px-6">
                    <div className="max-w-xs">
                      <p className="text-sm text-foreground truncate">{item.content}</p>
                      {item.reason && (
                        <p className="text-xs text-destructive mt-1">拒绝原因: {item.reason}</p>
                      )}
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-2">
                      <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center">
                        <span className="text-xs font-medium text-primary">
                          {item.author.nickname[0]}
                        </span>
                      </div>
                      <span className="text-sm text-foreground">{item.author.nickname}</span>
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-2">
                      {getTypeIcon(item.type)}
                      <span className="text-sm text-muted-foreground capitalize">
                        {item.type === 'post' ? '帖子' : 
                         item.type === 'comment' ? '评论' :
                         item.type === 'image' ? '图片' : '视频'}
                      </span>
                    </div>
                  </td>
                  <td className="py-4 px-6">{getStatusBadge(item.status)}</td>
                  <td className="py-4 px-6">{getPriorityBadge(item.priority)}</td>
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-1">
                      <Flag size={14} className="text-destructive" />
                      <span className="text-sm font-medium">{item.reportCount}</span>
                    </div>
                  </td>
                  <td className="py-4 px-6 text-sm text-muted-foreground">
                    {item.createdAt}
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex items-center justify-center space-x-2">
                      {item.status === 'pending' && (
                        <>
                          <button 
                            onClick={() => handleContentAction(item.id, 'approve')}
                            className="p-1 rounded-lg hover:bg-muted transition-colors"
                            title="通过"
                          >
                            <CheckCircle size={16} className="text-success" />
                          </button>
                          <button 
                            onClick={() => handleContentAction(item.id, 'reject', '违反社区规定')}
                            className="p-1 rounded-lg hover:bg-muted transition-colors"
                            title="拒绝"
                          >
                            <XCircle size={16} className="text-destructive" />
                          </button>
                        </>
                      )}
                      <button className="p-1 rounded-lg hover:bg-muted transition-colors" title="查看详情">
                        <Eye size={16} className="text-primary" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {filteredContent.length === 0 && (
          <div className="text-center py-12">
            <Shield size={48} className="mx-auto text-muted-foreground mb-4" />
            <h3 className="text-lg font-medium text-foreground mb-2">没有找到内容</h3>
            <p className="text-muted-foreground">请尝试调整搜索条件</p>
          </div>
        )}
      </div>
    </div>
  )
}