/**
 * 星趣后台管理系统 - 智能推荐管理组件
 * 提供推荐算法管理、性能监控和数据分析的完整界面
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
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
  Activity,
  Settings,
  Download,
  Play,
  Pause,
  AlertTriangle,
  CheckCircle
} from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Input } from '@/components/ui/Input'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { Progress } from '@/components/ui/Progress'
import { useRecommendationManagement } from '@/lib/hooks/useRecommendationManagement'
import { cn } from '@/lib/utils'

const RecommendationManager: React.FC = () => {
  const {
    // 数据状态
    trendingRecs,
    personalizedRecs,
    searchRecs,
    stats,
    analytics,
    
    // 加载状态
    loading,
    processing,
    error,
    
    // 推荐管理
    loadStats,
    loadTrendingRecommendations,
    loadPersonalizedRecommendations,
    searchRecommendations,
    refreshRecommendations,
    
    // 算法分析
    loadAnalytics,
    testAlgorithm,
    
    // 实时监控
    startMonitoring,
    stopMonitoring,
    monitoringActive,
    
    // 工具方法
    clearError,
    exportRecommendationData
  } = useRecommendationManagement()

  // 本地状态
  const [searchQuery, setSearchQuery] = useState('')
  const [testUserId, setTestUserId] = useState('test-user-123')
  const [selectedAlgorithm, setSelectedAlgorithm] = useState('trending')
  const [testResults, setTestResults] = useState<any[]>([])

  // 初始化加载
  useEffect(() => {
    refreshRecommendations()
    loadAnalytics()
  }, [])

  // 搜索处理
  const handleSearchRecommendations = async () => {
    if (!searchQuery.trim()) return
    await searchRecommendations(searchQuery)
  }

  // 算法测试处理
  const handleTestAlgorithm = async () => {
    try {
      const results = await testAlgorithm(selectedAlgorithm, 5)
      setTestResults(results)
    } catch (error) {
      console.error('算法测试失败:', error)
    }
  }

  // 数据导出处理
  const handleExportData = async () => {
    try {
      const csvUrl = await exportRecommendationData()
      const link = document.createElement('a')
      link.href = csvUrl
      link.download = `recommendation_data_${new Date().toISOString().split('T')[0]}.csv`
      link.click()
    } catch (error) {
      console.error('数据导出失败:', error)
    }
  }

  // 格式化日期
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('zh-CN')
  }

  // 获取分类颜色
  const getCategoryColor = (category: any) => {
    const colors = {
      trending: 'bg-red-100 text-red-800',
      personalized: 'bg-blue-100 text-blue-800',
      category_based: 'bg-green-100 text-green-800',
      collaborative: 'bg-purple-100 text-purple-800',
      content_based: 'bg-orange-100 text-orange-800'
    }
    return colors[category] || 'bg-gray-100 text-gray-800'
  }

  // 获取分类名称
  const getCategoryName = (category: any) => {
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
    <div className="space-y-6">
      {/* 错误提示 */}
      {error && (
        <div className="flex items-center justify-between p-4 bg-red-50 border border-red-200 rounded-lg">
          <div className="flex items-center space-x-2">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <span className="text-red-700">{error}</span>
          </div>
          <Button variant="ghost" size="sm" onClick={clearError}>
            ✕
          </Button>
        </div>
      )}

      {/* 页面标题和控制按钮 */}
      <div className="flex items-start justify-between">
        <div className="max-w-2xl">
          <h1 className="text-3xl font-bold text-foreground">智能推荐系统管理</h1>
          <p className="text-muted-foreground mt-2">
            管理推荐算法、监控系统性能并分析推荐效果
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <Button
            variant="secondary"
            onClick={refreshRecommendations}
            disabled={loading}
            className="flex items-center space-x-2"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>刷新数据</span>
          </Button>
          
          <Button
            variant="outline"
            onClick={monitoringActive ? stopMonitoring : startMonitoring}
            className={cn(
              "flex items-center space-x-2",
              monitoringActive && "bg-green-50 text-green-700 border-green-200"
            )}
          >
            {monitoringActive ? <Pause size={16} /> : <Play size={16} />}
            <span>{monitoringActive ? '停止监控' : '开始监控'}</span>
          </Button>
          
          <Button
            variant="outline"
            onClick={handleExportData}
            className="flex items-center space-x-2"
          >
            <Download size={16} />
            <span>导出数据</span>
          </Button>
        </div>
      </div>

      {/* 统计卡片 */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
              <CardTitle className="text-sm font-medium">推荐成功率</CardTitle>
              <Target className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {analytics ? Math.round(analytics.success_rate * 100) : 0}%
              </div>
              <p className="text-xs text-muted-foreground">
                用户参与率: {analytics ? Math.round(analytics.user_engagement_rate * 100) : 0}%
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">系统状态</CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5 text-green-500" />
                <span className="text-sm font-medium">正常运行</span>
              </div>
              <p className="text-xs text-muted-foreground">
                监控状态: {monitoringActive ? '活跃' : '暂停'}
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* 主要功能标签页 */}
      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview">概览</TabsTrigger>
          <TabsTrigger value="algorithms">算法管理</TabsTrigger>
          <TabsTrigger value="testing">测试工具</TabsTrigger>
          <TabsTrigger value="analytics">数据分析</TabsTrigger>
          <TabsTrigger value="monitoring">实时监控</TabsTrigger>
        </TabsList>

        {/* 概览标签页 */}
        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 搜索推荐测试 */}
            <Card>
              <CardHeader>
                <div className="flex items-center gap-3">
                  <Search className="h-5 w-5 text-primary" />
                  <div>
                    <CardTitle>搜索推荐测试</CardTitle>
                    <CardDescription>测试基于关键词的搜索推荐功能</CardDescription>
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
                    disabled={!searchQuery.trim() || processing}
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

            {/* API接口状态 */}
            <Card>
              <CardHeader>
                <div className="flex items-center gap-3">
                  <BarChart3 className="h-5 w-5 text-primary" />
                  <div>
                    <CardTitle>API接口状态</CardTitle>
                    <CardDescription>推荐系统API接口运行状态</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {[
                    { endpoint: '/api/recommendations/trending', desc: '趋势推荐', status: 'active' },
                    { endpoint: '/api/recommendations/personalized', desc: '个性化推荐', status: 'active' },
                    { endpoint: '/api/recommendations/category', desc: '分类推荐', status: 'active' },
                    { endpoint: '/api/recommendations/search', desc: '搜索推荐', status: 'active' },
                    { endpoint: '/api/recommendations/stats', desc: '统计信息', status: 'active' }
                  ].map((api, index) => (
                    <div key={index} className="flex items-center justify-between p-2 border rounded-lg">
                      <div className="flex-1">
                        <code className="text-sm font-mono bg-muted px-2 py-1 rounded">
                          {api.endpoint}
                        </code>
                        <p className="text-xs text-muted-foreground mt-1">{api.desc}</p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                        <span className="text-xs text-green-600">正常</span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* 热门推荐展示 */}
          <Card>
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
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
                        使用: {rec.agent.usage_count || 0}
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
                      <Progress value={Math.min(rec.score, 100)} className="h-1.5 mt-1" />
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 算法管理标签页 */}
        <TabsContent value="algorithms" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 算法性能对比 */}
            <Card>
              <CardHeader>
                <CardTitle>算法性能对比</CardTitle>
                <CardDescription>各推荐算法的性能指标对比</CardDescription>
              </CardHeader>
              <CardContent>
                {analytics?.algorithm_performance && (
                  <div className="space-y-4">
                    {Object.entries(analytics.algorithm_performance).map(([algorithm, performance]) => (
                      <div key={algorithm} className="space-y-2">
                        <div className="flex justify-between items-center">
                          <span className="text-sm font-medium capitalize">{algorithm}</span>
                          <span className="text-sm text-muted-foreground">
                            {Math.round(performance * 100)}%
                          </span>
                        </div>
                        <Progress value={performance * 100} className="h-2" />
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* 算法配置 */}
            <Card>
              <CardHeader>
                <CardTitle>算法配置</CardTitle>
                <CardDescription>推荐算法参数设置</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">默认推荐算法</label>
                  <select className="w-full p-2 border rounded-md">
                    <option value="hybrid">混合算法</option>
                    <option value="trending">趋势算法</option>
                    <option value="collaborative">协同过滤</option>
                    <option value="content_based">内容推荐</option>
                  </select>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">推荐数量限制</label>
                  <Input type="number" placeholder="20" min="1" max="100" />
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">缓存时间(分钟)</label>
                  <Input type="number" placeholder="15" min="1" max="60" />
                </div>
                
                <Button className="w-full">
                  <Settings className="h-4 w-4 mr-2" />
                  保存配置
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* 测试工具标签页 */}
        <TabsContent value="testing" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>算法测试工具</CardTitle>
              <CardDescription>测试不同推荐算法的效果</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">选择算法</label>
                  <select 
                    className="w-full p-2 border rounded-md"
                    value={selectedAlgorithm}
                    onChange={(e) => setSelectedAlgorithm(e.target.value)}
                  >
                    <option value="trending">趋势算法</option>
                    <option value="personalized">个性化算法</option>
                    <option value="category_based">分类算法</option>
                    <option value="content_based">内容算法</option>
                  </select>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">测试用户ID</label>
                  <Input
                    value={testUserId}
                    onChange={(e) => setTestUserId(e.target.value)}
                    placeholder="test-user-123"
                  />
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">操作</label>
                  <Button 
                    onClick={handleTestAlgorithm}
                    disabled={processing}
                    className="w-full"
                  >
                    {processing ? '测试中...' : '开始测试'}
                  </Button>
                </div>
              </div>
              
              {/* 测试结果 */}
              {testResults.length > 0 && (
                <div className="mt-6 space-y-4">
                  <h3 className="text-lg font-semibold">测试结果</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {testResults.map((result, index) => (
                      <div key={index} className="p-3 border rounded-lg">
                        <div className="flex items-center justify-between mb-2">
                          <span className="font-medium text-sm">{result.agent.name}</span>
                          <Badge variant="outline" className="text-xs">
                            {Math.round(result.score)}%
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground mb-1">
                          {result.agent.description?.slice(0, 50)}...
                        </p>
                        <p className="text-xs text-blue-600">{result.reason}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* 数据分析标签页 */}
        <TabsContent value="analytics" className="space-y-6">
          {stats && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* 分类分布 */}
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

              {/* 热门标签 */}
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
        </TabsContent>

        {/* 实时监控标签页 */}
        <TabsContent value="monitoring" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* 系统健康状态 */}
            <Card>
              <CardHeader>
                <CardTitle>系统健康</CardTitle>
                <CardDescription>推荐系统整体状态</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center space-x-2">
                  <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                  <span className="font-medium">系统正常</span>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-sm">API响应时间</span>
                    <span className="text-sm text-green-600">45ms</span>
                  </div>
                  <Progress value={85} className="h-2" />
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-sm">系统负载</span>
                    <span className="text-sm text-yellow-600">65%</span>
                  </div>
                  <Progress value={65} className="h-2" />
                </div>
              </CardContent>
            </Card>

            {/* 实时指标 */}
            <Card>
              <CardHeader>
                <CardTitle>实时指标</CardTitle>
                <CardDescription>当前推荐系统性能</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="text-center">
                  <div className="text-2xl font-bold text-blue-600">128</div>
                  <div className="text-sm text-muted-foreground">每分钟推荐请求</div>
                </div>
                
                <div className="text-center">
                  <div className="text-2xl font-bold text-green-600">92%</div>
                  <div className="text-sm text-muted-foreground">推荐命中率</div>
                </div>
                
                <div className="text-center">
                  <div className="text-2xl font-bold text-purple-600">3.2s</div>
                  <div className="text-sm text-muted-foreground">平均响应时间</div>
                </div>
              </CardContent>
            </Card>

            {/* 监控控制 */}
            <Card>
              <CardHeader>
                <CardTitle>监控控制</CardTitle>
                <CardDescription>监控系统控制面板</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">实时监控</span>
                  <Badge variant={monitoringActive ? "default" : "secondary"}>
                    {monitoringActive ? '运行中' : '已停止'}
                  </Badge>
                </div>
                
                <Button
                  variant={monitoringActive ? "secondary" : "default"}
                  onClick={monitoringActive ? stopMonitoring : startMonitoring}
                  className="w-full"
                >
                  {monitoringActive ? (
                    <>
                      <Pause className="h-4 w-4 mr-2" />
                      停止监控
                    </>
                  ) : (
                    <>
                      <Play className="h-4 w-4 mr-2" />
                      开始监控
                    </>
                  )}
                </Button>
                
                <div className="text-xs text-muted-foreground text-center">
                  监控频率: 15秒更新一次
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default RecommendationManager