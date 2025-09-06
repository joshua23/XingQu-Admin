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
import { Checkbox } from '@/components/ui/Checkbox'
import { 
  BarChart3, LineChart, PieChart, TrendingUp, Download, 
  Calendar, Clock, Users, DollarSign, Eye, Settings, Plus, 
  FileSpreadsheet, FileText, Image, Share2, RefreshCw
} from 'lucide-react'
import { dataService } from '@/lib/services/supabase'
import { DateRange } from 'react-day-picker'

interface Report {
  id: string
  name: string
  description: string
  type: 'user_analytics' | 'content_analytics' | 'revenue_report' | 'system_performance'
  status: 'draft' | 'scheduled' | 'running' | 'completed' | 'failed'
  schedule_type: 'once' | 'daily' | 'weekly' | 'monthly'
  last_run?: string
  next_run?: string
  created_by: string
  created_at: string
  file_url?: string
  parameters?: any
}

interface ReportTemplate {
  id: string
  name: string
  description: string
  type: string
  icon: React.ReactNode
  parameters: Array<{
    name: string
    label: string
    type: 'date_range' | 'select' | 'multi_select' | 'text'
    options?: string[]
    required: boolean
  }>
}

export default function ReportsPage() {
  const [activeTab, setActiveTab] = useState('reports')
  const [reports, setReports] = useState<Report[]>([])
  const [templates, setTemplates] = useState<ReportTemplate[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedReport, setSelectedReport] = useState<Report | null>(null)
  const [createReportOpen, setCreateReportOpen] = useState(false)
  const [selectedTemplate, setSelectedTemplate] = useState<ReportTemplate | null>(null)

  // 报表模板
  const reportTemplates: ReportTemplate[] = [
    {
      id: '1',
      name: '用户增长报告',
      description: '分析用户注册、活跃度和留存情况',
      type: 'user_analytics',
      icon: <Users className="w-5 h-5" />,
      parameters: [
        { name: 'date_range', label: '日期范围', type: 'date_range', required: true },
        { name: 'user_segments', label: '用户群体', type: 'multi_select', options: ['新用户', '活跃用户', '会员用户'], required: false },
        { name: 'metrics', label: '指标', type: 'multi_select', options: ['注册数', '活跃数', '留存率'], required: true }
      ]
    },
    {
      id: '2',
      name: '内容统计报告',
      description: '内容创建、审核和热度分析',
      type: 'content_analytics',
      icon: <FileText className="w-5 h-5" />,
      parameters: [
        { name: 'date_range', label: '日期范围', type: 'date_range', required: true },
        { name: 'content_types', label: '内容类型', type: 'multi_select', options: ['智能体', '聊天', '素材', '帖子'], required: false },
        { name: 'status', label: '审核状态', type: 'select', options: ['全部', '待审核', '已通过', '已拒绝'], required: false }
      ]
    },
    {
      id: '3',
      name: '收入分析报告',
      description: '订阅、支付和收入趋势分析',
      type: 'revenue_report',
      icon: <DollarSign className="w-5 h-5" />,
      parameters: [
        { name: 'date_range', label: '日期范围', type: 'date_range', required: true },
        { name: 'revenue_type', label: '收入类型', type: 'multi_select', options: ['订阅费', '单次购买', '广告收入'], required: false },
        { name: 'currency', label: '货币', type: 'select', options: ['CNY', 'USD'], required: true }
      ]
    },
    {
      id: '4',
      name: '系统性能报告',
      description: '服务器性能、响应时间和错误统计',
      type: 'system_performance',
      icon: <BarChart3 className="w-5 h-5" />,
      parameters: [
        { name: 'date_range', label: '日期范围', type: 'date_range', required: true },
        { name: 'metrics', label: '性能指标', type: 'multi_select', options: ['CPU使用率', '内存使用率', '响应时间', '错误率'], required: true },
        { name: 'servers', label: '服务器', type: 'multi_select', options: ['web-01', 'web-02', 'db-01'], required: false }
      ]
    }
  ]

  // 模拟报告数据
  const mockReports: Report[] = [
    {
      id: '1',
      name: '2024年第一季度用户增长报告',
      description: '分析Q1用户注册、活跃和留存情况',
      type: 'user_analytics',
      status: 'completed',
      schedule_type: 'once',
      last_run: new Date(Date.now() - 86400000).toISOString(),
      created_by: '系统管理员',
      created_at: new Date(Date.now() - 172800000).toISOString(),
      file_url: '/reports/q1_user_growth.pdf',
      parameters: {
        date_range: { start: '2024-01-01', end: '2024-03-31' },
        metrics: ['注册数', '活跃数', '留存率']
      }
    },
    {
      id: '2',
      name: '内容审核周报',
      description: '每周内容审核情况统计',
      type: 'content_analytics',
      status: 'scheduled',
      schedule_type: 'weekly',
      next_run: new Date(Date.now() + 86400000 * 2).toISOString(),
      last_run: new Date(Date.now() - 86400000 * 5).toISOString(),
      created_by: '内容管理员',
      created_at: new Date(Date.now() - 86400000 * 30).toISOString(),
      file_url: '/reports/content_moderation_weekly.xlsx'
    },
    {
      id: '3',
      name: '月度收入分析',
      description: '每月订阅和支付收入分析',
      type: 'revenue_report',
      status: 'running',
      schedule_type: 'monthly',
      last_run: new Date().toISOString(),
      created_by: '财务管理员',
      created_at: new Date(Date.now() - 86400000 * 60).toISOString()
    },
    {
      id: '4',
      name: '系统性能监控报告',
      description: '服务器性能和响应时间分析',
      type: 'system_performance',
      status: 'failed',
      schedule_type: 'daily',
      last_run: new Date(Date.now() - 3600000).toISOString(),
      created_by: '运维工程师',
      created_at: new Date(Date.now() - 86400000 * 7).toISOString()
    }
  ]

  useEffect(() => {
    loadReports()
    setTemplates(reportTemplates)
  }, [])

  const loadReports = async () => {
    try {
      setLoading(true)
      // 实际应用中应该从 Supabase 的 xq_reports 表获取数据
      setReports(mockReports)
    } catch (error) {
      console.error('加载报告失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const generateReport = async (templateId: string, parameters: any) => {
    try {
      // 实际应用中应该调用报告生成API
      const template = templates.find(t => t.id === templateId)
      if (!template) return

      const newReport: Report = {
        id: Date.now().toString(),
        name: `${template.name} - ${new Date().toLocaleDateString('zh-CN')}`,
        description: template.description,
        type: template.type as any,
        status: 'running',
        schedule_type: 'once',
        created_by: '当前用户',
        created_at: new Date().toISOString(),
        parameters
      }

      setReports(prev => [newReport, ...prev])
      setCreateReportOpen(false)
      setSelectedTemplate(null)

      // 模拟报告生成完成
      setTimeout(() => {
        setReports(prev => prev.map(r => 
          r.id === newReport.id 
            ? { ...r, status: 'completed' as const, file_url: `/reports/${r.id}.pdf` }
            : r
        ))
      }, 3000)
    } catch (error) {
      console.error('生成报告失败:', error)
    }
  }

  const downloadReport = async (report: Report) => {
    try {
      // 实际应用中应该从服务器下载文件
      console.log('下载报告:', report.name)
    } catch (error) {
      console.error('下载报告失败:', error)
    }
  }

  const getStatusBadge = (status: string) => {
    const variants = {
      draft: 'secondary',
      scheduled: 'outline',
      running: 'default',
      completed: 'outline',
      failed: 'destructive'
    } as const

    const labels = {
      draft: '草稿',
      scheduled: '已计划',
      running: '运行中',
      completed: '已完成',
      failed: '失败'
    }

    return (
      <Badge variant={variants[status as keyof typeof variants] || 'outline'}>
        {labels[status as keyof typeof labels] || status}
      </Badge>
    )
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'user_analytics':
        return <Users className="w-4 h-4" />
      case 'content_analytics':
        return <FileText className="w-4 h-4" />
      case 'revenue_report':
        return <DollarSign className="w-4 h-4" />
      case 'system_performance':
        return <BarChart3 className="w-4 h-4" />
      default:
        return <FileSpreadsheet className="w-4 h-4" />
    }
  }

  const stats = {
    totalReports: reports.length,
    completedReports: reports.filter(r => r.status === 'completed').length,
    scheduledReports: reports.filter(r => r.status === 'scheduled').length,
    runningReports: reports.filter(r => r.status === 'running').length
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">报表中心</h1>
          <p className="text-muted-foreground">
            生成和管理各类数据分析报告
          </p>
        </div>

        {/* 统计卡片 */}
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">总报告数</CardTitle>
              <FileSpreadsheet className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalReports}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">已完成</CardTitle>
              <Eye className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{stats.completedReports}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">已计划</CardTitle>
              <Calendar className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">{stats.scheduledReports}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">运行中</CardTitle>
              <RefreshCw className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-orange-600">{stats.runningReports}</div>
            </CardContent>
          </Card>
        </div>

        {/* 主要内容区域 */}
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="reports" className="flex items-center gap-2">
              <FileSpreadsheet className="w-4 h-4" />
              我的报告
            </TabsTrigger>
            <TabsTrigger value="templates" className="flex items-center gap-2">
              <Settings className="w-4 h-4" />
              报告模板
            </TabsTrigger>
          </TabsList>

          {/* 我的报告 */}
          <TabsContent value="reports" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>报告列表</CardTitle>
                    <CardDescription>查看和管理生成的报告</CardDescription>
                  </div>
                  <Dialog open={createReportOpen} onOpenChange={setCreateReportOpen}>
                    <DialogTrigger asChild>
                      <Button>
                        <Plus className="w-4 h-4 mr-2" />
                        生成报告
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="max-w-2xl">
                      <DialogHeader>
                        <DialogTitle>生成新报告</DialogTitle>
                        <DialogDescription>
                          选择报告模板并配置参数
                        </DialogDescription>
                      </DialogHeader>
                      {!selectedTemplate ? (
                        <div className="space-y-4">
                          <h3 className="text-lg font-semibold">选择报告模板</h3>
                          <div className="grid gap-4 md:grid-cols-2">
                            {templates.map((template) => (
                              <Card 
                                key={template.id} 
                                className="cursor-pointer hover:shadow-md transition-shadow"
                                onClick={() => setSelectedTemplate(template)}
                              >
                                <CardHeader>
                                  <CardTitle className="flex items-center gap-2 text-base">
                                    {template.icon}
                                    {template.name}
                                  </CardTitle>
                                  <CardDescription>{template.description}</CardDescription>
                                </CardHeader>
                              </Card>
                            ))}
                          </div>
                        </div>
                      ) : (
                        <ReportConfigForm 
                          template={selectedTemplate}
                          onGenerate={(parameters) => generateReport(selectedTemplate.id, parameters)}
                          onBack={() => setSelectedTemplate(null)}
                        />
                      )}
                    </DialogContent>
                  </Dialog>
                </div>
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="text-center py-4">加载中...</div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>报告名称</TableHead>
                        <TableHead>类型</TableHead>
                        <TableHead>状态</TableHead>
                        <TableHead>计划类型</TableHead>
                        <TableHead>最后运行</TableHead>
                        <TableHead>创建者</TableHead>
                        <TableHead>操作</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {reports.map((report) => (
                        <TableRow key={report.id}>
                          <TableCell className="font-medium max-w-[300px] truncate">
                            {report.name}
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-2">
                              {getTypeIcon(report.type)}
                              <span className="text-sm">
                                {report.type.replace('_', ' ')}
                              </span>
                            </div>
                          </TableCell>
                          <TableCell>
                            {getStatusBadge(report.status)}
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline">
                              {report.schedule_type === 'once' ? '一次性' : 
                               report.schedule_type === 'daily' ? '每日' :
                               report.schedule_type === 'weekly' ? '每周' : '每月'}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            {report.last_run ? 
                              new Date(report.last_run).toLocaleDateString('zh-CN') : '-'}
                          </TableCell>
                          <TableCell>{report.created_by}</TableCell>
                          <TableCell>
                            <div className="flex gap-2">
                              <Dialog>
                                <DialogTrigger asChild>
                                  <Button variant="outline" size="sm" onClick={() => setSelectedReport(report)}>
                                    <Eye className="w-4 h-4" />
                                  </Button>
                                </DialogTrigger>
                                <DialogContent>
                                  <DialogHeader>
                                    <DialogTitle>报告详情</DialogTitle>
                                    <DialogDescription>查看报告配置和执行信息</DialogDescription>
                                  </DialogHeader>
                                  {selectedReport && (
                                    <div className="space-y-4">
                                      <div>
                                        <Label>报告名称</Label>
                                        <div className="mt-1 p-2 border rounded-md">{selectedReport.name}</div>
                                      </div>
                                      <div>
                                        <Label>描述</Label>
                                        <div className="mt-1 p-2 border rounded-md">{selectedReport.description}</div>
                                      </div>
                                      <div className="grid grid-cols-2 gap-4">
                                        <div>
                                          <Label>状态</Label>
                                          <div className="mt-1">{getStatusBadge(selectedReport.status)}</div>
                                        </div>
                                        <div>
                                          <Label>计划类型</Label>
                                          <div className="mt-1">
                                            <Badge variant="outline">
                                              {selectedReport.schedule_type === 'once' ? '一次性' : 
                                               selectedReport.schedule_type === 'daily' ? '每日' :
                                               selectedReport.schedule_type === 'weekly' ? '每周' : '每月'}
                                            </Badge>
                                          </div>
                                        </div>
                                      </div>
                                      {selectedReport.parameters && (
                                        <div>
                                          <Label>参数配置</Label>
                                          <pre className="mt-1 p-2 border rounded-md bg-gray-50 text-sm overflow-x-auto">
                                            {JSON.stringify(selectedReport.parameters, null, 2)}
                                          </pre>
                                        </div>
                                      )}
                                      {selectedReport.status === 'completed' && selectedReport.file_url && (
                                        <div className="pt-4">
                                          <Button onClick={() => downloadReport(selectedReport)}>
                                            <Download className="w-4 h-4 mr-2" />
                                            下载报告
                                          </Button>
                                        </div>
                                      )}
                                    </div>
                                  )}
                                </DialogContent>
                              </Dialog>
                              {report.status === 'completed' && report.file_url && (
                                <Button variant="outline" size="sm" onClick={() => downloadReport(report)}>
                                  <Download className="w-4 h-4" />
                                </Button>
                              )}
                              {report.status === 'running' && (
                                <Button variant="outline" size="sm" disabled>
                                  <RefreshCw className="w-4 h-4 animate-spin" />
                                </Button>
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
          </TabsContent>

          {/* 报告模板 */}
          <TabsContent value="templates" className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              {templates.map((template) => (
                <Card key={template.id}>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      {template.icon}
                      {template.name}
                    </CardTitle>
                    <CardDescription>{template.description}</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2">
                      <div className="text-sm font-medium">配置参数:</div>
                      <div className="space-y-1">
                        {template.parameters.map((param, index) => (
                          <div key={index} className="flex items-center justify-between text-sm">
                            <span>{param.label}</span>
                            <Badge variant="outline" className="text-xs">
                              {param.required ? '必需' : '可选'}
                            </Badge>
                          </div>
                        ))}
                      </div>
                    </div>
                    <div className="pt-4">
                      <Dialog open={createReportOpen} onOpenChange={setCreateReportOpen}>
                        <DialogTrigger asChild>
                          <Button 
                            variant="outline" 
                            className="w-full"
                            onClick={() => setSelectedTemplate(template)}
                          >
                            使用模板
                          </Button>
                        </DialogTrigger>
                      </Dialog>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}

// 报告配置表单组件
function ReportConfigForm({ 
  template, 
  onGenerate, 
  onBack 
}: {
  template: ReportTemplate
  onGenerate: (parameters: any) => void
  onBack: () => void
}) {
  const [parameters, setParameters] = useState<any>({})

  const handleParameterChange = (paramName: string, value: any) => {
    setParameters(prev => ({ ...prev, [paramName]: value }))
  }

  const handleSubmit = () => {
    // 验证必需参数
    const missingRequired = template.parameters
      .filter(p => p.required)
      .find(p => !parameters[p.name])
    
    if (missingRequired) {
      alert(`请填写必需参数: ${missingRequired.label}`)
      return
    }

    onGenerate(parameters)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <Button variant="outline" size="sm" onClick={onBack}>
          ← 返回
        </Button>
        <div>
          <h3 className="text-lg font-semibold flex items-center gap-2">
            {template.icon}
            {template.name}
          </h3>
          <p className="text-sm text-muted-foreground">{template.description}</p>
        </div>
      </div>

      <div className="space-y-4">
        {template.parameters.map((param) => (
          <div key={param.name}>
            <Label>
              {param.label} {param.required && <span className="text-red-500">*</span>}
            </Label>
            {param.type === 'date_range' && (
              <div className="mt-1">
                <DatePickerWithRange 
                  onDateChange={(range) => handleParameterChange(param.name, range)}
                />
              </div>
            )}
            {param.type === 'select' && param.options && (
              <Select onValueChange={(value) => handleParameterChange(param.name, value)}>
                <SelectTrigger className="mt-1">
                  <SelectValue placeholder={`选择${param.label}`} />
                </SelectTrigger>
                <SelectContent>
                  {param.options.map((option) => (
                    <SelectItem key={option} value={option}>{option}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )}
            {param.type === 'multi_select' && param.options && (
              <div className="mt-1 space-y-2">
                {param.options.map((option) => (
                  <div key={option} className="flex items-center space-x-2">
                    <Checkbox
                      id={`${param.name}_${option}`}
                      onCheckedChange={(checked) => {
                        const current = parameters[param.name] || []
                        const newValue = checked 
                          ? [...current, option]
                          : current.filter((v: string) => v !== option)
                        handleParameterChange(param.name, newValue)
                      }}
                    />
                    <Label htmlFor={`${param.name}_${option}`}>{option}</Label>
                  </div>
                ))}
              </div>
            )}
            {param.type === 'text' && (
              <Input
                className="mt-1"
                placeholder={param.label}
                onChange={(e) => handleParameterChange(param.name, e.target.value)}
              />
            )}
          </div>
        ))}
      </div>

      <div className="flex gap-2 pt-4">
        <Button onClick={handleSubmit} className="flex-1">
          生成报告
        </Button>
        <Button variant="outline" onClick={onBack}>
          取消
        </Button>
      </div>
    </div>
  )
}