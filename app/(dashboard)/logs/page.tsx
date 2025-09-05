'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Input } from '@/components/ui/Input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/Select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/Table'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/Dialog'
import { Label } from '@/components/ui/Label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { DatePickerWithRange } from '@/components/ui/DateRangePicker'
import { 
  FileText, AlertCircle, Info, CheckCircle, XCircle, Zap, 
  Search, Filter, Download, Eye, RefreshCw, Server, Database, Shield 
} from 'lucide-react'
import { dataService } from '@/lib/services/supabase'
import { DateRange } from 'react-day-picker'

interface LogEntry {
  id: string
  timestamp: string
  level: 'info' | 'warn' | 'error' | 'debug'
  module: string
  action: string
  user_id?: string
  user_name?: string
  ip_address?: string
  message: string
  details?: any
  request_id?: string
  duration_ms?: number
}

interface SystemMetric {
  id: string
  timestamp: string
  metric_name: string
  metric_value: number
  metric_unit?: string
  tags?: any
}

export default function LogsManagementPage() {
  const [activeTab, setActiveTab] = useState('logs')
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [metrics, setMetrics] = useState<SystemMetric[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [levelFilter, setLevelFilter] = useState('all')
  const [moduleFilter, setModuleFilter] = useState('all')
  const [dateRange, setDateRange] = useState<DateRange>()
  const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null)
  const [autoRefresh, setAutoRefresh] = useState(false)

  // 模拟日志数据
  const mockLogs: LogEntry[] = [
    {
      id: '1',
      timestamp: new Date().toISOString(),
      level: 'info',
      module: 'auth',
      action: 'user_login',
      user_id: 'user123',
      user_name: '张三',
      ip_address: '192.168.1.100',
      message: '用户成功登录',
      request_id: 'req_12345',
      duration_ms: 150
    },
    {
      id: '2',
      timestamp: new Date(Date.now() - 300000).toISOString(),
      level: 'warn',
      module: 'content',
      action: 'content_flagged',
      user_id: 'user456',
      user_name: '李四',
      ip_address: '192.168.1.101',
      message: '内容被系统标记为可疑',
      details: { content_id: 'content_789', reason: 'inappropriate_language' },
      request_id: 'req_12346'
    },
    {
      id: '3',
      timestamp: new Date(Date.now() - 600000).toISOString(),
      level: 'error',
      module: 'database',
      action: 'connection_failed',
      message: '数据库连接失败',
      details: { error: 'Connection timeout', retry_count: 3 },
      request_id: 'req_12347',
      duration_ms: 5000
    },
    {
      id: '4',
      timestamp: new Date(Date.now() - 900000).toISOString(),
      level: 'info',
      module: 'api',
      action: 'rate_limit_exceeded',
      user_id: 'user789',
      ip_address: '192.168.1.102',
      message: 'API 请求频率限制',
      details: { endpoint: '/api/v1/agents', current_rate: 120, limit: 100 },
      request_id: 'req_12348'
    },
    {
      id: '5',
      timestamp: new Date(Date.now() - 1200000).toISOString(),
      level: 'debug',
      module: 'cache',
      action: 'cache_miss',
      message: '缓存未命中',
      details: { key: 'user_profile_user123', ttl: 3600 },
      request_id: 'req_12349',
      duration_ms: 25
    }
  ]

  // 模拟系统指标数据
  const mockMetrics: SystemMetric[] = [
    {
      id: '1',
      timestamp: new Date().toISOString(),
      metric_name: 'cpu_usage',
      metric_value: 45.2,
      metric_unit: 'percent',
      tags: { server: 'web-01' }
    },
    {
      id: '2',
      timestamp: new Date().toISOString(),
      metric_name: 'memory_usage',
      metric_value: 68.5,
      metric_unit: 'percent',
      tags: { server: 'web-01' }
    },
    {
      id: '3',
      timestamp: new Date().toISOString(),
      metric_name: 'response_time',
      metric_value: 125,
      metric_unit: 'ms',
      tags: { endpoint: '/api/v1/users' }
    },
    {
      id: '4',
      timestamp: new Date().toISOString(),
      metric_name: 'active_connections',
      metric_value: 256,
      metric_unit: 'count',
      tags: { database: 'primary' }
    }
  ]

  useEffect(() => {
    loadLogs()
    loadMetrics()
  }, [])

  useEffect(() => {
    let interval: NodeJS.Timeout
    if (autoRefresh) {
      interval = setInterval(() => {
        loadLogs()
        loadMetrics()
      }, 30000) // 每30秒刷新
    }
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [autoRefresh])

  const loadLogs = async () => {
    try {
      setLoading(true)
      // 实际应用中应该从 Supabase 的 xq_system_logs 表获取数据
      setLogs(mockLogs)
    } catch (error) {
      console.error('加载日志失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const loadMetrics = async () => {
    try {
      // 实际应用中应该从 Supabase 的 xq_system_metrics 表获取数据
      setMetrics(mockMetrics)
    } catch (error) {
      console.error('加载指标数据失败:', error)
    }
  }

  const exportLogs = async () => {
    try {
      // 实际应用中应该调用导出API
      const dataStr = JSON.stringify(filteredLogs, null, 2)
      const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr)
      
      const exportFileDefaultName = `system_logs_${new Date().toISOString().split('T')[0]}.json`
      
      const linkElement = document.createElement('a')
      linkElement.setAttribute('href', dataUri)
      linkElement.setAttribute('download', exportFileDefaultName)
      linkElement.click()
    } catch (error) {
      console.error('导出日志失败:', error)
    }
  }

  const filteredLogs = logs.filter(log => {
    const matchesSearch = log.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         log.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         log.module.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesLevel = levelFilter === 'all' || log.level === levelFilter
    const matchesModule = moduleFilter === 'all' || log.module === moduleFilter
    
    // 日期范围筛选
    let matchesDateRange = true
    if (dateRange?.from && dateRange?.to) {
      const logDate = new Date(log.timestamp)
      matchesDateRange = logDate >= dateRange.from && logDate <= dateRange.to
    }
    
    return matchesSearch && matchesLevel && matchesModule && matchesDateRange
  })

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'error':
        return <XCircle className="w-4 h-4 text-red-500" />
      case 'warn':
        return <AlertCircle className="w-4 h-4 text-yellow-500" />
      case 'info':
        return <Info className="w-4 h-4 text-blue-500" />
      case 'debug':
        return <FileText className="w-4 h-4 text-gray-500" />
      default:
        return <Info className="w-4 h-4" />
    }
  }

  const getLevelBadge = (level: string) => {
    const variants = {
      error: 'destructive',
      warn: 'secondary',
      info: 'outline',
      debug: 'outline'
    } as const
    
    return (
      <Badge variant={variants[level as keyof typeof variants] || 'outline'}>
        {level.toUpperCase()}
      </Badge>
    )
  }

  const getModuleIcon = (module: string) => {
    switch (module) {
      case 'auth':
        return <Shield className="w-4 h-4" />
      case 'database':
        return <Database className="w-4 h-4" />
      case 'api':
        return <Server className="w-4 h-4" />
      default:
        return <FileText className="w-4 h-4" />
    }
  }

  const stats = {
    totalLogs: logs.length,
    errorLogs: logs.filter(l => l.level === 'error').length,
    warnLogs: logs.filter(l => l.level === 'warn').length,
    todayLogs: logs.filter(l => {
      const today = new Date().toDateString()
      return new Date(l.timestamp).toDateString() === today
    }).length
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">日志管理</h1>
          <p className="text-muted-foreground">
            系统日志监控、查询分析和运维指标
          </p>
        </div>

        {/* 统计卡片 */}
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">总日志数</CardTitle>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalLogs}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">错误日志</CardTitle>
              <XCircle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">{stats.errorLogs}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">警告日志</CardTitle>
              <AlertCircle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-yellow-600">{stats.warnLogs}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">今日日志</CardTitle>
              <Zap className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">{stats.todayLogs}</div>
            </CardContent>
          </Card>
        </div>

        {/* 主要内容区域 */}
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="logs" className="flex items-center gap-2">
              <FileText className="w-4 h-4" />
              系统日志
            </TabsTrigger>
            <TabsTrigger value="metrics" className="flex items-center gap-2">
              <Zap className="w-4 h-4" />
              系统指标
            </TabsTrigger>
            <TabsTrigger value="alerts" className="flex items-center gap-2">
              <AlertCircle className="w-4 h-4" />
              告警管理
            </TabsTrigger>
          </TabsList>

          {/* 系统日志 */}
          <TabsContent value="logs" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle className="flex items-center gap-2">
                      <Filter className="h-5 w-5" />
                      日志筛选
                    </CardTitle>
                    <CardDescription>筛选和搜索系统日志</CardDescription>
                  </div>
                  <div className="flex gap-2">
                    <Button 
                      variant="outline" 
                      onClick={() => setAutoRefresh(!autoRefresh)}
                      className={autoRefresh ? 'bg-green-50 border-green-200' : ''}
                    >
                      <RefreshCw className={`w-4 h-4 mr-2 ${autoRefresh ? 'animate-spin' : ''}`} />
                      {autoRefresh ? '自动刷新中' : '自动刷新'}
                    </Button>
                    <Button variant="outline" onClick={exportLogs}>
                      <Download className="w-4 h-4 mr-2" />
                      导出日志
                    </Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex gap-4 flex-wrap">
                    <div className="flex-1 min-w-[300px]">
                      <div className="relative">
                        <Search className="absolute left-2 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          placeholder="搜索日志内容、操作或用户..."
                          className="pl-8"
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                        />
                      </div>
                    </div>
                    <Select value={levelFilter} onValueChange={setLevelFilter}>
                      <SelectTrigger className="w-[140px]">
                        <SelectValue placeholder="日志级别" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">全部级别</SelectItem>
                        <SelectItem value="error">错误</SelectItem>
                        <SelectItem value="warn">警告</SelectItem>
                        <SelectItem value="info">信息</SelectItem>
                        <SelectItem value="debug">调试</SelectItem>
                      </SelectContent>
                    </Select>
                    <Select value={moduleFilter} onValueChange={setModuleFilter}>
                      <SelectTrigger className="w-[140px]">
                        <SelectValue placeholder="模块" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">全部模块</SelectItem>
                        <SelectItem value="auth">认证</SelectItem>
                        <SelectItem value="content">内容</SelectItem>
                        <SelectItem value="database">数据库</SelectItem>
                        <SelectItem value="api">API</SelectItem>
                        <SelectItem value="cache">缓存</SelectItem>
                      </SelectContent>
                    </Select>
                    <DatePickerWithRange 
                      date={dateRange}
                      onDateChange={setDateRange}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>日志记录</CardTitle>
                <CardDescription>
                  共找到 {filteredLogs.length} 条日志记录
                </CardDescription>
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="text-center py-4">加载中...</div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>时间</TableHead>
                        <TableHead>级别</TableHead>
                        <TableHead>模块</TableHead>
                        <TableHead>用户</TableHead>
                        <TableHead>消息</TableHead>
                        <TableHead>IP地址</TableHead>
                        <TableHead>操作</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredLogs.map((log) => (
                        <TableRow key={log.id}>
                          <TableCell className="font-mono text-sm">
                            {new Date(log.timestamp).toLocaleString('zh-CN')}
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-2">
                              {getLevelIcon(log.level)}
                              {getLevelBadge(log.level)}
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-2">
                              {getModuleIcon(log.module)}
                              <Badge variant="outline">{log.module}</Badge>
                            </div>
                          </TableCell>
                          <TableCell>{log.user_name || '-'}</TableCell>
                          <TableCell className="max-w-[300px] truncate">
                            {log.message}
                          </TableCell>
                          <TableCell className="font-mono text-sm">
                            {log.ip_address || '-'}
                          </TableCell>
                          <TableCell>
                            <Dialog>
                              <DialogTrigger asChild>
                                <Button variant="outline" size="sm" onClick={() => setSelectedLog(log)}>
                                  <Eye className="w-4 h-4" />
                                </Button>
                              </DialogTrigger>
                              <DialogContent className="max-w-4xl">
                                <DialogHeader>
                                  <DialogTitle>日志详情</DialogTitle>
                                  <DialogDescription>
                                    查看完整的日志记录信息
                                  </DialogDescription>
                                </DialogHeader>
                                {selectedLog && (
                                  <div className="space-y-4">
                                    <div className="grid grid-cols-2 gap-4">
                                      <div>
                                        <Label>时间戳</Label>
                                        <div className="mt-1 p-2 border rounded-md font-mono text-sm">
                                          {new Date(selectedLog.timestamp).toLocaleString('zh-CN')}
                                        </div>
                                      </div>
                                      <div>
                                        <Label>请求ID</Label>
                                        <div className="mt-1 p-2 border rounded-md font-mono text-sm">
                                          {selectedLog.request_id || '-'}
                                        </div>
                                      </div>
                                      <div>
                                        <Label>级别</Label>
                                        <div className="mt-1">{getLevelBadge(selectedLog.level)}</div>
                                      </div>
                                      <div>
                                        <Label>模块</Label>
                                        <div className="mt-1">
                                          <Badge variant="outline">{selectedLog.module}</Badge>
                                        </div>
                                      </div>
                                      <div>
                                        <Label>用户</Label>
                                        <div className="mt-1 p-2 border rounded-md">
                                          {selectedLog.user_name || '-'}
                                        </div>
                                      </div>
                                      <div>
                                        <Label>IP地址</Label>
                                        <div className="mt-1 p-2 border rounded-md font-mono text-sm">
                                          {selectedLog.ip_address || '-'}
                                        </div>
                                      </div>
                                    </div>
                                    <div>
                                      <Label>消息</Label>
                                      <div className="mt-1 p-2 border rounded-md">
                                        {selectedLog.message}
                                      </div>
                                    </div>
                                    {selectedLog.details && (
                                      <div>
                                        <Label>详细信息</Label>
                                        <pre className="mt-1 p-2 border rounded-md bg-gray-50 text-sm overflow-x-auto">
                                          {JSON.stringify(selectedLog.details, null, 2)}
                                        </pre>
                                      </div>
                                    )}
                                    {selectedLog.duration_ms && (
                                      <div>
                                        <Label>执行时长</Label>
                                        <div className="mt-1 p-2 border rounded-md">
                                          {selectedLog.duration_ms} 毫秒
                                        </div>
                                      </div>
                                    )}
                                  </div>
                                )}
                              </DialogContent>
                            </Dialog>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* 系统指标 */}
          <TabsContent value="metrics" className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              {metrics.map((metric) => (
                <Card key={metric.id}>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      {metric.metric_name.replace('_', ' ').toUpperCase()}
                    </CardTitle>
                    <Zap className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {metric.metric_value}{metric.metric_unit && ` ${metric.metric_unit}`}
                    </div>
                    {metric.tags && (
                      <div className="text-xs text-muted-foreground mt-1">
                        {Object.entries(metric.tags).map(([key, value]) => (
                          <span key={key} className="mr-2">
                            {key}: {value}
                          </span>
                        ))}
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          {/* 告警管理 */}
          <TabsContent value="alerts" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>系统告警</CardTitle>
                <CardDescription>系统告警和通知管理</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <AlertCircle className="h-12 w-12 mx-auto mb-4" />
                  <p>暂无活跃告警</p>
                  <p className="text-sm">系统运行正常</p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}