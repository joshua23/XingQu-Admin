/**
 * 星趣后台管理系统 - 订阅管理服务
 * 提供订阅计划管理、用户订阅操作和统计分析功能
 * Created: 2025-09-05
 */

import { dataService } from './supabase'
import type { 
  UUID,
  SubscriptionPlan,
  UserSubscription,
  SubscriptionFilters,
  SubscriptionStatistics,
  ApiResponse
} from '../types/admin'

export interface SubscriptionPlanCreate {
  name: string
  display_name: string
  description?: string
  price: number
  currency: string
  billing_period: 'monthly' | 'yearly' | 'lifetime'
  features: string[]
  limits: {
    daily_requests?: number
    monthly_requests?: number
    max_file_size?: number
    concurrent_sessions?: number
    api_calls?: number
    storage_gb?: number
    [key: string]: any
  }
  is_active: boolean
  sort_order: number
  metadata?: Record<string, any>
}

export interface SubscriptionUpdate {
  status?: 'active' | 'cancelled' | 'expired' | 'paused'
  expires_at?: string
  auto_renew?: boolean
  cancellation_reason?: string
  metadata?: Record<string, any>
}

export interface BulkSubscriptionOperation {
  operation: 'extend' | 'cancel' | 'upgrade' | 'downgrade' | 'pause' | 'resume'
  subscriptionIds: UUID[]
  parameters?: {
    newPlanId?: UUID
    extensionDays?: number
    reason?: string
    [key: string]: any
  }
}

class SubscriptionService {
  private static instance: SubscriptionService

  static getInstance(): SubscriptionService {
    if (!SubscriptionService.instance) {
      SubscriptionService.instance = new SubscriptionService()
    }
    return SubscriptionService.instance
  }

  // ============================================
  // 订阅计划管理
  // ============================================

  /**
   * 获取所有订阅计划
   */
  async getSubscriptionPlans(activeOnly = false): Promise<SubscriptionPlan[]> {
    try {
      let query = dataService.supabase
        .from('xq_subscription_plans')
        .select('*')
        .order('sort_order', { ascending: true })

      if (activeOnly) {
        query = query.eq('is_active', true)
      }

      const { data, error } = await query

      if (error) throw error
      return data || []
    } catch (error) {
      console.error('获取订阅计划失败:', error)
      throw error
    }
  }

  /**
   * 创建订阅计划
   */
  async createSubscriptionPlan(plan: SubscriptionPlanCreate): Promise<SubscriptionPlan> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_subscription_plans')
        .insert({
          ...plan,
          id: crypto.randomUUID(),
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('创建订阅计划失败:', error)
      throw error
    }
  }

