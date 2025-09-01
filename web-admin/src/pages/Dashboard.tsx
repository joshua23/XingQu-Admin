import React, { useEffect, useState } from 'react'
import {
  Users,
  Activity,
  TrendingUp,
  Eye,
  Clock,
  DollarSign,
  RefreshCw
} from 'lucide-react'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'

interface DashboardStats {
  totalUsers: number
  activeUsers: number
  totalSessions: number
  averageSessionTime: number
  totalRevenue: number
  conversionRate: number
}

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

  const MetricCard: React.FC<{
    title: string
    value: string | number
    change?: string
    icon: React.ReactNode
    color: string
  }> = ({ title, value, change, icon, color }) => (
    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-400 text-sm font-medium">{title}</p>
          <p className="text-2xl font-bold text-white mt-1">
            {typeof value === 'number' && title.includes('收入')
              ? `¥${value.toLocaleString()}`
              : value.toLocaleString()
            }
          </p>
          {change && (
            <p className={`text-sm mt-1 ${change.startsWith('+') ? 'text-green-400' : 'text-red-400'}`}>
              {change}
            </p>
          )}
        </div>
        <div className={`p-3 rounded-lg ${color}`}>
          {icon}
        </div>
      </div>
    </div>
  )

  if (loading && !lastUpdated) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和状态 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">数据总览</h1>
          <div className="flex items-center space-x-4 mt-1">
            <p className="text-gray-400">星趣App核心运营指标监控</p>
            {lastUpdated && (
              <div className="flex items-center text-sm text-gray-500">
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
          className="flex items-center space-x-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:cursor-not-allowed text-white rounded-lg transition-colors"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          <span>刷新</span>
        </button>
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

      {/* 指标卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <MetricCard
          title="总用户数"
          value={stats.totalUsers}
          change="+12.5%"
          icon={<Users size={24} className="text-white" />}
          color="bg-blue-500"
        />
        <MetricCard
          title="活跃用户"
          value={stats.activeUsers}
          change="+8.2%"
          icon={<Activity size={24} className="text-white" />}
          color="bg-green-500"
        />
        <MetricCard
          title="会话总数"
          value={stats.totalSessions}
          change="+15.3%"
          icon={<Eye size={24} className="text-white" />}
          color="bg-purple-500"
        />
        <MetricCard
          title="平均会话时长"
          value={`${stats.averageSessionTime}分钟`}
          change="+5.1%"
          icon={<Clock size={24} className="text-white" />}
          color="bg-orange-500"
        />
        <MetricCard
          title="总收入"
          value={stats.totalRevenue}
          change="+22.1%"
          icon={<DollarSign size={24} className="text-white" />}
          color="bg-emerald-500"
        />
        <MetricCard
          title="转化率"
          value={`${Math.round(stats.conversionRate * 10) / 10}%`}
          change="+2.1%"
          icon={<TrendingUp size={24} className="text-white" />}
          color="bg-pink-500"
        />
      </div>

      {/* 图表区域 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 用户增长趋势 */}
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <h3 className="text-lg font-semibold text-white mb-4">用户增长趋势</h3>
          <div className="h-64 flex items-center justify-center">
            <div className="text-gray-400 text-center">
              <TrendingUp size={48} className="mx-auto mb-2" />
              <p>图表组件开发中...</p>
            </div>
          </div>
        </div>

        {/* 实时活跃用户 */}
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <h3 className="text-lg font-semibold text-white mb-4">实时活跃用户</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                <span className="text-gray-300">当前在线</span>
              </div>
              <span className="text-white font-semibold">{stats.activeUsers}</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                <span className="text-gray-300">今日活跃</span>
              </div>
              <span className="text-white font-semibold">15,240</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <span className="text-gray-300">本周活跃</span>
              </div>
              <span className="text-white font-semibold">67,890</span>
            </div>
          </div>
        </div>
      </div>

      {/* 最新活动 */}
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h3 className="text-lg font-semibold text-white mb-4">最新活动</h3>
        <div className="space-y-3">
          <div className="flex items-center space-x-3 p-3 bg-gray-700 rounded-lg">
            <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
            <div className="flex-1">
              <p className="text-white text-sm">新用户注册</p>
              <p className="text-gray-400 text-xs">用户ID: 123456 刚刚注册</p>
            </div>
            <span className="text-gray-400 text-xs">2分钟前</span>
          </div>
          <div className="flex items-center space-x-3 p-3 bg-gray-700 rounded-lg">
            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
            <div className="flex-1">
              <p className="text-white text-sm">支付成功</p>
              <p className="text-gray-400 text-xs">订单金额: ¥99.00</p>
            </div>
            <span className="text-gray-400 text-xs">5分钟前</span>
          </div>
          <div className="flex items-center space-x-3 p-3 bg-gray-700 rounded-lg">
            <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
            <div className="flex-1">
              <p className="text-white text-sm">内容审核</p>
              <p className="text-gray-400 text-xs">新内容等待审核</p>
            </div>
            <span className="text-gray-400 text-xs">8分钟前</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Dashboard
