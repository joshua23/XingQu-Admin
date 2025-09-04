/**
 * API Authentication Utilities
 * 为API路由提供身份验证和授权功能
 */

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { NextRequest } from 'next/server'
import { cookies } from 'next/headers'
import { withRateLimit, rateLimitConfigs, userKeyGenerator, defaultKeyGenerator, RateLimitConfig } from './rateLimiter'

export interface AuthenticatedUser {
  id: string
  email?: string
  role?: string
}

export interface AuthResult {
  user: AuthenticatedUser | null
  error?: string
}

/**
 * 验证API请求的身份
 */
export async function authenticateApiRequest(request: NextRequest): Promise<AuthResult> {
  try {
    // 检查Authorization header
    const authHeader = request.headers.get('authorization')
    if (!authHeader) {
      return { user: null, error: 'Missing authorization header' }
    }

    // 支持Bearer token格式
    const token = authHeader.startsWith('Bearer ') 
      ? authHeader.substring(7)
      : authHeader

    // 使用Supabase验证token
    const supabase = createRouteHandlerClient({ cookies })
    const { data: { user }, error } = await supabase.auth.getUser(token)

    if (error || !user) {
      return { user: null, error: 'Invalid or expired token' }
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.user_metadata?.role || 'user'
      }
    }

  } catch (error) {
    console.error('API authentication error:', error)
    return { user: null, error: 'Authentication failed' }
  }
}

/**
 * 验证管理员权限
 */
export function isAdmin(user: AuthenticatedUser | null): boolean {
  return user?.role === 'admin' || user?.email?.endsWith('@admin.example.com') === true
}

/**
 * 创建认证中间件包装器
 */
export function withAuth(handler: (request: NextRequest, user: AuthenticatedUser) => Promise<Response>) {
  return async (request: NextRequest) => {
    const { user, error } = await authenticateApiRequest(request)
    
    if (!user) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: error || 'Authentication required',
          code: 'UNAUTHORIZED'
        }),
        { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    return handler(request, user)
  }
}

/**
 * 创建管理员认证中间件包装器
 */
export function withAdminAuth(handler: (request: NextRequest, user: AuthenticatedUser) => Promise<Response>) {
  return async (request: NextRequest) => {
    const { user, error } = await authenticateApiRequest(request)
    
    if (!user) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: error || 'Authentication required',
          code: 'UNAUTHORIZED'
        }),
        { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    if (!isAdmin(user)) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Admin access required',
          code: 'FORBIDDEN'
        }),
        { 
          status: 403,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    return handler(request, user)
  }
}

/**
 * 创建可选认证中间件包装器
 * 如果提供了认证信息则验证，否则以匿名用户身份继续
 */
export function withOptionalAuth(
  handler: (request: NextRequest, user: AuthenticatedUser | null) => Promise<Response>
) {
  return async (request: NextRequest) => {
    const authHeader = request.headers.get('authorization')
    
    if (!authHeader) {
      // 没有认证头，以匿名用户身份继续
      return handler(request, null)
    }

    const { user, error } = await authenticateApiRequest(request)
    
    if (error) {
      // 认证失败，返回错误
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: error,
          code: 'INVALID_AUTH'
        }),
        { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    return handler(request, user)
  }
}