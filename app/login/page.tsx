'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/components/providers/AuthProvider'
import { LogIn } from 'lucide-react'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const { signIn } = useAuth()
  const router = useRouter()
  
  // 开发模式检测
  const isDevelopment = process.env.NODE_ENV === 'development' || 
                       (typeof window !== 'undefined' && (
                         window.location.hostname === 'localhost' ||
                         window.location.hostname === '127.0.0.1'
                       ))

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    const result = await signIn(email, password)

    if (result.success) {
      router.push('/dashboard')
    } else {
      setError(result.error || '登录失败')
    }

    setLoading(false)
  }

  // 开发模式快速登录
  const handleDevLogin = async () => {
    console.log('🚀 开发模式快速登录')
    setLoading(true)
    setError('')
    
    try {
      const result = await signIn('', '') // 空账密触发开发模式
      console.log('📝 登录结果:', result)
      
      if (result.success) {
        console.log('✅ 登录成功，跳转到仪表盘')
        router.push('/dashboard')
      } else {
        console.log('❌ 登录失败:', result.error)
        setError(result.error || '登录失败')
      }
    } catch (error) {
      console.error('🔥 登录过程中发生错误:', error)
      setError('登录发生错误: ' + String(error))
    }
    
    setLoading(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
      <div className="max-w-md w-full space-y-8">
        {/* Logo and title */}
        <div className="text-center">
          <div className="w-16 h-16 bg-primary-500 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="text-white text-2xl font-bold">星</span>
          </div>
          <h2 className="text-3xl font-bold text-white">星趣App</h2>
          <p className="text-gray-400 mt-2">后台管理系统</p>
        </div>

        {/* Login form */}
        <div className="bg-gray-800 rounded-lg p-8 border border-gray-700">
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3">
                <p className="text-red-400 text-sm">{error}</p>
              </div>
            )}

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
                邮箱地址
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="admin@example.com"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-300 mb-2">
                密码
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="请输入密码"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-primary-500 hover:bg-primary-600 disabled:bg-primary-500/50 disabled:cursor-not-allowed text-white font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center space-x-2"
            >
              {loading ? (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              ) : (
                <LogIn size={18} />
              )}
              <span>{loading ? '登录中...' : '登录'}</span>
            </button>

            {/* 开发模式快速登录按钮 */}
            {isDevelopment && (
              <button
                type="button"
                onClick={handleDevLogin}
                disabled={loading}
                className="w-full bg-green-600 hover:bg-green-700 disabled:bg-green-600/50 disabled:cursor-not-allowed text-white font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center space-x-2"
              >
                {loading ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                ) : (
                  <span>🚀</span>
                )}
                <span>{loading ? '登录中...' : '开发模式 - 快速登录'}</span>
              </button>
            )}
          </form>
        </div>

        {/* Footer */}
        <div className="text-center text-sm text-gray-400">
          <p>© 2025 星趣App. All rights reserved.</p>
        </div>
      </div>
    </div>
  )
}