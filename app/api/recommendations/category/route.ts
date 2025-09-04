/**
 * 分类推荐API路由
 * GET /api/recommendations/category - 获取特定分类的推荐
 */

import { NextRequest } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'
import { withOptionalAuth, AuthenticatedUser } from '@/lib/auth/apiAuth'

async function handleGetCategory(request: NextRequest, user: AuthenticatedUser | null) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    const category = searchParams.get('category')
    const limitParam = searchParams.get('limit')

    // 验证分类参数
    if (!category || category.trim().length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: '缺少分类参数',
          code: 'MISSING_CATEGORY'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    const trimmedCategory = category.trim()

    // 验证分类名称长度和格式
    if (trimmedCategory.length > 50) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Category name too long. Maximum 50 characters.',
          code: 'CATEGORY_TOO_LONG'
        }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 验证有效的分类列表
    const validCategories = ['学习教育', '娱乐休闲', '工作助手', '创意制作', '社交聊天', '综合服务']
    if (!validCategories.includes(trimmedCategory)) {
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

    const recommendations = await recommendationService.getCategoryRecommendations(
      trimmedCategory,
      limit
    )

    const response = {
      success: true,
      data: recommendations,
      count: recommendations.length,
      category: trimmedCategory,
      timestamp: new Date().toISOString(),
      ...(user && { authenticated: true, user_id: user.id })
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('分类推荐API错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: '获取分类推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
}

export const GET = withOptionalAuth(handleGetCategory)