/**
 * 权限管理服务 - 星趣后台管理系统
 * 功能：角色权限检查、操作日志记录、管理员账号管理
 * Created: 2025-09-05
 */

import { supabase } from '@/lib/supabase'
import { AdminPermission, AdminLog, AdminRole } from '@/types/permission'

export interface Permission {
  id: string
  name: string
  resource: string
  action: string
  description?: string
}

export interface AdminUser {
  id: string
  email: string
  nickname: string
  role: AdminRole
  permissions: string[]
  isActive: boolean
  lastLoginAt?: string
  createdAt: string
  updatedAt: string
}

export interface CreateAdminRequest {
  email: string
  nickname: string
  role: AdminRole
  permissions?: string[]
}

export interface AuditFilter {
  adminId?: string
  action?: string
  resource?: string
  dateFrom?: string
  dateTo?: string
  limit?: number
  offset?: number
}

class PermissionService {
  /**
   * 检查用户是否具有指定权限
   */
  async hasPermission(adminId: string, permission: string): Promise<boolean> {
    try {
      const { data: admin, error } = await supabase
        .from('admin_users')
        .select('role, permissions')
        .eq('id', adminId)
        .eq('is_active', true)
        .single()

      if (error || !admin) {
        console.error('获取管理员信息失败:', error)
        return false
      }

      // 超级管理员拥有所有权限
      if (admin.role === 'super_admin') {
        return true
      }

      // 检查具体权限
      const permissions = Array.isArray(admin.permissions) ? admin.permissions : []
      return permissions.includes(permission)
    } catch (error) {
      console.error('权限检查失败:', error)
      return false
    }
  }

  /**
   * 检查用户角色
   */
  async hasRole(adminId: string, role: AdminRole): Promise<boolean> {
    try {
      const { data: admin, error } = await supabase
        .from('admin_users')
        .select('role')
        .eq('id', adminId)
        .eq('is_active', true)
        .single()

      if (error || !admin) {
        return false
      }

      return admin.role === role
    } catch (error) {
      console.error('角色检查失败:', error)
      return false
    }
  }

  /**
   * 获取用户权限列表
   */
  async getUserPermissions(adminId: string): Promise<string[]> {
    try {
      const { data: admin, error } = await supabase
        .from('admin_users')
        .select('role, permissions')
        .eq('id', adminId)
        .eq('is_active', true)
        .single()

      if (error || !admin) {
        console.error('获取用户权限失败:', error)
        return []
      }

      // 超级管理员拥有所有权限
      if (admin.role === 'super_admin') {
        return ['*'] // 代表所有权限
      }

      return Array.isArray(admin.permissions) ? admin.permissions : []
    } catch (error) {
      console.error('获取用户权限失败:', error)
      return []
    }
  }

  /**
   * 创建管理员账号
   */
  async createAdmin(request: CreateAdminRequest): Promise<{ success: boolean; data?: AdminUser; error?: string }> {
    try {
      // 检查邮箱是否已存在
      const { data: existingAdmin } = await supabase
        .from('admin_users')
        .select('id')
        .eq('email', request.email)
        .single()

      if (existingAdmin) {
        return { success: false, error: '邮箱已被使用' }
      }

      const adminData = {
        email: request.email,
        nickname: request.nickname,
        role: request.role,
        permissions: request.permissions || this.getDefaultPermissions(request.role),
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }

      const { data: newAdmin, error } = await supabase
        .from('admin_users')
        .insert([adminData])
        .select()
        .single()

      if (error) {
        console.error('创建管理员失败:', error)
        return { success: false, error: '创建失败' }
      }

      return { success: true, data: newAdmin as AdminUser }
    } catch (error) {
      console.error('创建管理员异常:', error)
      return { success: false, error: '系统异常' }
    }
  }

  /**
   * 更新管理员权限
   */
  async updateAdminPermissions(adminId: string, permissions: string[]): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('admin_users')
        .update({
          permissions,
          updated_at: new Date().toISOString()
        })
        .eq('id', adminId)

      if (error) {
        console.error('更新权限失败:', error)
        return { success: false, error: '更新失败' }
      }

