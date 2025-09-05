'use client'

import React from 'react'
import RecommendationManager from '@/components/recommendations/RecommendationManager'

export default function RecommendationsPage() {
  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">智能推荐系统</h1>
          <p className="text-muted-foreground">
            管理智能体推荐算法和API接口，为Flutter App提供个性化推荐服务
          </p>
        </div>

        <RecommendationManager />
      </div>
    </div>
  )
}