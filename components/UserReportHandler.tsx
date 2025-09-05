/**
 * 用户举报处理组件 - 星趣后台管理系统
 * 功能：举报工单列表、举报内容审查、处理结果记录
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Textarea } from '@/components/ui/textarea'
import { Separator } from '@/components/ui/separator'
import { 
  Flag,
  Search,
  Filter,
  Eye,
  Clock,
  Check,
  X,
  MessageSquare,
  Image,
  User,
  AlertTriangle,
  Shield,
  FileText,
  Calendar,
  MapPin,
  Star,
  BarChart3,
  Trash2,
  Ban,
  Play,
  RefreshCw,
  Download,
  ChevronRight
} from 'lucide-react'

// 用户举报类型定义
export interface UserReport {
  id: string
  reporterId?: string
  reportedContentId?: string
  reportedUserId?: string
  reportType: 'spam' | 'inappropriate' | 'harassment' | 'fake' | 'copyright' | 'other'
  reportCategory: 'content' | 'user' | 'system'
  reason: string
  evidenceUrls: string[]
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed'
  priority: 1 | 2 | 3 | 4 | 5
  assignedTo?: string
  handlerNotes?: string
  resolution?: string
  handledBy?: string
  handledAt?: string
  reporterIp?: string
  reporterUserAgent?: string
  createdAt: string
  updatedAt: string
  
  // 关联数据
  reporter?: {
    id: string
    nickname: string
    email: string
    avatar?: string
  }
  reportedUser?: {
    id: string
    nickname: string
    email: string
    avatar?: string
  }
  reportedContent?: {
    id: string
    type: string
    content: string
    createdAt: string
  }
}

// 举报统计类型
export interface ReportStats {
  totalReports: number
  pendingReports: number
  investigatingReports: number
  resolvedReports: number
  dismissedReports: number
  averageResponseTime: number // 小时
  resolutionRate: number
  reportsByType: Record<string, number>
  reportsByCategory: Record<string, number>
}

interface UserReportHandlerProps {
  reports: UserReport[]
  stats: ReportStats
  onAssignReport: (reportId: string, assigneeId: string) => Promise<void>
  onResolveReport: (reportId: string, resolution: string, notes: string) => Promise<void>
  onDismissReport: (reportId: string, reason: string) => Promise<void>
  onEscalateReport: (reportId: string, priority: number) => Promise<void>
  loading?: boolean
}

export default function UserReportHandler({
  reports = [],
  stats,
  onAssignReport,
  onResolveReport,
  onDismissReport,
  onEscalateReport,
  loading = false
}: UserReportHandlerProps) {
  const [activeTab, setActiveTab] = useState('reports')
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [priorityFilter, setPriorityFilter] = useState('all')
  const [selectedReport, setSelectedReport] = useState<UserReport | null>(null)
  const [showDetailDialog, setShowDetailDialog] = useState(false)
  const [showResolveDialog, setShowResolveDialog] = useState(false)
  const [showDismissDialog, setShowDismissDialog] = useState(false)
  const [resolution, setResolution] = useState('')
  const [handlerNotes, setHandlerNotes] = useState('')
  const [dismissReason, setDismissReason] = useState('')

  // 过滤和搜索举报
  const filteredReports = useMemo(() => {
    let filtered = reports

    // 状态筛选
    if (statusFilter !== 'all') {
      filtered = filtered.filter(report => report.status === statusFilter)
    }

    // 类型筛选
    if (typeFilter !== 'all') {
      filtered = filtered.filter(report => report.reportType === typeFilter)
    }

    // 优先级筛选
    if (priorityFilter !== 'all') {
      filtered = filtered.filter(report => report.priority.toString() === priorityFilter)
    }

    // 搜索过滤
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(report =>
        report.reason.toLowerCase().includes(query) ||
        report.reportedUser?.nickname.toLowerCase().includes(query) ||
        report.reporter?.nickname.toLowerCase().includes(query) ||
        report.id.toLowerCase().includes(query)
      )
    }

    // 按创建时间倒序排列
    return filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
  }, [reports, statusFilter, typeFilter, priorityFilter, searchQuery])

  // 获取举报类型标签
  const getReportTypeBadge = (type: string) => {
    const variants = {
      spam: { variant: 'outline' as const, label: '垃圾信息', color: 'text-orange-600' },
      inappropriate: { variant: 'destructive' as const, label: '不当内容', color: 'text-red-600' },
      harassment: { variant: 'destructive' as const, label: '骚扰', color: 'text-red-700' },
      fake: { variant: 'outline' as const, label: '虚假信息', color: 'text-yellow-600' },
      copyright: { variant: 'outline' as const, label: '版权侵犯', color: 'text-purple-600' },
      other: { variant: 'secondary' as const, label: '其他', color: 'text-gray-600' }
    }
    const config = variants[type as keyof typeof variants] || variants.other
    return (
      <Badge variant={config.variant} className={`text-xs ${config.color}`}>
        {config.label}
      </Badge>
    )
  }

  // 获取状态徽章
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="secondary" className="text-xs">待处理</Badge>
      case 'investigating':
        return <Badge variant="outline" className="text-blue-600 text-xs">调查中</Badge>
      case 'resolved':
        return <Badge variant="default" className="text-green-600 text-xs">已解决</Badge>
      case 'dismissed':
        return <Badge variant="outline" className="text-gray-600 text-xs">已驳回</Badge>
      default:
        return <Badge variant="outline" className="text-xs">{status}</Badge>
    }
  }

  // 获取优先级颜色
  const getPriorityColor = (priority: number) => {
    const colors = {
      1: 'text-gray-500',
      2: 'text-blue-500',
      3: 'text-yellow-500',
      4: 'text-orange-500',
      5: 'text-red-500'
    }
    return colors[priority as keyof typeof colors] || 'text-gray-500'
  }

  // 获取优先级标签
  const getPriorityLabel = (priority: number) => {
    const labels = {
      1: '低',
      2: '一般',
      3: '中等',
      4: '高',
      5: '紧急'
    }
    return labels[priority as keyof typeof labels] || '未知'
  }

  // 处理解决举报
  const handleResolveReport = async () => {
    if (!selectedReport || !resolution.trim()) return

    try {
      await onResolveReport(selectedReport.id, resolution, handlerNotes)
      setShowResolveDialog(false)
      setResolution('')
      setHandlerNotes('')
      setSelectedReport(null)
    } catch (error) {
      console.error('解决举报失败:', error)
    }
  }

  // 处理驳回举报
  const handleDismissReport = async () => {
    if (!selectedReport || !dismissReason.trim()) return

    try {
      await onDismissReport(selectedReport.id, dismissReason)
      setShowDismissDialog(false)
      setDismissReason('')
      setSelectedReport(null)
    } catch (error) {
      console.error('驳回举报失败:', error)
    }
  }

  // 渲染统计概览
  const renderStats = () => (
    <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4 mb-6">
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-blue-600">{stats.totalReports.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground">总举报数</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-orange-600">{stats.pendingReports}</div>
          <p className="text-xs text-muted-foreground">待处理</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-purple-600">{stats.investigatingReports}</div>
          <p className="text-xs text-muted-foreground">调查中</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-green-600">{stats.resolvedReports}</div>
          <p className="text-xs text-muted-foreground">已解决</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-gray-600">{stats.dismissedReports}</div>
          <p className="text-xs text-muted-foreground">已驳回</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-cyan-600">{stats.averageResponseTime}h</div>
          <p className="text-xs text-muted-foreground">平均响应</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-indigo-600">{(stats.resolutionRate * 100).toFixed(1)}%</div>
          <p className="text-xs text-muted-foreground">解决率</p>
        </CardContent>
      </Card>
    </div>
  )

  // 渲染举报列表
  const renderReportsList = () => (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>举报工单列表</CardTitle>
            <CardDescription>
              显示 {filteredReports.length} 条举报，共 {reports.length} 条
            </CardDescription>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" disabled={loading}>
              <Download className="h-4 w-4 mr-2" />
              导出
            </Button>
            <Button variant="outline" size="sm" disabled={loading}>
              <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              刷新
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {/* 筛选控件 */}
        <div className="flex flex-wrap gap-4 mb-4">
          <div className="flex items-center gap-2">
            <Search className="h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="搜索举报..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-48"
            />
          </div>
          
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="状态" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有状态</SelectItem>
              <SelectItem value="pending">待处理</SelectItem>
              <SelectItem value="investigating">调查中</SelectItem>
              <SelectItem value="resolved">已解决</SelectItem>
              <SelectItem value="dismissed">已驳回</SelectItem>
            </SelectContent>
          </Select>

          <Select value={typeFilter} onValueChange={setTypeFilter}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="类型" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有类型</SelectItem>
              <SelectItem value="spam">垃圾信息</SelectItem>
              <SelectItem value="inappropriate">不当内容</SelectItem>
              <SelectItem value="harassment">骚扰</SelectItem>
              <SelectItem value="fake">虚假信息</SelectItem>
              <SelectItem value="copyright">版权侵犯</SelectItem>
              <SelectItem value="other">其他</SelectItem>
            </SelectContent>
          </Select>

          <Select value={priorityFilter} onValueChange={setPriorityFilter}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="优先级" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有优先级</SelectItem>
              <SelectItem value="1">低</SelectItem>
              <SelectItem value="2">一般</SelectItem>
              <SelectItem value="3">中等</SelectItem>
              <SelectItem value="4">高</SelectItem>
              <SelectItem value="5">紧急</SelectItem>
            </SelectContent>
          </Select>

          {(searchQuery || statusFilter !== 'all' || typeFilter !== 'all' || priorityFilter !== 'all') && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setSearchQuery('')
                setStatusFilter('all')
                setTypeFilter('all')
                setPriorityFilter('all')
              }}
            >
              清除筛选
            </Button>
          )}
        </div>

        {/* 举报列表 */}
        <div className="space-y-3">
          {loading ? (
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <Card key={i} className="animate-pulse">
                  <CardContent className="p-4">
                    <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-full mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : filteredReports.length === 0 ? (
            <Card>
              <CardContent className="flex items-center justify-center py-12">
                <div className="text-center">
                  <Flag className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-muted-foreground mb-2">
                    {searchQuery ? '没有找到匹配的举报' : '暂无举报'}
                  </h3>
                  <p className="text-muted-foreground">
                    {searchQuery ? '尝试调整搜索条件' : '系统运行正常，没有新的举报'}
                  </p>
                </div>
              </CardContent>
            </Card>
          ) : (
            filteredReports.map((report) => (
              <Card key={report.id} className="hover:shadow-sm transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-2">
                        <Flag className="h-4 w-4 text-muted-foreground" />
                        <span className="font-medium text-sm">#{report.id.slice(-8)}</span>
                        {getReportTypeBadge(report.reportType)}
                        {getStatusBadge(report.status)}
                        <Badge variant="outline" className={`text-xs ${getPriorityColor(report.priority)}`}>
                          {getPriorityLabel(report.priority)}
                        </Badge>
                      </div>

                      <div className="text-sm mb-2 line-clamp-2">
                        <span className="font-medium">举报原因:</span> {report.reason}
                      </div>

                      <div className="flex items-center gap-4 text-xs text-muted-foreground">
                        {report.reporter && (
                          <span className="flex items-center gap-1">
                            <User className="h-3 w-3" />
                            举报人: {report.reporter.nickname}
                          </span>
                        )}
                        {report.reportedUser && (
                          <span className="flex items-center gap-1">
                            <AlertTriangle className="h-3 w-3" />
                            被举报用户: {report.reportedUser.nickname}
                          </span>
                        )}
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          {new Date(report.createdAt).toLocaleDateString()}
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-1 ml-4">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedReport(report)
                          setShowDetailDialog(true)
                        }}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>

                      {report.status === 'pending' && (
                        <>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedReport(report)
                              setShowResolveDialog(true)
                            }}
                            disabled={loading}
                          >
                            <Check className="h-4 w-4 text-green-600" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedReport(report)
                              setShowDismissDialog(true)
                            }}
                            disabled={loading}
                          >
                            <X className="h-4 w-4 text-red-600" />
                          </Button>
                        </>
                      )}

                      {report.priority < 5 && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => onEscalateReport(report.id, Math.min(5, report.priority + 1))}
                          disabled={loading}
                          title="提升优先级"
                        >
                          <AlertTriangle className="h-4 w-4 text-orange-600" />
                        </Button>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  )

  // 渲染数据统计
  const renderAnalytics = () => (
    <Card>
      <CardHeader>
        <CardTitle>举报数据分析</CardTitle>
        <CardDescription>举报趋势和分类统计</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">按类型分布</h3>
            {Object.entries(stats.reportsByType).map(([type, count]) => (
              <div key={type} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center gap-2">
                  {getReportTypeBadge(type)}
                </div>
                <div className="text-right">
                  <p className="font-medium">{count}</p>
                  <p className="text-sm text-muted-foreground">举报</p>
                </div>
              </div>
            ))}
          </div>
          
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">按分类分布</h3>
            {Object.entries(stats.reportsByCategory).map(([category, count]) => (
              <div key={category} className="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <p className="font-medium">{category}</p>
                  <p className="text-sm text-muted-foreground">
                    {category === 'content' ? '内容举报' : 
                     category === 'user' ? '用户举报' : '系统举报'}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-medium">{count}</p>
                  <p className="text-sm text-muted-foreground">举报</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  )

  return (
    <div className="space-y-6">
      {/* 统计概览 */}
      {renderStats()}

      {/* 主要内容区域 */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="reports" className="flex items-center gap-2">
            <Flag className="h-4 w-4" />
            举报工单
          </TabsTrigger>
          <TabsTrigger value="analytics" className="flex items-center gap-2">
            <BarChart3 className="h-4 w-4" />
            数据分析
          </TabsTrigger>
        </TabsList>

        <TabsContent value="reports">
          {renderReportsList()}
        </TabsContent>

        <TabsContent value="analytics">
          {renderAnalytics()}
        </TabsContent>
      </Tabs>

      {/* 详情对话框 */}
      <Dialog open={showDetailDialog} onOpenChange={setShowDetailDialog}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>举报详情</DialogTitle>
          </DialogHeader>
          {selectedReport && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">举报ID</label>
                  <p className="text-sm text-muted-foreground">#{selectedReport.id}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">举报类型</label>
                  <div className="flex items-center gap-2">
                    {getReportTypeBadge(selectedReport.reportType)}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium">处理状态</label>
                  <div className="flex items-center gap-2">
                    {getStatusBadge(selectedReport.status)}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium">优先级</label>
                  <p className={`text-sm font-medium ${getPriorityColor(selectedReport.priority)}`}>
                    {getPriorityLabel(selectedReport.priority)}
                  </p>
                </div>
              </div>

              <Separator />

              <div>
                <label className="text-sm font-medium">举报原因</label>
                <div className="mt-1 p-3 bg-muted rounded-lg">
                  <p className="text-sm">{selectedReport.reason}</p>
                </div>
              </div>

              {selectedReport.reporter && (
                <div>
                  <label className="text-sm font-medium">举报人信息</label>
                  <div className="flex items-center gap-3 mt-1 p-3 border rounded-lg">
                    <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                      <User className="h-5 w-5" />
                    </div>
                    <div>
                      <p className="font-medium">{selectedReport.reporter.nickname}</p>
                      <p className="text-sm text-muted-foreground">{selectedReport.reporter.email}</p>
                    </div>
                  </div>
                </div>
              )}

              {selectedReport.reportedUser && (
                <div>
                  <label className="text-sm font-medium">被举报用户</label>
                  <div className="flex items-center gap-3 mt-1 p-3 border rounded-lg">
                    <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                      <AlertTriangle className="h-5 w-5 text-red-600" />
                    </div>
                    <div>
                      <p className="font-medium">{selectedReport.reportedUser.nickname}</p>
                      <p className="text-sm text-muted-foreground">{selectedReport.reportedUser.email}</p>
                    </div>
                  </div>
                </div>
              )}

              {selectedReport.reportedContent && (
                <div>
                  <label className="text-sm font-medium">被举报内容</label>
                  <div className="mt-1 p-3 bg-red-50 border border-red-200 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Badge variant="outline" className="text-xs">
                        {selectedReport.reportedContent.type}
                      </Badge>
                      <span className="text-xs text-muted-foreground">
                        {new Date(selectedReport.reportedContent.createdAt).toLocaleString()}
                      </span>
                    </div>
                    <p className="text-sm">{selectedReport.reportedContent.content}</p>
                  </div>
                </div>
              )}

              {selectedReport.handlerNotes && (
                <div>
                  <label className="text-sm font-medium">处理备注</label>
                  <div className="mt-1 p-3 bg-muted rounded-lg">
                    <p className="text-sm">{selectedReport.handlerNotes}</p>
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">创建时间</label>
                  <p className="text-sm text-muted-foreground">
                    {new Date(selectedReport.createdAt).toLocaleString()}
                  </p>
                </div>
                {selectedReport.handledAt && (
                  <div>
                    <label className="text-sm font-medium">处理时间</label>
                    <p className="text-sm text-muted-foreground">
                      {new Date(selectedReport.handledAt).toLocaleString()}
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* 解决举报对话框 */}
      <Dialog open={showResolveDialog} onOpenChange={setShowResolveDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>解决举报</DialogTitle>
            <DialogDescription>记录处理结果和解决方案</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">解决方案</label>
              <Textarea
                placeholder="请描述如何解决了这个举报..."
                value={resolution}
                onChange={(e) => setResolution(e.target.value)}
                rows={3}
              />
            </div>
            <div>
              <label className="text-sm font-medium">处理备注</label>
              <Textarea
                placeholder="补充说明和备注（可选）..."
                value={handlerNotes}
                onChange={(e) => setHandlerNotes(e.target.value)}
                rows={2}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowResolveDialog(false)}>
              取消
            </Button>
            <Button onClick={handleResolveReport} disabled={!resolution.trim()}>
              标记为已解决
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* 驳回举报对话框 */}
      <Dialog open={showDismissDialog} onOpenChange={setShowDismissDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>驳回举报</DialogTitle>
            <DialogDescription>说明驳回理由</DialogDescription>
          </DialogHeader>
          <div>
            <label className="text-sm font-medium">驳回理由</label>
            <Textarea
              placeholder="请说明为什么驳回这个举报..."
              value={dismissReason}
              onChange={(e) => setDismissReason(e.target.value)}
              rows={3}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDismissDialog(false)}>
              取消
            </Button>
            <Button onClick={handleDismissReport} disabled={!dismissReason.trim()}>
              确认驳回
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}