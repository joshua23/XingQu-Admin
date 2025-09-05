/**
 * 星趣后台管理系统 - 订阅计划管理组件
 * 管理会员体系和订阅服务
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table'
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger 
} from '@/components/ui/dialog'
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Plus,
  Edit,
  Trash2,
  Crown,
  Users,
  TrendingUp,
  Calendar,
  DollarSign,
  Star,
  Gift,
  Settings,
  BarChart3
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

// 类型定义
interface SubscriptionPlan {
  id: string
  name: string
  description: string
  price: number
  currency: string
  duration: number // 天数
  durationType: 'days' | 'months' | 'years'
  features: string[]
  isActive: boolean
  isPopular: boolean
  maxUsers?: number
  maxStorage?: number // GB
  maxProjects?: number
  createdAt: string
  updatedAt: string
}

interface SubscriptionStats {
  totalRevenue: number
  activeSubscriptions: number
  monthlyGrowth: number
  churnRate: number
  popularPlan: string
  totalUsers: number
}

interface UserSubscription {
  id: string
  userId: string
  planId: string
  planName: string
  userEmail: string
  startDate: string
  endDate: string
  status: 'active' | 'expired' | 'cancelled' | 'pending'
  amount: number
  currency: string
}

export default function SubscriptionManager() {
  // 状态管理
  const [plans, setPlans] = useState<SubscriptionPlan[]>([])
  const [subscriptions, setSubscriptions] = useState<UserSubscription[]>([])
  const [stats, setStats] = useState<SubscriptionStats>({
    totalRevenue: 0,
    activeSubscriptions: 0,
    monthlyGrowth: 0,
    churnRate: 0,
    popularPlan: '',
    totalUsers: 0
  })
  const [loading, setLoading] = useState(true)
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState<string>('all')

  // 表单状态
  const [planForm, setPlanForm] = useState({
    name: '',
    description: '',
    price: 0,
    currency: 'CNY',
    duration: 30,
    durationType: 'days' as 'days' | 'months' | 'years',
    features: [] as string[],
    isActive: true,
    isPopular: false,
    maxUsers: undefined as number | undefined,
    maxStorage: undefined as number | undefined,
    maxProjects: undefined as number | undefined
  })

  useEffect(() => {
    fetchPlans()
    fetchSubscriptions()
    fetchStats()
  }, [])

  // 获取订阅计划
  const fetchPlans = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const mockPlans: SubscriptionPlan[] = [
        {
          id: '1',
          name: '基础版',
          description: '适合个人用户和小团队',
          price: 29.9,
          currency: 'CNY',
          duration: 30,
          durationType: 'days',
          features: ['基础功能', '5GB存储', '邮件支持'],
          isActive: true,
          isPopular: false,
          maxUsers: 5,
          maxStorage: 5,
          maxProjects: 10,
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        },
        {
          id: '2',
          name: '专业版',
          description: '适合成长型企业',
          price: 99.9,
          currency: 'CNY',
          duration: 30,
          durationType: 'days',
          features: ['全部功能', '50GB存储', '优先支持', '自定义品牌'],
          isActive: true,
          isPopular: true,
          maxUsers: 50,
          maxStorage: 50,
          maxProjects: 100,
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        },
        {
          id: '3',
          name: '企业版',
          description: '适合大型企业',
          price: 299.9,
          currency: 'CNY',
          duration: 30,
          durationType: 'days',
          features: ['企业级功能', '无限存储', '24/7支持', 'API访问', '单点登录'],
          isActive: true,
          isPopular: false,
          maxUsers: undefined,
          maxStorage: undefined,
          maxProjects: undefined,
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        }
      ]
      
      setPlans(mockPlans)
    } catch (error) {
      console.error('获取订阅计划失败:', error)
    } finally {
      setLoading(false)
    }
  }

  // 获取用户订阅
  const fetchSubscriptions = async () => {
    try {
      // 模拟API调用
      const mockSubscriptions: UserSubscription[] = [
        {
          id: '1',
          userId: 'user1',
          planId: '2',
          planName: '专业版',
          userEmail: 'user1@example.com',
          startDate: '2025-08-01',
          endDate: '2025-09-01',
          status: 'active',
          amount: 99.9,
          currency: 'CNY'
        },
        {
          id: '2',
          userId: 'user2',
          planId: '1',
          planName: '基础版',
          userEmail: 'user2@example.com',
          startDate: '2025-07-15',
          endDate: '2025-08-15',
          status: 'expired',
          amount: 29.9,
          currency: 'CNY'
        }
      ]
      
      setSubscriptions(mockSubscriptions)
    } catch (error) {
      console.error('获取订阅数据失败:', error)
    }
  }

  // 获取统计数据
  const fetchStats = async () => {
    try {
      setStats({
        totalRevenue: 15680,
        activeSubscriptions: 234,
        monthlyGrowth: 15.2,
        churnRate: 3.8,
        popularPlan: '专业版',
        totalUsers: 1256
      })
    } catch (error) {
      console.error('获取统计数据失败:', error)
    }
  }

  // 创建或更新计划
  const savePlan = async () => {
    try {
      if (selectedPlan) {
        // 更新计划
        const updatedPlans = plans.map(plan => 
          plan.id === selectedPlan.id 
            ? { ...selectedPlan, ...planForm, updatedAt: new Date().toISOString() }
            : plan
        )
        setPlans(updatedPlans)
      } else {
        // 创建新计划
        const newPlan: SubscriptionPlan = {
          id: Date.now().toString(),
          ...planForm,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
        setPlans([...plans, newPlan])
      }
      
      resetForm()
      setIsDialogOpen(false)
    } catch (error) {
      console.error('保存计划失败:', error)
    }
  }

  // 删除计划
  const deletePlan = async (planId: string) => {
    try {
      setPlans(plans.filter(plan => plan.id !== planId))
    } catch (error) {
      console.error('删除计划失败:', error)
    }
  }

  // 重置表单
  const resetForm = () => {
    setPlanForm({
      name: '',
      description: '',
      price: 0,
      currency: 'CNY',
      duration: 30,
      durationType: 'days',
      features: [],
      isActive: true,
      isPopular: false,
      maxUsers: undefined,
      maxStorage: undefined,
      maxProjects: undefined
    })
    setSelectedPlan(null)
  }

  // 编辑计划
  const editPlan = (plan: SubscriptionPlan) => {
    setSelectedPlan(plan)
    setPlanForm({
      name: plan.name,
      description: plan.description,
      price: plan.price,
      currency: plan.currency,
      duration: plan.duration,
      durationType: plan.durationType,
      features: plan.features,
      isActive: plan.isActive,
      isPopular: plan.isPopular,
      maxUsers: plan.maxUsers,
      maxStorage: plan.maxStorage,
      maxProjects: plan.maxProjects
    })
    setIsDialogOpen(true)
  }

  // 过滤订阅数据
  const filteredSubscriptions = useMemo(() => {
    return subscriptions.filter(sub => {
      const matchesSearch = searchTerm === '' || 
        sub.userEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
        sub.planName.toLowerCase().includes(searchTerm.toLowerCase())
      
      const matchesStatus = filterStatus === 'all' || sub.status === filterStatus
      
      return matchesSearch && matchesStatus
    })
  }, [subscriptions, searchTerm, filterStatus])

  // 状态样式
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-100 text-green-700 border-green-200">活跃</Badge>
      case 'expired':
        return <Badge variant="outline" className="text-red-600">已过期</Badge>
      case 'cancelled':
        return <Badge variant="outline" className="text-gray-600">已取消</Badge>
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">待激活</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  return (
    <div className="space-y-6">
      {/* 统计卡片 */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">总收入</CardTitle>
            <DollarSign className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">¥{stats.totalRevenue.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">本月收入</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">活跃订阅</CardTitle>
            <Users className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeSubscriptions}</div>
            <p className="text-xs text-muted-foreground">当前活跃用户</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">月度增长</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">+{stats.monthlyGrowth}%</div>
            <p className="text-xs text-muted-foreground">订阅增长率</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">流失率</CardTitle>
            <BarChart3 className="h-4 w-4 text-red-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.churnRate}%</div>
            <p className="text-xs text-muted-foreground">用户流失率</p>
          </CardContent>
        </Card>
      </div>

      {/* 主要内容 */}
      <Tabs defaultValue="plans" className="space-y-4">
        <TabsList>
          <TabsTrigger value="plans">订阅计划</TabsTrigger>
          <TabsTrigger value="subscriptions">用户订阅</TabsTrigger>
          <TabsTrigger value="analytics">数据分析</TabsTrigger>
        </TabsList>

        {/* 订阅计划管理 */}
        <TabsContent value="plans" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>订阅计划管理</CardTitle>
                  <CardDescription>创建和管理不同的订阅计划</CardDescription>
                </div>
                <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                  <DialogTrigger asChild>
                    <Button onClick={resetForm}>
                      <Plus className="w-4 h-4 mr-2" />
                      新建计划
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="max-w-2xl">
                    <DialogHeader>
                      <DialogTitle>
                        {selectedPlan ? '编辑订阅计划' : '创建订阅计划'}
                      </DialogTitle>
                      <DialogDescription>
                        配置订阅计划的详细信息和功能特性
                      </DialogDescription>
                    </DialogHeader>
                    
                    <div className="grid gap-4 py-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="name">计划名称</Label>
                          <Input
                            id="name"
                            value={planForm.name}
                            onChange={(e) => setPlanForm({...planForm, name: e.target.value})}
                            placeholder="例如：专业版"
                          />
                        </div>
                        <div>
                          <Label htmlFor="price">价格</Label>
                          <Input
                            id="price"
                            type="number"
                            value={planForm.price}
                            onChange={(e) => setPlanForm({...planForm, price: parseFloat(e.target.value) || 0})}
                            placeholder="29.9"
                          />
                        </div>
                      </div>
                      
                      <div>
                        <Label htmlFor="description">描述</Label>
                        <Textarea
                          id="description"
                          value={planForm.description}
                          onChange={(e) => setPlanForm({...planForm, description: e.target.value})}
                          placeholder="描述该计划的特点和适用场景"
                        />
                      </div>
                      
                      <div className="grid grid-cols-3 gap-4">
                        <div>
                          <Label htmlFor="duration">周期时长</Label>
                          <Input
                            id="duration"
                            type="number"
                            value={planForm.duration}
                            onChange={(e) => setPlanForm({...planForm, duration: parseInt(e.target.value) || 0})}
                          />
                        </div>
                        <div>
                          <Label htmlFor="durationType">周期类型</Label>
                          <Select value={planForm.durationType} onValueChange={(value) => setPlanForm({...planForm, durationType: value as any})}>
                            <SelectTrigger>
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="days">天</SelectItem>
                              <SelectItem value="months">月</SelectItem>
                              <SelectItem value="years">年</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                        <div>
                          <Label htmlFor="currency">货币</Label>
                          <Select value={planForm.currency} onValueChange={(value) => setPlanForm({...planForm, currency: value})}>
                            <SelectTrigger>
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="CNY">人民币</SelectItem>
                              <SelectItem value="USD">美元</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                      </div>
                      
                      <div className="flex items-center space-x-6">
                        <div className="flex items-center space-x-2">
                          <Switch
                            id="isActive"
                            checked={planForm.isActive}
                            onCheckedChange={(checked) => setPlanForm({...planForm, isActive: checked})}
                          />
                          <Label htmlFor="isActive">启用计划</Label>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Switch
                            id="isPopular"
                            checked={planForm.isPopular}
                            onCheckedChange={(checked) => setPlanForm({...planForm, isPopular: checked})}
                          />
                          <Label htmlFor="isPopular">热门推荐</Label>
                        </div>
                      </div>
                    </div>

                    <DialogFooter>
                      <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                        取消
                      </Button>
                      <Button onClick={savePlan}>
                        {selectedPlan ? '更新' : '创建'}
                      </Button>
                    </DialogFooter>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {plans.map((plan) => (
                  <Card key={plan.id} className={`relative ${plan.isPopular ? 'ring-2 ring-blue-500' : ''}`}>
                    {plan.isPopular && (
                      <div className="absolute -top-3 left-4">
                        <Badge className="bg-blue-500 text-white">
                          <Star className="w-3 h-3 mr-1" />
                          热门
                        </Badge>
                      </div>
                    )}
                    <CardHeader>
                      <div className="flex items-center justify-between">
                        <CardTitle className="text-lg">{plan.name}</CardTitle>
                        <div className="flex space-x-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => editPlan(plan)}
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => deletePlan(plan.id)}
                          >
                            <Trash2 className="w-4 h-4 text-red-600" />
                          </Button>
                        </div>
                      </div>
                      <CardDescription>{plan.description}</CardDescription>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-3">
                        <div className="flex items-baseline">
                          <span className="text-2xl font-bold">¥{plan.price}</span>
                          <span className="text-muted-foreground ml-1">/{plan.duration}{
                            plan.durationType === 'days' ? '天' :
                            plan.durationType === 'months' ? '月' : '年'
                          }</span>
                        </div>
                        
                        <div className="space-y-1">
                          {plan.features.map((feature, index) => (
                            <div key={index} className="flex items-center text-sm">
                              <Gift className="w-3 h-3 mr-2 text-green-600" />
                              {feature}
                            </div>
                          ))}
                        </div>
                        
                        <div className="flex items-center justify-between pt-2">
                          <Badge variant={plan.isActive ? "default" : "outline"}>
                            {plan.isActive ? '已启用' : '已停用'}
                          </Badge>
                          {plan.maxUsers && (
                            <span className="text-xs text-muted-foreground">
                              最多 {plan.maxUsers} 用户
                            </span>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 用户订阅管理 */}
        <TabsContent value="subscriptions" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>用户订阅管理</CardTitle>
              <CardDescription>查看和管理用户的订阅状态</CardDescription>
              <div className="flex items-center space-x-4">
                <Input
                  placeholder="搜索用户邮箱或计划名称..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="max-w-sm"
                />
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger className="w-40">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部状态</SelectItem>
                    <SelectItem value="active">活跃</SelectItem>
                    <SelectItem value="expired">已过期</SelectItem>
                    <SelectItem value="cancelled">已取消</SelectItem>
                    <SelectItem value="pending">待激活</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>用户邮箱</TableHead>
                    <TableHead>订阅计划</TableHead>
                    <TableHead>开始日期</TableHead>
                    <TableHead>到期日期</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>金额</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredSubscriptions.map((sub) => (
                    <TableRow key={sub.id}>
                      <TableCell>{sub.userEmail}</TableCell>
                      <TableCell>
                        <div className="flex items-center">
                          <Crown className="w-4 h-4 mr-2 text-yellow-600" />
                          {sub.planName}
                        </div>
                      </TableCell>
                      <TableCell>{sub.startDate}</TableCell>
                      <TableCell>{sub.endDate}</TableCell>
                      <TableCell>{getStatusBadge(sub.status)}</TableCell>
                      <TableCell>¥{sub.amount}</TableCell>
                      <TableCell>
                        <Button variant="ghost" size="sm">
                          <Settings className="w-4 h-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 数据分析 */}
        <TabsContent value="analytics" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>收入趋势</CardTitle>
                <CardDescription>近期订阅收入变化趋势</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  收入趋势图表 (待实现)
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>计划受欢迎程度</CardTitle>
                <CardDescription>各订阅计划的用户分布</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {plans.map((plan, index) => (
                    <div key={plan.id} className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className={`w-3 h-3 rounded mr-2 ${
                          index === 0 ? 'bg-blue-500' :
                          index === 1 ? 'bg-green-500' :
                          'bg-yellow-500'
                        }`} />
                        <span>{plan.name}</span>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        {Math.floor(Math.random() * 100)}%
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>关键指标</CardTitle>
              <CardDescription>订阅业务的重要指标分析</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-3">
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-green-600">¥{(stats.totalRevenue / stats.activeSubscriptions).toFixed(0)}</div>
                  <div className="text-sm text-muted-foreground">平均客单价</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">{(30 * (1 - stats.churnRate / 100)).toFixed(0)}天</div>
                  <div className="text-sm text-muted-foreground">平均生命周期</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">{stats.popularPlan}</div>
                  <div className="text-sm text-muted-foreground">最受欢迎计划</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}