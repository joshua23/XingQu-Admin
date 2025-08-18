import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import dayjs from 'dayjs'
import type { 
  FilterOptions, 
  MetricData, 
  ChartDataPoint, 
  FunnelData,
  GaugeData,
  RealtimeData,
  DashboardTab,
  LoadingState
} from '../types/dashboard'

// 模拟API服务
const mockApi = {
  // 获取运营数据
  async getOperationsData(filters: FilterOptions) {
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    return {
      metrics: [
        {
          key: 'dau',
          label: 'DAU',
          value: 23456,
          change: 0.125,
          changeType: 'increase' as const,
          icon: 'user',
          description: '日活跃用户数'
        },
        {
          key: 'new_users',
          label: '新增用户',
          value: 1234,
          change: 0.083,
          changeType: 'increase' as const,
          icon: 'user-add',
          description: '今日新注册用户'
        },
        {
          key: 'retention',
          label: '次留率',
          value: '42.3%',
          change: 0.021,
          changeType: 'increase' as const,
          icon: 'heart',
          description: '次日留存率'
        },
        {
          key: 'duration',
          label: '使用时长',
          value: '28.5分钟',
          change: 3.2,
          changeType: 'increase' as const,
          icon: 'clock',
          suffix: '',
          description: '平均使用时长'
        }
      ] as MetricData[],
      
      trendData: generateTrendData(),
      funnelData: generateFunnelData(),
      tableData: generateTableData()
    }
  },
  
  // 获取商业化数据
  async getRevenueData(filters: FilterOptions) {
    await new Promise(resolve => setTimeout(resolve, 800))
    
    return {
      metrics: [
        {
          key: 'revenue',
          label: '今日收入',
          value: '¥128,456',
          change: 0.156,
          changeType: 'increase' as const,
          icon: 'money',
          description: '今日总收入'
        },
        {
          key: 'conversion',
          label: '付费转化率',
          value: '5.8%',
          change: 0.003,
          changeType: 'increase' as const,
          icon: 'percentage',
          description: '付费用户转化率'
        },
        {
          key: 'arpu',
          label: 'ARPU',
          value: '¥28.5',
          change: 2.1,
          changeType: 'increase' as const,
          icon: 'dollar',
          description: '平均每用户收入'
        },
        {
          key: 'ltv',
          label: 'LTV',
          value: '¥856',
          change: 0.045,
          changeType: 'increase' as const,
          icon: 'line-chart',
          description: '用户生命周期价值'
        }
      ] as MetricData[],
      
      revenueGauge: {
        percent: 0.642,
        target: 200000,
        current: 128456,
        title: '今日收入目标',
        unit: '¥'
      } as GaugeData,
      
      membershipData: generateMembershipData(),
      realtimeOrders: generateRealtimeOrders()
    }
  }
}

// 数据生成函数
function generateTrendData(): ChartDataPoint[] {
  const data: ChartDataPoint[] = []
  const types = ['DAU', 'MAU', '新增用户']
  
  for (let i = 0; i < 30; i++) {
    const date = dayjs().subtract(29 - i, 'day').format('YYYY-MM-DD')
    
    types.forEach(type => {
      let baseValue = 0
      if (type === 'DAU') baseValue = 20000 + Math.random() * 8000
      if (type === 'MAU') baseValue = 180000 + Math.random() * 20000
      if (type === '新增用户') baseValue = 800 + Math.random() * 600
      
      data.push({
        date,
        value: Math.round(baseValue),
        type
      })
    })
  }
  
  return data
}

function generateFunnelData(): FunnelData[] {
  return [
    {
      stage: 'Acquisition',
      stageName: '获取',
      value: 10000,
      rate: 100,
      color: '#1890FF'
    },
    {
      stage: 'Activation',
      stageName: '激活',
      value: 3000,
      rate: 30,
      color: '#13C2C2'
    },
    {
      stage: 'Retention',
      stageName: '留存',
      value: 1200,
      rate: 12,
      color: '#52C41A'
    },
    {
      stage: 'Revenue',
      stageName: '收入',
      value: 500,
      rate: 5,
      color: '#FAAD14'
    },
    {
      stage: 'Referral',
      stageName: '推荐',
      value: 100,
      rate: 1,
      color: '#722ED1'
    }
  ]
}

function generateTableData(): any[] {
  const data = []
  for (let i = 0; i < 15; i++) {
    data.push({
      id: i + 1,
      date: dayjs().subtract(i, 'day').format('MM-DD'),
      dau: Math.round(20000 + Math.random() * 8000),
      newUsers: Math.round(800 + Math.random() * 600),
      retention: Math.round(40 + Math.random() * 20),
      revenue: Math.round(100000 + Math.random() * 80000),
      conversion: Number((4 + Math.random() * 3).toFixed(2))
    })
  }
  return data
}

function generateMembershipData(): any[] {
  return [
    { segment: 'free', segmentName: '免费用户', userCount: 55000, percentage: 55, arpu: 0, ltv: 0 },
    { segment: 'basic', segmentName: '基础会员', userCount: 28000, percentage: 28, arpu: 25, ltv: 300 },
    { segment: 'premium', segmentName: '高级会员', userCount: 15000, percentage: 15, arpu: 68, ltv: 850 },
    { segment: 'vip', segmentName: '终身会员', userCount: 2000, percentage: 2, arpu: 0, ltv: 1999 }
  ]
}

