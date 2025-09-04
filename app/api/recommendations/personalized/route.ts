/**
 * 个性化推荐API路由
 * GET /api/recommendations/personalized - 获取个性化推荐
 */

import { NextRequest, NextResponse } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    const userId = searchParams.get('user_id')
    const limit = parseInt(searchParams.get('limit') || '10')
    const context = searchParams.get('context') || 'home'

    // 验证必需的用户ID
    if (!userId) {
      return NextResponse.json(
        {
          success: false,
          error: '缺少用户ID参数'
        },
        { status: 400 }
      )
    }

    const recommendations = await recommendationService.getPersonalizedRecommendations(
      userId,
      limit,
      context
    )

    return NextResponse.json({
      success: true,
      data: recommendations,
      count: recommendations.length,
      user_id: userId,
      timestamp: new Date().toISOString()
    })

  } catch (error) {
    console.error('个性化推荐API错误:', error)
    return NextResponse.json(
      {
        success: false,
        error: '获取个性化推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}