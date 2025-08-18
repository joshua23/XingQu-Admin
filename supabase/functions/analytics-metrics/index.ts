import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MetricsRequest {
  metric_type: 'dau' | 'revenue' | 'retention' | 'funnel' | 'user_segments'
  date_range?: {
    start_date: string
    end_date: string
  }
  filters?: {
    user_segment?: string
    platform?: string
    channel?: string
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { metric_type, date_range, filters }: MetricsRequest = await req.json()

    let result
    
    switch (metric_type) {
      case 'dau':
        result = await calculateDAU(supabaseClient, date_range, filters)
        break
      case 'revenue':
        result = await calculateRevenue(supabaseClient, date_range, filters)
        break
      case 'retention':
        result = await calculateRetention(supabaseClient, date_range)
        break
      case 'funnel':
        result = await calculateFunnel(supabaseClient, date_range)
        break
      case 'user_segments':
        result = await getUserSegments(supabaseClient, filters)
        break
      default:
        throw new Error(`Unsupported metric type: ${metric_type}`)
    }

    return new Response(
      JSON.stringify({ success: true, data: result }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Metrics calculation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to calculate metrics', details: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// DAU计算 - 基于现有user_analytics表
async function calculateDAU(supabaseClient: any, dateRange?: any, filters?: any) {
  const endDate = dateRange?.end_date || new Date().toISOString().split('T')[0]
  const startDate = dateRange?.start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

  // 基于现有user_analytics表计算DAU
  const { data, error } = await supabaseClient
    .from('user_analytics')
    .select('user_id, created_at')
    .gte('created_at', startDate)
    .lte('created_at', endDate + ' 23:59:59')

  if (error) throw error

  // 按日期分组计算每日活跃用户
  const dailyActiveUsers: Record<string, Set<string>> = {}
  
  data.forEach(record => {
    const date = record.created_at.split('T')[0]
    if (!dailyActiveUsers[date]) {
      dailyActiveUsers[date] = new Set()
    }
    dailyActiveUsers[date].add(record.user_id)
  })

  // 转换为图表数据格式
  const chartData = Object.entries(dailyActiveUsers).map(([date, userSet]) => ({
    date,
    dau: userSet.size,
    users: Array.from(userSet)
  })).sort((a, b) => a.date.localeCompare(b.date))

  return {
    metric_name: 'Daily Active Users',
    time_range: { start_date: startDate, end_date: endDate },
    total_days: chartData.length,
    average_dau: Math.round(chartData.reduce((sum, day) => sum + day.dau, 0) / chartData.length),
    peak_dau: Math.max(...chartData.map(day => day.dau)),
    chart_data: chartData
  }
}

// 收入指标计算 - 基于现有payment_orders表
async function calculateRevenue(supabaseClient: any, dateRange?: any, filters?: any) {
  const endDate = dateRange?.end_date || new Date().toISOString().split('T')[0]
  const startDate = dateRange?.start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

  const { data, error } = await supabaseClient
    .from('payment_orders')
    .select('amount, created_at, status, payment_provider')
    .eq('status', 'completed')
    .gte('created_at', startDate)
    .lte('created_at', endDate + ' 23:59:59')

  if (error) throw error

  // 按日期分组计算收入
  const dailyRevenue: Record<string, number> = {}
  let totalRevenue = 0

  data.forEach(order => {
    const date = order.created_at.split('T')[0]
    const amount = parseFloat(order.amount) || 0
    
    if (!dailyRevenue[date]) {
      dailyRevenue[date] = 0
    }
    dailyRevenue[date] += amount
    totalRevenue += amount
  })

  const chartData = Object.entries(dailyRevenue).map(([date, revenue]) => ({
    date,
    revenue: Math.round(revenue * 100) / 100, // 保留两位小数
    orders: data.filter(order => order.created_at.startsWith(date)).length
  })).sort((a, b) => a.date.localeCompare(b.date))

  return {
    metric_name: 'Daily Revenue',
    time_range: { start_date: startDate, end_date: endDate },
    total_revenue: Math.round(totalRevenue * 100) / 100,
    total_orders: data.length,
    average_daily_revenue: Math.round((totalRevenue / chartData.length) * 100) / 100,
    chart_data: chartData
  }
}

// 用户留存计算
async function calculateRetention(supabaseClient: any, dateRange?: any) {
  // 基于用户注册日期和后续活跃情况计算留存
  const cohortDate = dateRange?.start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

  // 获取队列用户（特定日期注册的用户）
  const { data: cohortUsers, error: cohortError } = await supabaseClient
    .from('users')
    .select('id, created_at')
    .gte('created_at', cohortDate)
    .lt('created_at', cohortDate + ' 23:59:59')

  if (cohortError) throw cohortError

  if (cohortUsers.length === 0) {
    return { metric_name: 'User Retention', cohort_size: 0, retention_data: [] }
  }

  // 计算不同天数的留存率
  const retentionDays = [1, 3, 7, 14, 30]
  const retentionData = []

  for (const day of retentionDays) {
    const targetDate = new Date(new Date(cohortDate).getTime() + day * 24 * 60 * 60 * 1000)
    const targetDateStr = targetDate.toISOString().split('T')[0]

    // 查询在目标日期有活动的队列用户
    const { data: activeUsers, error: activeError } = await supabaseClient
      .from('user_analytics')
      .select('user_id')
      .in('user_id', cohortUsers.map(u => u.id))
      .gte('created_at', targetDateStr)
      .lt('created_at', targetDateStr + ' 23:59:59')

    if (activeError) throw activeError

    const uniqueActiveUsers = new Set(activeUsers.map(u => u.user_id))
    const retentionRate = (uniqueActiveUsers.size / cohortUsers.length) * 100

    retentionData.push({
      day: `Day ${day}`,
      retained_users: uniqueActiveUsers.size,
      retention_rate: Math.round(retentionRate * 100) / 100
    })
  }

  return {
    metric_name: 'User Retention',
    cohort_date: cohortDate,
    cohort_size: cohortUsers.length,
    retention_data: retentionData
  }
}

// AARRR漏斗分析
async function calculateFunnel(supabaseClient: any, dateRange?: any) {
  const endDate = dateRange?.end_date || new Date().toISOString().split('T')[0]
  const startDate = dateRange?.start_date || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

  // 获取总用户数（获取 - Acquisition）
  const { count: totalUsers } = await supabaseClient
    .from('users')
    .select('*', { count: 'exact', head: true })
    .gte('created_at', startDate)
    .lte('created_at', endDate + ' 23:59:59')

  // 活跃用户数（激活 - Activation）
  const { data: activeUsersData } = await supabaseClient
    .from('user_analytics')
    .select('user_id')
    .gte('created_at', startDate)
    .lte('created_at', endDate + ' 23:59:59')

  const activeUsers = new Set(activeUsersData?.map(u => u.user_id) || []).size

  // 付费用户数（收入 - Revenue）
  const { data: payingUsersData } = await supabaseClient
    .from('payment_orders')
    .select('user_id')
    .eq('status', 'completed')
    .gte('created_at', startDate)
    .lte('created_at', endDate + ' 23:59:59')

  const payingUsers = new Set(payingUsersData?.map(o => o.user_id) || []).size

  // 构建漏斗数据
  const funnelData = [
    { step: 'Acquisition', users: totalUsers || 0, rate: 100 },
    { step: 'Activation', users: activeUsers, rate: totalUsers ? Math.round((activeUsers / totalUsers) * 10000) / 100 : 0 },
    { step: 'Revenue', users: payingUsers, rate: totalUsers ? Math.round((payingUsers / totalUsers) * 10000) / 100 : 0 }
  ]

  return {
    metric_name: 'AARRR Funnel',
    time_range: { start_date: startDate, end_date: endDate },
    funnel_data: funnelData,
    conversion_rates: {
      acquisition_to_activation: funnelData[1].rate,
      activation_to_revenue: activeUsers ? Math.round((payingUsers / activeUsers) * 10000) / 100 : 0
    }
  }
}

// 用户分层数据
async function getUserSegments(supabaseClient: any, filters?: any) {
  // 基于用户会员等级和活跃度进行分层
  const { data: membershipData, error } = await supabaseClient
    .from('user_memberships')
    .select(`
      user_id,
      plan_id,
      subscription_plans (plan_name, plan_type),
      status,
      created_at
    `)
    .eq('status', 'active')

  if (error) throw error

  // 统计各会员等级用户数
  const segments: Record<string, number> = {
    'Free Users': 0,
    'Basic Members': 0,
    'Premium Members': 0,
    'VIP Members': 0
  }

  membershipData?.forEach(membership => {
    const planName = membership.subscription_plans?.plan_name || 'Free'
    if (planName.toLowerCase().includes('basic')) {
      segments['Basic Members']++
    } else if (planName.toLowerCase().includes('premium')) {
      segments['Premium Members']++
    } else if (planName.toLowerCase().includes('vip')) {
      segments['VIP Members']++
    } else {
      segments['Free Users']++
    }
  })

  // 获取总用户数来计算免费用户
  const { count: totalUsers } = await supabaseClient
    .from('users')
    .select('*', { count: 'exact', head: true })

  const paidUsers = Object.values(segments).reduce((sum, count) => sum + count, 0)
  segments['Free Users'] = (totalUsers || 0) - paidUsers

  const segmentData = Object.entries(segments).map(([segment, count]) => ({
    segment,
    user_count: count,
    percentage: totalUsers ? Math.round((count / totalUsers) * 10000) / 100 : 0
  }))

  return {
    metric_name: 'User Segments',
    total_users: totalUsers || 0,
    segments: segmentData
  }
}