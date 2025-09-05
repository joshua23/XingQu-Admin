/**
 * 星趣后台管理系统 - 内容审核服务
 * 提供AI智能内容审核、人工复审和规则管理功能
 * Created: 2025-09-05
 */

import { dataService } from './supabase'
import type { 
  UUID,
  ModerationRecord,
  ModerationRule,
  ContentReport,
  ModerationStatistics,
  ApiResponse
} from '../types/admin'

export interface ModerationRequest {
  content: string
  contentType: 'text' | 'image' | 'video' | 'audio'
  contentId?: UUID
  userId?: UUID
  source: 'user_generated' | 'comment' | 'profile' | 'message'
  priority: 'low' | 'medium' | 'high' | 'urgent'
  metadata?: Record<string, any>
}

export interface ModerationResult {
  id: UUID
  status: 'approved' | 'rejected' | 'pending' | 'flagged'
  confidence: number
  violations: Array<{
    type: string
    severity: 'low' | 'medium' | 'high' | 'critical'
    description: string
    confidence: number
  }>
  aiAnalysis: {
    sentiment: number
    toxicity: number
    categories: Record<string, number>
    keywords: string[]
  }
  recommendedAction: 'approve' | 'reject' | 'review' | 'escalate'
  reason?: string
  reviewedBy?: UUID
  reviewedAt?: string
}

export interface BatchModerationRequest {
  items: ModerationRequest[]
  options?: {
    enableAI?: boolean
    enableHuman?: boolean
    priority?: 'low' | 'medium' | 'high'
    callback?: string
  }
}

export interface ModerationFilters {
  status?: string[]
  contentType?: string[]
  dateRange?: {
    start: string
    end: string
  }
  reviewer?: UUID[]
  source?: string[]
  severity?: string[]
  hasViolations?: boolean
}

class ModerationService {
  private static instance: ModerationService

  static getInstance(): ModerationService {
    if (!ModerationService.instance) {
      ModerationService.instance = new ModerationService()
    }
    return ModerationService.instance
  }

  // ============================================
  // 内容审核核心功能
  // ============================================

  /**
   * 提交内容审核
   */
  async submitForModeration(request: ModerationRequest): Promise<ModerationResult> {
    try {
      // 先进行AI预审
      const aiResult = await this.performAIModeration(request)
      
      // 创建审核记录
      const moderationRecord: Partial<ModerationRecord> = {
        id: crypto.randomUUID(),
        content_id: request.contentId,
        content_type: request.contentType,
        content_text: request.content,
        user_id: request.userId,
        source: request.source,
        status: aiResult.status,
        ai_confidence: aiResult.confidence,
        ai_analysis: aiResult.aiAnalysis,
        violations: aiResult.violations,
        priority: request.priority,
        metadata: request.metadata || {},
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }

      // 根据AI结果决定是否需要人工审核
      if (aiResult.recommendedAction === 'review' || 
          aiResult.confidence < 0.8 || 
          request.priority === 'high' ||
          request.priority === 'urgent') {
        moderationRecord.requires_human_review = true
        moderationRecord.status = 'pending'
      }

      const { data, error } = await dataService.supabase
        .from('xq_content_moderation_records')
        .insert(moderationRecord)
        .select()
        .single()

      if (error) throw error

      return {
        id: data.id,
        status: data.status,
        confidence: data.ai_confidence,
        violations: data.violations || [],
        aiAnalysis: data.ai_analysis,
        recommendedAction: aiResult.recommendedAction,
        reason: data.reason,
        reviewedBy: data.reviewed_by,
        reviewedAt: data.reviewed_at
      }
    } catch (error) {
      console.error('提交内容审核失败:', error)
      throw error
    }
  }

  /**
   * AI智能审核
   */
  private async performAIModeration(request: ModerationRequest): Promise<ModerationResult> {
    // 模拟AI审核逻辑
    const analysis = {
      sentiment: Math.random() * 2 - 1, // -1 到 1
      toxicity: Math.random(),
      categories: {
        spam: Math.random(),
        hate_speech: Math.random(),
        violence: Math.random(),
        adult_content: Math.random(),
        harassment: Math.random()
      },
      keywords: this.extractKeywords(request.content)
    }

    const violations = []
    let maxSeverity = 0

    // 检查各种违规类型
    Object.entries(analysis.categories).forEach(([category, score]) => {
      if (score > 0.7) {
        violations.push({
          type: category,
          severity: score > 0.9 ? 'critical' : score > 0.8 ? 'high' : 'medium' as 'low' | 'medium' | 'high' | 'critical',
          description: `检测到${category}内容`,
          confidence: score
        })
        maxSeverity = Math.max(maxSeverity, score)
      }
    })

    const confidence = 1 - Math.abs(analysis.sentiment) * 0.5 - analysis.toxicity * 0.5
    let status: 'approved' | 'rejected' | 'pending' | 'flagged' = 'approved'
    let recommendedAction: 'approve' | 'reject' | 'review' | 'escalate' = 'approve'

    if (maxSeverity > 0.9) {
      status = 'rejected'
      recommendedAction = 'reject'
    } else if (maxSeverity > 0.7 || confidence < 0.6) {
      status = 'flagged'
      recommendedAction = 'review'
    } else if (violations.length > 0) {
      status = 'flagged'
      recommendedAction = 'review'
    }

    return {
      id: crypto.randomUUID(),
      status,
      confidence,
      violations,
      aiAnalysis: analysis,
      recommendedAction
    }
  }

