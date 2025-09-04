/**
 * 趋势推荐API路由
 * GET /api/recommendations/trending - 获取热门趋势推荐
 */

import { NextRequest } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'
import { withOptionalAuth, AuthenticatedUser } from '@/lib/auth/apiAuth'
import { sanitizeRecommendationResults } from '@/lib/utils/dataSanitization'

async function handleGetTrending(request: NextRequest, user: AuthenticatedUser | null) {
  try {
    const searchParams = request.nextUrl.searchParams
    const limitParam = searchParams.get('limit')
    
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

    const recommendations = await recommendationService.getTrendingRecommendations(limit)

    // 清理敏感数据
    const sanitizedRecommendations = sanitizeRecommendationResults(recommendations, !!user)

    const response = {
      success: true,
      data: sanitizedRecommendations,
      count: sanitizedRecommendations.length,
      timestamp: new Date().toISOString(),
      ...(user && { authenticated: true, user_id: user.id })
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('趋势推荐API错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: '获取趋势推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
}

export const GET = withOptionalAuth(handleGetTrending)