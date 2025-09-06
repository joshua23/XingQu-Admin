/**
 * 星趣后台管理系统 - 商业化管理页面
 * 提供完整的商业化管理界面，集成订阅和订单管理
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  DollarSign, 
  TrendingUp, 
  Users, 
  CreditCard, 
  ShoppingCart, 
  Crown,
  BarChart3,
  Calendar,
  Target,
  Zap,
  AlertCircle,
  CheckCircle,
  PieChart,
  LineChart,
  Activity
} from 'lucide-react'
import SubscriptionManager from '@/components/subscription/SubscriptionManager'
import OrderPaymentManager from '@/components/OrderPaymentManager'

interface CommerceMetrics {
  totalRevenue: number
  monthlyRevenue: number
  revenueGrowth: number
  activeSubscriptions: number
  subscriptionGrowth: number
  totalOrders: number
  orderGrowth: number
  avgOrderValue: number
  customerLifetimeValue: number
  churnRate: number
  conversionRate: number
  refundRate: number
}

interface RevenueData {
  month: string
  subscription: number
  oneTime: number
  total: number
}

export default function CommercePage() {
  const [metrics, setMetrics] = useState<CommerceMetrics>({
    totalRevenue: 0,
    monthlyRevenue: 0,
    revenueGrowth: 0,
    activeSubscriptions: 0,
    subscriptionGrowth: 0,
    totalOrders: 0,
    orderGrowth: 0,
    avgOrderValue: 0,
    customerLifetimeValue: 0,
    churnRate: 0,
    conversionRate: 0,
    refundRate: 0
  })
  const [loading, setLoading] = useState(true)
  const [selectedPeriod, setSelectedPeriod] = useState('30d')

  useEffect(() => {
    fetchCommerceMetrics()
  }, [selectedPeriod])

  const fetchCommerceMetrics = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setMetrics({
        totalRevenue: 156780.50,
        monthlyRevenue: 23450.80,
        revenueGrowth: 18.5,
        activeSubscriptions: 1247,
        subscriptionGrowth: 12.3,
        totalOrders: 3456,
        orderGrowth: 8.7,
        avgOrderValue: 125.60,
        customerLifetimeValue: 890.30,
        churnRate: 3.2,
        conversionRate: 24.6,
        refundRate: 1.8
      })
    } catch (error) {
      console.error('获取商业化数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const revenueData: RevenueData[] = [
    { month: '1月', subscription: 18500, oneTime: 4200, total: 22700 },
    { month: '2月', subscription: 19200, oneTime: 3800, total: 23000 },
    { month: '3月', subscription: 20100, oneTime: 4500, total: 24600 },
    { month: '4月', subscription: 19800, oneTime: 4100, total: 23900 },
    { month: '5月', subscription: 21300, oneTime: 4800, total: 26100 },
    { month: '6月', subscription: 22000, oneTime: 5200, total: 27200 }
  ]

  const MetricCard = ({ 
    title, 
    value, 
    change, 
    icon: Icon, 
    format = 'number',
    trend = 'positive'
  }: {
    title: string
    value: number
    change?: number
    icon: React.ElementType
    format?: 'number' | 'currency' | 'percentage'
    trend?: 'positive' | 'negative'
  }) => {
    const formatValue = (val: number) => {
      switch (format) {
        case 'currency':
          return `¥${val.toLocaleString()}`
        case 'percentage':
          return `${val}%`
        default:
          return val.toLocaleString()
      }
    }

    const getTrendColor = (changeVal?: number) => {
      if (!changeVal) return 'text-muted-foreground'
      return trend === 'positive' 
        ? (changeVal > 0 ? 'text-green-600' : 'text-red-600')
        : (changeVal > 0 ? 'text-red-600' : 'text-green-600')
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
            <p className={`text-xs ${getTrendColor(change)}`}>
              {change > 0 ? '+' : ''}{change}% 较上期
            </p>
          )}
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        {/* 页面标题 */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">商业化管理中心</h1>
            <p className="text-muted-foreground">
              订阅服务、支付订单和收入分析管理
            </p>
          </div>
          <div className="flex items-center space-x-2">
            <Button variant="outline" onClick={fetchCommerceMetrics} disabled={loading}>
              <Activity className="w-4 h-4 mr-2" />
              刷新数据
            </Button>
            <Badge variant="outline" className="text-green-600">
              <CheckCircle className="w-3 h-3 mr-1" />
              系统正常运行
            </Badge>
          </div>
        </div>

        {/* 关键指标 */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <MetricCard
            title="总收入"
            value={metrics.totalRevenue}
            change={metrics.revenueGrowth}
            icon={DollarSign}
            format="currency"
          />
          <MetricCard
            title="月收入"
            value={metrics.monthlyRevenue}
            icon={TrendingUp}
            format="currency"
          />
          <MetricCard
            title="活跃订阅"
            value={metrics.activeSubscriptions}
            change={metrics.subscriptionGrowth}
            icon={Crown}
          />
          <MetricCard
            title="平均订单价值"
            value={metrics.avgOrderValue}
            icon={ShoppingCart}
            format="currency"
          />
        </div>

        {/* 业务健康度指标 */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <MetricCard
            title="客户终身价值"
            value={metrics.customerLifetimeValue}
            icon={Users}
            format="currency"
          />
          <MetricCard
            title="转化率"
            value={metrics.conversionRate}
            icon={Target}
            format="percentage"
          />
          <MetricCard
            title="流失率"
            value={metrics.churnRate}
            icon={AlertCircle}
            format="percentage"
            trend="negative"
          />
          <MetricCard
            title="退款率"
            value={metrics.refundRate}
            icon={CreditCard}
            format="percentage"
            trend="negative"
          />
        </div>

        {/* 收入趋势分析 */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center">
                  <LineChart className="w-5 h-5 mr-2" />
                  收入趋势分析
                </CardTitle>
                <CardDescription>近6个月的收入变化趋势</CardDescription>
              </div>
              <div className="flex items-center space-x-2">
                <Button 
                  variant={selectedPeriod === '30d' ? 'default' : 'outline'} 
                  size="sm"
                  onClick={() => setSelectedPeriod('30d')}
                >
                  30天
                </Button>
                <Button 
                  variant={selectedPeriod === '90d' ? 'default' : 'outline'} 
                  size="sm"
                  onClick={() => setSelectedPeriod('90d')}
                >
                  90天
                </Button>
                <Button 
                  variant={selectedPeriod === '180d' ? 'default' : 'outline'} 
                  size="sm"
                  onClick={() => setSelectedPeriod('180d')}
                >
                  6个月
                </Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-6 md:grid-cols-2">
              {/* 收入构成分析 */}
              <div>
                <h4 className="text-sm font-medium mb-4">收入构成分析</h4>
                <div className="space-y-3">
                  {revenueData.slice(-3).map((data, index) => (
                    <div key={data.month} className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>{data.month}</span>
                        <span className="font-medium">¥{data.total.toLocaleString()}</span>
                      </div>
                      <div className="flex space-x-1 h-2">
                        <div 
                          className="bg-blue-500 rounded-sm"
                          style={{ width: `${(data.subscription / data.total) * 100}%` }}
                        />
                        <div 
                          className="bg-green-500 rounded-sm"
                          style={{ width: `${(data.oneTime / data.total) * 100}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
                <div className="flex items-center justify-center space-x-4 mt-4 pt-4 border-t">
                  <div className="flex items-center text-sm">
                    <div className="w-3 h-3 bg-blue-500 rounded mr-2" />
                    订阅收入
                  </div>
                  <div className="flex items-center text-sm">
                    <div className="w-3 h-3 bg-green-500 rounded mr-2" />
                    一次性收入
                  </div>
                </div>
              </div>

              {/* 关键比率分析 */}
              <div>
                <h4 className="text-sm font-medium mb-4">关键比率分析</h4>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm">订阅收入占比</span>
                    <div className="flex items-center">
                      <div className="w-20 h-2 bg-gray-200 rounded mr-2">
                        <div className="h-2 bg-blue-500 rounded" style={{ width: '82%' }} />
                      </div>
                      <span className="text-sm font-medium">82%</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm">复购率</span>
                    <div className="flex items-center">
                      <div className="w-20 h-2 bg-gray-200 rounded mr-2">
                        <div className="h-2 bg-green-500 rounded" style={{ width: '68%' }} />
                      </div>
                      <span className="text-sm font-medium">68%</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm">新用户转化率</span>
                    <div className="flex items-center">
                      <div className="w-20 h-2 bg-gray-200 rounded mr-2">
                        <div className="h-2 bg-purple-500 rounded" style={{ width: '25%' }} />
                      </div>
                      <span className="text-sm font-medium">25%</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm">用户满意度</span>
                    <div className="flex items-center">
                      <div className="w-20 h-2 bg-gray-200 rounded mr-2">
                        <div className="h-2 bg-yellow-500 rounded" style={{ width: '91%' }} />
                      </div>
                      <span className="text-sm font-medium">91%</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 主要功能模块 */}
        <Tabs defaultValue="overview" className="space-y-4">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="overview">业务概览</TabsTrigger>
            <TabsTrigger value="subscriptions">订阅管理</TabsTrigger>
            <TabsTrigger value="orders">订单管理</TabsTrigger>
            <TabsTrigger value="analytics">深度分析</TabsTrigger>
          </TabsList>

          {/* 业务概览 */}
          <TabsContent value="overview" className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              {/* 今日业务概况 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Calendar className="w-5 h-5 mr-2" />
                    今日业务概况
                  </CardTitle>
                  <CardDescription>实时业务数据监控</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex justify-between items-center">
                      <span className="text-sm">今日收入</span>
                      <span className="font-semibold text-green-600">¥1,245.80</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm">新增订阅</span>
                      <span className="font-semibold text-blue-600">23</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm">完成订单</span>
                      <span className="font-semibold text-purple-600">45</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm">活跃用户</span>
                      <span className="font-semibold text-orange-600">156</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm">退款处理</span>
                      <span className="font-semibold text-red-600">2</span>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* 业务健康度 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Activity className="w-5 h-5 mr-2" />
                    业务健康度
                  </CardTitle>
                  <CardDescription>关键业务指标健康状态</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <CheckCircle className="w-4 h-4 mr-2 text-green-500" />
                        <span className="text-sm">支付成功率</span>
                      </div>
                      <Badge className="bg-green-100 text-green-700">97.2%</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <CheckCircle className="w-4 h-4 mr-2 text-green-500" />
                        <span className="text-sm">服务稳定性</span>
                      </div>
                      <Badge className="bg-green-100 text-green-700">99.9%</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <AlertCircle className="w-4 h-4 mr-2 text-yellow-500" />
                        <span className="text-sm">客户满意度</span>
                      </div>
                      <Badge className="bg-yellow-100 text-yellow-700">91.5%</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <CheckCircle className="w-4 h-4 mr-2 text-green-500" />
                        <span className="text-sm">系统性能</span>
                      </div>
                      <Badge className="bg-green-100 text-green-700">优秀</Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* 快速操作 */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Zap className="w-5 h-5 mr-2" />
                  快速操作
                </CardTitle>
                <CardDescription>常用管理操作快捷入口</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                  <Button variant="outline" className="h-20 flex flex-col">
                    <Crown className="w-6 h-6 mb-2" />
                    <span>创建订阅计划</span>
                  </Button>
                  <Button variant="outline" className="h-20 flex flex-col">
                    <CreditCard className="w-6 h-6 mb-2" />
                    <span>处理退款</span>
                  </Button>
                  <Button variant="outline" className="h-20 flex flex-col">
                    <BarChart3 className="w-6 h-6 mb-2" />
                    <span>查看报表</span>
                  </Button>
                  <Button variant="outline" className="h-20 flex flex-col">
                    <Users className="w-6 h-6 mb-2" />
                    <span>用户分析</span>
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* 订阅管理 */}
          <TabsContent value="subscriptions" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Crown className="w-5 h-5 mr-2" />
                  订阅计划管理
                </CardTitle>
                <CardDescription>
                  管理会员订阅计划、定价策略和用户订阅状态
                </CardDescription>
              </CardHeader>
              <CardContent>
                <SubscriptionManager />
              </CardContent>
            </Card>
          </TabsContent>

          {/* 订单管理 */}
          <TabsContent value="orders" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <ShoppingCart className="w-5 h-5 mr-2" />
                  订单支付管理
                </CardTitle>
                <CardDescription>
                  处理支付订单、退款请求和财务数据分析
                </CardDescription>
              </CardHeader>
              <CardContent>
                <OrderPaymentManager />
              </CardContent>
            </Card>
          </TabsContent>

          {/* 深度分析 */}
          <TabsContent value="analytics" className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle>用户价值分析</CardTitle>
                  <CardDescription>用户生命周期价值和行为分析</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="text-center p-6 border rounded-lg">
                      <div className="text-3xl font-bold text-blue-600 mb-2">¥890</div>
                      <div className="text-sm text-muted-foreground">平均客户终身价值</div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="text-center p-4 border rounded">
                        <div className="font-bold text-lg">8.5个月</div>
                        <div className="text-xs text-muted-foreground">平均订阅时长</div>
                      </div>
                      <div className="text-center p-4 border rounded">
                        <div className="font-bold text-lg">2.3次</div>
                        <div className="text-xs text-muted-foreground">平均续费次数</div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>收入预测</CardTitle>
                  <CardDescription>基于历史数据的收入增长预测</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="text-center p-6 border rounded-lg">
                      <div className="text-3xl font-bold text-green-600 mb-2">¥35,680</div>
                      <div className="text-sm text-muted-foreground">下月预计收入</div>
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>订阅收入</span>
                        <span className="font-medium">¥28,540 (80%)</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span>一次性收入</span>
                        <span className="font-medium">¥7,140 (20%)</span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle>市场竞争分析</CardTitle>
                <CardDescription>行业基准对比和竞争态势分析</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid gap-6 md:grid-cols-3">
                  <div className="text-center p-4 border rounded-lg">
                    <div className="text-2xl font-bold text-green-600 mb-2">优秀</div>
                    <div className="text-sm text-muted-foreground mb-1">转化率表现</div>
                    <div className="text-xs text-gray-500">高于行业平均32%</div>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <div className="text-2xl font-bold text-blue-600 mb-2">领先</div>
                    <div className="text-sm text-muted-foreground mb-1">用户留存率</div>
                    <div className="text-xs text-gray-500">高于同类产品18%</div>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <div className="text-2xl font-bold text-purple-600 mb-2">优化</div>
                    <div className="text-sm text-muted-foreground mb-1">定价策略</div>
                    <div className="text-xs text-gray-500">有提升空间</div>
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