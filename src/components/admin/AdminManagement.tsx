import React, { useState, useEffect } from 'react'
import { 
  Users as UsersIcon, 
  UserPlus, 
  Edit, 
  Trash2, 
  Shield, 
  Eye,
  CheckCircle,
  XCircle,
  Search,
  Filter
} from 'lucide-react'
import { adminService } from '../../services/adminService'
import { AdminUser, AdminRole, ADMIN_ROLES } from '../../types/admin'
import { Badge } from '../ui/Badge'

interface AdminManagementProps {
  onClose?: () => void
}

export const AdminManagement: React.FC<AdminManagementProps> = ({ onClose }) => {
  const [adminUsers, setAdminUsers] = useState<AdminUser[]>([])
  const [adminRoles, setAdminRoles] = useState<AdminRole[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [roleFilter, setRoleFilter] = useState<string>('')
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [editingAdmin, setEditingAdmin] = useState<AdminUser | null>(null)

  useEffect(() => {
    loadAdminData()
  }, [])

  const loadAdminData = async () => {
    setLoading(true)
    try {
      const [usersResult, rolesResult] = await Promise.all([
        adminService.getAdminUsers(),
        adminService.getAdminRoles()
      ])

      if (usersResult.data) {
        setAdminUsers(usersResult.data)
      }

      if (rolesResult.data) {
        setAdminRoles(rolesResult.data)
      }
    } catch (error) {
      console.error('Error loading admin data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateAdmin = async (adminData: {
    email: string
    name: string
    role: string
  }) => {
    const result = await adminService.createAdminUser(adminData)
    if (result.data) {
      setAdminUsers(prev => [result.data!, ...prev])
      setShowCreateModal(false)
    }
  }

  const handleUpdateAdmin = async (adminId: string, updates: Partial<AdminUser>) => {
    const result = await adminService.updateAdminUser(adminId, updates)
    if (result.data) {
      setAdminUsers(prev => prev.map(admin => 
        admin.id === adminId ? result.data! : admin
      ))
      setEditingAdmin(null)
    }
  }

  const handleDeleteAdmin = async (adminId: string) => {
    if (window.confirm('确定要删除这个管理员吗？')) {
      const result = await adminService.deleteAdminUser(adminId)
      if (!result.error) {
        setAdminUsers(prev => prev.filter(admin => admin.id !== adminId))
      }
    }
  }

  const filteredAdmins = adminUsers.filter(admin => {
    const matchesSearch = admin.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         admin.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesRole = !roleFilter || admin.role === roleFilter
    return matchesSearch && matchesRole
  })

  const getRoleBadgeColor = (role: string) => {
    switch (role) {
      case ADMIN_ROLES.SUPER_ADMIN: return 'bg-red-500'
      case ADMIN_ROLES.OPERATOR: return 'bg-blue-500'
      case ADMIN_ROLES.MODERATOR: return 'bg-green-500'
      case ADMIN_ROLES.TECHNICAL: return 'bg-purple-500'
      default: return 'bg-gray-500'
    }
  }

  const getRoleDisplayName = (role: string) => {
    switch (role) {
      case ADMIN_ROLES.SUPER_ADMIN: return '超级管理员'
      case ADMIN_ROLES.OPERATOR: return '运营经理'
      case ADMIN_ROLES.MODERATOR: return '内容审核员'
      case ADMIN_ROLES.TECHNICAL: return '技术运维'
      default: return role
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500 dark:text-gray-400">加载中...</div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和操作栏 */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <Shield className="text-primary-500" size={24} />
          <div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">管理员管理</h2>
            <p className="text-gray-600 dark:text-gray-400">管理系统管理员账号和权限</p>
          </div>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-primary-500 hover:bg-primary-600 text-white rounded-lg transition-colors"
        >
          <UserPlus size={18} />
          <span>添加管理员</span>
        </button>
      </div>

      {/* 搜索和筛选栏 */}
      <div className="flex items-center space-x-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
          <input
            type="text"
            placeholder="搜索管理员姓名或邮箱..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          />
        </div>
        <div className="relative">
          <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="pl-10 pr-8 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            <option value="">所有角色</option>
            {Object.values(ADMIN_ROLES).map(role => (
              <option key={role} value={role}>{getRoleDisplayName(role)}</option>
            ))}
          </select>
        </div>
      </div>

      {/* 统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">总管理员</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{adminUsers.length}</p>
            </div>
            <UsersIcon className="text-primary-500" size={24} />
          </div>
        </div>
        
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">活跃账号</p>
              <p className="text-2xl font-bold text-green-600">{adminUsers.filter(a => a.is_active).length}</p>
            </div>
            <CheckCircle className="text-green-500" size={24} />
          </div>
        </div>
        
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">停用账号</p>
              <p className="text-2xl font-bold text-red-600">{adminUsers.filter(a => !a.is_active).length}</p>
            </div>
            <XCircle className="text-red-500" size={24} />
          </div>
        </div>
        
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 dark:text-gray-400 text-sm">超级管理员</p>
              <p className="text-2xl font-bold text-red-600">
                {adminUsers.filter(a => a.role === ADMIN_ROLES.SUPER_ADMIN).length}
              </p>
            </div>
            <Shield className="text-red-500" size={24} />
          </div>
        </div>
      </div>

      {/* 管理员列表 */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  管理员信息
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  角色
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  状态
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  最后登录
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  操作
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-600">
              {filteredAdmins.map((admin) => (
                <tr key={admin.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                  <td className="px-6 py-4">
                    <div>
                      <div className="text-sm font-medium text-gray-900 dark:text-white">
                        {admin.name}
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        {admin.email}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <Badge className={`text-white ${getRoleBadgeColor(admin.role)}`}>
                      {getRoleDisplayName(admin.role)}
                    </Badge>
                  </td>
                  <td className="px-6 py-4">
                    <Badge className={admin.is_active ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}>
                      {admin.is_active ? '活跃' : '停用'}
                    </Badge>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                    {admin.last_login_at ? 
                      new Date(admin.last_login_at).toLocaleString() : 
                      '从未登录'
                    }
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => setEditingAdmin(admin)}
                        className="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
                      >
                        <Edit size={16} />
                      </button>
                      <button
                        onClick={() => handleDeleteAdmin(admin.id)}
                        className="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 创建管理员模态框 */}
      {showCreateModal && (
        <CreateAdminModal 
          onClose={() => setShowCreateModal(false)}
          onSuccess={handleCreateAdmin}
        />
      )}

      {/* 编辑管理员模态框 */}
      {editingAdmin && (
        <EditAdminModal
          admin={editingAdmin}
          onClose={() => setEditingAdmin(null)}
          onSuccess={(updates) => handleUpdateAdmin(editingAdmin.id, updates)}
        />
      )}
    </div>
  )
}

// 创建管理员模态框组件
const CreateAdminModal: React.FC<{
  onClose: () => void
  onSuccess: (data: { email: string; name: string; role: string }) => void
}> = ({ onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    email: '',
    name: '',
    role: ADMIN_ROLES.MODERATOR
  })
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      await onSuccess(formData)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          创建管理员账号
        </h3>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              邮箱
            </label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              姓名
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              角色
            </label>
            <select
              value={formData.role}
              onChange={(e) => setFormData(prev => ({ ...prev, role: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            >
              {Object.values(ADMIN_ROLES).map(role => (
                <option key={role} value={role}>
                  {role === ADMIN_ROLES.SUPER_ADMIN && '超级管理员'}
                  {role === ADMIN_ROLES.OPERATOR && '运营经理'} 
                  {role === ADMIN_ROLES.MODERATOR && '内容审核员'}
                  {role === ADMIN_ROLES.TECHNICAL && '技术运维'}
                </option>
              ))}
            </select>
          </div>
          <div className="flex items-center justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
            >
              取消
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-6 py-2 bg-primary-500 hover:bg-primary-600 disabled:bg-primary-500/50 text-white rounded-lg"
            >
              {loading ? '创建中...' : '创建'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// 编辑管理员模态框组件
const EditAdminModal: React.FC<{
  admin: AdminUser
  onClose: () => void
  onSuccess: (updates: Partial<AdminUser>) => void
}> = ({ admin, onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    name: admin.name,
    role: admin.role,
    is_active: admin.is_active
  })
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      await onSuccess(formData)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          编辑管理员
        </h3>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              姓名
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              角色
            </label>
            <select
              value={formData.role}
              onChange={(e) => setFormData(prev => ({ ...prev, role: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            >
              {Object.values(ADMIN_ROLES).map(role => (
                <option key={role} value={role}>
                  {role === ADMIN_ROLES.SUPER_ADMIN && '超级管理员'}
                  {role === ADMIN_ROLES.OPERATOR && '运营经理'} 
                  {role === ADMIN_ROLES.MODERATOR && '内容审核员'}
                  {role === ADMIN_ROLES.TECHNICAL && '技术运维'}
                </option>
              ))}
            </select>
          </div>
          <div className="flex items-center">
            <input
              type="checkbox"
              id="is_active"
              checked={formData.is_active}
              onChange={(e) => setFormData(prev => ({ ...prev, is_active: e.target.checked }))}
              className="mr-2"
            />
            <label htmlFor="is_active" className="text-sm text-gray-700 dark:text-gray-300">
              账号激活状态
            </label>
          </div>
          <div className="flex items-center justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
            >
              取消
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-6 py-2 bg-primary-500 hover:bg-primary-600 disabled:bg-primary-500/50 text-white rounded-lg"
            >
              {loading ? '保存中...' : '保存'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}