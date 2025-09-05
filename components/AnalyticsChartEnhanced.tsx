'use client'

import React, { useState, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/Card'
import { Badge } from './ui/Badge'
import { cn } from '../lib/utils'
import { 
  TrendingUp, 
  TrendingDown, 
  BarChart3, 
  LineChart,
  PieChart,
  Activity,
  Calendar,
  Download,
  Filter,
  MoreVertical
} from 'lucide-react'

interface ChartDataPoint {
  label: string
  value: number
  trend?: 'up' | 'down' | 'neutral'
  category?: string
  percentage?: number
}

interface AnalyticsChartEnhancedProps {
  title: string
  description?: string
  data: ChartDataPoint[]
  type?: 'bar' | 'line' | 'area' | 'funnel' | 'donut'
  color?: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'aarrr'
  showTrend?: boolean
  showLegend?: boolean
  showGrid?: boolean
  height?: number
  dateRange?: string
  onExport?: () => void
  onFilter?: () => void
}

export const AnalyticsChartEnhanced: React.FC<AnalyticsChartEnhancedProps> = ({
  title,
  description,
  data,
  type = 'bar',
  color = 'default',
  showTrend = true,
  showLegend = false,
  showGrid = true,
  height = 300,
  dateRange = '最近7天',
  onExport,
  onFilter
}) => {
  const [selectedPeriod, setSelectedPeriod] = useState(dateRange)
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null)
  
  // 计算统计数据
  const stats = useMemo(() => {
    const total = data.reduce((sum, point) => sum + point.value, 0)
    const average = Math.round(total / data.length)
    const max = Math.max(...data.map(d => d.value))
    const min = Math.min(...data.map(d => d.value))
    
    // 计算环比
    const lastValue = data[data.length - 1]?.value || 0
    const previousValue = data[data.length - 2]?.value || lastValue
    const changePercent = previousValue !== 0 
      ? ((lastValue - previousValue) / previousValue * 100).toFixed(1) 
      : '0'
    
    return { total, average, max, min, changePercent }
  }, [data])

  // 获取图表颜色配置
  const getColorScheme = () => {
    const schemes = {
      default: ['#1890FF', '#52C41A', '#FAAD14', '#F5222D'],
      primary: ['#1890FF', '#40A9FF', '#69C0FF', '#91D5FF'],
      success: ['#52C41A', '#73D13D', '#95DE64', '#B7EB8F'],
      warning: ['#FAAD14', '#FFBB33', '#FFC53D', '#FFD666'],
      danger: ['#F5222D', '#FF4D4F', '#FF7875', '#FFA39E'],
      aarrr: ['#1890FF', '#13C2C2', '#52C41A', '#FAAD14', '#722ED1']
    }
    return schemes[color] || schemes.default
  }

  const colors = getColorScheme()

  // 增强版柱状图
  const EnhancedBarChart = () => {
    const maxValue = stats.max
    const minValue = stats.min
    const range = maxValue - minValue || 1

    return (
      <div className="relative" style={{ height: `${height}px` }}>
        {/* 网格背景 */}
        {showGrid && (
          <div className="absolute inset-0 flex flex-col justify-between pointer-events-none">
            {[0, 1, 2, 3, 4].map(i => (
              <div key={i} className="border-t border-gray-3" />
            ))}
          </div>
        )}
        
        {/* Y轴标签 */}
        <div className="absolute left-0 inset-y-0 flex flex-col justify-between text-xs text-gray-6 w-12">
          {[maxValue, maxValue * 0.75, maxValue * 0.5, maxValue * 0.25, 0].map((val, i) => (
            <span key={i} className="font-mono">
              {val >= 1000 ? `${(val / 1000).toFixed(1)}K` : Math.round(val)}
            </span>
          ))}
        </div>

        {/* 图表主体 */}
        <div className="flex items-end justify-between h-full pl-14 pr-2 pb-8">
          {data.map((point, index) => {
            const heightPercent = ((point.value - minValue) / range) * 85 + 5
            const isHovered = hoveredIndex === index
            
            return (
              <div 
                key={index} 
                className="relative flex-1 mx-1 group"
                onMouseEnter={() => setHoveredIndex(index)}
                onMouseLeave={() => setHoveredIndex(null)}
              >
                {/* 柱体 */}
                <div 
                  className="relative w-full rounded-t-md transition-all duration-300"
                  style={{
                    height: `${heightPercent}%`,
                    backgroundColor: colors[index % colors.length],
                    opacity: hoveredIndex === null || isHovered ? 1 : 0.5,
                    transform: isHovered ? 'scaleY(1.02)' : 'scaleY(1)'
                  }}
                >
                  {/* 渐变效果 */}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/10 to-transparent rounded-t-md" />
                  
                  {/* 悬浮数值提示 */}
                  {isHovered && (
                    <div className="absolute -top-10 left-1/2 -translate-x-1/2 z-10">
                      <div className="bg-gray-10 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg whitespace-nowrap">
                        {point.value.toLocaleString()}
                        {point.percentage && (
                          <span className="ml-2 text-gray-3">({point.percentage}%)</span>
                        )}
                      </div>
                      <div className="w-0 h-0 border-l-4 border-l-transparent border-r-4 border-r-transparent border-t-4 border-t-gray-10 mx-auto" />
                    </div>
                  )}
                </div>

                {/* X轴标签 */}
                <div className="absolute -bottom-6 left-0 right-0 text-center">
                  <span className="text-xs text-gray-7 font-medium">
                    {point.label}
                  </span>
                  {showTrend && point.trend && (
                    <div className="flex justify-center mt-1">
                      {point.trend === 'up' ? 
                        <TrendingUp className="w-3 h-3 text-metric-positive" /> :
                        point.trend === 'down' ? 
                        <TrendingDown className="w-3 h-3 text-metric-negative" /> :
                        null
                      }
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  // 增强版折线/面积图
  const EnhancedLineChart = () => {
    const maxValue = stats.max
    const minValue = stats.min
    const range = maxValue - minValue || 1
    
    // 计算SVG路径点
    const points = data.map((point, index) => {
      const x = (index / Math.max(data.length - 1, 1)) * 100
      const y = 85 - ((point.value - minValue) / range) * 75
      return { x, y, value: point.value }
    })
    
    // 创建平滑贝塞尔曲线路径
    const linePath = points.reduce((acc, point, index) => {
      if (index === 0) return `M ${point.x},${point.y}`
      const prev = points[index - 1]
      const cpX = (prev.x + point.x) / 2
      return `${acc} C ${cpX},${prev.y} ${cpX},${point.y} ${point.x},${point.y}`
    }, '')
    
    const areaPath = type === 'area' ? `${linePath} L 100,90 L 0,90 Z` : ''

    return (
      <div className="relative" style={{ height: `${height}px` }}>
        {/* 网格背景 */}
        {showGrid && (
          <div className="absolute inset-0 flex flex-col justify-between pointer-events-none">
            {[0, 1, 2, 3, 4].map(i => (
              <div key={i} className="border-t border-gray-3" />
            ))}
          </div>
        )}

        {/* SVG图表 */}
        <svg viewBox="0 0 100 100" className="w-full h-full" preserveAspectRatio="none">
          <defs>
            <linearGradient id={`gradient-${title}`} x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor={colors[0]} stopOpacity="0.3" />
              <stop offset="100%" stopColor={colors[0]} stopOpacity="0.05" />
            </linearGradient>
          </defs>
          
          {/* 面积图渐变填充 */}
          {type === 'area' && (
            <path
              d={areaPath}
              fill={`url(#gradient-${title})`}
            />
          )}
          
          {/* 折线 */}
          <path
            d={linePath}
            fill="none"
            stroke={colors[0]}
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="drop-shadow-sm"
          />
          
          {/* 数据点 */}
          {points.map((point, index) => (
            <g key={index}>
              <circle
                cx={point.x}
                cy={point.y}
                r="3"
                fill="white"
                stroke={colors[0]}
                strokeWidth="2"
                className="drop-shadow-sm"
              />
              {/* 悬浮激活圈 */}
              <circle
                cx={point.x}
                cy={point.y}
                r="8"
                fill={colors[0]}
                fillOpacity="0"
                className="hover:fill-opacity-20 transition-all cursor-pointer"
                onMouseEnter={() => setHoveredIndex(index)}
                onMouseLeave={() => setHoveredIndex(null)}
              />
              {/* 数值标签 */}
              {hoveredIndex === index && (
                <g>
                  <rect
                    x={point.x - 20}
                    y={point.y - 25}
                    width="40"
                    height="20"
                    rx="3"
                    fill="#262626"
                    fillOpacity="0.9"
                  />
                  <text
                    x={point.x}
                    y={point.y - 12}
                    textAnchor="middle"
                    className="text-[10px] fill-white font-bold"
                  >
                    {point.value.toLocaleString()}
                  </text>
                </g>
              )}
            </g>
          ))}
        </svg>

        {/* X轴标签 */}
        <div className="absolute bottom-0 left-0 right-0 flex justify-between px-2">
          {data.map((point, index) => (
            <div key={index} className="text-xs text-gray-7 text-center">
              {point.label}
            </div>
          ))}
        </div>
      </div>
    )
  }

  // AARRR漏斗图
  const FunnelChart = () => {
    if (color !== 'aarrr') return <EnhancedBarChart />
    
    const funnelColors = {
      'Acquisition': '#1890FF',
      'Activation': '#13C2C2',
      'Retention': '#52C41A',
      'Revenue': '#FAAD14',
      'Referral': '#722ED1'
    }

    return (
      <div className="space-y-3">
        {data.map((stage, index) => {
          const widthPercent = (stage.value / data[0].value) * 100
          const conversionRate = index > 0 
            ? ((stage.value / data[index - 1].value) * 100).toFixed(1)
            : '100'
          
          return (
            <div key={index} className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="font-medium text-gray-9">{stage.label}</span>
                <div className="flex items-center gap-3">
                  <span className="font-mono font-bold text-gray-10">
                    {stage.value.toLocaleString()}
                  </span>
                  {index > 0 && (
                    <Badge variant="outline" className="text-xs">
                      转化率 {conversionRate}%
                    </Badge>
                  )}
                </div>
              </div>
              <div className="relative">
                <div className="w-full bg-gray-3 rounded-full h-8">
                  <div
                    className="h-8 rounded-full flex items-center justify-end px-3 transition-all duration-1000"
                    style={{
                      width: `${widthPercent}%`,
                      backgroundColor: funnelColors[stage.label as keyof typeof funnelColors] || colors[index]
                    }}
                  >
                    <span className="text-xs text-white font-bold">
                      {widthPercent.toFixed(1)}%
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )
        })}
      </div>
    )
  }

  return (
    <Card className="transition-all duration-200 hover:shadow-lg">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="space-y-1">
            <CardTitle className="text-lg font-bold text-gray-10">{title}</CardTitle>
            {description && (
              <CardDescription className="text-sm text-gray-7">{description}</CardDescription>
            )}
          </div>
          
          {/* 操作按钮 */}
          <div className="flex items-center gap-2">
            <select
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="px-3 py-1.5 text-xs border border-gray-4 rounded-md bg-white hover:bg-gray-2 transition-colors"
            >
              <option value="24h">24小时</option>
              <option value="7d">最近7天</option>
              <option value="30d">最近30天</option>
              <option value="90d">最近90天</option>
            </select>
            
            {onFilter && (
              <button
                onClick={onFilter}
                className="p-1.5 hover:bg-gray-2 rounded-md transition-colors"
                title="筛选"
              >
                <Filter className="w-4 h-4 text-gray-7" />
              </button>
            )}
            
            {onExport && (
              <button
                onClick={onExport}
                className="p-1.5 hover:bg-gray-2 rounded-md transition-colors"
                title="导出"
              >
                <Download className="w-4 h-4 text-gray-7" />
              </button>
            )}
            
            <button className="p-1.5 hover:bg-gray-2 rounded-md transition-colors">
              <MoreVertical className="w-4 h-4 text-gray-7" />
            </button>
          </div>
        </div>
        
        {/* 统计摘要 */}
        <div className="flex items-center gap-6 mt-4 pt-4 border-t border-gray-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-6">总计</span>
            <span className="text-sm font-bold text-gray-10 font-mono">
              {stats.total.toLocaleString()}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-6">平均</span>
            <span className="text-sm font-bold text-gray-10 font-mono">
              {stats.average.toLocaleString()}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-6">峰值</span>
            <span className="text-sm font-bold text-gray-10 font-mono">
              {stats.max.toLocaleString()}
            </span>
          </div>
          {showTrend && (
            <Badge
              variant="outline"
              className={cn(
                "ml-auto text-xs font-semibold px-2 py-1",
                Number(stats.changePercent) > 0 
                  ? "border-metric-positive/50 text-metric-positive bg-metric-positive/5"
                  : Number(stats.changePercent) < 0
                    ? "border-metric-negative/50 text-metric-negative bg-metric-negative/5"
                    : "border-gray-5 text-gray-7 bg-gray-2"
              )}
            >
              {Number(stats.changePercent) > 0 ? '+' : ''}{stats.changePercent}%
            </Badge>
          )}
        </div>
      </CardHeader>
      
      <CardContent className="pt-6">
        {type === 'bar' && color !== 'aarrr' && <EnhancedBarChart />}
        {(type === 'line' || type === 'area') && <EnhancedLineChart />}
        {color === 'aarrr' && <FunnelChart />}
      </CardContent>
    </Card>
  )
}