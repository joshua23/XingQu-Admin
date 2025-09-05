/**
 * 星趣后台管理系统 - 增强用户管理组件
 * 提供高级用户管理、批量操作和数据分析功能
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Checkbox } from '@/components/ui/checkbox'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Separator } from '@/components/ui/separator'
import { useUserManagement } from '@/lib/hooks/useUserManagement'
import {
  Search,
  Filter,
  Download,
  Edit,
  Trash2,
  Ban,
  Shield,
  Tag,
  RefreshCw,
  MoreHorizontal,
  Users,
  TrendingUp,
  Eye,
  Mail,
  Calendar,
  MapPin,
  Crown,
  AlertTriangle,
  CheckCircle,
  Clock,
  Settings
} from 'lucide-react'
import type { UserProfile, UserFilters } from '@/lib/services/userService'

interface EnhancedUserManagerProps {
  showStatistics?: boolean
  enableBatchOperations?: boolean
  enableExport?: boolean
}

export default function EnhancedUserManager({
  showStatistics = true,
  enableBatchOperations = true,
  enableExport = true
}: EnhancedUserManagerProps) {
  // Hooks
  const {
    users,
    selectedUsers,
    totalUsers,
    totalPages,
    currentPage,
    statistics,
    loading,
    error,
    batchOperations,
    isProcessingBatch,
    loadUsers,
    searchUsers,
    loadStatistics,
    selectAllUsers,
    clearSelection,
    toggleUserSelection,
    batchUpdate,
    batchDelete,
    exportUsers,
    banUser,
    unbanUser,
    updateUserTags,
    resetUserPassword,
    refreshData,
    clearError
  } = useUserManagement()

  // 本地状态
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<UserProfile[]>([])
  const [showSearch, setShowSearch] = useState(false)
  const [filters, setFilters] = useState<UserFilters>({})
  const [showFilters, setShowFilters] = useState(false)
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null)
  const [showUserDetails, setShowUserDetails] = useState(false)
  const [showBatchActions, setShowBatchActions] = useState(false)
  const [pageSize, setPageSize] = useState(50)

  // 初始化数据
  useEffect(() => {
    loadUsers({}, 1, pageSize)
    if (showStatistics) {
      loadStatistics()
    }
  }, [loadUsers, loadStatistics, showStatistics, pageSize])

  // 搜索处理
  const handleSearch = useCallback(async (query: string) => {
    if (query.length < 2) {
      setSearchResults([])
      return
    }

    try {
      const results = await searchUsers(query)
      setSearchResults(results)
    } catch (error) {
      console.error('搜索失败:', error)
    }
  }, [searchUsers])

  // 筛选处理
  const handleFilterChange = useCallback((newFilters: UserFilters) => {
    setFilters(newFilters)
    loadUsers(newFilters, 1, pageSize)
  }, [loadUsers, pageSize])

  // 导出处理
  const handleExport = useCallback(async () => {
    try {
      const csvData = await exportUsers(filters)
      const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      link.href = URL.createObjectURL(blob)
      link.download = `users_export_${new Date().toISOString().split('T')[0]}.csv`
      link.click()
    } catch (error) {
      console.error('导出失败:', error)
    }
  }, [exportUsers, filters])

  // 获取订阅状态徽章
  const getSubscriptionBadge = (status: string) => {
    const variants = {
      free: { variant: 'secondary' as const, label: '免费' },
      basic: { variant: 'default' as const, label: '基础' },
      premium: { variant: 'default' as const, label: '高级' },
      lifetime: { variant: 'default' as const, label: '终身' }
    }
    const config = variants[status as keyof typeof variants] || variants.free
    return <Badge variant={config.variant} className="text-xs">{config.label}</Badge>
  }

  // 获取用户状态图标
  const getUserStatusIcon = (user: UserProfile) => {
    if (user.banned_until && new Date(user.banned_until) > new Date()) {
      return <Ban className="h-4 w-4 text-red-500" title="已封禁" />
    }
    if (!user.is_active) {
      return <AlertTriangle className="h-4 w-4 text-yellow-500" title="未激活" />
    }
    if (user.verification_status === 'verified') {
      return <CheckCircle className="h-4 w-4 text-green-500" title="已验证" />
    }
    return <Clock className="h-4 w-4 text-gray-500" title="待验证" />
  }

  // 渲染统计卡片
  const renderStatistics = () => {
    if (!showStatistics || !statistics) return null

    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">总用户数</p>
                <p className="text-2xl font-bold">{statistics.totalUsers.toLocaleString()}</p>
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
                <p className="text-2xl font-bold">{statistics.activeUsers.toLocaleString()}</p>
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
                <p className="text-2xl font-bold">{statistics.newUsersToday}</p>
              </div>
              <Calendar className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">付费用户</p>
                <p className="text-2xl font-bold">
                  {(statistics.subscriptionStats.basic + 
                    statistics.subscriptionStats.premium + 
                    statistics.subscriptionStats.lifetime).toLocaleString()}
                </p>
              </div>
              <Crown className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  // 渲染筛选器
  const renderFilters = () => (
    <Card className="mb-4">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Filter className="h-5 w-5" />
          筛选条件
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
          <Select
            value={filters.subscriptionStatus?.[0] || 'all'}
            onValueChange={(value) => 
              handleFilterChange({
                ...filters,
                subscriptionStatus: value === 'all' ? undefined : [value]
              })
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="订阅状态" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有状态</SelectItem>
              <SelectItem value="free">免费用户</SelectItem>
              <SelectItem value="basic">基础会员</SelectItem>
              <SelectItem value="premium">高级会员</SelectItem>
              <SelectItem value="lifetime">终身会员</SelectItem>
            </SelectContent>
          </Select>

          <Select
            value={filters.verificationStatus?.[0] || 'all'}
            onValueChange={(value) =>
              handleFilterChange({
                ...filters,
                verificationStatus: value === 'all' ? undefined : [value]
              })
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="验证状态" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有状态</SelectItem>
              <SelectItem value="verified">已验证</SelectItem>
              <SelectItem value="pending">待验证</SelectItem>
              <SelectItem value="rejected">已拒绝</SelectItem>
            </SelectContent>
          </Select>

          <Select
            value={filters.isActive === undefined ? 'all' : filters.isActive.toString()}
            onValueChange={(value) =>
              handleFilterChange({
                ...filters,
                isActive: value === 'all' ? undefined : value === 'true'
              })
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="活跃状态" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有状态</SelectItem>
              <SelectItem value="true">活跃</SelectItem>
              <SelectItem value="false">非活跃</SelectItem>
            </SelectContent>
          </Select>

          <Button
            variant="outline"
            onClick={() => {
              setFilters({})
              loadUsers({}, 1, pageSize)
            }}
          >
            重置筛选
          </Button>
        </div>
      </CardContent>
    </Card>
  )

  // 渲染用户表格
  const renderUserTable = () => (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>用户列表</CardTitle>
            <CardDescription>
              共 {totalUsers} 个用户，当前第 {currentPage} 页，共 {totalPages} 页
            </CardDescription>
          </div>
          <div className="flex items-center gap-2">
            {enableBatchOperations && selectedUsers.length > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowBatchActions(true)}
                disabled={isProcessingBatch}
              >
                批量操作 ({selectedUsers.length})
              </Button>
            )}
            {enableExport && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleExport}
                disabled={loading}
              >
                <Download className="h-4 w-4 mr-2" />
                导出
              </Button>
            )}
            <Button
              variant="outline"
              size="sm"
              onClick={refreshData}
              disabled={loading}
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              刷新
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b">
                {enableBatchOperations && (
                  <th className="text-left p-2">
                    <Checkbox
                      checked={selectedUsers.length === users.length && users.length > 0}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          selectAllUsers()
                        } else {
                          clearSelection()
                        }
                      }}
                    />
                  </th>
                )}
                <th className="text-left p-2">用户</th>
                <th className="text-left p-2">订阅</th>
                <th className="text-left p-2">状态</th>
                <th className="text-left p-2">注册时间</th>
                <th className="text-left p-2">最后活跃</th>
                <th className="text-left p-2">操作</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id} className="border-b hover:bg-muted/50">
                  {enableBatchOperations && (
                    <td className="p-2">
                      <Checkbox
                        checked={selectedUsers.some(u => u.id === user.id)}
                        onCheckedChange={() => toggleUserSelection(user)}
                      />
                    </td>
                  )}
                  <td className="p-2">
                    <div className="flex items-center gap-3">
                      {user.avatar_url ? (
                        <img
                          src={user.avatar_url}
                          alt={user.username || user.email}
                          className="w-8 h-8 rounded-full"
                        />
                      ) : (
                        <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                          <span className="text-sm font-medium">
                            {(user.full_name || user.email)[0].toUpperCase()}
                          </span>
                        </div>
                      )}
                      <div>
                        <p className="font-medium">
                          {user.full_name || user.username || '未设置'}
                        </p>
                        <p className="text-sm text-muted-foreground">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="p-2">
                    {getSubscriptionBadge(user.subscription_status)}
                  </td>
                  <td className="p-2">
                    <div className="flex items-center gap-2">
                      {getUserStatusIcon(user)}
                      <span className="text-sm">
                        {user.verification_status === 'verified' ? '已验证' : '待验证'}
                      </span>
                    </div>
                  </td>
                  <td className="p-2">
                    <span className="text-sm">
                      {new Date(user.created_at).toLocaleDateString()}
                    </span>
                  </td>
                  <td className="p-2">
                    <span className="text-sm">
                      {user.last_seen_at 
                        ? new Date(user.last_seen_at).toLocaleDateString()
                        : '从未活跃'}
                    </span>
                  </td>
                  <td className="p-2">
                    <div className="flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedUser(user)
                          setShowUserDetails(true)
                        }}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => resetUserPassword(user.email)}
                      >
                        <Mail className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          if (user.banned_until && new Date(user.banned_until) > new Date()) {
                            unbanUser(user.id)
                          } else {
                            // 这里应该打开封禁对话框
                            banUser(user.id, '违规行为', 30)
                          }
                        }}
                      >
                        {user.banned_until && new Date(user.banned_until) > new Date() ? (
                          <Shield className="h-4 w-4 text-green-500" />
                        ) : (
                          <Ban className="h-4 w-4 text-red-500" />
                        )}
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* 分页控件 */}
        <div className="flex items-center justify-between mt-4">
          <div className="text-sm text-muted-foreground">
            显示 {(currentPage - 1) * pageSize + 1} - {Math.min(currentPage * pageSize, totalUsers)} 
            条，共 {totalUsers} 条
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={currentPage <= 1 || loading}
              onClick={() => loadUsers(filters, currentPage - 1, pageSize)}
            >
              上一页
            </Button>
            <span className="text-sm">
              第 {currentPage} / {totalPages} 页
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={currentPage >= totalPages || loading}
              onClick={() => loadUsers(filters, currentPage + 1, pageSize)}
            >
              下一页
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )

  return (
    <div className="space-y-6">
      {/* 错误提示 */}
      {error && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {/* 搜索和筛选控制 */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="搜索用户..."
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value)
              handleSearch(e.target.value)
            }}
            className="pl-10"
          />
        </div>
        <Button
          variant="outline"
          onClick={() => setShowFilters(!showFilters)}
        >
          <Filter className="h-4 w-4 mr-2" />
          筛选
        </Button>
      </div>

      {/* 统计卡片 */}
      {renderStatistics()}

      {/* 筛选器 */}
      {showFilters && renderFilters()}

      {/* 用户表格 */}
      {renderUserTable()}

      {/* 用户详情对话框 */}
      <Dialog open={showUserDetails} onOpenChange={setShowUserDetails}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>用户详情</DialogTitle>
            <DialogDescription>
              查看和管理用户信息
            </DialogDescription>
          </DialogHeader>
          {selectedUser && (
            <div className="space-y-4">
              <div className="flex items-center gap-4">
                {selectedUser.avatar_url ? (
                  <img
                    src={selectedUser.avatar_url}
                    alt={selectedUser.username || selectedUser.email}
                    className="w-16 h-16 rounded-full"
                  />
                ) : (
                  <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center">
                    <span className="text-xl font-medium">
                      {(selectedUser.full_name || selectedUser.email)[0].toUpperCase()}
                    </span>
                  </div>
                )}
                <div>
                  <h3 className="text-lg font-semibold">
                    {selectedUser.full_name || selectedUser.username || '未设置姓名'}
                  </h3>
                  <p className="text-muted-foreground">{selectedUser.email}</p>
                  <div className="flex items-center gap-2 mt-1">
                    {getSubscriptionBadge(selectedUser.subscription_status)}
                    {getUserStatusIcon(selectedUser)}
                  </div>
                </div>
              </div>
              
              <Separator />
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">注册时间</label>
                  <p className="text-sm text-muted-foreground">
                    {new Date(selectedUser.created_at).toLocaleString()}
                  </p>
                </div>
                <div>
                  <label className="text-sm font-medium">最后活跃</label>
                  <p className="text-sm text-muted-foreground">
                    {selectedUser.last_seen_at 
                      ? new Date(selectedUser.last_seen_at).toLocaleString()
                      : '从未活跃'}
                  </p>
                </div>
                <div>
                  <label className="text-sm font-medium">对话次数</label>
                  <p className="text-sm text-muted-foreground">
                    {selectedUser.total_conversations}
                  </p>
                </div>
                <div>
                  <label className="text-sm font-medium">Token使用量</label>
                  <p className="text-sm text-muted-foreground">
                    {selectedUser.total_tokens_used.toLocaleString()}
                  </p>
                </div>
              </div>

              {selectedUser.tags.length > 0 && (
                <div>
                  <label className="text-sm font-medium">用户标签</label>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {selectedUser.tags.map((tag) => (
                      <Badge key={tag} variant="outline" className="text-xs">
                        {tag}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}