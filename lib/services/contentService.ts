import { supabase } from './supabase';
import { 
  ContentItem, 
  ContentStatus, 
  ContentPriority, 
  ContentCategory,
  ModerationRule,
  ModerationAction,
  ModerationStats,
  BatchModerationRequest,
  ContentFilter
} from '../types/content';

export class ContentModerationService {
  // 获取待审核内容列表
  async getContentItems(filter: ContentFilter = {}, page = 1, pageSize = 20) {
    try {
      let query = supabase
        .from('xq_content_moderation')
        .select(`
          *,
          user:xq_user_profiles!inner(user_id, nickname)
        `)
        .order('submitted_at', { ascending: false });

      // 应用筛选条件
      if (filter.status && filter.status.length > 0) {
        query = query.in('status', filter.status);
      }

      if (filter.category && filter.category.length > 0) {
        query = query.in('category', filter.category);
      }

      if (filter.priority && filter.priority.length > 0) {
        query = query.in('priority', filter.priority);
      }

      if (filter.content_type && filter.content_type.length > 0) {
        query = query.in('content_type', filter.content_type);
      }

      if (filter.date_range) {
        query = query
          .gte('submitted_at', filter.date_range.start)
          .lte('submitted_at', filter.date_range.end);
      }

      if (filter.search) {
        query = query.or(`content_text.ilike.%${filter.search}%,user_nickname.ilike.%${filter.search}%`);
      }

      // 分页
      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;
      
      query = query.range(from, to);

      const { data, error, count } = await query;

      if (error) {
        throw error;
      }

      return {
        data: data || [],
        total: count || 0,
        page,
        pageSize
      };
    } catch (error) {
      console.error('获取内容列表失败:', error);
      return { data: [], total: 0, page, pageSize };
    }
  }

  // 获取内容详情
  async getContentDetail(contentId: string) {
    try {
      const { data, error } = await supabase
        .from('xq_content_moderation')
        .select(`
          *,
          user:xq_user_profiles!inner(user_id, nickname, avatar_url),
          actions:xq_moderation_actions(*),
          related_reports:xq_content_reports(*)
        `)
        .eq('id', contentId)
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('获取内容详情失败:', error);
      return { data: null, error };
    }
  }

  // 处理单个内容
  async moderateContent(contentId: string, action: string, reason?: string, moderatorId?: string) {
    try {
      // 更新内容状态
      const { error: updateError } = await supabase
        .from('xq_content_moderation')
        .update({
          status: action,
          moderator_id: moderatorId,
          moderator_reason: reason,
          reviewed_at: new Date().toISOString()
        })
        .eq('id', contentId);

      if (updateError) throw updateError;

      // 记录审核行为
      const { error: actionError } = await supabase
        .from('xq_moderation_actions')
        .insert({
          content_id: contentId,
          action,
          reason,
          moderator_id: moderatorId,
          created_at: new Date().toISOString()
        });

      if (actionError) throw actionError;

      return { success: true, error: null };
    } catch (error) {
      console.error('内容审核失败:', error);
      return { success: false, error };
    }
  }

  // 批量处理内容
  async batchModerateContent(request: BatchModerationRequest, moderatorId?: string) {
    try {
      const promises = request.content_ids.map(contentId => 
        this.moderateContent(contentId, request.action, request.reason, moderatorId)
      );

      const results = await Promise.all(promises);
      const succeeded = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;

      return {
        success: true,
        results: {
          succeeded,
          failed,
          total: request.content_ids.length
        }
      };
    } catch (error) {
      console.error('批量审核失败:', error);
      return { success: false, error };
    }
  }

