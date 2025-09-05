/**
 * 星趣后台管理系统 - 优化用户管理页面
 * 集成EnhancedUserManager、UserTagSystem和批量操作功能
 * Created: 2025-09-05, Updated: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Separator } from '@/components/ui/separator'
import EnhancedUserManager from '@/components/users/EnhancedUserManager'
import UserTagSystem from '@/components/UserTagSystem'
import { 
  Users, 
  Tag, 
  BarChart3, 
  Settings, 
  TrendingUp, 
  Crown, 
  Shield, 
  AlertTriangle,
  CheckCircle,
  Download,
  Upload,
  RefreshCw
} from 'lucide-react'
import type { UserTag, TaggedUser } from '@/components/UserTagSystem'

// 模拟数据 - 实际项目中应该从API获取
const mockTags: UserTag[] = [
  {
    id: '1',
    name: '活跃用户',
    color: '#10B981',
    description: '最近30天内有活动的用户',
    category: 'behavior',
    userCount: 1250,
    isSystem: true,
    createdAt: '2025-01-01',
    updatedAt: '2025-01-01'
  },
  {
    id: '2', 
    name: '付费用户',
    color: '#F59E0B',
    description: '已购买付费套餐的用户',
    category: 'demographic',
    userCount: 350,
    isSystem: true,
    createdAt: '2025-01-01',
    updatedAt: '2025-01-01'
  },
  {
    id: '3',
    name: '高风险用户',
    color: '#EF4444', 
    description: '存在违规行为风险的用户',
    category: 'risk',
    userCount: 45,
    isSystem: false,
    createdAt: '2025-01-02',
    updatedAt: '2025-01-05'
  },
  {
    id: '4',
    name: '新用户',
    color: '#8B5CF6',
    description: '注册时间不到7天的用户', 
    category: 'engagement',
    userCount: 89,
    isSystem: true,
    createdAt: '2025-01-01',
    updatedAt: '2025-01-01'
  }
]

const mockTaggedUsers: TaggedUser[] = [
  {
    id: 'user1',
    nickname: '张三',
    email: 'zhangsan@example.com',
    tags: ['1', '2'],
    avatar: undefined
  },
  {
    id: 'user2', 
    nickname: '李四',
    email: 'lisi@example.com',
    tags: ['1', '4'],
    avatar: undefined
  },
  {
    id: 'user3',
    nickname: '王五',
    email: 'wangwu@example.com', 
    tags: ['3'],
    avatar: undefined
  }
]

interface UserManagementStats {
  totalUsers: number
  activeUsers: number
  newUsersToday: number
  paidUsers: number
  tagsCount: number
  recentActivity: {
    date: string
    newUsers: number
    activeUsers: number
  }[]
}

export default function UsersPage() {
  const [activeTab, setActiveTab] = useState('users')
  const [stats, setStats] = useState<UserManagementStats | null>(null)
  const [loading, setLoading] = useState(false)
  const [tags, setTags] = useState<UserTag[]>(mockTags)
  const [taggedUsers, setTaggedUsers] = useState<TaggedUser[]>(mockTaggedUsers)

  // 加载统计数据
  useEffect(() => {
    const loadStats = async () => {
      setLoading(true)
      try {
        // 模拟API调用
        await new Promise(resolve => setTimeout(resolve, 1000))
        setStats({
          totalUsers: 12450,
          activeUsers: 8750,
          newUsersToday: 125,
          paidUsers: 1380,
          tagsCount: tags.length,
          recentActivity: [
            { date: '2025-01-05', newUsers: 125, activeUsers: 8750 },
            { date: '2025-01-04', newUsers: 98, activeUsers: 8650 },
            { date: '2025-01-03', newUsers: 110, activeUsers: 8550 },
          ]
        })
      } catch (error) {
        console.error('加载统计数据失败:', error)
      } finally {
        setLoading(false)
      }
    }

    loadStats()
  }, [tags.length])

  // 标签管理处理函数
  const handleCreateTag = async (tagData: Omit<UserTag, 'id' | 'userCount' | 'createdAt' | 'updatedAt'>) => {
    try {
      const newTag: UserTag = {
        ...tagData,
        id: `tag_${Date.now()}`,
        userCount: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
      setTags([...tags, newTag])
    } catch (error) {
      console.error('创建标签失败:', error)
    }
  }

  const handleUpdateTag = async (id: string, updates: Partial<UserTag>) => {
    try {
      setTags(tags.map(tag => 
        tag.id === id 
          ? { ...tag, ...updates, updatedAt: new Date().toISOString() }
          : tag
      ))
    } catch (error) {
      console.error('更新标签失败:', error)
    }
  }

  const handleDeleteTag = async (id: string) => {
    try {
      setTags(tags.filter(tag => tag.id !== id))
      // 同时从用户中移除该标签
      setTaggedUsers(taggedUsers.map(user => ({
        ...user,
        tags: user.tags.filter(tagId => tagId !== id)
      })))
    } catch (error) {
      console.error('删除标签失败:', error)
    }
  }

  const handleAssignTags = async (userIds: string[], tagIds: string[]) => {
    try {
      setTaggedUsers(taggedUsers.map(user => {
        if (userIds.includes(user.id)) {
          const newTags = [...new Set([...user.tags, ...tagIds])]
          return { ...user, tags: newTags }
        }
        return user
      }))
      
      // 更新标签的用户计数
      setTags(tags.map(tag => {
        if (tagIds.includes(tag.id)) {
          return { 
            ...tag, 
            userCount: tag.userCount + userIds.length,
            updatedAt: new Date().toISOString()
          }
        }
        return tag
      }))
    } catch (error) {
      console.error('分配标签失败:', error)
    }
  }

  const handleRemoveTags = async (userIds: string[], tagIds: string[]) => {
    try {
      setTaggedUsers(taggedUsers.map(user => {
        if (userIds.includes(user.id)) {
          const newTags = user.tags.filter(tagId => !tagIds.includes(tagId))
          return { ...user, tags: newTags }
        }
        return user
      }))

      // 更新标签的用户计数
      setTags(tags.map(tag => {
        if (tagIds.includes(tag.id)) {
          return { 
            ...tag, 
            userCount: Math.max(0, tag.userCount - userIds.length),
            updatedAt: new Date().toISOString()
          }
        }
        return tag
      }))
    } catch (error) {
      console.error('移除标签失败:', error)
    }
  }

  // 渲染概览统计
  const renderOverviewStats = () => {
    if (!stats) return null

    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-6">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">总用户数</p>
                <p className="text-2xl font-bold">{stats.totalUsers.toLocaleString()}</p>
              </div>
              <Users className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">活跃用户</p>
                <p className="text-2xl font-bold">{stats.activeUsers.toLocaleString()}</p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">今日新增</p>
                <p className="text-2xl font-bold">{stats.newUsersToday}</p>
              </div>
              <CheckCircle className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">付费用户</p>
                <p className="text-2xl font-bold">{stats.paidUsers.toLocaleString()}</p>
              </div>
              <Crown className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">用户标签</p>
                <p className="text-2xl font-bold">{stats.tagsCount}</p>
              </div>
              <Tag className="h-8 w-8 text-cyan-500" />
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        {/* 页面头部 */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">用户管理中心</h1>
            <p className="text-muted-foreground">
              全面的用户管理、批量操作、标签分类和数据分析平台
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" disabled={loading}>
              <Upload className="h-4 w-4 mr-2" />
              批量导入
            </Button>
            <Button variant="outline" size="sm" disabled={loading}>
              <Download className="h-4 w-4 mr-2" />
              导出数据
            </Button>
            <Button 
              variant="outline" 
              size="sm" 
              onClick={() => window.location.reload()}
              disabled={loading}
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              刷新数据
            </Button>
          </div>
        </div>

        {/* 概览统计 */}
        {renderOverviewStats()}

        {/* 主要内容区域 */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="users" className="flex items-center gap-2">
              <Users className="h-4 w-4" />
              用户管理
            </TabsTrigger>
            <TabsTrigger value="tags" className="flex items-center gap-2">
              <Tag className="h-4 w-4" />
              标签系统
            </TabsTrigger>
            <TabsTrigger value="analytics" className="flex items-center gap-2">
              <BarChart3 className="h-4 w-4" />
              数据分析
            </TabsTrigger>
            <TabsTrigger value="settings" className="flex items-center gap-2">
              <Settings className="h-4 w-4" />
              系统设置
            </TabsTrigger>
          </TabsList>

          {/* 用户管理标签页 */}
          <TabsContent value="users" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-5 w-5" />
                  用户管理
                </CardTitle>
                <CardDescription>
                  管理所有用户账户，支持批量操作、高级搜索和数据导出
                </CardDescription>
              </CardHeader>
              <CardContent>
                <EnhancedUserManager 
                  showStatistics={true}
                  enableBatchOperations={true}
                  enableExport={true}
                />
              </CardContent>
            </Card>
          </TabsContent>

          {/* 标签系统标签页 */}
          <TabsContent value="tags" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Tag className="h-5 w-5" />
                  用户标签管理
                </CardTitle>
                <CardDescription>
                  创建和管理用户标签，实现精细化用户分类和批量操作
                </CardDescription>
              </CardHeader>
              <CardContent>
                <UserTagSystem
                  tags={tags}
                  users={taggedUsers}
                  onCreateTag={handleCreateTag}
                  onUpdateTag={handleUpdateTag}
                  onDeleteTag={handleDeleteTag}
                  onAssignTags={handleAssignTags}
                  onRemoveTags={handleRemoveTags}
                  loading={loading}
                />
              </CardContent>
            </Card>
          </TabsContent>

          {/* 数据分析标签页 */}
          <TabsContent value="analytics" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <BarChart3 className="h-5 w-5" />
                  用户数据分析
                </CardTitle>
                <CardDescription>
                  用户行为分析、增长趋势和关键指标监控
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <h3 className="text-lg font-semibold">用户增长趋势</h3>
                    {stats?.recentActivity.map((activity, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                        <div>
                          <p className="font-medium">{activity.date}</p>
                          <p className="text-sm text-muted-foreground">新用户: {activity.newUsers}</p>
                        </div>
                        <div className="text-right">
                          <p className="font-medium">{activity.activeUsers.toLocaleString()}</p>
                          <p className="text-sm text-muted-foreground">活跃用户</p>
                        </div>
                      </div>
                    ))}
                  </div>
                  
                  <div className="space-y-4">
                    <h3 className="text-lg font-semibold">标签分布</h3>
                    {tags.slice(0, 5).map(tag => (
                      <div key={tag.id} className="flex items-center justify-between p-3 border rounded-lg">
                        <div className="flex items-center gap-2">
                          <Badge style={{ backgroundColor: tag.color + '20', color: tag.color }}>
                            {tag.name}
                          </Badge>
                        </div>
                        <div className="text-right">
                          <p className="font-medium">{tag.userCount}</p>
                          <p className="text-sm text-muted-foreground">用户</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* 系统设置标签页 */}
          <TabsContent value="settings" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Settings className="h-5 w-5" />
                  用户管理设置
                </CardTitle>
                <CardDescription>
                  配置用户管理相关的系统参数和策略
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  <div>
                    <h3 className="text-lg font-semibold mb-3">默认设置</h3>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between p-3 border rounded-lg">
                        <div>
                          <p className="font-medium">新用户自动激活</p>
                          <p className="text-sm text-muted-foreground">新注册用户是否自动激活账户</p>
                        </div>
                        <Badge variant="outline">已启用</Badge>
                      </div>
                      <div className="flex items-center justify-between p-3 border rounded-lg">
                        <div>
                          <p className="font-medium">批量操作限制</p>
                          <p className="text-sm text-muted-foreground">单次批量操作的最大用户数</p>
                        </div>
                        <Badge variant="outline">1000</Badge>
                      </div>
                      <div className="flex items-center justify-between p-3 border rounded-lg">
                        <div>
                          <p className="font-medium">数据导出格式</p>
                          <p className="text-sm text-muted-foreground">支持的数据导出格式</p>
                        </div>
                        <div className="flex gap-1">
                          <Badge variant="outline">CSV</Badge>
                          <Badge variant="outline">Excel</Badge>
                        </div>
                      </div>
                    </div>
                  </div>

                  <Separator />

                  <div>
                    <h3 className="text-lg font-semibold mb-3">安全策略</h3>
                    <div className="space-y-3">
                      <Alert>
                        <Shield className="h-4 w-4" />
                        <AlertDescription>
                          用户管理操作已启用详细日志记录，所有批量操作和关键变更都会被记录在审计日志中。
                        </AlertDescription>
                      </Alert>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}