      return { success: true }
    } catch (error) {
      console.error('更新权限异常:', error)
      return { success: false, error: '系统异常' }
    }
  }

  /**
   * 更新管理员角色
   */
  async updateAdminRole(adminId: string, role: AdminRole): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('admin_users')
        .update({
          role,
          permissions: this.getDefaultPermissions(role),
          updated_at: new Date().toISOString()
        })
        .eq('id', adminId)

      if (error) {
        console.error('更新角色失败:', error)
        return { success: false, error: '更新失败' }
      }

      return { success: true }
    } catch (error) {
      console.error('更新角色异常:', error)
      return { success: false, error: '系统异常' }
    }
  }

  /**
   * 启用/禁用管理员账号
   */
  async toggleAdminStatus(adminId: string, isActive: boolean): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('admin_users')
        .update({
          is_active: isActive,
          updated_at: new Date().toISOString()
        })
        .eq('id', adminId)

      if (error) {
        console.error('更新账号状态失败:', error)
        return { success: false, error: '更新失败' }
      }

      return { success: true }
    } catch (error) {
      console.error('更新账号状态异常:', error)
      return { success: false, error: '系统异常' }
    }
  }

  /**
   * 记录操作日志
   */
  async logOperation(
    adminId: string,
    action: string,
    resource: string,
    resourceId?: string,
    details?: Record<string, any>,
    ipAddress?: string,
    userAgent?: string
  ): Promise<void> {
    try {
      const logData: Omit<AdminLog, 'id' | 'createdAt'> = {
        adminId,
        action,
        resource,
        resourceId,
        details: details || {},
        ipAddress: ipAddress || '',
        userAgent: userAgent || '',
        createdAt: new Date().toISOString()
      }

      const { error } = await supabase
        .from('admin_operation_logs')
        .insert([{
          admin_id: logData.adminId,
          action: logData.action,
          resource: logData.resource,
          resource_id: logData.resourceId,
          details: logData.details,
          ip_address: logData.ipAddress,
          user_agent: logData.userAgent,
          created_at: logData.createdAt
        }])

      if (error) {
        console.error('记录操作日志失败:', error)
      }
    } catch (error) {
      console.error('记录操作日志异常:', error)
    }
  }

  /**
   * 获取操作日志
   */
  async getAuditLogs(filters: AuditFilter = {}): Promise<{ success: boolean; data?: AdminLog[]; total?: number; error?: string }> {
    try {
      let query = supabase
        .from('admin_operation_logs')
        .select(`
          id,
          admin_id,
          action,
          resource,
          resource_id,
          details,
          ip_address,
          user_agent,
          created_at,
          admin_users!inner(nickname, email)
        `, { count: 'exact' })
        .order('created_at', { ascending: false })

      // 应用过滤条件
      if (filters.adminId) {
        query = query.eq('admin_id', filters.adminId)
      }
      if (filters.action) {
        query = query.ilike('action', `%${filters.action}%`)
      }
      if (filters.resource) {
        query = query.ilike('resource', `%${filters.resource}%`)
      }
      if (filters.dateFrom) {
        query = query.gte('created_at', filters.dateFrom)
      }
      if (filters.dateTo) {
        query = query.lte('created_at', filters.dateTo)
      }

      // 分页
      const limit = filters.limit || 50
      const offset = filters.offset || 0
      query = query.range(offset, offset + limit - 1)

      const { data: logs, error, count } = await query

      if (error) {
        console.error('获取操作日志失败:', error)
        return { success: false, error: '获取失败' }
      }

      // 转换数据格式
      const formattedLogs: AdminLog[] = (logs || []).map(log => ({
        id: log.id,
        adminId: log.admin_id,
        action: log.action,
        resource: log.resource,
        resourceId: log.resource_id,
        details: log.details,
        ipAddress: log.ip_address,
        userAgent: log.user_agent,
        createdAt: log.created_at,
        adminInfo: {
          nickname: log.admin_users?.nickname || '',
          email: log.admin_users?.email || ''
        }
      }))

      return { success: true, data: formattedLogs, total: count || 0 }
    } catch (error) {
      console.error('获取操作日志异常:', error)
      return { success: false, error: '系统异常' }
    }
  }

  /**
   * 获取所有管理员列表
   */
  async getAdminList(): Promise<{ success: boolean; data?: AdminUser[]; error?: string }> {
    try {
      const { data: admins, error } = await supabase
        .from('admin_users')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        console.error('获取管理员列表失败:', error)
        return { success: false, error: '获取失败' }
      }

      const formattedAdmins: AdminUser[] = (admins || []).map(admin => ({
        id: admin.id,
        email: admin.email,
        nickname: admin.nickname,
        role: admin.role,
        permissions: admin.permissions || [],
        isActive: admin.is_active,
        lastLoginAt: admin.last_login_at,
        createdAt: admin.created_at,
        updatedAt: admin.updated_at
      }))

      return { success: true, data: formattedAdmins }
    } catch (error) {
      console.error('获取管理员列表异常:', error)
      return { success: false, error: '系统异常' }
    }
  }

  /**
   * 获取角色默认权限
   */
  private getDefaultPermissions(role: AdminRole): string[] {
    const permissions = {
      super_admin: ['*'], // 所有权限
      operator: [
        'users.read',
        'users.edit',
        'users.batch_edit',
        'analytics.read',
        'content.read',
        'content.moderate'
      ],
      moderator: [
        'users.read',
        'content.read',
        'content.moderate',
        'reports.read',
        'reports.handle'
      ],
      technical: [
        'system.monitor',
        'system.config',
        'ai.monitor',
        'logs.read'
      ]
    }

    return permissions[role] || []
  }

  /**
   * 验证敏感操作需要二次验证
   */
  async requireTwoFactorAuth(adminId: string, operation: string): Promise<boolean> {
    const sensitiveOperations = [
      'admin.create',
      'admin.delete',
      'admin.permission_change',
      'system.config_change',
      'financial.refund'
    ]

    return sensitiveOperations.includes(operation)
  }

  /**
   * 检测异常操作行为
   */
  async detectAnomalousActivity(adminId: string): Promise<{ suspicious: boolean; reasons: string[] }> {
    try {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
      
      const { data: recentLogs, error } = await supabase
        .from('admin_operation_logs')
        .select('action, ip_address, created_at')
        .eq('admin_id', adminId)
        .gte('created_at', oneHourAgo)
        .order('created_at', { ascending: false })

      if (error || !recentLogs) {
        return { suspicious: false, reasons: [] }
      }

      const reasons: string[] = []

      // 检查频率异常（1小时内超过100次操作）
      if (recentLogs.length > 100) {
        reasons.push('操作频率异常')
      }

      // 检查IP地址变化
      const uniqueIPs = new Set(recentLogs.map(log => log.ip_address))
      if (uniqueIPs.size > 3) {
        reasons.push('IP地址频繁变化')
      }

      // 检查敏感操作集中
      const sensitiveActions = recentLogs.filter(log => 
        log.action.includes('delete') || 
        log.action.includes('permission') ||
        log.action.includes('config')
      )
      if (sensitiveActions.length > 10) {
        reasons.push('敏感操作过于集中')
      }

      return { suspicious: reasons.length > 0, reasons }
    } catch (error) {
      console.error('检测异常活动失败:', error)
      return { suspicious: false, reasons: [] }
    }
  }

  /**
   * 锁定管理员账号
   */
  async lockAdmin(adminId: string, reason: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('admin_users')
        .update({
          is_active: false,
          locked_reason: reason,
          locked_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', adminId)

      if (error) {
        console.error('锁定账号失败:', error)
        return { success: false, error: '锁定失败' }
      }

      // 记录锁定日志
      await this.logOperation(
        adminId,
        'admin.locked',
        'admin_users',
        adminId,
        { reason, locked_at: new Date().toISOString() }
      )

      return { success: true }
    } catch (error) {
      console.error('锁定账号异常:', error)
      return { success: false, error: '系统异常' }
    }
  }
}

