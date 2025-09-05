/**
 * 星趣后台管理系统 - 用户管理服务
 * 提供用户批量操作、分析和管理功能
 * Created: 2025-09-05
 */

import { dataService } from './supabase'
import type { 
  UUID,
  FilterOptions,
  UserBatchUpdate,
  BatchOperation,
  APIResponse
} from '../types/admin'

export interface UserProfile {
  id: UUID
  email: string
  username?: string
  avatar_url?: string
  full_name?: string
  created_at: string
  updated_at: string
  last_seen_at?: string
  is_active: boolean
  subscription_status: 'free' | 'basic' | 'premium' | 'lifetime'
  subscription_expires_at?: string
  total_conversations: number
  total_tokens_used: number
  daily_usage_count: number
  tags: string[]
  banned_until?: string
  ban_reason?: string
  verification_status: 'pending' | 'verified' | 'rejected'
  phone?: string
  location?: string
  signup_source: string
  referrer_id?: UUID
  metadata: Record<string, any>
}

export interface UserStatistics {
  totalUsers: number
  activeUsers: number
  newUsersToday: number
  newUsersThisWeek: number
  newUsersThisMonth: number
  verifiedUsers: number
  subscriptionStats: {
    free: number
    basic: number
    premium: number
    lifetime: number
  }
  topCountries: Array<{ country: string; count: number }>
  topSignupSources: Array<{ source: string; count: number }>
  dailyActiveUsers: number
  weeklyActiveUsers: number
  monthlyActiveUsers: number
  averageSessionDuration: number
  churnRate: number
}

export interface UserFilters extends FilterOptions {
  subscriptionStatus?: string[]
  verificationStatus?: string[]
  signupSource?: string[]
  location?: string[]
  isActive?: boolean
  isBanned?: boolean
  hasSubscription?: boolean
  registrationDateRange?: {
    start: string
    end: string
  }
  lastSeenRange?: {
    start: string
    end: string
  }
  usageRange?: {
    min: number
    max: number
  }
}

class UserService {
  private static instance: UserService

