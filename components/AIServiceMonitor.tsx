/**
 * 星趣后台管理系统 - AI服务监控组件
 * 监控和优化AI服务使用
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Progress } from '@/components/ui/progress'
import {
  Brain,
  Zap,
  DollarSign,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle,
  Clock,
  Activity,
  BarChart3,
  PieChart,
  RefreshCw,
  Settings,
  Eye,
  Cpu,
  Globe,
  Server,
  Database
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

// 类型定义
interface AIService {
  id: string
  name: string
  provider: 'openai' | 'anthropic' | 'google' | 'baidu' | 'alibaba'
  type: 'text' | 'image' | 'audio' | 'video' | 'multimodal'
  status: 'active' | 'inactive' | 'error' | 'maintenance'
  apiCalls: number
  successRate: number
  avgResponseTime: number // ms
  dailyCost: number
  monthlyLimit: number
  usagePercentage: number
  lastUsed: string
}

interface AIUsageStats {
  totalCalls: number
  totalCost: number
  avgResponseTime: number
  successRate: number
  topService: string
  dailyGrowth: number
  errorCount: number
  activeServices: number
}

interface AIAlert {
  id: string
  type: 'cost' | 'usage' | 'performance' | 'error'
  severity: 'low' | 'medium' | 'high' | 'critical'
  service: string
  message: string
  timestamp: string
  resolved: boolean
}

interface CostBreakdown {
  service: string
  provider: string
  dailyCost: number
  monthlyCost: number
  percentage: number
}

export default function AIServiceMonitor() {
  const [services, setServices] = useState<AIService[]>([])
  const [stats, setStats] = useState<AIUsageStats>({
    totalCalls: 0,
    totalCost: 0,
    avgResponseTime: 0,
    successRate: 0,
    topService: '',
    dailyGrowth: 0,
    errorCount: 0,
    activeServices: 0
  })
  const [alerts, setAlerts] = useState<AIAlert[]>([])
  const [costBreakdown, setCostBreakdown] = useState<CostBreakdown[]>([])
  const [loading, setLoading] = useState(true)
  const [timeRange, setTimeRange] = useState('24h')
  const [selectedProvider, setSelectedProvider] = useState('all')

  useEffect(() => {
    fetchAIServices()
    fetchUsageStats()
    fetchAlerts()
    fetchCostBreakdown()
  }, [timeRange, selectedProvider])

  // 获取AI服务数据
  const fetchAIServices = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const mockServices: AIService[] = [
        {
          id: '1',
          name: 'GPT-4 文本生成',
          provider: 'openai',
          type: 'text',
          status: 'active',
          apiCalls: 15420,
          successRate: 98.5,
          avgResponseTime: 1200,
          dailyCost: 145.30,
          monthlyLimit: 10000,
          usagePercentage: 65,
          lastUsed: '2025-09-05 14:30:00'
        },
        {
          id: '2',
          name: 'Claude 内容审核',
          provider: 'anthropic',
          type: 'text',
          status: 'active',
          apiCalls: 8760,
          successRate: 99.2,
          avgResponseTime: 800,
          dailyCost: 89.50,
          monthlyLimit: 8000,
          usagePercentage: 82,
          lastUsed: '2025-09-05 14:28:00'
        },
        {
          id: '3',
          name: 'DALL-E 图像生成',
          provider: 'openai',
          type: 'image',
          status: 'active',
          apiCalls: 2340,
          successRate: 96.8,
          avgResponseTime: 3500,
          dailyCost: 78.20,
          monthlyLimit: 3000,
          usagePercentage: 45,
          lastUsed: '2025-09-05 14:25:00'
        },
        {
          id: '4',
          name: '百度语音识别',
          provider: 'baidu',
          type: 'audio',
          status: 'active',
          apiCalls: 5670,
          successRate: 94.3,
          avgResponseTime: 950,
          dailyCost: 32.80,
          monthlyLimit: 15000,
          usagePercentage: 28,
          lastUsed: '2025-09-05 14:20:00'
        },
        {
          id: '5',
          name: 'Google Vision',
          provider: 'google',
          type: 'image',
          status: 'error',
          apiCalls: 120,
          successRate: 0,
          avgResponseTime: 0,
          dailyCost: 0,
          monthlyLimit: 5000,
          usagePercentage: 0,
          lastUsed: '2025-09-04 16:45:00'
        }
      ]
      
      setServices(mockServices)
    } catch (error) {
      console.error('获取AI服务数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  // 获取使用统计
  const fetchUsageStats = async () => {
    try {
      setStats({
        totalCalls: 32310,
        totalCost: 345.80,
        avgResponseTime: 1187,
        successRate: 97.3,
        topService: 'GPT-4 文本生成',
        dailyGrowth: 12.5,
        errorCount: 23,
        activeServices: 4
      })
    } catch (error) {
      console.error('获取使用统计失败:', error)
    }
  }

  // 获取告警信息
  const fetchAlerts = async () => {
    try {
      const mockAlerts: AIAlert[] = [
        {
          id: '1',
          type: 'cost',
          severity: 'high',
          service: 'Claude 内容审核',
          message: '日消费接近预算上限，当前已使用82%',
          timestamp: '2025-09-05 14:30:00',
          resolved: false
        },
        {
          id: '2',
          type: 'error',
          severity: 'critical',
          service: 'Google Vision',
          message: 'API服务连接失败，已持续2小时',
          timestamp: '2025-09-05 12:15:00',
          resolved: false
        },
        {
          id: '3',
          type: 'performance',
          severity: 'medium',
          service: 'DALL-E 图像生成',
          message: '响应时间超过阈值，平均延迟3.5秒',
          timestamp: '2025-09-05 13:45:00',
          resolved: false
        }
      ]
      
      setAlerts(mockAlerts)
    } catch (error) {
      console.error('获取告警信息失败:', error)
    }
  }

  // 获取费用分析
  const fetchCostBreakdown = async () => {
    try {
      const mockCostBreakdown: CostBreakdown[] = [
        {
          service: 'GPT-4 文本生成',
          provider: 'OpenAI',
          dailyCost: 145.30,
          monthlyCost: 4359.00,
          percentage: 42.0
        },
        {
          service: 'Claude 内容审核',
          provider: 'Anthropic',
          dailyCost: 89.50,
          monthlyCost: 2685.00,
          percentage: 25.9
        },
        {
          service: 'DALL-E 图像生成',
          provider: 'OpenAI',
          dailyCost: 78.20,
          monthlyCost: 2346.00,
          percentage: 22.6
        },
        {
          service: '百度语音识别',
          provider: '百度',
          dailyCost: 32.80,
          monthlyCost: 984.00,
          percentage: 9.5
        }
      ]
      
      setCostBreakdown(mockCostBreakdown)
    } catch (error) {
      console.error('获取费用分析失败:', error)
    }
  }

  // 过滤服务
  const filteredServices = useMemo(() => {
    return services.filter(service => 
      selectedProvider === 'all' || service.provider === selectedProvider
    )
  }, [services, selectedProvider])

  // 获取状态样式
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-100 text-green-700 border-green-200">运行中</Badge>
      case 'inactive':
        return <Badge variant="outline" className="text-gray-600">已停用</Badge>
      case 'error':
        return <Badge className="bg-red-100 text-red-700 border-red-200">错误</Badge>
      case 'maintenance':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">维护中</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getProviderBadge = (provider: string) => {
    const colors = {
      openai: 'bg-blue-100 text-blue-700 border-blue-200',
      anthropic: 'bg-purple-100 text-purple-700 border-purple-200',
      google: 'bg-orange-100 text-orange-700 border-orange-200',
      baidu: 'bg-red-100 text-red-700 border-red-200',
      alibaba: 'bg-green-100 text-green-700 border-green-200'
    }
    
    const names = {
      openai: 'OpenAI',
      anthropic: 'Anthropic',
      google: 'Google',
      baidu: '百度',
      alibaba: '阿里云'
    }
    
    return (
      <Badge className={colors[provider as keyof typeof colors] || 'bg-gray-100 text-gray-700'}>
        {names[provider as keyof typeof names] || provider}
      </Badge>
    )
  }

  const getTypeBadge = (type: string) => {
    const icons = {
      text: <Brain className="w-3 h-3 mr-1" />,
      image: <Eye className="w-3 h-3 mr-1" />,
      audio: <Activity className="w-3 h-3 mr-1" />,
      video: <Globe className="w-3 h-3 mr-1" />,
      multimodal: <Cpu className="w-3 h-3 mr-1" />
    }
    
    const names = {
      text: '文本',
      image: '图像',
      audio: '音频',
      video: '视频',
      multimodal: '多模态'
    }
    
    return (
      <Badge variant="outline" className="flex items-center">
        {icons[type as keyof typeof icons]}
        {names[type as keyof typeof names] || type}
      </Badge>
    )
  }

  const getAlertSeverityBadge = (severity: string) => {
    switch (severity) {
      case 'critical':
        return <Badge className="bg-red-600 text-white">严重</Badge>
      case 'high':
        return <Badge className="bg-red-100 text-red-700 border-red-200">高</Badge>
      case 'medium':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">中</Badge>
      case 'low':
        return <Badge variant="outline" className="text-gray-600">低</Badge>
      default:
        return <Badge variant="outline">{severity}</Badge>
    }
  }

  const MetricCard = ({ 
    title, 
    value, 
    change, 
    icon: Icon, 
    format = 'number',
    trend = 'positive'
  }: {
    title: string
    value: number | string
    change?: number
    icon: React.ElementType
    format?: 'number' | 'currency' | 'percentage' | 'time'
    trend?: 'positive' | 'negative'
  }) => {
    const formatValue = (val: number | string) => {
      if (typeof val === 'string') return val
      switch (format) {
        case 'currency':
          return `¥${val.toLocaleString()}`
        case 'percentage':
          return `${val}%`
        case 'time':
          return `${val}ms`
        default:
          return val.toLocaleString()
      }
    }

    return (
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">{title}</CardTitle>
          <Icon className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{formatValue(value)}</div>
          {change !== undefined && (
            <p className={`text-xs flex items-center ${
              trend === 'positive' 
                ? (change > 0 ? 'text-green-600' : 'text-red-600')
                : (change > 0 ? 'text-red-600' : 'text-green-600')
            }`}>
              {change > 0 ? <TrendingUp className="w-3 h-3 mr-1" /> : <TrendingDown className="w-3 h-3 mr-1" />}
              {Math.abs(change)}% 较昨日
            </p>
          )}
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* 统计卡片 */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="总API调用"
          value={stats.totalCalls}
          change={stats.dailyGrowth}
          icon={Zap}
        />
        <MetricCard
          title="总消费"
          value={stats.totalCost}
          icon={DollarSign}
          format="currency"
        />
        <MetricCard
          title="平均响应时间"
          value={stats.avgResponseTime}
          icon={Clock}
          format="time"
          trend="negative"
        />
        <MetricCard
          title="成功率"
          value={stats.successRate}
          icon={CheckCircle}
          format="percentage"
        />
      </div>

      {/* 告警信息 */}
      {alerts.filter(alert => !alert.resolved).length > 0 && (
        <Card className="border-red-200 bg-red-50">
          <CardHeader>
            <CardTitle className="text-red-700 flex items-center">
              <AlertTriangle className="w-5 h-5 mr-2" />
              活跃告警 ({alerts.filter(alert => !alert.resolved).length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {alerts.filter(alert => !alert.resolved).slice(0, 3).map(alert => (
                <div key={alert.id} className="flex items-center justify-between p-3 bg-white rounded border">
                  <div className="flex items-center space-x-3">
                    {getAlertSeverityBadge(alert.severity)}
                    <div>
                      <div className="font-medium text-sm">{alert.service}</div>
                      <div className="text-xs text-muted-foreground">{alert.message}</div>
                    </div>
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {new Date(alert.timestamp).toLocaleString()}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* 主要内容 */}
      <Tabs defaultValue="services" className="space-y-4">
        <TabsList>
          <TabsTrigger value="services">服务监控</TabsTrigger>
          <TabsTrigger value="costs">费用分析</TabsTrigger>
          <TabsTrigger value="performance">性能分析</TabsTrigger>
          <TabsTrigger value="alerts">告警管理</TabsTrigger>
        </TabsList>

        {/* 服务监控 */}
        <TabsContent value="services" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>AI服务监控</CardTitle>
                  <CardDescription>实时监控各AI服务的运行状态和使用情况</CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <Select value={selectedProvider} onValueChange={setSelectedProvider}>
                    <SelectTrigger className="w-32">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">全部提供商</SelectItem>
                      <SelectItem value="openai">OpenAI</SelectItem>
                      <SelectItem value="anthropic">Anthropic</SelectItem>
                      <SelectItem value="google">Google</SelectItem>
                      <SelectItem value="baidu">百度</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button variant="outline" onClick={fetchAIServices} disabled={loading}>
                    <RefreshCw className="w-4 h-4 mr-2" />
                    刷新
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>服务名称</TableHead>
                    <TableHead>提供商</TableHead>
                    <TableHead>类型</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>API调用</TableHead>
                    <TableHead>成功率</TableHead>
                    <TableHead>响应时间</TableHead>
                    <TableHead>日消费</TableHead>
                    <TableHead>使用率</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredServices.map((service) => (
                    <TableRow key={service.id}>
                      <TableCell className="font-medium">{service.name}</TableCell>
                      <TableCell>{getProviderBadge(service.provider)}</TableCell>
                      <TableCell>{getTypeBadge(service.type)}</TableCell>
                      <TableCell>{getStatusBadge(service.status)}</TableCell>
                      <TableCell>{service.apiCalls.toLocaleString()}</TableCell>
                      <TableCell>
                        <div className="flex items-center">
                          <span className={service.successRate > 95 ? 'text-green-600' : service.successRate > 90 ? 'text-yellow-600' : 'text-red-600'}>
                            {service.successRate}%
                          </span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className={service.avgResponseTime > 2000 ? 'text-red-600' : service.avgResponseTime > 1000 ? 'text-yellow-600' : 'text-green-600'}>
                          {service.avgResponseTime}ms
                        </span>
                      </TableCell>
                      <TableCell>¥{service.dailyCost}</TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          <Progress 
                            value={service.usagePercentage} 
                            className="w-16" 
                          />
                          <span className="text-sm">{service.usagePercentage}%</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button variant="ghost" size="sm">
                            <Settings className="w-4 h-4" />
                          </Button>
                          <Button variant="ghost" size="sm">
                            <BarChart3 className="w-4 h-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 费用分析 */}
        <TabsContent value="costs" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>费用构成分析</CardTitle>
                <CardDescription>各服务的费用占比和趋势</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {costBreakdown.map((item, index) => (
                    <div key={item.service} className="space-y-2">
                      <div className="flex justify-between items-center">
                        <div className="flex items-center space-x-2">
                          <div 
                            className={`w-3 h-3 rounded ${
                              index === 0 ? 'bg-blue-500' :
                              index === 1 ? 'bg-green-500' :
                              index === 2 ? 'bg-yellow-500' :
                              'bg-purple-500'
                            }`} 
                          />
                          <span className="text-sm font-medium">{item.service}</span>
                        </div>
                        <div className="text-right">
                          <div className="font-semibold">¥{item.dailyCost}</div>
                          <div className="text-xs text-muted-foreground">{item.percentage}%</div>
                        </div>
                      </div>
                      <Progress value={item.percentage} className="h-2" />
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>预算管理</CardTitle>
                <CardDescription>月度预算使用情况和预警</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="text-center p-4 border rounded-lg">
                    <div className="text-2xl font-bold text-green-600 mb-2">¥10,374</div>
                    <div className="text-sm text-muted-foreground">本月已消费</div>
                    <div className="mt-2">
                      <Progress value={69.2} className="h-3" />
                      <div className="text-xs mt-1 text-muted-foreground">预算使用: 69.2%</div>
                    </div>
                  </div>
                  
                  <div className="space-y-3">
                    <div className="flex justify-between items-center p-3 border rounded">
                      <div className="flex items-center">
                        <AlertTriangle className="w-4 h-4 mr-2 text-yellow-500" />
                        <span className="text-sm">预算预警</span>
                      </div>
                      <Badge className="bg-yellow-100 text-yellow-700">预计超支15%</Badge>
                    </div>
                    
                    <div className="flex justify-between items-center p-3 border rounded">
                      <div className="flex items-center">
                        <TrendingUp className="w-4 h-4 mr-2 text-green-500" />
                        <span className="text-sm">成本优化</span>
                      </div>
                      <Badge className="bg-green-100 text-green-700">节省¥234</Badge>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* 性能分析 */}
        <TabsContent value="performance" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>响应时间分析</CardTitle>
                <CardDescription>各服务的响应时间分布和趋势</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {services.filter(s => s.status === 'active').map(service => (
                    <div key={service.id} className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <div className={`w-2 h-2 rounded-full ${
                          service.avgResponseTime < 1000 ? 'bg-green-500' :
                          service.avgResponseTime < 2000 ? 'bg-yellow-500' : 'bg-red-500'
                        }`} />
                        <span className="text-sm">{service.name}</span>
                      </div>
                      <div className="text-right">
                        <div className="font-medium">{service.avgResponseTime}ms</div>
                        <div className="text-xs text-muted-foreground">
                          {service.avgResponseTime < 1000 ? '优秀' :
                           service.avgResponseTime < 2000 ? '良好' : '需优化'}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>成功率监控</CardTitle>
                <CardDescription>服务可用性和错误率统计</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {services.map(service => (
                    <div key={service.id} className="space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-sm font-medium">{service.name}</span>
                        <span className={`font-semibold ${
                          service.successRate > 95 ? 'text-green-600' :
                          service.successRate > 90 ? 'text-yellow-600' : 'text-red-600'
                        }`}>
                          {service.successRate}%
                        </span>
                      </div>
                      <Progress 
                        value={service.successRate} 
                        className={`h-2 ${
                          service.successRate > 95 ? '[&>div]:bg-green-500' :
                          service.successRate > 90 ? '[&>div]:bg-yellow-500' : '[&>div]:bg-red-500'
                        }`}
                      />
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* 告警管理 */}
        <TabsContent value="alerts" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>告警管理</CardTitle>
              <CardDescription>系统告警和异常事件管理</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>严重程度</TableHead>
                    <TableHead>服务</TableHead>
                    <TableHead>告警信息</TableHead>
                    <TableHead>时间</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {alerts.map((alert) => (
                    <TableRow key={alert.id}>
                      <TableCell>{getAlertSeverityBadge(alert.severity)}</TableCell>
                      <TableCell className="font-medium">{alert.service}</TableCell>
                      <TableCell>{alert.message}</TableCell>
                      <TableCell>{new Date(alert.timestamp).toLocaleString()}</TableCell>
                      <TableCell>
                        {alert.resolved ? (
                          <Badge className="bg-green-100 text-green-700">已解决</Badge>
                        ) : (
                          <Badge className="bg-red-100 text-red-700">待处理</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button variant="ghost" size="sm">
                            <Eye className="w-4 h-4" />
                          </Button>
                          {!alert.resolved && (
                            <Button variant="ghost" size="sm">
                              <CheckCircle className="w-4 h-4" />
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
      </Tabs>
    </div>
  )
}