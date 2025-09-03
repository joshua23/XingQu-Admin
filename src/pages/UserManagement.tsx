import React, { useState } from 'react'
import { MetricCard } from '../components/MetricCard'
import { DataTable, StatusBadge, type TableColumn } from '../components/DataTable'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/Tabs'
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/Card'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'
import DocumentUploadTab from '../components/document/DocumentUploadTab'
import { UserDetailModal } from '../components/user/UserDetailModal'
import { BatchOperationsModal } from '../components/user/BatchOperationsModal'
import {
  RefreshCw,
  Clock,
  AlertTriangle,
  Search,
  Filter,
  Eye,
  Settings,
  CheckSquare
} from 'lucide-react'

interface User {
  id: string
  user_id: string
  nickname?: string
  avatar_url?: string
  created_at: string
  updated_at?: string
  account_status: 'active' | 'inactive' | 'suspended' | 'violation' | 'deactivated'
  is_member: boolean
  membership_expires_at?: string
  gender?: 'male' | 'female' | 'hidden'
}

// 用户基础指标 (动态生成)
const generateUserBasicMetrics = (userMetrics: any) => {
  const metrics = userMetrics || { totalUsers: 0, newUsers: 0, activeUsers: 0, memberUsers: 0 }
  
  return [
    { 
      title: "总用户数", 
      value: metrics.totalUsers, 
      change: metrics.totalUsers > 0 ? 100 : 0, 
      changeLabel: "较上月" 
    },
    { 
      title: "新增用户", 
      value: metrics.newUsers, 
      change: metrics.newUsers > 0 ? 100 : 0, 
      changeLabel: "较上月" 
    },
    { 
      title: "活跃用户", 
      value: metrics.activeUsers, 
      change: metrics.activeUsers > 0 ? 100 : 0, 
      changeLabel: "较上月" 
    },
    { 
      title: "会员用户", 
      value: metrics.memberUsers, 
      change: metrics.memberUsers > 0 ? 100 : 0, 
      changeLabel: "较上月" 
    },
  ]
}

// 基础属性表格配置（将在组件内部重新定义）

// 账户状态表格配置
const accountStatusColumns: TableColumn[] = [
  { key: 'userId', label: '用户ID', width: '120px' },
  {
    key: 'accountStatus',
    label: '账号状态',
    width: '100px',
    align: 'center',
    render: (value) => <StatusBadge status={value} />
  },
  { key: 'lastLogin', label: '最后登录时间', width: '140px' },
  { key: 'hasPhone', label: '绑定手机号', width: '100px', align: 'center' },
  { key: 'thirdParty', label: '第三方绑定', width: '120px' },
  { key: 'registerChannel', label: '注册渠道', width: '100px' },
  { key: 'accountAge', label: '账号创建时长(天)', width: '120px', align: 'right' },
  { key: 'activeDays', label: '近30天活跃天数', width: '120px', align: 'right' },
];

// 基于真实数据生成表格数据的函数
const generateBasicAttributesData = (users: User[]) => {
  return users.map((user) => {
    const genderMap = {
      'male': '男',
      'female': '女',
      'hidden': '保密'
    }
    
    const memberLevelMap = {
      'true': '普通会员',
      'false': '非会员'
    }
    
    return {
      userId: user.user_id.slice(0, 8), // 显示短ID
      registerTime: user.created_at.split('T')[0],
      gender: genderMap[user.gender || 'hidden' as keyof typeof genderMap] || '保密',
      ageGroup: '25-35', // 暂时固定，后续可根据实际数据计算
      location: '未知', // 暂无地理位置数据
      device: 'Web应用', // 暂无设备信息
      system: '未知', // 暂无系统信息
      memberLevel: memberLevelMap[String(user.is_member) as keyof typeof memberLevelMap]
    }
  })
}

const generateAccountStatusData = (users: User[]) => {
  return users.map((user) => {
    const statusMap = {
      'active': '正常',
      'inactive': '未激活',
      'suspended': '冻结',
      'violation': '违规',
      'deactivated': '注销'
    }
    
    const accountAge = Math.floor((Date.now() - new Date(user.created_at).getTime()) / (1000 * 60 * 60 * 24))
    
    return {
      userId: user.user_id.slice(0, 8),
      accountStatus: statusMap[user.account_status as keyof typeof statusMap] || '未知',
      lastLogin: user.updated_at ? user.updated_at.replace('T', ' ').slice(0, 16) : '从未登录',
      hasPhone: '未知', // 需要额外查询
      thirdParty: '未知', // 需要分析登录方式
      registerChannel: 'Web', // 暂时固定
      accountAge: accountAge,
      activeDays: Math.min(accountAge, 30) // 估算值
    }
  })
}

