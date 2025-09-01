import React, { useEffect, useState } from 'react'
import { MetricCard } from '../components/MetricCard'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'
import {
  Users,
  Activity,
  TrendingUp,
  Eye,
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

// 快速统计数据
const quickStats = [
  {
    icon: Users,
    title: "用户概况",
    stats: [
      { label: "新用户注册", value: "1,234", trend: "+12%" },
      { label: "活跃用户", value: "8,650", trend: "+8%" },
      { label: "会员用户", value: "12,847", trend: "+16%" },
    ]
  },
  {
    icon: MousePointer,
    title: "用户行为",
    stats: [
      { label: "页面访问量", value: "234,567", trend: "+15%" },
      { label: "平均停留时长", value: "3分42秒", trend: "+9%" },
      { label: "跳出率", value: "32.5%", trend: "-5%" },
    ]
  },
  {
    icon: DollarSign,
    title: "财务数据",
    stats: [
      { label: "今日收入", value: "¥45,280", trend: "+13%" },
      { label: "广告投放", value: "¥32,150", trend: "-8%" },
      { label: "净利润", value: "¥10,790", trend: "+22%" },
    ]
  },
]

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    activeUsers: 0,
    totalSessions: 0,
    averageSessionTime: 0,
    totalRevenue: 0,
    conversionRate: 0
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
        throw new Error(apiError.message || '加载数据失败')
      }

      if (data) {
        setStats(data)
        setLastUpdated(new Date())
      }
    } catch (error) {
      console.error('加载Dashboard数据失败:', error)
      setError(error instanceof Error ? error.message : '加载数据失败')
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

  // 主要指标数据
  const overviewMetrics = [
    { title: "总用户数", value: stats.totalUsers || 128540, change: 12.5, changeLabel: "较上月" },
    { title: "今日活跃", value: stats.activeUsers || 8650, change: 8.2, changeLabel: "较昨日" },
    { title: "今日收入", value: stats.totalRevenue ? `¥${stats.totalRevenue}` : "¥45,280", change: 15.6, changeLabel: "较昨日" },
    { title: "转化率", value: `${Math.round((stats.conversionRate || 0.032) * 1000) / 10}%`, change: -2.1, changeLabel: "较昨日" },
  ]

  if (loading && !lastUpdated) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和状态 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">数据总览</h1>
          <div className="flex items-center space-x-4 mt-1">
            <p className="text-muted-foreground">系统关键指标和实时数据监控</p>
            {lastUpdated && (
              <div className="flex items-center text-sm text-muted-foreground">
                <Clock size={14} className="mr-1" />
                最后更新: {lastUpdated.toLocaleTimeString()}
              </div>
            )}
          </div>
        </div>

        {/* 手动刷新按钮 */}
        <button
          onClick={() => refresh()}
          disabled={loading}
          className="flex items-center space-x-2 px-4 py-2 bg-secondary hover:bg-secondary/80 disabled:bg-secondary/50 disabled:cursor-not-allowed text-secondary-foreground rounded-lg transition-colors"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          <span>刷新</span>
        </button>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertTriangle size={16} className="text-destructive" />
            <p className="text-destructive font-medium">数据加载失败</p>
          </div>
          <p className="text-destructive/80 text-sm mt-1">{error}</p>
        </div>
      )}

      {/* 主要指标卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {overviewMetrics.map((metric, index) => (
          <MetricCard key={index} {...metric} />
        ))}
      </div>

      {/* 快速统计和实时活动 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {quickStats.map((section, index) => {
          const Icon = section.icon;
          return (
            <Card key={index}>
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Icon className="w-5 h-5 text-primary" />
                  <CardTitle className="text-base">{section.title}</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                {section.stats.map((stat, statIndex) => (
                  <div key={statIndex} className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">{stat.label}</span>
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-sm font-medium">{stat.value}</span>
                      <Badge
                        variant="secondary"
                        className={`text-xs ${
                          stat.trend.startsWith('+')
                            ? 'text-metric-positive'
                            : stat.trend.startsWith('-')
                              ? 'text-metric-negative'
                              : 'text-metric-neutral'
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
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Activity className="w-4 h-4" />
              实时活动
            </CardTitle>
            <CardDescription>系统最新动态和异常提醒</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentActivities.map((activity, index) => (
                <div key={index} className="flex gap-3">
                  <div className="text-xs text-muted-foreground font-mono w-12 flex-shrink-0 mt-1">
                    {activity.time}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h4 className="text-sm font-medium">{activity.action}</h4>
                      <Badge
                        variant="outline"
                        className={`text-xs ${
                          activity.type === 'warning'
                            ? 'border-warning text-warning'
                            : activity.type === 'success'
                              ? 'border-success text-success'
                              : 'border-primary text-primary'
                        }`}
                      >
                        {activity.type === 'warning' ? '警告' : activity.type === 'success' ? '正常' : '信息'}
                      </Badge>
                    </div>
                    <p className="text-xs text-muted-foreground">{activity.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Target className="w-4 h-4" />
              今日目标
            </CardTitle>
            <CardDescription>关键指标完成情况</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm">收入目标</span>
                  <span className="text-sm font-mono">¥45,280 / ¥50,000</span>
                </div>
                <div className="w-full bg-muted rounded-full h-2">
                  <div className="bg-primary rounded-full h-2" style={{ width: '90.6%' }}></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm">新用户注册</span>
                  <span className="text-sm font-mono">1,234 / 1,000</span>
                </div>
                <div className="w-full bg-muted rounded-full h-2">
                  <div className="bg-success rounded-full h-2" style={{ width: '100%' }}></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm">活跃用户</span>
                  <span className="text-sm font-mono">{stats.activeUsers || 8650} / 10,000</span>
                </div>
                <div className="w-full bg-muted rounded-full h-2">
                  <div className="bg-chart-3 rounded-full h-2" style={{ width: `${Math.min(((stats.activeUsers || 8650) / 10000) * 100, 100)}%` }}></div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default Dashboard
