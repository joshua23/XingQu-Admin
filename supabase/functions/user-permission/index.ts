// 用户权限验证 Edge Function
// 管理用户会员权限和API配额

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

// Supabase配置
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface PermissionRequest {
  action: 'check' | 'update_quota' | 'get_usage' | 'verify_feature'
  apiType?: 'llm' | 'tts' | 'asr' | 'image_gen'
  feature?: string
  quotaType?: 'daily' | 'monthly' | 'total'
}

interface PermissionResponse {
  success: boolean
  allowed?: boolean
  data?: any
  error?: string
}

interface UserPermissions {
  membership: {
    planType: string
    status: string
    expiresAt: string | null
  }
  features: {
    aiChatUnlimited: boolean
    voiceInteraction: boolean
    imageGeneration: boolean
    customAgents: boolean
    premiumModels: boolean
  }
  quotas: {
    llm: QuotaInfo
    tts: QuotaInfo
    asr: QuotaInfo
    imageGen: QuotaInfo
  }
  usage: {
    today: UsageStats
    thisMonth: UsageStats
  }
}

interface QuotaInfo {
  limit: number
  used: number
  remaining: number
  resetAt: string
}

interface UsageStats {
  apiCalls: number
  totalCost: number
  tokensUsed: number
}

serve(async (req) => {
  // 处理CORS预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 验证用户身份
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 创建Supabase客户端
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      }
    })

    // 验证JWT并获取用户信息
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid authorization token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 解析请求
    const requestData: PermissionRequest = await req.json()
    const { action } = requestData

    let response: PermissionResponse

    switch (action) {
      case 'check':
        response = await handleCheckPermission(supabase, user.id, requestData)
        break

      case 'update_quota':
        response = await handleUpdateQuota(supabase, user.id, requestData)
        break

      case 'get_usage':
        response = await handleGetUsage(supabase, user.id, requestData)
        break

      case 'verify_feature':
        response = await handleVerifyFeature(supabase, user.id, requestData)
        break

      default:
        response = {
          success: false,
          error: 'Invalid action'
        }
    }

    return new Response(
      JSON.stringify(response),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Permission function error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// 处理权限检查
async function handleCheckPermission(
  supabase: any,
  userId: string,
  request: PermissionRequest
): Promise<PermissionResponse> {
  const { apiType } = request

  // 获取完整的用户权限信息
  const permissions = await getUserPermissions(supabase, userId)

  // 如果请求特定API类型的权限
  if (apiType) {
    const quotaInfo = await checkApiQuota(supabase, userId, apiType)
    const hasFeatureAccess = checkFeatureAccess(permissions.features, apiType)

    return {
      success: true,
      allowed: hasFeatureAccess && quotaInfo.allowed,
      data: {
        feature: hasFeatureAccess,
        quota: quotaInfo,
        permissions: permissions
      }
    }
  }

  // 返回完整权限信息
  return {
    success: true,
    data: permissions
  }
}

// 处理配额更新
async function handleUpdateQuota(
  supabase: any,
  userId: string,
  request: PermissionRequest
): Promise<PermissionResponse> {
  const { apiType, quotaType = 'daily' } = request

  if (!apiType) {
    return {
      success: false,
      error: 'API type is required'
    }
  }

  // 检查是否需要重置配额
  const { data: currentQuota } = await supabase
    .from('api_quota_management')
    .select('*')
    .eq('user_id', userId)
    .eq('api_type', apiType)
    .eq('quota_type', quotaType)
    .single()

  if (currentQuota && new Date(currentQuota.next_reset_at) <= new Date()) {
    // 重置配额
    const { error } = await supabase
      .from('api_quota_management')
      .update({
        quota_used: 0,
        quota_remaining: currentQuota.quota_limit,
        last_reset_at: new Date().toISOString(),
        next_reset_at: calculateNextResetTime(quotaType)
      })
      .eq('id', currentQuota.id)

    if (error) {
      return {
        success: false,
        error: 'Failed to reset quota'
      }
    }

    return {
      success: true,
      data: {
        reset: true,
        newQuota: {
          limit: currentQuota.quota_limit,
          used: 0,
          remaining: currentQuota.quota_limit
        }
      }
    }
  }

  return {
    success: true,
    data: {
      reset: false,
      currentQuota
    }
  }
}

// 处理使用量查询
async function handleGetUsage(
  supabase: any,
  userId: string,
  request: PermissionRequest
): Promise<PermissionResponse> {
  // 获取今日使用统计
  const { data: todayStats } = await supabase
    .from('api_usage_statistics')
    .select('api_type, request_count, tokens_used, cost_amount')
    .eq('user_id', userId)
    .eq('usage_date', new Date().toISOString().split('T')[0])

  // 获取本月使用统计
  const startOfMonth = new Date()
  startOfMonth.setDate(1)
  startOfMonth.setHours(0, 0, 0, 0)

  const { data: monthStats } = await supabase
    .from('api_usage_statistics')
    .select('api_type, request_count, tokens_used, cost_amount')
    .eq('user_id', userId)
    .gte('usage_date', startOfMonth.toISOString().split('T')[0])

  // 汇总统计数据
  const todaySummary = summarizeUsage(todayStats || [])
  const monthSummary = summarizeUsage(monthStats || [])

  // 获取各API类型的详细统计
  const apiTypeStats = groupByApiType(monthStats || [])

  return {
    success: true,
    data: {
      today: todaySummary,
      thisMonth: monthSummary,
      byApiType: apiTypeStats,
      details: {
        todayDetails: todayStats,
        monthDetails: monthStats
      }
    }
  }
}

// 处理功能验证
async function handleVerifyFeature(
  supabase: any,
  userId: string,
  request: PermissionRequest
): Promise<PermissionResponse> {
  const { feature } = request

  if (!feature) {
    return {
      success: false,
      error: 'Feature name is required'
    }
  }

  // 获取用户会员信息
  const { data: membership } = await supabase
    .from('user_memberships')
    .select(`
      *,
      subscription_plans (
        plan_name,
        plan_type,
        features
      )
    `)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single()

  if (!membership) {
    // 免费用户权限
    const freeFeatures = ['basic_chat', 'public_content']
    return {
      success: true,
      allowed: freeFeatures.includes(feature),
      data: {
        feature,
        membershipType: 'free',
        hasAccess: freeFeatures.includes(feature)
      }
    }
  }

  // 检查功能权限
  const featurePermissions = membership.feature_permissions || {}
  const planFeatures = membership.subscription_plans?.features || []

  const hasAccess = featurePermissions[feature] === true || 
                   planFeatures.includes(feature)

  return {
    success: true,
    allowed: hasAccess,
    data: {
      feature,
      membershipType: membership.subscription_plans?.plan_type,
      planName: membership.subscription_plans?.plan_name,
      hasAccess,
      expiresAt: membership.expires_at
    }
  }
}

// 辅助函数：获取完整用户权限
async function getUserPermissions(supabase: any, userId: string): Promise<UserPermissions> {
  // 获取会员信息
  const { data: membership } = await supabase
    .from('user_memberships')
    .select(`
      *,
      subscription_plans (
        plan_name,
        plan_type
      )
    `)
    .eq('user_id', userId)
    .eq('status', 'active')
    .single()

  // 获取API配额
  const { data: quotas } = await supabase
    .from('api_quota_management')
    .select('*')
    .eq('user_id', userId)
    .eq('quota_type', 'daily')
    .eq('is_active', true)

  // 获取今日使用统计
  const { data: todayUsage } = await supabase
    .from('api_usage_statistics')
    .select('request_count, tokens_used, cost_amount')
    .eq('user_id', userId)
    .eq('usage_date', new Date().toISOString().split('T')[0])

  // 构建权限对象
  const permissions: UserPermissions = {
    membership: {
      planType: membership?.subscription_plans?.plan_type || 'free',
      status: membership?.status || 'inactive',
      expiresAt: membership?.expires_at || null
    },
    features: {
      aiChatUnlimited: membership?.feature_permissions?.ai_chat_unlimited || false,
      voiceInteraction: membership?.feature_permissions?.voice_interaction || false,
      imageGeneration: membership?.feature_permissions?.image_generation || false,
      customAgents: membership?.feature_permissions?.custom_agents || false,
      premiumModels: membership?.feature_permissions?.premium_models || false
    },
    quotas: {
      llm: getQuotaInfo(quotas, 'llm', membership),
      tts: getQuotaInfo(quotas, 'tts', membership),
      asr: getQuotaInfo(quotas, 'asr', membership),
      imageGen: getQuotaInfo(quotas, 'image_gen', membership)
    },
    usage: {
      today: summarizeUsage(todayUsage || []),
      thisMonth: { apiCalls: 0, totalCost: 0, tokensUsed: 0 } // 简化处理
    }
  }

  return permissions
}

// 辅助函数：检查API配额
async function checkApiQuota(
  supabase: any,
  userId: string,
  apiType: string
): Promise<any> {
  const { data } = await supabase.rpc('check_api_quota', {
    p_user_id: userId,
    p_api_type: apiType
  })

  return data || { allowed: false, quota_remaining: 0 }
}

// 辅助函数：检查功能访问权限
function checkFeatureAccess(features: any, apiType: string): boolean {
  switch (apiType) {
    case 'llm':
      return true // 基础对话都允许
    case 'tts':
    case 'asr':
      return features.voiceInteraction
    case 'image_gen':
      return features.imageGeneration
    default:
      return false
  }
}

// 辅助函数：获取配额信息
function getQuotaInfo(quotas: any[], apiType: string, membership: any): QuotaInfo {
  const quota = quotas?.find(q => q.api_type === apiType)
  
  if (quota) {
    return {
      limit: quota.quota_limit,
      used: quota.quota_used,
      remaining: quota.quota_remaining,
      resetAt: quota.next_reset_at
    }
  }

  // 默认配额（根据会员类型）
  const defaultQuotas: any = {
    free: { llm: 10, tts: 0, asr: 0, image_gen: 0 },
    basic: { llm: 100, tts: 30, asr: 30, image_gen: 10 },
    premium: { llm: -1, tts: -1, asr: -1, image_gen: 50 }
  }

  const planType = membership?.subscription_plans?.plan_type || 'free'
  const limit = defaultQuotas[planType]?.[apiType] || 0

  return {
    limit,
    used: 0,
    remaining: limit,
    resetAt: calculateNextResetTime('daily')
  }
}

// 辅助函数：计算下次重置时间
function calculateNextResetTime(quotaType: string): string {
  const now = new Date()
  let resetTime = new Date()

  switch (quotaType) {
    case 'daily':
      resetTime.setDate(now.getDate() + 1)
      resetTime.setHours(0, 0, 0, 0)
      break
    case 'monthly':
      resetTime.setMonth(now.getMonth() + 1)
      resetTime.setDate(1)
      resetTime.setHours(0, 0, 0, 0)
      break
    default:
      resetTime = now
  }

  return resetTime.toISOString()
}

// 辅助函数：汇总使用统计
function summarizeUsage(stats: any[]): UsageStats {
  return stats.reduce((acc, stat) => {
    acc.apiCalls += stat.request_count || 0
    acc.totalCost += parseFloat(stat.cost_amount || 0)
    acc.tokensUsed += stat.tokens_used || 0
    return acc
  }, { apiCalls: 0, totalCost: 0, tokensUsed: 0 })
}

// 辅助函数：按API类型分组
function groupByApiType(stats: any[]): any {
  return stats.reduce((acc, stat) => {
    if (!acc[stat.api_type]) {
      acc[stat.api_type] = {
        requests: 0,
        tokens: 0,
        cost: 0
      }
    }
    acc[stat.api_type].requests += stat.request_count || 0
    acc[stat.api_type].tokens += stat.tokens_used || 0
    acc[stat.api_type].cost += parseFloat(stat.cost_amount || 0)
    return acc
  }, {})
}