/**
 * 星趣后台管理系统 - 订单支付管理组件
 * 处理支付订单和财务管理
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Search,
  Filter,
  Download,
  RefreshCw,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Clock,
  DollarSign,
  CreditCard,
  TrendingUp,
  Users,
  Calendar,
  FileText,
  ArrowUpDown,
  Eye,
  RotateCcw
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

// 类型定义
interface Order {
  id: string
  orderNumber: string
  userId: string
  userEmail: string
  planId: string
  planName: string
  amount: number
  currency: string
  status: 'pending' | 'paid' | 'failed' | 'cancelled' | 'refunded' | 'partial_refund'
  paymentMethod: 'alipay' | 'wechat' | 'card' | 'bank'
  paymentId?: string
  createdAt: string
  paidAt?: string
  failedAt?: string
  refundedAt?: string
  refundAmount?: number
  refundReason?: string
  notes?: string
}

interface PaymentStats {
  totalRevenue: number
  todayRevenue: number
  pendingOrders: number
  failedOrders: number
  refundRequests: number
  successRate: number
  avgOrderValue: number
  totalOrders: number
}

interface RefundRequest {
  id: string
  orderId: string
  orderNumber: string
  amount: number
  requestedAmount: number
  reason: string
  status: 'pending' | 'approved' | 'rejected' | 'processed'
  requestedAt: string
  processedAt?: string
  processedBy?: string
  notes?: string
}

export default function OrderPaymentManager() {
  // 状态管理
  const [orders, setOrders] = useState<Order[]>([])
  const [refundRequests, setRefundRequests] = useState<RefundRequest[]>([])
  const [stats, setStats] = useState<PaymentStats>({
    totalRevenue: 0,
    todayRevenue: 0,
    pendingOrders: 0,
    failedOrders: 0,
    refundRequests: 0,
    successRate: 0,
    avgOrderValue: 0,
    totalOrders: 0
  })
  const [loading, setLoading] = useState(true)
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null)
  const [selectedRefund, setSelectedRefund] = useState<RefundRequest | null>(null)
  const [isOrderDialogOpen, setIsOrderDialogOpen] = useState(false)
  const [isRefundDialogOpen, setIsRefundDialogOpen] = useState(false)
  
  // 筛选状态
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [paymentMethodFilter, setPaymentMethodFilter] = useState<string>('all')
  const [dateRange, setDateRange] = useState<string>('7')
  const [sortField, setSortField] = useState<string>('createdAt')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc')

  // 退款表单
  const [refundForm, setRefundForm] = useState({
    amount: 0,
    reason: '',
    notes: ''
  })

  useEffect(() => {
    fetchOrders()
    fetchRefundRequests()
    fetchStats()
  }, [])

  // 获取订单数据
  const fetchOrders = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const mockOrders: Order[] = [
        {
          id: '1',
          orderNumber: 'ORD-2025090501',
          userId: 'user1',
          userEmail: 'user1@example.com',
          planId: 'plan1',
          planName: '专业版',
          amount: 99.9,
          currency: 'CNY',
          status: 'paid',
          paymentMethod: 'alipay',
          paymentId: 'ali_2025090501',
          createdAt: '2025-09-05 10:30:00',
          paidAt: '2025-09-05 10:31:00'
        },
        {
          id: '2',
          orderNumber: 'ORD-2025090502',
          userId: 'user2',
          userEmail: 'user2@example.com',
          planId: 'plan2',
          planName: '基础版',
          amount: 29.9,
          currency: 'CNY',
          status: 'pending',
          paymentMethod: 'wechat',
          createdAt: '2025-09-05 11:00:00'
        },
        {
          id: '3',
          orderNumber: 'ORD-2025090503',
          userId: 'user3',
          userEmail: 'user3@example.com',
          planId: 'plan1',
          planName: '专业版',
          amount: 99.9,
          currency: 'CNY',
          status: 'failed',
          paymentMethod: 'card',
          createdAt: '2025-09-05 09:15:00',
          failedAt: '2025-09-05 09:16:00',
          notes: '银行卡余额不足'
        },
        {
          id: '4',
          orderNumber: 'ORD-2025090504',
          userId: 'user4',
          userEmail: 'user4@example.com',
          planId: 'plan3',
          planName: '企业版',
          amount: 299.9,
          currency: 'CNY',
          status: 'refunded',
          paymentMethod: 'alipay',
          paymentId: 'ali_2025090504',
          createdAt: '2025-09-04 14:20:00',
          paidAt: '2025-09-04 14:21:00',
          refundedAt: '2025-09-05 16:30:00',
          refundAmount: 299.9,
          refundReason: '用户主动申请退款'
        }
      ]
      
      setOrders(mockOrders)
    } catch (error) {
      console.error('获取订单数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  // 获取退款请求
  const fetchRefundRequests = async () => {
    try {
      const mockRefunds: RefundRequest[] = [
        {
          id: '1',
          orderId: '5',
          orderNumber: 'ORD-2025090505',
          amount: 99.9,
          requestedAmount: 99.9,
          reason: '服务不满意',
          status: 'pending',
          requestedAt: '2025-09-05 15:30:00'
        },
        {
          id: '2',
          orderId: '6',
          orderNumber: 'ORD-2025090506',
          amount: 299.9,
          requestedAmount: 150.0,
          reason: '部分功能未使用',
          status: 'approved',
          requestedAt: '2025-09-04 10:00:00',
          processedAt: '2025-09-04 16:00:00',
          processedBy: 'admin1'
        }
      ]
      
      setRefundRequests(mockRefunds)
    } catch (error) {
      console.error('获取退款数据失败:', error)
    }
  }

  // 获取统计数据
  const fetchStats = async () => {
    try {
      setStats({
        totalRevenue: 45680.50,
        todayRevenue: 1250.30,
        pendingOrders: 23,
        failedOrders: 8,
        refundRequests: 5,
        successRate: 94.2,
        avgOrderValue: 156.78,
        totalOrders: 892
      })
    } catch (error) {
      console.error('获取统计数据失败:', error)
    }
  }

  // 处理退款
  const processRefund = async (refundId: string, action: 'approve' | 'reject') => {
    try {
      const updatedRequests = refundRequests.map(request =>
        request.id === refundId
          ? {
              ...request,
              status: action === 'approve' ? 'approved' as const : 'rejected' as const,
              processedAt: new Date().toISOString(),
              processedBy: 'current_admin',
              notes: refundForm.notes
            }
          : request
      )
      setRefundRequests(updatedRequests)
      setIsRefundDialogOpen(false)
      resetRefundForm()
    } catch (error) {
      console.error('处理退款失败:', error)
    }
  }

  // 重置退款表单
  const resetRefundForm = () => {
    setRefundForm({
      amount: 0,
      reason: '',
      notes: ''
    })
    setSelectedRefund(null)
  }

  // 过滤订单
  const filteredOrders = useMemo(() => {
    let filtered = orders.filter(order => {
      const matchesSearch = searchTerm === '' || 
        order.orderNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.userEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.planName.toLowerCase().includes(searchTerm.toLowerCase())
      
      const matchesStatus = statusFilter === 'all' || order.status === statusFilter
      const matchesPaymentMethod = paymentMethodFilter === 'all' || order.paymentMethod === paymentMethodFilter
      
      return matchesSearch && matchesStatus && matchesPaymentMethod
    })

    // 排序
    filtered.sort((a, b) => {
      let aValue = a[sortField as keyof Order]
      let bValue = b[sortField as keyof Order]
      
      if (typeof aValue === 'string') aValue = aValue.toLowerCase()
      if (typeof bValue === 'string') bValue = bValue.toLowerCase()
      
      if (sortOrder === 'asc') {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0
      }
    })

    return filtered
  }, [orders, searchTerm, statusFilter, paymentMethodFilter, sortField, sortOrder])

  // 状态样式
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'paid':
        return <Badge className="bg-green-100 text-green-700 border-green-200">已支付</Badge>
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">待支付</Badge>
      case 'failed':
        return <Badge className="bg-red-100 text-red-700 border-red-200">支付失败</Badge>
      case 'cancelled':
        return <Badge variant="outline" className="text-gray-600">已取消</Badge>
      case 'refunded':
        return <Badge variant="outline" className="text-purple-600">已退款</Badge>
      case 'partial_refund':
        return <Badge variant="outline" className="text-orange-600">部分退款</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getRefundStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">待处理</Badge>
      case 'approved':
        return <Badge className="bg-green-100 text-green-700 border-green-200">已批准</Badge>
      case 'rejected':
        return <Badge className="bg-red-100 text-red-700 border-red-200">已拒绝</Badge>
      case 'processed':
        return <Badge className="bg-blue-100 text-blue-700 border-blue-200">已处理</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getPaymentMethodBadge = (method: string) => {
    switch (method) {
      case 'alipay':
        return <Badge variant="outline" className="text-blue-600">支付宝</Badge>
      case 'wechat':
        return <Badge variant="outline" className="text-green-600">微信支付</Badge>
      case 'card':
        return <Badge variant="outline" className="text-purple-600">银行卡</Badge>
      case 'bank':
        return <Badge variant="outline" className="text-gray-600">银行转账</Badge>
      default:
        return <Badge variant="outline">{method}</Badge>
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
            <p className="text-xs text-muted-foreground">
              今日 ¥{stats.todayRevenue.toLocaleString()}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">待处理订单</CardTitle>
            <Clock className="h-4 w-4 text-yellow-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.pendingOrders}</div>
            <p className="text-xs text-muted-foreground">需要关注</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">成功率</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.successRate}%</div>
            <p className="text-xs text-muted-foreground">支付成功率</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">平均订单金额</CardTitle>
            <CreditCard className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">¥{stats.avgOrderValue}</div>
            <p className="text-xs text-muted-foreground">用户平均消费</p>
          </CardContent>
        </Card>
      </div>

      {/* 主要内容 */}
      <Tabs defaultValue="orders" className="space-y-4">
        <TabsList>
          <TabsTrigger value="orders">订单管理</TabsTrigger>
          <TabsTrigger value="refunds">退款管理</TabsTrigger>
          <TabsTrigger value="analytics">财务分析</TabsTrigger>
        </TabsList>

        {/* 订单管理 */}
        <TabsContent value="orders" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>订单管理</CardTitle>
              <CardDescription>查看和管理所有支付订单</CardDescription>
              
              {/* 筛选工具栏 */}
              <div className="flex flex-wrap items-center gap-4">
                <div className="flex items-center space-x-2">
                  <Search className="w-4 h-4 text-muted-foreground" />
                  <Input
                    placeholder="搜索订单号、邮箱或计划..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-64"
                  />
                </div>
                
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-32">
                    <SelectValue placeholder="状态" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部状态</SelectItem>
                    <SelectItem value="paid">已支付</SelectItem>
                    <SelectItem value="pending">待支付</SelectItem>
                    <SelectItem value="failed">支付失败</SelectItem>
                    <SelectItem value="refunded">已退款</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={paymentMethodFilter} onValueChange={setPaymentMethodFilter}>
                  <SelectTrigger className="w-32">
                    <SelectValue placeholder="支付方式" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部方式</SelectItem>
                    <SelectItem value="alipay">支付宝</SelectItem>
                    <SelectItem value="wechat">微信支付</SelectItem>
                    <SelectItem value="card">银行卡</SelectItem>
                    <SelectItem value="bank">银行转账</SelectItem>
                  </SelectContent>
                </Select>

                <Button variant="outline" onClick={fetchOrders} disabled={loading}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  刷新
                </Button>

                <Button variant="outline">
                  <Download className="w-4 h-4 mr-2" />
                  导出
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="cursor-pointer" onClick={() => {
                      setSortField('orderNumber')
                      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
                    }}>
                      订单号 <ArrowUpDown className="inline w-3 h-3 ml-1" />
                    </TableHead>
                    <TableHead>用户邮箱</TableHead>
                    <TableHead>订阅计划</TableHead>
                    <TableHead className="cursor-pointer" onClick={() => {
                      setSortField('amount')
                      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
                    }}>
                      金额 <ArrowUpDown className="inline w-3 h-3 ml-1" />
                    </TableHead>
                    <TableHead>支付方式</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead className="cursor-pointer" onClick={() => {
                      setSortField('createdAt')
                      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
                    }}>
                      创建时间 <ArrowUpDown className="inline w-3 h-3 ml-1" />
                    </TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredOrders.map((order) => (
                    <TableRow key={order.id}>
                      <TableCell className="font-mono text-sm">{order.orderNumber}</TableCell>
                      <TableCell>{order.userEmail}</TableCell>
                      <TableCell>{order.planName}</TableCell>
                      <TableCell>¥{order.amount}</TableCell>
                      <TableCell>{getPaymentMethodBadge(order.paymentMethod)}</TableCell>
                      <TableCell>{getStatusBadge(order.status)}</TableCell>
                      <TableCell>{new Date(order.createdAt).toLocaleString()}</TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button 
                            variant="ghost" 
                            size="sm"
                            onClick={() => {
                              setSelectedOrder(order)
                              setIsOrderDialogOpen(true)
                            }}
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          {order.status === 'paid' && (
                            <Button variant="ghost" size="sm">
                              <RotateCcw className="w-4 h-4" />
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 退款管理 */}
        <TabsContent value="refunds" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>退款管理</CardTitle>
              <CardDescription>处理用户退款请求和异常订单</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>订单号</TableHead>
                    <TableHead>退款金额</TableHead>
                    <TableHead>申请金额</TableHead>
                    <TableHead>退款原因</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>申请时间</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {refundRequests.map((request) => (
                    <TableRow key={request.id}>
                      <TableCell className="font-mono text-sm">{request.orderNumber}</TableCell>
                      <TableCell>¥{request.amount}</TableCell>
                      <TableCell>¥{request.requestedAmount}</TableCell>
                      <TableCell>{request.reason}</TableCell>
                      <TableCell>{getRefundStatusBadge(request.status)}</TableCell>
                      <TableCell>{new Date(request.requestedAt).toLocaleString()}</TableCell>
                      <TableCell>
                        {request.status === 'pending' && (
                          <div className="flex space-x-2">
                            <Button 
                              variant="outline" 
                              size="sm"
                              onClick={() => processRefund(request.id, 'approve')}
                              className="text-green-600"
                            >
                              批准
                            </Button>
                            <Button 
                              variant="outline" 
                              size="sm"
                              onClick={() => processRefund(request.id, 'reject')}
                              className="text-red-600"
                            >
                              拒绝
                            </Button>
                          </div>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 财务分析 */}
        <TabsContent value="analytics" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>收入趋势</CardTitle>
                <CardDescription>近期收入变化趋势分析</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  收入趋势图表 (待实现)
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>支付方式分布</CardTitle>
                <CardDescription>不同支付方式的使用情况</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-3 h-3 rounded mr-2 bg-blue-500" />
                      <span>支付宝</span>
                    </div>
                    <div className="text-sm text-muted-foreground">45%</div>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-3 h-3 rounded mr-2 bg-green-500" />
                      <span>微信支付</span>
                    </div>
                    <div className="text-sm text-muted-foreground">35%</div>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-3 h-3 rounded mr-2 bg-purple-500" />
                      <span>银行卡</span>
                    </div>
                    <div className="text-sm text-muted-foreground">15%</div>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-3 h-3 rounded mr-2 bg-gray-500" />
                      <span>银行转账</span>
                    </div>
                    <div className="text-sm text-muted-foreground">5%</div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>关键财务指标</CardTitle>
              <CardDescription>重要的财务运营指标总览</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-4">
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-green-600">
                    {stats.totalOrders}
                  </div>
                  <div className="text-sm text-muted-foreground">总订单数</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">
                    {stats.successRate}%
                  </div>
                  <div className="text-sm text-muted-foreground">支付成功率</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">
                    ¥{stats.avgOrderValue}
                  </div>
                  <div className="text-sm text-muted-foreground">平均订单价值</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold text-orange-600">
                    {stats.refundRequests}
                  </div>
                  <div className="text-sm text-muted-foreground">退款请求</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* 订单详情对话框 */}
      <Dialog open={isOrderDialogOpen} onOpenChange={setIsOrderDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>订单详情</DialogTitle>
            <DialogDescription>
              查看订单的详细信息和处理记录
            </DialogDescription>
          </DialogHeader>
          
          {selectedOrder && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>订单号</Label>
                  <div className="font-mono text-sm">{selectedOrder.orderNumber}</div>
                </div>
                <div>
                  <Label>用户邮箱</Label>
                  <div>{selectedOrder.userEmail}</div>
                </div>
                <div>
                  <Label>订阅计划</Label>
                  <div>{selectedOrder.planName}</div>
                </div>
                <div>
                  <Label>订单金额</Label>
                  <div>¥{selectedOrder.amount}</div>
                </div>
                <div>
                  <Label>支付方式</Label>
                  <div>{getPaymentMethodBadge(selectedOrder.paymentMethod)}</div>
                </div>
                <div>
                  <Label>订单状态</Label>
                  <div>{getStatusBadge(selectedOrder.status)}</div>
                </div>
                <div>
                  <Label>创建时间</Label>
                  <div>{new Date(selectedOrder.createdAt).toLocaleString()}</div>
                </div>
                {selectedOrder.paidAt && (
                  <div>
                    <Label>支付时间</Label>
                    <div>{new Date(selectedOrder.paidAt).toLocaleString()}</div>
                  </div>
                )}
              </div>
              
              {selectedOrder.notes && (
                <div>
                  <Label>备注</Label>
                  <div className="mt-1 p-2 bg-muted rounded">{selectedOrder.notes}</div>
                </div>
              )}
              
              {selectedOrder.status === 'refunded' && (
                <div className="grid grid-cols-2 gap-4 p-4 bg-red-50 rounded">
                  <div>
                    <Label>退款金额</Label>
                    <div>¥{selectedOrder.refundAmount}</div>
                  </div>
                  <div>
                    <Label>退款时间</Label>
                    <div>{selectedOrder.refundedAt && new Date(selectedOrder.refundedAt).toLocaleString()}</div>
                  </div>
                  <div className="col-span-2">
                    <Label>退款原因</Label>
                    <div>{selectedOrder.refundReason}</div>
                  </div>
                </div>
              )}
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsOrderDialogOpen(false)}>
              关闭
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}