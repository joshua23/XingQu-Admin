/**
 * 搜索推荐API路由
 * GET /api/recommendations/search - 基于搜索关键词的推荐
 */

import { NextRequest } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'
import { AuthenticatedUser } from '@/lib/auth/apiAuth'
import { withOptionalAuthAndRateLimit } from '@/lib/auth/rateLimitedAuth'
import { rateLimitConfigs } from '@/lib/auth/rateLimiter'

async function handleGetSearch(request: NextRequest, user: AuthenticatedUser | null) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    const query = searchParams.get('q') || searchParams.get('query')
    const limitParam = searchParams.get('limit')

    // 验证搜索关键词
    if (!query || query.trim().length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: '缺少搜索关键词参数',
          code: 'MISSING_QUERY'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 验证查询长度和内容
    const trimmedQuery = query.trim()
    if (trimmedQuery.length > 100) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Search query too long. Maximum 100 characters.',
          code: 'QUERY_TOO_LONG'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 简单的XSS防护
    if (trimmedQuery.includes('<') || trimmedQuery.includes('>') || trimmedQuery.includes('script')) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Invalid search query format.',
          code: 'INVALID_QUERY'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 输入验证 - limit参数
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

    const recommendations = await recommendationService.getSearchRecommendations(
      trimmedQuery,
      limit
    )

    const response = {
      success: true,
      data: recommendations,
      count: recommendations.length,
      query: trimmedQuery,
      timestamp: new Date().toISOString(),
      ...(user && { authenticated: true, user_id: user.id })
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('搜索推荐API错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: '搜索推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
}

export const GET = withOptionalAuthAndRateLimit(handleGetSearch, rateLimitConfigs.search)