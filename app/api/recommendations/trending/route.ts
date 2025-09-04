/**
 * 趋势推荐API路由
 * GET /api/recommendations/trending - 获取热门趋势推荐
 */

import { NextRequest, NextResponse } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams
    const limit = parseInt(searchParams.get('limit') || '10')

    const recommendations = await recommendationService.getTrendingRecommendations(limit)

    return NextResponse.json({
      success: true,
      data: recommendations,
      count: recommendations.length,
      timestamp: new Date().toISOString()
    })

  } catch (error) {
    console.error('趋势推荐API错误:', error)
    return NextResponse.json(
      {
        success: false,
        error: '获取趋势推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}