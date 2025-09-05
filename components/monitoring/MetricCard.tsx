/**
 * 星趣后台管理系统 - 监控指标卡片组件
 * 显示单个监控指标的数据和状态
 * Created: 2025-09-05
 */

'use client'

import React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/Badge'
import { 
  TrendingUp, 
  TrendingDown, 
  Minus,
  Activity,
  Zap,
  Clock,
  Database
} from 'lucide-react'
import type { MetricCardProps } from '@/lib/types/admin'

export default function MetricCard({
  title,
  value,
  change,
  changeLabel,
  icon,
  color = 'default',
  sparklineData,
  target,
  description,
  loading = false
}: MetricCardProps) {
  
  // 获取颜色主题
  const getColorClasses = (color: string) => {
    switch (color) {
      case 'primary':
        return {
          card: 'border-blue-200 bg-blue-50',
          text: 'text-blue-900',
          badge: 'bg-blue-100 text-blue-800',
          icon: 'text-blue-600'
        }
      case 'success':
        return {
          card: 'border-green-200 bg-green-50',
          text: 'text-green-900',
          badge: 'bg-green-100 text-green-800',
          icon: 'text-green-600'
        }
      case 'warning':
        return {
          card: 'border-yellow-200 bg-yellow-50',
          text: 'text-yellow-900',
          badge: 'bg-yellow-100 text-yellow-800',
          icon: 'text-yellow-600'
        }
      default:
        return {
          card: 'border-gray-200 bg-white',
          text: 'text-gray-900',
          badge: 'bg-gray-100 text-gray-800',
          icon: 'text-gray-600'
        }
    }
  }

  const colorClasses = getColorClasses(color)

  // 获取趋势图标
  const getTrendIcon = () => {
    if (!change) return null
    
    if (change > 0) {
      return <TrendingUp className="h-4 w-4 text-green-500" />
    } else if (change < 0) {
      return <TrendingDown className="h-4 w-4 text-red-500" />
    } else {
      return <Minus className="h-4 w-4 text-gray-400" />
    }
  }

  // 获取默认图标
  const getDefaultIcon = () => {
    if (icon) return icon
    
    if (title.includes('响应时间') || title.includes('延迟')) {
      return <Clock className={`h-5 w-5 ${colorClasses.icon}`} />
    } else if (title.includes('数据库') || title.includes('存储')) {
      return <Database className={`h-5 w-5 ${colorClasses.icon}`} />
    } else if (title.includes('性能') || title.includes('速度')) {
      return <Zap className={`h-5 w-5 ${colorClasses.icon}`} />
    } else {
      return <Activity className={`h-5 w-5 ${colorClasses.icon}`} />
    }
  }

  // 渲染迷你趋势图
  const renderSparkline = () => {
    if (!sparklineData || sparklineData.length < 2) return null

    const max = Math.max(...sparklineData)
    const min = Math.min(...sparklineData)
    const range = max - min

    if (range === 0) return null

    const points = sparklineData.map((value, index) => {
      const x = (index / (sparklineData.length - 1)) * 60
      const y = 20 - ((value - min) / range) * 20
      return `${x},${y}`
    }).join(' ')

    return (
      <div className="mt-2">
        <svg width="60" height="20" className="opacity-60">
          <polyline
            points={points}
            fill="none"
            stroke="currentColor"
            strokeWidth="1"
            className={colorClasses.icon}
          />
        </svg>
      </div>
    )
  }

  // 渲染进度条（如果有目标值）
  const renderProgress = () => {
    if (!target || typeof value !== 'number') return null

    const progress = Math.min((value / target) * 100, 100)
    const isOverTarget = value > target

    return (
      <div className="mt-2">
        <div className="flex justify-between text-xs text-muted-foreground mb-1">
          <span>进度</span>
          <span>{Math.round(progress)}%</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-1.5">
          <div
            className={`h-1.5 rounded-full transition-all duration-300 ${
              isOverTarget ? 'bg-red-500' : progress >= 80 ? 'bg-green-500' : 'bg-blue-500'
            }`}
            style={{ width: `${Math.min(progress, 100)}%` }}
          />
        </div>
        <div className="text-xs text-muted-foreground mt-1">
          目标: {target}
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <Card className="animate-pulse">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <div className="h-4 bg-gray-200 rounded w-3/4"></div>
          <div className="h-5 w-5 bg-gray-200 rounded"></div>
        </CardHeader>
        <CardContent>
          <div className="h-8 bg-gray-200 rounded w-1/2 mb-2"></div>
          <div className="h-3 bg-gray-200 rounded w-full"></div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className={`transition-all duration-200 hover:shadow-md ${colorClasses.card}`}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className={`text-sm font-medium ${colorClasses.text}`}>
          {title}
        </CardTitle>
        <div className="flex items-center gap-2">
          {getDefaultIcon()}
          {change !== undefined && (
            <Badge variant="outline" className={`text-xs ${colorClasses.badge}`}>
              <div className="flex items-center gap-1">
                {getTrendIcon()}
                {Math.abs(change)}{changeLabel && ` ${changeLabel}`}
              </div>
            </Badge>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className={`text-2xl font-bold ${colorClasses.text}`}>
          {typeof value === 'number' ? value.toLocaleString() : value}
        </div>
        
        {description && (
          <p className="text-xs text-muted-foreground mt-1 line-clamp-2">
            {description}
          </p>
        )}

        {renderSparkline()}
        {renderProgress()}

        {/* 变化说明 */}
        {change !== undefined && changeLabel && (
          <div className="flex items-center gap-1 mt-2 text-xs text-muted-foreground">
            {getTrendIcon()}
            <span>
              {change > 0 ? '+' : ''}{change}% {changeLabel}
            </span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

// 预设的指标卡片组件
export const CPUUsageCard = ({ value, change, loading }: { value: number; change?: number; loading?: boolean }) => (
  <MetricCard
    title="CPU 使用率"
    value={`${value}%`}
    change={change}
    changeLabel="较昨日"
    color={value > 80 ? 'warning' : value > 90 ? 'warning' : 'success'}
    target={80}
    description="系统CPU使用率监控"
    loading={loading}
    icon={<Activity className="h-5 w-5" />}
  />
)

export const MemoryUsageCard = ({ value, change, loading }: { value: number; change?: number; loading?: boolean }) => (
  <MetricCard
    title="内存使用率"
    value={`${value}%`}
    change={change}
    changeLabel="较昨日"
    color={value > 85 ? 'warning' : 'success'}
    target={85}
    description="系统内存使用率监控"
    loading={loading}
    icon={<Database className="h-5 w-5" />}
  />
)

export const ResponseTimeCard = ({ value, change, loading }: { value: number; change?: number; loading?: boolean }) => (
  <MetricCard
    title="API响应时间"
    value={`${value}ms`}
    change={change}
    changeLabel="较昨日"
    color={value > 1000 ? 'warning' : 'primary'}
    target={500}
    description="平均API响应时间"
    loading={loading}
    icon={<Zap className="h-5 w-5" />}
  />
)

export const ActiveUsersCard = ({ value, change, sparklineData, loading }: { 
  value: number; 
  change?: number; 
  sparklineData?: number[];
  loading?: boolean 
}) => (
  <MetricCard
    title="在线用户数"
    value={value}
    change={change}
    changeLabel="较昨日"
    color="primary"
    sparklineData={sparklineData}
    description="当前在线用户数量"
    loading={loading}
    icon={<Activity className="h-5 w-5" />}
  />
)