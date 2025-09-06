'use client'

import React, { useState } from 'react'
import { 
  Settings, 
  Save, 
  Bell, 
  Shield, 
  Database, 
  Mail,
  Globe,
  Palette,
  Key,
  Users,
  Copy,
  CheckCircle,
  AlertTriangle,
  ExternalLink,
  UserCheck,
  FileText,
  Eye,
  Lock,
  Toggle,
  TestTube,
  Cog,
  Activity,
  BarChart3,
  Target,
  Layers
} from 'lucide-react'
import ABTestManager from '@/components/ABTestManager'
import PermissionManager from '@/components/PermissionManager'
import AdminAuditLog from '@/components/AdminAuditLog'

export default function SystemConfigPage() {
  const [settings, setSettings] = useState({
    // 系统基础设置
    siteName: '星趣社区管理后台',
    siteDescription: '专业的社区管理解决方案',
    adminEmail: 'admin@xingqu.com',
    
    // 功能开关
    abTestingEnabled: true,
    analyticsEnabled: true,
    realTimeMonitoring: true,
    apiLoggingEnabled: true,
    cacheEnabled: true,
    
    // 通知设置
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false,
    webhookNotifications: true,
    
    // 安全设置
    requireTwoFactor: false,
    passwordPolicy: 'medium',
    sessionTimeout: 30,
    maxLoginAttempts: 5,
    lockoutDuration: 30,
    ipWhitelistEnabled: false,
    apiRateLimit: 100,
    auditLogRetention: 365,
    sensitiveActionLogging: true,
    
    // 数据库设置
    backupFrequency: 'daily',
    retentionPeriod: 90,
    
    // 用户设置
    allowUserRegistration: true,
    requireEmailVerification: true,
    defaultUserRole: 'member',
    
    // 系统性能配置
    maxConcurrentUsers: 10000,
    requestTimeout: 30,
    memoryLimit: '2GB',
    
    // A/B测试配置
    abTestingSampleSize: 1000,
    abTestingConfidenceLevel: 95,
    abTestingAutoStop: true,
    
    // 配置变更审批
    requireApprovalForChanges: true,
    approvalWorkflowEnabled: true,
    multiStageApproval: false
  })

  const [activeTab, setActiveTab] = useState('general')
  const [copied, setCopied] = useState(false)
  const [pendingApprovals, setPendingApprovals] = useState([
    {
      id: '1',
      configType: 'Security',
      change: 'Enable Two-Factor Authentication',
      requestedBy: 'admin@xingqu.com',
      requestedAt: new Date('2024-01-20T10:30:00'),
      status: 'pending'
    },
    {
      id: '2', 
      configType: 'Performance',
      change: 'Increase API Rate Limit to 200',
      requestedBy: 'dev@xingqu.com',
      requestedAt: new Date('2024-01-19T15:45:00'),
      status: 'pending'
    }
  ])

  const handleSave = () => {
    console.log('保存系统配置:', settings)
    // 实现保存逻辑
  }

  const updateSetting = (key: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [key]: value
    }))
  }

  const handleApprovalAction = (id: string, action: 'approve' | 'reject') => {
    setPendingApprovals(prev => 
      prev.map(approval => 
        approval.id === id 
          ? { ...approval, status: action === 'approve' ? 'approved' : 'rejected' }
          : approval
      )
    )
  }

  const tabs = [
    { id: 'general', label: '常规配置', icon: Settings },
    { id: 'features', label: '功能开关', icon: Toggle },
    { id: 'abtesting', label: 'A/B测试管理', icon: TestTube },
    { id: 'performance', label: '性能配置', icon: Activity },
    { id: 'notifications', label: '通知设置', icon: Bell },
    { id: 'security', label: '安全配置', icon: Shield },
    { id: 'permissions', label: '权限管理', icon: UserCheck },
    { id: 'approval', label: '变更审批', icon: FileText },
    { id: 'audit', label: '操作审计', icon: Eye },
    { id: 'database', label: '数据库配置', icon: Database },
    { id: 'users', label: '用户配置', icon: Users }
  ]

  const ToggleSwitch = ({ checked, onChange, label, description }: {
    checked: boolean
    onChange: (value: boolean) => void
    label: string
    description?: string
  }) => (
    <div className="flex items-center justify-between">
      <div>
        <div className="font-medium text-foreground">{label}</div>
        {description && <div className="text-sm text-muted-foreground">{description}</div>}
      </div>
      <label className="relative inline-flex items-center cursor-pointer">
        <input
          type="checkbox"
          checked={checked}
          onChange={(e) => onChange(e.target.checked)}
          className="sr-only peer"
        />
        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
      </label>
    </div>
  )

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">系统配置管理</h1>
          <p className="text-sm text-muted-foreground">集成配置管理、A/B测试和功能开关控制</p>
        </div>
        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-2 px-3 py-2 bg-muted/50 rounded-lg">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span className="text-sm text-muted-foreground">系统正常运行</span>
          </div>
          <button 
            onClick={handleSave}
            className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-primary to-secondary text-primary-foreground rounded-xl hover:shadow-lg hover:shadow-primary/25 transition-all duration-200 font-medium"
          >
            <Save size={18} />
            <span>保存配置</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Sidebar Navigation */}
        <div className="lg:col-span-1">
          <div className="bg-card border border-border rounded-lg p-4 sticky top-6">
            <nav className="space-y-2">
              {tabs.map((tab) => {
                const Icon = tab.icon
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-lg text-left transition-colors text-sm ${
                      activeTab === tab.id
                        ? 'bg-primary/10 text-primary border border-primary/20'
                        : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                    }`}
                  >
                    <Icon size={16} />
                    <span className="font-medium">{tab.label}</span>
                  </button>
                )
              })}
            </nav>
          </div>
        </div>

        {/* Main Content */}
        <div className="lg:col-span-4">
          <div className="bg-card border border-border rounded-lg">
            {/* General Settings */}
            {activeTab === 'general' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Settings className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">常规配置</h2>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        系统名称
                      </label>
                      <input
                        type="text"
                        value={settings.siteName}
                        onChange={(e) => updateSetting('siteName', e.target.value)}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        系统描述
                      </label>
                      <textarea
                        value={settings.siteDescription}
                        onChange={(e) => updateSetting('siteDescription', e.target.value)}
                        rows={3}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        管理员邮箱
                      </label>
                      <input
                        type="email"
                        value={settings.adminEmail}
                        onChange={(e) => updateSetting('adminEmail', e.target.value)}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div className="bg-muted/30 p-4 rounded-lg">
                      <h3 className="font-medium text-foreground mb-3">系统状态</h3>
                      <div className="space-y-3">
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">运行时间</span>
                          <span className="text-sm font-medium">23天 5小时</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">活跃用户</span>
                          <span className="text-sm font-medium">1,234</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">API调用/小时</span>
                          <span className="text-sm font-medium">45,678</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">系统负载</span>
                          <span className="text-sm font-medium text-green-600">正常</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Feature Toggles */}
            {activeTab === 'features' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Toggle className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">功能开关</h2>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-4">
                    <h3 className="font-medium text-foreground">核心功能</h3>
                    <ToggleSwitch
                      checked={settings.abTestingEnabled}
                      onChange={(value) => updateSetting('abTestingEnabled', value)}
                      label="A/B测试系统"
                      description="启用A/B测试功能模块"
                    />
                    <ToggleSwitch
                      checked={settings.analyticsEnabled}
                      onChange={(value) => updateSetting('analyticsEnabled', value)}
                      label="数据分析"
                      description="启用高级数据分析功能"
                    />
                    <ToggleSwitch
                      checked={settings.realTimeMonitoring}
                      onChange={(value) => updateSetting('realTimeMonitoring', value)}
                      label="实时监控"
                      description="启用系统实时监控"
                    />
                    <ToggleSwitch
                      checked={settings.apiLoggingEnabled}
                      onChange={(value) => updateSetting('apiLoggingEnabled', value)}
                      label="API日志记录"
                      description="记录所有API调用详情"
                    />
                  </div>

                  <div className="space-y-4">
                    <h3 className="font-medium text-foreground">性能优化</h3>
                    <ToggleSwitch
                      checked={settings.cacheEnabled}
                      onChange={(value) => updateSetting('cacheEnabled', value)}
                      label="缓存系统"
                      description="启用Redis缓存加速"
                    />
                    <ToggleSwitch
                      checked={settings.webhookNotifications}
                      onChange={(value) => updateSetting('webhookNotifications', value)}
                      label="Webhook通知"
                      description="启用第三方Webhook集成"
                    />

                    <div className="mt-6 p-4 bg-info/10 border border-info/20 rounded-lg">
                      <div className="flex items-start space-x-2">
                        <AlertTriangle className="h-5 w-5 text-info mt-0.5" />
                        <div>
                          <h4 className="font-medium text-foreground">功能开关说明</h4>
                          <p className="text-sm text-muted-foreground mt-1">
                            功能开关允许您动态控制系统功能的启用和禁用，无需重启系统。部分核心功能的变更可能需要管理员审批。
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* A/B Testing Management */}
            {activeTab === 'abtesting' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <TestTube className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">A/B测试管理</h2>
                </div>
                
                {/* A/B Testing Configuration */}
                <div className="grid gap-6 md:grid-cols-3 mb-6">
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      默认样本大小
                    </label>
                    <input
                      type="number"
                      min="100"
                      max="100000"
                      value={settings.abTestingSampleSize}
                      onChange={(e) => updateSetting('abTestingSampleSize', parseInt(e.target.value))}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      置信度水平 (%)
                    </label>
                    <select
                      value={settings.abTestingConfidenceLevel}
                      onChange={(e) => updateSetting('abTestingConfidenceLevel', parseInt(e.target.value))}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    >
                      <option value="90">90%</option>
                      <option value="95">95%</option>
                      <option value="99">99%</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      自动停止测试
                    </label>
                    <div className="mt-3">
                      <ToggleSwitch
                        checked={settings.abTestingAutoStop}
                        onChange={(value) => updateSetting('abTestingAutoStop', value)}
                        label=""
                        description="达到统计显著性后自动停止"
                      />
                    </div>
                  </div>
                </div>

                {/* A/B Test Manager Component */}
                <ABTestManager />
              </div>
            )}

            {/* Performance Configuration */}
            {activeTab === 'performance' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Activity className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">性能配置</h2>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        最大并发用户数
                      </label>
                      <input
                        type="number"
                        min="100"
                        max="100000"
                        value={settings.maxConcurrentUsers}
                        onChange={(e) => updateSetting('maxConcurrentUsers', parseInt(e.target.value))}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        请求超时时间 (秒)
                      </label>
                      <input
                        type="number"
                        min="5"
                        max="300"
                        value={settings.requestTimeout}
                        onChange={(e) => updateSetting('requestTimeout', parseInt(e.target.value))}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        内存限制
                      </label>
                      <select
                        value={settings.memoryLimit}
                        onChange={(e) => updateSetting('memoryLimit', e.target.value)}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      >
                        <option value="1GB">1GB</option>
                        <option value="2GB">2GB</option>
                        <option value="4GB">4GB</option>
                        <option value="8GB">8GB</option>
                      </select>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div className="bg-muted/30 p-4 rounded-lg">
                      <h3 className="font-medium text-foreground mb-3">当前性能指标</h3>
                      <div className="space-y-3">
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">CPU使用率</span>
                          <div className="flex items-center space-x-2">
                            <div className="w-20 h-2 bg-muted rounded-full overflow-hidden">
                              <div className="h-full bg-green-500 w-3/4"></div>
                            </div>
                            <span className="text-sm font-medium">75%</span>
                          </div>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">内存使用</span>
                          <div className="flex items-center space-x-2">
                            <div className="w-20 h-2 bg-muted rounded-full overflow-hidden">
                              <div className="h-full bg-blue-500 w-1/2"></div>
                            </div>
                            <span className="text-sm font-medium">1.2GB</span>
                          </div>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">响应时间</span>
                          <span className="text-sm font-medium text-green-600">120ms</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-muted-foreground">在线用户</span>
                          <span className="text-sm font-medium">1,234</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Change Approval Workflow */}
            {activeTab === 'approval' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <FileText className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">配置变更审批</h2>
                </div>
                
                <div className="grid gap-6">
                  {/* Approval Settings */}
                  <div className="space-y-4">
                    <h3 className="font-medium text-foreground">审批设置</h3>
                    <ToggleSwitch
                      checked={settings.requireApprovalForChanges}
                      onChange={(value) => updateSetting('requireApprovalForChanges', value)}
                      label="配置变更需要审批"
                      description="关键配置变更需要管理员审批"
                    />
                    <ToggleSwitch
                      checked={settings.approvalWorkflowEnabled}
                      onChange={(value) => updateSetting('approvalWorkflowEnabled', value)}
                      label="启用审批工作流"
                      description="使用自定义审批流程"
                    />
                    <ToggleSwitch
                      checked={settings.multiStageApproval}
                      onChange={(value) => updateSetting('multiStageApproval', value)}
                      label="多级审批"
                      description="重要变更需要多人审批"
                    />
                  </div>

                  {/* Pending Approvals */}
                  <div>
                    <h3 className="font-medium text-foreground mb-4">待审批的变更</h3>
                    <div className="space-y-4">
                      {pendingApprovals.filter(a => a.status === 'pending').map(approval => (
                        <div key={approval.id} className="p-4 border border-border rounded-lg">
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <div className="flex items-center space-x-2 mb-2">
                                <span className="px-2 py-1 bg-primary/10 text-primary text-xs rounded-full">
                                  {approval.configType}
                                </span>
                                <span className="text-sm text-muted-foreground">
                                  {approval.requestedAt.toLocaleDateString()}
                                </span>
                              </div>
                              <h4 className="font-medium text-foreground mb-1">{approval.change}</h4>
                              <p className="text-sm text-muted-foreground">
                                请求人: {approval.requestedBy}
                              </p>
                            </div>
                            <div className="flex items-center space-x-2">
                              <button
                                onClick={() => handleApprovalAction(approval.id, 'approve')}
                                className="px-3 py-1 bg-green-100 text-green-700 text-sm rounded-lg hover:bg-green-200 transition-colors"
                              >
                                批准
                              </button>
                              <button
                                onClick={() => handleApprovalAction(approval.id, 'reject')}
                                className="px-3 py-1 bg-red-100 text-red-700 text-sm rounded-lg hover:bg-red-200 transition-colors"
                              >
                                拒绝
                              </button>
                            </div>
                          </div>
                        </div>
                      ))}
                      
                      {pendingApprovals.filter(a => a.status === 'pending').length === 0 && (
                        <div className="text-center py-8 text-muted-foreground">
                          <FileText className="h-12 w-12 mx-auto mb-4 opacity-50" />
                          <p>暂无待审批的配置变更</p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Other tabs using existing settings page content */}
            {activeTab === 'notifications' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Bell className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">通知设置</h2>
                </div>
                
                <div className="space-y-4">
                  <ToggleSwitch
                    checked={settings.emailNotifications}
                    onChange={(value) => updateSetting('emailNotifications', value)}
                    label="邮件通知"
                    description="接收重要事件的邮件通知"
                  />
                  <ToggleSwitch
                    checked={settings.pushNotifications}
                    onChange={(value) => updateSetting('pushNotifications', value)}
                    label="推送通知"
                    description="浏览器推送通知"
                  />
                  <ToggleSwitch
                    checked={settings.smsNotifications}
                    onChange={(value) => updateSetting('smsNotifications', value)}
                    label="短信通知"
                    description="紧急事件的短信通知"
                  />
                </div>
              </div>
            )}

            {activeTab === 'security' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Shield className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">安全配置</h2>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-4">
                    <ToggleSwitch
                      checked={settings.requireTwoFactor}
                      onChange={(value) => updateSetting('requireTwoFactor', value)}
                      label="双因素认证"
                      description="要求管理员启用双因素认证"
                    />
                    
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        密码策略
                      </label>
                      <select
                        value={settings.passwordPolicy}
                        onChange={(e) => updateSetting('passwordPolicy', e.target.value)}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      >
                        <option value="low">低 (最少6位)</option>
                        <option value="medium">中 (8位包含数字和字母)</option>
                        <option value="high">高 (12位包含数字、字母和特殊字符)</option>
                      </select>
                    </div>
                  </div>
                  
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        会话超时 (分钟)
                      </label>
                      <input
                        type="number"
                        min="5"
                        max="480"
                        value={settings.sessionTimeout}
                        onChange={(e) => updateSetting('sessionTimeout', parseInt(e.target.value))}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-foreground mb-2">
                        API速率限制 (次/分钟)
                      </label>
                      <input
                        type="number"
                        min="10"
                        max="1000"
                        value={settings.apiRateLimit}
                        onChange={(e) => updateSetting('apiRateLimit', parseInt(e.target.value))}
                        className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'permissions' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <UserCheck className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">权限管理</h2>
                </div>
                <PermissionManager />
              </div>
            )}

            {activeTab === 'audit' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Eye className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">操作审计</h2>
                </div>
                <AdminAuditLog />
              </div>
            )}

            {activeTab === 'database' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Database className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">数据库配置</h2>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      备份频率
                    </label>
                    <select
                      value={settings.backupFrequency}
                      onChange={(e) => updateSetting('backupFrequency', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    >
                      <option value="hourly">每小时</option>
                      <option value="daily">每天</option>
                      <option value="weekly">每周</option>
                      <option value="monthly">每月</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      数据保留期 (天)
                    </label>
                    <input
                      type="number"
                      min="7"
                      max="365"
                      value={settings.retentionPeriod}
                      onChange={(e) => updateSetting('retentionPeriod', parseInt(e.target.value))}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'users' && (
              <div className="p-6 space-y-6">
                <div className="flex items-center space-x-2 mb-4">
                  <Users className="h-5 w-5 text-primary" />
                  <h2 className="text-lg font-semibold text-foreground">用户配置</h2>
                </div>
                
                <div className="space-y-4">
                  <ToggleSwitch
                    checked={settings.allowUserRegistration}
                    onChange={(value) => updateSetting('allowUserRegistration', value)}
                    label="允许用户注册"
                    description="允许新用户自主注册账户"
                  />
                  <ToggleSwitch
                    checked={settings.requireEmailVerification}
                    onChange={(value) => updateSetting('requireEmailVerification', value)}
                    label="邮箱验证"
                    description="要求新用户验证邮箱地址"
                  />
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      默认用户角色
                    </label>
                    <select
                      value={settings.defaultUserRole}
                      onChange={(e) => updateSetting('defaultUserRole', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    >
                      <option value="member">普通会员</option>
                      <option value="premium">高级会员</option>
                      <option value="guest">访客</option>
                    </select>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}