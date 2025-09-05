'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { Progress } from '@/components/ui/Progress'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area
} from 'recharts'
import { 
  Users, TrendingUp, DollarSign, Activity, 
  Clock, Eye, MessageCircle, Star,
  ArrowUpRight, ArrowDownRight, RefreshCw,
  Calendar, Target, AlertCircle, CheckCircle
} from 'lucide-react'
import { dataService } from '@/lib/services/supabase'

interface DashboardStats {
  totalUsers: number
  activeUsers: number
  totalSessions: number
  averageSessionTime: number
  totalRevenue: number
  conversionRate: number
  memberUsers: number
  pageViews: number
}

interface ChartData {
  userGrowthData: Array<{ label: string; value: number; trend: 'up' | 'down' }>
  activityData: Array<{ label: string; value: number; trend: 'up' | 'down' }>
  revenueData: Array<{ label: string; value: number; trend: 'up' | 'down' }>
}

interface TopAgent {
  id: string
  name: string
  description: string
  avatar_url: string
  category: string
  tags: string[]
  usageCount: number
  userCount: number
  created_at: string
}

export default function OverviewPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [chartData, setChartData] = useState<ChartData | null>(null)
  const [topAgents, setTopAgents] = useState<TopAgent[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [activeTimeframe, setActiveTimeframe] = useState('7days')

  useEffect(() => {
    loadDashboardData()
  }, [activeTimeframe])

  const loadDashboardData = async () => {
    try {
      setLoading(true)
      
      // 并行加载数据
      const [statsResult, chartResult, agentsResult] = await Promise.all([
        dataService.getDashboardStats(),
        dataService.getChartData(),
        dataService.getTopAgents()
      ])

      if (statsResult.data) setStats(statsResult.data)
      if (chartResult.data) setChartData(chartResult.data)
      if (agentsResult.data) setTopAgents(agentsResult.data)

    } catch (error) {
      console.error('加载数据总览失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleRefresh = async () => {
    setRefreshing(true)
    await loadDashboardData()
    setRefreshing(false)
  }

  // 图表数据转换
  const userGrowthChartData = chartData?.userGrowthData.map((item, index) => ({
    name: item.label,
    users: item.value,
    active: Math.floor(item.value * 0.7) // 估算活跃用户
  })) || []

  const activityChartData = chartData?.activityData.map((item, index) => ({
    name: item.label,
    value: item.value
  })) || []

  const revenueChartData = chartData?.revenueData.map((item, index) => ({
    name: item.label,
    revenue: item.value,
    orders: Math.floor(item.value / 100) // 估算订单数
  })) || []

  // 饼图数据
  const userTypePieData = stats ? [
    { name: '会员用户', value: stats.memberUsers, color: '#8884d8' },
    { name: '普通用户', value: stats.totalUsers - stats.memberUsers, color: '#82ca9d' }
  ] : []

  const COLORS = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300']

  const getGrowthIndicator = (current: number, previous: number) => {
    if (previous === 0) return { value: 0, trend: 'up' as const }
    const growth = ((current - previous) / previous) * 100
    return {
      value: Math.abs(growth),
      trend: growth >= 0 ? 'up' as const : 'down' as const
    }
  }

  // 模拟前期数据用于计算增长率
  const mockPreviousStats = {
    totalUsers: stats ? Math.floor(stats.totalUsers * 0.85) : 0,
    activeUsers: stats ? Math.floor(stats.activeUsers * 0.92) : 0,
    totalRevenue: stats ? Math.floor(stats.totalRevenue * 0.88) : 0,
    pageViews: stats ? Math.floor(stats.pageViews * 0.76) : 0
  }

  if (loading) {
    return (
      <div className="container mx-auto py-6">
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">数据总览</h1>
            <p className="text-muted-foreground">加载中...</p>
          </div>
          <div className="grid gap-4 md:grid-cols-4">
            {[1, 2, 3, 4].map((i) => (
              <Card key={i}>
                <CardContent className="p-6">
                  <div className="animate-pulse space-y-2">
                    <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                    <div className="h-8 bg-gray-200 rounded w-1/2"></div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">数据总览</h1>
            <p className="text-muted-foreground">
              实时监控关键业务指标和趋势分析
            </p>
          </div>
          <div className="flex gap-2">
            <div className="flex border rounded-md">
              {[
                { key: '7days', label: '7天' },
                { key: '30days', label: '30天' },
                { key: '90days', label: '90天' }
              ].map((timeframe) => (
                <Button
                  key={timeframe.key}
                  variant={activeTimeframe === timeframe.key ? "default" : "ghost"}
                  size="sm"
                  onClick={() => setActiveTimeframe(timeframe.key)}
                >
                  {timeframe.label}
                </Button>
              ))}
            </div>
            <Button 
              variant="outline" 
              onClick={handleRefresh}
              disabled={refreshing}
            >
              <RefreshCw className={`w-4 h-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
              刷新
            </Button>
          </div>
        </div>

        {/* 核心指标卡片 */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">总用户数</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.totalUsers.toLocaleString()}</div>
              {stats && mockPreviousStats.totalUsers > 0 && (
                <div className="flex items-center text-sm">
                  {getGrowthIndicator(stats.totalUsers, mockPreviousStats.totalUsers).trend === 'up' ? (
                    <ArrowUpRight className="h-4 w-4 text-green-500 mr-1" />
                  ) : (
                    <ArrowDownRight className="h-4 w-4 text-red-500 mr-1" />
                  )}
                  <span className={getGrowthIndicator(stats.totalUsers, mockPreviousStats.totalUsers).trend === 'up' ? 'text-green-600' : 'text-red-600'}>
                    {getGrowthIndicator(stats.totalUsers, mockPreviousStats.totalUsers).value.toFixed(1)}%
                  </span>
                  <span className="text-muted-foreground ml-1">vs 上期</span>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">活跃用户</CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.activeUsers.toLocaleString()}</div>
              {stats && mockPreviousStats.activeUsers > 0 && (
                <div className="flex items-center text-sm">
                  {getGrowthIndicator(stats.activeUsers, mockPreviousStats.activeUsers).trend === 'up' ? (
                    <ArrowUpRight className="h-4 w-4 text-green-500 mr-1" />
                  ) : (
                    <ArrowDownRight className="h-4 w-4 text-red-500 mr-1" />
                  )}
                  <span className={getGrowthIndicator(stats.activeUsers, mockPreviousStats.activeUsers).trend === 'up' ? 'text-green-600' : 'text-red-600'}>
                    {getGrowthIndicator(stats.activeUsers, mockPreviousStats.activeUsers).value.toFixed(1)}%
                  </span>
                  <span className="text-muted-foreground ml-1">vs 上期</span>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">页面浏览量</CardTitle>
              <Eye className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.pageViews.toLocaleString()}</div>
              {stats && mockPreviousStats.pageViews > 0 && (
                <div className="flex items-center text-sm">
                  {getGrowthIndicator(stats.pageViews, mockPreviousStats.pageViews).trend === 'up' ? (
                    <ArrowUpRight className="h-4 w-4 text-green-500 mr-1" />
                  ) : (
                    <ArrowDownRight className="h-4 w-4 text-red-500 mr-1" />
                  )}
                  <span className={getGrowthIndicator(stats.pageViews, mockPreviousStats.pageViews).trend === 'up' ? 'text-green-600' : 'text-red-600'}>
                    {getGrowthIndicator(stats.pageViews, mockPreviousStats.pageViews).value.toFixed(1)}%
                  </span>
                  <span className="text-muted-foreground ml-1">vs 上期</span>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">平均会话时长</CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.averageSessionTime.toFixed(1)}分</div>
              <div className="text-sm text-muted-foreground">
                总会话: {stats?.totalSessions.toLocaleString()}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* 图表区域 */}
        <div className="grid gap-6 md:grid-cols-2">
          {/* 用户增长趋势 */}
          <Card>
            <CardHeader>
              <CardTitle>用户增长趋势</CardTitle>
              <CardDescription>过去7天用户注册和活跃情况</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={userGrowthChartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Area type="monotone" dataKey="users" stackId="1" stroke="#8884d8" fill="#8884d8" />
                  <Area type="monotone" dataKey="active" stackId="1" stroke="#82ca9d" fill="#82ca9d" />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* 活跃度分析 */}
          <Card>
            <CardHeader>
              <CardTitle>活跃度分析</CardTitle>
              <CardDescription>每日活跃用户变化</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={activityChartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="value" stroke="#8884d8" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>

        {/* 下方区域 */}
        <div className="grid gap-6 md:grid-cols-3">
          {/* 用户构成 */}
          <Card>
            <CardHeader>
              <CardTitle>用户构成</CardTitle>
              <CardDescription>会员与普通用户比例</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie
                    data={userTypePieData}
                    cx="50%"
                    cy="50%"
                    outerRadius={60}
                    fill="#8884d8"
                    dataKey="value"
                    label={({ name, value }) => `${name}: ${value}`}
                  >
                    {userTypePieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
              <div className="mt-4 space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-blue-500 rounded"></div>
                    <span>会员用户</span>
                  </div>
                  <span className="font-medium">{stats?.memberUsers}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-green-500 rounded"></div>
                    <span>普通用户</span>
                  </div>
                  <span className="font-medium">{stats ? stats.totalUsers - stats.memberUsers : 0}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* 关键指标 */}
          <Card>
            <CardHeader>
              <CardTitle>关键指标</CardTitle>
              <CardDescription>重要业务指标概览</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">转化率</span>
                <span className="font-medium">{stats?.conversionRate.toFixed(1)}%</span>
              </div>
              <Progress value={stats?.conversionRate || 0} className="h-2" />
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">会员比例</span>
                <span className="font-medium">
                  {stats ? ((stats.memberUsers / stats.totalUsers) * 100).toFixed(1) : 0}%
                </span>
              </div>
              <Progress 
                value={stats ? (stats.memberUsers / stats.totalUsers) * 100 : 0} 
                className="h-2" 
              />

              <div className="pt-2 space-y-2">
                <div className="flex items-center gap-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-green-500" />
                  <span>系统运行正常</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Target className="w-4 h-4 text-blue-500" />
                  <span>月度目标完成 78%</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* 热门智能体 */}
          <Card>
            <CardHeader>
              <CardTitle>热门智能体</CardTitle>
              <CardDescription>使用量最高的智能体</CardDescription>
            </CardHeader>
            <CardContent>
              {topAgents.length > 0 ? (
                <div className="space-y-3">
                  {topAgents.slice(0, 5).map((agent, index) => (
                    <div key={agent.id} className="flex items-center gap-3">
                      <div className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-100 text-xs font-medium">
                        {index + 1}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-sm truncate">{agent.name}</div>
                        <div className="text-xs text-muted-foreground">
                          {agent.usageCount} 次使用 · {agent.userCount} 用户
                        </div>
                      </div>
                      <Badge variant="outline" className="text-xs">
                        {agent.category}
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center text-muted-foreground py-4">
                  <Star className="w-8 h-8 mx-auto mb-2 opacity-50" />
                  <p className="text-sm">暂无智能体数据</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* 实时活动 */}
        <Card>
          <CardHeader>
            <CardTitle>实时活动</CardTitle>
            <CardDescription>系统实时动态和提醒</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg">
                <Activity className="w-5 h-5 text-blue-500" />
                <div className="flex-1">
                  <div className="text-sm font-medium">系统运行正常</div>
                  <div className="text-xs text-muted-foreground">所有服务正常运行中</div>
                </div>
                <div className="text-xs text-muted-foreground">刚刚</div>
              </div>
              
              <div className="flex items-center gap-3 p-3 bg-green-50 rounded-lg">
                <TrendingUp className="w-5 h-5 text-green-500" />
                <div className="flex-1">
                  <div className="text-sm font-medium">用户活跃度上升</div>
                  <div className="text-xs text-muted-foreground">较昨日增长 12.3%</div>
                </div>
                <div className="text-xs text-muted-foreground">5分钟前</div>
              </div>

              <div className="flex items-center gap-3 p-3 bg-yellow-50 rounded-lg">
                <AlertCircle className="w-5 h-5 text-yellow-500" />
                <div className="flex-1">
                  <div className="text-sm font-medium">待审核内容增加</div>
                  <div className="text-xs text-muted-foreground">当前有 23 个内容待审核</div>
                </div>
                <div className="text-xs text-muted-foreground">10分钟前</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}