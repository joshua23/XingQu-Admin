/**
 * 星趣后台管理系统 - 支付订单管理服务
 * 提供支付订单处理、退款管理和财务统计功能
 * Created: 2025-09-05
 */

import { dataService } from './supabase'
import type { 
  UUID,
  PaymentOrder,
  PaymentFilters,
  PaymentStatistics,
  RefundRequest,
  ApiResponse
} from '../types/admin'

export interface PaymentOrderCreate {
  user_id: UUID
  plan_id: UUID
  amount: number
  currency: string
  payment_method: 'alipay' | 'wechat' | 'card' | 'paypal' | 'stripe'
  payment_channel: string
  discount_amount?: number
  discount_code?: string
  metadata?: Record<string, any>
}

export interface PaymentUpdate {
  status?: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled' | 'refunded'
  payment_id?: string
  paid_at?: string
  failure_reason?: string
  refund_amount?: number
  refund_reason?: string
  metadata?: Record<string, any>
}

export interface BulkPaymentOperation {
  operation: 'refund' | 'cancel' | 'retry' | 'approve'
  orderIds: UUID[]
  parameters?: {
    refundReason?: string
    refundAmount?: number
    [key: string]: any
  }
}

class PaymentService {
  private static instance: PaymentService

  static getInstance(): PaymentService {
    if (!PaymentService.instance) {
      PaymentService.instance = new PaymentService()
    }
    return PaymentService.instance
  }

  // ============================================
  // 支付订单管理
  // ============================================

