'use client'

import React, { useState, useEffect } from 'react'
import { Users, Search, Filter, MoreHorizontal, Edit, Trash, UserPlus, Ban, CheckCircle, XCircle, FileText, Shield } from 'lucide-react'
import { AddUserModal } from '@/components/modals/AddUserModal'
import { adminUserService, AdminUser } from '@/lib/services/adminUserService'

interface User {
  id: string
  nickname: string
  email: string
  avatar_url?: string
  created_at: string
  account_status: 'active' | 'inactive' | 'banned'
  is_member: boolean
  phone?: string
  last_login?: string
  agreement_accepted: boolean
  agreement_version?: string
  role: 'user' | 'premium' | 'admin'
}

const mockUsers: User[] = [
  {
    id: '1',
    nickname: '张三',
    email: 'zhangsan@example.com',
    created_at: '2024-01-15',
    account_status: 'active',
    is_member: true,
    phone: '138****1234',
    last_login: '2024-01-20 10:30',
    agreement_accepted: true,
    agreement_version: 'v2.1',
    role: 'premium'
  },
  {
    id: '2', 
    nickname: '李四',
    email: 'lisi@example.com',
    created_at: '2024-02-20',
    account_status: 'active',
    is_member: false,
    phone: '139****5678',
    last_login: '2024-02-25 14:20',
    agreement_accepted: true,
    agreement_version: 'v2.0',
    role: 'user'
  },
  {
    id: '3',
    nickname: '王五',
    email: 'wangwu@example.com', 
    created_at: '2024-03-10',
    account_status: 'inactive',
    is_member: true,
    last_login: '2024-03-05 09:15',
    agreement_accepted: false,
    agreement_version: 'v1.5',
    role: 'user'
  },
  {
    id: '4',
    nickname: '赵六',
    email: 'zhaoliu@example.com',
    created_at: '2024-03-15',
    account_status: 'banned',
    is_member: false,
    phone: '137****9012',
    last_login: '2024-03-14 16:45',
    agreement_accepted: true,
    agreement_version: 'v2.1',
    role: 'user'
  }
]

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set())
  const [showUserDetail, setShowUserDetail] = useState<AdminUser | null>(null)
  const [showAddUserModal, setShowAddUserModal] = useState(false)

  // 加载用户数据
  const loadUsers = async () => {
    try {
      setLoading(true)
      const { data, error } = await adminUserService.getAllAdminUsers()
      
      if (error) {
        console.error('Error loading users:', error)
        // 如果数据库还没有表，使用mock数据作为fallback
        setUsers(mockUsers as any[])
      } else if (data) {
        setUsers(data)
      }
    } catch (error) {
      console.error('Error loading users:', error)
      // 使用mock数据作为fallback
      setUsers(mockUsers as any[])
    } finally {
      setLoading(false)
    }
  }

  // 页面加载时获取数据
  useEffect(() => {
    loadUsers()
  }, [])

  // 用户添加成功后重新加载数据
  const handleUserAdded = () => {
    loadUsers()
  }

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.nickname.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || user.account_status === statusFilter
    return matchesSearch && matchesStatus
  })

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800 border-green-200',
      inactive: 'bg-gray-100 text-gray-800 border-gray-200', 
      banned: 'bg-red-100 text-red-800 border-red-200'
    }
    const labels = {
      active: '活跃',
      inactive: '非活跃',
      banned: '已封禁'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles]}`}>
        {labels[status as keyof typeof labels]}
      </span>
    )
  }

  const getMembershipBadge = (isMember: boolean) => {
    return isMember ? (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-primary/10 text-primary border border-primary/20">
        会员
      </span>
    ) : (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-border">
        普通用户
      </span>
    )
  }

  const getAgreementBadge = (accepted: boolean, version?: string) => {
    return accepted ? (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-success/10 text-success border border-success/20">
        已同意 {version}
      </span>
    ) : (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-warning/10 text-warning border border-warning/20">
        未同意
      </span>
    )
  }

  const handleUserAction = async (userId: string, action: string) => {
    try {
      let updateData: Partial<AdminUser> = {}
      
      switch (action) {
        case 'activate':
          updateData = { account_status: 'active' }
          break
        case 'deactivate':
          updateData = { account_status: 'inactive' }
          break
        case 'ban':
          updateData = { account_status: 'banned' }
          break
        default:
          return
      }

      const { error } = await adminUserService.updateAdminUser(userId, updateData)
      
      if (error) {
        console.error('Error updating user:', error)
        return
      }

      // 重新加载数据
      loadUsers()
    } catch (error) {
      console.error('Error updating user:', error)
    }
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">用户管理</h1>
          <p className="text-sm text-muted-foreground">管理系统中的所有用户账户</p>
        </div>
        <button 
          onClick={() => setShowAddUserModal(true)}
          className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-primary to-secondary text-primary-foreground rounded-xl hover:shadow-lg hover:shadow-primary/25 transition-all duration-200 font-medium"
        >
          <UserPlus size={18} />
          <span>添加用户</span>
        </button>
      </div>

      {/* Filters */}
      <div className="bg-card border border-border rounded-lg p-6 mt-3">
        <div className="flex flex-col sm:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="搜索用户..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            />
          </div>
          
          {/* Status Filter */}
          <div className="flex items-center space-x-2">
            <Filter size={16} className="text-muted-foreground" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            >
              <option value="all">所有状态</option>
              <option value="active">活跃</option>
              <option value="inactive">非活跃</option>
              <option value="banned">已封禁</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-card border border-border rounded-lg overflow-hidden mt-3">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50 border-b border-border">
              <tr>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">用户</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">联系信息</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">账户状态</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">会员类型</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">用户协议</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">最后登录</th>
                <th className="text-center py-4 px-6 font-medium text-sm text-muted-foreground">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-muted/30 transition-colors">
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                        <span className="text-sm font-medium text-primary">
                          {user.nickname[0]}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium text-foreground">{user.nickname}</div>
                        <div className="text-xs text-muted-foreground">ID: {user.id}</div>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="space-y-1">
                      <div className="text-sm text-foreground">{user.email}</div>
                      {user.phone && (
                        <div className="text-xs text-muted-foreground">{user.phone}</div>
                      )}
                    </div>
                  </td>
                  <td className="py-4 px-6">{getStatusBadge(user.account_status)}</td>
                  <td className="py-4 px-6">{getMembershipBadge(user.is_member)}</td>
                  <td className="py-4 px-6">{getAgreementBadge(user.agreement_accepted, user.agreement_version)}</td>
                  <td className="py-4 px-6">
                    <div className="text-sm text-muted-foreground">
                      {user.last_login || '未登录'}
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex items-center justify-center space-x-2">
                      {user.account_status === 'active' ? (
                        <button 
                          onClick={() => handleUserAction(user.id, 'deactivate')}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="停用账户"
                        >
                          <XCircle size={16} className="text-orange-500" />
                        </button>
                      ) : user.account_status === 'inactive' ? (
                        <button 
                          onClick={() => handleUserAction(user.id, 'activate')}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="激活账户"
                        >
                          <CheckCircle size={16} className="text-green-500" />
                        </button>
                      ) : null}
                      {user.account_status !== 'banned' && (
                        <button 
                          onClick={() => handleUserAction(user.id, 'ban')}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="封禁账户"
                        >
                          <Ban size={16} className="text-red-500" />
                        </button>
                      )}
                      <button 
                        onClick={() => setShowUserDetail(user)}
                        className="p-1 rounded-lg hover:bg-muted transition-colors"
                        title="查看详情"
                      >
                        <FileText size={16} className="text-primary" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {filteredUsers.length === 0 && (
          <div className="text-center py-12">
            <Users size={48} className="mx-auto text-muted-foreground mb-4" />
            <h3 className="text-lg font-medium text-foreground mb-2">没有找到用户</h3>
            <p className="text-muted-foreground">请尝试调整搜索条件或添加新用户</p>
          </div>
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mt-3">
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-foreground">{users.length}</div>
          <div className="text-sm text-muted-foreground">总用户数</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-success">
            {users.filter(u => u.account_status === 'active').length}
          </div>
          <div className="text-sm text-muted-foreground">活跃用户</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-primary">
            {users.filter(u => u.is_member).length}
          </div>
          <div className="text-sm text-muted-foreground">会员用户</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-warning">
            {users.filter(u => u.account_status === 'inactive').length}
          </div>
          <div className="text-sm text-muted-foreground">非活跃用户</div>
        </div>
      </div>

      {/* Add User Modal */}
      <AddUserModal
        isOpen={showAddUserModal}
        onClose={() => setShowAddUserModal(false)}
        onUserAdded={handleUserAdded}
      />

      {/* Loading overlay */}
      {loading && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-40">
          <div className="bg-card rounded-lg p-6 flex items-center space-x-3">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            <span className="text-foreground">加载中...</span>
          </div>
        </div>
      )}
    </div>
  )
}