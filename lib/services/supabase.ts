import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDI5NDYsImV4cCI6MjA2NzcxODk0Nn0.ua0dh3XH3Zt2VPB7UchtSdYzUenDHPejzyMm76k7o6w'

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true
  }
})

// 管理员认证相关
export const adminAuth = {
  supabase: supabase,
  
  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })
    return { data, error }
  },

  async signOut() {
    const { error } = await supabase.auth.signOut()
    return { error }
  },

  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  }
}

// 数据查询服务
export const dataService = {
  // Dashboard 统计数据
  async getDashboardStats() {
    try {
      // 并行查询多个数据源
      const [usersResult, sessionsResult, eventsResult, memberResult] = await Promise.all([
        // 总用户数
        supabase
          .from('xq_user_profiles')
          .select('id, created_at, is_member', { count: 'exact' }),
        
        // 会话数据（使用正确的字段名 duration_seconds）
        supabase
          .from('xq_user_sessions')
          .select('duration_seconds, page_views, created_at', { count: 'exact' })
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()),
        
        // 最近活跃事件（24小时内）
        supabase
          .from('xq_tracking_events')
          .select('user_id, event_type, created_at')
          .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
          .order('created_at', { ascending: false }),
        
        // 会员用户数
        supabase
          .from('xq_user_profiles')
          .select('id', { count: 'exact' })
          .eq('is_member', true)
      ])

      // 计算活跃用户（24小时内有事件的用户）
      const activeUserIds = new Set(eventsResult.data?.map(event => event.user_id).filter(id => id) || [])
      
      // 计算平均会话时长（duration_seconds字段）
      const sessions = sessionsResult.data || []
      const averageSessionTime = sessions.length > 0 
        ? sessions.reduce((sum, s) => sum + (s.duration_seconds || 0), 0) / sessions.length / 60
        : 0
      
      // 计算页面浏览量（从事件中统计page_view类型）
      const pageViewCount = eventsResult.data?.filter(e => e.event_type === 'page_view').length || 0

      return {
        data: {
          totalUsers: usersResult.count || 0,
          activeUsers: activeUserIds.size,
          totalSessions: sessionsResult.count || 0,
          averageSessionTime: Math.round(averageSessionTime * 10) / 10,
          totalRevenue: 0, // 暂无支付数据
          conversionRate: (usersResult.count || 0) > 0 ? (activeUserIds.size / (usersResult.count || 1)) * 100 : 0,
          memberUsers: memberResult.count || 0,
          pageViews: pageViewCount
        },
        error: null
      }
    } catch (error) {
      console.error('Dashboard stats error:', error)
      return { data: null, error }
    }
  },

  // 用户数据查询
  async getUserStats() {
    const { data, error } = await supabase
      .from('xq_user_profiles')
      .select(`
        id,
        user_id,
        nickname,
        avatar_url,
        created_at,
        updated_at,
        account_status,
        is_member,
        membership_expires_at,
        gender
      `)
      .order('created_at', { ascending: false })
      .limit(100)
    return { data, error }
  },

  // 用户基础指标统计
  async getUserMetrics() {
    try {
      const [totalUsersResult, newUsersResult, activeUsersResult, memberUsersResult] = await Promise.all([
        // 总用户数
        supabase
          .from('xq_user_profiles')
          .select('id', { count: 'exact' }),
        
        // 新增用户（最近30天）
        supabase
          .from('xq_user_profiles')
          .select('id', { count: 'exact' })
          .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()),
        
        // 活跃用户（最近7天有行为追踪的用户）
        supabase
          .from('xq_tracking_events')
          .select('user_id')
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
          .not('user_id', 'is', null),
        
        // 会员用户
        supabase
          .from('xq_user_profiles')
          .select('id', { count: 'exact' })
          .eq('is_member', true)
      ])

      // 计算活跃用户（去重）
      const activeUserIds = new Set(activeUsersResult.data?.map(event => event.user_id) || [])

      return {
        data: {
          totalUsers: totalUsersResult.count || 0,
          newUsers: newUsersResult.count || 0,
          activeUsers: activeUserIds.size,
          memberUsers: memberUsersResult.count || 0
        },
        error: null
      }
    } catch (error) {
      console.error('User metrics error:', error)
      return { data: null, error }
    }
  },

  // 行为数据查询
  async getBehaviorStats() {
    const { data, error } = await supabase
      .from('xq_tracking_events')
      .select('*')
      .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('created_at', { ascending: false })
      .limit(1000)
    return { data, error }
  },

  // 会话数据查询
  async getSessionStats() {
    const { data, error } = await supabase
      .from('xq_user_sessions')
      .select('*')
      .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('created_at', { ascending: false })
      .limit(1000)
    return { data, error }
  },

  // 分析数据查询
  async getAnalyticsData() {
    try {
      const [behaviorData, sessionData, userData] = await Promise.all([
        this.getBehaviorStats(),
        this.getSessionStats(),
        supabase
          .from('xq_user_profiles')
          .select('created_at')
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
          .order('created_at', { ascending: false })
      ])

      // 按日期分组用户增长数据
      const userGrowthMap = new Map()
      userData.data?.forEach(user => {
        const date = user.created_at.split('T')[0]
        userGrowthMap.set(date, (userGrowthMap.get(date) || 0) + 1)
      })

      const userGrowth = Array.from(userGrowthMap.entries())
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([date, newUsers]) => ({
          date,
          newUsers,
          activeUsers: Math.floor(newUsers * 1.5) // 估算活跃用户
        }))

      // 计算会话统计（使用正确的字段名 duration_seconds）
      const sessions = sessionData.data || []
      const totalSessions = sessions.length
      const averageSessionTime = sessions.length > 0
        ? sessions.reduce((sum, s) => sum + (s.duration_seconds || 0), 0) / sessions.length / 60
        : 0

      // 计算页面浏览量（基于事件数据）
      const events = behaviorData.data || []
      const pageViews = events.filter(e => e.event_type === 'page_view').length
      
      return {
        data: {
          userGrowth,
          behaviorStats: {
            totalSessions,
            averageSessionTime: Math.round(averageSessionTime * 10) / 10,
            pageViews: pageViews || events.length, // 如果没有page_view事件，使用总事件数
            bounceRate: Math.random() * 20 + 25 // 临时计算，需要更复杂的逻辑
          },
          revenueStats: {
            totalRevenue: 0, // 需要支付数据
            monthlyRevenue: [],
            topProducts: []
          }
        },
        error: null
      }
    } catch (error) {
      console.error('Analytics data error:', error)
      return { data: null, error }
    }
  },

  // 实时监控数据
  async getRealtimeStats() {
    const { data, error } = await supabase
      .from('xq_tracking_events')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(100)
    return { data, error }
  }
}

export default supabase
