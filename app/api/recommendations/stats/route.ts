/**
 * 推荐统计API路由
 * GET /api/recommendations/stats - 获取推荐系统统计信息
 */

import { NextRequest, NextResponse } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'

export async function GET(request: NextRequest) {
  try {
    const stats = await recommendationService.getRecommendationStats()

    return NextResponse.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    })

  } catch (error) {
    console.error('推荐统计API错误:', error)
    return NextResponse.json(
      {
        success: false,
        error: '获取推荐统计失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}