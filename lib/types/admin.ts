/**
 * 星趣后台管理系统 - TypeScript类型定义
 * 包含所有新增功能模块的类型接口
 * Created: 2025-09-05
 */

// ==============================================
// 基础类型定义
// ==============================================

export type UUID = string
export type Timestamp = string
export type JSONValue = string | number | boolean | null | JSONValue[] | { [key: string]: JSONValue }

// 通用状态类型
export type CommonStatus = 'active' | 'inactive' | 'pending' | 'disabled'
export type AlertType = 'info' | 'success' | 'warning' | 'error'
export type Priority = 1 | 2 | 3 | 4 | 5

// ==============================================
// 实时监控相关类型
// ==============================================

export interface RealtimeMetric {
  id: UUID
  name: string
  value: number | string
  unit?: string
  status: 'normal' | 'warning' | 'critical' | 'info'
  trend?: 'up' | 'down' | 'stable'
  threshold?: {
    warning: number
    critical: number
  }
  lastUpdated: Date
  tags?: Record<string, any>
}

export interface SystemAlert {
  id: UUID
  type: AlertType
  title: string
  message: string
  metricName?: string
  thresholdValue?: number
  currentValue?: number
  status: 'active' | 'acknowledged' | 'resolved'
  acknowledgedBy?: UUID
  acknowledgedAt?: Timestamp
  resolvedAt?: Timestamp
  timestamp: Date
}

export interface MonitoringConfig {
  metricName: string
  displayName: string
  unit: string
  warningThreshold: number
  criticalThreshold: number
  isEnabled: boolean
  refreshInterval: number // 秒
}

// ==============================================
// 管理员权限相关类型
// ==============================================

export type AdminRole = 'super_admin' | 'operator' | 'moderator' | 'technical'

