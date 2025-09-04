/**
 * 搜索推荐API路由
 * GET /api/recommendations/search - 基于搜索关键词的推荐
 */

import { NextRequest, NextResponse } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    const query = searchParams.get('q') || searchParams.get('query')
    const limit = parseInt(searchParams.get('limit') || '10')

    // 验证搜索关键词
    if (!query || query.trim().length === 0) {
      return NextResponse.json(
        {
          success: false,
          error: '缺少搜索关键词参数'
        },
        { status: 400 }
      )
    }

    const recommendations = await recommendationService.getSearchRecommendations(
      query.trim(),
      limit
    )

    return NextResponse.json({
      success: true,
      data: recommendations,
      count: recommendations.length,
      query: query.trim(),
      timestamp: new Date().toISOString()
    })

  } catch (error) {
    console.error('搜索推荐API错误:', error)
    return NextResponse.json(
      {
        success: false,
        error: '搜索推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}