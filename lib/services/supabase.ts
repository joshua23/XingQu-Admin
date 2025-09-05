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
  supabase: supabase, // 暴露supabase客户端供其他服务使用
  
  // Dashboard 统计数据（优化：减少数据库查询复杂度）
  async getDashboardStats() {
    try {
      // 优化：减少并行查询，合并部分查询逻辑
      const [usersResult, recentSessionsResult, recentEventsResult] = await Promise.all([
        // 获取用户基础统计（包含会员信息）
        supabase
          .from('xq_user_profiles')
          .select('id, created_at, is_member', { count: 'exact' })
          .order('created_at', { ascending: false })
          .limit(1000), // 限制查询量提升性能
        
        // 最近会话数据（限制查询范围）
        supabase
          .from('xq_user_sessions')
          .select('duration_seconds, page_views, created_at', { count: 'exact' })
          .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()) // 缩短到24小时
          .limit(500), // 限制查询量
        
        // 最近活跃事件（限制查询）
        supabase
          .from('xq_tracking_events')
          .select('user_id, event_type, created_at')
          .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
          .limit(1000) // 限制查询量
          .order('created_at', { ascending: false })
      ])

      // 优化：从单次查询结果中计算多个指标
      const activeUserIds = new Set(recentEventsResult.data?.map(event => event.user_id).filter(id => id) || [])
      const memberUsers = usersResult.data?.filter(user => user.is_member).length || 0
      
      // 计算平均会话时长
      const sessions = recentSessionsResult.data || []
      const averageSessionTime = sessions.length > 0 
        ? sessions.reduce((sum, s) => sum + (s.duration_seconds || 0), 0) / sessions.length / 60
        : 0
      
      // 计算页面浏览量
      const pageViewCount = recentEventsResult.data?.filter(e => e.event_type === 'page_view').length || 0

      return {
        data: {
          totalUsers: usersResult.count || 0,
          activeUsers: activeUserIds.size,
          totalSessions: recentSessionsResult.count || 0,
          averageSessionTime: Math.round(averageSessionTime * 10) / 10,
          totalRevenue: 0, // 暂无支付数据
          conversionRate: (usersResult.count || 0) > 0 ? (activeUserIds.size / (usersResult.count || 1)) * 100 : 0,
          memberUsers: memberUsers,
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
  },

  // 获取图表数据
  async getChartData() {
    try {
      const now = new Date()
      const daysAgo = (days: number) => new Date(now.getTime() - days * 24 * 60 * 60 * 1000)
      
      // 获取过去7天的用户增长数据
      const userGrowthData = []
      for (let i = 6; i >= 0; i--) {
        const startDate = daysAgo(i + 1)
        const endDate = daysAgo(i)
        
        const { count } = await supabase
          .from('xq_user_profiles')
          .select('*', { count: 'exact', head: true })
          .gte('created_at', startDate.toISOString())
          .lt('created_at', endDate.toISOString())
          
        const dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
        const dayName = dayNames[endDate.getDay()]
        
        userGrowthData.push({
          label: dayName,
          value: count || 0,
          trend: 'up' as const
        })
      }

      // 获取过去7天的活跃用户数据
      const activityData = []
      for (let i = 6; i >= 0; i--) {
        const startDate = daysAgo(i + 1)
        const endDate = daysAgo(i)
        
        const { data: events } = await supabase
          .from('xq_tracking_events')
          .select('user_id')
          .gte('created_at', startDate.toISOString())
          .lt('created_at', endDate.toISOString())
          .not('user_id', 'is', null)
        
        const activeUsers = new Set(events?.map(e => e.user_id) || []).size
        const dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
        const dayName = dayNames[endDate.getDay()]
        
        activityData.push({
          label: dayName,
          value: activeUsers,
          trend: 'up' as const
        })
      }

      // 获取过去7天的收入数据（目前使用页面浏览量作为替代指标）
      const revenueData = []
      for (let i = 6; i >= 0; i--) {
        const startDate = daysAgo(i + 1)
        const endDate = daysAgo(i)
        
        const { count } = await supabase
          .from('xq_tracking_events')
          .select('*', { count: 'exact', head: true })
          .eq('event_type', 'page_view')
          .gte('created_at', startDate.toISOString())
          .lt('created_at', endDate.toISOString())
        
        const dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
        const dayName = dayNames[endDate.getDay()]
        
        revenueData.push({
          label: dayName,
          value: (count || 0) * 10, // 模拟收入：每个页面浏览按10元计算
          trend: 'up' as const
        })
      }

      return {
        data: {
          userGrowthData,
          activityData, 
          revenueData
        },
        error: null
      }
    } catch (error) {
      console.error('Chart data error:', error)
      return { data: null, error }
    }
  },

  // 获取热门智能体数据 - 只使用真实的xq_agents表数据
  async getTopAgents() {
    try {
      // 获取智能体基础信息
      const { data: agents, error: agentsError } = await supabase
        .from('xq_agents')
        .select(`
          id,
          name,
          description,
          avatar_url,
          creator_id,
          created_at,
          is_active,
          category,
          tags
        `)
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(20)

      if (agentsError) {
        console.error('获取智能体数据失败:', agentsError)
        return { data: [], error: agentsError }
      }

      if (!agents || agents.length === 0) {
        return { data: [], error: null }
      }

      // 获取智能体使用统计
      const agentIds = agents.map(agent => agent.id)
      const { data: usageStats } = await supabase
        .from('xq_agent_usage')
        .select('agent_id, user_id, created_at')
        .in('agent_id', agentIds)
        .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())

      // 统计每个智能体的使用次数和用户数
      const agentStats = new Map()
      usageStats?.forEach(usage => {
        const current = agentStats.get(usage.agent_id) || { usageCount: 0, users: new Set() }
        current.usageCount += 1
        current.users.add(usage.user_id)
        agentStats.set(usage.agent_id, current)
      })

      // 组合数据并按使用量排序
      const topAgents = agents
        .map(agent => {
          const stats = agentStats.get(agent.id) || { usageCount: 0, users: new Set() }
          return {
            id: agent.id,
            name: agent.name,
            description: agent.description,
            avatar_url: agent.avatar_url,
            category: agent.category,
            tags: agent.tags || [],
            usageCount: stats.usageCount,
            userCount: stats.users.size,
            created_at: agent.created_at
          }
        })
        .sort((a, b) => b.usageCount - a.usageCount)
        .slice(0, 6)

      return { data: topAgents, error: null }
    } catch (error) {
      console.error('Top agents error:', error)
      return { data: [], error }
    }
  },

  // 获取Sparkline小图数据（用于指标卡片）
  async getSparklineData(metric: 'users' | 'activity' | 'revenue' | 'pageviews') {
    try {
      const now = new Date()
      const daysAgo = (days: number) => new Date(now.getTime() - days * 24 * 60 * 60 * 1000)
      
      const sparklineData = []
      
      for (let i = 6; i >= 0; i--) {
        const startDate = daysAgo(i + 1)
        const endDate = daysAgo(i)
        
        let value = 0
        
        switch (metric) {
          case 'users':
            const { count: userCount } = await supabase
              .from('xq_user_profiles')
              .select('*', { count: 'exact', head: true })
              .gte('created_at', startDate.toISOString())
              .lt('created_at', endDate.toISOString())
            value = userCount || 0
            break
            
          case 'activity':
            const { data: events } = await supabase
              .from('xq_tracking_events')
              .select('user_id')
              .gte('created_at', startDate.toISOString())
              .lt('created_at', endDate.toISOString())
              .not('user_id', 'is', null)
            value = new Set(events?.map(e => e.user_id) || []).size
            break
            
          case 'pageviews':
            const { count: pageCount } = await supabase
              .from('xq_tracking_events')
              .select('*', { count: 'exact', head: true })
              .eq('event_type', 'page_view')
              .gte('created_at', startDate.toISOString())
              .lt('created_at', endDate.toISOString())
            value = pageCount || 0
            break
            
          case 'revenue':
            // 暂无真实收入数据，使用页面浏览量模拟
            const { count: revenueCount } = await supabase
              .from('xq_tracking_events')
              .select('*', { count: 'exact', head: true })
              .eq('event_type', 'page_view')
              .gte('created_at', startDate.toISOString())
              .lt('created_at', endDate.toISOString())
            value = (revenueCount || 0) * 10
            break
        }
        
        sparklineData.push(value)
      }
      
      return { data: sparklineData, error: null }
    } catch (error) {
      console.error('Sparkline data error:', error)
      return { data: null, error }
    }
  },

  // ==============================================
  // 实时监控数据服务扩展
  // ==============================================

  // 获取实时监控指标
  async getRealtimeMetrics() {
    try {
      const { data, error } = await supabase
        .from('admin_metrics')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(100)
      
      return { data, error }
    } catch (error) {
      console.error('Realtime metrics error:', error)
      return { data: null, error }
    }
  },

  // 插入监控指标数据
  async insertMetric(metricName: string, value: number, unit?: string, tags?: any) {
    try {
      const { data, error } = await supabase
        .from('admin_metrics')
        .insert({
          metric_name: metricName,
          metric_value: value,
          metric_unit: unit,
          tags: tags || {}
        })
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Insert metric error:', error)
      return { data: null, error }
    }
  },

  // 获取系统告警
  async getSystemAlerts(status?: 'active' | 'acknowledged' | 'resolved') {
    try {
      let query = supabase
        .from('admin_alerts')
        .select('*')
        .order('created_at', { ascending: false })

      if (status) {
        query = query.eq('status', status)
      }

      const { data, error } = await query.limit(50)
      return { data, error }
    } catch (error) {
      console.error('System alerts error:', error)
      return { data: null, error }
    }
  },

  // 创建系统告警
  async createAlert(alert: {
    type: string;
    title: string;
    message: string;
    metricName?: string;
    thresholdValue?: number;
    currentValue?: number;
  }) {
    try {
      const { data, error } = await supabase
        .from('admin_alerts')
        .insert({
          alert_type: alert.type,
          title: alert.title,
          message: alert.message,
          metric_name: alert.metricName,
          threshold_value: alert.thresholdValue,
          current_value: alert.currentValue
        })
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Create alert error:', error)
      return { data: null, error }
    }
  },

  // 确认告警
  async acknowledgeAlert(alertId: string, adminId: string) {
    try {
      const { data, error } = await supabase
        .from('admin_alerts')
        .update({
          status: 'acknowledged',
          acknowledged_by: adminId,
          acknowledged_at: new Date().toISOString()
        })
        .eq('id', alertId)
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Acknowledge alert error:', error)
      return { data: null, error }
    }
  },

  // ==============================================
  // 用户批量操作服务
  // ==============================================

  // 获取用户列表（支持筛选和分页）
  async getUsersWithFilters(filters: {
    search?: string;
    status?: string;
    membershipStatus?: string;
    dateRange?: { start: string; end: string };
    page?: number;
    pageSize?: number;
  }) {
    try {
      let query = supabase
        .from('xq_user_profiles')
        .select(`
          id,
          user_id,
          nickname,
          avatar_url,
          account_status,
          is_member,
          membership_expires_at,
          created_at,
          updated_at
        `, { count: 'exact' })

      // 应用筛选条件
      if (filters.search) {
        query = query.or(`nickname.ilike.%${filters.search}%,user_id.ilike.%${filters.search}%`)
      }

      if (filters.status) {
        query = query.eq('account_status', filters.status)
      }

      if (filters.membershipStatus === 'member') {
        query = query.eq('is_member', true)
      } else if (filters.membershipStatus === 'non_member') {
        query = query.eq('is_member', false)
      }

      if (filters.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
      }

      // 分页
      const page = filters.page || 1
      const pageSize = filters.pageSize || 50
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      const { data, error, count } = await query
        .range(from, to)
        .order('created_at', { ascending: false })

      return {
        data,
        error,
        pagination: {
          page,
          pageSize,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / pageSize)
        }
      }
    } catch (error) {
      console.error('Get users with filters error:', error)
      return { data: null, error, pagination: null }
    }
  },

  // 批量更新用户状态
  async batchUpdateUsers(userIds: string[], updates: {
    accountStatus?: string;
    isMember?: boolean;
    tags?: string[];
  }) {
    try {
      const updateData: any = {}
      
      if (updates.accountStatus) {
        updateData.account_status = updates.accountStatus
      }
      
      if (updates.isMember !== undefined) {
        updateData.is_member = updates.isMember
      }

      updateData.updated_at = new Date().toISOString()

      const { data, error } = await supabase
        .from('xq_user_profiles')
        .update(updateData)
        .in('user_id', userIds)
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Batch update users error:', error)
      return { data: null, error }
    }
  },

  // 导出用户数据
  async exportUsers(filters?: {
    search?: string;
    status?: string;
    membershipStatus?: string;
    dateRange?: { start: string; end: string };
  }) {
    try {
      let query = supabase
        .from('xq_user_profiles')
        .select(`
          user_id,
          nickname,
          account_status,
          is_member,
          membership_expires_at,
          created_at
        `)

      // 应用筛选条件（与getUsersWithFilters类似）
      if (filters?.search) {
        query = query.or(`nickname.ilike.%${filters.search}%,user_id.ilike.%${filters.search}%`)
      }

      if (filters?.status) {
        query = query.eq('account_status', filters.status)
      }

      if (filters?.membershipStatus === 'member') {
        query = query.eq('is_member', true)
      } else if (filters?.membershipStatus === 'non_member') {
        query = query.eq('is_member', false)
      }

      if (filters?.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
      }

      const { data, error } = await query
        .order('created_at', { ascending: false })
        .limit(10000) // 限制导出数量

      return { data, error }
    } catch (error) {
      console.error('Export users error:', error)
      return { data: null, error }
    }
  },

  // ==============================================
  // 内容审核服务
  // ==============================================

  // 获取审核记录
  async getModerationRecords(filters?: {
    status?: string;
    contentType?: string;
    reviewerId?: string;
    dateRange?: { start: string; end: string };
    page?: number;
    pageSize?: number;
  }) {
    try {
      let query = supabase
        .from('content_moderation_records')
        .select(`
          *,
          human_reviewer:human_reviewer_id(name),
          appeal_handler:appeal_handled_by(name)
        `, { count: 'exact' })

      // 应用筛选条件
      if (filters?.status) {
        query = query.eq('moderation_result', filters.status)
      }

      if (filters?.contentType) {
        query = query.eq('content_type', filters.contentType)
      }

      if (filters?.reviewerId) {
        query = query.eq('human_reviewer_id', filters.reviewerId)
      }

      if (filters?.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
      }

      // 分页
      const page = filters?.page || 1
      const pageSize = filters?.pageSize || 50
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      const { data, error, count } = await query
        .range(from, to)
        .order('created_at', { ascending: false })

      return {
        data,
        error,
        pagination: {
          page,
          pageSize,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / pageSize)
        }
      }
    } catch (error) {
      console.error('Get moderation records error:', error)
      return { data: null, error, pagination: null }
    }
  },

  // 创建审核记录
  async createModerationRecord(record: {
    contentId: string;
    contentType: string;
    contentSource?: string;
    originalContent?: string;
    moderationResult: string;
    aiConfidence?: number;
    aiReasons?: string[];
    violationTypes?: string[];
    severityLevel?: number;
    autoAction?: string;
  }) {
    try {
      const { data, error } = await supabase
        .from('content_moderation_records')
        .insert({
          content_id: record.contentId,
          content_type: record.contentType,
          content_source: record.contentSource,
          original_content: record.originalContent,
          moderation_result: record.moderationResult,
          ai_confidence: record.aiConfidence,
          ai_reasons: record.aiReasons || [],
          violation_types: record.violationTypes || [],
          severity_level: record.severityLevel || 1,
          auto_action: record.autoAction
        })
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Create moderation record error:', error)
      return { data: null, error }
    }
  },

  // 人工审核处理
  async handleModerationReview(recordId: string, reviewerId: string, result: {
    humanReviewResult: string;
    humanReviewReason?: string;
    violationTypes?: string[];
    severityLevel?: number;
  }) {
    try {
      const { data, error } = await supabase
        .from('content_moderation_records')
        .update({
          human_reviewer_id: reviewerId,
          human_review_result: result.humanReviewResult,
          human_review_reason: result.humanReviewReason,
          violation_types: result.violationTypes,
          severity_level: result.severityLevel,
          reviewed_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', recordId)
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Handle moderation review error:', error)
      return { data: null, error }
    }
  },

  // 获取用户举报
  async getUserReports(filters?: {
    status?: string;
    reportType?: string;
    assignedTo?: string;
    priority?: number;
    page?: number;
    pageSize?: number;
  }) {
    try {
      let query = supabase
        .from('user_reports')
        .select(`
          *,
          assigned_admin:assigned_to(name),
          handler_admin:handled_by(name)
        `, { count: 'exact' })

      // 应用筛选条件
      if (filters?.status) {
        query = query.eq('status', filters.status)
      }

      if (filters?.reportType) {
        query = query.eq('report_type', filters.reportType)
      }

      if (filters?.assignedTo) {
        query = query.eq('assigned_to', filters.assignedTo)
      }

      if (filters?.priority) {
        query = query.eq('priority', filters.priority)
      }

      // 分页
      const page = filters?.page || 1
      const pageSize = filters?.pageSize || 50
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      const { data, error, count } = await query
        .range(from, to)
        .order('priority', { ascending: true })
        .order('created_at', { ascending: false })

      return {
        data,
        error,
        pagination: {
          page,
          pageSize,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / pageSize)
        }
      }
    } catch (error) {
      console.error('Get user reports error:', error)
      return { data: null, error, pagination: null }
    }
  },

  // 处理用户举报
  async handleUserReport(reportId: string, handlerId: string, resolution: {
    status: string;
    handlerNotes?: string;
    resolution?: string;
  }) {
    try {
      const { data, error } = await supabase
        .from('user_reports')
        .update({
          status: resolution.status,
          handler_notes: resolution.handlerNotes,
          resolution: resolution.resolution,
          handled_by: handlerId,
          handled_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', reportId)
        .select()
      
      return { data, error }
    } catch (error) {
      console.error('Handle user report error:', error)
      return { data: null, error }
    }
  },

  // ==============================================
  // 商业化数据服务
  // ==============================================

  // 获取订阅计划
  async getSubscriptionPlans(activeOnly: boolean = true) {
    try {
      let query = supabase
        .from('subscription_plans')
        .select('*')
        .order('sort_order', { ascending: true })

      if (activeOnly) {
        query = query.eq('is_active', true)
      }

      const { data, error } = await query
      return { data, error }
    } catch (error) {
      console.error('Get subscription plans error:', error)
      return { data: null, error }
    }
  },

  // 获取用户订阅记录
  async getUserSubscriptions(filters?: {
    userId?: string;
    planId?: string;
    status?: string;
    page?: number;
    pageSize?: number;
  }) {
    try {
      let query = supabase
        .from('user_subscriptions')
        .select(`
          *,
          plan:plan_id(name, display_name, price, duration_days)
        `, { count: 'exact' })

      // 应用筛选条件
      if (filters?.userId) {
        query = query.eq('user_id', filters.userId)
      }

      if (filters?.planId) {
        query = query.eq('plan_id', filters.planId)
      }

      if (filters?.status) {
        query = query.eq('status', filters.status)
      }

      // 分页
      const page = filters?.page || 1
      const pageSize = filters?.pageSize || 50
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      const { data, error, count } = await query
        .range(from, to)
        .order('created_at', { ascending: false })

      return {
        data,
        error,
        pagination: {
          page,
          pageSize,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / pageSize)
        }
      }
    } catch (error) {
      console.error('Get user subscriptions error:', error)
      return { data: null, error, pagination: null }
    }
  },

  // 获取支付订单
  async getPaymentOrders(filters?: {
    userId?: string;
    status?: string;
    paymentMethod?: string;
    dateRange?: { start: string; end: string };
    page?: number;
    pageSize?: number;
  }) {
    try {
      let query = supabase
        .from('payment_orders')
        .select(`
          *,
          plan:plan_id(name, display_name),
          subscription:subscription_id(status)
        `, { count: 'exact' })

      // 应用筛选条件
      if (filters?.userId) {
        query = query.eq('user_id', filters.userId)
      }

      if (filters?.status) {
        query = query.eq('status', filters.status)
      }

      if (filters?.paymentMethod) {
        query = query.eq('payment_method', filters.paymentMethod)
      }

      if (filters?.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
      }

      // 分页
      const page = filters?.page || 1
      const pageSize = filters?.pageSize || 50
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      const { data, error, count } = await query
        .range(from, to)
        .order('created_at', { ascending: false })

      return {
        data,
        error,
        pagination: {
          page,
          pageSize,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / pageSize)
        }
      }
    } catch (error) {
      console.error('Get payment orders error:', error)
      return { data: null, error, pagination: null }
    }
  },

  // 获取收入统计
  async getRevenueStats(dateRange?: { start: string; end: string }) {
    try {
      let query = supabase
        .from('payment_orders')
        .select('amount, currency, status, paid_at, created_at')
        .eq('status', 'completed')

      if (dateRange) {
        query = query
          .gte('paid_at', dateRange.start)
          .lte('paid_at', dateRange.end)
      }

      const { data, error } = await query
      
      if (error || !data) {
        return { data: null, error }
      }

      // 计算统计数据
      const totalRevenue = data.reduce((sum, order) => sum + (order.amount || 0), 0)
      const orderCount = data.length
      const averageOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0

      // 按日期分组收入
      const dailyRevenue = new Map()
      data.forEach(order => {
        const date = order.paid_at?.split('T')[0]
        if (date) {
          dailyRevenue.set(date, (dailyRevenue.get(date) || 0) + order.amount)
        }
      })

      return {
        data: {
          totalRevenue,
          orderCount,
          averageOrderValue,
          dailyRevenue: Array.from(dailyRevenue.entries()).map(([date, amount]) => ({
            date,
            amount
          })).sort((a, b) => a.date.localeCompare(b.date))
        },
        error: null
      }
    } catch (error) {
      console.error('Get revenue stats error:', error)
      return { data: null, error }
    }
  },

  // 获取当前用户
  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  }
}

export default supabase
