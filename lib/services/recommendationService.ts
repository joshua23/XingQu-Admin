/**
 * 智能推荐系统服务
 * 为Flutter App提供智能体推荐API
 */

import { supabase } from './supabase'
import { createClient } from '@supabase/supabase-js'

// 创建服务端客户端用于推荐系统，绕过RLS
const supabaseServiceRole = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://wqdpqhfqrxvssxifpmvt.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZHBxaGZxcnh2c3N4aWZwbXZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjE0Mjk0NiwiZXhwIjoyMDY3NzE4OTQ2fQ.A632wk9FONoPgb6QEnqqU-C5oVGzqkhAXLEOo4X6WnQ',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
)

// 智能体数据接口
export interface Agent {
  id: string
  name: string
  description: string
  avatar_url?: string
  creator_id?: string
  created_at: string
  is_active: boolean
  category: string
  tags: string[]
  usage_count?: number
  rating_average?: number
  popularity_score?: number
}

// 推荐结果接口
export interface RecommendationResult {
  agent: Agent
  score: number
  reason: string
  category: 'trending' | 'personalized' | 'category_based' | 'collaborative' | 'content_based'
}

// 推荐请求参数
export interface RecommendationRequest {
  user_id?: string
  category?: string
  limit?: number
  exclude_ids?: string[]
  user_preferences?: string[]
  context?: 'home' | 'search' | 'category' | 'profile'
}

class RecommendationService {
  
  /**
   * 获取所有活跃智能体
   */
  async getActiveAgents(): Promise<{ data: Agent[] | null, error: Error | null }> {
    try {
      const { data, error } = await supabaseServiceRole
        .from('xq_agents')
        .select(`
          id,
          name,
          description,
          avatar_id,
          user_id,
          created_at,
          updated_at,
          is_public,
          usage_count,
          tags,
          gender
        `)
        .eq('is_public', true)
        .eq('is_deleted', false)
        .order('created_at', { ascending: false })

      if (error) throw error

      // 计算使用统计和人气分数
      const agentsWithStats = await this.enrichAgentsWithStats(data || [])

      return { data: agentsWithStats, error: null }
    } catch (error) {
      console.error('获取活跃智能体失败:', error)
      return { data: null, error: error as Error }
    }
  }

  /**
   * 为智能体数据添加统计信息
   */
  private async enrichAgentsWithStats(agents: any[]): Promise<Agent[]> {
    return agents.map((agent) => {
      // 计算人气分数（基于创建时间、使用次数等）
      const daysSinceCreated = (Date.now() - new Date(agent.created_at).getTime()) / (1000 * 60 * 60 * 24)
      const recencyScore = Math.max(0, 30 - daysSinceCreated) / 30 // 最近30天内创建的得高分
      const usageScore = Math.min((agent.usage_count || 0) / 100, 1) // 使用次数标准化到0-1
      const popularityScore = (recencyScore * 0.3) + (usageScore * 0.7)

      // 根据tags和description生成分类
      const category = this.inferCategoryFromAgent(agent)

      return {
        id: agent.id,
        name: agent.name,
        description: agent.description,
        avatar_url: agent.avatar_id, // 暂时使用avatar_id
        creator_id: agent.user_id,
        created_at: agent.created_at,
        is_active: agent.is_public,
        category: category,
        tags: agent.tags || [],
        usage_count: agent.usage_count || 0,
        popularity_score: popularityScore,
        rating_average: 4.5 // 默认评分，后续可以从评分表获取
      } as Agent
    })
  }

  /**
   * 根据智能体信息推断分类
   */
  private inferCategoryFromAgent(agent: any): string {
    const tags = agent.tags || []
    const description = agent.description.toLowerCase()
    const name = agent.name.toLowerCase()

    // 根据标签和描述内容推断分类
    if (tags.includes('学习') || description.includes('学习') || description.includes('教育')) {
      return '学习教育'
    }
    if (tags.includes('娱乐') || description.includes('娱乐') || description.includes('游戏')) {
      return '娱乐休闲'
    }
    if (tags.includes('工作') || description.includes('工作') || description.includes('助手')) {
      return '工作助手'
    }
    if (description.includes('音乐') || description.includes('创作') || name.includes('制作')) {
      return '创意制作'
    }
    if (description.includes('聊天') || description.includes('陪伴')) {
      return '社交聊天'
    }
    
    return '综合服务'
  }

