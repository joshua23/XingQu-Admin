/**
 * 智能推荐系统API路由 - 主要推荐接口
 * GET /api/recommendations - 获取综合推荐
 */

import { NextRequest, NextResponse } from 'next/server'
import { recommendationService } from '@/lib/services/recommendationService'

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams
    
    // 解析查询参数
    const userId = searchParams.get('user_id')
    const category = searchParams.get('category')
    const limit = parseInt(searchParams.get('limit') || '20')
    const excludeIds = searchParams.get('exclude_ids')?.split(',') || []
    const context = searchParams.get('context') || 'home'

    // 获取综合推荐
    const recommendations = await recommendationService.getMixedRecommendations({
      user_id: userId || undefined,
      category: category || undefined,
      limit,
      exclude_ids: excludeIds,
      context: context as 'home' | 'search' | 'category' | 'profile'
    })

    return NextResponse.json({
      success: true,
      data: recommendations,
      timestamp: new Date().toISOString()
    })

  } catch (error) {
    console.error('推荐API错误:', error)
    return NextResponse.json(
      {
        success: false,
        error: '获取推荐失败',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}