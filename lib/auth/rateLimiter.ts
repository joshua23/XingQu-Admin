/**
 * Rate Limiter Utilities
 * 为API路由提供速率限制功能
 */

export interface RateLimitConfig {
  windowMs: number      // 时间窗口（毫秒）
  maxRequests: number   // 最大请求数
  keyGenerator?: (req: any) => string  // 键生成器
  skipSuccessful?: boolean  // 是否跳过成功请求
  skipFailedRequests?: boolean  // 是否跳过失败请求
}

interface RateLimitEntry {
  count: number
  resetTime: number
}

// 简单的内存存储（生产环境建议使用Redis）
class MemoryStore {
  private store = new Map<string, RateLimitEntry>()

  async get(key: string): Promise<RateLimitEntry | null> {
    const entry = this.store.get(key)
    if (!entry || entry.resetTime < Date.now()) {
      this.store.delete(key)
      return null
    }
    return entry
  }

  async set(key: string, entry: RateLimitEntry): Promise<void> {
    this.store.set(key, entry)
  }

  async delete(key: string): Promise<void> {
    this.store.delete(key)
  }

  // 清理过期条目
  cleanup(): void {
    const now = Date.now()
    for (const [key, entry] of this.store.entries()) {
      if (entry.resetTime < now) {
        this.store.delete(key)
      }
    }
  }
}

const store = new MemoryStore()

// 定期清理过期条目
setInterval(() => {
  store.cleanup()
}, 60000) // 每分钟清理一次

export interface RateLimitResult {
  allowed: boolean
  remaining: number
  resetTime: number
  totalHits: number
}

/**
 * 检查速率限制
 */
export async function checkRateLimit(
  key: string, 
  config: RateLimitConfig
): Promise<RateLimitResult> {
  const now = Date.now()
  const windowStart = now - config.windowMs
  const resetTime = now + config.windowMs

  let entry = await store.get(key)

  if (!entry || entry.resetTime <= now) {
    // 创建新的时间窗口
    entry = {
      count: 1,
      resetTime
    }
    await store.set(key, entry)

    return {
      allowed: true,
      remaining: config.maxRequests - 1,
      resetTime,
      totalHits: 1
    }
  }

  // 增加计数
  entry.count++
  await store.set(key, entry)

  const allowed = entry.count <= config.maxRequests
  const remaining = Math.max(0, config.maxRequests - entry.count)

  return {
    allowed,
    remaining,
    resetTime: entry.resetTime,
    totalHits: entry.count
  }
}

/**
 * 默认键生成器 - 基于IP地址
 */
export function defaultKeyGenerator(request: any): string {
  const forwarded = request.headers.get('x-forwarded-for')
  const ip = forwarded ? forwarded.split(',')[0] : request.headers.get('x-real-ip') || 'unknown'
  return `rate_limit:${ip}`
}

/**
 * 基于用户的键生成器
 */
export function userKeyGenerator(request: any, userId?: string): string {
  if (userId) {
    return `rate_limit:user:${userId}`
  }
  return defaultKeyGenerator(request)
}

/**
 * 创建速率限制中间件
 */
export function withRateLimit(
  config: RateLimitConfig,
  handler: (request: any, ...args: any[]) => Promise<Response>
) {
  return async (request: any, ...args: any[]) => {
    try {
      // 生成限制键
      const keyGen = config.keyGenerator || defaultKeyGenerator
      const key = keyGen(request)

      // 检查速率限制
      const result = await checkRateLimit(key, config)

      // 添加速率限制响应头
      const headers = {
        'X-RateLimit-Limit': config.maxRequests.toString(),
        'X-RateLimit-Remaining': result.remaining.toString(),
        'X-RateLimit-Reset': new Date(result.resetTime).toISOString(),
        'X-RateLimit-Window': config.windowMs.toString()
      }

      if (!result.allowed) {
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Too Many Requests',
            code: 'RATE_LIMIT_EXCEEDED',
            retryAfter: Math.ceil((result.resetTime - Date.now()) / 1000)
          }),
          { 
            status: 429,
            headers: {
              'Content-Type': 'application/json',
              'Retry-After': Math.ceil((result.resetTime - Date.now()) / 1000).toString(),
              ...headers
            }
          }
        )
      }

      // 执行原处理函数
      const response = await handler(request, ...args)

      // 添加速率限制头到响应
      for (const [key, value] of Object.entries(headers)) {
        response.headers.set(key, value)
      }

      return response

    } catch (error) {
      console.error('Rate limiting error:', error)
      // 如果速率限制出错，允许请求通过
      return handler(request, ...args)
    }
  }
}

/**
 * 预定义的速率限制配置
 */
export const rateLimitConfigs = {
  // 严格限制 - 用于敏感操作
  strict: {
    windowMs: 15 * 60 * 1000, // 15分钟
    maxRequests: 10
  },
  
  // 标准限制 - 用于一般API
  standard: {
    windowMs: 15 * 60 * 1000, // 15分钟
    maxRequests: 100
  },
  
  // 宽松限制 - 用于公开API
  relaxed: {
    windowMs: 15 * 60 * 1000, // 15分钟
    maxRequests: 1000
  },

  // 搜索API专用
  search: {
    windowMs: 1 * 60 * 1000, // 1分钟
    maxRequests: 30
  },

  // 个性化推荐专用（需要认证）
  personalized: {
    windowMs: 1 * 60 * 1000, // 1分钟
    maxRequests: 60
  }
}