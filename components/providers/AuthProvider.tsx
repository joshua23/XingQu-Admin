'use client'

import React, { createContext, useContext, useEffect, useState } from 'react'
import { User } from '@/lib/types'
import { adminAuth } from '@/lib/services/supabase'

interface AuthContextType {
  user: User | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // 检查开发模式
    const isDevelopment = process.env.NODE_ENV === 'development'
    
    if (isDevelopment) {
      // 开发模式下检查本地存储的开发用户
      const devUser = localStorage.getItem('dev_admin_user')
      if (devUser) {
        setUser(JSON.parse(devUser))
        setLoading(false)
        return
      }
    }

    // 检查当前用户
    checkUser()

    // 监听认证状态变化
    const { data: { subscription } } = adminAuth.supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (session?.user) {
          setUser({
            id: session.user.id,
            user_id: session.user.id,
            nickname: session.user.user_metadata?.name || session.user.email,
            avatar_url: session.user.user_metadata?.avatar_url,
            created_at: session.user.created_at,
            updated_at: session.user.updated_at,
            account_status: 'active',
            is_member: false
          })
        } else {
          setUser(null)
        }
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const checkUser = async () => {
    try {
      const user = await adminAuth.getCurrentUser()
      if (user) {
        setUser({
          id: user.id,
          user_id: user.id,
          nickname: user.user_metadata?.name || user.email,
          avatar_url: user.user_metadata?.avatar_url,
          created_at: user.created_at,
          updated_at: user.updated_at,
          account_status: 'active',
          is_member: false
        })
      }
    } catch (error) {
      console.error('Error checking user:', error)
    } finally {
      setLoading(false)
    }
  }

  const signIn = async (email: string, password: string) => {
    try {
      // 开发模式支持空账密登录 - 使用多种方式检测开发模式
      const isDevelopment = process.env.NODE_ENV === 'development' || 
                           window.location.hostname === 'localhost' ||
                           window.location.hostname === '127.0.0.1'
      console.log('🚀 开发模式检查:', { 
        nodeEnv: process.env.NODE_ENV, 
        hostname: window.location.hostname,
        isDevelopment, 
        email, 
        password 
      })
      
      if (isDevelopment && (!email || !password)) {
        console.log('✅ 触发开发模式快速登录')
        const devUser = {
          id: 'dev-admin-001',
          user_id: 'dev-admin-001',
          nickname: '开发管理员',
          avatar_url: undefined,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          account_status: 'active' as const,
          is_member: false
        }
        localStorage.setItem('dev_admin_user', JSON.stringify(devUser))
        
        // 设置cookie供middleware使用
        document.cookie = `dev_admin_user=${JSON.stringify(devUser)}; path=/; max-age=86400`
        
        setUser(devUser)
        console.log('✅ 开发模式登录完成:', devUser)
        return { success: true }
      }

      const { error } = await adminAuth.signIn(email, password)
      if (error) {
        return { success: false, error: error.message }
      }
      return { success: true }
    } catch (error) {
      return { success: false, error: '登录失败，请重试' }
    }
  }

  const signOut = async () => {
    try {
      // 清除开发模式用户数据
      const isDevelopment = process.env.NODE_ENV === 'development' || 
                           (typeof window !== 'undefined' && (
                             window.location.hostname === 'localhost' ||
                             window.location.hostname === '127.0.0.1'
                           ))
      
      if (isDevelopment) {
        localStorage.removeItem('dev_admin_user')
        // 清除开发模式cookie
        document.cookie = 'dev_admin_user=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT'
      }
      
      await adminAuth.signOut()
      setUser(null)
    } catch (error) {
      console.error('Error signing out:', error)
    }
  }

  const value = {
    user,
    loading,
    signIn,
    signOut
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}