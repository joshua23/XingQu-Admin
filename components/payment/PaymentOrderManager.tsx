/**
 * 星趣后台管理系统 - 支付订单管理组件
 * 提供支付订单处理、退款管理和财务统计功能
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
import { 
  DollarSign, 
  CreditCard, 
  TrendingUp, 
  AlertCircle,
  Search,
  Filter,
  Download,
  CheckCircle,
  XCircle,
  Clock,
  RefreshCw,
  Eye,
  RotateCcw,
  Ban,
  Smartphone,
  Wallet,
  Building,
  Globe,
  ArrowUpRight,
  ArrowDownRight,
  Calendar,
  User
} from 'lucide-react'
import { usePaymentManagement } from '@/lib/hooks/usePaymentManagement'
import type { PaymentFilters, PaymentOrder } from '@/lib/types/admin'

interface PaymentOrderManagerProps {
  className?: string
}

export default function PaymentOrderManager({ className }: PaymentOrderManagerProps) {
  const {
    orders,
    refunds,
    selectedOrders,
    statistics,
    totalOrders,
    loading,
    processing,
    error,
    loadOrders,
    loadRefunds,
    loadStatistics,
    updateOrder,
    processRefund,
    bulkOperate,
    selectOrder,
    unselectOrder,
    selectAllOrders,
    clearSelection,
    toggleOrderSelection,
    exportData,
    clearError
  } = usePaymentManagement()

  const [activeTab, setActiveTab] = useState<'orders' | 'refunds' | 'statistics'>('orders')
  const [filters, setFilters] = useState<PaymentFilters>({})
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedStatus, setSelectedStatus] = useState<string>('all')
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState<string>('all')

  // 页面初始化
  useEffect(() => {
    loadOrders()
    loadRefunds()
    loadStatistics()
  }, [loadOrders, loadRefunds, loadStatistics])

  // 处理搜索和过滤
  useEffect(() => {
    const newFilters: PaymentFilters = {}

    if (searchTerm) {
      newFilters.search = searchTerm
    }

    if (selectedStatus !== 'all') {
      newFilters.status = [selectedStatus]
    }

    if (selectedPaymentMethod !== 'all') {
      newFilters.paymentMethods = [selectedPaymentMethod]
    }

    setFilters(newFilters)
    loadOrders(newFilters)
  }, [searchTerm, selectedStatus, selectedPaymentMethod, loadOrders])

  const getStatusBadge = (status: string) => {
    const styles = {
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
      processing: 'bg-blue-100 text-blue-800 border-blue-200',
      completed: 'bg-green-100 text-green-800 border-green-200',
      failed: 'bg-red-100 text-red-800 border-red-200',
      cancelled: 'bg-gray-100 text-gray-800 border-gray-200',
      refunded: 'bg-purple-100 text-purple-800 border-purple-200'
    }
    const labels = {
      pending: '待支付',
      processing: '处理中',
      completed: '已完成',
      failed: '失败',
      cancelled: '已取消',
      refunded: '已退款'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles]}`}>
        {labels[status as keyof typeof labels]}
      </span>
    )
  }

  const getPaymentMethodIcon = (method: string) => {
    switch (method) {
      case 'alipay': return <Smartphone size={16} className="text-blue-600" />
      case 'wechat': return <Smartphone size={16} className="text-green-600" />
      case 'card': return <CreditCard size={16} className="text-purple-600" />
      case 'paypal': return <Globe size={16} className="text-blue-800" />
      default: return <Wallet size={16} className="text-gray-600" />
    }
  }

  const getPaymentMethodName = (method: string) => {
    const names = {
      alipay: '支付宝',
      wechat: '微信支付',
      card: '银行卡',
      paypal: 'PayPal',
      stripe: 'Stripe'
    }
    return names[method as keyof typeof names] || method
  }

  const handleBulkOperation = async (operation: string) => {
    if (selectedOrders.length === 0) return

    try {
      await bulkOperate({
        operation: operation as any,
        orderIds: selectedOrders.map(order => order.id),
        parameters: {}
      })
    } catch (error) {
      console.error('批量操作失败:', error)
    }
  }

  const handleRefund = async (orderId: string, refundAmount?: number) => {
    try {
      await processRefund(orderId, {
        refund_reason: '管理员手动退款',
        refund_amount: refundAmount
      })
    } catch (error) {
      console.error('退款失败:', error)
    }
  }

  const handleExport = async () => {
    try {
      const csv = await exportData(filters)
      
      // 创建下载链接
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `payment_orders_${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    } catch (error) {
      console.error('导出失败:', error)
    }
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* 错误提示 */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertCircle size={16} className="text-red-500" />
            <span className="text-red-800 text-sm">{error}</span>
            <button
              onClick={clearError}
              className="ml-auto text-red-500 hover:text-red-700"
            >
              <XCircle size={14} />
            </button>
          </div>
        </div>
      )}

      {/* 统计概览 */}
      {statistics && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <DollarSign size={24} className="text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">¥{statistics.totalRevenue.toLocaleString()}</p>
                <p className="text-sm text-gray-600">总收入</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <CreditCard size={24} className="text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{statistics.completedOrders.toLocaleString()}</p>
                <p className="text-sm text-gray-600">成功订单</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <TrendingUp size={24} className="text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">¥{statistics.averageOrderValue}</p>
                <p className="text-sm text-gray-600">平均订单价值</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                <Clock size={24} className="text-yellow-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{statistics.pendingOrders.toLocaleString()}</p>
                <p className="text-sm text-gray-600">待处理订单</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 标签页 */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="flex border-b border-gray-200">
          <button
            onClick={() => setActiveTab('orders')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'orders'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <CreditCard size={16} />
              <span>支付订单</span>
            </div>
          </button>

          <button
            onClick={() => setActiveTab('refunds')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'refunds'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <RotateCcw size={16} />
              <span>退款管理</span>
            </div>
          </button>

          <button
            onClick={() => setActiveTab('statistics')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'statistics'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <TrendingUp size={16} />
              <span>统计分析</span>
            </div>
          </button>
        </div>

        {/* 支付订单标签页 */}
        {activeTab === 'orders' && (
          <>
            {/* 筛选和操作栏 */}
            <div className="p-6 border-b border-gray-200">
              <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
                {/* 搜索和筛选 */}
                <div className="flex flex-1 gap-4">
                  <div className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input
                      type="text"
                      placeholder="搜索订单号或用户..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-64 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    />
                  </div>

                  <select
                    value={selectedStatus}
                    onChange={(e) => setSelectedStatus(e.target.value)}
                    className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">所有状态</option>
                    <option value="pending">待支付</option>
                    <option value="processing">处理中</option>
                    <option value="completed">已完成</option>
                    <option value="failed">失败</option>
                    <option value="cancelled">已取消</option>
                    <option value="refunded">已退款</option>
                  </select>

                  <select
                    value={selectedPaymentMethod}
                    onChange={(e) => setSelectedPaymentMethod(e.target.value)}
                    className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">所有支付方式</option>
                    <option value="alipay">支付宝</option>
                    <option value="wechat">微信支付</option>
                    <option value="card">银行卡</option>
                    <option value="paypal">PayPal</option>
                  </select>
                </div>

                {/* 操作按钮 */}
                <div className="flex items-center space-x-3">
                  {selectedOrders.length > 0 && (
                    <>
                      <button
                        onClick={() => handleBulkOperation('approve')}
                        disabled={processing}
                        className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                      >
                        <CheckCircle size={16} />
                        <span>批量确认</span>
                      </button>
                      <button
                        onClick={() => handleBulkOperation('cancel')}
                        disabled={processing}
                        className="flex items-center space-x-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                      >
                        <Ban size={16} />
                        <span>批量取消</span>
                      </button>
                    </>
                  )}

                  <button
                    onClick={handleExport}
                    className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    <Download size={16} />
                    <span>导出</span>
                  </button>
                </div>
              </div>

              {selectedOrders.length > 0 && (
                <div className="mt-4 flex items-center justify-between bg-blue-50 rounded-lg p-3">
                  <span className="text-sm text-blue-800">
                    已选择 {selectedOrders.length} 个订单
                  </span>
                  <button
                    onClick={clearSelection}
                    className="text-sm text-blue-600 hover:text-blue-800"
                  >
                    清空选择
                  </button>
                </div>
              )}
            </div>

            {/* 订单列表 */}
            <div className="p-6">
              {loading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  <span className="ml-3 text-gray-600">加载中...</span>
                </div>
              ) : (
                <div className="space-y-4">
                  {orders.map((order) => (
                    <div
                      key={order.id}
                      className={`border rounded-lg p-4 transition-all ${
                        selectedOrders.some(o => o.id === order.id)
                          ? 'border-blue-300 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="flex items-start space-x-4">
                        <input
                          type="checkbox"
                          checked={selectedOrders.some(o => o.id === order.id)}
                          onChange={() => toggleOrderSelection(order)}
                          className="mt-1 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />

                        <div className="flex-1">
                          <div className="flex items-center justify-between mb-3">
                            <div className="flex items-center space-x-3">
                              <h3 className="font-medium text-gray-900">
                                订单号: {order.order_id}
                              </h3>
                              {getStatusBadge(order.status)}
                            </div>
                            <div className="flex items-center space-x-2">
                              <span className="text-lg font-bold text-gray-900">
                                ¥{order.amount}
                              </span>
                              {order.discount_amount > 0 && (
                                <span className="text-sm text-green-600">
                                  (-¥{order.discount_amount})
                                </span>
                              )}
                            </div>
                          </div>

                          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm text-gray-600 mb-3">
                            <div className="flex items-center space-x-2">
                              <User size={16} />
                              <span>{order.user?.email || 'Unknown User'}</span>
                            </div>
                            <div className="flex items-center space-x-2">
                              {getPaymentMethodIcon(order.payment_method)}
                              <span>{getPaymentMethodName(order.payment_method)}</span>
                            </div>
                            <div className="flex items-center space-x-2">
                              <Calendar size={16} />
                              <span>{new Date(order.created_at).toLocaleString()}</span>
                            </div>
                            <div className="flex items-center space-x-2">
                              <Building size={16} />
                              <span>{order.plan?.display_name || 'Unknown Plan'}</span>
                            </div>
                          </div>

                          {order.failure_reason && (
                            <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-3">
                              <div className="flex items-center space-x-2">
                                <AlertCircle size={16} className="text-red-500" />
                                <span className="text-sm text-red-800">
                                  失败原因: {order.failure_reason}
                                </span>
                              </div>
                            </div>
                          )}

                          <div className="flex items-center justify-end space-x-2">
                            {order.status === 'pending' && (
                              <button
                                onClick={() => updateOrder(order.id, { status: 'completed', paid_at: new Date().toISOString() })}
                                className="flex items-center space-x-1 px-3 py-1 text-green-600 hover:bg-green-50 rounded text-sm"
                              >
                                <CheckCircle size={14} />
                                <span>确认支付</span>
                              </button>
                            )}
                            
                            {order.status === 'completed' && (
                              <button
                                onClick={() => handleRefund(order.id)}
                                className="flex items-center space-x-1 px-3 py-1 text-orange-600 hover:bg-orange-50 rounded text-sm"
                              >
                                <RotateCcw size={14} />
                                <span>退款</span>
                              </button>
                            )}

                            <button className="flex items-center space-x-1 px-3 py-1 text-blue-600 hover:bg-blue-50 rounded text-sm">
                              <Eye size={14} />
                              <span>详情</span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}

                  {orders.length === 0 && (
                    <div className="text-center py-12">
                      <CreditCard size={48} className="mx-auto text-gray-400 mb-4" />
                      <h3 className="text-lg font-medium text-gray-900 mb-2">暂无支付订单</h3>
                      <p className="text-gray-500">当前筛选条件下没有找到任何订单</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </>
        )}

        {/* 退款管理标签页 */}
        {activeTab === 'refunds' && (
          <div className="p-6">
            <div className="space-y-4">
              {refunds.map((refund) => (
                <div key={refund.id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="font-medium text-gray-900">
                      退款ID: {refund.id}
                    </h3>
                    <span className="text-lg font-bold text-red-600">
                      -¥{refund.refund_amount}
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 space-y-1">
                    <p>退款原因: {refund.refund_reason}</p>
                    <p>申请时间: {new Date(refund.created_at).toLocaleString()}</p>
                    <p>处理状态: {refund.status}</p>
                  </div>
                </div>
              ))}

              {refunds.length === 0 && (
                <div className="text-center py-12">
                  <RotateCcw size={48} className="mx-auto text-gray-400 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">暂无退款记录</h3>
                  <p className="text-gray-500">当前没有任何退款申请</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* 统计分析标签页 */}
        {activeTab === 'statistics' && statistics && (
          <div className="p-6 space-y-6">
            {/* 支付方式统计 */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">支付方式分布</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {statistics.paymentMethodStats.map((method) => (
                  <div key={method.method} className="bg-gray-50 rounded-lg p-4">
                    <div className="flex items-center space-x-3 mb-2">
                      {getPaymentMethodIcon(method.method)}
                      <span className="font-medium text-gray-900">
                        {getPaymentMethodName(method.method)}
                      </span>
                    </div>
                    <div className="space-y-1">
                      <div className="text-2xl font-bold text-gray-900">
                        {method.count.toLocaleString()}
                      </div>
                      <div className="text-sm text-gray-600">
                        {method.percentage}% · ¥{method.revenue.toLocaleString()}
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div 
                          className="bg-blue-600 h-2 rounded-full" 
                          style={{ width: `${method.percentage}%` }}
                        ></div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 每日收入趋势 */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">每日收入趋势</h3>
              <div className="bg-gray-50 rounded-lg p-4">
                <div className="grid grid-cols-7 gap-4">
                  {statistics.dailyRevenue.map((day) => (
                    <div key={day.date} className="text-center">
                      <div className="text-xs text-gray-500 mb-2">
                        {day.date.split('-')[2]}日
                      </div>
                      <div className="space-y-1">
                        <div className="text-sm font-medium text-gray-900">
                          ¥{(day.revenue / 1000).toFixed(0)}k
                        </div>
                        <div className="text-xs text-gray-600">
                          {day.orders}单
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* 关键指标 */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">关键指标</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="flex items-center justify-center space-x-2 mb-2">
                    <ArrowUpRight className="text-green-600" size={20} />
                    <div className="text-2xl font-bold text-gray-900">
                      {(statistics.monthlyGrowth * 100).toFixed(1)}%
                    </div>
                  </div>
                  <div className="text-sm text-gray-600">月度增长</div>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="flex items-center justify-center space-x-2 mb-2">
                    <RotateCcw className="text-red-600" size={20} />
                    <div className="text-2xl font-bold text-gray-900">
                      {(statistics.refundRate * 100).toFixed(1)}%
                    </div>
                  </div>
                  <div className="text-sm text-gray-600">退款率</div>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="flex items-center justify-center space-x-2 mb-2">
                    <TrendingUp className="text-blue-600" size={20} />
                    <div className="text-2xl font-bold text-gray-900">
                      {(statistics.conversionRate * 100).toFixed(1)}%
                    </div>
                  </div>
                  <div className="text-sm text-gray-600">转化率</div>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="text-2xl font-bold text-gray-900">
                    ¥{statistics.averageOrderValue}
                  </div>
                  <div className="text-sm text-gray-600">平均订单价值</div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}