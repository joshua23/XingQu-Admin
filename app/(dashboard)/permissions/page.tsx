'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Input } from '@/components/ui/Input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/Select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/Table'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/Dialog'
import { Textarea } from '@/components/ui/Textarea'
import { Label } from '@/components/ui/Label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { Switch } from '@/components/ui/Switch'
import { Checkbox } from '@/components/ui/Checkbox'
import { 
  Shield, ShieldCheck, ShieldAlert, Users, Key, Lock, 
  Plus, Edit, Trash2, Eye, Search, Filter, Settings, UserPlus 
} from 'lucide-react'
import { dataService } from '@/lib/services/supabase'

interface Role {
  id: string
  name: string
  display_name: string
  description: string
  permissions: string[]
  is_active: boolean
  created_at: string
  updated_at: string
}

interface Permission {
  id: string
  name: string
  display_name: string
  description: string
  module: string
  action: string
}

interface User {
  id: string
  user_id: string
  nickname: string
  email?: string
  roles: string[]
  is_active: boolean
  last_login?: string
}

export default function PermissionsManagementPage() {
  const [activeTab, setActiveTab] = useState('roles')
  const [roles, setRoles] = useState<Role[]>([])
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedRole, setSelectedRole] = useState<Role | null>(null)
  const [roleDialogOpen, setRoleDialogOpen] = useState(false)
  const [userRoleDialogOpen, setUserRoleDialogOpen] = useState(false)
  const [selectedUser, setSelectedUser] = useState<User | null>(null)

  // 模拟权限数据
  const mockPermissions: Permission[] = [
    { id: '1', name: 'users.view', display_name: '查看用户', description: '查看用户列表和详情', module: '用户管理', action: 'view' },
    { id: '2', name: 'users.edit', display_name: '编辑用户', description: '编辑用户信息', module: '用户管理', action: 'edit' },
    { id: '3', name: 'users.delete', display_name: '删除用户', description: '删除用户账号', module: '用户管理', action: 'delete' },
    { id: '4', name: 'content.view', display_name: '查看内容', description: '查看内容列表', module: '内容管理', action: 'view' },
    { id: '5', name: 'content.moderate', display_name: '内容审核', description: '审核用户内容', module: '内容管理', action: 'moderate' },
    { id: '6', name: 'analytics.view', display_name: '查看分析', description: '查看数据分析', module: '数据分析', action: 'view' },
    { id: '7', name: 'settings.manage', display_name: '系统设置', description: '管理系统设置', module: '系统管理', action: 'manage' },
    { id: '8', name: 'permissions.manage', display_name: '权限管理', description: '管理角色和权限', module: '系统管理', action: 'manage' }
  ]

  // 模拟角色数据
  const mockRoles: Role[] = [
    {
      id: '1',
      name: 'super_admin',
      display_name: '超级管理员',
      description: '拥有所有权限的超级管理员',
      permissions: mockPermissions.map(p => p.name),
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: '2',
      name: 'admin',
      display_name: '管理员',
      description: '普通管理员，拥有大部分管理权限',
      permissions: ['users.view', 'users.edit', 'content.view', 'content.moderate', 'analytics.view'],
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: '3',
      name: 'moderator',
      display_name: '审核员',
      description: '内容审核专员',
      permissions: ['content.view', 'content.moderate', 'users.view'],
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: '4',
      name: 'analyst',
      display_name: '数据分析师',
      description: '负责数据分析和报表',
      permissions: ['analytics.view', 'users.view', 'content.view'],
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  ]

  // 模拟用户数据
  const mockUsers: User[] = [
    {
      id: '1',
      user_id: 'admin1',
      nickname: '系统管理员',
      email: 'admin@xingqu.com',
      roles: ['super_admin'],
      is_active: true,
      last_login: new Date().toISOString()
    },
    {
      id: '2',
      user_id: 'admin2',
      nickname: '运营管理员',
      email: 'ops@xingqu.com',
      roles: ['admin'],
      is_active: true,
      last_login: new Date(Date.now() - 86400000).toISOString()
    },
    {
      id: '3',
      user_id: 'mod1',
      nickname: '内容审核员',
      email: 'moderator@xingqu.com',
      roles: ['moderator'],
      is_active: true,
      last_login: new Date(Date.now() - 3600000).toISOString()
    }
  ]

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      // 实际应用中应该从 Supabase 的 xq_roles, xq_permissions, xq_user_roles 表获取数据
      setRoles(mockRoles)
      setPermissions(mockPermissions)
      setUsers(mockUsers)
    } catch (error) {
      console.error('加载权限数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSaveRole = async (roleData: Partial<Role>) => {
    try {
      if (selectedRole) {
        // 更新角色
        setRoles(prev => prev.map(role => 
          role.id === selectedRole.id 
            ? { ...role, ...roleData, updated_at: new Date().toISOString() }
            : role
        ))
      } else {
        // 创建新角色
        const newRole: Role = {
          id: Date.now().toString(),
          name: roleData.name || '',
          display_name: roleData.display_name || '',
          description: roleData.description || '',
          permissions: roleData.permissions || [],
          is_active: roleData.is_active ?? true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
        setRoles(prev => [...prev, newRole])
      }
      setRoleDialogOpen(false)
      setSelectedRole(null)
    } catch (error) {
      console.error('保存角色失败:', error)
    }
  }

  const handleUpdateUserRoles = async (userId: string, newRoles: string[]) => {
    try {
      setUsers(prev => prev.map(user => 
        user.id === userId 
          ? { ...user, roles: newRoles }
          : user
      ))
      setUserRoleDialogOpen(false)
      setSelectedUser(null)
    } catch (error) {
      console.error('更新用户角色失败:', error)
    }
  }

  const filteredRoles = roles.filter(role => 
    role.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    role.description.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const filteredUsers = users.filter(user => 
    user.nickname.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email?.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const getPermissionsByModule = () => {
    const grouped = permissions.reduce((acc, permission) => {
      if (!acc[permission.module]) {
        acc[permission.module] = []
      }
      acc[permission.module].push(permission)
      return acc
    }, {} as Record<string, Permission[]>)
    return grouped
  }

  const stats = {
    totalRoles: roles.length,
    activeRoles: roles.filter(r => r.is_active).length,
    totalUsers: users.length,
    activeUsers: users.filter(u => u.is_active).length
  }

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">权限管理</h1>
          <p className="text-muted-foreground">
            管理系统角色、权限和用户访问控制
          </p>
        </div>

        {/* 统计卡片 */}
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">总角色数</CardTitle>
              <Shield className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalRoles}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">活跃角色</CardTitle>
              <ShieldCheck className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{stats.activeRoles}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">管理员用户</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalUsers}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">在线管理员</CardTitle>
              <Key className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">{stats.activeUsers}</div>
            </CardContent>
          </Card>
        </div>

        {/* 主要内容区域 */}
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="roles" className="flex items-center gap-2">
              <Shield className="w-4 h-4" />
              角色管理
            </TabsTrigger>
            <TabsTrigger value="permissions" className="flex items-center gap-2">
              <Key className="w-4 h-4" />
              权限列表
            </TabsTrigger>
            <TabsTrigger value="users" className="flex items-center gap-2">
              <Users className="w-4 h-4" />
              用户角色
            </TabsTrigger>
          </TabsList>

          {/* 角色管理 */}
          <TabsContent value="roles" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>角色管理</CardTitle>
                    <CardDescription>创建和管理系统角色</CardDescription>
                  </div>
                  <Dialog open={roleDialogOpen} onOpenChange={setRoleDialogOpen}>
                    <DialogTrigger asChild>
                      <Button onClick={() => setSelectedRole(null)}>
                        <Plus className="w-4 h-4 mr-2" />
                        添加角色
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="max-w-2xl">
                      <DialogHeader>
                        <DialogTitle>
                          {selectedRole ? '编辑角色' : '添加角色'}
                        </DialogTitle>
                        <DialogDescription>
                          配置角色信息和权限
                        </DialogDescription>
                      </DialogHeader>
                      <RoleEditForm 
                        role={selectedRole}
                        permissions={permissions}
                        onSave={handleSaveRole}
                        onCancel={() => {
                          setRoleDialogOpen(false)
                          setSelectedRole(null)
                        }}
                      />
                    </DialogContent>
                  </Dialog>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex gap-4">
                    <div className="relative flex-1">
                      <Search className="absolute left-2 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        placeholder="搜索角色..."
                        className="pl-8"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                      />
                    </div>
                  </div>
                  
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>角色名称</TableHead>
                        <TableHead>描述</TableHead>
                        <TableHead>权限数量</TableHead>
                        <TableHead>状态</TableHead>
                        <TableHead>创建时间</TableHead>
                        <TableHead>操作</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredRoles.map((role) => (
                        <TableRow key={role.id}>
                          <TableCell className="font-medium">{role.display_name}</TableCell>
                          <TableCell className="max-w-[200px] truncate">{role.description}</TableCell>
                          <TableCell>
                            <Badge variant="outline">{role.permissions.length} 个权限</Badge>
                          </TableCell>
                          <TableCell>
                            <Badge variant={role.is_active ? "outline" : "secondary"}>
                              {role.is_active ? '启用' : '禁用'}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            {new Date(role.created_at).toLocaleDateString('zh-CN')}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-2">
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => {
                                  setSelectedRole(role)
                                  setRoleDialogOpen(true)
                                }}
                              >
                                <Edit className="w-4 h-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* 权限列表 */}
          <TabsContent value="permissions" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>系统权限</CardTitle>
                <CardDescription>查看所有系统权限</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  {Object.entries(getPermissionsByModule()).map(([module, modulePermissions]) => (
                    <div key={module}>
                      <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                        <Lock className="w-5 h-5" />
                        {module}
                      </h3>
                      <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
                        {modulePermissions.map((permission) => (
                          <Card key={permission.id} className="p-4">
                            <div className="space-y-2">
                              <div className="flex items-center justify-between">
                                <h4 className="font-medium">{permission.display_name}</h4>
                                <Badge variant="outline" className="text-xs">
                                  {permission.action}
                                </Badge>
                              </div>
                              <p className="text-sm text-muted-foreground">
                                {permission.description}
                              </p>
                              <Badge variant="secondary" className="text-xs">
                                {permission.name}
                              </Badge>
                            </div>
                          </Card>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* 用户角色 */}
          <TabsContent value="users" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <div>
                    <CardTitle>用户角色分配</CardTitle>
                    <CardDescription>管理用户的角色权限</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex gap-4">
                    <div className="relative flex-1">
                      <Search className="absolute left-2 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        placeholder="搜索用户..."
                        className="pl-8"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                      />
                    </div>
                  </div>
                  
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>用户名</TableHead>
                        <TableHead>邮箱</TableHead>
                        <TableHead>角色</TableHead>
                        <TableHead>状态</TableHead>
                        <TableHead>最后登录</TableHead>
                        <TableHead>操作</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredUsers.map((user) => (
                        <TableRow key={user.id}>
                          <TableCell className="font-medium">{user.nickname}</TableCell>
                          <TableCell>{user.email}</TableCell>
                          <TableCell>
                            <div className="flex gap-1 flex-wrap">
                              {user.roles.map((roleId) => {
                                const role = roles.find(r => r.name === roleId)
                                return role ? (
                                  <Badge key={roleId} variant="outline" className="text-xs">
                                    {role.display_name}
                                  </Badge>
                                ) : null
                              })}
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge variant={user.is_active ? "outline" : "secondary"}>
                              {user.is_active ? '启用' : '禁用'}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            {user.last_login ? 
                              new Date(user.last_login).toLocaleDateString('zh-CN') : 
                              '从未登录'
                            }
                          </TableCell>
                          <TableCell>
                            <Dialog open={userRoleDialogOpen} onOpenChange={setUserRoleDialogOpen}>
                              <DialogTrigger asChild>
                                <Button 
                                  variant="outline" 
                                  size="sm"
                                  onClick={() => setSelectedUser(user)}
                                >
                                  <Settings className="w-4 h-4" />
                                </Button>
                              </DialogTrigger>
                              <DialogContent>
                                <DialogHeader>
                                  <DialogTitle>分配角色</DialogTitle>
                                  <DialogDescription>
                                    为用户 {selectedUser?.nickname} 分配角色
                                  </DialogDescription>
                                </DialogHeader>
                                {selectedUser && (
                                  <UserRoleEditForm 
                                    user={selectedUser}
                                    roles={roles}
                                    onSave={(newRoles) => handleUpdateUserRoles(selectedUser.id, newRoles)}
                                    onCancel={() => {
                                      setUserRoleDialogOpen(false)
                                      setSelectedUser(null)
                                    }}
                                  />
                                )}
                              </DialogContent>
                            </Dialog>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}

// 角色编辑表单组件
function RoleEditForm({ 
  role, 
  permissions, 
  onSave, 
  onCancel 
}: {
  role: Role | null
  permissions: Permission[]
  onSave: (roleData: Partial<Role>) => void
  onCancel: () => void
}) {
  const [formData, setFormData] = useState({
    name: role?.name || '',
    display_name: role?.display_name || '',
    description: role?.description || '',
    permissions: role?.permissions || [],
    is_active: role?.is_active ?? true
  })

  const handlePermissionChange = (permissionName: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      permissions: checked 
        ? [...prev.permissions, permissionName]
        : prev.permissions.filter(p => p !== permissionName)
    }))
  }

  const getPermissionsByModule = () => {
    return permissions.reduce((acc, permission) => {
      if (!acc[permission.module]) {
        acc[permission.module] = []
      }
      acc[permission.module].push(permission)
      return acc
    }, {} as Record<string, Permission[]>)
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label htmlFor="name">角色标识</Label>
          <Input
            id="name"
            value={formData.name}
            onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
            placeholder="role_name"
          />
        </div>
        <div>
          <Label htmlFor="display_name">显示名称</Label>
          <Input
            id="display_name"
            value={formData.display_name}
            onChange={(e) => setFormData(prev => ({ ...prev, display_name: e.target.value }))}
            placeholder="角色名称"
          />
        </div>
      </div>
      
      <div>
        <Label htmlFor="description">描述</Label>
        <Textarea
          id="description"
          value={formData.description}
          onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
          placeholder="角色描述"
        />
      </div>

      <div className="flex items-center space-x-2">
        <Switch
          id="is_active"
          checked={formData.is_active}
          onCheckedChange={(checked) => setFormData(prev => ({ ...prev, is_active: checked }))}
        />
        <Label htmlFor="is_active">启用角色</Label>
      </div>

      <div>
        <Label>权限配置</Label>
        <div className="max-h-96 overflow-y-auto border rounded-md p-4 mt-2">
          {Object.entries(getPermissionsByModule()).map(([module, modulePermissions]) => (
            <div key={module} className="mb-4">
              <h4 className="font-medium mb-2">{module}</h4>
              <div className="space-y-2">
                {modulePermissions.map((permission) => (
                  <div key={permission.id} className="flex items-center space-x-2">
                    <Checkbox
                      id={permission.name}
                      checked={formData.permissions.includes(permission.name)}
                      onCheckedChange={(checked) => 
                        handlePermissionChange(permission.name, checked as boolean)
                      }
                    />
                    <Label htmlFor={permission.name} className="flex-1">
                      <div>
                        <div className="font-medium text-sm">{permission.display_name}</div>
                        <div className="text-xs text-muted-foreground">{permission.description}</div>
                      </div>
                    </Label>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex gap-2 pt-4">
        <Button onClick={() => onSave(formData)} className="flex-1">
          保存角色
        </Button>
        <Button variant="outline" onClick={onCancel}>
          取消
        </Button>
      </div>
    </div>
  )
}

// 用户角色编辑表单组件
function UserRoleEditForm({ 
  user, 
  roles, 
  onSave, 
  onCancel 
}: {
  user: User
  roles: Role[]
  onSave: (roles: string[]) => void
  onCancel: () => void
}) {
  const [selectedRoles, setSelectedRoles] = useState<string[]>(user.roles)

  const handleRoleChange = (roleName: string, checked: boolean) => {
    setSelectedRoles(prev => 
      checked 
        ? [...prev, roleName]
        : prev.filter(r => r !== roleName)
    )
  }

  return (
    <div className="space-y-4">
      <div>
        <Label>选择角色</Label>
        <div className="space-y-2 mt-2">
          {roles.map((role) => (
            <div key={role.id} className="flex items-center space-x-2">
              <Checkbox
                id={role.name}
                checked={selectedRoles.includes(role.name)}
                onCheckedChange={(checked) => 
                  handleRoleChange(role.name, checked as boolean)
                }
              />
              <Label htmlFor={role.name} className="flex-1">
                <div>
                  <div className="font-medium">{role.display_name}</div>
                  <div className="text-sm text-muted-foreground">{role.description}</div>
                  <Badge variant="outline" className="text-xs mt-1">
                    {role.permissions.length} 个权限
                  </Badge>
                </div>
              </Label>
            </div>
          ))}
        </div>
      </div>

      <div className="flex gap-2 pt-4">
        <Button onClick={() => onSave(selectedRoles)} className="flex-1">
          保存
        </Button>
        <Button variant="outline" onClick={onCancel}>
          取消
        </Button>
      </div>
    </div>
  )
}