// 导出权限管理服务实例
export const permissionService = new PermissionService()

// 权限常量定义
export const PERMISSIONS = {
  // 用户管理
  USERS_READ: 'users.read',
  USERS_EDIT: 'users.edit',
  USERS_DELETE: 'users.delete',
  USERS_BATCH_EDIT: 'users.batch_edit',
  
  // 内容管理
  CONTENT_READ: 'content.read',
  CONTENT_MODERATE: 'content.moderate',
  CONTENT_DELETE: 'content.delete',
  
  // 数据分析
  ANALYTICS_READ: 'analytics.read',
  ANALYTICS_EXPORT: 'analytics.export',
  
  // 系统管理
  SYSTEM_CONFIG: 'system.config',
  SYSTEM_MONITOR: 'system.monitor',
  
  // 管理员管理
  ADMIN_CREATE: 'admin.create',
  ADMIN_EDIT: 'admin.edit',
  ADMIN_DELETE: 'admin.delete',
  
  // 财务管理
  FINANCIAL_READ: 'financial.read',
  FINANCIAL_REFUND: 'financial.refund',
  
  // AI服务
  AI_MONITOR: 'ai.monitor',
  AI_CONFIG: 'ai.config',
  
  // 日志查看
  LOGS_READ: 'logs.read'
} as const

export type PermissionKey = keyof typeof PERMISSIONS