const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([])
  const [userMetrics, setUserMetrics] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [_searchTerm, setSearchTerm] = useState('')
  const [_statusFilter, setStatusFilter] = useState<string>('all')
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)
  
  // 新增状态管理
  const [selectedUsers, setSelectedUsers] = useState<string[]>([])
  const [showUserDetail, setShowUserDetail] = useState<string | null>(null)
  const [showBatchOperations, setShowBatchOperations] = useState(false)

  // 加载真实用户数据
  const loadUsers = async () => {
    try {
      setLoading(true)
      setError(null)

      const [userStatsResult, userMetricsResult] = await Promise.all([
        dataService.getUserStats(),
        dataService.getUserMetrics()
      ])

      if (userStatsResult.error) {
        throw new Error((userStatsResult.error as any)?.message || '加载用户数据失败')
      }

      if (userMetricsResult.error) {
        throw new Error((userMetricsResult.error as any)?.message || '加载用户指标失败')
      }

      if (userStatsResult.data) {
        setUsers(userStatsResult.data)
      }

      if (userMetricsResult.data) {
        setUserMetrics(userMetricsResult.data)
      }

      setLastUpdated(new Date())
    } catch (error) {
      console.error('加载用户数据失败:', error)
      setError(error instanceof Error ? error.message : '加载数据失败')
    } finally {
      setLoading(false)
    }
  }

  // 设置15分钟自动刷新
  const { refresh } = useAutoRefresh(loadUsers, {
    interval: 15 * 60 * 1000, // 15分钟
    enabled: true,
    immediate: true
  })

  // 处理函数
  const handleUserSelect = (userId: string, selected: boolean) => {
    if (selected) {
      setSelectedUsers(prev => [...prev, userId])
    } else {
      setSelectedUsers(prev => prev.filter(id => id !== userId))
    }
  }

  const handleSelectAll = (selected: boolean) => {
    if (selected) {
      setSelectedUsers(users.map(user => user.user_id))
    } else {
      setSelectedUsers([])
    }
  }

  const handleViewUserDetail = (userId: string) => {
    setShowUserDetail(userId)
  }

  const handleBatchOperations = () => {
    if (selectedUsers.length === 0) {
      alert('请先选择要操作的用户')
      return
    }
    setShowBatchOperations(true)
  }

  const handleModalClose = () => {
    setShowUserDetail(null)
    setShowBatchOperations(false)
    setSelectedUsers([])
    // 刷新数据
    loadUsers()
  }

  // 增强的基础属性表格配置
  const basicAttributesColumns: TableColumn[] = [
    {
      key: 'select',
      label: (
        <input
          type="checkbox"
          onChange={(e) => handleSelectAll(e.target.checked)}
          checked={selectedUsers.length === users.length && users.length > 0}
          className="rounded"
        />
      ),
      width: '50px',
      align: 'center',
      render: (_value, row: any) => (
        <input
          type="checkbox"
          checked={selectedUsers.includes(row.user_id)}
          onChange={(e) => handleUserSelect(row.user_id, e.target.checked)}
          className="rounded"
        />
      )
    },
    { key: 'user_id', label: '用户ID', width: '120px' },
    { key: 'nickname', label: '昵称', width: '120px' },
    { 
      key: 'created_at', 
      label: '注册时间', 
      width: '140px',
      render: (value) => value ? new Date(value).toLocaleDateString() : '-'
    },
    { 
      key: 'gender', 
      label: '性别', 
      width: '80px', 
      align: 'center',
      render: (value) => value === 'male' ? '男' : value === 'female' ? '女' : '-'
    },
    {
      key: 'is_member',
      label: '会员等级',
      width: '100px',
      align: 'center',
      render: (value) => (
        <span className={`px-2 py-1 text-xs rounded-full ${
          value ? 'bg-yellow-500 text-white' : 'bg-gray-500 text-white'
        }`}>
          {value ? '会员' : '非会员'}
        </span>
      )
    },
    {
      key: 'account_status',
      label: '账户状态',
      width: '100px',
      align: 'center',
      render: (value) => <StatusBadge status={value} />
    },
    {
      key: 'actions',
      label: '操作',
      width: '120px',
      align: 'center',
      render: (_value, row: any) => (
        <div className="flex items-center justify-center space-x-2">
          <button
            onClick={() => handleViewUserDetail(row.user_id)}
            className="p-1 text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
            title="查看详情"
          >
            <Eye size={16} />
          </button>
        </div>
      )
    }
  ]


  if (loading && !lastUpdated) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和状态 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">用户管理</h1>
          <div className="flex items-center space-x-4 mt-1">
            <p className="text-muted-foreground">管理星趣App的用户信息和账户状态</p>
            {lastUpdated && (
              <div className="flex items-center text-sm text-muted-foreground">
                <Clock size={14} className="mr-1" />
                最后更新: {lastUpdated.toLocaleTimeString()}
              </div>
            )}
          </div>
        </div>

        {/* 手动刷新按钮 */}
        <button
          onClick={() => refresh()}
          disabled={loading}
          className="flex items-center space-x-2 px-4 py-2 bg-secondary hover:bg-secondary/80 disabled:bg-secondary/50 disabled:cursor-not-allowed text-secondary-foreground rounded-lg transition-colors"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          <span>刷新</span>
        </button>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertTriangle size={16} className="text-destructive" />
            <p className="text-destructive font-medium">数据加载失败</p>
          </div>
          <p className="text-destructive/80 text-sm mt-1">{error}</p>
        </div>
      )}

      {/* 用户基础指标 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {generateUserBasicMetrics(userMetrics).map((metric, index) => (
          <MetricCard key={index} {...metric} />
        ))}
      </div>

      {/* 用户数据详情 */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">用户数据详情</CardTitle>
        </CardHeader>
        <CardContent>
          {/* 搜索和筛选 */}
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="flex-1">
              <div className="relative">
                <Search size={20} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
                <input
                  type="text"
                  placeholder="搜索用户ID或昵称..."
                  value={_searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-background border border-input rounded-lg text-foreground placeholder-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
            <div className="flex items-center space-x-4">
              {selectedUsers.length > 0 && (
                <div className="flex items-center space-x-2">
                  <span className="text-sm text-muted-foreground">
                    已选中 {selectedUsers.length} 个用户
                  </span>
                  <button
                    onClick={handleBatchOperations}
                    className="flex items-center space-x-1 px-3 py-2 bg-primary-500 hover:bg-primary-600 text-white rounded-lg transition-colors"
                  >
                    <Settings size={16} />
                    <span>批量操作</span>
                  </button>
                </div>
              )}
              <div className="flex items-center space-x-2">
                <Filter size={20} className="text-muted-foreground" />
                <select
                  value={_statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="px-3 py-2 bg-background border border-input rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                >
                  <option value="all">全部状态</option>
                  <option value="active">正常</option>
                  <option value="inactive">未激活</option>
                </select>
              </div>
            </div>
          </div>

          {/* 数据表格 */}
          <Tabs defaultValue="basic-attributes" className="space-y-4">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="basic-attributes">基础属性</TabsTrigger>
              <TabsTrigger value="account-status">账户状态</TabsTrigger>
              <TabsTrigger value="document-management">隐私/用户协议管理</TabsTrigger>
            </TabsList>

            <TabsContent value="basic-attributes">
              <DataTable
                title="用户基础属性统计"
                columns={basicAttributesColumns}
                data={users}
              />
            </TabsContent>

            <TabsContent value="account-status">
              <DataTable
                title="用户账户状态统计"
                columns={accountStatusColumns}
                data={generateAccountStatusData(users)}
              />
            </TabsContent>

            <TabsContent value="document-management">
              <DocumentUploadTab />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* 用户详情模态框 */}
      {showUserDetail && (
        <UserDetailModal
          userId={showUserDetail}
          onClose={handleModalClose}
          onUpdate={handleModalClose}
        />
      )}

      {/* 批量操作模态框 */}
      {showBatchOperations && (
        <BatchOperationsModal
          selectedUsers={selectedUsers}
          onClose={handleModalClose}
          onSuccess={handleModalClose}
        />
      )}
    </div>
  )
}

export default UserManagement