  /**
   * 批量内容审核
   */
  async batchModeration(request: BatchModerationRequest): Promise<ModerationResult[]> {
    try {
      const results: ModerationResult[] = []
      
      for (const item of request.items) {
        const result = await this.submitForModeration(item)
        results.push(result)
      }

      return results
    } catch (error) {
      console.error('批量内容审核失败:', error)
      throw error
    }
  }

  // ============================================
  // 审核记录管理
  // ============================================

  /**
   * 获取审核记录列表
   */
  async getModerationRecords(
    filters: ModerationFilters = {},
    page = 1,
    pageSize = 50
  ): Promise<{
    records: ModerationRecord[]
    total: number
    totalPages: number
  }> {
    try {
      let query = dataService.supabase
        .from('xq_content_moderation_records')
        .select(`
          *,
          reviewed_by_user:xq_admin_users!reviewed_by(id, username, email)
        `)

      // 应用筛选条件
      if (filters.status?.length) {
        query = query.in('status', filters.status)
      }

      if (filters.contentType?.length) {
        query = query.in('content_type', filters.contentType)
      }

      if (filters.source?.length) {
        query = query.in('source', filters.source)
      }

      if (filters.reviewer?.length) {
        query = query.in('reviewed_by', filters.reviewer)
      }

      if (filters.hasViolations !== undefined) {
        if (filters.hasViolations) {
          query = query.not('violations', 'is', null)
        } else {
          query = query.is('violations', null)
        }
      }

      if (filters.dateRange) {
        query = query
          .gte('created_at', filters.dateRange.start)
          .lte('created_at', filters.dateRange.end)
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
        records: data || [],
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    } catch (error) {
      console.error('获取审核记录失败:', error)
      throw error
    }
  }

  /**
   * 人工审核处理
   */
  async reviewContent(
    recordId: UUID,
    decision: 'approved' | 'rejected',
    reason?: string,
    reviewerId?: UUID
  ): Promise<void> {
    try {
      const { error } = await dataService.supabase
        .from('xq_content_moderation_records')
        .update({
          status: decision,
          human_decision: decision,
          reason,
          reviewed_by: reviewerId || 'current-admin-id', // TODO: 从认证上下文获取
          reviewed_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', recordId)

      if (error) throw error
    } catch (error) {
      console.error('审核处理失败:', error)
      throw error
    }
  }

  /**
   * 批量审核处理
   */
  async batchReview(
    recordIds: UUID[],
    decision: 'approved' | 'rejected',
    reason?: string,
    reviewerId?: UUID
  ): Promise<void> {
    try {
      const { error } = await dataService.supabase
        .from('xq_content_moderation_records')
        .update({
          status: decision,
          human_decision: decision,
          reason,
          reviewed_by: reviewerId || 'current-admin-id',
          reviewed_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .in('id', recordIds)

      if (error) throw error
    } catch (error) {
      console.error('批量审核处理失败:', error)
      throw error
    }
  }

  // ============================================
  // 审核规则管理
  // ============================================

  /**
   * 获取审核规则
   */
  async getModerationRules(): Promise<ModerationRule[]> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_moderation_rules')
        .select('*')
        .eq('is_active', true)
        .order('priority', { ascending: false })

      if (error) throw error
      return data || []
    } catch (error) {
      console.error('获取审核规则失败:', error)
      throw error
    }
  }

  /**
   * 创建审核规则
   */
  async createModerationRule(rule: Omit<ModerationRule, 'id' | 'created_at' | 'updated_at'>): Promise<ModerationRule> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_moderation_rules')
        .insert({
          ...rule,
          id: crypto.randomUUID(),
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('创建审核规则失败:', error)
      throw error
    }
  }

  /**
   * 更新审核规则
   */
  async updateModerationRule(
    ruleId: UUID,
    updates: Partial<Omit<ModerationRule, 'id' | 'created_at'>>
  ): Promise<ModerationRule> {
    try {
      const { data, error } = await dataService.supabase
        .from('xq_moderation_rules')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', ruleId)
        .select()
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('更新审核规则失败:', error)
      throw error
    }
  }

  // ============================================
  // 用户举报管理
  // ============================================

  /**
   * 获取用户举报
   */
  async getUserReports(
    filters: { status?: string; type?: string; userId?: UUID } = {},
    page = 1,
    pageSize = 50
  ): Promise<{
    reports: ContentReport[]
    total: number
    totalPages: number
  }> {
    try {
      let query = dataService.supabase
        .from('xq_user_reports')
        .select(`
          *,
          reporter:xq_user_profiles!reporter_id(id, email, username),
          reported_user:xq_user_profiles!reported_user_id(id, email, username)
        `)

      if (filters.status) {
        query = query.eq('status', filters.status)
      }

      if (filters.type) {
        query = query.eq('report_type', filters.type)
      }

      if (filters.userId) {
        query = query.eq('reported_user_id', filters.userId)
      }

      const from = (page - 1) * pageSize
      const to = from + pageSize - 1
      
      query = query
        .order('created_at', { ascending: false })
        .range(from, to)

      const { data, error, count } = await query

      if (error) throw error

      return {
        reports: data || [],
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize)
      }
    } catch (error) {
      console.error('获取用户举报失败:', error)
      throw error
    }
  }

  /**
   * 处理用户举报
   */
  async handleReport(
    reportId: UUID,
    action: 'dismiss' | 'warn' | 'suspend' | 'ban',
    reason?: string
  ): Promise<void> {
    try {
      const { error } = await dataService.supabase
        .from('xq_user_reports')
        .update({
          status: 'resolved',
          resolution: action,
          resolution_reason: reason,
          resolved_at: new Date().toISOString(),
          resolved_by: 'current-admin-id', // TODO: 从认证上下文获取
          updated_at: new Date().toISOString()
        })
        .eq('id', reportId)

      if (error) throw error
    } catch (error) {
      console.error('处理用户举报失败:', error)
      throw error
    }
  }

  // ============================================
  // 统计分析
  // ============================================

  /**
   * 获取审核统计数据
   */
  async getModerationStatistics(): Promise<ModerationStatistics> {
    try {
      // 这里应该执行多个查询来获取统计数据
      // 为了示例，返回模拟数据
      return {
        totalReviewed: 15420,
        approvedCount: 13250,
        rejectedCount: 1890,
        pendingCount: 280,
        aiAccuracy: 0.87,
        averageReviewTime: 4.2,
        dailyVolume: 850,
        weeklyTrend: [
          { date: '2025-08-29', approved: 120, rejected: 15, pending: 8 },
          { date: '2025-08-30', approved: 135, rejected: 22, pending: 12 },
          { date: '2025-08-31', approved: 142, rejected: 18, pending: 6 },
          { date: '2025-09-01', approved: 156, rejected: 25, pending: 14 },
          { date: '2025-09-02', approved: 134, rejected: 19, pending: 9 },
          { date: '2025-09-03', approved: 148, rejected: 31, pending: 18 },
          { date: '2025-09-04', approved: 162, rejected: 24, pending: 11 }
        ],
        violationTypes: [
          { type: 'spam', count: 420, percentage: 22.2 },
          { type: 'hate_speech', count: 185, percentage: 9.8 },
          { type: 'adult_content', count: 156, percentage: 8.3 },
          { type: 'violence', count: 92, percentage: 4.9 },
          { type: 'harassment', count: 68, percentage: 3.6 }
        ],
        reviewerStats: [
          { reviewerId: 'admin-1', reviewed: 1250, accuracy: 0.92 },
          { reviewerId: 'admin-2', reviewed: 980, accuracy: 0.89 },
          { reviewerId: 'admin-3', reviewed: 756, accuracy: 0.94 }
        ]
      }
    } catch (error) {
      console.error('获取审核统计失败:', error)
      throw error
    }
  }

  // ============================================
  // 工具方法
  // ============================================

  /**
   * 提取关键词
   */
  private extractKeywords(content: string): string[] {
    // 简单的关键词提取逻辑
    const words = content.toLowerCase()
      .replace(/[^\u4e00-\u9fa5a-z0-9\s]/g, '')
      .split(/\s+/)
      .filter(word => word.length > 1)

    const frequency: { [key: string]: number } = {}
    words.forEach(word => {
      frequency[word] = (frequency[word] || 0) + 1
    })

    return Object.entries(frequency)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([word]) => word)
  }

  /**
   * 导出审核数据
   */
  async exportModerationData(filters: ModerationFilters = {}): Promise<string> {
    try {
      const { records } = await this.getModerationRecords(filters, 1, 10000) // 最多导出1万条

      const headers = [
        'ID', '内容类型', '状态', '创建时间', '审核时间', 'AI置信度', 
        '违规类型', '审核员', '原因'
      ]

      const csvData = records.map(record => [
        record.id,
        record.content_type,
        record.status,
        new Date(record.created_at).toLocaleString(),
        record.reviewed_at ? new Date(record.reviewed_at).toLocaleString() : '',
        record.ai_confidence?.toFixed(2) || '',
        record.violations?.map(v => v.type).join(';') || '',
        record.reviewed_by || '',
        record.reason || ''
      ])

      const csv = [headers, ...csvData].map(row => 
        row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
      ).join('\n')

      return csv
    } catch (error) {
      console.error('导出审核数据失败:', error)
      throw error
    }
  }
}

// 导出单例实例
export const moderationService = ModerationService.getInstance()

// 导出类型
export type { ModerationService }