  /**
   * 趋势推荐 - 最近热门的智能体
   */
  async getTrendingRecommendations(limit: number = 10): Promise<RecommendationResult[]> {
    const { data: agents } = await this.getActiveAgents()
    if (!agents) return []

    // 按人气分数和使用次数排序
    const trendingAgents = agents
      .sort((a, b) => {
        const scoreA = (a.popularity_score || 0) + (a.usage_count || 0) * 0.01
        const scoreB = (b.popularity_score || 0) + (b.usage_count || 0) * 0.01
        return scoreB - scoreA
      })
      .slice(0, limit)

    return trendingAgents.map(agent => ({
      agent,
      score: (agent.popularity_score || 0) * 100,
      reason: `热门智能体，已有${agent.usage_count}次使用`,
      category: 'trending'
    }))
  }

  /**
   * 分类推荐 - 基于特定分类的推荐
   */
  async getCategoryRecommendations(category: string, limit: number = 10): Promise<RecommendationResult[]> {
    const { data: agents } = await this.getActiveAgents()
    if (!agents) return []

    const categoryAgents = agents
      .filter(agent => agent.category === category)
      .sort((a, b) => (b.popularity_score || 0) - (a.popularity_score || 0))
      .slice(0, limit)

    return categoryAgents.map(agent => ({
      agent,
      score: (agent.popularity_score || 0) * 100,
      reason: `${category}分类推荐`,
      category: 'category_based'
    }))
  }

  /**
   * 内容相似推荐 - 基于标签和描述的相似度
   */
  async getContentBasedRecommendations(
    targetAgent: Agent, 
    limit: number = 10,
    excludeIds: string[] = []
  ): Promise<RecommendationResult[]> {
    const { data: agents } = await this.getActiveAgents()
    if (!agents) return []

    const targetTags = targetAgent.tags || []
    const targetCategory = targetAgent.category

    const similarAgents = agents
      .filter(agent => 
        agent.id !== targetAgent.id && 
        !excludeIds.includes(agent.id)
      )
      .map(agent => {
        let similarity = 0
        
        // 同分类加分
        if (agent.category === targetCategory) {
          similarity += 0.4
        }
        
        // 标签相似度
        const commonTags = agent.tags?.filter(tag => targetTags.includes(tag)) || []
        const tagSimilarity = commonTags.length / Math.max(targetTags.length, agent.tags?.length || 1)
        similarity += tagSimilarity * 0.6

        return {
          agent,
          similarity
        }
      })
      .filter(item => item.similarity > 0.2)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, limit)

