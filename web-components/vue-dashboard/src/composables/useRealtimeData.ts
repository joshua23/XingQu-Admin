import { ref, onMounted, onUnmounted } from 'vue'
import type { RealtimeData, RealtimeOrder } from '../types/dashboard'

// WebSocket连接状态
type ConnectionState = 'connecting' | 'connected' | 'disconnected' | 'error'

export const useRealtimeData = (url?: string) => {
  // 默认WebSocket地址
  const defaultUrl = 'wss://api.xingqu.com/ws/dashboard/realtime'
  const wsUrl = url || defaultUrl
  
  // 响应式状态
  const data = ref<RealtimeData | null>(null)
  const connectionState = ref<ConnectionState>('disconnected')
  const isConnected = ref(false)
  const connectionCount = ref(0)
  const lastUpdateTime = ref<Date | null>(null)
  const error = ref<string | null>(null)
  
  // WebSocket实例
  let websocket: WebSocket | null = null
  let reconnectTimer: NodeJS.Timeout | null = null
  let heartbeatTimer: NodeJS.Timeout | null = null
  
  // 重连配置
  const reconnectConfig = {
    maxRetries: 5,
    retryCount: 0,
    retryDelay: 1000, // 初始延迟1秒
    maxDelay: 30000   // 最大延迟30秒
  }
  
  // 生成模拟实时数据
  const generateMockRealtimeData = (): RealtimeData => {
    const baseRevenue = 128456
    const variation = (Math.random() - 0.5) * 10000
    const currentRevenue = Math.max(0, baseRevenue + variation)
    
    // 生成最近订单
    const orders: RealtimeOrder[] = []
    const products = ['基础会员', '高级会员', '终身会员', '星川礼包']
    const amounts = [99, 199, 599, 299]
    
    for (let i = 0; i < 5; i++) {
      const now = new Date()
      const time = new Date(now.getTime() - i * 60000) // 每分钟一个订单
      const productIndex = Math.floor(Math.random() * products.length)
      
      orders.push({
        time: time.toLocaleTimeString('zh-CN', { 
          hour: '2-digit', 
          minute: '2-digit' 
        }),
        amount: amounts[productIndex],
        userId: `user_${Math.random().toString(36).substr(2, 6)}`,
        product: products[productIndex]
      })
    }
    
    return {
      revenue: {
        current: Math.round(currentRevenue),
        target: 200000,
        orders
      },
      metrics: {
        paymentConversion: 5.8 + (Math.random() - 0.5) * 0.5,
        arpu: 28.5 + (Math.random() - 0.5) * 2,
        activeUsers: Math.round(23456 + (Math.random() - 0.5) * 2000)
      },
      timestamp: Date.now()
    }
  }
  
  // 创建WebSocket连接
  const connect = () => {
    if (websocket?.readyState === WebSocket.CONNECTING || 
        websocket?.readyState === WebSocket.OPEN) {
      return
    }
    
    try {
      connectionState.value = 'connecting'
      error.value = null
      
      // 在开发环境使用模拟数据
      if (process.env.NODE_ENV === 'development' || wsUrl.includes('localhost')) {
        // 模拟连接延迟
        setTimeout(() => {
          connectionState.value = 'connected'
          isConnected.value = true
          connectionCount.value = Math.floor(Math.random() * 10) + 1
          
          // 开始模拟数据推送
          startMockDataStream()
          
          console.log('模拟WebSocket连接已建立')
        }, 1000)
        
        return
      }
      
      // 实际WebSocket连接
      websocket = new WebSocket(wsUrl)
      
      websocket.onopen = handleOpen
      websocket.onmessage = handleMessage
      websocket.onclose = handleClose
      websocket.onerror = handleError
      
    } catch (err) {
      console.error('WebSocket连接创建失败:', err)
      handleConnectionError('连接创建失败')
    }
  }
  
  // 断开连接
  const disconnect = () => {
    stopReconnect()
    stopHeartbeat()
    stopMockDataStream()
    
    if (websocket) {
      websocket.close()
      websocket = null
    }
    
    connectionState.value = 'disconnected'
    isConnected.value = false
    connectionCount.value = 0
  }
  
  // WebSocket事件处理
  const handleOpen = () => {
    console.log('WebSocket连接已建立')
    connectionState.value = 'connected'
    isConnected.value = true
    
    // 重置重连计数
    reconnectConfig.retryCount = 0
    
    // 发送认证信息（如果需要）
    sendAuth()
    
    // 开始心跳
    startHeartbeat()
  }
  
  const handleMessage = (event: MessageEvent) => {
    try {
      const message = JSON.parse(event.data)
      
      switch (message.type) {
        case 'realtime_data':
          data.value = message.data
          lastUpdateTime.value = new Date()
          break
          
        case 'connection_count':
          connectionCount.value = message.count
          break
          
        case 'pong':
          // 心跳响应
          break
          
        default:
          console.log('未知消息类型:', message.type)
      }
      
    } catch (err) {
      console.error('消息解析失败:', err)
    }
  }
  
  const handleClose = (event: CloseEvent) => {
    console.log('WebSocket连接关闭:', event.code, event.reason)
    
    connectionState.value = 'disconnected'
    isConnected.value = false
    connectionCount.value = 0
    
    stopHeartbeat()
    
    // 如果不是主动关闭，尝试重连
    if (event.code !== 1000 && event.code !== 1001) {
      startReconnect()
    }
  }
  
  const handleError = (event: Event) => {
    console.error('WebSocket错误:', event)
    handleConnectionError('连接错误')
  }
  
  const handleConnectionError = (message: string) => {
    connectionState.value = 'error'
    error.value = message
    isConnected.value = false
    
    startReconnect()
  }
  
  // 发送认证信息
  const sendAuth = () => {
    if (websocket?.readyState === WebSocket.OPEN) {
      const authData = {
        type: 'auth',
        token: localStorage.getItem('authToken') || 'mock-token',
        dashboard: 'revenue'
      }
      
      websocket.send(JSON.stringify(authData))
    }
  }
  
  // 心跳机制
  const startHeartbeat = () => {
    heartbeatTimer = setInterval(() => {
      if (websocket?.readyState === WebSocket.OPEN) {
        websocket.send(JSON.stringify({ type: 'ping' }))
      }
    }, 30000) // 30秒心跳
  }
  
  const stopHeartbeat = () => {
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer)
      heartbeatTimer = null
    }
  }
  
  // 重连机制
  const startReconnect = () => {
    if (reconnectConfig.retryCount >= reconnectConfig.maxRetries) {
      console.error('达到最大重连次数，停止重连')
      connectionState.value = 'error'
      error.value = '连接失败，请刷新页面重试'
      return
    }
    
    const delay = Math.min(
      reconnectConfig.retryDelay * Math.pow(2, reconnectConfig.retryCount),
      reconnectConfig.maxDelay
    )
    
    console.log(`${delay}ms后尝试第${reconnectConfig.retryCount + 1}次重连`)
    
    reconnectTimer = setTimeout(() => {
      reconnectConfig.retryCount++
      connect()
    }, delay)
  }
  
  const stopReconnect = () => {
    if (reconnectTimer) {
      clearTimeout(reconnectTimer)
      reconnectTimer = null
    }
  }
  
  // 模拟数据流（开发环境使用）
  let mockDataTimer: NodeJS.Timeout | null = null
  
  const startMockDataStream = () => {
    // 立即发送一次数据
    data.value = generateMockRealtimeData()
    lastUpdateTime.value = new Date()
    
    // 每5秒更新一次
    mockDataTimer = setInterval(() => {
      data.value = generateMockRealtimeData()
      lastUpdateTime.value = new Date()
      
      // 模拟连接数变化
      connectionCount.value = Math.floor(Math.random() * 15) + 1
    }, 5000)
  }
  
  const stopMockDataStream = () => {
    if (mockDataTimer) {
      clearInterval(mockDataTimer)
      mockDataTimer = null
    }
  }
  
  // 手动刷新数据
  const refresh = () => {
    if (process.env.NODE_ENV === 'development') {
      data.value = generateMockRealtimeData()
      lastUpdateTime.value = new Date()
    } else if (websocket?.readyState === WebSocket.OPEN) {
      websocket.send(JSON.stringify({ type: 'refresh' }))
    }
  }
  
  // 获取连接状态描述
  const getConnectionStatusText = () => {
    switch (connectionState.value) {
      case 'connecting':
        return '连接中...'
      case 'connected':
        return '已连接'
      case 'disconnected':
        return '已断开'
      case 'error':
        return '连接错误'
      default:
        return '未知状态'
    }
  }
  
  // 生命周期管理
  onMounted(() => {
    // 默认不自动连接，由组件主动调用
  })
  
  onUnmounted(() => {
    disconnect()
  })
  
  return {
    // 响应式数据
    data,
    connectionState,
    isConnected,
    connectionCount,
    lastUpdateTime,
    error,
    
    // 方法
    connect,
    disconnect,
    refresh,
    getConnectionStatusText,
    
    // 工具方法
    generateMockRealtimeData
  }
}