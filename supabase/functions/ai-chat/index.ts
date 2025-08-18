// AI对话处理 Edge Function
// 集成火山引擎大模型API (doubao-1.5-thinking-pro)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

// 火山引擎API配置
const VOLCANO_API_URL = Deno.env.get('VOLCANO_API_URL') || 'https://maas-api.volcengineapi.com/v3/chat/completions'
const VOLCANO_API_KEY = Deno.env.get('VOLCANO_API_KEY')!
const VOLCANO_MODEL = Deno.env.get('VOLCANO_MODEL') || 'doubao-1.5-thinking-pro'

// Supabase配置
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface ChatRequest {
  sessionId?: string
  message: string
  characterId?: string
  stream?: boolean
  temperature?: number
  maxTokens?: number
}

interface ChatResponse {
  sessionId: string
  messageId: string
  content: string
  tokensUsed: number
  cost: number
  error?: string
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
        JSON.stringify({ error: 'Missing authorization header' }),
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
        JSON.stringify({ error: 'Invalid authorization token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 解析请求体
    const requestData: ChatRequest = await req.json()
    const { sessionId, message, characterId, stream = false, temperature = 0.7, maxTokens = 2048 } = requestData

    // 检查用户API配额
    const { data: quota, error: quotaError } = await supabase
      .rpc('check_api_quota', { 
        p_user_id: user.id, 
        p_api_type: 'llm' 
      })

    if (quotaError || !quota?.allowed) {
      return new Response(
        JSON.stringify({ error: 'API quota exceeded', details: quota }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 获取或创建会话
    let currentSessionId = sessionId
    if (!currentSessionId) {
      // 获取AI配置
      const { data: config } = await supabase
        .from('ai_conversation_configs')
        .select('id')
        .eq('is_active', true)
        .eq('provider', 'volcano_engine')
        .single()

      // 创建新会话
      const { data: newSession, error: sessionError } = await supabase
        .from('ai_conversation_sessions')
        .insert({
          user_id: user.id,
          character_id: characterId,
          config_id: config?.id,
          session_title: `对话 - ${new Date().toLocaleString('zh-CN')}`,
          status: 'active'
        })
        .select('id')
        .single()

      if (sessionError) {
        throw new Error(`Failed to create session: ${sessionError.message}`)
      }
      currentSessionId = newSession.id
    }

    // 获取会话上下文
    const { data: recentMessages } = await supabase
      .from('ai_conversation_messages')
      .select('message_type, content')
      .eq('session_id', currentSessionId)
      .order('sequence_number', { ascending: false })
      .limit(10)

    // 构建对话历史
    const messages = [
      // 系统提示词
      {
        role: 'system',
        content: characterId 
          ? await getCharacterPrompt(supabase, characterId)
          : '你是星趣APP的AI助理，专门为用户提供智能、友好、有用的服务。'
      },
      // 历史消息（反转顺序）
      ...recentMessages?.reverse().map(msg => ({
        role: msg.message_type === 'user' ? 'user' : 'assistant',
        content: msg.content
      })) || [],
      // 当前消息
      {
        role: 'user',
        content: message
      }
    ]

    // 保存用户消息
    const { data: userMessage } = await supabase
      .from('ai_conversation_messages')
      .insert({
        session_id: currentSessionId,
        message_type: 'user',
        content: message,
        sequence_number: (recentMessages?.length || 0) + 1
      })
      .select('id, sequence_number')
      .single()

    // 调用火山引擎API
    const volcanoResponse = await fetch(VOLCANO_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${VOLCANO_API_KEY}`,
      },
      body: JSON.stringify({
        model: VOLCANO_MODEL,
        messages,
        temperature,
        max_tokens: maxTokens,
        stream
      })
    })

    if (!volcanoResponse.ok) {
      throw new Error(`Volcano API error: ${volcanoResponse.status}`)
    }

    // 处理流式响应
    if (stream) {
      // 创建流式响应
      const encoder = new TextEncoder()
      const readable = new ReadableStream({
        async start(controller) {
          const reader = volcanoResponse.body?.getReader()
          if (!reader) return

          let fullContent = ''
          let totalTokens = 0

          while (true) {
            const { done, value } = await reader.read()
            if (done) break

            const chunk = new TextDecoder().decode(value)
            const lines = chunk.split('\n').filter(line => line.trim() !== '')

            for (const line of lines) {
              if (line.startsWith('data: ')) {
                const data = line.slice(6)
                if (data === '[DONE]') continue

                try {
                  const parsed = JSON.parse(data)
                  const content = parsed.choices?.[0]?.delta?.content || ''
                  const usage = parsed.usage

                  if (content) {
                    fullContent += content
                    controller.enqueue(encoder.encode(`data: ${JSON.stringify({ content })}\n\n`))
                  }

                  if (usage) {
                    totalTokens = usage.total_tokens || 0
                  }
                } catch (e) {
                  console.error('Parse error:', e)
                }
              }
            }
          }

          // 保存AI响应
          const cost = calculateCost(totalTokens)
          await saveAIResponse(supabase, currentSessionId, fullContent, totalTokens, cost, userMessage.sequence_number + 1)
          
          // 更新使用统计
          await updateUsageStatistics(supabase, user.id, totalTokens, cost)

          // 发送最终响应
          controller.enqueue(encoder.encode(`data: [DONE]\n\n`))
          controller.close()
        }
      })

      return new Response(readable, {
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
        }
      })
    } else {
      // 处理非流式响应
      const responseData = await volcanoResponse.json()
      const content = responseData.choices?.[0]?.message?.content || ''
      const totalTokens = responseData.usage?.total_tokens || 0
      const cost = calculateCost(totalTokens)

      // 保存AI响应
      const { data: aiMessage } = await saveAIResponse(
        supabase, 
        currentSessionId, 
        content, 
        totalTokens, 
        cost, 
        userMessage.sequence_number + 1
      )

      // 更新使用统计
      await updateUsageStatistics(supabase, user.id, totalTokens, cost)

      // 返回响应
      const response: ChatResponse = {
        sessionId: currentSessionId,
        messageId: aiMessage.id,
        content,
        tokensUsed: totalTokens,
        cost
      }

      return new Response(
        JSON.stringify(response),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Chat function error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// 辅助函数：获取角色提示词
async function getCharacterPrompt(supabase: any, characterId: string): Promise<string> {
  const { data } = await supabase
    .from('ai_characters')
    .select('role_prompt, personality, description')
    .eq('id', characterId)
    .single()

  if (data?.role_prompt) {
    return data.role_prompt
  }

  return `你正在扮演${data?.name || '一个AI角色'}。${data?.description || ''} 个性特点：${data?.personality || '友好、智能'}`
}

// 辅助函数：计算成本
function calculateCost(tokens: number): number {
  const costPer1kTokens = 0.002 // 每1000 tokens的成本
  return Math.round(tokens * costPer1kTokens * 100) / 100000 // 保留5位小数
}

// 辅助函数：保存AI响应
async function saveAIResponse(
  supabase: any,
  sessionId: string,
  content: string,
  tokens: number,
  cost: number,
  sequenceNumber: number
) {
  const { data, error } = await supabase
    .from('ai_conversation_messages')
    .insert({
      session_id: sessionId,
      message_type: 'assistant',
      content,
      tokens_used: tokens,
      model_used: VOLCANO_MODEL,
      sequence_number: sequenceNumber
    })
    .select('id')
    .single()

  if (error) {
    throw new Error(`Failed to save AI response: ${error.message}`)
  }

  // 更新会话统计
  await supabase
    .from('ai_conversation_sessions')
    .update({
      total_messages: sequenceNumber,
      total_tokens_used: supabase.sql`total_tokens_used + ${tokens}`,
      total_cost: supabase.sql`total_cost + ${cost}`,
      last_activity_at: new Date().toISOString()
    })
    .eq('id', sessionId)

  return data
}

// 辅助函数：更新使用统计
async function updateUsageStatistics(
  supabase: any,
  userId: string,
  tokens: number,
  cost: number
) {
  await supabase.rpc('update_api_usage_stats', {
    p_user_id: userId,
    p_provider: 'volcano_engine',
    p_api_type: 'llm',
    p_tokens: tokens,
    p_cost: cost,
    p_success: true
  })

  // 更新用户配额
  await supabase
    .from('api_quota_management')
    .update({
      quota_used: supabase.sql`quota_used + 1`,
      quota_remaining: supabase.sql`quota_remaining - 1`
    })
    .eq('user_id', userId)
    .eq('api_type', 'llm')
    .eq('quota_type', 'daily')
}