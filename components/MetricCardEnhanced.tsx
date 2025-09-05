'use client'

import React from 'react'
import { TrendingUp, TrendingDown, Minus, Activity, Target, BarChart3, Info } from 'lucide-react'
import { cn } from '../lib/utils'

interface MetricCardEnhancedProps {
  title: string
  value: string | number
  change?: number
  changeLabel?: string
  description?: string
  sparklineData?: number[]
  target?: number
  icon?: React.ReactNode
  color?: 'default' | 'primary' | 'success' | 'warning' | 'danger'
  format?: 'number' | 'currency' | 'percentage'
  prefix?: string
  suffix?: string
  showTrend?: boolean
  showProgress?: boolean
  tooltipContent?: string
}

export function MetricCardEnhanced({
  title,
  value,
  change,
  changeLabel = '较上期',
  description,
  sparklineData,
  target,
  icon,
  color = 'default',
  format = 'number',
  prefix = '',
  suffix = '',
  showTrend = true,
  showProgress = true,
  tooltipContent
}: MetricCardEnhancedProps) {
  
  // 格式化数值显示
  const formatValue = () => {
    if (typeof value !== 'number') return value
    
    switch (format) {
      case 'currency':
        return `¥${value.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
      case 'percentage':
        return `${value.toFixed(1)}%`
      default:
        return `${prefix}${value.toLocaleString('zh-CN')}${suffix}`
    }
  }

  // 获取趋势图标
  const getTrendIcon = () => {
    if (change === undefined || change === 0) return <Minus className="w-4 h-4" />
    return change > 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />
  }

  // 格式化变化值
  const formatChange = () => {
    if (change === undefined) return null
    const sign = change > 0 ? '+' : ''
    return `${sign}${change.toFixed(1)}%`
  }

  // 获取颜色配置
  const getColorClasses = () => {
    const colorMap = {
      primary: {
        card: 'border-chart-1/20 bg-gradient-to-br from-chart-1/5 to-chart-1/10',
        icon: 'text-chart-1 bg-chart-1/10',
        progress: 'bg-chart-1'
      },
      success: {
        card: 'border-metric-positive/20 bg-gradient-to-br from-metric-positive/5 to-metric-positive/10',
        icon: 'text-metric-positive bg-metric-positive/10',
        progress: 'bg-metric-positive'
      },
      warning: {
        card: 'border-funnel-revenue/20 bg-gradient-to-br from-funnel-revenue/5 to-funnel-revenue/10',
        icon: 'text-funnel-revenue bg-funnel-revenue/10',
        progress: 'bg-funnel-revenue'
      },
      danger: {
        card: 'border-metric-negative/20 bg-gradient-to-br from-metric-negative/5 to-metric-negative/10',
        icon: 'text-metric-negative bg-metric-negative/10',
        progress: 'bg-metric-negative'
      },
      default: {
        card: 'border-gray-4 bg-white',
        icon: 'text-gray-7 bg-gray-3',
        progress: 'bg-gray-7'
      }
    }
    return colorMap[color]
  }

  const colorClasses = getColorClasses()

  // 增强版迷你折线图
  const EnhancedSparkline = ({ data }: { data: number[] }) => {
    if (!data || data.length === 0) return null
    
    const max = Math.max(...data)
    const min = Math.min(...data)
    const range = max - min || 1
    
    // 生成平滑曲线路径
    const points = data.map((value, index) => {
      const x = (index / (data.length - 1)) * 100
      const y = 85 - ((value - min) / range) * 70
      return { x, y }
    })
    
    // 创建平滑贝塞尔曲线
    const pathD = points.reduce((acc, point, index) => {
      if (index === 0) return `M ${point.x},${point.y}`
      const prev = points[index - 1]
      const cpX = (prev.x + point.x) / 2
      return `${acc} Q ${cpX},${prev.y} ${cpX},${point.y} T ${point.x},${point.y}`
    }, '')

    // 创建渐变区域路径
    const areaD = `${pathD} L 100,90 L 0,90 Z`

    return (
      <div className="flex items-end h-10 w-24">
        <svg viewBox="0 0 100 100" className="w-full h-full">
          <defs>
            <linearGradient id={`gradient-${title}`} x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="currentColor" stopOpacity="0.3" />
              <stop offset="100%" stopColor="currentColor" stopOpacity="0.05" />
            </linearGradient>
          </defs>
          <path
            d={areaD}
            fill={`url(#gradient-${title})`}
            className="text-chart-1"
          />
          <path
            d={pathD}
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-chart-1"
          />
          {/* 添加数据点 */}
          {points.map((point, index) => (
            <circle
              key={index}
              cx={point.x}
              cy={point.y}
              r="1.5"
              className="fill-chart-1"
            />
          ))}
        </svg>
      </div>
    )
  }

  // 增强版进度条
  const EnhancedProgressBar = () => {
    if (!showProgress || !target || typeof value !== 'number') return null
    
    const percentage = Math.min((value / target) * 100, 100)
    const isOnTrack = percentage >= 70
    const isWarning = percentage >= 40 && percentage < 70
    const isDanger = percentage < 40
    
    return (
      <div className="mt-4">
        <div className="flex items-center justify-between text-xs mb-2">
          <span className="text-gray-7 font-medium">目标完成度</span>
          <div className="flex items-center gap-2">
            <span className="text-gray-10 font-bold font-mono">{Math.round(percentage)}%</span>
            {target && (
              <span className="text-gray-6">({formatValue()} / {typeof target === 'number' ? target.toLocaleString() : target})</span>
            )}
          </div>
        </div>
        <div className="relative w-full bg-gray-3 rounded-full h-2 overflow-hidden">
          <div 
            className={cn(
              "absolute top-0 left-0 h-full rounded-full transition-all duration-1000 ease-out",
              isOnTrack && "bg-metric-positive",
              isWarning && "bg-funnel-revenue",
              isDanger && "bg-metric-negative"
            )}
            style={{ width: `${percentage}%` }}
          >
            {/* 添加动画光效 */}
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-pulse" />
          </div>
          {/* 目标刻度线 */}
          {[25, 50, 75].map(mark => (
            <div
              key={mark}
              className="absolute top-0 w-px h-full bg-gray-5"
              style={{ left: `${mark}%` }}
            />
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className={cn(
      "relative p-6 rounded-xl border transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5 group",
      colorClasses.card
    )}>
      {/* Tooltip */}
      {tooltipContent && (
        <div className="absolute top-2 right-2 z-10">
          <div className="group/tooltip relative">
            <Info className="w-4 h-4 text-gray-6 cursor-help" />
            <div className="absolute right-0 top-6 w-64 p-3 bg-gray-10 text-white text-xs rounded-lg shadow-xl opacity-0 invisible group-hover/tooltip:opacity-100 group-hover/tooltip:visible transition-all duration-200 z-20">
              <div className="absolute -top-1 right-2 w-2 h-2 bg-gray-10 rotate-45" />
              {tooltipContent}
            </div>
          </div>
        </div>
      )}

      {/* 头部区域 */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-start gap-3 flex-1">
          {/* 图标 */}
          {icon && (
            <div className={cn("p-2 rounded-lg transition-colors", colorClasses.icon)}>
              {icon}
            </div>
          )}
          
          {/* 标题和数值 */}
          <div className="flex-1">
            <h3 className="text-sm font-medium text-gray-7 mb-2">{title}</h3>
            <div className="flex items-baseline gap-2">
              <div className="text-3xl font-bold text-gray-11 tracking-tight font-mono">
                {formatValue()}
              </div>
              {/* 实时指示器 */}
              {color === 'primary' && (
                <div className="flex items-center gap-1">
                  <div className="w-2 h-2 bg-metric-positive rounded-full animate-pulse" />
                  <span className="text-xs text-gray-6">实时</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* 迷你图表 */}
        {sparklineData && (
          <div className="mt-2">
            <EnhancedSparkline data={sparklineData} />
          </div>
        )}
      </div>

      {/* 变化趋势 */}
      {showTrend && change !== undefined && (
        <div className="flex items-center gap-4 mb-3">
          <div className={cn(
            "flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold",
            change > 0 && "bg-metric-positive/10 text-metric-positive",
            change < 0 && "bg-metric-negative/10 text-metric-negative",
            change === 0 && "bg-gray-3 text-gray-7"
          )}>
            {getTrendIcon()}
            <span>{formatChange()}</span>
          </div>
          <span className="text-xs text-gray-6">{changeLabel}</span>
        </div>
      )}

      {/* 描述文本 */}
      {description && (
        <p className="text-sm text-gray-7 mb-3 leading-relaxed">{description}</p>
      )}

      {/* 进度条 */}
      <EnhancedProgressBar />

      {/* 悬浮效果背景 */}
      <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-transparent to-gray-2/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none" />
    </div>
  )
}