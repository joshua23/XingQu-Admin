/**
 * 星趣后台管理系统 - AI服务管理页面
 * 提供AI服务的全面管理，集成监控和成本优化
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  Brain,
  Zap,
  DollarSign,
  TrendingUp,
  Activity,
  Settings,
  Eye,
  AlertTriangle,
  CheckCircle,
  BarChart3,
  Target,
  Cpu,
  Server,
  Globe,
  Lightbulb,
  RefreshCw
} from 'lucide-react'
import AIServiceMonitor from '@/components/AIServiceMonitor'
import AICostOptimizer from '@/components/AICostOptimizer'

interface ServiceHealthMetrics {
  overallHealth: number
  activeServices: number
  totalServices: number
  criticalAlerts: number
  warningAlerts: number
  avgResponseTime: number
  successRate: number
  monthlySpend: number
  budgetUtilization: number
}

interface QuickAction {
  id: string
  title: string
  description: string
  icon: React.ElementType
  action: string
  priority: 'high' | 'medium' | 'low'
  status: 'available' | 'processing' | 'completed'
}

export default function AIServicesPage() {
  const [healthMetrics, setHealthMetrics] = useState<ServiceHealthMetrics>({
    overallHealth: 0,
    activeServices: 0,
    totalServices: 0,
    criticalAlerts: 0,
    warningAlerts: 0,
    avgResponseTime: 0,
    successRate: 0,
    monthlySpend: 0,
    budgetUtilization: 0
  })
  const [quickActions, setQuickActions] = useState<QuickAction[]>([])
  const [loading, setLoading] = useState(true)
  const [lastUpdated, setLastUpdated] = useState<string>('')

  useEffect(() => {
    fetchServiceHealth()
    fetchQuickActions()
    
    // 设置自动刷新
    const interval = setInterval(() => {
      fetchServiceHealth()
    }, 30000) // 30秒刷新一次
    
    return () => clearInterval(interval)
  }, [])

  const fetchServiceHealth = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 800))
      
      setHealthMetrics({
        overallHealth: 87.5,
        activeServices: 4,
        totalServices: 5,
        criticalAlerts: 1,
        warningAlerts: 2,
        avgResponseTime: 1187,
        successRate: 97.3,
        monthlySpend: 10374,
        budgetUtilization: 69.2
      })
      
      setLastUpdated(new Date().toLocaleTimeString())
    } catch (error) {
      console.error('获取服务健康度失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchQuickActions = async () => {
    try {
      const mockActions: QuickAction[] = [
        {
          id: '1',
          title: '优化GPT-4成本',
          description: '使用GPT-3.5替代简单任务可节省¥2,850',
          icon: DollarSign,
          action: 'optimize_gpt4_cost',
          priority: 'high',
          status: 'available'
        },
        {
          id: '2',
          title: '修复Google Vision',
          description: 'API服务连接失败，需要检查配置',
          icon: AlertTriangle,
          action: 'fix_google_vision',
          priority: 'high',
          status: 'available'
        },
        {
          id: '3',
          title: '启用智能缓存',
          description: '减少20%重复调用，节省¥890/月',
          icon: Zap,
          action: 'enable_smart_cache',
          priority: 'medium',
          status: 'available'
        },
        {
          id: '4',
          title: '调整预算告警',
          description: 'Claude服务接近预算上限，建议调整',
          icon: Target,
          action: 'adjust_budget_alerts',
          priority: 'medium',
          status: 'available'
        }
      ]
      
      setQuickActions(mockActions)
    } catch (error) {
      console.error('获取快速操作失败:', error)
    }
  }

  const executeQuickAction = async (actionId: string) => {
    try {
      setQuickActions(prev => prev.map(action => 
        action.id === actionId 
          ? { ...action, status: 'processing' }
          : action
      ))
      
      // 模拟处理过程
      setTimeout(() => {
        setQuickActions(prev => prev.map(action => 
          action.id === actionId 
            ? { ...action, status: 'completed' }
            : action
        ))
      }, 3000)
    } catch (error) {
      console.error('执行快速操作失败:', error)
    }
  }

  const getHealthColor = (health: number) => {
    if (health >= 90) return 'text-green-600'
    if (health >= 70) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getHealthBadge = (health: number) => {
    if (health >= 90) return <Badge className="bg-green-100 text-green-700">优秀</Badge>
    if (health >= 70) return <Badge className="bg-yellow-100 text-yellow-700">良好</Badge>
    return <Badge className="bg-red-100 text-red-700">需关注</Badge>
  }

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'high':
        return <Badge className="bg-red-100 text-red-700 border-red-200">高</Badge>
      case 'medium':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">中</Badge>
      case 'low':
        return <Badge variant="outline" className="text-gray-600">低</Badge>
      default:
        return <Badge variant="outline">{priority}</Badge>
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'available':
        return <CheckCircle className="w-4 h-4 text-green-600" />
      case 'processing':
        return <RefreshCw className="w-4 h-4 text-blue-600 animate-spin" />
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-600" />
      default:
        return <CheckCircle className="w-4 h-4 text-gray-400" />
    }
  }

  const HealthCard = ({ 
    title, 
    value, 
    subtitle, 
    icon: Icon, 
    trend,
    color = 'text-muted-foreground'
  }: {
    title: string
    value: string | number
    subtitle?: string
    icon: React.ElementType
    trend?: 'up' | 'down' | 'stable'
    color?: string
  }) => (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className={`h-4 w-4 ${color}`} />
      </CardHeader>
      <CardContent>
        <div className={`text-2xl font-bold ${color}`}>{value}</div>
        {subtitle && (
          <p className="text-xs text-muted-foreground flex items-center">
            {trend === 'up' && <TrendingUp className="w-3 h-3 mr-1 text-green-600" />}
            {trend === 'down' && <TrendingUp className="w-3 h-3 mr-1 text-red-600 rotate-180" />}
            {subtitle}
          </p>
        )}
      </CardContent>
    </Card>
  )

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        {/* 页面标题 */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">AI服务管理中心</h1>
            <p className="text-muted-foreground">
              智能监控、成本优化和服务配置管理
            </p>
          </div>
          <div className="flex items-center space-x-2">
            <Button variant="outline" onClick={fetchServiceHealth} disabled={loading}>
              <RefreshCw className="w-4 h-4 mr-2" />
              刷新数据
            </Button>
            <Badge variant="outline">
              <Activity className="w-3 h-3 mr-1" />
              最后更新: {lastUpdated}
            </Badge>
          </div>
        </div>

        {/* 服务健康度概览 */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center">
                  <Server className="w-5 h-5 mr-2" />
                  服务健康度概览
                </CardTitle>
                <CardDescription>AI服务整体运行状况和关键指标</CardDescription>
              </div>
              <div className="text-right">
                <div className={`text-3xl font-bold ${getHealthColor(healthMetrics.overallHealth)}`}>
                  {healthMetrics.overallHealth}%
                </div>
                {getHealthBadge(healthMetrics.overallHealth)}
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              <HealthCard
                title="活跃服务"
                value={`${healthMetrics.activeServices}/${healthMetrics.totalServices}`}
                subtitle="服务运行正常"
                icon={Cpu}
                color="text-green-600"
              />
              <HealthCard
                title="告警数量"
                value={healthMetrics.criticalAlerts + healthMetrics.warningAlerts}
                subtitle={`${healthMetrics.criticalAlerts}严重 ${healthMetrics.warningAlerts}警告`}
                icon={AlertTriangle}
                color={healthMetrics.criticalAlerts > 0 ? "text-red-600" : "text-yellow-600"}
              />
              <HealthCard
                title="平均响应时间"
                value={`${healthMetrics.avgResponseTime}ms`}
                subtitle="系统响应速度"
                icon={Zap}
                color={healthMetrics.avgResponseTime > 2000 ? "text-red-600" : "text-green-600"}
              />
              <HealthCard
                title="成功率"
                value={`${healthMetrics.successRate}%`}
                subtitle="API调用成功率"
                icon={CheckCircle}
                color="text-green-600"
              />
            </div>
          </CardContent>
        </Card>

        {/* 快速操作 */}
        {quickActions.filter(action => action.status !== 'completed').length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Lightbulb className="w-5 h-5 mr-2" />
                智能建议和快速操作
              </CardTitle>
              <CardDescription>
                基于AI分析的优化建议和一键操作
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-2">
                {quickActions.filter(action => action.status !== 'completed').map(action => (
                  <Card key={action.id} className="border">
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start space-x-3">
                          <action.icon className="w-5 h-5 mt-1 text-blue-600" />
                          <div>
                            <div className="flex items-center space-x-2 mb-1">
                              <h4 className="font-semibold">{action.title}</h4>
                              {getPriorityBadge(action.priority)}
                            </div>
                            <p className="text-sm text-muted-foreground">{action.description}</p>
                          </div>
                        </div>
                        {getStatusIcon(action.status)}
                      </div>
                    </CardHeader>
                    <CardContent className="pt-0">
                      {action.status === 'available' && (
                        <Button 
                          size="sm" 
                          onClick={() => executeQuickAction(action.id)}
                          className="w-full"
                        >
                          立即执行
                        </Button>
                      )}
                      {action.status === 'processing' && (
                        <Button size="sm" disabled className="w-full">
                          <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                          处理中...
                        </Button>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* 主要功能区域 */}
        <Tabs defaultValue="monitor" className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="monitor" className="flex items-center">
              <BarChart3 className="w-4 h-4 mr-2" />
              服务监控
            </TabsTrigger>
            <TabsTrigger value="optimizer" className="flex items-center">
              <Target className="w-4 h-4 mr-2" />
              成本优化
            </TabsTrigger>
            <TabsTrigger value="config" className="flex items-center">
              <Settings className="w-4 h-4 mr-2" />
              配置管理
            </TabsTrigger>
          </TabsList>

          {/* 服务监控 */}
          <TabsContent value="monitor" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Activity className="w-5 h-5 mr-2" />
                  实时服务监控
                </CardTitle>
                <CardDescription>
                  监控各AI服务的运行状态、性能指标和使用情况
                </CardDescription>
              </CardHeader>
              <CardContent>
                <AIServiceMonitor />
              </CardContent>
            </Card>
          </TabsContent>

          {/* 成本优化 */}
          <TabsContent value="optimizer" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <DollarSign className="w-5 h-5 mr-2" />
                  AI成本优化中心
                </CardTitle>
                <CardDescription>
                  智能分析使用模式，提供个性化的成本优化建议
                </CardDescription>
              </CardHeader>
              <CardContent>
                <AICostOptimizer />
              </CardContent>
            </Card>
          </TabsContent>

          {/* 配置管理 */}
          <TabsContent value="config" className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Settings className="w-5 h-5 mr-2" />
                    服务配置
                  </CardTitle>
                  <CardDescription>管理AI服务的配置参数和API密钥</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="p-4 border rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-medium">OpenAI GPT-4</span>
                        <Badge className="bg-green-100 text-green-700">已配置</Badge>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        API密钥: sk-...****<br/>
                        模型: gpt-4-turbo-preview<br/>
                        请求频率限制: 10,000/min
                      </div>
                    </div>
                    
                    <div className="p-4 border rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-medium">Anthropic Claude</span>
                        <Badge className="bg-green-100 text-green-700">已配置</Badge>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        API密钥: sk-ant-...****<br/>
                        模型: claude-3-sonnet<br/>
                        请求频率限制: 5,000/min
                      </div>
                    </div>
                    
                    <div className="p-4 border rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-medium">Google Vision API</span>
                        <Badge className="bg-red-100 text-red-700">配置错误</Badge>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        服务账户: service-****<br/>
                        项目ID: vision-project<br/>
                        状态: 认证失败
                      </div>
                    </div>

                    <Button className="w-full">
                      <Settings className="w-4 h-4 mr-2" />
                      管理配置
                    </Button>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Globe className="w-5 h-5 mr-2" />
                    全局设置
                  </CardTitle>
                  <CardDescription>系统级的AI服务配置和策略</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-3 border rounded">
                      <div>
                        <div className="font-medium">自动故障转移</div>
                        <div className="text-sm text-muted-foreground">主服务不可用时自动切换</div>
                      </div>
                      <Badge className="bg-green-100 text-green-700">已启用</Badge>
                    </div>
                    
                    <div className="flex items-center justify-between p-3 border rounded">
                      <div>
                        <div className="font-medium">智能负载均衡</div>
                        <div className="text-sm text-muted-foreground">根据响应时间分配请求</div>
                      </div>
                      <Badge className="bg-green-100 text-green-700">已启用</Badge>
                    </div>
                    
                    <div className="flex items-center justify-between p-3 border rounded">
                      <div>
                        <div className="font-medium">成本监控告警</div>
                        <div className="text-sm text-muted-foreground">超出预算时发送通知</div>
                      </div>
                      <Badge className="bg-green-100 text-green-700">已启用</Badge>
                    </div>
                    
                    <div className="flex items-center justify-between p-3 border rounded">
                      <div>
                        <div className="font-medium">使用日志记录</div>
                        <div className="text-sm text-muted-foreground">详细记录API调用日志</div>
                      </div>
                      <Badge className="bg-yellow-100 text-yellow-700">部分启用</Badge>
                    </div>

                    <Button variant="outline" className="w-full">
                      <Eye className="w-4 h-4 mr-2" />
                      查看详细设置
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Brain className="w-5 h-5 mr-2" />
                  AI服务使用统计
                </CardTitle>
                <CardDescription>各服务的详细使用情况和趋势分析</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid gap-4 md:grid-cols-3">
                  <div className="text-center p-6 border rounded-lg">
                    <div className="text-2xl font-bold text-blue-600 mb-2">32,310</div>
                    <div className="text-sm text-muted-foreground">总API调用</div>
                    <div className="text-xs text-green-600 mt-1">+12.5% 较昨日</div>
                  </div>
                  <div className="text-center p-6 border rounded-lg">
                    <div className="text-2xl font-bold text-green-600 mb-2">¥10,374</div>
                    <div className="text-sm text-muted-foreground">本月消费</div>
                    <div className="text-xs text-muted-foreground mt-1">预算使用 69.2%</div>
                  </div>
                  <div className="text-center p-6 border rounded-lg">
                    <div className="text-2xl font-bold text-purple-600 mb-2">97.3%</div>
                    <div className="text-sm text-muted-foreground">平均成功率</div>
                    <div className="text-xs text-green-600 mt-1">+0.8% 较上周</div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}