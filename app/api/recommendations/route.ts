/**
 * 智能推荐系统API路由 - 主要推荐接口
 * GET /api/recommendations - 获取综合推荐
 */

import { NextRequest } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'
import { withOptionalAuth, AuthenticatedUser } from '@/lib/auth/apiAuth'

async function handleGetRecommendations(request: NextRequest, user: AuthenticatedUser | null) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    // 解析查询参数
    const category = searchParams.get('category')
    const limitParam = searchParams.get('limit')
    const excludeIds = searchParams.get('exclude_ids')?.split(',').filter(id => id.trim()) || []
    const context = searchParams.get('context') || 'home'

    // 输入验证 - limit参数
    let limit = 20
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

    // 验证category参数（如果提供）
    if (category) {
      const validCategories = ['学习教育', '娱乐休闲', '工作助手', '创意制作', '社交聊天', '综合服务']
      if (!validCategories.includes(category)) {
        return new Response(
          JSON.stringify({
            success: false,
            error: `Invalid category. Must be one of: ${validCategories.join(', ')}`,
            code: 'INVALID_CATEGORY'
          }),
          { 
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          }
        )
      }
    }

    // 验证exclude_ids格式
    if (excludeIds.length > 50) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Too many excluded IDs. Maximum 50 allowed.',
          code: 'TOO_MANY_EXCLUDES'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 获取综合推荐
    const recommendations = await recommendationService.getMixedRecommendations({
      user_id: user?.id,
      category: category || undefined,
      limit,
      exclude_ids: excludeIds,
      context: context as 'home' | 'search' | 'category' | 'profile'
    })

    const response = {
      success: true,
      data: recommendations,
      timestamp: new Date().toISOString(),
      ...(user && { authenticated: true, user_id: user.id })
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('推荐API错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: '获取推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
}

export const GET = withOptionalAuth(handleGetRecommendations)