  /**
   * 更新订阅计划
   */
  async updateSubscriptionPlan(
    planId: UUID,
    updates: Partial<SubscriptionPlanCreate>
  ): Promise<SubscriptionPlan> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_subscription_plans')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', planId)
        .select()
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('更新订阅计划失败:', error)
      throw error
    }
  }

  /**
   * 删除订阅计划
   */
  async deleteSubscriptionPlan(planId: UUID): Promise<void> {
    try {
      // 软删除：标记为不活跃
      const { error } = await dataService.supabase
        .from('xq_subscription_plans')
        .update({
          is_active: false,
          updated_at: new Date().toISOString()
        })
        .eq('id', planId)

      if (error) throw error
    } catch (error) {
      console.error('删除订阅计划失败:', error)
      throw error
    }
  }

  // ============================================
  // 用户订阅管理
  // ============================================

  /**
   * 获取用户订阅列表
   */
  async getUserSubscriptions(
    filters: SubscriptionFilters = {},
    page = 1,
    pageSize = 50
  ): Promise<{
    subscriptions: UserSubscription[]
    total: number
    totalPages: number
  }> {
    try {
      let query = dataService.supabase
        .from('xq_user_subscriptions')
        .select(`
          *,
          plan:xq_subscription_plans(*),
          user:xq_user_profiles(id, email, username, full_name)
        `)

      // 应用筛选条件
      if (filters.status?.length) {
        query = query.in('status', filters.status)
      }

      if (filters.planIds?.length) {
        query = query.in('plan_id', filters.planIds)
      }

      if (filters.userIds?.length) {
        query = query.in('user_id', filters.userIds)
      }

      if (filters.isExpiring) {
        const soon = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7天内到期
        query = query.lte('expires_at', soon)
      }

      if (filters.autoRenew !== undefined) {
        query = query.eq('auto_renew', filters.autoRenew)
      }

      if (filters.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
      }

      if (filters.search) {
        query = query.or(`
          user.email.ilike.%${filters.search}%,
          user.username.ilike.%${filters.search}%,
          user.full_name.ilike.%${filters.search}%
        `)
      }

      // 排序和分页
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1
      
      query = query
        .order('created_at', { ascending: false })
        .range(from, to)

      const { data, error, count } = await query

      if (error) throw error

      return {
        subscriptions: data || [],
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    } catch (error) {
      console.error('获取用户订阅失败:', error)
      throw error
    }
  }

  /**
   * 创建用户订阅
   */
  async createUserSubscription(
    userId: UUID,
    planId: UUID,
    duration?: { months?: number; days?: number }
  ): Promise<UserSubscription> {
    try {
      // 获取计划信息
      const plan = await this.getSubscriptionPlan(planId)
      if (!plan) throw new Error('订阅计划不存在')

      // 计算到期时间
      let expiresAt: string
      const now = new Date()
      
      if (plan.billing_period === 'lifetime') {
        expiresAt = new Date(now.getTime() + 100 * 365 * 24 * 60 * 60 * 1000).toISOString() // 100年
      } else if (duration) {
        const days = (duration.months || 0) * 30 + (duration.days || 0)
        expiresAt = new Date(now.getTime() + days * 24 * 60 * 60 * 1000).toISOString()
      } else {
        const defaultDays = plan.billing_period === 'monthly' ? 30 : 365
        expiresAt = new Date(now.getTime() + defaultDays * 24 * 60 * 60 * 1000).toISOString()
      }

      const { data, error } = await dataService.supabase
        .from('xq_user_subscriptions')
        .insert({
          id: crypto.randomUUID(),
          user_id: userId,
          plan_id: planId,
          status: 'active',
          starts_at: now.toISOString(),
          expires_at: expiresAt,
          auto_renew: true,
          created_at: now.toISOString(),
          updated_at: now.toISOString()
        })
        .select(`
          *,
          plan:xq_subscription_plans(*),
          user:xq_user_profiles(id, email, username, full_name)
        `)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('创建用户订阅失败:', error)
      throw error
    }
  }

  /**
   * 更新用户订阅
   */
  async updateUserSubscription(
    subscriptionId: UUID,
    updates: SubscriptionUpdate
  ): Promise<UserSubscription> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_user_subscriptions')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', subscriptionId)
        .select(`
          *,
          plan:xq_subscription_plans(*),
          user:xq_user_profiles(id, email, username, full_name)
        `)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('更新用户订阅失败:', error)
      throw error
    }
  }

  /**
   * 批量操作用户订阅
   */
  async bulkOperateSubscriptions(operation: BulkSubscriptionOperation): Promise<{
    success: number
    failed: number
    results: Array<{
      subscriptionId: UUID
      success: boolean
      error?: string
    }>
  }> {
    const results: Array<{
      subscriptionId: UUID
      success: boolean
      error?: string
    }> = []

    for (const subscriptionId of operation.subscriptionIds) {
      try {
        switch (operation.operation) {
          case 'extend':
            if (operation.parameters?.extensionDays) {
              const subscription = await this.getUserSubscription(subscriptionId)
              const newExpiry = new Date(subscription.expires_at)
              newExpiry.setDate(newExpiry.getDate() + operation.parameters.extensionDays)
              
              await this.updateUserSubscription(subscriptionId, {
                expires_at: newExpiry.toISOString()
              })
            }
            break

          case 'cancel':
            await this.updateUserSubscription(subscriptionId, {
              status: 'cancelled',
              auto_renew: false,
              cancellation_reason: operation.parameters?.reason
            })
            break

          case 'pause':
            await this.updateUserSubscription(subscriptionId, {
              status: 'paused'
            })
            break

          case 'resume':
            await this.updateUserSubscription(subscriptionId, {
              status: 'active'
            })
            break

          case 'upgrade':
          case 'downgrade':
            if (operation.parameters?.newPlanId) {
              await this.updateUserSubscription(subscriptionId, {
                plan_id: operation.parameters.newPlanId
              })
            }
            break
        }

        results.push({ subscriptionId, success: true })
      } catch (error) {
        results.push({
          subscriptionId,
          success: false,
          error: error instanceof Error ? error.message : '操作失败'
        })
      }
    }

    return {
      success: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      results
    }
  }

  // ============================================
  // 辅助方法
  // ============================================

  /**
   * 获取单个订阅计划
   */
  private async getSubscriptionPlan(planId: UUID): Promise<SubscriptionPlan | null> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_subscription_plans')
        .select('*')
        .eq('id', planId)
        .single()

      if (error && error.code !== 'PGRST116') throw error
      return data || null
    } catch (error) {
      console.error('获取订阅计划失败:', error)
      return null
    }
  }

  /**
   * 获取单个用户订阅
   */
  private async getUserSubscription(subscriptionId: UUID): Promise<UserSubscription> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_user_subscriptions')
        .select(`
          *,
          plan:xq_subscription_plans(*),
          user:xq_user_profiles(id, email, username, full_name)
        `)
        .eq('id', subscriptionId)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('获取用户订阅失败:', error)
      throw error
    }
  }

  // ============================================
  // 统计分析
  // ============================================

  /**
   * 获取订阅统计数据
   */
  async getSubscriptionStatistics(): Promise<SubscriptionStatistics> {
    try {
      // 这里应该执行多个查询来获取统计数据
      // 为了示例，返回模拟数据
      return {
        totalSubscriptions: 45680,
        activeSubscriptions: 38240,
        cancelledSubscriptions: 4820,
        expiredSubscriptions: 2620,
        totalRevenue: 2847560,
        monthlyRecurringRevenue: 324800,
        averageRevenuePerUser: 74.5,
        churnRate: 0.058,
        planDistribution: [
          { planId: 'free', planName: '免费版', count: 15420, percentage: 33.8 },
          { planId: 'basic', planName: '基础版', count: 18650, percentage: 40.8 },
          { planId: 'premium', planName: '高级版', count: 9840, percentage: 21.5 },
          { planId: 'lifetime', planName: '终身版', count: 1770, percentage: 3.9 }
        ],
        monthlyTrend: [
          { month: '2025-03', newSubs: 1240, cancelled: 85, revenue: 298400 },
          { month: '2025-04', newSubs: 1380, cancelled: 92, revenue: 312600 },
          { month: '2025-05', newSubs: 1520, cancelled: 103, revenue: 328900 },
          { month: '2025-06', newSubs: 1650, cancelled: 118, revenue: 345200 },
          { month: '2025-07', newSubs: 1840, cancelled: 125, revenue: 367800 },
          { month: '2025-08', newSubs: 1920, cancelled: 142, revenue: 384600 },
          { month: '2025-09', newSubs: 980, cancelled: 68, revenue: 198400 }
        ],
        expiringThisWeek: 245,
        expiringThisMonth: 1180,
        renewalRate: 0.842,
        upgrades: 156,
        downgrades: 43
      }
    } catch (error) {
      console.error('获取订阅统计失败:', error)
      throw error
    }
  }

  /**
   * 导出订阅数据
   */
  async exportSubscriptionData(filters: SubscriptionFilters = {}): Promise<string> {
    try {
      const { subscriptions } = await this.getUserSubscriptions(filters, 1, 10000) // 最多导出1万条

      const headers = [
        'ID', '用户邮箱', '用户名', '计划名称', '状态', '开始时间', 
        '到期时间', '自动续费', '创建时间', '价格'
      ]

      const csvData = subscriptions.map(sub => [
        sub.id,
        sub.user?.email || '',
        sub.user?.username || '',
        sub.plan?.display_name || '',
        sub.status,
        new Date(sub.starts_at).toLocaleString(),
        new Date(sub.expires_at).toLocaleString(),
        sub.auto_renew ? '是' : '否',
        new Date(sub.created_at).toLocaleString(),
        sub.plan?.price || 0
      ])

      const csv = [headers, ...csvData].map(row => 
        row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
      ).join('\n')

      return csv
    } catch (error) {
      console.error('导出订阅数据失败:', error)
      throw error
    }
  }
}

// 导出单例实例
export const subscriptionService = SubscriptionService.getInstance()

// 导出类型
export type { SubscriptionService }