    return similarAgents.map(({ agent, similarity }) => ({
      agent,
      score: similarity * 100,
      reason: `与"${targetAgent.name}"相似度${Math.round(similarity * 100)}%`,
      category: 'content_based'
    }))
  }

  /**
   * 个性化推荐 - 基于用户历史行为
   */
  async getPersonalizedRecommendations(
    userId: string, 
    limit: number = 10,
    context: string = 'home'
  ): Promise<RecommendationResult[]> {
    try {
      // 获取用户使用历史
      const { data: userHistory } = await supabase
        .from('xq_tracking_events')
        .select('agent_id, event_type, created_at')
        .eq('user_id', userId)
        .eq('event_type', 'agent_usage')
        .order('created_at', { ascending: false })
        .limit(50)

      const { data: agents } = await this.getActiveAgents()
      if (!agents || !userHistory) {
        // 如果没有历史数据，返回趋势推荐
        return await this.getTrendingRecommendations(limit)
      }

      // 分析用户偏好
      const usedAgentIds = [...new Set(userHistory.map(h => h.agent_id))]
      const usedAgents = agents.filter(a => usedAgentIds.includes(a.id))
      
      // 基于用户使用过的智能体找相似的
      let recommendations: RecommendationResult[] = []
      
      for (const usedAgent of usedAgents.slice(0, 3)) { // 取最近使用的3个
        const similar = await this.getContentBasedRecommendations(
          usedAgent, 
          3, 
          [...usedAgentIds, ...recommendations.map(r => r.agent.id)]
        )
        recommendations.push(...similar)
      }

      // 去重并按分数排序
      const uniqueRecs = Array.from(
        new Map(recommendations.map(r => [r.agent.id, r])).values()
      )
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)

      // 如果推荐不够，补充趋势推荐
      if (uniqueRecs.length < limit) {
        const trendingRecs = await this.getTrendingRecommendations(limit - uniqueRecs.length)
        const excludeIds = uniqueRecs.map(r => r.agent.id)
        const additionalRecs = trendingRecs.filter(r => !excludeIds.includes(r.agent.id))
        uniqueRecs.push(...additionalRecs)
      }

      return uniqueRecs.map(rec => ({
        ...rec,
        reason: `基于你的使用习惯推荐`,
        category: 'personalized'
      }))

    } catch (error) {
      console.error('个性化推荐失败:', error)
      // 降级到趋势推荐
      return await this.getTrendingRecommendations(limit)
    }
  }

  /**
   * 综合推荐 - 混合多种推荐策略
   */
  async getMixedRecommendations(request: RecommendationRequest): Promise<{
    trending: RecommendationResult[]
    personalized: RecommendationResult[]
    category_based: RecommendationResult[]
    total_count: number
  }> {
    const {
      user_id,
      category,
      limit = 20,
      exclude_ids = [],
      context = 'home'
    } = request

    const [trending, personalized, categoryBased] = await Promise.all([
      this.getTrendingRecommendations(Math.ceil(limit * 0.4)), // 40% 趋势推荐
      user_id ? 
        this.getPersonalizedRecommendations(user_id, Math.ceil(limit * 0.4), context) : 
        Promise.resolve([]), // 40% 个性化推荐
      category ? 
        this.getCategoryRecommendations(category, Math.ceil(limit * 0.2)) : 
        Promise.resolve([]) // 20% 分类推荐
    ])

    // 过滤排除的ID
    const filterExcluded = (recs: RecommendationResult[]) => 
      recs.filter(r => !exclude_ids.includes(r.agent.id))

    const filteredTrending = filterExcluded(trending)
    const filteredPersonalized = filterExcluded(personalized)
    const filteredCategoryBased = filterExcluded(categoryBased)

    return {
      trending: filteredTrending,
      personalized: filteredPersonalized,
      category_based: filteredCategoryBased,
      total_count: filteredTrending.length + filteredPersonalized.length + filteredCategoryBased.length
    }
  }

  /**
   * 搜索推荐 - 基于搜索关键词的推荐
   */
  async getSearchRecommendations(
    query: string, 
    limit: number = 10
  ): Promise<RecommendationResult[]> {
    const { data: agents } = await this.getActiveAgents()
    if (!agents) return []

    const searchTerms = query.toLowerCase().split(' ')
    
    const matchingAgents = agents
      .map(agent => {
        let relevance = 0
        const name = agent.name.toLowerCase()
        const description = agent.description.toLowerCase()
        const tags = agent.tags?.join(' ').toLowerCase() || ''
        const category = agent.category.toLowerCase()

        // 名称匹配权重最高
        searchTerms.forEach(term => {
          if (name.includes(term)) relevance += 3
          if (description.includes(term)) relevance += 2
          if (tags.includes(term)) relevance += 2
          if (category.includes(term)) relevance += 1
        })

        return { agent, relevance }
      })
      .filter(item => item.relevance > 0)
      .sort((a, b) => b.relevance - a.relevance)
      .slice(0, limit)

    return matchingAgents.map(({ agent, relevance }) => ({
      agent,
      score: relevance * 10,
      reason: `与"${query}"相关度${Math.min(relevance * 10, 100)}%`,
      category: 'content_based'
    }))
  }

  /**
   * 获取推荐统计信息
   */
  async getRecommendationStats(): Promise<{
    total_agents: number
    active_agents: number
    categories: Array<{ name: string, count: number }>
    top_tags: Array<{ tag: string, count: number }>
  }> {
    try {
      const { data: allAgents } = await supabaseServiceRole
        .from('xq_agents')
        .select('is_public, tags, name, description')
        .eq('is_deleted', false)

      if (!allAgents) {
        return {
          total_agents: 0,
          active_agents: 0,
          categories: [],
          top_tags: []
        }
      }

      const totalAgents = allAgents.length
      const activeAgents = allAgents.filter(a => a.is_public).length

      // 统计分类（推断的）
      const categoryCount = allAgents.reduce((acc: Record<string, number>, agent) => {
        const category = this.inferCategoryFromAgent(agent)
        acc[category] = (acc[category] || 0) + 1
        return acc
      }, {})

      // 统计标签
      const tagCount = allAgents.reduce((acc: Record<string, number>, agent) => {
        agent.tags?.forEach((tag: string) => {
          acc[tag] = (acc[tag] || 0) + 1
        })
        return acc
      }, {})

      return {
        total_agents: totalAgents,
        active_agents: activeAgents,
        categories: Object.entries(categoryCount)
          .map(([name, count]) => ({ name, count }))
          .sort((a, b) => b.count - a.count),
        top_tags: Object.entries(tagCount)
          .map(([tag, count]) => ({ tag, count }))
          .sort((a, b) => b.count - a.count)
          .slice(0, 20)
      }
    } catch (error) {
      console.error('获取推荐统计失败:', error)
      return {
        total_agents: 0,
        active_agents: 0,
        categories: [],
        top_tags: []
      }
    }
  }
}

export const recommendationService = new RecommendationService()