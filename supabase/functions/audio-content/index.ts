// 音频内容处理 Edge Function
// 管理音频流媒体配置和播放统计

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

// Supabase配置
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// CDN配置
const CDN_BASE_URL = Deno.env.get('CDN_BASE_URL') || 'https://cdn.xingqu.app'

interface AudioContentRequest {
  action: 'list' | 'detail' | 'play' | 'record_play'
  category?: string
  audioId?: string
  playPosition?: number
  completed?: boolean
  quality?: 'low' | 'medium' | 'high'
  page?: number
  pageSize?: number
}

interface AudioContentResponse {
  success: boolean
  data?: any
  error?: string
}

serve(async (req) => {
  // 处理CORS预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 获取用户信息（支持匿名用户）
    const authHeader = req.headers.get('Authorization')
    let userId: string | null = null

    // 创建Supabase客户端
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      }
    })

    // 如果有认证信息，验证用户
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '')
      const { data: { user } } = await supabase.auth.getUser(token)
      userId = user?.id || null
    }

    // 解析请求
    const requestData: AudioContentRequest = await req.json()
    const { action } = requestData

    let response: AudioContentResponse

    switch (action) {
      case 'list':
        response = await handleListAudioContent(supabase, requestData, userId)
        break

      case 'detail':
        response = await handleAudioDetail(supabase, requestData, userId)
        break

      case 'play':
        response = await handleAudioPlay(supabase, requestData, userId)
        break

      case 'record_play':
        response = await handleRecordPlay(supabase, requestData, userId)
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
    console.error('Audio content function error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// 处理音频内容列表
async function handleListAudioContent(
  supabase: any,
  request: AudioContentRequest,
  userId: string | null
): Promise<AudioContentResponse> {
  const { category, page = 1, pageSize = 20 } = request
  const offset = (page - 1) * pageSize

  // 构建查询
  let query = supabase
    .from('audio_contents')
    .select(`
      id,
      title,
      artist,
      duration_seconds,
      thumbnail_url,
      category,
      is_premium,
      play_count,
      created_at,
      streaming_status,
      audio_metadata,
      play_analytics,
      recommendation_weight
    `)
    .eq('is_public', true)
    .eq('streaming_status', 'ready')

  // 添加分类筛选
  if (category && category !== 'all') {
    query = query.eq('category', category)
  }

  // 排序和分页
  query = query
    .order('recommendation_weight', { ascending: false })
    .order('play_count', { ascending: false })
    .range(offset, offset + pageSize - 1)

  const { data: audioContents, error } = await query

  if (error) {
    return {
      success: false,
      error: error.message
    }
  }

  // 获取用户的播放历史（如果已登录）
  let playHistory = []
  if (userId) {
    const { data } = await supabase
      .from('audio_play_sessions')
      .select('audio_content_id, play_progress_percentage')
      .eq('user_id', userId)
      .eq('completed', false)
      .order('updated_at', { ascending: false })
      .limit(100)

    playHistory = data || []
  }

  // 处理音频内容数据
  const processedContents = audioContents.map(content => {
    const userProgress = playHistory.find(h => h.audio_content_id === content.id)
    
    return {
      ...content,
      streamUrl: `${CDN_BASE_URL}/audio/${content.id}`,
      hasPlayed: !!userProgress,
      playProgress: userProgress?.play_progress_percentage || 0,
      formattedDuration: formatDuration(content.duration_seconds),
      // 从play_analytics中提取统计数据
      stats: {
        totalPlayTime: content.play_analytics?.total_play_time || 0,
        uniqueListeners: content.play_analytics?.unique_listeners || 0,
        completionRate: content.play_analytics?.average_completion_rate || 0
      }
    }
  })

  // 获取总数
  const { count } = await supabase
    .from('audio_contents')
    .select('*', { count: 'exact', head: true })
    .eq('is_public', true)
    .eq('streaming_status', 'ready')

  return {
    success: true,
    data: {
      contents: processedContents,
      pagination: {
        page,
        pageSize,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    }
  }
}

// 处理音频详情
async function handleAudioDetail(
  supabase: any,
  request: AudioContentRequest,
  userId: string | null
): Promise<AudioContentResponse> {
  const { audioId } = request

  if (!audioId) {
    return {
      success: false,
      error: 'Audio ID is required'
    }
  }

  // 获取音频内容详情
  const { data: audioContent, error } = await supabase
    .from('audio_contents')
    .select(`
      *,
      audio_stream_configs (
        stream_url,
        backup_stream_url,
        quality_levels,
        adaptive_streaming,
        cache_policy,
        cdn_enabled,
        cdn_regions
      )
    `)
    .eq('id', audioId)
    .single()

  if (error || !audioContent) {
    return {
      success: false,
      error: 'Audio content not found'
    }
  }

  // 检查用户是否有权限访问高级内容
  if (audioContent.is_premium && userId) {
    const hasAccess = await checkPremiumAccess(supabase, userId)
    if (!hasAccess) {
      return {
        success: false,
        error: 'Premium content requires subscription'
      }
    }
  }

  // 获取流媒体配置
  const streamConfig = audioContent.audio_stream_configs?.[0] || {}
  
  // 构建音频URL（根据用户网络质量选择）
  const qualityLevels = streamConfig.quality_levels || [
    { quality: 'low', bitrate: 64, format: 'mp3' },
    { quality: 'medium', bitrate: 128, format: 'mp3' },
    { quality: 'high', bitrate: 320, format: 'mp3' }
  ]

  return {
    success: true,
    data: {
      ...audioContent,
      streamConfig: {
        primaryUrl: streamConfig.stream_url || `${CDN_BASE_URL}/audio/${audioId}`,
        backupUrl: streamConfig.backup_stream_url,
        qualityLevels,
        adaptiveStreaming: streamConfig.adaptive_streaming || false,
        cdnRegions: streamConfig.cdn_regions || ['cn-north', 'cn-east']
      }
    }
  }
}

// 处理音频播放请求
async function handleAudioPlay(
  supabase: any,
  request: AudioContentRequest,
  userId: string | null
): Promise<AudioContentResponse> {
  const { audioId, quality = 'medium' } = request

  if (!audioId) {
    return {
      success: false,
      error: 'Audio ID is required'
    }
  }

  // 创建播放会话
  const sessionData: any = {
    audio_content_id: audioId,
    user_id: userId,
    quality_level: quality,
    session_start_time: new Date().toISOString(),
    device_type: getDeviceType(request),
    platform: getPlatform(request)
  }

  const { data: playSession, error } = await supabase
    .from('audio_play_sessions')
    .insert(sessionData)
    .select('id')
    .single()

  if (error) {
    return {
      success: false,
      error: 'Failed to create play session'
    }
  }

  // 增加播放计数
  await supabase
    .from('audio_contents')
    .update({
      play_count: supabase.sql`play_count + 1`
    })
    .eq('id', audioId)

  // 获取流媒体URL
  const { data: streamConfig } = await supabase
    .from('audio_stream_configs')
    .select('stream_url, backup_stream_url, quality_levels')
    .eq('audio_content_id', audioId)
    .single()

  // 选择合适质量的流媒体URL
  const qualityConfig = streamConfig?.quality_levels?.find(
    (q: any) => q.quality === quality
  ) || { bitrate: 128 }

  const streamUrl = streamConfig?.stream_url || `${CDN_BASE_URL}/audio/${audioId}`
  const finalUrl = `${streamUrl}?bitrate=${qualityConfig.bitrate}&session=${playSession.id}`

  return {
    success: true,
    data: {
      sessionId: playSession.id,
      streamUrl: finalUrl,
      backupUrl: streamConfig?.backup_stream_url,
      quality: qualityConfig
    }
  }
}

// 记录播放进度
async function handleRecordPlay(
  supabase: any,
  request: AudioContentRequest,
  userId: string | null
): Promise<AudioContentResponse> {
  const { audioId, playPosition = 0, completed = false } = request

  if (!audioId) {
    return {
      success: false,
      error: 'Audio ID is required'
    }
  }

  // 获取音频时长
  const { data: audioContent } = await supabase
    .from('audio_contents')
    .select('duration_seconds')
    .eq('id', audioId)
    .single()

  const progressPercentage = audioContent?.duration_seconds 
    ? Math.min((playPosition / audioContent.duration_seconds) * 100, 100)
    : 0

  // 查找或创建播放会话
  let playSession
  if (userId) {
    // 查找最近的未完成会话
    const { data: existingSession } = await supabase
      .from('audio_play_sessions')
      .select('id')
      .eq('user_id', userId)
      .eq('audio_content_id', audioId)
      .eq('completed', false)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    playSession = existingSession
  }

  if (!playSession) {
    // 创建新会话
    const { data: newSession } = await supabase
      .from('audio_play_sessions')
      .insert({
        user_id: userId,
        audio_content_id: audioId,
        total_play_duration_seconds: playPosition,
        play_progress_percentage: progressPercentage,
        completed
      })
      .select('id')
      .single()

    playSession = newSession
  } else {
    // 更新现有会话
    await supabase
      .from('audio_play_sessions')
      .update({
        total_play_duration_seconds: playPosition,
        play_progress_percentage: progressPercentage,
        completed,
        session_end_time: completed ? new Date().toISOString() : null,
        completion_rate: completed ? 100 : progressPercentage
      })
      .eq('id', playSession.id)
  }

  // 更新音频内容的播放分析
  if (completed) {
    await supabase
      .from('audio_contents')
      .update({
        play_analytics: supabase.sql`
          jsonb_set(
            COALESCE(play_analytics, '{}'::jsonb),
            '{total_play_time}',
            to_jsonb(COALESCE((play_analytics->>'total_play_time')::int, 0) + ${playPosition})
          )
        `
      })
      .eq('id', audioId)
  }

  return {
    success: true,
    data: {
      sessionId: playSession?.id,
      progress: progressPercentage,
      completed
    }
  }
}

// 辅助函数：检查高级内容访问权限
async function checkPremiumAccess(supabase: any, userId: string): Promise<boolean> {
  const { data } = await supabase
    .from('user_memberships')
    .select('plan_id, status')
    .eq('user_id', userId)
    .eq('status', 'active')
    .single()

  if (!data) return false

  // 检查是否为付费会员
  const { data: plan } = await supabase
    .from('subscription_plans')
    .select('plan_type')
    .eq('id', data.plan_id)
    .single()

  return plan?.plan_type !== 'free'
}

// 辅助函数：格式化时长
function formatDuration(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
}

// 辅助函数：获取设备类型
function getDeviceType(request: any): string {
  // 从请求头或用户代理判断设备类型
  return 'mobile' // 简化处理
}

// 辅助函数：获取平台
function getPlatform(request: any): string {
  // 从请求头判断平台
  return 'ios' // 简化处理
}