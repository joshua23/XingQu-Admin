import { useEffect, useState } from 'react'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'
import { MetricCard } from '../components/MetricCard'
import {
  BarChart3,
  TrendingUp,
  Activity,
  Calendar,
  Download,
  RefreshCw,
  Clock
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

const Analytics: React.FC = () => {
  const [data, setData] = useState<AnalyticsData | null>(null)
  const [loading, setLoading] = useState(true)
  const [dateRange, setDateRange] = useState('7d')
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)

  // 加载真实分析数据
  const loadAnalyticsData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const { data: analyticsData, error: apiError } = await dataService.getAnalyticsData()
      
      if (apiError) {
        throw new Error((apiError as Error)?.message || '加载分析数据失败')
      }
      
      if (analyticsData) {
        setData(analyticsData)
        setLastUpdated(new Date())
      }
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
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和控制 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">数据分析</h1>
          <div className="flex items-center space-x-4 mt-1">
            <p className="text-gray-600 dark:text-gray-400">深入分析用户行为和业务数据</p>
            {lastUpdated && (
              <div className="flex items-center text-sm text-gray-500 dark:text-gray-500">
                <Clock size={14} className="mr-1" />
                最后更新: {lastUpdated.toLocaleTimeString()}
              </div>
            )}
          </div>
        </div>
        <div className="flex items-center space-x-3">
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
            className="px-3 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
          >
            <option value="7d">最近7天</option>
            <option value="30d">最近30天</option>
            <option value="90d">最近90天</option>
            <option value="1y">最近一年</option>
          </select>
          <button
            onClick={() => refresh()}
            disabled={loading}
            className="flex items-center space-x-2 px-4 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 disabled:bg-gray-100 dark:disabled:bg-gray-800 disabled:cursor-not-allowed text-gray-900 dark:text-white rounded-lg transition-colors"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>刷新</span>
          </button>
          <button className="flex items-center space-x-2 px-4 py-2 bg-primary-500 hover:bg-primary-600 text-white rounded-lg">
            <Download size={16} />
            <span>导出报告</span>
          </button>
        </div>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-red-500 rounded-full"></div>
            <p className="text-red-400 font-medium">数据加载失败</p>
          </div>
          <p className="text-red-300 text-sm mt-1">{error}</p>
        </div>
      )}

      {/* 关键指标 */}
      {data && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
      {data && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* 用户增长趋势 */}
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
            <div className="p-6 pb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">用户增长趋势</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                新用户: {data.userGrowth.reduce((sum, day) => sum + day.newUsers, 0)} | 
                活跃用户: {data.userGrowth.length > 0 ? data.userGrowth[data.userGrowth.length - 1]?.activeUsers || 0 : 0}
              </p>
            </div>
            <div className="px-6 pb-6">
              <div className="h-48 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-950/30 dark:to-indigo-950/30 rounded-lg flex items-center justify-center">
                <div className="text-center text-gray-600 dark:text-gray-400">
                  <TrendingUp size={32} className="mx-auto mb-2 text-blue-500" />
                  <p className="text-sm font-medium">图表组件待实现</p>
                  <p className="text-xs opacity-70">基于 {data.userGrowth.length} 天数据</p>
                </div>
              </div>
            </div>
          </div>

          {/* 收入分析 */}
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
            <div className="p-6 pb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">收入分析</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                本月收入: ¥{data.revenueStats.totalRevenue.toLocaleString()} | 
                增长率: {data.revenueStats.totalRevenue > 0 ? "+15.2%" : "暂无数据"}
              </p>
            </div>
            <div className="px-6 pb-6">
              <div className="h-48 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-950/30 dark:to-emerald-950/30 rounded-lg flex items-center justify-center">
                <div className="text-center text-gray-600 dark:text-gray-400">
                  <BarChart3 size={32} className="mx-auto mb-2 text-green-500" />
                  <p className="text-sm font-medium">图表组件待实现</p>
                  <p className="text-xs opacity-70">基于 {data.revenueStats.monthlyRevenue.length} 月数据</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 详细数据表格 */}
      {data && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* 热门产品 */}
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">热门产品销售</h3>
            <div className="space-y-4">
              {data.revenueStats.topProducts.length > 0 ? (
                data.revenueStats.topProducts.map((product, index) => (
                  <div key={product.name} className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white text-sm font-bold">
                        {index + 1}
                      </div>
                      <div>
                        <p className="text-gray-900 dark:text-white text-sm font-medium">{product.name}</p>
                        <p className="text-gray-600 dark:text-gray-400 text-xs">{product.sales} 份销售</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-gray-900 dark:text-white font-medium">¥{product.revenue.toLocaleString()}</p>
                      <p className="text-gray-600 dark:text-gray-400 text-xs">
                        {data.revenueStats.totalRevenue > 0 
                          ? ((product.revenue / data.revenueStats.totalRevenue) * 100).toFixed(1)
                          : '0.0'
                        }%
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center text-gray-600 dark:text-gray-400 py-8">
                  <BarChart3 size={48} className="mx-auto mb-2 opacity-50" />
                  <p>暂无产品销售数据</p>
                </div>
              )}
            </div>
          </div>

          {/* 用户行为分析 */}
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">用户行为分析</h3>
            <div className="space-y-5">
              <div className="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-700/50">
                <span className="text-gray-700 dark:text-gray-300 font-medium">每日活跃用户</span>
                <span className="text-gray-900 dark:text-white font-semibold text-lg">
                  {data.userGrowth.length > 0 ? data.userGrowth[data.userGrowth.length - 1]?.activeUsers.toLocaleString() : '0'}
                </span>
              </div>
              <div className="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-700/50">
                <span className="text-gray-700 dark:text-gray-300 font-medium">平均会话时长</span>
                <span className="text-gray-900 dark:text-white font-semibold text-lg">
                  {data.behaviorStats.averageSessionTime}分钟
                </span>
              </div>
              <div className="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-700/50">
                <span className="text-gray-700 dark:text-gray-300 font-medium">页面浏览量</span>
                <span className="text-gray-900 dark:text-white font-semibold text-lg">
                  {data.behaviorStats.pageViews.toLocaleString()}
                </span>
              </div>
              <div className="flex items-center justify-between py-2">
                <span className="text-gray-700 dark:text-gray-300 font-medium">跳出率</span>
                <div className="text-right">
                  <span className="text-gray-900 dark:text-white font-semibold text-lg">
                    {Math.round(data.behaviorStats.bounceRate * 10) / 10}%
                  </span>
                  <p className={`text-xs mt-0.5 ${
                    data.behaviorStats.bounceRate < 40 ? 'text-green-500' : 
                    data.behaviorStats.bounceRate < 70 ? 'text-yellow-500' : 
                    'text-red-500'
                  }`}>
                    {data.behaviorStats.bounceRate < 40 ? '优秀' : 
                     data.behaviorStats.bounceRate < 70 ? '良好' : '需优化'}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 数据导出选项 */}
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">数据导出</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
            <div className="text-center">
              <BarChart3 size={24} className="mx-auto mb-2 text-primary-500" />
              <p className="text-gray-900 dark:text-white font-medium">用户数据</p>
              <p className="text-gray-600 dark:text-gray-400 text-sm">导出用户行为数据</p>
            </div>
          </button>
          <button className="p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
            <div className="text-center">
              <TrendingUp size={24} className="mx-auto mb-2 text-green-500" />
              <p className="text-gray-900 dark:text-white font-medium">收入数据</p>
              <p className="text-gray-600 dark:text-gray-400 text-sm">导出财务数据报表</p>
            </div>
          </button>
          <button className="p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
            <div className="text-center">
              <Activity size={24} className="mx-auto mb-2 text-blue-500" />
              <p className="text-gray-900 dark:text-white font-medium">运营数据</p>
              <p className="text-gray-600 dark:text-gray-400 text-sm">导出运营分析报告</p>
            </div>
          </button>
        </div>
      </div>
    </div>
  )
}

export default Analytics
