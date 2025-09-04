/**
 * Rate Limited Authentication Utilities
 * 提供带速率限制的认证中间件
 */

import { NextRequest } from 'next/server'
import { withAuth, withOptionalAuth, withAdminAuth, AuthenticatedUser } from './apiAuth'
import { withRateLimit, rateLimitConfigs, userKeyGenerator, defaultKeyGenerator, RateLimitConfig } from './rateLimiter'

/**
 * 创建带速率限制的认证中间件
 */
export function withAuthAndRateLimit(
  handler: (request: NextRequest, user: AuthenticatedUser) => Promise<Response>,
  rateLimitConfig: RateLimitConfig = rateLimitConfigs.standard
) {
  const authHandler = withAuth(handler)
  
  return withRateLimit({
    ...rateLimitConfig,
    keyGenerator: (request: NextRequest) => {
      // 尝试从认证中获取用户信息用于个性化限制
      const authHeader = request.headers.get('authorization')
      if (authHeader) {
        return userKeyGenerator(request, authHeader) // 使用token作为用户标识
      }
      return defaultKeyGenerator(request)
    }
  }, authHandler)
}

/**
 * 创建带速率限制的可选认证中间件
 */
export function withOptionalAuthAndRateLimit(
  handler: (request: NextRequest, user: AuthenticatedUser | null) => Promise<Response>,
  rateLimitConfig: RateLimitConfig = rateLimitConfigs.standard
) {
  const authHandler = withOptionalAuth(handler)
  
  return withRateLimit({
    ...rateLimitConfig,
    keyGenerator: (request: NextRequest) => {
      const authHeader = request.headers.get('authorization')
      if (authHeader) {
        return userKeyGenerator(request, authHeader)
      }
      return defaultKeyGenerator(request)
    }
  }, authHandler)
}

/**
 * 创建带速率限制的管理员认证中间件
 */
export function withAdminAuthAndRateLimit(
  handler: (request: NextRequest, user: AuthenticatedUser) => Promise<Response>,
  rateLimitConfig: RateLimitConfig = rateLimitConfigs.strict
) {
  const authHandler = withAdminAuth(handler)
  
  return withRateLimit({
    ...rateLimitConfig,
    keyGenerator: (request: NextRequest) => {
      const authHeader = request.headers.get('authorization')
      if (authHeader) {
        return userKeyGenerator(request, authHeader)
      }
      return defaultKeyGenerator(request)
    }
  }, authHandler)
}