/**
 * 星趣后台管理系统 - AI成本优化建议组件
 * 帮助优化AI服务成本
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Progress } from '@/components/ui/progress'
import { Slider } from '@/components/ui/slider'
import {
  TrendingDown,
  DollarSign,
  Lightbulb,
  Target,
  PieChart,
  BarChart3,
  AlertTriangle,
  CheckCircle,
  Settings,
  Zap,
  Clock,
  RefreshCw,
  Download,
  Calculator,
  Brain,
  Eye,
  Activity
} from 'lucide-react'

// 类型定义
interface OptimizationSuggestion {
  id: string
  type: 'cost' | 'performance' | 'usage' | 'model'
  priority: 'high' | 'medium' | 'low'
  service: string
  title: string
  description: string
  potentialSavings: number
  implementationEffort: 'easy' | 'medium' | 'hard'
  estimatedTimeToImplement: string
  impact: string
  status: 'pending' | 'implementing' | 'completed' | 'dismissed'
}

interface UsagePattern {
  service: string
  peakHours: string[]
  lowUsageHours: string[]
  weekdayUsage: number
  weekendUsage: number
  averageCallsPerHour: number
  costPerCall: number
  efficiency: number
}

interface CostProjection {
  currentMonthly: number
  projectedMonthly: number
  optimizedMonthly: number
  potentialSavings: number
  savingsPercentage: number
}

interface BudgetAlert {
  id: string
  service: string
  type: 'budget_exceeded' | 'approaching_limit' | 'unusual_spike'
  currentSpend: number
  budgetLimit: number
  percentage: number
  trend: 'increasing' | 'stable' | 'decreasing'
}

export default function AICostOptimizer() {
  const [suggestions, setSuggestions] = useState<OptimizationSuggestion[]>([])
  const [usagePatterns, setUsagePatterns] = useState<UsagePattern[]>([])
  const [costProjection, setCostProjection] = useState<CostProjection>({
    currentMonthly: 0,
    projectedMonthly: 0,
    optimizedMonthly: 0,
    potentialSavings: 0,
    savingsPercentage: 0
  })
  const [budgetAlerts, setBudgetAlerts] = useState<BudgetAlert[]>([])
  const [loading, setLoading] = useState(true)
  const [monthlyBudget, setMonthlyBudget] = useState<number>(15000)
  const [selectedService, setSelectedService] = useState<string>('all')

  useEffect(() => {
    fetchOptimizationData()
  }, [])

  const fetchOptimizationData = async () => {
    try {
      setLoading(true)
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      // 模拟优化建议数据
      const mockSuggestions: OptimizationSuggestion[] = [
        {
          id: '1',
          type: 'cost',
          priority: 'high',
          service: 'GPT-4 文本生成',
          title: '使用GPT-3.5替代部分简单任务',
          description: '对于简单的文本处理任务，使用GPT-3.5可以节省70%的成本，而质量差异很小。',
          potentialSavings: 2850,
          implementationEffort: 'easy',
          estimatedTimeToImplement: '1-2天',
          impact: '预计可节省约40%的文本生成成本',
          status: 'pending'
        },
        {
          id: '2',
          type: 'usage',
          priority: 'high',
          service: 'Claude 内容审核',
          title: '优化调用频率和批处理',
          description: '通过批量处理内容和减少重复调用，可以显著降低API调用次数。',
          potentialSavings: 1200,
          implementationEffort: 'medium',
          estimatedTimeToImplement: '3-5天',
          impact: '减少30%的API调用次数',
          status: 'pending'
        },
        {
          id: '3',
          type: 'model',
          priority: 'medium',
          service: 'DALL-E 图像生成',
          title: '调整图像生成分辨率',
          description: '根据实际需求调整图像分辨率，避免生成过高分辨率的图像。',
          potentialSavings: 680,
          implementationEffort: 'easy',
          estimatedTimeToImplement: '1天',
          impact: '降低25%的图像生成成本',
          status: 'pending'
        },
        {
          id: '4',
          type: 'performance',
          priority: 'medium',
          service: '百度语音识别',
          title: '启用音频预处理',
          description: '在发送到API前进行音频预处理，可以提高识别准确率并减少重试次数。',
          potentialSavings: 320,
          implementationEffort: 'medium',
          estimatedTimeToImplement: '2-3天',
          impact: '减少15%的重试调用',
          status: 'pending'
        },
        {
          id: '5',
          type: 'cost',
          priority: 'low',
          service: '通用优化',
          title: '设置智能缓存策略',
          description: '对相似查询结果进行缓存，避免重复的API调用。',
          potentialSavings: 890,
          implementationEffort: 'hard',
          estimatedTimeToImplement: '1-2周',
          impact: '减少20%的重复调用成本',
          status: 'pending'
        }
      ]

      // 模拟使用模式数据
      const mockUsagePatterns: UsagePattern[] = [
        {
          service: 'GPT-4 文本生成',
          peakHours: ['09:00-11:00', '14:00-17:00'],
          lowUsageHours: ['22:00-06:00'],
          weekdayUsage: 85,
          weekendUsage: 35,
          averageCallsPerHour: 147,
          costPerCall: 0.032,
          efficiency: 78
        },
        {
          service: 'Claude 内容审核',
          peakHours: ['10:00-12:00', '15:00-18:00'],
          lowUsageHours: ['00:00-07:00'],
          weekdayUsage: 92,
          weekendUsage: 28,
          averageCallsPerHour: 89,
          costPerCall: 0.018,
          efficiency: 85
        },
        {
          service: 'DALL-E 图像生成',
          peakHours: ['13:00-16:00'],
          lowUsageHours: ['20:00-08:00'],
          weekdayUsage: 68,
          weekendUsage: 45,
          averageCallsPerHour: 23,
          costPerCall: 0.125,
          efficiency: 65
        }
      ]

      // 模拟成本预测数据
      const mockCostProjection: CostProjection = {
        currentMonthly: 10374,
        projectedMonthly: 14250,
        optimizedMonthly: 9580,
        potentialSavings: 4670,
        savingsPercentage: 32.8
      }

      // 模拟预算告警
      const mockBudgetAlerts: BudgetAlert[] = [
        {
          id: '1',
          service: 'Claude 内容审核',
          type: 'approaching_limit',
          currentSpend: 2847,
          budgetLimit: 3000,
          percentage: 94.9,
          trend: 'increasing'
        },
        {
          id: '2',
          service: 'GPT-4 文本生成',
          type: 'unusual_spike',
          currentSpend: 4235,
          budgetLimit: 5000,
          percentage: 84.7,
          trend: 'increasing'
        }
      ]

      setSuggestions(mockSuggestions)
      setUsagePatterns(mockUsagePatterns)
      setCostProjection(mockCostProjection)
      setBudgetAlerts(mockBudgetAlerts)
    } catch (error) {
      console.error('获取优化数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  // 应用优化建议
  const applySuggestion = async (suggestionId: string) => {
    try {
      setSuggestions(prev => prev.map(s => 
        s.id === suggestionId 
          ? { ...s, status: 'implementing' }
          : s
      ))
      
      // 模拟实施过程
      setTimeout(() => {
        setSuggestions(prev => prev.map(s => 
          s.id === suggestionId 
            ? { ...s, status: 'completed' }
            : s
        ))
      }, 2000)
    } catch (error) {
      console.error('应用优化建议失败:', error)
    }
  }

  // 忽略建议
  const dismissSuggestion = async (suggestionId: string) => {
    try {
      setSuggestions(prev => prev.map(s => 
        s.id === suggestionId 
          ? { ...s, status: 'dismissed' }
          : s
      ))
    } catch (error) {
      console.error('忽略建议失败:', error)
    }
  }

  // 过滤建议
  const filteredSuggestions = useMemo(() => {
    return suggestions.filter(suggestion => 
      selectedService === 'all' || suggestion.service === selectedService
    ).filter(s => s.status !== 'dismissed')
  }, [suggestions, selectedService])

  // 获取优先级样式
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

  const getTypeBadge = (type: string) => {
    const config = {
      cost: { icon: DollarSign, label: '成本', color: 'bg-green-100 text-green-700 border-green-200' },
      performance: { icon: Zap, label: '性能', color: 'bg-blue-100 text-blue-700 border-blue-200' },
      usage: { icon: Activity, label: '使用', color: 'bg-purple-100 text-purple-700 border-purple-200' },
      model: { icon: Brain, label: '模型', color: 'bg-orange-100 text-orange-700 border-orange-200' }
    }
    
    const { icon: Icon, label, color } = config[type as keyof typeof config] || config.cost
    
    return (
      <Badge className={`flex items-center ${color}`}>
        <Icon className="w-3 h-3 mr-1" />
        {label}
      </Badge>
    )
  }

  const getEffortBadge = (effort: string) => {
    switch (effort) {
      case 'easy':
        return <Badge className="bg-green-100 text-green-700">简单</Badge>
      case 'medium':
        return <Badge className="bg-yellow-100 text-yellow-700">中等</Badge>
      case 'hard':
        return <Badge className="bg-red-100 text-red-700">复杂</Badge>
      default:
        return <Badge variant="outline">{effort}</Badge>
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="outline">待处理</Badge>
      case 'implementing':
        return <Badge className="bg-blue-100 text-blue-700">实施中</Badge>
      case 'completed':
        return <Badge className="bg-green-100 text-green-700">已完成</Badge>
      case 'dismissed':
        return <Badge variant="outline" className="text-gray-500">已忽略</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  return (
    <div className="space-y-6">
      {/* 成本概览 */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">当前月消费</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">¥{costProjection.currentMonthly.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">预算使用: {((costProjection.currentMonthly / monthlyBudget) * 100).toFixed(1)}%</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">预计月消费</CardTitle>
            <TrendingDown className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">¥{costProjection.projectedMonthly.toLocaleString()}</div>
            <p className="text-xs text-red-600">预计超支 {((costProjection.projectedMonthly - monthlyBudget) / monthlyBudget * 100).toFixed(1)}%</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">优化后消费</CardTitle>
            <Target className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">¥{costProjection.optimizedMonthly.toLocaleString()}</div>
            <p className="text-xs text-green-600">节省 ¥{costProjection.potentialSavings.toLocaleString()}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">潜在节省</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">{costProjection.savingsPercentage}%</div>
            <p className="text-xs text-muted-foreground">通过优化可节省</p>
          </CardContent>
        </Card>
      </div>

      {/* 预算告警 */}
      {budgetAlerts.length > 0 && (
        <Card className="border-yellow-200 bg-yellow-50">
          <CardHeader>
            <CardTitle className="text-yellow-700 flex items-center">
              <AlertTriangle className="w-5 h-5 mr-2" />
              预算告警 ({budgetAlerts.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {budgetAlerts.map(alert => (
                <div key={alert.id} className="flex items-center justify-between p-3 bg-white rounded border">
                  <div>
                    <div className="font-medium text-sm">{alert.service}</div>
                    <div className="text-xs text-muted-foreground">
                      已使用 ¥{alert.currentSpend.toLocaleString()} / ¥{alert.budgetLimit.toLocaleString()} ({alert.percentage.toFixed(1)}%)
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Progress value={alert.percentage} className="w-20" />
                    <Badge className={
                      alert.type === 'budget_exceeded' ? 'bg-red-100 text-red-700' :
                      alert.type === 'approaching_limit' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-blue-100 text-blue-700'
                    }>
                      {alert.type === 'budget_exceeded' ? '超支' :
                       alert.type === 'approaching_limit' ? '接近上限' : '异常增长'}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* 主要内容 */}
      <Tabs defaultValue="suggestions" className="space-y-4">
        <TabsList>
          <TabsTrigger value="suggestions">优化建议</TabsTrigger>
          <TabsTrigger value="patterns">使用模式</TabsTrigger>
          <TabsTrigger value="budget">预算管理</TabsTrigger>
          <TabsTrigger value="calculator">成本计算器</TabsTrigger>
        </TabsList>

        {/* 优化建议 */}
        <TabsContent value="suggestions" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center">
                    <Lightbulb className="w-5 h-5 mr-2" />
                    智能优化建议
                  </CardTitle>
                  <CardDescription>基于使用模式和成本分析的个性化优化建议</CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <Select value={selectedService} onValueChange={setSelectedService}>
                    <SelectTrigger className="w-40">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">全部服务</SelectItem>
                      <SelectItem value="GPT-4 文本生成">GPT-4 文本生成</SelectItem>
                      <SelectItem value="Claude 内容审核">Claude 内容审核</SelectItem>
                      <SelectItem value="DALL-E 图像生成">DALL-E 图像生成</SelectItem>
                      <SelectItem value="百度语音识别">百度语音识别</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button variant="outline" onClick={fetchOptimizationData} disabled={loading}>
                    <RefreshCw className="w-4 h-4 mr-2" />
                    刷新建议
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {filteredSuggestions.map(suggestion => (
                  <Card key={suggestion.id} className="border">
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center space-x-2">
                            {getPriorityBadge(suggestion.priority)}
                            {getTypeBadge(suggestion.type)}
                            {getStatusBadge(suggestion.status)}
                          </div>
                          <h4 className="font-semibold">{suggestion.title}</h4>
                          <p className="text-sm text-muted-foreground">{suggestion.service}</p>
                        </div>
                        <div className="text-right">
                          <div className="text-lg font-bold text-green-600">
                            ¥{suggestion.potentialSavings.toLocaleString()}
                          </div>
                          <div className="text-xs text-muted-foreground">潜在节省</div>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="pt-0">
                      <p className="text-sm mb-4">{suggestion.description}</p>
                      
                      <div className="grid grid-cols-3 gap-4 mb-4">
                        <div>
                          <Label className="text-xs text-muted-foreground">实施难度</Label>
                          <div>{getEffortBadge(suggestion.implementationEffort)}</div>
                        </div>
                        <div>
                          <Label className="text-xs text-muted-foreground">预计时间</Label>
                          <div className="text-sm">{suggestion.estimatedTimeToImplement}</div>
                        </div>
                        <div>
                          <Label className="text-xs text-muted-foreground">预期影响</Label>
                          <div className="text-sm">{suggestion.impact}</div>
                        </div>
                      </div>

                      {suggestion.status === 'pending' && (
                        <div className="flex space-x-2">
                          <Button 
                            size="sm" 
                            onClick={() => applySuggestion(suggestion.id)}
                            className="bg-green-600 hover:bg-green-700"
                          >
                            <CheckCircle className="w-4 h-4 mr-2" />
                            应用建议
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => dismissSuggestion(suggestion.id)}
                          >
                            忽略
                          </Button>
                        </div>
                      )}

                      {suggestion.status === 'implementing' && (
                        <div className="flex items-center text-blue-600">
                          <Settings className="w-4 h-4 mr-2 animate-spin" />
                          <span className="text-sm">正在实施中...</span>
                        </div>
                      )}

                      {suggestion.status === 'completed' && (
                        <div className="flex items-center text-green-600">
                          <CheckCircle className="w-4 h-4 mr-2" />
                          <span className="text-sm">优化已完成</span>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 使用模式分析 */}
        <TabsContent value="patterns" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            {usagePatterns.map(pattern => (
              <Card key={pattern.service}>
                <CardHeader>
                  <CardTitle className="text-base">{pattern.service}</CardTitle>
                  <CardDescription>使用模式和效率分析</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div>
                      <Label className="text-sm font-medium">使用效率</Label>
                      <div className="flex items-center space-x-2">
                        <Progress value={pattern.efficiency} className="flex-1" />
                        <span className="text-sm font-medium">{pattern.efficiency}%</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label className="text-xs text-muted-foreground">平均每小时调用</Label>
                        <div className="text-sm font-medium">{pattern.averageCallsPerHour}</div>
                      </div>
                      <div>
                        <Label className="text-xs text-muted-foreground">平均单次成本</Label>
                        <div className="text-sm font-medium">¥{pattern.costPerCall}</div>
                      </div>
                    </div>

                    <div>
                      <Label className="text-xs text-muted-foreground">高峰时段</Label>
                      <div className="flex flex-wrap gap-1 mt-1">
                        {pattern.peakHours.map(hour => (
                          <Badge key={hour} variant="outline" className="text-xs">
                            {hour}
                          </Badge>
                        ))}
                      </div>
                    </div>

                    <div className="flex justify-between text-sm">
                      <div>
                        <span className="text-muted-foreground">工作日:</span>
                        <span className="ml-1 font-medium">{pattern.weekdayUsage}%</span>
                      </div>
                      <div>
                        <span className="text-muted-foreground">周末:</span>
                        <span className="ml-1 font-medium">{pattern.weekendUsage}%</span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* 预算管理 */}
        <TabsContent value="budget" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>预算设置和监控</CardTitle>
              <CardDescription>设置月度预算并监控支出情况</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div>
                  <Label htmlFor="monthlyBudget">月度预算 (¥)</Label>
                  <Input
                    id="monthlyBudget"
                    type="number"
                    value={monthlyBudget}
                    onChange={(e) => setMonthlyBudget(Number(e.target.value) || 0)}
                    className="mt-1"
                  />
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <div className="text-center p-6 border rounded-lg">
                    <div className="text-2xl font-bold mb-2">
                      ¥{costProjection.currentMonthly.toLocaleString()}
                    </div>
                    <div className="text-sm text-muted-foreground mb-2">本月已消费</div>
                    <Progress 
                      value={(costProjection.currentMonthly / monthlyBudget) * 100} 
                      className="h-3" 
                    />
                    <div className="text-xs mt-1 text-muted-foreground">
                      {((costProjection.currentMonthly / monthlyBudget) * 100).toFixed(1)}% 已使用
                    </div>
                  </div>

                  <div className="text-center p-6 border rounded-lg">
                    <div className="text-2xl font-bold mb-2 text-red-600">
                      ¥{(costProjection.projectedMonthly - monthlyBudget).toLocaleString()}
                    </div>
                    <div className="text-sm text-muted-foreground mb-2">预计超支</div>
                    <Progress 
                      value={((costProjection.projectedMonthly - monthlyBudget) / monthlyBudget) * 100} 
                      className="h-3 [&>div]:bg-red-500" 
                    />
                    <div className="text-xs mt-1 text-red-600">
                      {(((costProjection.projectedMonthly - monthlyBudget) / monthlyBudget) * 100).toFixed(1)}% 超支
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-green-50 rounded-lg">
                  <div className="flex items-center mb-2">
                    <Target className="w-5 h-5 mr-2 text-green-600" />
                    <span className="font-medium text-green-700">优化后预算状况</span>
                  </div>
                  <div className="text-sm text-green-600">
                    应用所有优化建议后，预计月消费为 ¥{costProjection.optimizedMonthly.toLocaleString()}，
                    比预算节省 ¥{(monthlyBudget - costProjection.optimizedMonthly).toLocaleString()}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 成本计算器 */}
        <TabsContent value="calculator" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Calculator className="w-5 h-5 mr-2" />
                AI服务成本计算器
              </CardTitle>
              <CardDescription>预估不同使用场景下的成本</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                <Calculator className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <div>成本计算器功能开发中</div>
                <div className="text-sm">支持多种AI服务的成本预估和对比</div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}