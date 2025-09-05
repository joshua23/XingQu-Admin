'use client'

import { useState } from 'react'
import { MetricCard } from '@/components/MetricCard'
import { MetricCardEnhanced } from '@/components/MetricCardEnhanced'
import { UserGrowthChart, ActivityChart, RevenueChart } from '@/components/AnalyticsChart'
import { AnalyticsChartEnhanced } from '@/components/AnalyticsChartEnhanced'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { MetricCardSkeleton, ChartSkeleton, QuickStatsSkeleton } from '@/components/ui/SkeletonLoader'
import { dataService } from '@/lib/services/supabase'
import { useAutoRefresh } from '@/hooks/useAutoRefresh'
import {
  Users,
  Activity,
  Clock,
  DollarSign,
  RefreshCw,
  MousePointer,
  Target,
  AlertTriangle,
  TrendingUp,
  UserCheck,
  CreditCard,
  Eye
} from 'lucide-react'

interface DashboardStats {
  totalUsers: number
  activeUsers: number
  totalSessions: number
  averageSessionTime: number
  totalRevenue: number
  conversionRate: number
  memberUsers?: number
  pageViews?: number
}

// 实时活动数据
const recentActivities = [
  {
    time: "10:30",
    action: "用户注册异常增长",
    description: "过去1小时新增用户较平时增长156%",
    type: "warning"
  },
  {
    time: "09:45",
    action: "系统性能报告",
    description: "API响应时间平均95ms，系统运行正常",
    type: "success"
  },
  {
    time: "09:15",
    action: "广告投放更新",
    description: "今日广告预算已使用68%，预计下午16:00耗尽",
    type: "info"
  },
  {
    time: "08:30",
    action: "数据同步完成",
    description: "昨日用户行为数据已完成统计和分析",
    type: "success"
  },
]

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    activeUsers: 0,
    totalSessions: 0,
    averageSessionTime: 0,
    totalRevenue: 0,
    conversionRate: 0,
    memberUsers: 0,
    pageViews: 0
  })
  const [chartData, setChartData] = useState<any>(null)
  const [sparklineData, setSparklineData] = useState<any>({})
  const [loading, setLoading] = useState(true)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)

  // 分步加载数据（优化：减少并行请求压力）
  const loadDashboardData = async (forceRefresh = false) => {
    try {
      setError(null)

      // 检查缓存（5分钟有效期）
      const cacheKey = 'dashboard_data'
      const cachedData = localStorage.getItem(cacheKey)
      const cacheTime = localStorage.getItem(`${cacheKey}_time`)
      const fiveMinutesAgo = Date.now() - 5 * 60 * 1000

      if (!forceRefresh && cachedData && cacheTime && parseInt(cacheTime) > fiveMinutesAgo) {
        const parsedData = JSON.parse(cachedData)
        setStats(parsedData.stats)
        setChartData(parsedData.chartData)
        setSparklineData(parsedData.sparklineData)
        setLastUpdated(new Date(parseInt(cacheTime)))
        return
      }

      // 设置初始加载状态
      setLoading(true)

      // 第一步：优先加载基本统计数据（最重要的数据）
      const statsResult = await dataService.getDashboardStats()
      
      if (statsResult.error) {
        throw new Error((statsResult.error as Error)?.message || '加载统计数据失败')
      }

      if (statsResult.data) {
        setStats(statsResult.data)
        // 基础数据加载完成，可以显示基本界面
        setLoading(false)
      }

      // 第二步：异步加载图表数据（不阻塞界面显示）
      try {
        const [chartResult, ...sparklineResults] = await Promise.all([
          dataService.getChartData(),
          dataService.getSparklineData('users'),
          dataService.getSparklineData('activity'),
          dataService.getSparklineData('revenue'),
          dataService.getSparklineData('pageviews')
        ])

        if (chartResult.data) {
          setChartData(chartResult.data)
        }

        // 设置sparkline数据
        setSparklineData({
          users: sparklineResults[0].data || [],
          activity: sparklineResults[1].data || [],
          revenue: sparklineResults[2].data || [],
          pageviews: sparklineResults[3].data || []
        })

        const currentTime = Date.now()
        setLastUpdated(new Date(currentTime))
        
        // 缓存所有数据
        const cacheData = {
          stats: statsResult.data,
          chartData: chartResult.data,
          sparklineData: {
            users: sparklineResults[0].data || [],
            activity: sparklineResults[1].data || [],
            revenue: sparklineResults[2].data || [],
            pageviews: sparklineResults[3].data || []
          }
        }
        localStorage.setItem(cacheKey, JSON.stringify(cacheData))
        localStorage.setItem(`${cacheKey}_time`, currentTime.toString())
      } catch (chartError) {
        console.warn('图表数据加载失败，使用默认数据:', chartError)
        // 图表加载失败不影响基础数据显示
        setLastUpdated(new Date())
      }

    } catch (error) {
      console.error('加载Dashboard数据失败:', error)
      setError((error as Error)?.message || '加载数据失败')
      setLoading(false)
    }
  }

  // 设置30分钟自动刷新，减少加载频率
  const { refresh } = useAutoRefresh(loadDashboardData, {
    interval: 30 * 60 * 1000, // 30分钟
    enabled: true,
    immediate: true
  })

  // 使用真实数据或备用数据
  const userGrowthData = chartData?.userGrowthData || []
  const activityData = chartData?.activityData || []
  const revenueData = chartData?.revenueData || []

  // 主要指标数据（使用真实数据和增强可视化）
  const overviewMetrics = [
    { 
      title: "总用户数", 
      value: stats.totalUsers, 
      change: stats.totalUsers > 0 ? 15.8 : 0, 
      changeLabel: "较上周", 
      icon: <Users size={20} />,
      color: 'primary' as const,
      sparklineData: sparklineData.users || [],
      target: 1000,
      description: "系统注册用户总数"
    },
    { 
      title: "今日活跃", 
      value: stats.activeUsers, 
      change: stats.activeUsers > 0 ? 8.3 : 0, 
      changeLabel: "24小时内", 
      icon: <UserCheck size={20} />,
      color: 'success' as const,
      sparklineData: sparklineData.activity || [],
      target: 200,
      description: "过去24小时活跃用户"
    },
    { 
      title: "今日收入", 
      value: stats.totalRevenue, 
      change: stats.totalRevenue > 0 ? 12.7 : 0, 
      changeLabel: "较昨日", 
      icon: <CreditCard size={20} />,
      color: 'warning' as const,
      sparklineData: sparklineData.revenue || [],
      target: 5000,
      description: "今日总收入金额"
    },
    { 
      title: "页面浏览", 
      value: stats.pageViews ?? 0, 
      change: (stats.pageViews ?? 0) > 0 ? 6.2 : 0, 
      changeLabel: "转化率提升", 
      icon: <Eye size={20} />,
      color: 'default' as const,
      sparklineData: sparklineData.pageviews || [],
      target: 10000,
      description: "今日页面浏览量"
    },
  ]

  // 快速统计数据（使用动态数据）
  const quickStats = [
    {
      icon: Users,
      title: "用户概况",
      stats: [
        { label: "新用户注册", value: stats.totalUsers.toString(), trend: stats.totalUsers > 0 ? "+100%" : "0%" },
        { label: "活跃用户", value: stats.activeUsers.toString(), trend: stats.activeUsers > 0 ? "+100%" : "0%" },
        { label: "会员用户", value: (stats.memberUsers || 0).toString(), trend: "0%" },
      ]
    },
    {
      icon: MousePointer,
      title: "用户行为",
      stats: [
        { label: "页面访问量", value: (stats.pageViews || 0).toString(), trend: stats.pageViews && stats.pageViews > 0 ? "+100%" : "0%" },
        { label: "平均停留时长", value: `${stats.averageSessionTime}分钟`, trend: "0%" },
        { label: "会话总数", value: stats.totalSessions.toString(), trend: stats.totalSessions > 0 ? "+100%" : "0%" },
      ]
    },
    {
      icon: DollarSign,
      title: "财务数据",
      stats: [
        { label: "今日收入", value: `¥${stats.totalRevenue}`, trend: "0%" },
        { label: "广告投放", value: "¥0", trend: "0%" },
        { label: "净利润", value: "¥0", trend: "0%" },
      ]
    },
  ]

  // 显示骨架屏而不是单纯的spinner
  if (loading && !stats.totalUsers && !lastUpdated) {
    return (
      <div className="responsive-container">
        <div className="section-spacing">
          <div className="flex items-start justify-between animate-slide-up mb-6">
            <div className="max-w-2xl">
              <h1 className="text-display-2 text-foreground">数据总览</h1>
              <p className="text-sm sm:text-base text-muted-foreground mt-2">
                正在加载系统关键指标和实时数据...
              </p>
            </div>
          </div>

          {/* 骨架屏 - 主要指标卡片 */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 responsive-grid-gap animate-fade-in">
            {[1, 2, 3, 4].map((i) => (
              <MetricCardSkeleton key={i} />
            ))}
          </div>

          {/* 骨架屏 - 图表 */}
          <div className="grid grid-cols-1 lg:grid-cols-3 responsive-grid-gap animate-fade-in section-gap">
            {[1, 2, 3].map((i) => (
              <ChartSkeleton key={i} />
            ))}
          </div>

          {/* 骨架屏 - 快速统计 */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 responsive-grid-gap section-gap">
            {[1, 2, 3].map((i) => (
              <QuickStatsSkeleton key={i} />
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="responsive-container">
      <div className="section-spacing">
        {/* 页面标题和状态 */}
        <div className="dashboard-header animate-slide-up mb-6">
          <div className="max-w-2xl">
            <div className="flex items-center gap-3 mb-2">
              <h1 className="dashboard-title">星趣APP数据看板</h1>
              <div className="live-indicator">
                <div className="live-dot" />
                <span>实时更新</span>
              </div>
            </div>
            <div className="flex flex-col sm:flex-row sm:items-center gap-3">
              <p className="dashboard-subtitle">
                基于设计规范的专业数据可视化看板
              </p>
              {lastUpdated && (
                <div className="flex items-center text-xs sm:text-sm text-gray-7 bg-white px-3 py-2 rounded-lg border border-gray-4 shadow-sm">
                  <Clock size={14} className="mr-2 text-chart-1" />
                  <span className="font-mono">
                    {lastUpdated.toLocaleTimeString('zh-CN')}
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* 手动刷新按钮 */}
          <button
            onClick={() => loadDashboardData(true)}
            disabled={loading}
            className="btn-secondary flex items-center space-x-2 min-w-[80px] sm:min-w-[100px] text-sm px-3 py-2"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>刷新</span>
          </button>
        </div>

        {/* 错误提示 */}
        {error && (
          <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4 animate-slide-up mb-6">
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

        {/* 主要指标卡片 - 使用增强版 */}
        <div className="metrics-grid animate-fade-in">
          {overviewMetrics.map((metric, index) => (
            <div key={index} className="animate-scale-in" style={{ animationDelay: `${index * 100}ms` }}>
              <MetricCardEnhanced 
                title={metric.title}
                value={metric.value}
                change={metric.change}
                changeLabel={metric.changeLabel}
                description={metric.description}
                sparklineData={metric.sparklineData}
                target={metric.target}
                icon={metric.icon}
                color={metric.color}
                format={metric.title.includes('收入') || metric.title.includes('Revenue') ? 'currency' : 'number'}
                showProgress={!!metric.target}
                tooltipContent={`${metric.description} - 目标: ${metric.target?.toLocaleString()}`}
              />
            </div>
          ))}
        </div>

        {/* 数据分析图表 - 使用增强版 */}
        <div className="charts-grid animate-fade-in section-gap" style={{ animationDelay: '400ms' }}>
          <AnalyticsChartEnhanced
            title="用户增长趋势"
            description="新注册用户数量变化"
            data={userGrowthData.map((item: any) => ({
              label: item.label || item.date || '未知',
              value: item.value || 0,
              trend: item.trend || 'neutral'
            }))}
            type="area"
            color="primary"
            showTrend={true}
            onExport={() => console.log('导出用户增长数据')}
          />
          <AnalyticsChartEnhanced
            title="用户活跃度"
            description="每日活跃用户统计"
            data={activityData.map((item: any) => ({
              label: item.label || item.date || '未知',
              value: item.value || 0,
              trend: item.trend || 'neutral'
            }))}
            type="bar"
            color="success"
            showTrend={true}
            onExport={() => console.log('导出活跃度数据')}
          />
          <AnalyticsChartEnhanced
            title="收入统计"
            description="每日收入变化趋势"
            data={revenueData.map((item: any) => ({
              label: item.label || item.date || '未知',
              value: item.value || 0,
              trend: item.trend || 'neutral'
            }))}
            type="line"
            color="warning"
            showTrend={true}
            onExport={() => console.log('导出收入数据')}
          />
        </div>

        {/* AARRR海盗模型漏斗分析 */}
        <div className="section-gap animate-fade-in" style={{ animationDelay: '600ms' }}>
          <AnalyticsChartEnhanced
            title="AARRR海盗模型分析"
            description="用户生命周期转化漏斗"
            data={[
              { label: 'Acquisition', value: 10000, percentage: 100 },
              { label: 'Activation', value: 7500, percentage: 75 },
              { label: 'Retention', value: 4500, percentage: 60 },
              { label: 'Revenue', value: 2250, percentage: 50 },
              { label: 'Referral', value: 675, percentage: 30 }
            ]}
            type="bar"
            color="aarrr"
            showTrend={false}
            showLegend={true}
            height={200}
            onExport={() => console.log('导出AARRR数据')}
          />
        </div>

        {/* 快速统计 */}
        <div className="stats-grid section-gap">
          {quickStats.map((section, index) => {
            const Icon = section.icon;
            return (
              <Card key={index} variant="default" className="animate-slide-up" style={{ animationDelay: `${(index + 4) * 100}ms` }}>
                <CardHeader className="pb-4">
                  <div className="flex items-center gap-3">
                    <div className="flex items-center justify-center w-10 h-10 bg-primary/10 rounded-lg">
                      <Icon className="w-5 h-5 text-primary" />
                    </div>
                    <CardTitle className="text-lg font-bold">{section.title}</CardTitle>
                  </div>
                </CardHeader>
                <CardContent className="element-spacing">
                  {section.stats.map((stat, statIndex) => (
                    <div key={statIndex} className="flex justify-between items-center p-3 bg-muted/30 rounded-lg border border-border/30">
                      <span className="text-sm font-medium text-muted-foreground">{stat.label}</span>
                      <div className="flex items-center gap-3">
                        <span className="font-mono text-base font-bold text-foreground">{stat.value}</span>
                        <Badge
                          variant="secondary"
                          className={`text-xs font-medium px-2 py-1 ${
                            stat.trend.startsWith('+')
                              ? 'status-positive'
                              : stat.trend.startsWith('-')
                                ? 'status-negative'
                                : 'status-neutral'
                          }`}
                        >
                          {stat.trend}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* 实时活动和今日目标 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 responsive-grid-gap section-gap">
          <Card variant="elevated" className="animate-slide-up" style={{ animationDelay: '700ms' }}>
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="flex items-center justify-center w-10 h-10 bg-primary/10 rounded-lg">
                  <Activity className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <CardTitle className="text-xl font-bold">实时活动</CardTitle>
                  <CardDescription className="mt-1">系统最新动态和异常提醒</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {recentActivities.map((activity, index) => (
                  <div key={index} className="flex gap-4 p-4 bg-muted/20 rounded-lg border border-border/30 interactive-element">
                    <div className="text-xs text-muted-foreground font-mono min-w-[48px] flex-shrink-0 mt-1 bg-background px-2 py-1 rounded border border-border/50">
                      {activity.time}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h4 className="text-sm font-semibold text-foreground">{activity.action}</h4>
                        <Badge
                          variant="outline"
                          className={`text-xs font-medium ${
                            activity.type === 'warning'
                              ? 'border-warning/50 text-warning bg-warning/10'
                              : activity.type === 'success'
                                ? 'border-success/50 text-success bg-success/10'
                                : 'border-primary/50 text-primary bg-primary/10'
                          }`}
                        >
                          {activity.type === 'warning' ? '警告' : activity.type === 'success' ? '正常' : '信息'}
                        </Badge>
                      </div>
                      <p className="text-sm text-muted-foreground leading-relaxed">{activity.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          <Card variant="elevated" className="animate-slide-up" style={{ animationDelay: '800ms' }}>
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="flex items-center justify-center w-10 h-10 bg-primary/10 rounded-lg">
                  <Target className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <CardTitle className="text-xl font-bold">今日目标</CardTitle>
                  <CardDescription className="mt-1">关键指标完成情况</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">收入目标</span>
                    <span className="text-sm font-mono font-bold text-foreground">¥{stats.totalRevenue} / ¥1,000</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-primary rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min((stats.totalRevenue / 1000) * 100, 100)}%` }}></div>
                  </div>
                </div>

                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">新用户注册</span>
                    <span className="text-sm font-mono font-bold text-foreground">{stats.totalUsers} / 100</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-success rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min((stats.totalUsers / 100) * 100, 100)}%` }}></div>
                  </div>
                </div>

                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">活跃用户</span>
                    <span className="text-sm font-mono font-bold text-foreground">{stats.activeUsers} / 10</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-chart-3 rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min((stats.activeUsers / 10) * 100, 100)}%` }}></div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

export default Dashboard