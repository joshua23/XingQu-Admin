/**
 * 星趣后台管理系统 - 角色权限管理组件
 * 提供灵活的权限管理功能
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
import { Checkbox } from '@/components/ui/checkbox'
import { Switch } from '@/components/ui/switch'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Plus,
  Edit,
  Trash2,
  Shield,
  Users,
  Key,
  Crown,
  Settings,
  Eye,
  Check,
  X,
  Copy,
  AlertTriangle,
  CheckCircle,
  Search,
  Filter
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

// 类型定义
interface Permission {
  id: string
  name: string
  code: string
  category: string
  description: string
  isSystem: boolean
}

interface Role {
  id: string
  name: string
  code: string
  description: string
  level: number
  isSystem: boolean
  isActive: boolean
  permissions: string[]
  userCount: number
  parentRoleId?: string
  createdAt: string
  updatedAt: string
}

interface RoleUser {
  id: string
  userId: string
  userName: string
  userEmail: string
  roleId: string
  roleName: string
  assignedAt: string
  assignedBy: string
  isActive: boolean
}

interface PermissionCategory {
  id: string
  name: string
  description: string
  permissions: Permission[]
}

export default function PermissionManager() {
  const [roles, setRoles] = useState<Role[]>([])
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [permissionCategories, setPermissionCategories] = useState<PermissionCategory[]>([])
  const [roleUsers, setRoleUsers] = useState<RoleUser[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedRole, setSelectedRole] = useState<Role | null>(null)
  const [isRoleDialogOpen, setIsRoleDialogOpen] = useState(false)
  const [isPermissionDialogOpen, setIsPermissionDialogOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterCategory, setFilterCategory] = useState<string>('all')

  // 表单状态
  const [roleForm, setRoleForm] = useState({
    name: '',
    code: '',
    description: '',
    level: 1,
    isActive: true,
    parentRoleId: '',
    permissions: [] as string[]
  })

  useEffect(() => {
    fetchRoles()
    fetchPermissions()
    fetchRoleUsers()
  }, [])

  const fetchRoles = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const mockRoles: Role[] = [
        {
          id: '1',
          name: '超级管理员',
          code: 'super_admin',
          description: '拥有系统全部权限的最高管理员',
          level: 1,
          isSystem: true,
          isActive: true,
          permissions: ['*'],
          userCount: 2,
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        },
        {
          id: '2',
          name: '系统管理员',
          code: 'system_admin',
          description: '负责系统配置和用户管理',
          level: 2,
          isSystem: false,
          isActive: true,
          permissions: ['user.view', 'user.create', 'user.edit', 'system.config', 'analytics.view'],
          userCount: 5,
          parentRoleId: '1',
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        },
        {
          id: '3',
          name: '内容管理员',
          code: 'content_admin',
          description: '负责内容审核和管理',
          level: 3,
          isSystem: false,
          isActive: true,
          permissions: ['content.view', 'content.edit', 'content.moderate', 'moderation.view'],
          userCount: 12,
          parentRoleId: '2',
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        },
        {
          id: '4',
          name: '客服专员',
          code: 'customer_service',
          description: '处理用户反馈和客服事务',
          level: 4,
          isSystem: false,
          isActive: true,
          permissions: ['user.view', 'support.view', 'support.reply'],
          userCount: 8,
          parentRoleId: '3',
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        },
        {
          id: '5',
          name: '数据分析师',
          code: 'data_analyst',
          description: '查看和分析系统数据',
          level: 4,
          isSystem: false,
          isActive: true,
          permissions: ['analytics.view', 'analytics.export', 'dashboard.view'],
          userCount: 3,
          parentRoleId: '2',
          createdAt: '2025-01-01',
          updatedAt: '2025-09-05'
        }
      ]
      
      setRoles(mockRoles)
    } catch (error) {
      console.error('获取角色数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchPermissions = async () => {
    try {
      const mockPermissions: Permission[] = [
        // 用户管理权限
        { id: '1', name: '查看用户', code: 'user.view', category: 'user', description: '查看用户列表和详情', isSystem: true },
        { id: '2', name: '创建用户', code: 'user.create', category: 'user', description: '创建新用户账户', isSystem: true },
        { id: '3', name: '编辑用户', code: 'user.edit', category: 'user', description: '编辑用户信息', isSystem: true },
        { id: '4', name: '删除用户', code: 'user.delete', category: 'user', description: '删除用户账户', isSystem: true },
        { id: '5', name: '用户权限管理', code: 'user.permission', category: 'user', description: '管理用户角色和权限', isSystem: true },
        
        // 内容管理权限
        { id: '6', name: '查看内容', code: 'content.view', category: 'content', description: '查看所有内容', isSystem: true },
        { id: '7', name: '编辑内容', code: 'content.edit', category: 'content', description: '编辑和修改内容', isSystem: true },
        { id: '8', name: '删除内容', code: 'content.delete', category: 'content', description: '删除内容', isSystem: true },
        { id: '9', name: '内容审核', code: 'content.moderate', category: 'content', description: '审核和处理举报内容', isSystem: true },
        
        // 系统管理权限
        { id: '10', name: '系统配置', code: 'system.config', category: 'system', description: '修改系统配置', isSystem: true },
        { id: '11', name: '查看日志', code: 'system.logs', category: 'system', description: '查看系统操作日志', isSystem: true },
        { id: '12', name: '数据备份', code: 'system.backup', category: 'system', description: '执行数据备份操作', isSystem: true },
        
        // 数据分析权限
        { id: '13', name: '查看分析', code: 'analytics.view', category: 'analytics', description: '查看数据分析报表', isSystem: true },
        { id: '14', name: '导出数据', code: 'analytics.export', category: 'analytics', description: '导出分析数据', isSystem: true },
        { id: '15', name: '查看仪表板', code: 'dashboard.view', category: 'dashboard', description: '查看管理仪表板', isSystem: true },
        
        // 审核管理权限
        { id: '16', name: '查看审核', code: 'moderation.view', category: 'moderation', description: '查看审核队列', isSystem: true },
        { id: '17', name: '处理审核', code: 'moderation.handle', category: 'moderation', description: '处理审核请求', isSystem: true },
        
        // 客服支持权限
        { id: '18', name: '查看工单', code: 'support.view', category: 'support', description: '查看客服工单', isSystem: true },
        { id: '19', name: '回复工单', code: 'support.reply', category: 'support', description: '回复客服工单', isSystem: true },
        
        // 商业化权限
        { id: '20', name: '查看订单', code: 'commerce.orders', category: 'commerce', description: '查看订单数据', isSystem: true },
        { id: '21', name: '管理订阅', code: 'commerce.subscriptions', category: 'commerce', description: '管理用户订阅', isSystem: true },
        
        // AI服务权限
        { id: '22', name: 'AI服务监控', code: 'ai.monitor', category: 'ai', description: '监控AI服务状态', isSystem: true },
        { id: '23', name: 'AI成本管理', code: 'ai.cost', category: 'ai', description: '管理AI服务成本', isSystem: true }
      ]
      
      setPermissions(mockPermissions)
      
      // 按类别分组权限
      const categories = mockPermissions.reduce((acc, permission) => {
        const existingCategory = acc.find(cat => cat.id === permission.category)
        if (existingCategory) {
          existingCategory.permissions.push(permission)
        } else {
          acc.push({
            id: permission.category,
            name: getCategoryName(permission.category),
            description: getCategoryDescription(permission.category),
            permissions: [permission]
          })
        }
        return acc
      }, [] as PermissionCategory[])
      
      setPermissionCategories(categories)
    } catch (error) {
      console.error('获取权限数据失败:', error)
    }
  }

  const fetchRoleUsers = async () => {
    try {
      const mockRoleUsers: RoleUser[] = [
        {
          id: '1',
          userId: 'user1',
          userName: '张三',
          userEmail: 'zhangsan@example.com',
          roleId: '1',
          roleName: '超级管理员',
          assignedAt: '2025-01-01',
          assignedBy: 'system',
          isActive: true
        },
        {
          id: '2',
          userId: 'user2',
          userName: '李四',
          userEmail: 'lisi@example.com',
          roleId: '2',
          roleName: '系统管理员',
          assignedAt: '2025-01-15',
          assignedBy: 'admin',
          isActive: true
        },
        {
          id: '3',
          userId: 'user3',
          userName: '王五',
          userEmail: 'wangwu@example.com',
          roleId: '3',
          roleName: '内容管理员',
          assignedAt: '2025-02-01',
          assignedBy: 'admin',
          isActive: true
        }
      ]
      
      setRoleUsers(mockRoleUsers)
    } catch (error) {
      console.error('获取角色用户数据失败:', error)
    }
  }

  const getCategoryName = (category: string) => {
    const names: Record<string, string> = {
      user: '用户管理',
      content: '内容管理',
      system: '系统管理',
      analytics: '数据分析',
      dashboard: '仪表板',
      moderation: '审核管理',
      support: '客服支持',
      commerce: '商业化',
      ai: 'AI服务'
    }
    return names[category] || category
  }

  const getCategoryDescription = (category: string) => {
    const descriptions: Record<string, string> = {
      user: '用户账户和权限相关功能',
      content: '内容创建、编辑和管理',
      system: '系统配置和维护功能',
      analytics: '数据统计和分析功能',
      dashboard: '管理面板访问权限',
      moderation: '内容审核和举报处理',
      support: '客服工单和用户支持',
      commerce: '订单、订阅和支付管理',
      ai: 'AI服务监控和管理'
    }
    return descriptions[category] || ''
  }

  const saveRole = async () => {
    try {
      if (selectedRole) {
        // 更新角色
        const updatedRoles = roles.map(role => 
          role.id === selectedRole.id 
            ? { ...selectedRole, ...roleForm, updatedAt: new Date().toISOString() }
            : role
        )
        setRoles(updatedRoles)
      } else {
        // 创建新角色
        const newRole: Role = {
          id: Date.now().toString(),
          ...roleForm,
          isSystem: false,
          userCount: 0,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
        setRoles([...roles, newRole])
      }
      
      resetRoleForm()
      setIsRoleDialogOpen(false)
    } catch (error) {
      console.error('保存角色失败:', error)
    }
  }

  const deleteRole = async (roleId: string) => {
    try {
      const role = roles.find(r => r.id === roleId)
      if (role?.isSystem) {
        alert('系统角色不能删除')
        return
      }
      
      setRoles(roles.filter(role => role.id !== roleId))
    } catch (error) {
      console.error('删除角色失败:', error)
    }
  }

  const resetRoleForm = () => {
    setRoleForm({
      name: '',
      code: '',
      description: '',
      level: 1,
      isActive: true,
      parentRoleId: '',
      permissions: []
    })
    setSelectedRole(null)
  }

  const editRole = (role: Role) => {
    setSelectedRole(role)
    setRoleForm({
      name: role.name,
      code: role.code,
      description: role.description,
      level: role.level,
      isActive: role.isActive,
      parentRoleId: role.parentRoleId || '',
      permissions: role.permissions
    })
    setIsRoleDialogOpen(true)
  }

  const togglePermission = (permissionCode: string) => {
    setRoleForm(prev => ({
      ...prev,
      permissions: prev.permissions.includes(permissionCode)
        ? prev.permissions.filter(p => p !== permissionCode)
        : [...prev.permissions, permissionCode]
    }))
  }

  const filteredRoles = useMemo(() => {
    return roles.filter(role => 
      searchTerm === '' || 
      role.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      role.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      role.description.toLowerCase().includes(searchTerm.toLowerCase())
    )
  }, [roles, searchTerm])

  const getLevelBadge = (level: number) => {
    const colors = [
      'bg-red-100 text-red-700 border-red-200',
      'bg-orange-100 text-orange-700 border-orange-200',
      'bg-yellow-100 text-yellow-700 border-yellow-200',
      'bg-blue-100 text-blue-700 border-blue-200',
      'bg-green-100 text-green-700 border-green-200'
    ]
    return (
      <Badge className={colors[Math.min(level - 1, colors.length - 1)] || 'bg-gray-100 text-gray-700'}>
        级别 {level}
      </Badge>
    )
  }

  const getStatusBadge = (isActive: boolean) => {
    return isActive ? (
      <Badge className="bg-green-100 text-green-700 border-green-200">启用</Badge>
    ) : (
      <Badge variant="outline" className="text-gray-600">禁用</Badge>
    )
  }

  const getRoleHierarchy = (roleId: string, visited = new Set()): Role[] => {
    if (visited.has(roleId)) return []
    visited.add(roleId)
    
    const role = roles.find(r => r.id === roleId)
    if (!role) return []
    
    const children = roles.filter(r => r.parentRoleId === roleId)
    const hierarchy = [role]
    
    children.forEach(child => {
      hierarchy.push(...getRoleHierarchy(child.id, visited))
    })
    
    return hierarchy
  }

  return (
    <div className="space-y-6">
      {/* 统计卡片 */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">总角色数</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{roles.length}</div>
            <p className="text-xs text-muted-foreground">
              系统角色: {roles.filter(r => r.isSystem).length}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">总用户数</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{roleUsers.length}</div>
            <p className="text-xs text-muted-foreground">
              活跃用户: {roleUsers.filter(u => u.isActive).length}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">权限总数</CardTitle>
            <Key className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{permissions.length}</div>
            <p className="text-xs text-muted-foreground">
              分类: {permissionCategories.length}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">活跃角色</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{roles.filter(r => r.isActive).length}</div>
            <p className="text-xs text-muted-foreground">
              使用率: {((roles.filter(r => r.isActive).length / roles.length) * 100).toFixed(1)}%
            </p>
          </CardContent>
        </Card>
      </div>

      {/* 主要内容 */}
      <Tabs defaultValue="roles" className="space-y-4">
        <TabsList>
          <TabsTrigger value="roles">角色管理</TabsTrigger>
          <TabsTrigger value="permissions">权限管理</TabsTrigger>
          <TabsTrigger value="users">用户分配</TabsTrigger>
          <TabsTrigger value="hierarchy">权限继承</TabsTrigger>
        </TabsList>

        {/* 角色管理 */}
        <TabsContent value="roles" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>角色管理</CardTitle>
                  <CardDescription>创建和管理系统角色</CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <div className="flex items-center space-x-2">
                    <Search className="w-4 h-4 text-muted-foreground" />
                    <Input
                      placeholder="搜索角色..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-64"
                    />
                  </div>
                  <Dialog open={isRoleDialogOpen} onOpenChange={setIsRoleDialogOpen}>
                    <DialogTrigger asChild>
                      <Button onClick={resetRoleForm}>
                        <Plus className="w-4 h-4 mr-2" />
                        新建角色
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="max-w-4xl">
                      <DialogHeader>
                        <DialogTitle>
                          {selectedRole ? '编辑角色' : '创建角色'}
                        </DialogTitle>
                        <DialogDescription>
                          配置角色的基本信息和权限设置
                        </DialogDescription>
                      </DialogHeader>
                      
                      <div className="grid gap-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <Label htmlFor="name">角色名称</Label>
                            <Input
                              id="name"
                              value={roleForm.name}
                              onChange={(e) => setRoleForm({...roleForm, name: e.target.value})}
                              placeholder="例如：内容管理员"
                            />
                          </div>
                          <div>
                            <Label htmlFor="code">角色代码</Label>
                            <Input
                              id="code"
                              value={roleForm.code}
                              onChange={(e) => setRoleForm({...roleForm, code: e.target.value})}
                              placeholder="例如：content_admin"
                            />
                          </div>
                        </div>
                        
                        <div>
                          <Label htmlFor="description">描述</Label>
                          <Textarea
                            id="description"
                            value={roleForm.description}
                            onChange={(e) => setRoleForm({...roleForm, description: e.target.value})}
                            placeholder="描述该角色的职责和权限范围"
                          />
                        </div>
                        
                        <div className="grid grid-cols-3 gap-4">
                          <div>
                            <Label htmlFor="level">角色级别</Label>
                            <Select value={roleForm.level.toString()} onValueChange={(value) => setRoleForm({...roleForm, level: parseInt(value)})}>
                              <SelectTrigger>
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="1">1级（最高）</SelectItem>
                                <SelectItem value="2">2级</SelectItem>
                                <SelectItem value="3">3级</SelectItem>
                                <SelectItem value="4">4级</SelectItem>
                                <SelectItem value="5">5级（最低）</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                          <div>
                            <Label htmlFor="parentRole">父级角色</Label>
                            <Select value={roleForm.parentRoleId} onValueChange={(value) => setRoleForm({...roleForm, parentRoleId: value})}>
                              <SelectTrigger>
                                <SelectValue placeholder="选择父级角色" />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="">无</SelectItem>
                                {roles.filter(r => r.id !== selectedRole?.id).map(role => (
                                  <SelectItem key={role.id} value={role.id}>
                                    {role.name}
                                  </SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          </div>
                          <div className="flex items-center space-x-2">
                            <Switch
                              id="isActive"
                              checked={roleForm.isActive}
                              onCheckedChange={(checked) => setRoleForm({...roleForm, isActive: checked})}
                            />
                            <Label htmlFor="isActive">启用角色</Label>
                          </div>
                        </div>

                        {/* 权限选择 */}
                        <div>
                          <Label>权限分配</Label>
                          <div className="mt-2 max-h-96 overflow-y-auto border rounded p-4">
                            {permissionCategories.map(category => (
                              <div key={category.id} className="mb-4">
                                <div className="flex items-center space-x-2 mb-2">
                                  <Checkbox
                                    id={`category-${category.id}`}
                                    checked={category.permissions.every(p => roleForm.permissions.includes(p.code))}
                                    onCheckedChange={(checked) => {
                                      if (checked) {
                                        setRoleForm(prev => ({
                                          ...prev,
                                          permissions: [...new Set([...prev.permissions, ...category.permissions.map(p => p.code)])]
                                        }))
                                      } else {
                                        setRoleForm(prev => ({
                                          ...prev,
                                          permissions: prev.permissions.filter(p => !category.permissions.map(cp => cp.code).includes(p))
                                        }))
                                      }
                                    }}
                                  />
                                  <Label htmlFor={`category-${category.id}`} className="font-medium">
                                    {category.name}
                                  </Label>
                                  <Badge variant="outline" className="text-xs">
                                    {category.permissions.length}
                                  </Badge>
                                </div>
                                <div className="grid grid-cols-2 gap-2 ml-6">
                                  {category.permissions.map(permission => (
                                    <div key={permission.id} className="flex items-center space-x-2">
                                      <Checkbox
                                        id={permission.code}
                                        checked={roleForm.permissions.includes(permission.code)}
                                        onCheckedChange={() => togglePermission(permission.code)}
                                      />
                                      <Label htmlFor={permission.code} className="text-sm">
                                        {permission.name}
                                      </Label>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>

                      <DialogFooter>
                        <Button variant="outline" onClick={() => setIsRoleDialogOpen(false)}>
                          取消
                        </Button>
                        <Button onClick={saveRole}>
                          {selectedRole ? '更新' : '创建'}
                        </Button>
                      </DialogFooter>
                    </DialogContent>
                  </Dialog>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>角色名称</TableHead>
                    <TableHead>角色代码</TableHead>
                    <TableHead>级别</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>用户数</TableHead>
                    <TableHead>权限数</TableHead>
                    <TableHead>创建时间</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredRoles.map((role) => (
                    <TableRow key={role.id}>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          {role.isSystem && <Crown className="w-4 h-4 text-yellow-600" />}
                          <div>
                            <div className="font-medium">{role.name}</div>
                            <div className="text-xs text-muted-foreground">{role.description}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="font-mono text-sm">{role.code}</TableCell>
                      <TableCell>{getLevelBadge(role.level)}</TableCell>
                      <TableCell>{getStatusBadge(role.isActive)}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{role.userCount}</Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{role.permissions.length}</Badge>
                      </TableCell>
                      <TableCell>{new Date(role.createdAt).toLocaleDateString()}</TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => editRole(role)}
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {/* 查看详情 */}}
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          {!role.isSystem && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => deleteRole(role.id)}
                            >
                              <Trash2 className="w-4 h-4 text-red-600" />
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

        {/* 权限管理 */}
        <TabsContent value="permissions" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>权限管理</CardTitle>
              <CardDescription>查看和管理系统权限</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                {permissionCategories.map(category => (
                  <Card key={category.id} className="border">
                    <CardHeader>
                      <div className="flex items-center justify-between">
                        <div>
                          <CardTitle className="text-base">{category.name}</CardTitle>
                          <CardDescription>{category.description}</CardDescription>
                        </div>
                        <Badge variant="outline">{category.permissions.length} 权限</Badge>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
                        {category.permissions.map(permission => (
                          <div key={permission.id} className="flex items-center justify-between p-3 border rounded">
                            <div>
                              <div className="font-medium text-sm">{permission.name}</div>
                              <div className="text-xs text-muted-foreground">{permission.code}</div>
                              <div className="text-xs text-muted-foreground">{permission.description}</div>
                            </div>
                            {permission.isSystem && (
                              <Badge variant="outline" className="text-xs">系统</Badge>
                            )}
                          </div>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 用户分配 */}
        <TabsContent value="users" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>用户角色分配</CardTitle>
              <CardDescription>管理用户的角色分配</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>用户名</TableHead>
                    <TableHead>邮箱</TableHead>
                    <TableHead>角色</TableHead>
                    <TableHead>分配时间</TableHead>
                    <TableHead>分配者</TableHead>
                    <TableHead>状态</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {roleUsers.map((roleUser) => (
                    <TableRow key={roleUser.id}>
                      <TableCell className="font-medium">{roleUser.userName}</TableCell>
                      <TableCell>{roleUser.userEmail}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{roleUser.roleName}</Badge>
                      </TableCell>
                      <TableCell>{new Date(roleUser.assignedAt).toLocaleDateString()}</TableCell>
                      <TableCell>{roleUser.assignedBy}</TableCell>
                      <TableCell>{getStatusBadge(roleUser.isActive)}</TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button variant="ghost" size="sm">
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button variant="ghost" size="sm">
                            <Trash2 className="w-4 h-4 text-red-600" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 权限继承 */}
        <TabsContent value="hierarchy" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>权限继承关系</CardTitle>
              <CardDescription>查看角色的层级关系和权限继承</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                <Settings className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <div>权限继承关系图</div>
                <div className="text-sm">显示角色间的层级关系和权限继承流向</div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}