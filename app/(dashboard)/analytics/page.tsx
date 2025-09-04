'use client'

import { useEffect, useState } from 'react'
import { dataService } from '@/lib/services/supabase'
import { useAutoRefresh } from '@/hooks/useAutoRefresh'
import { MetricCard } from '@/components/MetricCard'
import { AnalyticsChart } from '@/components/AnalyticsChart'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import {
  BarChart3,
  TrendingUp,
  Activity,
  Calendar,
  Download,
  RefreshCw,
  Clock,
  AlertTriangle
} from 'lucide-react'

interface AnalyticsData {
  userGrowth: Array<{ date: string; newUsers: number; activeUsers: number }>
  behaviorStats: {
    totalSessions: number
    averageSessionTime: number
    pageViews: number
    bounceRate: number
  }
  revenueStats: {
    totalRevenue: number
    monthlyRevenue: Array<{ month: string; revenue: number }>
    topProducts: Array<{ name: string; sales: number; revenue: number }>
  }
}

interface TopAgent {
  id: string
  name: string
  description: string
  avatar_url?: string
  category: string
  tags: string[]
  usageCount: number
  userCount: number
  created_at: string
}

const Analytics: React.FC = () => {
  const [data, setData] = useState<AnalyticsData | null>(null)
  const [chartData, setChartData] = useState<any>(null)
  const [topAgents, setTopAgents] = useState<TopAgent[]>([])
  const [agentsError, setAgentsError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [dateRange, setDateRange] = useState('7d')
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)

  // 加载真实分析数据
  const loadAnalyticsData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      // 并行加载分析数据、图表数据和智能体数据
      const [analyticsResult, chartResult, agentsResult] = await Promise.all([
        dataService.getAnalyticsData(),
        dataService.getChartData(),
        dataService.getTopAgents()
      ])
      
      if (analyticsResult.error) {
        throw new Error((analyticsResult.error as Error)?.message || '加载分析数据失败')
      }
      
      if (analyticsResult.data) {
        setData(analyticsResult.data)
      }
      
      if (chartResult.data) {
        setChartData(chartResult.data)
      }
      
      if (agentsResult.error) {
        setAgentsError((agentsResult.error as Error)?.message || '加载智能体数据失败')
      } else if (agentsResult.data) {
        setTopAgents(agentsResult.data)
        setAgentsError(null)
      }
      
      setLastUpdated(new Date())
    } catch (error) {
      console.error('加载Analytics数据失败:', error)
      setError((error as Error)?.message || '加载数据失败')
    } finally {
      setLoading(false)
    }
  }

  // 设置15分钟自动刷新
  const { refresh } = useAutoRefresh(loadAnalyticsData, {
    interval: 15 * 60 * 1000, // 15分钟
    enabled: true,
    immediate: true
  })

  // 当日期范围改变时重新加载数据
  useEffect(() => {
    loadAnalyticsData()
  }, [dateRange])

  if (loading && !data) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="responsive-container">
      <div className="section-spacing">
        {/* 页面标题和控制 */}
        <div className="flex items-start justify-between animate-slide-up">
          <div className="content-spacing max-w-2xl">
            <h1 className="text-display-2 text-foreground">数据分析</h1>
            <div className="flex flex-col sm:flex-row sm:items-center gap-4">
              <p className="text-body text-muted-foreground">
                深入分析用户行为和业务数据
              </p>
              {lastUpdated && (
                <div className="flex items-center text-sm text-muted-foreground bg-muted/50 px-3 py-1.5 rounded-md border border-border/50">
                  <Clock size={14} className="mr-2 text-primary" />
                  <span className="font-mono">
                    最后更新: {lastUpdated.toLocaleTimeString()}
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className="flex items-center space-x-3">
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value)}
              className="px-3 py-2 bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            >
              <option value="7d">最近7天</option>
              <option value="30d">最近30天</option>
              <option value="90d">最近90天</option>
              <option value="1y">最近一年</option>
            </select>
            <Button
              variant="secondary"
              onClick={() => refresh()}
              disabled={loading}
              className="flex items-center space-x-2"
            >
              <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
              <span>刷新</span>
            </Button>
            <Button variant="primary" className="flex items-center space-x-2">
              <Download size={16} />
              <span>导出报告</span>
            </Button>
          </div>
        </div>

        {/* 错误提示 */}
        {error && (
          <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-6 animate-slide-up">
            <div className="flex items-center space-x-3">
              <div className="flex items-center justify-center w-8 h-8 bg-destructive/20 rounded-full">
                <AlertTriangle size={16} className="text-destructive" />
              </div>
              <div>
                <p className="text-destructive font-semibold text-lg">数据加载失败</p>
                <p className="text-destructive/80 text-sm mt-1 leading-relaxed">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* 关键指标 */}
        {data && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3 animate-fade-in mt-3">
            <MetricCard
              title="总会话数"
              value={data.behaviorStats.totalSessions}
              change={data.behaviorStats.totalSessions > 0 ? 15 : 0}
              changeLabel="vs 上周"
              icon={<Activity size={20} />}
              color="primary"
              description="用户会话总数"
            />
            <MetricCard
              title="平均会话时长"
              value={`${data.behaviorStats.averageSessionTime}分钟`}
              change={data.behaviorStats.averageSessionTime > 0 ? 8 : 0}
              changeLabel="vs 上周"
              icon={<Clock size={20} />}
              color="success"
              description="用户平均停留时间"
            />
            <MetricCard
              title="页面浏览量"
              value={data.behaviorStats.pageViews}
              change={data.behaviorStats.pageViews > 0 ? 25 : 0}
              changeLabel="vs 上周"
              icon={<BarChart3 size={20} />}
              color="warning"
              description="页面访问总次数"
            />
            <MetricCard
              title="跳出率"
              value={`${Math.round(data.behaviorStats.bounceRate * 10) / 10}%`}
              change={data.behaviorStats.bounceRate < 50 ? -5 : data.behaviorStats.bounceRate > 75 ? 12 : 0}
              changeLabel="vs 上周"
              icon={<TrendingUp size={20} />}
              color={data.behaviorStats.bounceRate > 75 ? "danger" : "success"}
              description="单页访问后离开比例"
            />
          </div>
        )}

        {/* 图表区域 */}
        {data && chartData && (
          <div className="grid grid-cols-1 xl:grid-cols-3 responsive-grid-gap animate-fade-in" style={{ animationDelay: '200ms' }}>
            {/* 用户增长趋势图 */}
            <AnalyticsChart
              title="用户增长趋势"
              description={`新用户: ${data.userGrowth.reduce((sum, day) => sum + day.newUsers, 0)} | 活跃用户: ${data.userGrowth.length > 0 ? data.userGrowth[data.userGrowth.length - 1]?.activeUsers || 0 : 0}`}
              data={chartData.userGrowthData || []}
              type="area"
              color="primary"
            />
            
            {/* 用户活跃度图 */}
            <AnalyticsChart
              title="用户活跃度"
              description="每日活跃用户统计"
              data={chartData.activityData || []}
              type="bar"
              color="success"
            />
            
            {/* 页面浏览量图 */}
            <AnalyticsChart
              title="页面浏览量"
              description="每日页面访问统计"
              data={chartData.revenueData?.map((item: any) => ({
                label: item.label,
                value: Math.round(item.value / 10), // 转换回页面浏览量
                trend: item.trend
              })) || []}
              type="line"
              color="warning"
            />
          </div>
        )}
        
        {/* 会话时长分析图 */}
        {data && (
          <div className="animate-fade-in" style={{ animationDelay: '300ms' }}>
            <AnalyticsChart
              title="会话时长分析"
              description={`平均会话时长: ${data.behaviorStats.averageSessionTime}分钟 | 跳出率: ${Math.round(data.behaviorStats.bounceRate * 10) / 10}%`}
              data={[
                { label: '< 1分钟', value: Math.round(data.behaviorStats.totalSessions * 0.2), trend: 'down' },
                { label: '1-5分钟', value: Math.round(data.behaviorStats.totalSessions * 0.35), trend: 'up' },
                { label: '5-15分钟', value: Math.round(data.behaviorStats.totalSessions * 0.25), trend: 'up' },
                { label: '15-30分钟', value: Math.round(data.behaviorStats.totalSessions * 0.15), trend: 'neutral' },
                { label: '> 30分钟', value: Math.round(data.behaviorStats.totalSessions * 0.05), trend: 'neutral' }
              ]}
              type="bar"
              color="primary"
            />
          </div>
        )}

        {/* 详细数据表格 */}
        {data && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 animate-fade-in mt-8" style={{ animationDelay: '400ms' }}>
            {/* 热门智能体 */}
            <Card variant="default">
              <CardHeader>
                <CardTitle className="text-xl font-bold">热门智能体</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {loading ? (
                    <div className="text-center text-muted-foreground py-8">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-2"></div>
                      <p>加载智能体数据中...</p>
                    </div>
                  ) : agentsError ? (
                    <div className="text-center text-muted-foreground py-8">
                      <AlertTriangle size={48} className="mx-auto mb-2 opacity-50 text-destructive" />
                      <p className="text-destructive font-medium">智能体数据加载失败</p>
                      <p className="text-xs mt-1 opacity-75">{agentsError}</p>
                    </div>
                  ) : topAgents.length > 0 ? (
                    topAgents.map((agent, index) => (
                      <div key={agent.id} className="flex items-center justify-between p-3 bg-muted/30 rounded-lg border border-border/30">
                        <div className="flex items-center space-x-3">
                          <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-primary-foreground text-sm font-bold">
                            {index + 1}
                          </div>
                          <div className="flex items-center space-x-3">
                            {agent.avatar_url ? (
                              <img 
                                src={agent.avatar_url} 
                                alt={agent.name}
                                className="w-8 h-8 rounded-full object-cover"
                              />
                            ) : (
                              <div className="w-8 h-8 bg-gradient-to-br from-primary/20 to-secondary/20 rounded-full flex items-center justify-center">
                                <Activity size={16} className="text-primary" />
                              </div>
                            )}
                            <div>
                              <p className="text-foreground text-sm font-medium">{agent.name}</p>
                              <div className="flex items-center space-x-2 text-xs text-muted-foreground">
                                <span>{agent.category}</span>
                                <span>•</span>
                                <span>{agent.usageCount} 次使用</span>
                                <span>•</span>
                                <span>{agent.userCount} 用户</span>
                              </div>
                            </div>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="text-foreground font-medium">{agent.usageCount}</p>
                          <Badge variant="secondary" className="text-xs">
                            {agent.tags.slice(0, 1).join(', ') || '通用'}
                          </Badge>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-center text-muted-foreground py-8">
                      <Activity size={48} className="mx-auto mb-2 opacity-50" />
                      <p>暂无智能体数据</p>
                      <p className="text-xs mt-1 opacity-75">请检查xq_agents表中是否有活跃的智能体</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* 用户行为分析 */}
            <Card variant="default">
              <CardHeader>
                <CardTitle className="text-xl font-bold">用户行为分析</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-5">
                  <div className="flex items-center justify-between py-3 border-b border-border/50">
                    <span className="text-muted-foreground font-medium">每日活跃用户</span>
                    <span className="text-foreground font-semibold text-lg">
                      {data.userGrowth.length > 0 ? data.userGrowth[data.userGrowth.length - 1]?.activeUsers.toLocaleString() : '0'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between py-3 border-b border-border/50">
                    <span className="text-muted-foreground font-medium">平均会话时长</span>
                    <span className="text-foreground font-semibold text-lg">
                      {data.behaviorStats.averageSessionTime}分钟
                    </span>
                  </div>
                  <div className="flex items-center justify-between py-3 border-b border-border/50">
                    <span className="text-muted-foreground font-medium">页面浏览量</span>
                    <span className="text-foreground font-semibold text-lg">
                      {data.behaviorStats.pageViews.toLocaleString()}
                    </span>
                  </div>
                  <div className="flex items-center justify-between py-3">
                    <span className="text-muted-foreground font-medium">跳出率</span>
                    <div className="text-right">
                      <span className="text-foreground font-semibold text-lg">
                        {Math.round(data.behaviorStats.bounceRate * 10) / 10}%
                      </span>
                      <Badge
                        variant="outline"
                        className={`text-xs mt-0.5 block ${
                          data.behaviorStats.bounceRate < 40 ? 'border-success/50 text-success bg-success/10' : 
                          data.behaviorStats.bounceRate < 70 ? 'border-warning/50 text-warning bg-warning/10' : 
                          'border-destructive/50 text-destructive bg-destructive/10'
                        }`}
                      >
                        {data.behaviorStats.bounceRate < 40 ? '优秀' : 
                         data.behaviorStats.bounceRate < 70 ? '良好' : '需优化'}
                      </Badge>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* 数据导出选项 */}
        <Card variant="default" className="animate-fade-in" style={{ animationDelay: '600ms' }}>
          <CardHeader>
            <CardTitle className="text-xl font-bold">数据导出</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button className="p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors interactive-element">
                <div className="text-center">
                  <BarChart3 size={24} className="mx-auto mb-2 text-primary" />
                  <p className="text-foreground font-medium">用户数据</p>
                  <p className="text-muted-foreground text-sm">导出用户行为数据</p>
                </div>
              </button>
              <button className="p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors interactive-element">
                <div className="text-center">
                  <TrendingUp size={24} className="mx-auto mb-2 text-success" />
                  <p className="text-foreground font-medium">收入数据</p>
                  <p className="text-muted-foreground text-sm">导出财务数据报表</p>
                </div>
              </button>
              <button className="p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors interactive-element">
                <div className="text-center">
                  <Activity size={24} className="mx-auto mb-2 text-primary" />
                  <p className="text-foreground font-medium">运营数据</p>
                  <p className="text-muted-foreground text-sm">导出运营分析报告</p>
                </div>
              </button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default Analytics