  /**
   * 获取支付订单列表
   */
  async getPaymentOrders(
    filters: PaymentFilters = {},
    page = 1,
    pageSize = 50
  ): Promise<{
    orders: PaymentOrder[]
    total: number
    totalPages: number
  }> {
    try {
      let query = dataService.supabase
        .from('xq_payment_orders')
        .select(`
          *,
          user:xq_user_profiles(id, email, username, full_name),
          plan:xq_subscription_plans(id, name, display_name, price)
        `)

      // 应用筛选条件
      if (filters.status?.length) {
        query = query.in('status', filters.status)
      }

      if (filters.paymentMethods?.length) {
        query = query.in('payment_method', filters.paymentMethods)
      }

      if (filters.userIds?.length) {
        query = query.in('user_id', filters.userIds)
      }

      if (filters.planIds?.length) {
        query = query.in('plan_id', filters.planIds)
      }

      if (filters.amountRange) {
        query = query
          .gte('amount', filters.amountRange.min)
          .lte('amount', filters.amountRange.max)
      }

      if (filters.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
      }

      if (filters.search) {
        query = query.or(`
          order_id.ilike.%${filters.search}%,
          payment_id.ilike.%${filters.search}%,
          user.email.ilike.%${filters.search}%,
          user.username.ilike.%${filters.search}%
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
        orders: data || [],
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    } catch (error) {
      console.error('获取支付订单失败:', error)
      throw error
    }
  }

  /**
   * 创建支付订单
   */
  async createPaymentOrder(orderData: PaymentOrderCreate): Promise<PaymentOrder> {
    try {
      const orderId = `PAY_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
      
      const { data, error } = await dataService.supabase
        .from('xq_payment_orders')
        .insert({
          id: crypto.randomUUID(),
          order_id: orderId,
          user_id: orderData.user_id,
          plan_id: orderData.plan_id,
          amount: orderData.amount,
          currency: orderData.currency,
          payment_method: orderData.payment_method,
          payment_channel: orderData.payment_channel,
          discount_amount: orderData.discount_amount || 0,
          discount_code: orderData.discount_code,
          status: 'pending',
          metadata: orderData.metadata || {},
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select(`
          *,
          user:xq_user_profiles(id, email, username, full_name),
          plan:xq_subscription_plans(id, name, display_name, price)
        `)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('创建支付订单失败:', error)
      throw error
    }
  }

  /**
   * 更新支付订单
   */
  async updatePaymentOrder(
    orderId: UUID,
    updates: PaymentUpdate
  ): Promise<PaymentOrder> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_payment_orders')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', orderId)
        .select(`
          *,
          user:xq_user_profiles(id, email, username, full_name),
          plan:xq_subscription_plans(id, name, display_name, price)
        `)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('更新支付订单失败:', error)
      throw error
    }
  }

  /**
   * 批量操作支付订单
   */
  async bulkOperateOrders(operation: BulkPaymentOperation): Promise<{
    success: number
    failed: number
    results: Array<{
      orderId: UUID
      success: boolean
      error?: string
    }>
  }> {
    const results: Array<{
      orderId: UUID
      success: boolean
      error?: string
    }> = []

    for (const orderId of operation.orderIds) {
      try {
        switch (operation.operation) {
          case 'refund':
            await this.processRefund(orderId, {
              refund_reason: operation.parameters?.refundReason,
              refund_amount: operation.parameters?.refundAmount
            })
            break

          case 'cancel':
            await this.updatePaymentOrder(orderId, {
              status: 'cancelled'
            })
            break

          case 'retry':
            await this.updatePaymentOrder(orderId, {
              status: 'pending'
            })
            break

          case 'approve':
            await this.updatePaymentOrder(orderId, {
              status: 'completed',
              paid_at: new Date().toISOString()
            })
            break
        }

        results.push({ orderId, success: true })
      } catch (error) {
        results.push({
          orderId,
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
  // 退款管理
  // ============================================

  /**
   * 处理退款
   */
  async processRefund(
    orderId: UUID,
    refundData: {
      refund_reason?: string
      refund_amount?: number
    }
  ): Promise<PaymentOrder> {
    try {
      // 获取原订单信息
      const order = await this.getPaymentOrder(orderId)
      if (!order) throw new Error('订单不存在')

      if (order.status !== 'completed') {
        throw new Error('只有已完成的订单才能退款')
      }

      const refundAmount = refundData.refund_amount || order.amount

      // 更新订单状态
      const updatedOrder = await this.updatePaymentOrder(orderId, {
        status: 'refunded',
        refund_amount: refundAmount,
        refund_reason: refundData.refund_reason
      })

      // 创建退款记录
      await this.createRefundRecord({
        order_id: orderId,
        refund_amount: refundAmount,
        refund_reason: refundData.refund_reason || '管理员操作退款'
      })

      return updatedOrder
    } catch (error) {
      console.error('处理退款失败:', error)
      throw error
    }
  }

  /**
   * 创建退款记录
   */
  private async createRefundRecord(refundData: {
    order_id: UUID
    refund_amount: number
    refund_reason: string
  }): Promise<void> {
    try {
      await dataService.supabase
        .from('xq_refund_records')
        .insert({
          id: crypto.randomUUID(),
          order_id: refundData.order_id,
          refund_amount: refundData.refund_amount,
          refund_reason: refundData.refund_reason,
          status: 'processing',
          created_at: new Date().toISOString(),
          processed_by: 'current-admin-id' // TODO: 从认证上下文获取
        })
    } catch (error) {
      console.error('创建退款记录失败:', error)
      throw error
    }
  }

  /**
   * 获取退款请求
   */
  async getRefundRequests(
    filters: { status?: string; orderId?: UUID } = {},
    page = 1,
    pageSize = 50
  ): Promise<{
    refunds: RefundRequest[]
    total: number
    totalPages: number
  }> {
    try {
      let query = dataService.supabase
        .from('xq_refund_records')
        .select(`
          *,
          order:xq_payment_orders(
            *,
            user:xq_user_profiles(id, email, username),
            plan:xq_subscription_plans(id, name, display_name)
          )
        `)

      if (filters.status) {
        query = query.eq('status', filters.status)
      }

      if (filters.orderId) {
        query = query.eq('order_id', filters.orderId)
      }

      const from = (page - 1) * pageSize
      const to = from + pageSize - 1
      
      query = query
        .order('created_at', { ascending: false })
        .range(from, to)

      const { data, error, count } = await query

      if (error) throw error

      return {
        refunds: data || [],
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    } catch (error) {
      console.error('获取退款请求失败:', error)
      throw error
    }
  }

  // ============================================
  // 统计分析
  // ============================================

  /**
   * 获取支付统计数据
   */
  async getPaymentStatistics(): Promise<PaymentStatistics> {
    try {
      // 这里应该执行多个查询来获取统计数据
      // 为了示例，返回模拟数据
      return {
        totalOrders: 28650,
        totalRevenue: 4275800,
        completedOrders: 24580,
        pendingOrders: 1420,
        failedOrders: 1890,
        refundedOrders: 760,
        averageOrderValue: 173.8,
        paymentMethodStats: [
          { method: 'alipay', count: 12480, percentage: 43.5, revenue: 2167200 },
          { method: 'wechat', count: 8760, percentage: 30.6, revenue: 1523100 },
          { method: 'card', count: 4820, percentage: 16.8, revenue: 837300 },
          { method: 'paypal', count: 2590, percentage: 9.1, revenue: 450200 }
        ],
        dailyRevenue: [
          { date: '2025-08-29', revenue: 82400, orders: 456 },
          { date: '2025-08-30', revenue: 89600, orders: 492 },
          { date: '2025-08-31', revenue: 91200, orders: 521 },
          { date: '2025-09-01', revenue: 95800, orders: 548 },
          { date: '2025-09-02', revenue: 88300, orders: 476 },
          { date: '2025-09-03', revenue: 93700, orders: 524 },
          { date: '2025-09-04', revenue: 97900, orders: 562 }
        ],
        monthlyGrowth: 0.148,
        refundRate: 0.027,
        conversionRate: 0.742,
        topPlans: [
          { planId: 'premium', planName: '高级版', revenue: 1685400, orders: 9420 },
          { planId: 'basic', planName: '基础版', revenue: 1456800, orders: 14568 },
          { planId: 'lifetime', planName: '终身版', revenue: 982600, orders: 1964 },
          { planId: 'enterprise', planName: '企业版', revenue: 251000, orders: 698 }
        ]
      }
    } catch (error) {
      console.error('获取支付统计失败:', error)
      throw error
    }
  }

  // ============================================
  // 辅助方法
  // ============================================

  /**
   * 获取单个支付订单
   */
  private async getPaymentOrder(orderId: UUID): Promise<PaymentOrder | null> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_payment_orders')
        .select(`
          *,
          user:xq_user_profiles(id, email, username, full_name),
          plan:xq_subscription_plans(id, name, display_name, price)
        `)
        .eq('id', orderId)
        .single()

      if (error && error.code !== 'PGRST116') throw error
      return data || null
    } catch (error) {
      console.error('获取支付订单失败:', error)
      return null
    }
  }

  /**
   * 导出支付数据
   */
  async exportPaymentData(filters: PaymentFilters = {}): Promise<string> {
    try {
      const { orders } = await this.getPaymentOrders(filters, 1, 10000) // 最多导出1万条

      const headers = [
        'ID', '订单号', '用户邮箱', '计划名称', '金额', '支付方式', 
        '状态', '创建时间', '支付时间', '折扣金额', '失败原因'
      ]

      const csvData = orders.map(order => [
        order.id,
        order.order_id,
        order.user?.email || '',
        order.plan?.display_name || '',
        order.amount,
        order.payment_method,
        order.status,
        new Date(order.created_at).toLocaleString(),
        order.paid_at ? new Date(order.paid_at).toLocaleString() : '',
        order.discount_amount || 0,
        order.failure_reason || ''
      ])

      const csv = [headers, ...csvData].map(row => 
        row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
      ).join('\n')

      return csv
    } catch (error) {
      console.error('导出支付数据失败:', error)
      throw error
    }
  }

  /**
   * 处理支付回调
   */
  async handlePaymentCallback(
    paymentId: string,
    status: 'success' | 'failed',
    metadata?: Record<string, any>
  ): Promise<void> {
    try {
      const { data: order } = await dataService.supabase
        .from('xq_payment_orders')
        .select('id')
        .eq('payment_id', paymentId)
        .single()

      if (order) {
        await this.updatePaymentOrder(order.id, {
          status: status === 'success' ? 'completed' : 'failed',
          paid_at: status === 'success' ? new Date().toISOString() : undefined,
          failure_reason: status === 'failed' ? '支付失败' : undefined,
          metadata: { ...metadata }
        })
      }
    } catch (error) {
      console.error('处理支付回调失败:', error)
      throw error
    }
  }
}

// 导出单例实例
export const paymentService = PaymentService.getInstance()

// 导出类型
export type { PaymentService }