function generateRealtimeOrders(): any[] {
  const orders = []
  const products = ['基础会员', '高级会员', '终身会员', '星川礼包']
  const amounts = [99, 199, 599, 299]
  
  for (let i = 0; i < 10; i++) {
    const time = dayjs().subtract(i * 2, 'minute').format('HH:mm')
    const productIndex = Math.floor(Math.random() * products.length)
    
    orders.push({
      time,
      amount: amounts[productIndex],
      userId: `user_${Math.random().toString(36).substr(2, 8)}`,
      product: products[productIndex]
    })
  }
  
  return orders
}

export const useDashboardStore = defineStore('dashboard', () => {
  // 状态
  const activeTab = ref<DashboardTab>('operations')
  const filters = ref<FilterOptions>({
    dateRange: [dayjs().subtract(7, 'day'), dayjs()],
    department: '',
    channel: '',
    userSegment: '',
    granularity: 'day'
  })
  
  // 加载状态
  const operationsLoadingState = ref<LoadingState>('idle')
  const revenueLoadingState = ref<LoadingState>('idle')
  
  // 数据存储
  const operationsData = ref<any>({
    metrics: [],
    trendData: [],
    funnelData: [],
    tableData: []
  })
  
  const revenueData = ref<any>({
    metrics: [],
    revenueGauge: null,
    membershipData: [],
    realtimeOrders: []
  })
  
  // 错误状态
  const error = ref<string | null>(null)
  
  // 计算属性
  const isLoading = computed(() => 
    operationsLoadingState.value === 'loading' || 
    revenueLoadingState.value === 'loading'
  )
  
  const operationsMetrics = computed(() => operationsData.value.metrics || [])
  const revenueMetrics = computed(() => revenueData.value.metrics || [])
  
  const currentMetrics = computed(() => 
    activeTab.value === 'operations' ? operationsMetrics.value : revenueMetrics.value
  )
  
  // Actions
  const setActiveTab = (tab: DashboardTab) => {
    activeTab.value = tab
  }
  
  const setFilters = (newFilters: FilterOptions) => {
    filters.value = { ...newFilters }
  }
  
  const resetFilters = () => {
    filters.value = {
      dateRange: [dayjs().subtract(7, 'day'), dayjs()],
      department: '',
      channel: '',
      userSegment: '',
      granularity: 'day'
    }
  }
  
  const fetchOperationsData = async (filterOptions?: FilterOptions) => {
    operationsLoadingState.value = 'loading'
    error.value = null
    
    try {
      const currentFilters = filterOptions || filters.value
      const data = await mockApi.getOperationsData(currentFilters)
      
      operationsData.value = data
      operationsLoadingState.value = 'success'
      
    } catch (err) {
      console.error('获取运营数据失败:', err)
      error.value = '获取运营数据失败'
      operationsLoadingState.value = 'error'
    }
  }
  
  const fetchRevenueData = async (filterOptions?: FilterOptions) => {
    revenueLoadingState.value = 'loading'
    error.value = null
    
    try {
      const currentFilters = filterOptions || filters.value
      const data = await mockApi.getRevenueData(currentFilters)
      
      revenueData.value = data
      revenueLoadingState.value = 'success'
      
    } catch (err) {
      console.error('获取商业化数据失败:', err)
      error.value = '获取商业化数据失败'
      revenueLoadingState.value = 'error'
    }
  }
  
  const refreshCurrentData = async () => {
    if (activeTab.value === 'operations') {
      await fetchOperationsData()
    } else {
      await fetchRevenueData()
    }
  }
  
  const updateRealtimeData = (data: RealtimeData) => {
    // 更新实时数据
    if (revenueData.value.revenueGauge) {
      revenueData.value.revenueGauge.current = data.revenue.current
    }
    
    // 更新实时订单
    revenueData.value.realtimeOrders = data.revenue.orders || []
    
    // 更新相关指标
    const metrics = revenueData.value.metrics
    if (metrics && metrics.length > 0) {
      // 更新付费转化率
      const conversionMetric = metrics.find((m: MetricData) => m.key === 'conversion')
      if (conversionMetric) {
        conversionMetric.value = `${data.metrics.paymentConversion.toFixed(1)}%`
      }
      
      // 更新ARPU
      const arpuMetric = metrics.find((m: MetricData) => m.key === 'arpu')
      if (arpuMetric) {
        arpuMetric.value = `¥${data.metrics.arpu.toFixed(1)}`
      }
    }
  }
  
  // 导出数据
  const exportData = async (type: 'excel' | 'pdf' = 'excel') => {
    const currentData = activeTab.value === 'operations' 
      ? operationsData.value 
      : revenueData.value
    
    // 这里可以实现实际的导出逻辑
    console.log(`导出${type.toUpperCase()}数据:`, currentData)
    
    return Promise.resolve()
  }
  
  return {
    // 状态
    activeTab,
    filters,
    operationsLoadingState,
    revenueLoadingState,
    operationsData,
    revenueData,
    error,
    
    // 计算属性
    isLoading,
    operationsMetrics,
    revenueMetrics,
    currentMetrics,
    
    // 方法
    setActiveTab,
    setFilters,
    resetFilters,
    fetchOperationsData,
    fetchRevenueData,
    refreshCurrentData,
    updateRealtimeData,
    exportData
  }
})