/**
 * 权限管理相关类型定义 - 星趣后台管理系统
 * Created: 2025-09-05
 */

export type AdminRole = 'super_admin' | 'operator' | 'moderator' | 'technical'

export interface AdminPermission {
  id: string
  adminId: string
  role: AdminRole
  permissions: string[]
  createdAt: string
  updatedAt: string
}

export interface AdminLog {
  id: string
  adminId: string
  action: string
  resource: string
  resourceId?: string
  details: Record<string, any>
  ipAddress: string
  userAgent: string
  createdAt: string
  adminInfo?: {
    nickname: string
    email: string
  }
}

export interface Permission {
  id: string
  name: string
  resource: string
  action: string
  description?: string
}

export interface RolePermission {
  role: AdminRole
  permissions: Permission[]
  description: string
}

export interface SecurityEvent {
  id: string
  adminId: string
  eventType: 'login_failure' | 'suspicious_activity' | 'permission_denied' | 'account_locked'
  description: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  ipAddress: string
  userAgent: string
  createdAt: string
}