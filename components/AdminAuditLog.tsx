/**
 * 星趣后台管理系统 - 操作审计组件
 * 提供完整的操作审计功能
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table'
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger 
} from '@/components/ui/dialog'
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import {
  Search,
  Filter,
  Download,
  RefreshCw,
  Eye,
  AlertTriangle,
  Shield,
  Activity,
  Clock,
  User,
  FileText,
  BarChart3,
  Calendar as CalendarIcon,
  Settings,
  Trash2,
  Edit,
  Plus,
  Database,
  Lock,
  Unlock,
  UserPlus,
  UserMinus
} from 'lucide-react'
import { format } from 'date-fns'
import { zh } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'

// 类型定义
interface AuditLog {
  id: string
  userId: string
  userName: string
  userEmail: string
  action: string
  actionType: 'create' | 'update' | 'delete' | 'login' | 'logout' | 'access' | 'export' | 'config'
  resource: string
  resourceId?: string
  details: string
  ipAddress: string
  userAgent: string
  timestamp: string
  success: boolean
  riskLevel: 'low' | 'medium' | 'high' | 'critical'
  sessionId: string
}

interface AuditStats {
  totalLogs: number
  todayLogs: number
  failedActions: number
  highRiskActions: number
  uniqueUsers: number
  mostActiveUser: string
  mostCommonAction: string
  suspiciousActivities: number
}

interface SuspiciousActivity {
  id: string
  type: 'multiple_failed_logins' | 'unusual_hours' | 'suspicious_ip' | 'mass_deletion' | 'privilege_escalation'
  userId: string
  userName: string
  description: string
  riskScore: number
  timestamp: string
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed'
  investigatedBy?: string
  notes?: string
}

interface AuditReport {
  id: string
  name: string
  description: string
  timeRange: { start: string; end: string }
  filters: {
    users?: string[]
    actions?: string[]
    resources?: string[]
    riskLevels?: string[]
  }
  generatedAt: string
  generatedBy: string
  status: 'generating' | 'completed' | 'failed'
  downloadUrl?: string
}

export default function AdminAuditLog() {
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([])
  const [stats, setStats] = useState<AuditStats>({
    totalLogs: 0,
    todayLogs: 0,
    failedActions: 0,
    highRiskActions: 0,
    uniqueUsers: 0,
    mostActiveUser: '',
    mostCommonAction: '',
    suspiciousActivities: 0
  })
  const [suspiciousActivities, setSuspiciousActivities] = useState<SuspiciousActivity[]>([])
  const [auditReports, setAuditReports] = useState<AuditReport[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null)
  const [isDetailDialogOpen, setIsDetailDialogOpen] = useState(false)
  const [isReportDialogOpen, setIsReportDialogOpen] = useState(false)

  // 筛选状态
  const [searchTerm, setSearchTerm] = useState('')
  const [filterAction, setFilterAction] = useState<string>('all')
  const [filterRiskLevel, setFilterRiskLevel] = useState<string>('all')
  const [filterUser, setFilterUser] = useState<string>('all')
  const [dateRange, setDateRange] = useState<{ from?: Date; to?: Date }>({})
  const [showOnlyFailed, setShowOnlyFailed] = useState(false)

  // 报告表单
  const [reportForm, setReportForm] = useState({
    name: '',
    description: '',
    timeRange: { start: '', end: '' },
    includeUsers: [] as string[],
    includeActions: [] as string[],
    includeResources: [] as string[],
    includeRiskLevels: [] as string[]
  })

  useEffect(() => {
    fetchAuditLogs()
    fetchStats()
    fetchSuspiciousActivities()
    fetchAuditReports()
  }, [])

  const fetchAuditLogs = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      const mockLogs: AuditLog[] = [
        {
          id: '1',
          userId: 'admin1',
          userName: '张三',
          userEmail: 'zhangsan@example.com',
          action: '登录系统',
          actionType: 'login',
          resource: 'auth',
          details: '管理员成功登录系统',
          ipAddress: '192.168.1.100',
          userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          timestamp: '2025-09-05 14:30:25',
          success: true,
          riskLevel: 'low',
          sessionId: 'sess_001'
        },
        {
          id: '2',
          userId: 'admin2',
          userName: '李四',
          userEmail: 'lisi@example.com',
          action: '删除用户',
          actionType: 'delete',
          resource: 'user',
          resourceId: 'user_123',
          details: '删除用户账户: user_123',
          ipAddress: '192.168.1.101',
          userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          timestamp: '2025-09-05 14:25:15',
          success: true,
          riskLevel: 'high',
          sessionId: 'sess_002'
        },
        {
          id: '3',
          userId: 'admin3',
          userName: '王五',
          userEmail: 'wangwu@example.com',
          action: '登录失败',
          actionType: 'login',
          resource: 'auth',
          details: '登录失败: 密码错误',
          ipAddress: '203.0.113.45',
          userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          timestamp: '2025-09-05 14:20:10',
          success: false,
          riskLevel: 'medium',
          sessionId: 'sess_003'
        },
        {
          id: '4',
          userId: 'admin1',
          userName: '张三',
          userEmail: 'zhangsan@example.com',
          action: '修改系统配置',
          actionType: 'config',
          resource: 'system_config',
          resourceId: 'config_001',
          details: '修改AI服务配置参数',
          ipAddress: '192.168.1.100',
          userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          timestamp: '2025-09-05 14:15:30',
          success: true,
          riskLevel: 'medium',
          sessionId: 'sess_001'
        },
        {
          id: '5',
          userId: 'admin4',
          userName: '赵六',
          userEmail: 'zhaoliu@example.com',
          action: '导出数据',
          actionType: 'export',
          resource: 'user_data',
          details: '导出用户数据报表',
          ipAddress: '192.168.1.102',
          userAgent: 'Mozilla/5.0 (Ubuntu; Linux x86_64) AppleWebKit/537.36',
          timestamp: '2025-09-05 14:10:45',
          success: true,
          riskLevel: 'medium',
          sessionId: 'sess_004'
        }
      ]
      
      setAuditLogs(mockLogs)
    } catch (error) {
      console.error('获取审计日志失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchStats = async () => {
    try {
      setStats({
        totalLogs: 1247,
        todayLogs: 85,
        failedActions: 12,
        highRiskActions: 8,
        uniqueUsers: 25,
        mostActiveUser: '张三',
        mostCommonAction: '查看用户',
        suspiciousActivities: 3
      })
    } catch (error) {
      console.error('获取统计数据失败:', error)
    }
  }

  const fetchSuspiciousActivities = async () => {
    try {
      const mockActivities: SuspiciousActivity[] = [
        {
          id: '1',
          type: 'multiple_failed_logins',
          userId: 'admin3',
          userName: '王五',
          description: '在5分钟内连续5次登录失败',
          riskScore: 75,
          timestamp: '2025-09-05 14:20:10',
          status: 'pending'
        },
        {
          id: '2',
          type: 'unusual_hours',
          userId: 'admin5',
          userName: '陈七',
          description: '凌晨2:30执行敏感操作',
          riskScore: 60,
          timestamp: '2025-09-05 02:30:15',
          status: 'investigating',
          investigatedBy: 'security_team'
        },
        {
          id: '3',
          type: 'suspicious_ip',
          userId: 'admin6',
          userName: '刘八',
          description: '从未见过的IP地址登录',
          riskScore: 85,
          timestamp: '2025-09-05 13:45:20',
          status: 'pending'
        }
      ]
      
      setSuspiciousActivities(mockActivities)
    } catch (error) {
      console.error('获取可疑活动失败:', error)
    }
  }

  const fetchAuditReports = async () => {
    try {
      const mockReports: AuditReport[] = [
        {
          id: '1',
          name: '9月安全审计报告',
          description: '2025年9月份完整的安全操作审计',
          timeRange: { start: '2025-09-01', end: '2025-09-30' },
          filters: {},
          generatedAt: '2025-09-05 10:00:00',
          generatedBy: 'admin1',
          status: 'completed',
          downloadUrl: '/reports/audit_2025_09.pdf'
        },
        {
          id: '2',
          name: '高风险操作报告',
          description: '近30天内的高风险操作汇总',
          timeRange: { start: '2025-08-06', end: '2025-09-05' },
          filters: { riskLevels: ['high', 'critical'] },
          generatedAt: '2025-09-05 09:30:00',
          generatedBy: 'admin1',
          status: 'completed',
          downloadUrl: '/reports/high_risk_2025.pdf'
        }
      ]
      
      setAuditReports(mockReports)
    } catch (error) {
      console.error('获取审计报告失败:', error)
    }
  }

  const generateReport = async () => {
    try {
      const newReport: AuditReport = {
        id: Date.now().toString(),
        ...reportForm,
        generatedAt: new Date().toISOString(),
        generatedBy: 'current_user',
        status: 'generating'
      }
      
      setAuditReports([newReport, ...auditReports])
      setIsReportDialogOpen(false)
      
      // 模拟报告生成过程
      setTimeout(() => {
        setAuditReports(prev => prev.map(report => 
          report.id === newReport.id 
            ? { ...report, status: 'completed', downloadUrl: '/reports/custom_report.pdf' }
            : report
        ))
      }, 3000)
    } catch (error) {
      console.error('生成报告失败:', error)
    }
  }

  const investigateSuspiciousActivity = async (activityId: string) => {
    try {
      setSuspiciousActivities(prev => prev.map(activity =>
        activity.id === activityId
          ? { ...activity, status: 'investigating', investigatedBy: 'current_user' }
          : activity
      ))
    } catch (error) {
      console.error('标记调查失败:', error)
    }
  }

  const resolveSuspiciousActivity = async (activityId: string, notes: string) => {
    try {
      setSuspiciousActivities(prev => prev.map(activity =>
        activity.id === activityId
          ? { ...activity, status: 'resolved', notes }
          : activity
      ))
    } catch (error) {
      console.error('解决可疑活动失败:', error)
    }
  }

  // 过滤审计日志
  const filteredLogs = useMemo(() => {
    return auditLogs.filter(log => {
      const matchesSearch = searchTerm === '' || 
        log.userName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.resource.toLowerCase().includes(searchTerm.toLowerCase())
      
      const matchesAction = filterAction === 'all' || log.actionType === filterAction
      const matchesRiskLevel = filterRiskLevel === 'all' || log.riskLevel === filterRiskLevel
      const matchesUser = filterUser === 'all' || log.userId === filterUser
      const matchesSuccess = !showOnlyFailed || !log.success
      
      return matchesSearch && matchesAction && matchesRiskLevel && matchesUser && matchesSuccess
    })
  }, [auditLogs, searchTerm, filterAction, filterRiskLevel, filterUser, showOnlyFailed])

  // 获取样式
  const getRiskBadge = (riskLevel: string) => {
    switch (riskLevel) {
      case 'critical':
        return <Badge className="bg-red-600 text-white">严重</Badge>
      case 'high':
        return <Badge className="bg-red-100 text-red-700 border-red-200">高</Badge>
      case 'medium':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">中</Badge>
      case 'low':
        return <Badge variant="outline" className="text-green-600">低</Badge>
      default:
        return <Badge variant="outline">{riskLevel}</Badge>
    }
  }

  const getActionIcon = (actionType: string) => {
    switch (actionType) {
      case 'login':
        return <Unlock className="w-4 h-4" />
      case 'logout':
        return <Lock className="w-4 h-4" />
      case 'create':
        return <Plus className="w-4 h-4" />
      case 'update':
        return <Edit className="w-4 h-4" />
      case 'delete':
        return <Trash2 className="w-4 h-4" />
      case 'access':
        return <Eye className="w-4 h-4" />
      case 'export':
        return <Download className="w-4 h-4" />
      case 'config':
        return <Settings className="w-4 h-4" />
      default:
        return <Activity className="w-4 h-4" />
    }
  }

  const getSuccessBadge = (success: boolean) => {
    return success ? (
      <Badge className="bg-green-100 text-green-700 border-green-200">成功</Badge>
    ) : (
      <Badge className="bg-red-100 text-red-700 border-red-200">失败</Badge>
    )
  }

  const getSuspiciousTypeBadge = (type: string) => {
    const types = {
      multiple_failed_logins: '多次登录失败',
      unusual_hours: '异常时间操作',
      suspicious_ip: '可疑IP',
      mass_deletion: '批量删除',
      privilege_escalation: '权限提升'
    }
    
    return types[type as keyof typeof types] || type
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-700">待处理</Badge>
      case 'investigating':
        return <Badge className="bg-blue-100 text-blue-700">调查中</Badge>
      case 'resolved':
        return <Badge className="bg-green-100 text-green-700">已解决</Badge>
      case 'dismissed':
        return <Badge variant="outline" className="text-gray-600">已忽略</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getReportStatusBadge = (status: string) => {
    switch (status) {
      case 'generating':
        return <Badge className="bg-blue-100 text-blue-700">生成中</Badge>
      case 'completed':
        return <Badge className="bg-green-100 text-green-700">已完成</Badge>
      case 'failed':
        return <Badge className="bg-red-100 text-red-700">失败</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  return (
    <div className="space-y-6">
      {/* 统计卡片 */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">总日志数</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalLogs.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              今日: {stats.todayLogs}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">失败操作</CardTitle>
            <AlertTriangle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{stats.failedActions}</div>
            <p className="text-xs text-muted-foreground">需要关注</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">高风险操作</CardTitle>
            <Shield className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">{stats.highRiskActions}</div>
            <p className="text-xs text-muted-foreground">需要审核</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">可疑活动</CardTitle>
            <Activity className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{stats.suspiciousActivities}</div>
            <p className="text-xs text-muted-foreground">待调查</p>
          </CardContent>
        </Card>
      </div>

      {/* 主要内容 */}
      <Tabs defaultValue="logs" className="space-y-4">
        <TabsList>
          <TabsTrigger value="logs">操作日志</TabsTrigger>
          <TabsTrigger value="suspicious">可疑活动</TabsTrigger>
          <TabsTrigger value="reports">审计报告</TabsTrigger>
          <TabsTrigger value="analytics">统计分析</TabsTrigger>
        </TabsList>

        {/* 操作日志 */}
        <TabsContent value="logs" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>操作审计日志</CardTitle>
                  <CardDescription>系统所有操作的详细记录</CardDescription>
                </div>
                <Button variant="outline" onClick={fetchAuditLogs} disabled={loading}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  刷新
                </Button>
              </div>
              
              {/* 筛选工具栏 */}
              <div className="flex flex-wrap items-center gap-4">
                <div className="flex items-center space-x-2">
                  <Search className="w-4 h-4 text-muted-foreground" />
                  <Input
                    placeholder="搜索用户、操作或资源..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-64"
                  />
                </div>
                
                <Select value={filterAction} onValueChange={setFilterAction}>
                  <SelectTrigger className="w-32">
                    <SelectValue placeholder="操作类型" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部操作</SelectItem>
                    <SelectItem value="login">登录</SelectItem>
                    <SelectItem value="create">创建</SelectItem>
                    <SelectItem value="update">更新</SelectItem>
                    <SelectItem value="delete">删除</SelectItem>
                    <SelectItem value="export">导出</SelectItem>
                    <SelectItem value="config">配置</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={filterRiskLevel} onValueChange={setFilterRiskLevel}>
                  <SelectTrigger className="w-32">
                    <SelectValue placeholder="风险等级" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部等级</SelectItem>
                    <SelectItem value="low">低风险</SelectItem>
                    <SelectItem value="medium">中风险</SelectItem>
                    <SelectItem value="high">高风险</SelectItem>
                    <SelectItem value="critical">严重</SelectItem>
                  </SelectContent>
                </Select>

                <Button
                  variant={showOnlyFailed ? "default" : "outline"}
                  onClick={() => setShowOnlyFailed(!showOnlyFailed)}
                >
                  <AlertTriangle className="w-4 h-4 mr-2" />
                  仅显示失败
                </Button>

                <Button variant="outline">
                  <Download className="w-4 h-4 mr-2" />
                  导出日志
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>时间</TableHead>
                    <TableHead>用户</TableHead>
                    <TableHead>操作</TableHead>
                    <TableHead>资源</TableHead>
                    <TableHead>结果</TableHead>
                    <TableHead>风险等级</TableHead>
                    <TableHead>IP地址</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredLogs.map((log) => (
                    <TableRow key={log.id}>
                      <TableCell className="font-mono text-sm">
                        {new Date(log.timestamp).toLocaleString()}
                      </TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium">{log.userName}</div>
                          <div className="text-xs text-muted-foreground">{log.userEmail}</div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          {getActionIcon(log.actionType)}
                          <span>{log.action}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium">{log.resource}</div>
                          {log.resourceId && (
                            <div className="text-xs text-muted-foreground">{log.resourceId}</div>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>{getSuccessBadge(log.success)}</TableCell>
                      <TableCell>{getRiskBadge(log.riskLevel)}</TableCell>
                      <TableCell className="font-mono text-sm">{log.ipAddress}</TableCell>
                      <TableCell>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            setSelectedLog(log)
                            setIsDetailDialogOpen(true)
                          }}
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 可疑活动 */}
        <TabsContent value="suspicious" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>可疑活动监控</CardTitle>
              <CardDescription>自动检测的异常行为和安全威胁</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {suspiciousActivities.map((activity) => (
                  <Card key={activity.id} className="border">
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center space-x-2">
                            <Badge className="bg-red-100 text-red-700">
                              {getSuspiciousTypeBadge(activity.type)}
                            </Badge>
                            {getStatusBadge(activity.status)}
                            <Badge variant="outline">
                              风险分数: {activity.riskScore}
                            </Badge>
                          </div>
                          <h4 className="font-semibold">{activity.userName}</h4>
                          <p className="text-sm text-muted-foreground">{activity.description}</p>
                        </div>
                        <div className="text-xs text-muted-foreground">
                          {new Date(activity.timestamp).toLocaleString()}
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="pt-0">
                      {activity.status === 'pending' && (
                        <div className="flex space-x-2">
                          <Button 
                            size="sm" 
                            onClick={() => investigateSuspiciousActivity(activity.id)}
                          >
                            开始调查
                          </Button>
                          <Button variant="outline" size="sm">
                            忽略
                          </Button>
                        </div>
                      )}
                      
                      {activity.status === 'investigating' && (
                        <div className="flex items-center space-x-2">
                          <span className="text-sm text-blue-600">调查中...</span>
                          <Button 
                            size="sm" 
                            onClick={() => resolveSuspiciousActivity(activity.id, '调查完成，无异常')}
                          >
                            标记解决
                          </Button>
                        </div>
                      )}
                      
                      {activity.status === 'resolved' && activity.notes && (
                        <div className="text-sm text-green-600">
                          已解决: {activity.notes}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 审计报告 */}
        <TabsContent value="reports" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>审计报告管理</CardTitle>
                  <CardDescription>生成和管理审计报告</CardDescription>
                </div>
                <Dialog open={isReportDialogOpen} onOpenChange={setIsReportDialogOpen}>
                  <DialogTrigger asChild>
                    <Button>
                      <Plus className="w-4 h-4 mr-2" />
                      生成报告
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="max-w-2xl">
                    <DialogHeader>
                      <DialogTitle>生成审计报告</DialogTitle>
                      <DialogDescription>
                        配置报告参数和筛选条件
                      </DialogDescription>
                    </DialogHeader>
                    
                    <div className="grid gap-4 py-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="reportName">报告名称</Label>
                          <Input
                            id="reportName"
                            value={reportForm.name}
                            onChange={(e) => setReportForm({...reportForm, name: e.target.value})}
                            placeholder="例如：安全审计报告"
                          />
                        </div>
                      </div>
                      
                      <div>
                        <Label htmlFor="reportDescription">报告描述</Label>
                        <Input
                          id="reportDescription"
                          value={reportForm.description}
                          onChange={(e) => setReportForm({...reportForm, description: e.target.value})}
                          placeholder="描述报告的内容和用途"
                        />
                      </div>
                    </div>

                    <DialogFooter>
                      <Button variant="outline" onClick={() => setIsReportDialogOpen(false)}>
                        取消
                      </Button>
                      <Button onClick={generateReport}>
                        生成报告
                      </Button>
                    </DialogFooter>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>报告名称</TableHead>
                    <TableHead>时间范围</TableHead>
                    <TableHead>生成时间</TableHead>
                    <TableHead>生成者</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {auditReports.map((report) => (
                    <TableRow key={report.id}>
                      <TableCell>
                        <div>
                          <div className="font-medium">{report.name}</div>
                          <div className="text-xs text-muted-foreground">{report.description}</div>
                        </div>
                      </TableCell>
                      <TableCell>
                        {report.timeRange.start} 至 {report.timeRange.end}
                      </TableCell>
                      <TableCell>{new Date(report.generatedAt).toLocaleString()}</TableCell>
                      <TableCell>{report.generatedBy}</TableCell>
                      <TableCell>{getReportStatusBadge(report.status)}</TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button variant="ghost" size="sm">
                            <Eye className="w-4 h-4" />
                          </Button>
                          {report.status === 'completed' && (
                            <Button variant="ghost" size="sm">
                              <Download className="w-4 h-4" />
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 统计分析 */}
        <TabsContent value="analytics" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>操作类型分布</CardTitle>
                <CardDescription>各类型操作的数量统计</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <BarChart3 className="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <div>操作类型统计图表</div>
                  <div className="text-sm">显示各类操作的使用频率</div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>时间分布分析</CardTitle>
                <CardDescription>操作时间的分布情况</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <Clock className="w-12 h-12 mx-auto mb-4 opacity-50" />
                  <div>时间分布统计图表</div>
                  <div className="text-sm">显示操作的时间规律</div>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>关键指标统计</CardTitle>
              <CardDescription>重要的安全和操作指标</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-4">
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">{stats.uniqueUsers}</div>
                  <div className="text-sm text-muted-foreground">活跃用户数</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-green-600">
                    {((stats.totalLogs - stats.failedActions) / stats.totalLogs * 100).toFixed(1)}%
                  </div>
                  <div className="text-sm text-muted-foreground">操作成功率</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-orange-600">{stats.mostActiveUser}</div>
                  <div className="text-sm text-muted-foreground">最活跃用户</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">{stats.mostCommonAction}</div>
                  <div className="text-sm text-muted-foreground">最常见操作</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* 详情对话框 */}
      <Dialog open={isDetailDialogOpen} onOpenChange={setIsDetailDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>操作详情</DialogTitle>
            <DialogDescription>
              查看操作的完整信息和上下文
            </DialogDescription>
          </DialogHeader>
          
          {selectedLog && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>操作时间</Label>
                  <div className="font-mono text-sm">{selectedLog.timestamp}</div>
                </div>
                <div>
                  <Label>操作用户</Label>
                  <div>
                    <div className="font-medium">{selectedLog.userName}</div>
                    <div className="text-sm text-muted-foreground">{selectedLog.userEmail}</div>
                  </div>
                </div>
                <div>
                  <Label>操作类型</Label>
                  <div className="flex items-center space-x-2">
                    {getActionIcon(selectedLog.actionType)}
                    <span>{selectedLog.action}</span>
                  </div>
                </div>
                <div>
                  <Label>资源</Label>
                  <div>
                    <div className="font-medium">{selectedLog.resource}</div>
                    {selectedLog.resourceId && (
                      <div className="text-sm text-muted-foreground">{selectedLog.resourceId}</div>
                    )}
                  </div>
                </div>
                <div>
                  <Label>操作结果</Label>
                  <div>{getSuccessBadge(selectedLog.success)}</div>
                </div>
                <div>
                  <Label>风险等级</Label>
                  <div>{getRiskBadge(selectedLog.riskLevel)}</div>
                </div>
                <div>
                  <Label>IP地址</Label>
                  <div className="font-mono text-sm">{selectedLog.ipAddress}</div>
                </div>
                <div>
                  <Label>会话ID</Label>
                  <div className="font-mono text-sm">{selectedLog.sessionId}</div>
                </div>
              </div>
              
              <div>
                <Label>操作详情</Label>
                <div className="mt-1 p-3 bg-muted rounded">{selectedLog.details}</div>
              </div>
              
              <div>
                <Label>用户代理</Label>
                <div className="mt-1 p-3 bg-muted rounded text-xs break-all">
                  {selectedLog.userAgent}
                </div>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDetailDialogOpen(false)}>
              关闭
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}