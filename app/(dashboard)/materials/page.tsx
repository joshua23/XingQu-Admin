'use client'

import React from 'react'
import MaterialManager from '@/components/materials/MaterialManager'

export default function MaterialsPage() {
  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">素材管理</h1>
          <p className="text-muted-foreground">
            管理音频、视频和图片素材，支持上传、分类和批量操作
          </p>
        </div>

        <MaterialManager />
      </div>
    </div>
  )
}