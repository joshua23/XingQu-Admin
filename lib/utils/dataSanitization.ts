/**
 * Data Sanitization Utilities
 * 清理API响应中的敏感数据
 */

import { Agent, RecommendationResult } from '@/lib/services/recommendationService'

/**
 * 公开API响应的Agent接口 - 移除敏感信息
 */
export interface PublicAgent {
  id: string
  name: string
  description: string
  avatar_url?: string
  created_at: string
  is_active: boolean
  category: string
  tags: string[]
  usage_count?: number
  rating_average?: number
  // 注意: 移除了 creator_id 和 popularity_score (内部算法信息)
}

/**
 * 公开API的推荐结果接口
 */
export interface PublicRecommendationResult {
  agent: PublicAgent
  score: number
  reason: string
  category: 'trending' | 'personalized' | 'category_based' | 'collaborative' | 'content_based'
}

/**
 * 清理Agent数据，移除敏感信息
 */
export function sanitizeAgent(agent: Agent, isAuthenticated: boolean = false): PublicAgent {
  const publicAgent: PublicAgent = {
    id: agent.id,
    name: agent.name,
    description: agent.description,
    avatar_url: agent.avatar_url,
    created_at: agent.created_at,
    is_active: agent.is_active,
    category: agent.category,
    tags: agent.tags,
    rating_average: agent.rating_average
  }

  // 只有认证用户才能看到使用统计
  if (isAuthenticated) {
    publicAgent.usage_count = agent.usage_count
  }

  return publicAgent
}

/**
 * 清理推荐结果数据
 */
export function sanitizeRecommendationResult(
  result: RecommendationResult, 
  isAuthenticated: boolean = false
): PublicRecommendationResult {
  return {
    agent: sanitizeAgent(result.agent, isAuthenticated),
    score: Math.round(result.score), // 四舍五入分数，不暴露精确的内部算法分数
    reason: result.reason,
    category: result.category
  }
}

/**
 * 清理推荐结果数组
 */
export function sanitizeRecommendationResults(
  results: RecommendationResult[], 
  isAuthenticated: boolean = false
): PublicRecommendationResult[] {
  return results.map(result => sanitizeRecommendationResult(result, isAuthenticated))
}

/**
 * 清理统计数据，移除可能暴露业务敏感信息的数据
 */
export function sanitizeStats(stats: any, isAuthenticated: boolean = false) {
  const publicStats = {
    total_agents: stats.total_agents,
    active_agents: stats.active_agents,
    categories: stats.categories.map((cat: any) => ({
      name: cat.name,
      count: cat.count
    })),
    // 限制返回的标签数量
    top_tags: stats.top_tags.slice(0, isAuthenticated ? 20 : 10).map((tag: any) => ({
      tag: tag.tag,
      count: isAuthenticated ? tag.count : undefined // 匿名用户不显示具体数量
    }))
  }

  return publicStats
}

/**
 * 清理错误信息，避免暴露内部实现细节
 */
export function sanitizeError(error: any, isDevelopment: boolean = false) {
  if (isDevelopment) {
    // 开发环境返回详细错误信息
    return {
      message: error.message || 'Unknown error',
      stack: error.stack,
      details: error
    }
  }

  // 生产环境只返回安全的错误信息
  const safeErrorMessages: Record<string, string> = {
    'ECONNREFUSED': 'Service temporarily unavailable',
    'ENOTFOUND': 'Service temporarily unavailable', 
    'ETIMEDOUT': 'Request timeout',
    'ValidationError': 'Invalid request parameters',
    'AuthenticationError': 'Authentication failed',
    'AuthorizationError': 'Access denied'
  }

  const errorType = error.name || error.code || 'UnknownError'
  const safeMessage = safeErrorMessages[errorType] || 'An error occurred while processing your request'

  return {
    message: safeMessage,
    type: 'InternalError'
  }
}

/**
 * 创建数据清理中间件
 */
export function withDataSanitization<T>(
  handler: (...args: any[]) => Promise<T>,
  sanitizer: (data: T, isAuthenticated: boolean) => any
) {
  return async (...args: any[]) => {
    const result = await handler(...args)
    
    // 检查是否有用户认证信息（通过参数推断）
    const isAuthenticated = args.some(arg => 
      arg && typeof arg === 'object' && 'id' in arg && 'email' in arg
    )

    return sanitizer(result, isAuthenticated)
  }
}