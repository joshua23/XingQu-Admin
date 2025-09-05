/**
 * 星趣后台管理系统 - 订阅管理组件
 * 提供订阅计划管理和用户订阅操作功能
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect } from 'react'
import { 
  CreditCard, 
  Users, 
  TrendingUp, 
  Calendar,
  Search,
  Filter,
  Download,
  Plus,
  Edit,
  Trash2,
  Crown,
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle,
  DollarSign,
  BarChart3,
  Settings,
  Eye,
  RefreshCw,
  Pause,
  Play,
  ArrowUp,
  ArrowDown
} from 'lucide-react'
import { useSubscriptionManagement } from '@/lib/hooks/useSubscriptionManagement'
import type { SubscriptionFilters, UserSubscription, SubscriptionPlan } from '@/lib/types/admin'

interface SubscriptionManagerProps {
  className?: string
}

export default function SubscriptionManager({ className }: SubscriptionManagerProps) {
  const {
    plans,
    subscriptions,
    selectedSubscriptions,
    statistics,
    totalSubscriptions,
    loading,
    processing,
    error,
    loadPlans,
    loadSubscriptions,
    loadStatistics,
    updateSubscription,
    bulkOperate,
    selectSubscription,
    unselectSubscription,
    selectAllSubscriptions,
    clearSelection,
    toggleSubscriptionSelection,
    exportData,
    clearError
  } = useSubscriptionManagement()

  const [activeTab, setActiveTab] = useState<'subscriptions' | 'plans' | 'statistics'>('subscriptions')
  const [filters, setFilters] = useState<SubscriptionFilters>({})
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedStatus, setSelectedStatus] = useState<string>('all')
  const [selectedPlanId, setSelectedPlanId] = useState<string>('all')

  // 页面初始化
  useEffect(() => {
    loadSubscriptions()
    loadPlans()
    loadStatistics()
  }, [loadSubscriptions, loadPlans, loadStatistics])

  // 处理搜索和过滤
  useEffect(() => {
    const newFilters: SubscriptionFilters = {}

    if (searchTerm) {
      newFilters.search = searchTerm
    }

    if (selectedStatus !== 'all') {
      newFilters.status = [selectedStatus]
    }

    if (selectedPlanId !== 'all') {
      newFilters.planIds = [selectedPlanId]
    }

    setFilters(newFilters)
    loadSubscriptions(newFilters)
  }, [searchTerm, selectedStatus, selectedPlanId, loadSubscriptions])

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800 border-green-200',
      cancelled: 'bg-red-100 text-red-800 border-red-200',
      expired: 'bg-gray-100 text-gray-800 border-gray-200',
      paused: 'bg-yellow-100 text-yellow-800 border-yellow-200'
    }
    const labels = {
      active: '活跃',
      cancelled: '已取消',
      expired: '已过期',
      paused: '已暂停'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles]}`}>
        {labels[status as keyof typeof labels]}
      </span>
    )
  }

  const getPlanBadge = (plan: SubscriptionPlan) => {
    const colors = {
      free: 'bg-gray-100 text-gray-800',
      basic: 'bg-blue-100 text-blue-800',
      premium: 'bg-purple-100 text-purple-800',
      lifetime: 'bg-yellow-100 text-yellow-800'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${colors[plan.name as keyof typeof colors] || 'bg-gray-100 text-gray-800'}`}>
        {plan.display_name}
      </span>
    )
  }

  const handleBulkOperation = async (operation: string) => {
    if (selectedSubscriptions.length === 0) return

    try {
      await bulkOperate({
        operation: operation as any,
        subscriptionIds: selectedSubscriptions.map(sub => sub.id),
        parameters: {}
      })
    } catch (error) {
      console.error('批量操作失败:', error)
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
      link.setAttribute('download', `subscriptions_${new Date().toISOString().split('T')[0]}.csv`)
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
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <Users size={24} className="text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{statistics.activeSubscriptions.toLocaleString()}</p>
                <p className="text-sm text-gray-600">活跃订阅</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <DollarSign size={24} className="text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">¥{statistics.monthlyRecurringRevenue.toLocaleString()}</p>
                <p className="text-sm text-gray-600">月度经常性收入</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <TrendingUp size={24} className="text-purple-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">¥{statistics.averageRevenuePerUser}</p>
                <p className="text-sm text-gray-600">平均用户收入</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <AlertCircle size={24} className="text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{(statistics.churnRate * 100).toFixed(1)}%</p>
                <p className="text-sm text-gray-600">流失率</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 标签页 */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="flex border-b border-gray-200">
          <button
            onClick={() => setActiveTab('subscriptions')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'subscriptions'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <CreditCard size={16} />
              <span>用户订阅</span>
            </div>
          </button>

          <button
            onClick={() => setActiveTab('plans')}
            className={`px-6 py-4 font-medium text-sm transition-colors ${
              activeTab === 'plans'
                ? 'border-b-2 border-blue-500 text-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              <Crown size={16} />
              <span>订阅计划</span>
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
              <BarChart3 size={16} />
              <span>统计分析</span>
            </div>
          </button>
        </div>

        {/* 用户订阅标签页 */}
        {activeTab === 'subscriptions' && (
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
                      placeholder="搜索用户..."
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
                    <option value="active">活跃</option>
                    <option value="cancelled">已取消</option>
                    <option value="expired">已过期</option>
                    <option value="paused">已暂停</option>
                  </select>

                  <select
                    value={selectedPlanId}
                    onChange={(e) => setSelectedPlanId(e.target.value)}
                    className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">所有计划</option>
                    {plans.map((plan) => (
                      <option key={plan.id} value={plan.id}>
                        {plan.display_name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* 操作按钮 */}
                <div className="flex items-center space-x-3">
                  {selectedSubscriptions.length > 0 && (
                    <>
                      <button
                        onClick={() => handleBulkOperation('extend')}
                        disabled={processing}
                        className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                      >
                        <Calendar size={16} />
                        <span>延期</span>
                      </button>
                      <button
                        onClick={() => handleBulkOperation('pause')}
                        disabled={processing}
                        className="flex items-center space-x-2 px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 disabled:opacity-50"
                      >
                        <Pause size={16} />
                        <span>暂停</span>
                      </button>
                      <button
                        onClick={() => handleBulkOperation('cancel')}
                        disabled={processing}
                        className="flex items-center space-x-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                      >
                        <XCircle size={16} />
                        <span>取消</span>
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

              {selectedSubscriptions.length > 0 && (
                <div className="mt-4 flex items-center justify-between bg-blue-50 rounded-lg p-3">
                  <span className="text-sm text-blue-800">
                    已选择 {selectedSubscriptions.length} 个订阅
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

            {/* 订阅列表 */}
            <div className="p-6">
              {loading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  <span className="ml-3 text-gray-600">加载中...</span>
                </div>
              ) : (
                <div className="space-y-4">
                  {subscriptions.map((subscription) => (
                    <div
                      key={subscription.id}
                      className={`border rounded-lg p-4 transition-all ${
                        selectedSubscriptions.some(s => s.id === subscription.id)
                          ? 'border-blue-300 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="flex items-center space-x-4">
                        <input
                          type="checkbox"
                          checked={selectedSubscriptions.some(s => s.id === subscription.id)}
                          onChange={() => toggleSubscriptionSelection(subscription)}
                          className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />

                        <div className="flex-1">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center space-x-3">
                              <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                                <span className="text-sm font-medium text-gray-600">
                                  {subscription.user?.email?.[0]?.toUpperCase() || 'U'}
                                </span>
                              </div>
                              <div>
                                <h3 className="font-medium text-gray-900">
                                  {subscription.user?.email || 'Unknown User'}
                                </h3>
                                <p className="text-sm text-gray-500">
                                  {subscription.user?.username || 'No username'}
                                </p>
                              </div>
                            </div>
                            <div className="flex items-center space-x-2">
                              {getPlanBadge(subscription.plan!)}
                              {getStatusBadge(subscription.status)}
                            </div>
                          </div>

                          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm text-gray-600">
                            <div>
                              <span className="font-medium">开始时间:</span>
                              <p>{new Date(subscription.starts_at).toLocaleDateString()}</p>
                            </div>
                            <div>
                              <span className="font-medium">到期时间:</span>
                              <p>{new Date(subscription.expires_at).toLocaleDateString()}</p>
                            </div>
                            <div>
                              <span className="font-medium">自动续费:</span>
                              <p>{subscription.auto_renew ? '是' : '否'}</p>
                            </div>
                            <div>
                              <span className="font-medium">价格:</span>
                              <p>¥{subscription.plan?.price || 0}</p>
                            </div>
                          </div>

                          <div className="flex items-center justify-end space-x-2 mt-3">
                            <button
                              onClick={() => updateSubscription(subscription.id, { status: 'active' })}
                              className="flex items-center space-x-1 px-3 py-1 text-green-600 hover:bg-green-50 rounded"
                            >
                              <Play size={14} />
                              <span>激活</span>
                            </button>
                            <button
                              onClick={() => updateSubscription(subscription.id, { status: 'paused' })}
                              className="flex items-center space-x-1 px-3 py-1 text-yellow-600 hover:bg-yellow-50 rounded"
                            >
                              <Pause size={14} />
                              <span>暂停</span>
                            </button>
                            <button className="flex items-center space-x-1 px-3 py-1 text-blue-600 hover:bg-blue-50 rounded">
                              <Eye size={14} />
                              <span>详情</span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}

                  {subscriptions.length === 0 && (
                    <div className="text-center py-12">
                      <CreditCard size={48} className="mx-auto text-gray-400 mb-4" />
                      <h3 className="text-lg font-medium text-gray-900 mb-2">暂无订阅记录</h3>
                      <p className="text-gray-500">当前筛选条件下没有找到任何订阅</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </>
        )}

        {/* 订阅计划标签页 */}
        {activeTab === 'plans' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {plans.map((plan) => (
                <div key={plan.id} className="border rounded-lg p-6 hover:border-blue-300 transition-colors">
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h3 className="font-semibold text-lg text-gray-900">{plan.display_name}</h3>
                      <p className="text-gray-600">{plan.description}</p>
                    </div>
                    <div className="flex items-center space-x-1">
                      <button className="p-1 text-gray-400 hover:text-blue-600">
                        <Edit size={16} />
                      </button>
                      <button className="p-1 text-gray-400 hover:text-red-600">
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>

                  <div className="mb-4">
                    <div className="flex items-baseline space-x-1">
                      <span className="text-3xl font-bold text-gray-900">¥{plan.price}</span>
                      <span className="text-gray-500">
                        /{plan.billing_period === 'monthly' ? '月' : plan.billing_period === 'yearly' ? '年' : '终身'}
                      </span>
                    </div>
                  </div>

                  <div className="space-y-2 mb-4">
                    {plan.features.map((feature, index) => (
                      <div key={index} className="flex items-center space-x-2 text-sm">
                        <CheckCircle size={16} className="text-green-500" />
                        <span>{feature}</span>
                      </div>
                    ))}
                  </div>

                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>排序: {plan.sort_order}</span>
                    <span className={`px-2 py-1 rounded-full text-xs ${
                      plan.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                    }`}>
                      {plan.is_active ? '活跃' : '停用'}
                    </span>
                  </div>
                </div>
              ))}

              {/* 添加新计划按钮 */}
              <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 flex flex-col items-center justify-center hover:border-blue-400 transition-colors cursor-pointer">
                <Plus size={32} className="text-gray-400 mb-2" />
                <span className="text-gray-500">添加新计划</span>
              </div>
            </div>
          </div>
        )}

        {/* 统计分析标签页 */}
        {activeTab === 'statistics' && statistics && (
          <div className="p-6 space-y-6">
            {/* 计划分布 */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">计划分布</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {statistics.planDistribution.map((item) => (
                  <div key={item.planId} className="bg-gray-50 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-gray-900">{item.planName}</span>
                      <span className="text-xs text-gray-500">{item.percentage}%</span>
                    </div>
                    <div className="text-2xl font-bold text-gray-900">{item.count.toLocaleString()}</div>
                    <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
                      <div 
                        className="bg-blue-600 h-2 rounded-full" 
                        style={{ width: `${item.percentage}%` }}
                      ></div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 月度趋势 */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">月度趋势</h3>
              <div className="bg-gray-50 rounded-lg p-4">
                <div className="grid grid-cols-7 gap-4">
                  {statistics.monthlyTrend.map((item) => (
                    <div key={item.month} className="text-center">
                      <div className="text-xs text-gray-500 mb-1">
                        {item.month.split('-')[1]}月
                      </div>
                      <div className="space-y-1">
                        <div className="text-sm font-medium text-green-600">
                          +{item.newSubs}
                        </div>
                        <div className="text-sm text-red-600">
                          -{item.cancelled}
                        </div>
                        <div className="text-xs text-gray-600">
                          ¥{(item.revenue / 1000).toFixed(0)}k
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
                  <div className="text-2xl font-bold text-gray-900">{statistics.expiringThisWeek}</div>
                  <div className="text-sm text-gray-600">本周到期</div>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="text-2xl font-bold text-gray-900">{statistics.expiringThisMonth}</div>
                  <div className="text-sm text-gray-600">本月到期</div>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="text-2xl font-bold text-gray-900">{(statistics.renewalRate * 100).toFixed(1)}%</div>
                  <div className="text-sm text-gray-600">续费率</div>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <div className="flex items-center justify-center space-x-2">
                    <div className="flex items-center space-x-1 text-green-600">
                      <ArrowUp size={16} />
                      <span className="font-bold">{statistics.upgrades}</span>
                    </div>
                    <div className="flex items-center space-x-1 text-red-600">
                      <ArrowDown size={16} />
                      <span className="font-bold">{statistics.downgrades}</span>
                    </div>
                  </div>
                  <div className="text-sm text-gray-600">升级/降级</div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}