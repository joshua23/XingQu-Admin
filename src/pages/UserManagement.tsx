import React, { useEffect, useState } from 'react'
import { Search, Filter, MoreVertical, User, Mail, Calendar, RefreshCw, Clock } from 'lucide-react'
import { dataService } from '../services/supabase'
import { useAutoRefresh } from '../hooks/useAutoRefresh'

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

  const getStatusBadge = (isActive?: boolean) => {
    if (isActive) {
      return (
        <span className="px-2 py-1 text-xs rounded-full text-white bg-green-500">
          正常
        </span>
      )
    } else {
      return (
        <span className="px-2 py-1 text-xs rounded-full text-white bg-gray-500">
          未激活
        </span>
      )
    }
  }

  const getMembershipBadge = (subscriptionType?: string) => {
    const membershipConfig = {
      free: { bg: 'bg-gray-600', text: '免费版' },
      basic: { bg: 'bg-blue-500', text: '基础版' },
      premium: { bg: 'bg-yellow-500', text: '高级版' },
      lifetime: { bg: 'bg-purple-500', text: '终身版' }
    }
    const config = membershipConfig[(subscriptionType || 'free') as keyof typeof membershipConfig]
    return (
      <span className={`px-2 py-1 text-xs rounded-full text-white ${config.bg}`}>
        {config.text}
      </span>
    )
  }

  if (loading && !lastUpdated) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和状态 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">用户管理</h1>
          <div className="flex items-center space-x-4 mt-1">
            <p className="text-gray-400">管理星趣App的用户信息和账户状态</p>
            {lastUpdated && (
              <div className="flex items-center text-sm text-gray-500">
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
          className="flex items-center space-x-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 disabled:bg-gray-800 disabled:cursor-not-allowed text-white rounded-lg transition-colors"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          <span>刷新</span>
        </button>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-red-500 rounded-full"></div>
            <p className="text-red-400 font-medium">数据加载失败</p>
          </div>
          <p className="text-red-300 text-sm mt-1">{error}</p>
        </div>
      )}

      {/* 搜索和筛选 */}
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <Search size={20} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="搜索用户姓名或邮箱..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              />
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <Filter size={20} className="text-gray-400" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <option value="all">全部状态</option>
              <option value="active">正常</option>
              <option value="inactive">未激活</option>
            </select>
          </div>
        </div>
      </div>

      {/* 用户列表 */}
      <div className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-700">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  用户信息
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  会员状态
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  账户状态
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  注册时间
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  最后登录
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  操作
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-700">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="w-10 h-10 bg-gray-600 rounded-full flex items-center justify-center">
                        <User size={20} className="text-gray-300" />
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-white">
                          {user.username || '未设置'}
                        </div>
                        <div className="text-sm text-gray-400 flex items-center">
                          <Mail size={14} className="mr-1" />
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getMembershipBadge(user.subscription_type)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getStatusBadge(user.is_active)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                    {user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleDateString() : '从未登录'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button className="text-gray-400 hover:text-white p-1">
                      <MoreVertical size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* 分页 */}
        <div className="bg-gray-700 px-6 py-3 flex items-center justify-between">
          <div className="text-sm text-gray-400">
            显示 {filteredUsers.length} 个用户中的 1 到 {filteredUsers.length} 个
          </div>
          <div className="flex space-x-2">
            <button className="px-3 py-1 text-sm bg-gray-600 hover:bg-gray-500 text-white rounded">
              上一页
            </button>
            <button className="px-3 py-1 text-sm bg-gray-600 hover:bg-gray-500 text-white rounded">
              下一页
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default UserManagement
