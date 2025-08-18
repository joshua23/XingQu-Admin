import type { Dayjs } from 'dayjs'

// 指标数据类型
export interface MetricData {
  key: string
  label: string
  value: number | string
  change?: number
  changeType?: 'increase' | 'decrease' | 'neutral'
  icon?: string
  suffix?: string
  prefix?: string
  description?: string
}

// 图表数据点类型
export interface ChartDataPoint {
  date: string | number
  value: number
  type?: string
  category?: string
  [key: string]: any
}

// 漏斗数据类型
export interface FunnelData {
  stage: string
  stageName: string
  value: number
  rate: number
  conversion?: number
  color?: string
}

// 仪表盘数据类型
export interface GaugeData {
  percent: number
  target: number
  current: number
  title: string
  unit?: string
}

// 筛选器选项类型
export interface FilterOptions {
  dateRange: [Dayjs, Dayjs]
  department: string
  channel: string
  userSegment: string
  granularity?: 'hour' | 'day' | 'week' | 'month'
}

// 实时数据类型
export interface RealtimeData {
  revenue: {
    current: number
    target: number
    orders: RealtimeOrder[]
  }
  metrics: {
    paymentConversion: number
    arpu: number
    activeUsers: number
  }
  timestamp: number
}

export interface RealtimeOrder {
  time: string
  amount: number
  userId: string
  product: string
}

// AARRR模型数据
export interface AARRRData {
  acquisition: number
  activation: number
  retention: number
  revenue: number
  referral: number
  conversionRates: {
    acquisitionToActivation: number
    activationToRetention: number
    retentionToRevenue: number
    revenueToReferral: number
  }
}

// 用户分层数据
export interface UserSegmentData {
  segment: 'free' | 'basic' | 'premium' | 'vip'
  segmentName: string
  userCount: number
  percentage: number
  arpu: number
  ltv: number
}

// 会员体系数据
export interface MembershipData {
  distribution: UserSegmentData[]
  funnel: {
    viewMembership: number
    clickPurchase: number
    paymentSuccess: number
    renewalSuccess: number
  }
  metrics: {
    totalPayingUsers: number
    monthlyChurnRate: number
    averageOrderValue: number
  }
}

// API响应类型
export interface ApiResponse<T = any> {
  code: number
  data: T
  message: string
  timestamp: number
  success: boolean
}

// 图表配置类型
export interface ChartConfig {
  data: any[]
  height?: number
  width?: number
  padding?: number[]
  theme?: 'default' | 'dark'
  animation?: boolean
  interaction?: boolean
  [key: string]: any
}

// 看板配置类型
export interface DashboardConfig {
  refreshInterval: {
    operations: number  // T+1数据刷新间隔(毫秒)
    revenue: number     // 实时数据刷新间隔(毫秒)
  }
  autoRefresh: boolean
  defaultDateRange: number  // 默认天数
  maxDataPoints: number     // 图表最大数据点数
  enableWebSocket: boolean  // 是否启用WebSocket
}

// 错误类型
export interface DashboardError {
  code: string
  message: string
  details?: any
  timestamp: number
}

// 加载状态类型
export type LoadingState = 'idle' | 'loading' | 'success' | 'error'

// 组件Props类型
export interface MetricCardProps {
  data: MetricData
  loading?: boolean
  size?: 'small' | 'default' | 'large'
}

export interface ChartPanelProps {
  title: string
  extra?: string
  loading?: boolean
  height?: number
  data: any[]
  chartType: 'line' | 'column' | 'pie' | 'funnel' | 'gauge'
  config?: ChartConfig
}

export interface FilterPanelProps {
  filters: FilterOptions
  loading?: boolean
  showExport?: boolean
  onFiltersChange: (filters: FilterOptions) => void
  onExport?: () => void
}

// 事件类型
export interface DashboardEvents {
  'metric-click': (metric: MetricData) => void
  'filter-change': (filters: FilterOptions) => void
  'chart-drill-down': (data: any) => void
  'export-data': (type: 'excel' | 'pdf') => void
  'refresh-data': () => void
}

// Tab类型
export type DashboardTab = 'operations' | 'revenue'

export interface TabConfig {
  key: DashboardTab
  label: string
  icon?: string
  refreshType: 'scheduled' | 'realtime'
}