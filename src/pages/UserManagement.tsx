import React, { useEffect, useState } from 'react'
import { MetricCard } from '../components/MetricCard'
import { DataTable, StatusBadge, type TableColumn } from '../components/DataTable'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/Tabs'
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/Card'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'
import {
  Users,
  UserCheck,
  UserX,
  Crown,
  RefreshCw,
  Clock,
  AlertTriangle,
  Search,
  Filter
} from 'lucide-react'

interface User {
  id: string
  email: string
  username?: string
  avatar_url?: string
  created_at: string
  last_sign_in_at?: string
  subscription_type?: 'free' | 'basic' | 'premium' | 'lifetime'
  is_active?: boolean
}

// 用户基础指标
const userBasicMetrics = [
  { title: "总用户数", value: 128540, change: 12.5, changeLabel: "较上月" },
  { title: "新增用户", value: 3248, change: 8.2, changeLabel: "较上月" },
  { title: "活跃用户", value: 45621, change: -2.1, changeLabel: "较上月" },
  { title: "会员用户", value: 12847, change: 15.6, changeLabel: "较上月" },
]

// 基础属性表格配置
const basicAttributesColumns: TableColumn[] = [
  { key: 'userId', label: '用户ID', width: '120px' },
  { key: 'registerTime', label: '注册时间', width: '140px' },
  { key: 'gender', label: '性别', width: '80px', align: 'center' },
  { key: 'ageGroup', label: '年龄分层', width: '100px', align: 'center' },
  { key: 'location', label: '地域', width: '120px' },
  { key: 'device', label: '设备型号', width: '120px' },
  { key: 'system', label: '系统版本', width: '100px' },
  {
    key: 'memberLevel',
    label: '会员等级',
    width: '100px',
    align: 'center',
    render: (value) => {
      const levels = {
        '普通会员': { variant: 'default' as const, text: '普通' },
        '高级会员': { variant: 'warning' as const, text: '高级' },
        'VIP会员': { variant: 'success' as const, text: 'VIP' },
        '非会员': { variant: 'secondary' as const, text: '非会员' }
      };
      const level = levels[value as keyof typeof levels] || levels['非会员'];
      return <span className={`px-2 py-1 text-xs rounded-full bg-${level.variant} text-${level.variant}-foreground`}>{level.text}</span>;
    }
  },
];

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

// Mock 数据
const basicAttributesData = [
  {
    userId: 'U001234',
    registerTime: '2024-01-15',
    gender: '男',
    ageGroup: '25-35',
    location: '北京市',
    device: 'iPhone 14',
    system: 'iOS 17.2',
    memberLevel: '普通会员'
  },
  {
    userId: 'U001235',
    registerTime: '2024-01-16',
    gender: '女',
    ageGroup: '18-25',
    location: '上海市',
    device: 'Huawei P50',
    system: 'Android 12',
    memberLevel: '高级会员'
  },
  {
    userId: 'U001236',
    registerTime: '2024-01-17',
    gender: '男',
    ageGroup: '35-45',
    location: '广州市',
    device: 'Samsung S23',
    system: 'Android 13',
    memberLevel: '非会员'
  },
];

const accountStatusData = [
  {
    userId: 'U001234',
    accountStatus: '正常',
    lastLogin: '2024-01-30 14:30',
    hasPhone: '是',
    thirdParty: '微信',
    registerChannel: '官网',
    accountAge: 15,
    activeDays: 12
  },
  {
    userId: 'U001235',
    accountStatus: '正常',
    lastLogin: '2024-01-30 16:45',
    hasPhone: '是',
    thirdParty: 'QQ',
    registerChannel: 'App Store',
    accountAge: 14,
    activeDays: 18
  },
  {
    userId: 'U001236',
    accountStatus: '冻结',
    lastLogin: '2024-01-28 09:15',
    hasPhone: '否',
    thirdParty: '无',
    registerChannel: '推广链接',
    accountAge: 13,
    activeDays: 5
  },
];

const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)

  // 加载真实用户数据
  const loadUsers = async () => {
    try {
      setLoading(true)
      setError(null)

      const { data, error: apiError } = await dataService.getUserStats()

      if (apiError) {
        throw new Error(apiError.message || '加载用户数据失败')
      }

      if (data) {
        setUsers(data)
        setLastUpdated(new Date())
      }
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

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.username?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' ||
                         (statusFilter === 'active' && user.is_active) ||
                         (statusFilter === 'inactive' && !user.is_active)
    return matchesSearch && matchesStatus
  })

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
        {userBasicMetrics.map((metric, index) => (
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
                  placeholder="搜索用户ID或邮箱..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-background border border-input rounded-lg text-foreground placeholder-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Filter size={20} className="text-muted-foreground" />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 bg-background border border-input rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              >
                <option value="all">全部状态</option>
                <option value="active">正常</option>
                <option value="inactive">未激活</option>
              </select>
            </div>
          </div>

          {/* 数据表格 */}
          <Tabs defaultValue="basic-attributes" className="space-y-4">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="basic-attributes">基础属性</TabsTrigger>
              <TabsTrigger value="account-status">账户状态</TabsTrigger>
            </TabsList>

            <TabsContent value="basic-attributes">
              <DataTable
                title="用户基础属性统计"
                columns={basicAttributesColumns}
                data={basicAttributesData}
              />
            </TabsContent>

            <TabsContent value="account-status">
              <DataTable
                title="用户账户状态统计"
                columns={accountStatusColumns}
                data={accountStatusData}
              />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  )
}

export default UserManagement