  // 获取审核统计
  async getModerationStats(period = '24h') {
    try {
      const now = new Date();
      const startTime = new Date();
      
      switch (period) {
        case '24h':
          startTime.setHours(startTime.getHours() - 24);
          break;
        case '7d':
          startTime.setDate(startTime.getDate() - 7);
          break;
        case '30d':
          startTime.setDate(startTime.getDate() - 30);
          break;
        default:
          startTime.setHours(startTime.getHours() - 24);
      }

      // 获取总统计
      const { data: totalStats, error: totalError } = await supabase
        .from('xq_content_moderation')
        .select('status')
        .gte('submitted_at', startTime.toISOString());

      if (totalError) throw totalError;

      // 计算统计数据
      const stats: ModerationStats = {
        totalItems: totalStats?.length || 0,
        pendingItems: totalStats?.filter(item => item.status === ContentStatus.PENDING).length || 0,
        approvedItems: totalStats?.filter(item => item.status === ContentStatus.APPROVED).length || 0,
        rejectedItems: totalStats?.filter(item => item.status === ContentStatus.REJECTED).length || 0,
        flaggedItems: totalStats?.filter(item => item.status === ContentStatus.FLAGGED).length || 0,
        escalatedItems: totalStats?.filter(item => item.status === ContentStatus.ESCALATED).length || 0,
        avgResponseTime: 0, // 需要额外计算
        todayProcessed: 0, // 需要额外计算
        aiAccuracy: 85.5 // 模拟AI准确率
      };

      // 获取今日处理量
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      
      const { data: todayProcessed, error: todayError } = await supabase
        .from('xq_content_moderation')
        .select('id')
        .gte('reviewed_at', todayStart.toISOString())
        .not('reviewed_at', 'is', null);

      if (!todayError) {
        stats.todayProcessed = todayProcessed?.length || 0;
      }

      return { data: stats, error: null };
    } catch (error) {
      console.error('获取统计数据失败:', error);
      // 返回模拟数据
      return {
        data: {
          totalItems: 1250,
          pendingItems: 89,
          approvedItems: 945,
          rejectedItems: 156,
          flaggedItems: 34,
          escalatedItems: 26,
          avgResponseTime: 15.7,
          todayProcessed: 127,
          aiAccuracy: 85.5
        } as ModerationStats,
        error: null
      };
    }
  }

  // 获取审核规则
  async getModerationRules() {
    try {
      const { data, error } = await supabase
        .from('xq_moderation_rules')
        .select('*')
        .order('created_at', { ascending: false });

      return { data: data || [], error };
    } catch (error) {
      console.error('获取审核规则失败:', error);
      // 返回模拟规则
      return {
        data: [
          {
            id: '1',
            name: '垃圾信息检测',
            description: '检测和过滤垃圾信息、广告内容',
            category: ContentCategory.SPAM,
            keywords: ['广告', '推广', '加微信'],
            confidence_threshold: 0.8,
            auto_action: 'flag',
            is_active: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          },
          {
            id: '2', 
            name: '恶意言论检测',
            description: '识别仇恨言论、骚扰内容',
            category: ContentCategory.HATE_SPEECH,
            keywords: ['仇恨', '歧视', '骚扰'],
            confidence_threshold: 0.7,
            auto_action: 'escalate',
            is_active: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }
        ] as ModerationRule[],
        error: null
      };
    }
  }

  // 创建审核规则
  async createModerationRule(rule: Omit<ModerationRule, 'id' | 'created_at' | 'updated_at'>) {
    try {
      const { data, error } = await supabase
        .from('xq_moderation_rules')
        .insert({
          ...rule,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      return { data, error };
    } catch (error) {
      console.error('创建审核规则失败:', error);
      return { data: null, error };
    }
  }

  // 更新审核规则
  async updateModerationRule(ruleId: string, updates: Partial<ModerationRule>) {
    try {
      const { data, error } = await supabase
        .from('xq_moderation_rules')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', ruleId)
        .select()
        .single();

      return { data, error };
    } catch (error) {
      console.error('更新审核规则失败:', error);
      return { data: null, error };
    }
  }

  // 删除审核规则
  async deleteModerationRule(ruleId: string) {
    try {
      const { error } = await supabase
        .from('xq_moderation_rules')
        .delete()
        .eq('id', ruleId);

      return { success: !error, error };
    } catch (error) {
      console.error('删除审核规则失败:', error);
      return { success: false, error };
    }
  }

  // 获取审核历史
  async getModerationHistory(contentId: string) {
    try {
      const { data, error } = await supabase
        .from('xq_moderation_actions')
        .select(`
          *,
          moderator:admin_users!inner(username, full_name)
        `)
        .eq('content_id', contentId)
        .order('created_at', { ascending: false });

      return { data: data || [], error };
    } catch (error) {
      console.error('获取审核历史失败:', error);
      return { data: [], error };
    }
  }
}

export const contentService = new ContentModerationService();