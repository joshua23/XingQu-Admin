// 用户相关类型
export interface User {
  id: string
  email: string
  name?: string
  avatar_url?: string
  created_at: string
  last_sign_in_at?: string
  membership_status?: 'free' | 'basic' | 'premium' | 'lifetime'
}

// 管理员相关类型
export interface AdminUser {
  id: string
  email: string
  name: string
  role: 'super_admin' | 'operator' | 'moderator' | 'technical'
  permissions: Record<string, any>
  is_active: boolean
  last_login_at?: string
  created_at: string
}

// 数据统计类型
export interface DashboardStats {
  totalUsers: number
  activeUsers: number
  newUsers: number
  totalSessions: number
  averageSessionDuration: number
  totalRevenue: number
  conversionRate: number
}

// 行为追踪事件类型
export interface TrackingEvent {
  id: string
  user_id: string
  event_name: string
  event_category: string
  event_properties?: Record<string, any>
  session_id?: string
  page_name?: string
  timestamp: string
}

// 会话数据类型
export interface UserSession {
  id: string
  user_id: string
  session_start: string
  session_end?: string
  duration?: number
  device_info?: Record<string, any>
  location_info?: Record<string, any>
}

// 导航菜单类型
export interface NavItem {
  id: string
  label: string
  icon: string
  path: string
  children?: NavItem[]
}

// 图表数据类型
export interface ChartData {
  name: string
  value: number
  date?: string
}

// 筛选条件类型
export interface FilterOptions {
  dateRange: {
    start: Date
    end: Date
  }
  userType?: string[]
  eventType?: string[]
  status?: string[]
}
