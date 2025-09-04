/**
 * 个性化推荐API路由
 * GET /api/recommendations/personalized - 获取个性化推荐
 * 需要用户认证，确保用户只能访问自己的个性化推荐
 */

import { NextRequest } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'
import { AuthenticatedUser } from '@/lib/auth/apiAuth'
import { withAuthAndRateLimit } from '@/lib/auth/rateLimitedAuth'
import { rateLimitConfigs } from '@/lib/auth/rateLimiter'

async function handleGetPersonalized(request: NextRequest, user: AuthenticatedUser) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    const limitParam = searchParams.get('limit')
    const context = searchParams.get('context') || 'home'

    // 输入验证
    let limit = 10
    if (limitParam) {
      const parsedLimit = parseInt(limitParam)
      if (isNaN(parsedLimit) || parsedLimit < 1 || parsedLimit > 100) {
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Invalid limit parameter. Must be between 1 and 100.',
            code: 'INVALID_PARAMETER'
          }),
          { 
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          }
        )
      }
      limit = parsedLimit
    }

    // 验证context参数
    const validContexts = ['home', 'search', 'category', 'profile']
    if (!validContexts.includes(context)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Invalid context. Must be one of: ${validContexts.join(', ')}`,
          code: 'INVALID_PARAMETER'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 使用认证用户的ID进行个性化推荐
    const recommendations = await recommendationService.getPersonalizedRecommendations(
      user.id,
      limit,
      context
    )

    const response = {
      success: true,
      data: recommendations,
      count: recommendations.length,
      user_id: user.id,
      context: context,
      timestamp: new Date().toISOString()
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('个性化推荐API错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: '获取个性化推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
}

export const GET = withAuthAndRateLimit(handleGetPersonalized, rateLimitConfigs.personalized)