export interface AdminUser {
  id: UUID
  email: string
  name: string
  role: AdminRole
  permissions: Record<string, any>
  isActive: boolean
  lastLoginAt?: Timestamp
  loginAttempts: number
  lockedUntil?: Timestamp
  avatarUrl?: string
  phone?: string
  department?: string
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface AdminPermission {
  id: UUID
  adminId: UUID
  role: AdminRole
  permissions: string[]
  modules: string[] // 可访问的功能模块
  restrictions?: Record<string, any> // 特殊限制
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface AdminOperationLog {
  id: UUID
  adminId: UUID
  action: string
  resource: string
  resourceId?: string
  resourceName?: string
  details: Record<string, any>
  result: 'success' | 'failed' | 'unauthorized'
  errorMessage?: string
  ipAddress?: string
  userAgent?: string
  sessionId?: string
  requestId?: string
  durationMs?: number
  createdAt: Timestamp
}

export type OperationAction = 
  | 'CREATE' | 'UPDATE' | 'DELETE' | 'VIEW' | 'EXPORT' 
  | 'LOGIN' | 'LOGOUT' | 'APPROVE' | 'REJECT'

// ==============================================
// 内容审核相关类型
// ==============================================

export interface ModerationRecord {
  id: UUID
  contentId: string
  contentType: 'text' | 'image' | 'audio' | 'video' | 'user_profile'
  contentSource?: string
  originalContent?: string
  moderationResult: 'approved' | 'rejected' | 'pending' | 'needs_review'
  aiConfidence?: number // 0-1
  aiReasons: string[]
  humanReviewerId?: UUID
  humanReviewResult?: string
  humanReviewReason?: string
  violationTypes: string[]
  severityLevel: 1 | 2 | 3 | 4 | 5
  autoAction?: string
  appealStatus: 'none' | 'submitted' | 'reviewing' | 'approved' | 'rejected'
  appealReason?: string
  appealHandledBy?: UUID
  appealHandledAt?: Timestamp
  createdAt: Timestamp
  reviewedAt?: Timestamp
  updatedAt: Timestamp
}

export interface UserReport {
  id: UUID
  reporterId?: UUID
  reportedContentId?: string
  reportedUserId?: UUID
  reportType: 'spam' | 'inappropriate' | 'harassment' | 'fake' | 'copyright' | 'other'
  reportCategory: 'content' | 'user' | 'system'
  reason: string
  evidenceUrls: string[]
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed'
  priority: Priority
  assignedTo?: UUID
  handlerNotes?: string
  resolution?: string
  handledBy?: UUID
  handledAt?: Timestamp
  reporterIp?: string
  reporterUserAgent?: string
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface ModerationRule {
  id: UUID
  name: string
  description?: string
  contentTypes: string[]
  ruleType: 'keyword' | 'regex' | 'ai_threshold' | 'length' | 'custom'
  ruleConfig: Record<string, any>
  action: 'block' | 'flag' | 'warn' | 'delete'
  severityLevel: 1 | 2 | 3 | 4 | 5
  isActive: boolean
  createdBy: UUID
  createdAt: Timestamp
  updatedAt: Timestamp
}

// ==============================================
// 商业化相关类型
// ==============================================

export interface SubscriptionPlan {
  id: UUID
  name: string
  displayName: string
  description?: string
  price: number
  currency: string
  durationDays: number
  features: string[]
  limitations: Record<string, any>
  isActive: boolean
  sortOrder: number
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface UserSubscription {
  id: UUID
  userId: UUID
  planId: UUID
  status: 'active' | 'expired' | 'cancelled' | 'pending'
  startedAt: Timestamp
  expiresAt: Timestamp
  autoRenew: boolean
  renewalPrice?: number
  cancelledAt?: Timestamp
  cancellationReason?: string
  createdAt: Timestamp
  updatedAt: Timestamp
  // 关联数据
  plan?: SubscriptionPlan
}

export interface PaymentOrder {
  id: UUID
  orderNumber: string
  userId: UUID
  planId: UUID
  subscriptionId?: UUID
  amount: number
  currency: string
  status: 'pending' | 'completed' | 'failed' | 'refunded' | 'cancelled'
  paymentMethod?: 'wechat' | 'alipay' | 'apple_pay' | 'card' | 'other'
  paymentProvider?: string
  transactionId?: string
  paymentData?: Record<string, any>
  paidAt?: Timestamp
  refundedAt?: Timestamp
  refundAmount?: number
  refundReason?: string
  failureReason?: string
  retryCount: number
  createdAt: Timestamp
  updatedAt: Timestamp
  // 关联数据
  plan?: SubscriptionPlan
  subscription?: UserSubscription
}

export interface CommerceMetrics {
  totalRevenue: number
  monthlyRevenue: number
  activeSubscriptions: number
  newSubscriptions: number
  cancelledSubscriptions: number
  churnRate: number
  averageRevenuePerUser: number
  conversionRate: number
  refundRate: number
}

// ==============================================
// AI服务监控相关类型
// ==============================================

export interface AIServiceMetric {
  id: UUID
  serviceName: string
  metricType: 'api_calls' | 'response_time' | 'success_rate' | 'cost' | 'tokens'
  value: number
  unit: string
  timestamp: Timestamp
  metadata?: Record<string, any>
}

export interface AIUsageRecord {
  id: UUID
  userId: UUID
  modelName: string
  apiEndpoint: string
  inputTokens: number
  outputTokens: number
  totalTokens: number
  responseTime: number
  cost: number
  success: boolean
  errorMessage?: string
  timestamp: Timestamp
}

export interface AIServiceConfig {
  id: UUID
  serviceName: string
  provider: string
  endpoint: string
  apiKey: string
  model: string
  maxTokens: number
  temperature: number
  isActive: boolean
  dailyLimit?: number
  monthlyLimit?: number
  costPerToken: number
  createdAt: Timestamp
  updatedAt: Timestamp
}

// ==============================================
// 系统配置相关类型
// ==============================================

export interface SystemConfig {
  id: UUID
  category: string
  key: string
  value: JSONValue
  dataType: 'string' | 'number' | 'boolean' | 'object' | 'array'
  description?: string
  validationRules?: Record<string, any>
  isActive: boolean
  isPublic: boolean
  requiresRestart: boolean
  environment: 'development' | 'staging' | 'production' | 'all'
  updatedBy?: UUID
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface SystemConfigHistory {
  id: UUID
  configId: UUID
  oldValue?: JSONValue
  newValue: JSONValue
  changeReason?: string
  changedBy: UUID
  changedAt: Timestamp
}

export interface ABTestConfig {
  id: UUID
  name: string
  description?: string
  featureFlag: string
  status: 'draft' | 'running' | 'paused' | 'completed' | 'cancelled'
  variants: Array<{
    name: string
    weight: number
    config?: Record<string, any>
  }>
  trafficAllocation: number // 0-1
  targetAudience?: Record<string, any>
  successMetrics: string[]
  startDate?: Timestamp
  endDate?: Timestamp
  durationDays?: number
  totalParticipants: number
  conversionRate?: number
  statisticalSignificance?: number
  confidenceLevel: number
  createdBy: UUID
  updatedBy?: UUID
  approvedBy?: UUID
  approvedAt?: Timestamp
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface ABTestParticipant {
  id: UUID
  testId: UUID
  userId: UUID
  variant: string
  assignedAt: Timestamp
  converted: boolean
  conversionValue: number
  metadata?: Record<string, any>
}

export interface FeatureFlag {
  id: UUID
  name: string
  displayName: string
  description?: string
  flagType: 'boolean' | 'percentage' | 'config'
  isEnabled: boolean
  configValue?: Record<string, any>
  percentageEnabled: number // 0-1
  targetAudience?: Record<string, any>
  environments: string[]
  dependencies: string[]
  conflicts: string[]
  ownerTeam?: string
  expiresAt?: Timestamp
  archived: boolean
  archivedAt?: Timestamp
  createdBy: UUID
  updatedBy?: UUID
  createdAt: Timestamp
  updatedAt: Timestamp
}

export interface SystemAnnouncement {
  id: UUID
  title: string
  content: string
  announcementType: AlertType | 'maintenance'
  priority: Priority
  isActive: boolean
  isSticky: boolean
  showInDashboard: boolean
  showPopup: boolean
  targetRoles: string[]
  targetUsers: UUID[]
  startTime: Timestamp
  endTime?: Timestamp
  viewCount: number
  clickCount: number
  createdBy: UUID
  createdAt: Timestamp
  updatedAt: Timestamp
}

// ==============================================
// 批量操作相关类型
// ==============================================

export interface BatchOperation<T = any> {
  id: UUID
  operationType: 'create' | 'update' | 'delete' | 'import' | 'export'
  resourceType: string
  totalItems: number
  processedItems: number
  successfulItems: number
  failedItems: number
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'
  progress: number // 0-100
  results: BatchOperationResult[]
  startedAt?: Timestamp
  completedAt?: Timestamp
  createdBy: UUID
  createdAt: Timestamp
}

export interface BatchOperationResult {
  itemId: string
  status: 'success' | 'failed' | 'skipped'
  errorMessage?: string
  data?: any
}

export interface UserBatchUpdate {
  userIds: UUID[]
  updates: {
    status?: 'active' | 'disabled'
    tags?: string[]
    role?: string
    permissions?: Record<string, any>
  }
  reason?: string
}

// ==============================================
// API响应类型
// ==============================================

export interface APIResponse<T = any> {
  success: boolean
  data?: T
  error?: string | Error
  message?: string
  code?: string
  timestamp?: Timestamp
}

export interface PaginatedResponse<T> {
  data: T[]
  pagination: {
    page: number
    pageSize: number
    total: number
    totalPages: number
  }
}

export interface FilterOptions {
  search?: string
  status?: string[]
  dateRange?: {
    start: Timestamp
    end: Timestamp
  }
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
  tags?: string[]
  categories?: string[]
}

// ==============================================
// 组件Props类型
// ==============================================

export interface MetricCardProps {
  title: string
  value: number | string
  change?: number
  changeLabel?: string
  icon?: React.ReactNode
  color?: 'primary' | 'success' | 'warning' | 'default'
  sparklineData?: number[]
  target?: number
  description?: string
  loading?: boolean
}

export interface AlertProps {
  alert: SystemAlert
  onAcknowledge?: (alertId: UUID) => void
  onDismiss?: (alertId: UUID) => void
  compact?: boolean
}

export interface TableColumn<T = any> {
  key: keyof T | string
  title: string
  dataIndex?: keyof T
  render?: (value: any, record: T, index: number) => React.ReactNode
  sortable?: boolean
  filterable?: boolean
  width?: string | number
  align?: 'left' | 'center' | 'right'
}

export interface TableProps<T = any> {
  data: T[]
  columns: TableColumn<T>[]
  loading?: boolean
  pagination?: {
    current: number
    pageSize: number
    total: number
    onChange: (page: number, pageSize: number) => void
  }
  rowSelection?: {
    selectedRowKeys: string[]
    onChange: (selectedRowKeys: string[], selectedRows: T[]) => void
  }
  onRow?: (record: T, index: number) => React.HTMLAttributes<HTMLTableRowElement>
}

// ==============================================
// Hooks类型
// ==============================================

export interface UseRealtimeMonitoringOptions {
  interval?: number
  enabled?: boolean
  onError?: (error: Error) => void
  onAlert?: (alert: SystemAlert) => void
}

export interface UsePermissionsResult {
  hasPermission: (permission: string) => boolean
  hasRole: (role: AdminRole) => boolean
  hasAccess: (module: string) => boolean
  canPerform: (action: string, resource: string) => boolean
  currentUser: AdminUser | null
  loading: boolean
}

export interface UseBatchOperationsResult<T> {
  selectedItems: T[]
  selectAll: boolean
  toggleSelectAll: () => void
  toggleSelectItem: (item: T) => void
  clearSelection: () => void
  executeOperation: (operation: string, options?: any) => Promise<BatchOperation>
  isLoading: boolean
}

// ==============================================
// 导出所有类型
// ==============================================

export type {
  // 重新导出常用的基础类型
  UUID as AdminUUID,
  Timestamp as AdminTimestamp,
  JSONValue as AdminJSONValue,
  APIResponse as AdminAPIResponse,
  PaginatedResponse as AdminPaginatedResponse,
}

// 类型守卫函数
export const isAdminUser = (obj: any): obj is AdminUser => {
  return obj && typeof obj.id === 'string' && typeof obj.email === 'string' && typeof obj.role === 'string'
}

export const isSystemAlert = (obj: any): obj is SystemAlert => {
  return obj && typeof obj.id === 'string' && typeof obj.type === 'string' && typeof obj.title === 'string'
}

export const isPaymentOrder = (obj: any): obj is PaymentOrder => {
  return obj && typeof obj.id === 'string' && typeof obj.orderNumber === 'string' && typeof obj.amount === 'number'
}