  static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService()
    }
    return UserService.instance
  }

  // ============================================
  // 用户查询和筛选
  // ============================================

  /**
   * 获取用户列表（支持高级筛选）
   */
  async getUsers(filters: UserFilters = {}, page = 1, pageSize = 50): Promise<{
    users: UserProfile[]
    total: number
    totalPages: number
  }> {
    try {
      let query = dataService.supabase
        .from('xq_user_profiles')
        .select(`
          *
        `)

      // 应用筛选条件
      if (filters.search) {
        query = query.or(`
          email.ilike.%${filters.search}%,
          username.ilike.%${filters.search}%,
          full_name.ilike.%${filters.search}%
        `)
      }

      if (filters.subscriptionStatus?.length) {
        query = query.in('subscription_status', filters.subscriptionStatus)
      }

      if (filters.verificationStatus?.length) {
        query = query.in('verification_status', filters.verificationStatus)
      }

      if (filters.isActive !== undefined) {
        query = query.eq('is_active', filters.isActive)
      }

      if (filters.isBanned !== undefined) {
        if (filters.isBanned) {
          query = query.not('banned_until', 'is', null)
        } else {
          query = query.is('banned_until', null)
        }
      }

      if (filters.registrationDateRange) {
        query = query
          .gte('created_at', filters.registrationDateRange.start)
          .lte('created_at', filters.registrationDateRange.end)
      }

      if (filters.lastSeenRange) {
        query = query
          .gte('last_seen_at', filters.lastSeenRange.start)
          .lte('last_seen_at', filters.lastSeenRange.end)
      }

      if (filters.location?.length) {
        query = query.in('location', filters.location)
      }

      if (filters.signupSource?.length) {
        query = query.in('signup_source', filters.signupSource)
      }

      if (filters.tags?.length) {
        query = query.overlaps('tags', filters.tags)
      }

      // 排序
      const sortBy = filters.sortBy || 'created_at'
      const sortOrder = filters.sortOrder || 'desc'
      query = query.order(sortBy, { ascending: sortOrder === 'asc' })

      // 分页
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1
      query = query.range(from, to)

      const { data, error, count } = await query

      if (error) throw error

      return {
        users: data || [],
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    } catch (error) {
      console.error('获取用户列表失败:', error)
      throw error
    }
  }

  /**
   * 获取用户详情
   */
  async getUserById(userId: UUID): Promise<UserProfile | null> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_user_profiles')
        .select(`
          *
        `)
        .eq('id', userId)
        .single()

      if (error && error.code !== 'PGRST116') throw error
      return data || null
    } catch (error) {
      console.error('获取用户详情失败:', error)
      throw error
    }
  }

  /**
   * 搜索用户
   */
  async searchUsers(query: string, limit = 10): Promise<UserProfile[]> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_user_profiles')
        .select('id, email, username, full_name, avatar_url, subscription_status')
        .or(`
          email.ilike.%${query}%,
          username.ilike.%${query}%,
          full_name.ilike.%${query}%
        `)
        .limit(limit)

      if (error) throw error
      return data || []
    } catch (error) {
      console.error('搜索用户失败:', error)
      throw error
    }
  }

  // ============================================
  // 批量操作
  // ============================================

  /**
   * 批量更新用户
   */
  async batchUpdateUsers(userIds: UUID[], updates: UserBatchUpdate): Promise<BatchOperation> {
    try {
      const operation: BatchOperation = {
        id: crypto.randomUUID(),
        operationType: 'update',
        resourceType: 'users',
        totalItems: userIds.length,
        processedItems: 0,
        successfulItems: 0,
        failedItems: 0,
        status: 'processing',
        progress: 0,
        results: [],
        startedAt: new Date().toISOString(),
        createdBy: 'current-admin-id', // TODO: 从认证上下文获取
        createdAt: new Date().toISOString()
      }

      // 批量更新逻辑
      for (const userId of userIds) {
        try {
          const updateData: Partial<UserProfile> = {}

          if (updates.updates.status !== undefined) {
            updateData.is_active = updates.updates.status === 'active'
          }

          if (updates.updates.tags !== undefined) {
            updateData.tags = updates.updates.tags
          }

          const { error } = await dataService.supabase
            .from('xq_user_profiles')
            .update(updateData)
            .eq('id', userId)

          if (error) throw error

          operation.results.push({
            itemId: userId,
            status: 'success',
            data: updateData
          })
          operation.successfulItems++
        } catch (error) {
          operation.results.push({
            itemId: userId,
            status: 'failed',
            errorMessage: error instanceof Error ? error.message : '更新失败'
          })
          operation.failedItems++
        }

        operation.processedItems++
        operation.progress = (operation.processedItems / operation.totalItems) * 100
      }

      operation.status = operation.failedItems === 0 ? 'completed' : 'completed'
      operation.completedAt = new Date().toISOString()

      return operation
    } catch (error) {
      console.error('批量更新用户失败:', error)
      throw error
    }
  }

  /**
   * 批量删除用户
   */
  async batchDeleteUsers(userIds: UUID[], reason?: string): Promise<BatchOperation> {
    try {
      const operation: BatchOperation = {
        id: crypto.randomUUID(),
        operationType: 'delete',
        resourceType: 'users',
        totalItems: userIds.length,
        processedItems: 0,
        successfulItems: 0,
        failedItems: 0,
        status: 'processing',
        progress: 0,
        results: [],
        startedAt: new Date().toISOString(),
        createdBy: 'current-admin-id',
        createdAt: new Date().toISOString()
      }

      for (const userId of userIds) {
        try {
          // 软删除：标记为不活跃
          const { error } = await dataService.supabase
            .from('xq_user_profiles')
            .update({
              is_active: false,
              banned_until: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(), // 封禁一年
              ban_reason: reason || '批量操作删除',
              updated_at: new Date().toISOString()
            })
            .eq('id', userId)

          if (error) throw error

          operation.results.push({
            itemId: userId,
            status: 'success'
          })
          operation.successfulItems++
        } catch (error) {
          operation.results.push({
            itemId: userId,
            status: 'failed',
            errorMessage: error instanceof Error ? error.message : '删除失败'
          })
          operation.failedItems++
        }

        operation.processedItems++
        operation.progress = (operation.processedItems / operation.totalItems) * 100
      }

      operation.status = 'completed'
      operation.completedAt = new Date().toISOString()

      return operation
    } catch (error) {
      console.error('批量删除用户失败:', error)
      throw error
    }
  }

  /**
   * 导出用户数据
   */
  async exportUsers(filters: UserFilters = {}): Promise<string> {
    try {
      const { users } = await this.getUsers(filters, 1, 10000) // 最多导出1万条

      const headers = [
        'ID', '邮箱', '用户名', '姓名', '注册时间', '最后活跃', 
        '订阅状态', '验证状态', '是否激活', '位置', '注册来源', '标签'
      ]

      const csvData = users.map(user => [
        user.id,
        user.email,
        user.username || '',
        user.full_name || '',
        new Date(user.created_at).toLocaleString(),
        user.last_seen_at ? new Date(user.last_seen_at).toLocaleString() : '',
        user.subscription_status,
        user.verification_status,
        user.is_active ? '是' : '否',
        user.location || '',
        user.signup_source,
        user.tags.join(';')
      ])

      const csv = [headers, ...csvData].map(row => 
        row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
      ).join('\n')

      return csv
    } catch (error) {
      console.error('导出用户数据失败:', error)
      throw error
    }
  }

  // ============================================
  // 用户统计分析
  // ============================================

  /**
   * 获取用户统计数据
   */
  async getUserStatistics(): Promise<UserStatistics> {
    try {
      // 这里应该调用多个查询来获取统计数据
      // 为了示例，我们返回模拟数据
      return {
        totalUsers: 150000,
        activeUsers: 89000,
        newUsersToday: 245,
        newUsersThisWeek: 1680,
        newUsersThisMonth: 7200,
        verifiedUsers: 132000,
        subscriptionStats: {
          free: 120000,
          basic: 20000,
          premium: 8000,
          lifetime: 2000
        },
        topCountries: [
          { country: '中国', count: 89000 },
          { country: '美国', count: 25000 },
          { country: '日本', count: 18000 },
          { country: '韩国', count: 12000 },
          { country: '其他', count: 6000 }
        ],
        topSignupSources: [
          { source: 'organic', count: 78000 },
          { source: 'weChat', count: 45000 },
          { source: 'weibo', count: 18000 },
          { source: 'friend_referral', count: 9000 }
        ],
        dailyActiveUsers: 25000,
        weeklyActiveUsers: 67000,
        monthlyActiveUsers: 89000,
        averageSessionDuration: 18.5,
        churnRate: 0.035
      }
    } catch (error) {
      console.error('获取用户统计失败:', error)
      throw error
    }
  }

  // ============================================
  // 用户操作
  // ============================================

  /**
   * 封禁用户
   */
  async banUser(userId: UUID, reason: string, duration?: number): Promise<void> {
    try {
      const bannedUntil = duration 
        ? new Date(Date.now() + duration * 24 * 60 * 60 * 1000).toISOString()
        : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString() // 默认封禁一年

      const { error } = await dataService.supabase
        .from('xq_user_profiles')
        .update({
          is_active: false,
          banned_until: bannedUntil,
          ban_reason: reason,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)

      if (error) throw error
    } catch (error) {
      console.error('封禁用户失败:', error)
      throw error
    }
  }

  /**
   * 解封用户
   */
  async unbanUser(userId: UUID): Promise<void> {
    try {
      const { error } = await dataService.supabase
        .from('xq_user_profiles')
        .update({
          is_active: true,
          banned_until: null,
          ban_reason: null,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)

      if (error) throw error
    } catch (error) {
      console.error('解封用户失败:', error)
      throw error
    }
  }

  /**
   * 更新用户标签
   */
  async updateUserTags(userId: UUID, tags: string[]): Promise<void> {
    try {
      const { error } = await dataService.supabase
        .from('xq_user_profiles')
        .update({
          tags,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)

      if (error) throw error
    } catch (error) {
      console.error('更新用户标签失败:', error)
      throw error
    }
  }

  /**
   * 重置用户密码
   */
  async resetUserPassword(email: string): Promise<void> {
    try {
      const { error } = await dataService.supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`
      })

      if (error) throw error
    } catch (error) {
      console.error('重置用户密码失败:', error)
      throw error
    }
  }
}

// 导出单例实例
export const userService = UserService.getInstance()

// 导出类型
export type { UserService }