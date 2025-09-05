'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Input } from '@/components/ui/Input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/Select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/Table'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/Dialog'
import { Textarea } from '@/components/ui/Textarea'
import { Label } from '@/components/ui/Label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { AlertTriangle, Eye, Trash2, CheckCircle, XCircle, Clock, Filter, Search, MoreHorizontal } from 'lucide-react'
import { dataService } from '@/lib/services/supabase'

interface ContentItem {
  id: string
  title: string
  content: string
  content_type: 'agent' | 'chat' | 'material' | 'post'
  status: 'pending' | 'approved' | 'rejected' | 'flagged'
  creator_id: string
  creator_name?: string
  created_at: string
  moderation_score?: number
  violation_types?: string[]
  reviewer_id?: string
  reviewer_name?: string
  reviewed_at?: string
}

export default function ContentManagementPage() {
  const [contents, setContents] = useState<ContentItem[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [selectedContent, setSelectedContent] = useState<ContentItem | null>(null)
  const [reviewDialogOpen, setReviewDialogOpen] = useState(false)

  // 模拟数据，实际应用中应该从 Supabase 的 xq_contents 表获取
  useEffect(() => {
    loadContents()
  }, [])

  const loadContents = async () => {
    try {
      setLoading(true)
      
      // 模拟数据，实际应该调用 Supabase
      const mockContents: ContentItem[] = [
        {
          id: '1',
          title: 'AI助手创建指南',
          content: '如何创建一个高效的AI智能助手...',
          content_type: 'agent',
          status: 'pending',
          creator_id: 'user1',
          creator_name: '张三',
          created_at: new Date().toISOString(),
          moderation_score: 0.8
        },
        {
          id: '2', 
          title: '用户反馈收集',
          content: '关于产品功能的一些建议...',
          content_type: 'post',
          status: 'flagged',
          creator_id: 'user2',
          creator_name: '李四',
          created_at: new Date(Date.now() - 86400000).toISOString(),
          moderation_score: 0.3,
          violation_types: ['inappropriate_content']
        },
        {
          id: '3',
          title: '聊天记录分析',
          content: '用户聊天数据的统计分析...',
          content_type: 'chat',
          status: 'approved',
          creator_id: 'user3',
          creator_name: '王五',
          created_at: new Date(Date.now() - 172800000).toISOString(),
          reviewer_id: 'admin1',
          reviewer_name: '管理员',
          reviewed_at: new Date(Date.now() - 86400000).toISOString()
        }
      ]

      setContents(mockContents)
    } catch (error) {
      console.error('加载内容失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleReview = async (contentId: string, action: 'approve' | 'reject', reason?: string) => {
    try {
      // 实际应该调用 Supabase API 更新 xq_contents 表
      setContents(prev => prev.map(item => 
        item.id === contentId 
          ? { 
              ...item, 
              status: action === 'approve' ? 'approved' : 'rejected',
              reviewer_id: 'current-admin-id',
              reviewer_name: '当前管理员',
              reviewed_at: new Date().toISOString()
            }
          : item
      ))
      setReviewDialogOpen(false)
      setSelectedContent(null)
    } catch (error) {
      console.error('审核失败:', error)
    }
  }

  const filteredContents = contents.filter(item => {
    const matchesSearch = item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (item.creator_name?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false)
    const matchesStatus = statusFilter === 'all' || item.status === statusFilter
    const matchesType = typeFilter === 'all' || item.content_type === typeFilter
    return matchesSearch && matchesStatus && matchesType
  })

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="outline" className="text-yellow-600"><Clock className="w-3 h-3 mr-1" />待审核</Badge>
      case 'approved':
        return <Badge variant="outline" className="text-green-600"><CheckCircle className="w-3 h-3 mr-1" />已通过</Badge>
      case 'rejected':
        return <Badge variant="outline" className="text-red-600"><XCircle className="w-3 h-3 mr-1" />已拒绝</Badge>
      case 'flagged':
        return <Badge variant="outline" className="text-orange-600"><AlertTriangle className="w-3 h-3 mr-1" />已标记</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getTypeBadge = (type: string) => {
    const typeMap = {
      agent: '智能体',
      chat: '聊天',
      material: '素材',
      post: '帖子'
    }
    return <Badge variant="secondary">{typeMap[type as keyof typeof typeMap] || type}</Badge>
  }

  const stats = {
    total: contents.length,
    pending: contents.filter(c => c.status === 'pending').length,
    flagged: contents.filter(c => c.status === 'flagged').length,
    approved: contents.filter(c => c.status === 'approved').length
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">内容管理</h1>
          <p className="text-muted-foreground">
            管理用户生成的内容，进行审核和监管
          </p>
        </div>

        {/* 统计卡片 */}
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">总内容数</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">待审核</CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-yellow-600">{stats.pending}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">已标记</CardTitle>
              <AlertTriangle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-orange-600">{stats.flagged}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">已通过</CardTitle>
              <CheckCircle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{stats.approved}</div>
            </CardContent>
          </Card>
        </div>

        {/* 筛选和搜索 */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-5 w-5" />
              筛选条件
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex gap-4 flex-wrap">
              <div className="flex-1 min-w-[300px]">
                <div className="relative">
                  <Search className="absolute left-2 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="搜索标题、内容或创建者..."
                    className="pl-8"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
              </div>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="审核状态" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">全部状态</SelectItem>
                  <SelectItem value="pending">待审核</SelectItem>
                  <SelectItem value="approved">已通过</SelectItem>
                  <SelectItem value="rejected">已拒绝</SelectItem>
                  <SelectItem value="flagged">已标记</SelectItem>
                </SelectContent>
              </Select>
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="内容类型" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">全部类型</SelectItem>
                  <SelectItem value="agent">智能体</SelectItem>
                  <SelectItem value="chat">聊天</SelectItem>
                  <SelectItem value="material">素材</SelectItem>
                  <SelectItem value="post">帖子</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* 内容列表 */}
        <Card>
          <CardHeader>
            <CardTitle>内容列表</CardTitle>
            <CardDescription>
              共找到 {filteredContents.length} 条内容
            </CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-4">加载中...</div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>标题</TableHead>
                    <TableHead>类型</TableHead>
                    <TableHead>创建者</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>创建时间</TableHead>
                    <TableHead>审核分数</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredContents.map((content) => (
                    <TableRow key={content.id}>
                      <TableCell className="font-medium max-w-[200px] truncate">
                        {content.title}
                      </TableCell>
                      <TableCell>
                        {getTypeBadge(content.content_type)}
                      </TableCell>
                      <TableCell>{content.creator_name}</TableCell>
                      <TableCell>
                        {getStatusBadge(content.status)}
                      </TableCell>
                      <TableCell>
                        {new Date(content.created_at).toLocaleDateString('zh-CN')}
                      </TableCell>
                      <TableCell>
                        {content.moderation_score ? (
                          <Badge 
                            variant={content.moderation_score > 0.7 ? "outline" : content.moderation_score > 0.4 ? "secondary" : "destructive"}
                          >
                            {(content.moderation_score * 100).toFixed(0)}%
                          </Badge>
                        ) : '-'}
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Dialog>
                            <DialogTrigger asChild>
                              <Button variant="outline" size="sm" onClick={() => setSelectedContent(content)}>
                                <Eye className="w-4 h-4" />
                              </Button>
                            </DialogTrigger>
                            <DialogContent className="max-w-2xl">
                              <DialogHeader>
                                <DialogTitle>内容详情</DialogTitle>
                                <DialogDescription>
                                  查看和管理内容详细信息
                                </DialogDescription>
                              </DialogHeader>
                              {selectedContent && (
                                <div className="space-y-4">
                                  <div>
                                    <Label>标题</Label>
                                    <div className="mt-1 p-2 border rounded-md">{selectedContent.title}</div>
                                  </div>
                                  <div>
                                    <Label>内容</Label>
                                    <div className="mt-1 p-2 border rounded-md max-h-40 overflow-y-auto">
                                      {selectedContent.content}
                                    </div>
                                  </div>
                                  <div className="grid grid-cols-2 gap-4">
                                    <div>
                                      <Label>类型</Label>
                                      <div className="mt-1">{getTypeBadge(selectedContent.content_type)}</div>
                                    </div>
                                    <div>
                                      <Label>状态</Label>
                                      <div className="mt-1">{getStatusBadge(selectedContent.status)}</div>
                                    </div>
                                  </div>
                                  {selectedContent.violation_types && selectedContent.violation_types.length > 0 && (
                                    <div>
                                      <Label>违规类型</Label>
                                      <div className="mt-1 flex gap-2">
                                        {selectedContent.violation_types.map((type, index) => (
                                          <Badge key={index} variant="destructive">{type}</Badge>
                                        ))}
                                      </div>
                                    </div>
                                  )}
                                  {selectedContent.status === 'pending' && (
                                    <div className="flex gap-2 pt-4">
                                      <Button 
                                        onClick={() => handleReview(selectedContent.id, 'approve')}
                                        className="bg-green-600 hover:bg-green-700"
                                      >
                                        <CheckCircle className="w-4 h-4 mr-2" />
                                        通过
                                      </Button>
                                      <Button 
                                        variant="destructive"
                                        onClick={() => handleReview(selectedContent.id, 'reject')}
                                      >
                                        <XCircle className="w-4 h-4 mr-2" />
                                        拒绝
                                      </Button>
                                    </div>
                                  )}
                                </div>
                              )}
                            </DialogContent>
                          </Dialog>
                          {content.status === 'pending' && (
                            <>
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => handleReview(content.id, 'approve')}
                                className="text-green-600 hover:text-green-700"
                              >
                                <CheckCircle className="w-4 h-4" />
                              </Button>
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => handleReview(content.id, 'reject')}
                                className="text-red-600 hover:text-red-700"
                              >
                                <XCircle className="w-4 h-4" />
                              </Button>
                            </>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}