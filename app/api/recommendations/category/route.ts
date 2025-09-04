/**
 * 分类推荐API路由
 * GET /api/recommendations/category - 获取特定分类的推荐
 */

import { NextRequest, NextResponse } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    const category = searchParams.get('category')
    const limit = parseInt(searchParams.get('limit') || '10')

    // 验证分类参数
    if (!category) {
      return NextResponse.json(
        {
          success: false,
          error: '缺少分类参数'
        },
        { status: 400 }
      )
    }

    const recommendations = await recommendationService.getCategoryRecommendations(
      category,
      limit
    )

    return NextResponse.json({
      success: true,
      data: recommendations,
      count: recommendations.length,
      category: category,
      timestamp: new Date().toISOString()
    })

  } catch (error) {
    console.error('分类推荐API错误:', error)
    return NextResponse.json(
      {
        success: false,
        error: '获取分类推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}