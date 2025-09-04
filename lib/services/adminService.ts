import { supabase } from './supabase'
import { AdminUser, AdminRole, AdminLog, AdminPermission, ADMIN_ROLES, DEFAULT_ROLE_PERMISSIONS } from '../types/admin'

export const adminService = {
  // 管理员用户管理
  async getAdminUsers(): Promise<{ data: AdminUser[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('admin_users')
        .select(`
          id,
          user_id,
          email,
          name,
          role,
          permissions,
          is_active,
          last_login_at,
          created_at,
          updated_at
        `)
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('Get admin users error:', error)
      return { data: null, error }
    }
  },

  async createAdminUser(adminData: {
    email: string
    name: string
    role: string
    permissions?: Record<string, boolean>
  }): Promise<{ data: AdminUser | null; error: any }> {
    try {
      // 创建Supabase Auth用户
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: adminData.email,
        password: this.generateRandomPassword(),
        email_confirm: true,
        user_metadata: {
          name: adminData.name
        }
      })

      if (authError) {
        return { data: null, error: authError }
      }

      // 获取角色默认权限
      const defaultPermissions = this.getRoleDefaultPermissions(adminData.role)
      const permissions = adminData.permissions || defaultPermissions

      // 创建管理员记录
      const { data, error } = await supabase
        .from('admin_users')
        .insert({
          user_id: authData.user.id,
          email: adminData.email,
          name: adminData.name,
          role: adminData.role,
          permissions,
          is_active: true
        })
        .select()
        .single()

      // 记录操作日志
      if (data) {
        await this.logAdminAction({
          action: 'create_admin',
          resource: 'admin_users',
          resource_id: data.id,
          details: { email: adminData.email, name: adminData.name, role: adminData.role }
        })
      }

      return { data, error }
    } catch (error) {
      console.error('Create admin user error:', error)
      return { data: null, error }
    }
  },

  async updateAdminUser(adminId: string, updates: Partial<AdminUser>): Promise<{ data: AdminUser | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('admin_users')
        .update(updates)
        .eq('id', adminId)
        .select()
        .single()

      // 记录操作日志
      if (data) {
        await this.logAdminAction({
          action: 'update_admin',
          resource: 'admin_users',
          resource_id: adminId,
          details: updates
        })
      }

      return { data, error }
    } catch (error) {
      console.error('Update admin user error:', error)
      return { data: null, error }
    }
  },

  async deleteAdminUser(adminId: string): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('admin_users')
        .delete()
        .eq('id', adminId)

      // 记录操作日志
      if (!error) {
        await this.logAdminAction({
          action: 'delete_admin',
          resource: 'admin_users',
          resource_id: adminId,
          details: {}
        })
      }

      return { error }
    } catch (error) {
      console.error('Delete admin user error:', error)
      return { error }
    }
  },

  // 角色管理
  async getAdminRoles(): Promise<{ data: AdminRole[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('admin_roles')
        .select('*')
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('Get admin roles error:', error)
      return { data: null, error }
    }
  },

  async createAdminRole(roleData: {
    name: string
    description: string
    permissions: Record<string, boolean>
  }): Promise<{ data: AdminRole | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('admin_roles')
        .insert(roleData)
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('Create admin role error:', error)
      return { data: null, error }
    }
  },

  // 操作日志
  async getAdminLogs(filters?: {
    adminId?: string
    action?: string
    startDate?: string
    endDate?: string
    limit?: number
  }): Promise<{ data: AdminLog[] | null; error: any }> {
    try {
      let query = supabase
        .from('admin_logs')
        .select('*')

      if (filters?.adminId) {
        query = query.eq('admin_id', filters.adminId)
      }

      if (filters?.action) {
        query = query.eq('action', filters.action)
      }

      if (filters?.startDate) {
        query = query.gte('created_at', filters.startDate)
      }

      if (filters?.endDate) {
        query = query.lte('created_at', filters.endDate)
      }

      const { data, error } = await query
        .order('created_at', { ascending: false })
        .limit(filters?.limit || 100)

      return { data, error }
    } catch (error) {
      console.error('Get admin logs error:', error)
      return { data: null, error }
    }
  },

  async logAdminAction(logData: {
    action: string
    resource: string
    resource_id?: string
    details: Record<string, any>
  }): Promise<void> {
    try {
      const currentUser = await supabase.auth.getUser()
      if (!currentUser.data.user) return

      await supabase
        .from('admin_logs')
        .insert({
          admin_id: currentUser.data.user.id,
          admin_name: currentUser.data.user.user_metadata?.name || currentUser.data.user.email,
          action: logData.action,
          resource: logData.resource,
          resource_id: logData.resource_id,
          details: logData.details,
          ip_address: await this.getClientIP(),
          user_agent: navigator.userAgent
        })
    } catch (error) {
      console.error('Log admin action error:', error)
    }
  },

  // 权限检查
  async checkPermission(permission: AdminPermission): Promise<boolean> {
    try {
      const currentUser = await supabase.auth.getUser()
      if (!currentUser.data.user) return false

      const { data: adminUser } = await supabase
        .from('admin_users')
        .select('role, permissions')
        .eq('user_id', currentUser.data.user.id)
        .eq('is_active', true)
        .single()

      if (!adminUser) return false

      // 检查用户特定权限
      if (adminUser.permissions && adminUser.permissions[permission]) {
        return true
      }

      // 检查角色默认权限
      const rolePermissions = DEFAULT_ROLE_PERMISSIONS[adminUser.role] || []
      return rolePermissions.includes(permission)
    } catch (error) {
      console.error('Check permission error:', error)
      return false
    }
  },

  // 工具函数
  generateRandomPassword(length: number = 12): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*'
    let result = ''
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  },

  getRoleDefaultPermissions(role: string): Record<string, boolean> {
    const permissions = DEFAULT_ROLE_PERMISSIONS[role] || []
    const permissionMap: Record<string, boolean> = {}
    permissions.forEach(permission => {
      permissionMap[permission] = true
    })
    return permissionMap
  },

  async getClientIP(): Promise<string | null> {
    try {
      const response = await fetch('https://api.ipify.org?format=json')
      const data = await response.json()
      return data.ip
    } catch (error) {
      return null
    }
  }
}