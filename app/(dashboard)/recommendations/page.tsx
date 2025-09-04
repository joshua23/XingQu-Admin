'use client'

import { useState, useEffect } from 'react'
import { 
  Brain, 
  TrendingUp, 
  Users, 
  Search, 
  Target,
  RefreshCw,
  Eye,
  Star,
  Zap,
  BarChart3,
  Tag,
  Calendar,
  Activity
} from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Input } from '@/components/ui/Input'

interface Agent {
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

interface RecommendationResult {
  agent: Agent
  score: number
  reason: string
  category: 'trending' | 'personalized' | 'category_based' | 'collaborative' | 'content_based'
}

interface RecommendationStats {
  total_agents: number
  active_agents: number
  categories: Array<{ name: string, count: number }>
  top_tags: Array<{ tag: string, count: number }>
}

const RecommendationsPage = () => {
  const [stats, setStats] = useState<RecommendationStats | null>(null)
  const [trendingRecs, setTrendingRecs] = useState<RecommendationResult[]>([])
  const [searchRecs, setSearchRecs] = useState<RecommendationResult[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [testUserId, setTestUserId] = useState('test-user-123')
  const [selectedCategory, setSelectedCategory] = useState('')

  // 加载推荐统计数据
  const loadStats = async () => {
    try {
      const response = await fetch('/api/recommendations/stats')
      const result = await response.json()
      
      if (result.success) {
        setStats(result.data)
      }
    } catch (error) {
      console.error('加载统计数据失败:', error)
    }
  }

  // 加载趋势推荐
  const loadTrendingRecommendations = async () => {
    try {
      const response = await fetch('/api/recommendations/trending?limit=8')
      const result = await response.json()
      
      if (result.success) {
        setTrendingRecs(result.data)
      }
    } catch (error) {
      console.error('加载趋势推荐失败:', error)
    }
  }

  // 搜索推荐
  const handleSearchRecommendations = async () => {
    if (!searchQuery.trim()) return

    try {
      setLoading(true)
      const response = await fetch(`/api/recommendations/search?q=${encodeURIComponent(searchQuery)}&limit=8`)
      const result = await response.json()
      
      if (result.success) {
        setSearchRecs(result.data)
      }
    } catch (error) {
      console.error('搜索推荐失败:', error)
    } finally {
      setLoading(false)
    }
  }

  // 初始化加载
  useEffect(() => {
    const initLoad = async () => {
      setLoading(true)
      await Promise.all([
        loadStats(),
        loadTrendingRecommendations()
      ])
      setLoading(false)
    }
    
    initLoad()
  }, [])

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('zh-CN')
  }

  const getCategoryColor = (category: RecommendationResult['category']) => {
    const colors = {
      trending: 'bg-red-100 text-red-800',
      personalized: 'bg-blue-100 text-blue-800',
      category_based: 'bg-green-100 text-green-800',
      collaborative: 'bg-purple-100 text-purple-800',
      content_based: 'bg-orange-100 text-orange-800'
    }
    return colors[category] || 'bg-gray-100 text-gray-800'
  }

  const getCategoryName = (category: RecommendationResult['category']) => {
    const names = {
      trending: '热门',
      personalized: '个性化',
      category_based: '分类',
      collaborative: '协同',
      content_based: '内容'
    }
    return names[category] || '其他'
  }

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="responsive-container">
      <div className="section-spacing">
        {/* 页面标题 */}
        <div className="flex items-start justify-between animate-slide-up">
          <div className="max-w-2xl">
            <h1 className="text-display-2 text-foreground">智能推荐系统</h1>
            <p className="text-muted-foreground mt-2">
              管理智能体推荐算法和API接口，为Flutter App提供个性化推荐服务
            </p>
          </div>
          
          <div className="flex items-center space-x-3">
            <Button
              variant="secondary"
              onClick={() => {
                loadStats()
                loadTrendingRecommendations()
              }}
              disabled={loading}
              className="flex items-center space-x-2"
            >
              <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
              <span>刷新数据</span>
            </Button>
          </div>
        </div>

        {/* 统计卡片 */}
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 responsive-grid-gap animate-fade-in section-gap">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">智能体总数</CardTitle>
                <Brain className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total_agents}</div>
                <p className="text-xs text-muted-foreground">
                  活跃: {stats.active_agents}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">分类数量</CardTitle>
                <Tag className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.categories.length}</div>
                <p className="text-xs text-muted-foreground">
                  标签: {stats.top_tags.length}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">API接口</CardTitle>
                <Activity className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">5</div>
                <p className="text-xs text-muted-foreground">
                  推荐接口数量
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">推荐算法</CardTitle>
                <Zap className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">4</div>
                <p className="text-xs text-muted-foreground">
                  算法类型
                </p>
              </CardContent>
            </Card>
          </div>
        )}

        {/* API测试区域 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 responsive-grid-gap section-gap">
          {/* 搜索推荐测试 */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-3">
                <Search className="h-5 w-5 text-primary" />
                <div>
                  <CardTitle>搜索推荐测试</CardTitle>
                  <CardDescription>测试基于关键词的搜索推荐API</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex space-x-2">
                <Input
                  placeholder="输入搜索关键词..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSearchRecommendations()}
                />
                <Button 
                  onClick={handleSearchRecommendations}
                  disabled={!searchQuery.trim() || loading}
                >
                  搜索
                </Button>
              </div>
              
              {searchRecs.length > 0 && (
                <div className="space-y-2 max-h-60 overflow-y-auto">
                  <p className="text-sm text-muted-foreground">找到 {searchRecs.length} 个推荐结果:</p>
                  {searchRecs.map((rec, index) => (
                    <div key={index} className="flex items-center justify-between p-2 bg-muted/30 rounded-lg">
                      <div className="flex-1">
                        <p className="font-medium text-sm">{rec.agent.name}</p>
                        <p className="text-xs text-muted-foreground">{rec.reason}</p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Badge variant="secondary" className="text-xs">
                          {Math.round(rec.score)}%
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* API接口列表 */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-3">
                <BarChart3 className="h-5 w-5 text-primary" />
                <div>
                  <CardTitle>API接口列表</CardTitle>
                  <CardDescription>Flutter App可用的推荐API接口</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {[
                  { endpoint: '/api/recommendations', desc: '综合推荐', method: 'GET' },
                  { endpoint: '/api/recommendations/trending', desc: '趋势推荐', method: 'GET' },
                  { endpoint: '/api/recommendations/personalized', desc: '个性化推荐', method: 'GET' },
                  { endpoint: '/api/recommendations/category', desc: '分类推荐', method: 'GET' },
                  { endpoint: '/api/recommendations/search', desc: '搜索推荐', method: 'GET' },
                  { endpoint: '/api/recommendations/stats', desc: '统计信息', method: 'GET' }
                ].map((api, index) => (
                  <div key={index} className="flex items-center justify-between p-2 border rounded-lg">
                    <div>
                      <code className="text-sm font-mono bg-muted px-2 py-1 rounded">
                        {api.endpoint}
                      </code>
                      <p className="text-xs text-muted-foreground mt-1">{api.desc}</p>
                    </div>
                    <Badge variant="outline" className="text-xs">
                      {api.method}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* 热门趋势推荐 */}
        <Card className="animate-fade-in section-gap">
          <CardHeader>
            <div className="flex items-center gap-3">
              <TrendingUp className="h-5 w-5 text-primary" />
              <div>
                <CardTitle>热门趋势推荐</CardTitle>
                <CardDescription>
                  当前最受欢迎的智能体推荐 ({trendingRecs.length} 个结果)
                </CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 responsive-grid-gap">
              {trendingRecs.map((rec, index) => (
                <div key={index} className="border rounded-lg p-4 hover:bg-muted/50 transition-colors">
                  <div className="flex items-start justify-between mb-2">
                    <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                      <Brain size={16} className="text-primary" />
                    </div>
                    <div className="flex items-center space-x-1">
                      <Badge className={`text-xs ${getCategoryColor(rec.category)}`}>
                        {getCategoryName(rec.category)}
                      </Badge>
                    </div>
                  </div>
                  
                  <h3 className="font-semibold text-sm mb-1">{rec.agent.name}</h3>
                  <p className="text-xs text-muted-foreground mb-2 line-clamp-2">
                    {rec.agent.description}
                  </p>
                  
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-muted-foreground">
                      使用次数: {rec.agent.usage_count || 0}
                    </span>
                    <div className="flex items-center space-x-1">
                      <Star size={12} className="text-yellow-500" />
                      <span>{rec.agent.rating_average || 4.5}</span>
                    </div>
                  </div>
                  
                  <div className="mt-2 pt-2 border-t">
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-muted-foreground">推荐分数</span>
                      <span className="text-xs font-semibold">{Math.round(rec.score)}%</span>
                    </div>
                    <div className="w-full bg-muted rounded-full h-1.5 mt-1">
                      <div 
                        className="bg-primary rounded-full h-1.5 transition-all duration-500"
                        style={{ width: `${Math.min(rec.score, 100)}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* 分类统计 */}
        {stats && (
          <div className="grid grid-cols-1 lg:grid-cols-2 responsive-grid-gap section-gap">
            <Card>
              <CardHeader>
                <CardTitle>分类分布</CardTitle>
                <CardDescription>智能体按分类的分布情况</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {stats.categories.slice(0, 8).map((cat, index) => (
                    <div key={index} className="flex items-center justify-between">
                      <span className="text-sm font-medium">{cat.name}</span>
                      <div className="flex items-center space-x-2">
                        <div className="w-20 bg-muted rounded-full h-2">
                          <div 
                            className="bg-primary rounded-full h-2 transition-all duration-500"
                            style={{ width: `${(cat.count / stats.total_agents) * 100}%` }}
                          ></div>
                        </div>
                        <span className="text-sm text-muted-foreground min-w-[2rem] text-right">
                          {cat.count}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>热门标签</CardTitle>
                <CardDescription>最常用的智能体标签</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {stats.top_tags.slice(0, 20).map((tag, index) => (
                    <Badge key={index} variant="secondary" className="text-xs">
                      {tag.tag} ({tag.count})
                    </Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </div>
  )
}

export default RecommendationsPage