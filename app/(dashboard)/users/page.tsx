/**
 * 星趣后台管理系统 - 增强用户管理页面
 * 集成新的EnhancedUserManager组件
 * Created: 2025-09-05
 */

'use client'

import React from 'react'
import EnhancedUserManager from '@/components/users/EnhancedUserManager'

export default function UsersPage() {
  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">用户管理</h1>
          <p className="text-muted-foreground">
            管理系统用户、批量操作、统计分析和数据导出
          </p>
        </div>

        <EnhancedUserManager />
      </div>
    </div>
  )
}