'use client'

import { useAuth } from '@/components/providers/AuthProvider'
import { useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

export default function Home() {
  const { user, loading } = useAuth()
  const router = useRouter()
  const [redirecting, setRedirecting] = useState(false)

  useEffect(() => {
    console.log('🏠 根页面状态:', { user: !!user, loading, redirecting })
    
    if (!loading && !redirecting) {
      setRedirecting(true)
      
      if (user) {
        console.log('✅ 用户已认证，重定向到仪表盘')
        router.push('/dashboard')
      } else {
        console.log('❌ 用户未认证，重定向到登录页面')
        router.push('/login')
      }
    }
  }, [user, loading, redirecting, router])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">正在加载...</p>
        </div>
      </div>
    )
  }

  if (redirecting) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">正在跳转...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-2xl font-bold mb-4">星趣后台管理系统</h1>
        <p className="text-muted-foreground mb-4">正在初始化...</p>
        <div className="space-x-4">
          <button 
            onClick={() => router.push('/login')}
            className="px-4 py-2 bg-primary text-primary-foreground rounded hover:bg-primary/90"
          >
            前往登录
          </button>
          <button 
            onClick={() => router.push('/dashboard')}
            className="px-4 py-2 bg-secondary text-secondary-foreground rounded hover:bg-secondary/90"
          >
            前往仪表盘
          </button>
        </div>
      </div>
    </div>
  )
}