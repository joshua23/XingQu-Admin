export interface AdminUser {
  id: string
  user_id: string
  email: string
  name: string
  role: AdminRole
  permissions: Record<string, boolean>
  is_active: boolean
  last_login_at?: string
  created_at: string
  updated_at: string
}

export interface AdminRole {
  id: string
  name: string
  description: string
  permissions: Record<string, boolean>
  created_at: string
}

export interface AdminLog {
  id: string
  admin_id: string
  admin_name: string
  action: string
  resource: string
  resource_id?: string
  details: Record<string, any>
  ip_address?: string
  user_agent?: string
  created_at: string
}

export type AdminPermission = 
  // 用户管理权限
  | 'users.view'
  | 'users.edit'
  | 'users.delete'
  | 'users.export'
  | 'users.batch_operations'
  
  // 内容管理权限
  | 'content.view'
  | 'content.moderate'
  | 'content.delete'
  | 'content.reports'
  
  // 数据分析权限
  | 'analytics.view'
  | 'analytics.export'
  | 'analytics.advanced'
  
  // 商业化管理权限
  | 'business.view'
  | 'business.subscriptions'
  | 'business.payments'
  | 'business.revenue'
  
  // AI服务权限
  | 'ai.view'
  | 'ai.config'
  | 'ai.costs'
  
  // 系统管理权限
  | 'system.config'
  | 'system.users'
  | 'system.roles'
  | 'system.logs'
  | 'system.monitoring'

export const ADMIN_ROLES = {
  SUPER_ADMIN: 'super_admin',
  OPERATOR: 'operator', 
  MODERATOR: 'moderator',
  TECHNICAL: 'technical'
} as const

export const DEFAULT_ROLE_PERMISSIONS: Record<string, AdminPermission[]> = {
  [ADMIN_ROLES.SUPER_ADMIN]: [
    'users.view', 'users.edit', 'users.delete', 'users.export', 'users.batch_operations',
    'content.view', 'content.moderate', 'content.delete', 'content.reports',
    'analytics.view', 'analytics.export', 'analytics.advanced',
    'business.view', 'business.subscriptions', 'business.payments', 'business.revenue',
    'ai.view', 'ai.config', 'ai.costs',
    'system.config', 'system.users', 'system.roles', 'system.logs', 'system.monitoring'
  ],
  
  [ADMIN_ROLES.OPERATOR]: [
    'users.view', 'users.edit', 'users.export', 'users.batch_operations',
    'analytics.view', 'analytics.export',
    'business.view', 'business.subscriptions', 'business.payments', 'business.revenue',
    'ai.view'
  ],
  
  [ADMIN_ROLES.MODERATOR]: [
    'users.view', 'users.edit',
    'content.view', 'content.moderate', 'content.delete', 'content.reports'
  ],
  
  [ADMIN_ROLES.TECHNICAL]: [
    'analytics.view', 'analytics.advanced',
    'ai.view', 'ai.config', 'ai.costs',
    'system.monitoring', 'system.logs'
  ]
}