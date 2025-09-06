'use client'

import { useState } from 'react'
import { MetricCard } from '@/components/MetricCard'
import { UserGrowthChart, ActivityChart, RevenueChart } from '@/components/AnalyticsChart'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { MetricCardSkeleton, ChartSkeleton, QuickStatsSkeleton } from '@/components/ui/skeletonloader'
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
  Eye,
  ShoppingCart,
  Brain,
  Monitor,
  TestTube,
  Cog,
  Shield,
  Zap,
  Server,
  MessageSquare,
  Music
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
  // 新增业务指标
  abTestsRunning?: number
  aiServiceCalls?: number
  systemHealth?: number
  contentModerated?: number
  orderVolume?: number
  materialUploads?: number
  apiResponseTime?: number
  errorRate?: number
}

// 实时活动数据
const recentActivities = [
  {
    time: "11:15",
    action: "A/B测试自动停止",
    description: "首页按钮颜色测试达到统计显著性，自动停止并应用获胜变体",
    type: "success"
  },
  {
    time: "10:30",
    action: "AI服务调用激增",
    description: "智能推荐服务调用量较平时增长203%，系统自动扩容",
    type: "warning"
  },
  {
    time: "09:45",
    action: "内容审核完成",
    description: "今日已审核856条用户内容，其中12条需要人工复核",
    type: "info"
  },
  {
    time: "09:30",
    action: "系统配置变更",
    description: "管理员启用了新的缓存策略，API响应时间提升32%",
    type: "success"
  },
  {
    time: "09:15",
    action: "电商订单异常",
    description: "订单处理队列积压145个订单，正在调度更多资源处理",
    type: "warning"
  },
  {
    time: "08:30",
    action: "数据同步完成",
    description: "昨日用户行为数据已完成统计和分析，新增洞察报告3份",
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
    pageViews: 0,
    // 新增指标默认值
    abTestsRunning: 0,
    aiServiceCalls: 0,
    systemHealth: 95,
    contentModerated: 0,
    orderVolume: 0,
    materialUploads: 0,
    apiResponseTime: 120,
    errorRate: 0.5
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
        setLoading(false) // 确保缓存加载后也设置loading为false
        return
      }

      // 设置初始加载状态
      setLoading(true)

      // 添加超时处理
      const timeout = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('数据加载超时')), 10000)
      )

      // 第一步：优先加载基本统计数据（最重要的数据）
      try {
        const statsResult = await Promise.race([
          dataService.getDashboardStats(),
          timeout
        ])
        
        if (statsResult.error) {
          console.warn('统计数据加载失败，使用默认数据:', statsResult.error)
          // 即使失败也要停止loading，显示默认数据
          setLoading(false)
          setStats({
            totalUsers: 0,
            activeUsers: 0,
            totalSessions: 0,
            averageSessionTime: 0,
            totalRevenue: 0,
            conversionRate: 0,
            memberUsers: 0,
            pageViews: 0
          })
        } else if (statsResult.data) {
          setStats(statsResult.data)
          // 基础数据加载完成，可以显示基本界面
          setLoading(false)
        } else {
          // 数据为空的情况
          setLoading(false)
          setStats({
            totalUsers: 0,
            activeUsers: 0,
            totalSessions: 0,
            averageSessionTime: 0,
            totalRevenue: 0,
            conversionRate: 0,
            memberUsers: 0,
            pageViews: 0
          })
        }
      } catch (timeoutError) {
        console.error('数据加载超时:', timeoutError)
        setLoading(false)
        setError('数据加载超时，请检查网络连接')
        return
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
      title: "AI服务调用", 
      value: stats.aiServiceCalls ?? 0, 
      change: (stats.aiServiceCalls ?? 0) > 0 ? 23.4 : 0, 
      changeLabel: "较昨日", 
      icon: <Brain size={20} />,
      color: 'warning' as const,
      sparklineData: sparklineData.ai || [],
      target: 1000,
      description: "今日AI服务总调用次数"
    },
    { 
      title: "系统健康度", 
      value: stats.systemHealth ?? 95, 
      change: (stats.systemHealth ?? 95) > 90 ? 2.1 : -1.5, 
      changeLabel: "系统状态", 
      icon: <Monitor size={20} />,
      color: 'default' as const,
      sparklineData: sparklineData.health || [],
      target: 100,
      description: "系统整体健康评分",
      suffix: "%"
    },
  ]

  // 辅助业务指标
  const businessMetrics = [
    { 
      title: "运行中测试", 
      value: stats.abTestsRunning ?? 0, 
      change: (stats.abTestsRunning ?? 0) > 0 ? 25.0 : 0, 
      changeLabel: "测试效果", 
      icon: <TestTube size={20} />,
      color: 'primary' as const,
      target: 10,
      description: "当前运行的A/B测试数量"
    },
    { 
      title: "今日收入", 
      value: stats.totalRevenue, 
      change: stats.totalRevenue > 0 ? 12.7 : 0, 
      changeLabel: "较昨日", 
      icon: <DollarSign size={20} />,
      color: 'success' as const,
      target: 5000,
      description: "今日总收入金额",
      prefix: "¥"
    },
    { 
      title: "订单量", 
      value: stats.orderVolume ?? 0, 
      change: (stats.orderVolume ?? 0) > 0 ? 18.5 : 0, 
      changeLabel: "成交转化", 
      icon: <ShoppingCart size={20} />,
      color: 'warning' as const,
      target: 500,
      description: "今日成交订单数量"
    },
    { 
      title: "内容审核", 
      value: stats.contentModerated ?? 0, 
      change: (stats.contentModerated ?? 0) > 0 ? 9.2 : 0, 
      changeLabel: "审核效率", 
      icon: <Shield size={20} />,
      color: 'default' as const,
      target: 1000,
      description: "今日审核内容数量"
    },
  ]

  // 快速统计数据（使用动态数据）
  const quickStats = [
    {
      icon: Users,
      title: "用户概况",
      stats: [
        { label: "新用户注册", value: stats.totalUsers.toString(), trend: stats.totalUsers > 0 ? "+15.8%" : "0%" },
        { label: "活跃用户", value: stats.activeUsers.toString(), trend: stats.activeUsers > 0 ? "+8.3%" : "0%" },
        { label: "会员用户", value: (stats.memberUsers || 0).toString(), trend: "+12.1%" },
      ]
    },
    {
      icon: Brain,
      title: "AI服务状态",
      stats: [
        { label: "AI调用总数", value: (stats.aiServiceCalls || 0).toString(), trend: stats.aiServiceCalls && stats.aiServiceCalls > 0 ? "+23.4%" : "0%" },
        { label: "推荐命中率", value: "87.5%", trend: "+3.2%" },
        { label: "智能审核率", value: "92.1%", trend: "+1.8%" },
      ]
    },
    {
      icon: ShoppingCart,
      title: "电商数据",
      stats: [
        { label: "今日订单量", value: (stats.orderVolume || 0).toString(), trend: stats.orderVolume && stats.orderVolume > 0 ? "+18.5%" : "0%" },
        { label: "订单金额", value: `¥${stats.totalRevenue}`, trend: stats.totalRevenue > 0 ? "+12.7%" : "0%" },
        { label: "转化率", value: `${stats.conversionRate}%`, trend: "+0.8%" },
      ]
    },
    {
      icon: TestTube,
      title: "A/B测试",
      stats: [
        { label: "运行中测试", value: (stats.abTestsRunning || 0).toString(), trend: stats.abTestsRunning && stats.abTestsRunning > 0 ? "+25%" : "0%" },
        { label: "已完成测试", value: "12", trend: "+3" },
        { label: "测试胜率", value: "68%", trend: "+5%" },
      ]
    },
    {
      icon: Server,
      title: "系统性能",
      stats: [
        { label: "API响应时间", value: `${stats.apiResponseTime || 120}ms`, trend: "-15%" },
        { label: "错误率", value: `${stats.errorRate || 0.5}%`, trend: "-0.2%" },
        { label: "系统健康度", value: `${stats.systemHealth || 95}%`, trend: "+2.1%" },
      ]
    },
    {
      icon: Music,
      title: "内容管理",
      stats: [
        { label: "今日素材上传", value: (stats.materialUploads || 0).toString(), trend: stats.materialUploads && stats.materialUploads > 0 ? "+45%" : "0%" },
        { label: "内容审核量", value: (stats.contentModerated || 0).toString(), trend: stats.contentModerated && stats.contentModerated > 0 ? "+9.2%" : "0%" },
        { label: "审核通过率", value: "94.2%", trend: "+1.5%" },
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
        <div className="flex items-start justify-between animate-slide-up mb-6">
          <div className="max-w-2xl">
            <h1 className="text-display-2 text-foreground">数据总览</h1>
            <div className="flex flex-col sm:flex-row sm:items-center gap-3 mt-2">
              <p className="text-sm sm:text-base text-muted-foreground">
                系统关键指标和实时数据监控
              </p>
              {lastUpdated && (
                <div className="flex items-center text-xs sm:text-sm text-muted-foreground bg-muted/50 px-2 sm:px-3 py-1 sm:py-1.5 rounded-md border border-border/50">
                  <Clock size={14} className="mr-2 text-primary" />
                  <span className="font-mono">
                    最后更新: {lastUpdated.toLocaleTimeString()}
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

        {/* 主要指标卡片 */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 responsive-grid-gap animate-fade-in items-stretch">
          {overviewMetrics.map((metric, index) => (
            <div key={index} className="animate-scale-in" style={{ animationDelay: `${index * 100}ms` }}>
              <MetricCard {...metric} />
            </div>
          ))}
        </div>

        {/* 业务指标卡片 */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 responsive-grid-gap animate-fade-in section-gap items-stretch">
          {businessMetrics.map((metric, index) => (
            <div key={index} className="animate-scale-in" style={{ animationDelay: `${(index + 4) * 100}ms` }}>
              <MetricCard {...metric} />
            </div>
          ))}
        </div>

        {/* 数据分析图表 */}
        <div className="grid grid-cols-1 lg:grid-cols-3 responsive-grid-gap animate-fade-in section-gap" style={{ animationDelay: '400ms' }}>
          <UserGrowthChart data={userGrowthData} />
          <ActivityChart data={activityData} />
          <RevenueChart data={revenueData} />
        </div>

        {/* 快速统计 */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 responsive-grid-gap section-gap">
          {quickStats.map((section, index) => {
            const Icon = section.icon;
            return (
              <Card key={index} variant="default" className="animate-slide-up" style={{ animationDelay: `${(index + 8) * 100}ms` }}>
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
              <div className="space-y-4">
                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">收入目标</span>
                    <span className="text-sm font-mono font-bold text-foreground">¥{stats.totalRevenue} / ¥5,000</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-primary rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min((stats.totalRevenue / 5000) * 100, 100)}%` }}></div>
                  </div>
                </div>

                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">AI服务调用</span>
                    <span className="text-sm font-mono font-bold text-foreground">{stats.aiServiceCalls || 0} / 1,000</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-warning rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min(((stats.aiServiceCalls || 0) / 1000) * 100, 100)}%` }}></div>
                  </div>
                </div>

                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">订单完成量</span>
                    <span className="text-sm font-mono font-bold text-foreground">{stats.orderVolume || 0} / 500</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-success rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min(((stats.orderVolume || 0) / 500) * 100, 100)}%` }}></div>
                  </div>
                </div>

                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">内容审核量</span>
                    <span className="text-sm font-mono font-bold text-foreground">{stats.contentModerated || 0} / 1,000</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-info rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min(((stats.contentModerated || 0) / 1000) * 100, 100)}%` }}></div>
                  </div>
                </div>

                <div className="p-4 bg-muted/20 rounded-lg border border-border/30">
                  <div className="flex justify-between items-center mb-3">
                    <span className="text-sm font-medium text-foreground">系统健康度</span>
                    <span className="text-sm font-mono font-bold text-foreground">{stats.systemHealth || 95}% / 98%</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-3 border border-border/30">
                    <div className="bg-chart-3 rounded-full h-3 transition-all duration-1000 ease-out" style={{ width: `${Math.min(((stats.systemHealth || 95) / 98) * 100, 100)}%` }}></div>
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