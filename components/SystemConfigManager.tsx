/**
 * 星趣后台管理系统 - 系统配置管理组件
 * 提供系统参数的灵活配置
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
import { Switch } from '@/components/ui/switch'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Slider } from '@/components/ui/slider'
import {
  Plus,
  Edit,
  Trash2,
  Save,
  Search,
  Filter,
  Settings,
  Database,
  Globe,
  Shield,
  Bell,
  Users,
  Zap,
  RefreshCw,
  Copy,
  History,
  AlertTriangle,
  CheckCircle,
  Eye,
  Download,
  Upload,
  FileText
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

// 类型定义
interface ConfigItem {
  id: string
  key: string
  value: string
  defaultValue: string
  type: 'string' | 'number' | 'boolean' | 'json' | 'select' | 'password'
  category: string
  label: string
  description: string
  options?: string[] // 用于 select 类型
  validation?: {
    required?: boolean
    min?: number
    max?: number
    pattern?: string
  }
  isSystem: boolean
  isSecret: boolean
  lastModified: string
  modifiedBy: string
  version: number
}

interface ConfigCategory {
  id: string
  name: string
  description: string
  icon: React.ElementType
  count: number
}

interface ConfigVersion {
  id: string
  configId: string
  value: string
  version: number
  timestamp: string
  modifiedBy: string
  changeReason?: string
}

interface ConfigValidation {
  isValid: boolean
  errors: string[]
}

export default function SystemConfigManager() {
  const [configs, setConfigs] = useState<ConfigItem[]>([])
  const [categories, setCategories] = useState<ConfigCategory[]>([])
  const [configVersions, setConfigVersions] = useState<ConfigVersion[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedConfig, setSelectedConfig] = useState<ConfigItem | null>(null)
  const [selectedCategory, setSelectedCategory] = useState<string>('all')
  const [isConfigDialogOpen, setIsConfigDialogOpen] = useState(false)
  const [isVersionDialogOpen, setIsVersionDialogOpen] = useState(false)
  const [isImportDialogOpen, setIsImportDialogOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')

  // 表单状态
  const [configForm, setConfigForm] = useState({
    key: '',
    value: '',
    defaultValue: '',
    type: 'string' as ConfigItem['type'],
    category: '',
    label: '',
    description: '',
    options: [] as string[],
    validation: {
      required: false,
      min: undefined as number | undefined,
      max: undefined as number | undefined,
      pattern: ''
    },
    isSecret: false
  })

  const [bulkEditMode, setBulkEditMode] = useState(false)
  const [selectedConfigs, setSelectedConfigs] = useState<string[]>([])
  const [importData, setImportData] = useState('')

  useEffect(() => {
    fetchConfigs()
    fetchCategories()
    fetchConfigVersions()
  }, [])

  const fetchConfigs = async () => {
    try {
      setLoading(true)
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const mockConfigs: ConfigItem[] = [
        // 系统配置
        {
          id: '1',
          key: 'system.site_name',
          value: '星趣社区管理后台',
          defaultValue: '星趣社区管理后台',
          type: 'string',
          category: 'system',
          label: '站点名称',
          description: '显示在页面标题和导航中的站点名称',
          validation: { required: true },
          isSystem: true,
          isSecret: false,
          lastModified: '2025-09-05 14:30:00',
          modifiedBy: 'admin',
          version: 1
        },
        {
          id: '2',
          key: 'system.maintenance_mode',
          value: 'false',
          defaultValue: 'false',
          type: 'boolean',
          category: 'system',
          label: '维护模式',
          description: '启用后系统将显示维护页面，禁止用户访问',
          isSystem: true,
          isSecret: false,
          lastModified: '2025-09-05 14:25:00',
          modifiedBy: 'admin',
          version: 1
        },
        {
          id: '3',
          key: 'system.max_upload_size',
          value: '10',
          defaultValue: '10',
          type: 'number',
          category: 'system',
          label: '最大上传文件大小',
          description: '单个文件最大上传大小（MB）',
          validation: { min: 1, max: 100 },
          isSystem: false,
          isSecret: false,
          lastModified: '2025-09-05 14:20:00',
          modifiedBy: 'admin',
          version: 2
        },
        
        // 安全配置
        {
          id: '4',
          key: 'security.session_timeout',
          value: '30',
          defaultValue: '30',
          type: 'number',
          category: 'security',
          label: '会话超时时间',
          description: '用户会话超时时间（分钟）',
          validation: { min: 5, max: 1440 },
          isSystem: false,
          isSecret: false,
          lastModified: '2025-09-05 14:15:00',
          modifiedBy: 'admin',
          version: 1
        },
        {
          id: '5',
          key: 'security.password_min_length',
          value: '8',
          defaultValue: '6',
          type: 'number',
          category: 'security',
          label: '密码最小长度',
          description: '用户密码的最小长度要求',
          validation: { min: 6, max: 32 },
          isSystem: false,
          isSecret: false,
          lastModified: '2025-09-05 14:10:00',
          modifiedBy: 'admin',
          version: 3
        },
        {
          id: '6',
          key: 'security.jwt_secret',
          value: '***hidden***',
          defaultValue: '',
          type: 'password',
          category: 'security',
          label: 'JWT密钥',
          description: '用于JWT令牌签名的密钥',
          validation: { required: true },
          isSystem: true,
          isSecret: true,
          lastModified: '2025-09-05 14:05:00',
          modifiedBy: 'admin',
          version: 1
        },
        
        // 通知配置
        {
          id: '7',
          key: 'notification.email_enabled',
          value: 'true',
          defaultValue: 'false',
          type: 'boolean',
          category: 'notification',
          label: '邮件通知',
          description: '启用邮件通知功能',
          isSystem: false,
          isSecret: false,
          lastModified: '2025-09-05 14:00:00',
          modifiedBy: 'admin',
          version: 1
        },
        {
          id: '8',
          key: 'notification.smtp_server',
          value: 'smtp.gmail.com',
          defaultValue: '',
          type: 'string',
          category: 'notification',
          label: 'SMTP服务器',
          description: '邮件发送服务器地址',
          validation: { required: true },
          isSystem: false,
          isSecret: false,
          lastModified: '2025-09-05 13:55:00',
          modifiedBy: 'admin',
          version: 1
        },
        
        // AI配置
        {
          id: '9',
          key: 'ai.openai_api_key',
          value: '***hidden***',
          defaultValue: '',
          type: 'password',
          category: 'ai',
          label: 'OpenAI API密钥',
          description: 'OpenAI服务的API密钥',
          validation: { required: true },
          isSystem: false,
          isSecret: true,
          lastModified: '2025-09-05 13:50:00',
          modifiedBy: 'admin',
          version: 1
        },
        {
          id: '10',
          key: 'ai.default_model',
          value: 'gpt-4',
          defaultValue: 'gpt-3.5-turbo',
          type: 'select',
          category: 'ai',
          label: '默认模型',
          description: '默认使用的AI模型',
          options: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'],
          isSystem: false,
          isSecret: false,
          lastModified: '2025-09-05 13:45:00',
          modifiedBy: 'admin',
          version: 2
        }
      ]
      
      setConfigs(mockConfigs)
    } catch (error) {
      console.error('获取配置数据失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchCategories = async () => {
    try {
      const mockCategories: ConfigCategory[] = [
        { id: 'system', name: '系统配置', description: '基础系统参数设置', icon: Settings, count: 0 },
        { id: 'security', name: '安全配置', description: '安全相关参数配置', icon: Shield, count: 0 },
        { id: 'notification', name: '通知配置', description: '消息通知相关配置', icon: Bell, count: 0 },
        { id: 'database', name: '数据库配置', description: '数据库连接和性能配置', icon: Database, count: 0 },
        { id: 'ai', name: 'AI配置', description: 'AI服务相关配置', icon: Zap, count: 0 },
        { id: 'integration', name: '集成配置', description: '第三方服务集成配置', icon: Globe, count: 0 }
      ]
      
      setCategories(mockCategories)
    } catch (error) {
      console.error('获取分类数据失败:', error)
    }
  }

  const fetchConfigVersions = async () => {
    try {
      const mockVersions: ConfigVersion[] = [
        {
          id: '1',
          configId: '3',
          value: '5',
          version: 1,
          timestamp: '2025-09-04 10:00:00',
          modifiedBy: 'admin',
          changeReason: '调整上传限制'
        },
        {
          id: '2',
          configId: '5',
          value: '6',
          version: 1,
          timestamp: '2025-09-04 15:30:00',
          modifiedBy: 'admin',
          changeReason: '初始设置'
        },
        {
          id: '3',
          configId: '5',
          value: '7',
          version: 2,
          timestamp: '2025-09-05 09:15:00',
          modifiedBy: 'admin',
          changeReason: '提高安全性'
        }
      ]
      
      setConfigVersions(mockVersions)
    } catch (error) {
      console.error('获取版本数据失败:', error)
    }
  }

  const saveConfig = async () => {
    try {
      if (selectedConfig) {
        // 更新配置
        const updatedConfigs = configs.map(config => 
          config.id === selectedConfig.id 
            ? { 
                ...selectedConfig, 
                ...configForm, 
                lastModified: new Date().toISOString(),
                modifiedBy: 'current_user',
                version: config.version + 1
              }
            : config
        )
        setConfigs(updatedConfigs)
      } else {
        // 创建新配置
        const newConfig: ConfigItem = {
          id: Date.now().toString(),
          ...configForm,
          isSystem: false,
          lastModified: new Date().toISOString(),
          modifiedBy: 'current_user',
          version: 1
        }
        setConfigs([...configs, newConfig])
      }
      
      resetConfigForm()
      setIsConfigDialogOpen(false)
    } catch (error) {
      console.error('保存配置失败:', error)
    }
  }

  const deleteConfig = async (configId: string) => {
    try {
      const config = configs.find(c => c.id === configId)
      if (config?.isSystem) {
        alert('系统配置不能删除')
        return
      }
      
      setConfigs(configs.filter(config => config.id !== configId))
    } catch (error) {
      console.error('删除配置失败:', error)
    }
  }

  const resetConfigForm = () => {
    setConfigForm({
      key: '',
      value: '',
      defaultValue: '',
      type: 'string',
      category: '',
      label: '',
      description: '',
      options: [],
      validation: {
        required: false,
        min: undefined,
        max: undefined,
        pattern: ''
      },
      isSecret: false
    })
    setSelectedConfig(null)
  }

  const editConfig = (config: ConfigItem) => {
    setSelectedConfig(config)
    setConfigForm({
      key: config.key,
      value: config.value,
      defaultValue: config.defaultValue,
      type: config.type,
      category: config.category,
      label: config.label,
      description: config.description,
      options: config.options || [],
      validation: config.validation || {
        required: false,
        min: undefined,
        max: undefined,
        pattern: ''
      },
      isSecret: config.isSecret
    })
    setIsConfigDialogOpen(true)
  }

  const validateConfig = (config: Partial<ConfigItem>): ConfigValidation => {
    const errors: string[] = []
    
    if (!config.key) {
      errors.push('配置键不能为空')
    }
    
    if (config.validation?.required && !config.value) {
      errors.push('此配置项为必填项')
    }
    
    if (config.type === 'number' && config.value) {
      const numValue = Number(config.value)
      if (isNaN(numValue)) {
        errors.push('数值格式不正确')
      } else {
        if (config.validation?.min !== undefined && numValue < config.validation.min) {
          errors.push(`数值不能小于 ${config.validation.min}`)
        }
        if (config.validation?.max !== undefined && numValue > config.validation.max) {
          errors.push(`数值不能大于 ${config.validation.max}`)
        }
      }
    }
    
    if (config.validation?.pattern && config.value) {
      try {
        const regex = new RegExp(config.validation.pattern)
        if (!regex.test(config.value)) {
          errors.push('格式不匹配规则')
        }
      } catch {
        errors.push('正则表达式格式错误')
      }
    }
    
    return {
      isValid: errors.length === 0,
      errors
    }
  }

  const exportConfigs = () => {
    const exportData = configs.map(config => ({
      key: config.key,
      value: config.isSecret ? '[HIDDEN]' : config.value,
      type: config.type,
      category: config.category,
      label: config.label,
      description: config.description
    }))
    
    const dataStr = JSON.stringify(exportData, null, 2)
    const dataBlob = new Blob([dataStr], { type: 'application/json' })
    const url = URL.createObjectURL(dataBlob)
    
    const link = document.createElement('a')
    link.href = url
    link.download = `system-config-${new Date().toISOString().split('T')[0]}.json`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }

  const importConfigs = async () => {
    try {
      const data = JSON.parse(importData)
      // 这里应该有导入逻辑
      console.log('导入配置:', data)
      setIsImportDialogOpen(false)
      setImportData('')
    } catch (error) {
      console.error('导入配置失败:', error)
      alert('JSON格式错误')
    }
  }

  // 过滤配置
  const filteredConfigs = useMemo(() => {
    return configs.filter(config => {
      const matchesSearch = searchTerm === '' || 
        config.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
        config.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
        config.description.toLowerCase().includes(searchTerm.toLowerCase())
      
      const matchesCategory = selectedCategory === 'all' || config.category === selectedCategory
      
      return matchesSearch && matchesCategory
    })
  }, [configs, searchTerm, selectedCategory])

  // 更新分类计数
  const categoriesWithCount = useMemo(() => {
    return categories.map(category => ({
      ...category,
      count: configs.filter(config => config.category === category.id).length
    }))
  }, [categories, configs])

  const getTypeBadge = (type: string) => {
    const colors = {
      string: 'bg-blue-100 text-blue-700',
      number: 'bg-green-100 text-green-700',
      boolean: 'bg-purple-100 text-purple-700',
      json: 'bg-orange-100 text-orange-700',
      select: 'bg-yellow-100 text-yellow-700',
      password: 'bg-red-100 text-red-700'
    }
    
    const labels = {
      string: '字符串',
      number: '数字',
      boolean: '布尔值',
      json: 'JSON',
      select: '选择',
      password: '密码'
    }
    
    return (
      <Badge className={colors[type as keyof typeof colors] || 'bg-gray-100 text-gray-700'}>
        {labels[type as keyof typeof labels] || type}
      </Badge>
    )
  }

  const renderConfigValue = (config: ConfigItem) => {
    if (config.isSecret) {
      return <span className="text-muted-foreground">***hidden***</span>
    }
    
    switch (config.type) {
      case 'boolean':
        return config.value === 'true' ? '✓ 启用' : '✗ 禁用'
      case 'password':
        return '***hidden***'
      default:
        return config.value || '-'
    }
  }

  const renderConfigInput = () => {
    switch (configForm.type) {
      case 'boolean':
        return (
          <div className="flex items-center space-x-2">
            <Switch
              checked={configForm.value === 'true'}
              onCheckedChange={(checked) => setConfigForm({...configForm, value: checked.toString()})}
            />
            <Label>{configForm.value === 'true' ? '启用' : '禁用'}</Label>
          </div>
        )
      case 'number':
        return (
          <Input
            type="number"
            value={configForm.value}
            onChange={(e) => setConfigForm({...configForm, value: e.target.value})}
            min={configForm.validation.min}
            max={configForm.validation.max}
          />
        )
      case 'select':
        return (
          <Select value={configForm.value} onValueChange={(value) => setConfigForm({...configForm, value})}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {configForm.options.map(option => (
                <SelectItem key={option} value={option}>
                  {option}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )
      case 'json':
        return (
          <Textarea
            value={configForm.value}
            onChange={(e) => setConfigForm({...configForm, value: e.target.value})}
            rows={5}
            className="font-mono"
          />
        )
      case 'password':
        return (
          <Input
            type="password"
            value={configForm.value}
            onChange={(e) => setConfigForm({...configForm, value: e.target.value})}
            placeholder="输入新密码（留空保持不变）"
          />
        )
      default:
        return (
          <Input
            type="text"
            value={configForm.value}
            onChange={(e) => setConfigForm({...configForm, value: e.target.value})}
            placeholder="输入配置值"
          />
        )
    }
  }

  return (
    <div className="space-y-6">
      {/* 统计卡片 */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">配置总数</CardTitle>
            <Settings className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{configs.length}</div>
            <p className="text-xs text-muted-foreground">
              系统配置: {configs.filter(c => c.isSystem).length}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">配置分类</CardTitle>
            <Filter className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{categories.length}</div>
            <p className="text-xs text-muted-foreground">功能模块分类</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">敏感配置</CardTitle>
            <Shield className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">
              {configs.filter(c => c.isSecret).length}
            </div>
            <p className="text-xs text-muted-foreground">需要特殊保护</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">最近更新</CardTitle>
            <RefreshCw className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">
              {configs.filter(c => {
                const lastMod = new Date(c.lastModified)
                const today = new Date()
                return lastMod.toDateString() === today.toDateString()
              }).length}
            </div>
            <p className="text-xs text-muted-foreground">今日更新</p>
          </CardContent>
        </Card>
      </div>

      {/* 主要内容 */}
      <Tabs defaultValue="configs" className="space-y-4">
        <TabsList>
          <TabsTrigger value="configs">配置管理</TabsTrigger>
          <TabsTrigger value="categories">分类管理</TabsTrigger>
          <TabsTrigger value="versions">版本历史</TabsTrigger>
          <TabsTrigger value="import-export">导入导出</TabsTrigger>
        </TabsList>

        {/* 配置管理 */}
        <TabsContent value="configs" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>系统配置管理</CardTitle>
                  <CardDescription>管理系统的各项配置参数</CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <Button variant="outline" onClick={exportConfigs}>
                    <Download className="w-4 h-4 mr-2" />
                    导出
                  </Button>
                  <Dialog open={isConfigDialogOpen} onOpenChange={setIsConfigDialogOpen}>
                    <DialogTrigger asChild>
                      <Button onClick={resetConfigForm}>
                        <Plus className="w-4 h-4 mr-2" />
                        新建配置
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="max-w-2xl">
                      <DialogHeader>
                        <DialogTitle>
                          {selectedConfig ? '编辑配置' : '新建配置'}
                        </DialogTitle>
                        <DialogDescription>
                          配置系统参数的详细信息
                        </DialogDescription>
                      </DialogHeader>
                      
                      <div className="grid gap-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <Label htmlFor="key">配置键</Label>
                            <Input
                              id="key"
                              value={configForm.key}
                              onChange={(e) => setConfigForm({...configForm, key: e.target.value})}
                              placeholder="例如: system.site_name"
                            />
                          </div>
                          <div>
                            <Label htmlFor="label">显示名称</Label>
                            <Input
                              id="label"
                              value={configForm.label}
                              onChange={(e) => setConfigForm({...configForm, label: e.target.value})}
                              placeholder="例如: 站点名称"
                            />
                          </div>
                        </div>
                        
                        <div>
                          <Label htmlFor="description">描述</Label>
                          <Textarea
                            id="description"
                            value={configForm.description}
                            onChange={(e) => setConfigForm({...configForm, description: e.target.value})}
                            placeholder="详细描述此配置项的用途"
                          />
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <Label htmlFor="type">数据类型</Label>
                            <Select value={configForm.type} onValueChange={(value) => setConfigForm({...configForm, type: value as ConfigItem['type']})}>
                              <SelectTrigger>
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="string">字符串</SelectItem>
                                <SelectItem value="number">数字</SelectItem>
                                <SelectItem value="boolean">布尔值</SelectItem>
                                <SelectItem value="json">JSON</SelectItem>
                                <SelectItem value="select">选择项</SelectItem>
                                <SelectItem value="password">密码</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                          <div>
                            <Label htmlFor="category">配置分类</Label>
                            <Select value={configForm.category} onValueChange={(value) => setConfigForm({...configForm, category: value})}>
                              <SelectTrigger>
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                {categories.map(cat => (
                                  <SelectItem key={cat.id} value={cat.id}>
                                    {cat.name}
                                  </SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          </div>
                        </div>
                        
                        <div>
                          <Label htmlFor="value">配置值</Label>
                          {renderConfigInput()}
                        </div>
                        
                        <div>
                          <Label htmlFor="defaultValue">默认值</Label>
                          <Input
                            id="defaultValue"
                            value={configForm.defaultValue}
                            onChange={(e) => setConfigForm({...configForm, defaultValue: e.target.value})}
                            placeholder="配置的默认值"
                          />
                        </div>

                        {configForm.type === 'select' && (
                          <div>
                            <Label>选择项选项</Label>
                            <Textarea
                              value={configForm.options.join('\n')}
                              onChange={(e) => setConfigForm({...configForm, options: e.target.value.split('\n').filter(o => o.trim())})}
                              placeholder="每行一个选项"
                              rows={3}
                            />
                          </div>
                        )}
                        
                        <div className="flex items-center space-x-4">
                          <div className="flex items-center space-x-2">
                            <Switch
                              id="required"
                              checked={configForm.validation.required}
                              onCheckedChange={(checked) => setConfigForm({
                                ...configForm, 
                                validation: {...configForm.validation, required: checked}
                              })}
                            />
                            <Label htmlFor="required">必填项</Label>
                          </div>
                          <div className="flex items-center space-x-2">
                            <Switch
                              id="isSecret"
                              checked={configForm.isSecret}
                              onCheckedChange={(checked) => setConfigForm({...configForm, isSecret: checked})}
                            />
                            <Label htmlFor="isSecret">敏感配置</Label>
                          </div>
                        </div>
                      </div>

                      <DialogFooter>
                        <Button variant="outline" onClick={() => setIsConfigDialogOpen(false)}>
                          取消
                        </Button>
                        <Button onClick={saveConfig}>
                          {selectedConfig ? '更新' : '创建'}
                        </Button>
                      </DialogFooter>
                    </DialogContent>
                  </Dialog>
                </div>
              </div>
              
              {/* 筛选工具栏 */}
              <div className="flex items-center space-x-4">
                <div className="flex items-center space-x-2">
                  <Search className="w-4 h-4 text-muted-foreground" />
                  <Input
                    placeholder="搜索配置项..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-64"
                  />
                </div>
                
                <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="选择分类" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部分类</SelectItem>
                    {categoriesWithCount.map(category => (
                      <SelectItem key={category.id} value={category.id}>
                        {category.name} ({category.count})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                <Button variant="outline" onClick={fetchConfigs} disabled={loading}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  刷新
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>配置键</TableHead>
                    <TableHead>显示名称</TableHead>
                    <TableHead>类型</TableHead>
                    <TableHead>当前值</TableHead>
                    <TableHead>分类</TableHead>
                    <TableHead>最后修改</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredConfigs.map((config) => (
                    <TableRow key={config.id}>
                      <TableCell className="font-mono text-sm">
                        <div className="flex items-center space-x-2">
                          {config.isSystem && <Shield className="w-3 h-3 text-orange-500" />}
                          {config.isSecret && <AlertTriangle className="w-3 h-3 text-red-500" />}
                          <span>{config.key}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium">{config.label}</div>
                          <div className="text-xs text-muted-foreground">{config.description}</div>
                        </div>
                      </TableCell>
                      <TableCell>{getTypeBadge(config.type)}</TableCell>
                      <TableCell>{renderConfigValue(config)}</TableCell>
                      <TableCell>
                        {categories.find(cat => cat.id === config.category)?.name || config.category}
                      </TableCell>
                      <TableCell className="text-sm">
                        <div>{new Date(config.lastModified).toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">v{config.version}</div>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => editConfig(config)}
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {/* 查看历史 */}}
                          >
                            <History className="w-4 h-4" />
                          </Button>
                          {!config.isSystem && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => deleteConfig(config.id)}
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

        {/* 分类管理 */}
        <TabsContent value="categories" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {categoriesWithCount.map(category => {
              const Icon = category.icon
              return (
                <Card key={category.id}>
                  <CardHeader className="pb-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <div className="p-2 bg-primary/10 rounded-lg">
                          <Icon className="w-5 h-5 text-primary" />
                        </div>
                        <div>
                          <CardTitle className="text-base">{category.name}</CardTitle>
                        </div>
                      </div>
                      <Badge variant="outline">{category.count}</Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-muted-foreground">{category.description}</p>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </TabsContent>

        {/* 版本历史 */}
        <TabsContent value="versions" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>配置版本历史</CardTitle>
              <CardDescription>查看配置项的变更历史记录</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>配置项</TableHead>
                    <TableHead>版本</TableHead>
                    <TableHead>变更值</TableHead>
                    <TableHead>变更时间</TableHead>
                    <TableHead>操作者</TableHead>
                    <TableHead>变更原因</TableHead>
                    <TableHead>操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {configVersions.map((version) => {
                    const config = configs.find(c => c.id === version.configId)
                    return (
                      <TableRow key={version.id}>
                        <TableCell>
                          <div>
                            <div className="font-medium">{config?.label}</div>
                            <div className="text-xs text-muted-foreground font-mono">{config?.key}</div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline">v{version.version}</Badge>
                        </TableCell>
                        <TableCell className="font-mono text-sm">{version.value}</TableCell>
                        <TableCell>{new Date(version.timestamp).toLocaleString()}</TableCell>
                        <TableCell>{version.modifiedBy}</TableCell>
                        <TableCell>{version.changeReason || '-'}</TableCell>
                        <TableCell>
                          <Button variant="ghost" size="sm">
                            <Eye className="w-4 h-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* 导入导出 */}
        <TabsContent value="import-export" className="space-y-4">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Download className="w-5 h-5 mr-2" />
                  导出配置
                </CardTitle>
                <CardDescription>将当前系统配置导出为JSON文件</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="text-sm text-muted-foreground">
                    导出的配置文件包含所有非敏感配置项，可用于备份或迁移到其他环境。
                    敏感配置（如密钥）将被标记为 [HIDDEN]。
                  </div>
                  <Button onClick={exportConfigs} className="w-full">
                    <Download className="w-4 h-4 mr-2" />
                    导出所有配置
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Upload className="w-5 h-5 mr-2" />
                  导入配置
                </CardTitle>
                <CardDescription>从JSON文件导入系统配置</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="text-sm text-muted-foreground">
                    请粘贴有效的JSON配置数据。导入前请确认配置的正确性。
                  </div>
                  <Dialog open={isImportDialogOpen} onOpenChange={setIsImportDialogOpen}>
                    <DialogTrigger asChild>
                      <Button variant="outline" className="w-full">
                        <Upload className="w-4 h-4 mr-2" />
                        导入配置
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="max-w-2xl">
                      <DialogHeader>
                        <DialogTitle>导入配置数据</DialogTitle>
                        <DialogDescription>
                          粘贴JSON格式的配置数据
                        </DialogDescription>
                      </DialogHeader>
                      
                      <div className="space-y-4">
                        <Label htmlFor="importData">JSON数据</Label>
                        <Textarea
                          id="importData"
                          value={importData}
                          onChange={(e) => setImportData(e.target.value)}
                          placeholder="粘贴JSON配置数据..."
                          rows={10}
                          className="font-mono"
                        />
                      </div>

                      <DialogFooter>
                        <Button variant="outline" onClick={() => setIsImportDialogOpen(false)}>
                          取消
                        </Button>
                        <Button onClick={importConfigs}>
                          导入配置
                        </Button>
                      </DialogFooter>
                    </DialogContent>
                  </Dialog>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <FileText className="w-5 h-5 mr-2" />
                配置模板
              </CardTitle>
              <CardDescription>常用的配置模板示例</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                <FileText className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <div>配置模板功能</div>
                <div className="text-sm">提供常用配置的模板和示例</div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}