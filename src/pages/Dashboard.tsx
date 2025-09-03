import { useState } from 'react'
import { MetricCard } from '../components/MetricCard'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'
import {
  Users,
  Activity,
  Clock,
  DollarSign,
  RefreshCw,
  MousePointer,
  Target,
  AlertTriangle
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
  const [loading, setLoading] = useState(true)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)

  // 加载真实数据
  const loadDashboardData = async () => {
    try {
      setLoading(true)
      setError(null)

      const { data, error: apiError } = await dataService.getDashboardStats()

      if (apiError) {
        throw new Error((apiError as Error)?.message || '加载数据失败')
      }

      if (data) {
        setStats(data)
        setLastUpdated(new Date())
      }
    } catch (error) {
      console.error('加载Dashboard数据失败:', error)
      setError((error as Error)?.message || '加载数据失败')
    } finally {
      setLoading(false)
    }
  }

  // 设置15分钟自动刷新
  const { refresh } = useAutoRefresh(loadDashboardData, {
    interval: 15 * 60 * 1000, // 15分钟
    enabled: true,
    immediate: true
  })

  // 主要指标数据（使用真实数据）
  const overviewMetrics = [
    { title: "总用户数", value: stats.totalUsers, change: stats.totalUsers > 0 ? 100 : 0, changeLabel: "新增" },
    { title: "今日活跃", value: stats.activeUsers, change: stats.activeUsers > 0 ? 100 : 0, changeLabel: "24小时内" },
    { title: "今日收入", value: stats.totalRevenue > 0 ? `¥${stats.totalRevenue}` : "¥0", change: 0, changeLabel: "暂无数据" },
    { title: "转化率", value: `${Math.round(stats.conversionRate * 10) / 10}%`, change: stats.conversionRate > 0 ? stats.conversionRate : 0, changeLabel: "活跃率" },
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
        { label: "页面访问量", value: (stats.pageViews || 0).toString(), trend: (stats.pageViews || 0) > 0 ? "+100%" : "0%" },
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

  if (loading && !lastUpdated) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="grid-container">
      <div className="section-spacing">
        {/* 页面标题和状态 */}
        <div className="flex items-start justify-between animate-slide-up">
          <div className="content-spacing max-w-2xl">
            <h1 className="text-display-2 text-foreground">数据总览</h1>
            <div className="flex flex-col sm:flex-row sm:items-center gap-4">
              <p className="text-body text-muted-foreground">
                系统关键指标和实时数据监控
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

          {/* 手动刷新按钮 */}
          <button
            onClick={() => refresh()}
            disabled={loading}
            className="btn-secondary flex items-center space-x-2 min-w-[100px]"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>刷新</span>
          </button>
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

        {/* 主要指标卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 animate-fade-in">
          {overviewMetrics.map((metric, index) => (
            <div key={index} className="animate-scale-in" style={{ animationDelay: `${index * 100}ms` }}>
              <MetricCard {...metric} />
            </div>
          ))}
        </div>

        {/* 快速统计和实时活动 */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
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
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
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
