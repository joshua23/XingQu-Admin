/**
 * AI内容审核管理组件 - 星趣后台管理系统
 * 功能：审核队列管理、审核结果展示、审核规则配置
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Textarea } from '@/components/ui/textarea'
import { Separator } from '@/components/ui/separator'
import { 
  Bot,
  Eye,
  Check,
  X,
  Clock,
  AlertTriangle,
  Search,
  Filter,
  Settings,
  BarChart3,
  FileText,
  Image,
  Mic,
  Video,
  User,
  MessageSquare,
  Shield,
  ChevronRight,
  Trash2,
  Edit,
  Play,
  Pause,
  RefreshCw,
  Download,
  Upload
} from 'lucide-react'

// AI审核记录类型
export interface ModerationRecord {
  id: string
  contentId: string
  contentType: 'text' | 'image' | 'audio' | 'video' | 'user_profile'
  contentSource?: string
  originalContent?: string
  moderationResult: 'approved' | 'rejected' | 'pending' | 'needs_review'
  aiConfidence: number // 0-1
  aiReasons: string[]
  humanReviewerId?: string
  humanReviewResult?: string
  humanReviewReason?: string
  violationTypes: string[]
  severityLevel: 1 | 2 | 3 | 4 | 5
  autoAction?: string
  appealStatus: 'none' | 'submitted' | 'reviewing' | 'approved' | 'rejected'
  appealReason?: string
  appealHandledBy?: string
  appealHandledAt?: string
  createdAt: string
  reviewedAt?: string
  updatedAt: string
}

// 审核规则类型
export interface ModerationRule {
  id: string
  name: string
  description?: string
  contentTypes: string[]
  ruleType: 'keyword' | 'regex' | 'ai_threshold' | 'length' | 'custom'
  ruleConfig: Record<string, any>
  action: 'block' | 'flag' | 'warn' | 'delete'
  severityLevel: 1 | 2 | 3 | 4 | 5
  isActive: boolean
  createdBy: string
  createdAt: string
  updatedAt: string
}

// 审核统计类型
export interface ModerationStats {
  totalReviewed: number
  pendingReview: number
  approved: number
  rejected: number
  needsHumanReview: number
  accuracyRate: number
  averageResponseTime: number
  rulesCount: number
}

interface AIContentModerationProps {
  records: ModerationRecord[]
  rules: ModerationRule[]
  stats: ModerationStats
  onApprove: (recordId: string) => Promise<void>
  onReject: (recordId: string, reason: string) => Promise<void>
  onCreateRule: (rule: Omit<ModerationRule, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>
  onUpdateRule: (id: string, updates: Partial<ModerationRule>) => Promise<void>
  onDeleteRule: (id: string) => Promise<void>
  onHandleAppeal: (recordId: string, decision: 'approved' | 'rejected', reason: string) => Promise<void>
  loading?: boolean
}

export default function AIContentModeration({
  records = [],
  rules = [],
  stats,
  onApprove,
  onReject,
  onCreateRule,
  onUpdateRule,
  onDeleteRule,
  onHandleAppeal,
  loading = false
}: AIContentModerationProps) {
  const [activeTab, setActiveTab] = useState('queue')
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [severityFilter, setSeverityFilter] = useState('all')
  const [selectedRecord, setSelectedRecord] = useState<ModerationRecord | null>(null)
  const [showDetailDialog, setShowDetailDialog] = useState(false)
  const [showRejectDialog, setShowRejectDialog] = useState(false)
  const [showAppealDialog, setShowAppealDialog] = useState(false)
  const [rejectReason, setRejectReason] = useState('')
  const [appealDecision, setAppealDecision] = useState<'approved' | 'rejected'>('rejected')
  const [appealReason, setAppealReason] = useState('')

  // 规则管理状态
  const [showRuleDialog, setShowRuleDialog] = useState(false)
  const [editingRule, setEditingRule] = useState<ModerationRule | null>(null)
  const [newRule, setNewRule] = useState({
    name: '',
    description: '',
    contentTypes: ['text'] as string[],
    ruleType: 'keyword' as const,
    ruleConfig: {},
    action: 'flag' as const,
    severityLevel: 3 as const,
    isActive: true
  })

  // 过滤和搜索记录
  const filteredRecords = useMemo(() => {
    let filtered = records

    // 状态筛选
    if (statusFilter !== 'all') {
      filtered = filtered.filter(record => record.moderationResult === statusFilter)
    }

    // 内容类型筛选
    if (typeFilter !== 'all') {
      filtered = filtered.filter(record => record.contentType === typeFilter)
    }

    // 严重程度筛选
    if (severityFilter !== 'all') {
      filtered = filtered.filter(record => record.severityLevel.toString() === severityFilter)
    }

    // 搜索过滤
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(record =>
        record.contentId.toLowerCase().includes(query) ||
        record.originalContent?.toLowerCase().includes(query) ||
        record.aiReasons.some(reason => reason.toLowerCase().includes(query))
      )
    }

    return filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
  }, [records, statusFilter, typeFilter, severityFilter, searchQuery])

  // 获取内容类型图标
  const getContentTypeIcon = (type: string) => {
    switch (type) {
      case 'text':
        return <MessageSquare className="h-4 w-4" />
      case 'image':
        return <Image className="h-4 w-4" />
      case 'audio':
        return <Mic className="h-4 w-4" />
      case 'video':
        return <Video className="h-4 w-4" />
      case 'user_profile':
        return <User className="h-4 w-4" />
      default:
        return <FileText className="h-4 w-4" />
    }
  }

  // 获取审核结果徽章
  const getModerationBadge = (result: string, confidence?: number) => {
    switch (result) {
      case 'approved':
        return <Badge variant="default" className="text-green-700 bg-green-100">通过</Badge>
      case 'rejected':
        return <Badge variant="destructive">拒绝</Badge>
      case 'pending':
        return <Badge variant="secondary">待审核</Badge>
      case 'needs_review':
        return <Badge variant="outline" className="text-orange-700 border-orange-300">需人工审核</Badge>
      default:
        return <Badge variant="outline">{result}</Badge>
    }
  }

  // 获取严重程度颜色
  const getSeverityColor = (level: number) => {
    const colors = {
      1: 'text-gray-500',
      2: 'text-blue-500', 
      3: 'text-yellow-500',
      4: 'text-orange-500',
      5: 'text-red-500'
    }
    return colors[level as keyof typeof colors] || 'text-gray-500'
  }

  // 处理审核通过
  const handleApprove = async (record: ModerationRecord) => {
    try {
      await onApprove(record.id)
    } catch (error) {
      console.error('审核通过失败:', error)
    }
  }

  // 处理审核拒绝
  const handleReject = async () => {
    if (!selectedRecord || !rejectReason.trim()) return

    try {
      await onReject(selectedRecord.id, rejectReason)
      setShowRejectDialog(false)
      setRejectReason('')
      setSelectedRecord(null)
    } catch (error) {
      console.error('审核拒绝失败:', error)
    }
  }

  // 处理申诉
  const handleAppeal = async () => {
    if (!selectedRecord || !appealReason.trim()) return

    try {
      await onHandleAppeal(selectedRecord.id, appealDecision, appealReason)
      setShowAppealDialog(false)
      setAppealReason('')
      setSelectedRecord(null)
    } catch (error) {
      console.error('处理申诉失败:', error)
    }
  }

  // 创建规则
  const handleCreateRule = async () => {
    try {
      await onCreateRule({
        ...newRule,
        createdBy: 'current-admin-id' // 实际应用中从认证上下文获取
      })
      setShowRuleDialog(false)
      setNewRule({
        name: '',
        description: '',
        contentTypes: ['text'],
        ruleType: 'keyword',
        ruleConfig: {},
        action: 'flag',
        severityLevel: 3,
        isActive: true
      })
    } catch (error) {
      console.error('创建规则失败:', error)
    }
  }

  // 渲染统计概览
  const renderStats = () => (
    <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-4 mb-6">
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-blue-600">{stats.totalReviewed.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground">总审核数</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-orange-600">{stats.pendingReview}</div>
          <p className="text-xs text-muted-foreground">待审核</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-green-600">{stats.approved}</div>
          <p className="text-xs text-muted-foreground">已通过</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-red-600">{stats.rejected}</div>
          <p className="text-xs text-muted-foreground">已拒绝</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-purple-600">{stats.needsHumanReview}</div>
          <p className="text-xs text-muted-foreground">需人工审核</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-cyan-600">{(stats.accuracyRate * 100).toFixed(1)}%</div>
          <p className="text-xs text-muted-foreground">准确率</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-indigo-600">{stats.averageResponseTime}ms</div>
          <p className="text-xs text-muted-foreground">平均响应</p>
        </CardContent>
      </Card>
      <Card>
        <CardContent className="p-4">
          <div className="text-2xl font-bold text-pink-600">{stats.rulesCount}</div>
          <p className="text-xs text-muted-foreground">审核规则</p>
        </CardContent>
      </Card>
    </div>
  )

  // 渲染审核队列
  const renderModerationQueue = () => (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>审核队列</CardTitle>
            <CardDescription>
              显示 {filteredRecords.length} 条记录，共 {records.length} 条
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
              placeholder="搜索内容..."
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
              <SelectItem value="pending">待审核</SelectItem>
              <SelectItem value="needs_review">需人工审核</SelectItem>
              <SelectItem value="approved">已通过</SelectItem>
              <SelectItem value="rejected">已拒绝</SelectItem>
            </SelectContent>
          </Select>

          <Select value={typeFilter} onValueChange={setTypeFilter}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="类型" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有类型</SelectItem>
              <SelectItem value="text">文本</SelectItem>
              <SelectItem value="image">图片</SelectItem>
              <SelectItem value="audio">音频</SelectItem>
              <SelectItem value="video">视频</SelectItem>
              <SelectItem value="user_profile">用户资料</SelectItem>
            </SelectContent>
          </Select>

          <Select value={severityFilter} onValueChange={setSeverityFilter}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="严重程度" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有等级</SelectItem>
              <SelectItem value="1">1级</SelectItem>
              <SelectItem value="2">2级</SelectItem>
              <SelectItem value="3">3级</SelectItem>
              <SelectItem value="4">4级</SelectItem>
              <SelectItem value="5">5级</SelectItem>
            </SelectContent>
          </Select>

          {(searchQuery || statusFilter !== 'all' || typeFilter !== 'all' || severityFilter !== 'all') && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setSearchQuery('')
                setStatusFilter('all')
                setTypeFilter('all')
                setSeverityFilter('all')
              }}
            >
              清除筛选
            </Button>
          )}
        </div>

        {/* 记录列表 */}
        <div className="space-y-2">
          {loading ? (
            <div className="space-y-2">
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
          ) : filteredRecords.length === 0 ? (
            <Card>
              <CardContent className="flex items-center justify-center py-12">
                <div className="text-center">
                  <Bot className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-muted-foreground mb-2">
                    {searchQuery ? '没有找到匹配的记录' : '暂无审核记录'}
                  </h3>
                  <p className="text-muted-foreground">
                    {searchQuery ? '尝试调整搜索条件' : 'AI审核系统正在待命中'}
                  </p>
                </div>
              </CardContent>
            </Card>
          ) : (
            filteredRecords.map((record) => (
              <Card key={record.id} className="hover:shadow-sm transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-2">
                        {getContentTypeIcon(record.contentType)}
                        <span className="font-medium text-sm">内容ID: {record.contentId}</span>
                        {getModerationBadge(record.moderationResult, record.aiConfidence)}
                        <Badge variant="outline" className={`text-xs ${getSeverityColor(record.severityLevel)}`}>
                          {record.severityLevel}级
                        </Badge>
                        {record.appealStatus !== 'none' && (
                          <Badge variant="outline" className="text-xs">
                            申诉: {record.appealStatus}
                          </Badge>
                        )}
                      </div>

                      <div className="text-sm text-muted-foreground mb-2 line-clamp-2">
                        {record.originalContent ? (
                          record.originalContent.length > 100
                            ? record.originalContent.substring(0, 100) + '...'
                            : record.originalContent
                        ) : (
                          `${record.contentType} 内容`
                        )}
                      </div>

                      <div className="flex items-center gap-4 text-xs text-muted-foreground">
                        <span>AI置信度: {(record.aiConfidence * 100).toFixed(1)}%</span>
                        <span>审核时间: {new Date(record.createdAt).toLocaleString()}</span>
                        {record.aiReasons.length > 0 && (
                          <span>违规原因: {record.aiReasons.slice(0, 2).join(', ')}</span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-1 ml-4">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedRecord(record)
                          setShowDetailDialog(true)
                        }}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>

                      {record.moderationResult === 'pending' && (
                        <>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleApprove(record)}
                            disabled={loading}
                          >
                            <Check className="h-4 w-4 text-green-600" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedRecord(record)
                              setShowRejectDialog(true)
                            }}
                            disabled={loading}
                          >
                            <X className="h-4 w-4 text-red-600" />
                          </Button>
                        </>
                      )}

                      {record.appealStatus === 'submitted' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            setSelectedRecord(record)
                            setShowAppealDialog(true)
                          }}
                          disabled={loading}
                        >
                          <Shield className="h-4 w-4 text-blue-600" />
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

  // 渲染规则管理
  const renderRulesManagement = () => (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>审核规则管理</CardTitle>
            <CardDescription>
              配置和管理AI审核规则
            </CardDescription>
          </div>
          <Button onClick={() => setShowRuleDialog(true)}>
            <Settings className="h-4 w-4 mr-2" />
            新增规则
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {rules.map((rule) => (
            <Card key={rule.id} className="border border-gray-200">
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <h3 className="font-medium">{rule.name}</h3>
                      <Badge variant={rule.isActive ? "default" : "secondary"}>
                        {rule.isActive ? '启用' : '禁用'}
                      </Badge>
                      <Badge variant="outline" className="text-xs">
                        {rule.ruleType}
                      </Badge>
                      <Badge variant="outline" className={`text-xs ${getSeverityColor(rule.severityLevel)}`}>
                        {rule.severityLevel}级
                      </Badge>
                    </div>
                    {rule.description && (
                      <p className="text-sm text-muted-foreground mb-2">{rule.description}</p>
                    )}
                    <div className="text-xs text-muted-foreground">
                      适用于: {rule.contentTypes.join(', ')} | 动作: {rule.action}
                    </div>
                  </div>
                  <div className="flex items-center gap-1">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setEditingRule(rule)}
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => onUpdateRule(rule.id, { isActive: !rule.isActive })}
                    >
                      {rule.isActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => onDeleteRule(rule.id)}
                      className="text-red-600 hover:text-red-700"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
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
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="queue" className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            审核队列
          </TabsTrigger>
          <TabsTrigger value="rules" className="flex items-center gap-2">
            <Settings className="h-4 w-4" />
            规则管理
          </TabsTrigger>
          <TabsTrigger value="analytics" className="flex items-center gap-2">
            <BarChart3 className="h-4 w-4" />
            审核分析
          </TabsTrigger>
        </TabsList>

        <TabsContent value="queue">
          {renderModerationQueue()}
        </TabsContent>

        <TabsContent value="rules">
          {renderRulesManagement()}
        </TabsContent>

        <TabsContent value="analytics">
          <Card>
            <CardHeader>
              <CardTitle>审核数据分析</CardTitle>
              <CardDescription>AI审核系统的性能和趋势分析</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12 text-muted-foreground">
                <BarChart3 className="h-12 w-12 mx-auto mb-4" />
                <h3 className="text-lg font-medium mb-2">审核分析功能</h3>
                <p>详细的审核数据分析和趋势图表即将上线</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* 详情对话框 */}
      <Dialog open={showDetailDialog} onOpenChange={setShowDetailDialog}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>审核详情</DialogTitle>
          </DialogHeader>
          {selectedRecord && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">内容ID</label>
                  <p className="text-sm text-muted-foreground">{selectedRecord.contentId}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">内容类型</label>
                  <div className="flex items-center gap-2">
                    {getContentTypeIcon(selectedRecord.contentType)}
                    <span className="text-sm">{selectedRecord.contentType}</span>
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium">审核结果</label>
                  <div className="flex items-center gap-2">
                    {getModerationBadge(selectedRecord.moderationResult, selectedRecord.aiConfidence)}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium">AI置信度</label>
                  <p className="text-sm text-muted-foreground">{(selectedRecord.aiConfidence * 100).toFixed(1)}%</p>
                </div>
              </div>

              <Separator />

              {selectedRecord.originalContent && (
                <div>
                  <label className="text-sm font-medium">原始内容</label>
                  <div className="mt-1 p-3 bg-muted rounded-lg">
                    <p className="text-sm">{selectedRecord.originalContent}</p>
                  </div>
                </div>
              )}

              {selectedRecord.aiReasons.length > 0 && (
                <div>
                  <label className="text-sm font-medium">AI检测原因</label>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {selectedRecord.aiReasons.map((reason, index) => (
                      <Badge key={index} variant="outline" className="text-xs">
                        {reason}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}

              {selectedRecord.violationTypes.length > 0 && (
                <div>
                  <label className="text-sm font-medium">违规类型</label>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {selectedRecord.violationTypes.map((type, index) => (
                      <Badge key={index} variant="destructive" className="text-xs">
                        {type}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">严重程度</label>
                  <p className={`text-sm font-medium ${getSeverityColor(selectedRecord.severityLevel)}`}>
                    {selectedRecord.severityLevel}级
                  </p>
                </div>
                <div>
                  <label className="text-sm font-medium">创建时间</label>
                  <p className="text-sm text-muted-foreground">
                    {new Date(selectedRecord.createdAt).toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* 拒绝对话框 */}
      <Dialog open={showRejectDialog} onOpenChange={setShowRejectDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>拒绝审核</DialogTitle>
            <DialogDescription>请输入拒绝理由</DialogDescription>
          </DialogHeader>
          <Textarea
            placeholder="请输入拒绝理由..."
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            rows={3}
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRejectDialog(false)}>
              取消
            </Button>
            <Button onClick={handleReject} disabled={!rejectReason.trim()}>
              确认拒绝
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* 申诉处理对话框 */}
      <Dialog open={showAppealDialog} onOpenChange={setShowAppealDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>处理申诉</DialogTitle>
            <DialogDescription>审核用户申诉请求</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">申诉决定</label>
              <Select value={appealDecision} onValueChange={(value: 'approved' | 'rejected') => setAppealDecision(value)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="approved">批准申诉</SelectItem>
                  <SelectItem value="rejected">拒绝申诉</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-medium">处理理由</label>
              <Textarea
                placeholder="请输入处理理由..."
                value={appealReason}
                onChange={(e) => setAppealReason(e.target.value)}
                rows={3}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAppealDialog(false)}>
              取消
            </Button>
            <Button onClick={handleAppeal} disabled={!appealReason.trim()}>
              确认处理
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* 新增规则对话框 */}
      <Dialog open={showRuleDialog} onOpenChange={setShowRuleDialog}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>新增审核规则</DialogTitle>
            <DialogDescription>创建新的AI审核规则</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">规则名称</label>
              <Input
                value={newRule.name}
                onChange={(e) => setNewRule({ ...newRule, name: e.target.value })}
                placeholder="输入规则名称"
              />
            </div>
            <div>
              <label className="text-sm font-medium">规则描述</label>
              <Input
                value={newRule.description}
                onChange={(e) => setNewRule({ ...newRule, description: e.target.value })}
                placeholder="规则用途说明（可选）"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">规则类型</label>
                <Select 
                  value={newRule.ruleType} 
                  onValueChange={(value: any) => setNewRule({ ...newRule, ruleType: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="keyword">关键词</SelectItem>
                    <SelectItem value="regex">正则表达式</SelectItem>
                    <SelectItem value="ai_threshold">AI阈值</SelectItem>
                    <SelectItem value="length">长度限制</SelectItem>
                    <SelectItem value="custom">自定义</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium">执行动作</label>
                <Select 
                  value={newRule.action} 
                  onValueChange={(value: any) => setNewRule({ ...newRule, action: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="block">阻止</SelectItem>
                    <SelectItem value="flag">标记</SelectItem>
                    <SelectItem value="warn">警告</SelectItem>
                    <SelectItem value="delete">删除</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRuleDialog(false)}>
              取消
            </Button>
            <Button onClick={handleCreateRule} disabled={!newRule.name.trim()}>
              创建规则
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}