/**
 * 推荐统计API路由
 * GET /api/recommendations/stats - 获取推荐系统统计信息
 */

import { NextRequest } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'
import { withOptionalAuth, AuthenticatedUser } from '@/lib/auth/apiAuth'
import { sanitizeStats } from '@/lib/utils/dataSanitization'

async function handleGetStats(request: NextRequest, user: AuthenticatedUser | null) {
  try {
    const stats = await recommendationService.getRecommendationStats()

    // 清理敏感统计数据
    const sanitizedStats = sanitizeStats(stats, !!user)

    // 根据用户身份返回不同级别的数据
    const response = {
      success: true,
      data: sanitizedStats,
      timestamp: new Date().toISOString(),
      ...(user && { authenticated: true, user_id: user.id })
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('推荐统计API错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: '获取推荐统计失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
}

export const GET = withOptionalAuth(handleGetStats)