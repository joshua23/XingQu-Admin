/**
 * 星趣后台管理系统 - 告警管理组件
 * 管理系统告警的显示、确认和解决
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  Search, 
  Filter,
  Activity,
  Info,
  X
} from 'lucide-react'
import type { SystemAlert, AlertType } from '@/lib/types/admin'

interface AlertManagerProps {
  alerts: SystemAlert[]
  onAcknowledge: (alertId: string) => Promise<void>
  onResolve: (alertId: string) => Promise<void>
  loading?: boolean
}

export default function AlertManager({
  alerts,
  onAcknowledge,
  onResolve,
  loading = false
}: AlertManagerProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedType, setSelectedType] = useState<string>('all')
  const [selectedStatus, setSelectedStatus] = useState<string>('all')
  const [activeTab, setActiveTab] = useState('all')

  // 过滤和搜索告警
  const filteredAlerts = useMemo(() => {
    let filtered = alerts

    // 按状态筛选
    if (activeTab !== 'all') {
      filtered = filtered.filter(alert => alert.status === activeTab)
    }

    // 按类型筛选
    if (selectedType !== 'all') {
      filtered = filtered.filter(alert => alert.type === selectedType)
    }

    // 搜索过滤
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(alert =>
        alert.title.toLowerCase().includes(query) ||
        alert.message.toLowerCase().includes(query) ||
        alert.metricName?.toLowerCase().includes(query)
      )
    }

    // 按时间排序（最新的在前面）
    return filtered.sort((a, b) => 
      new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    )
  }, [alerts, activeTab, selectedType, searchQuery])

  // 获取告警统计
  const alertStats = useMemo(() => {
    const stats = {
      total: alerts.length,
      active: alerts.filter(a => a.status === 'active').length,
      acknowledged: alerts.filter(a => a.status === 'acknowledged').length,
      resolved: alerts.filter(a => a.status === 'resolved').length,
      critical: alerts.filter(a => a.type === 'error').length,
      warning: alerts.filter(a => a.type === 'warning').length,
    }
    return stats
  }, [alerts])

  // 获取告警图标
  const getAlertIcon = (type: AlertType) => {
    switch (type) {
      case 'error':
        return <AlertTriangle className="h-4 w-4 text-red-500" />
      case 'warning':
        return <AlertTriangle className="h-4 w-4 text-yellow-500" />
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />
      case 'info':
        return <Info className="h-4 w-4 text-blue-500" />
      default:
        return <Activity className="h-4 w-4 text-gray-500" />
    }
  }

  // 获取告警颜色
  const getAlertColor = (type: AlertType) => {
    switch (type) {
      case 'error':
        return 'border-red-200 bg-red-50'
      case 'warning':
        return 'border-yellow-200 bg-yellow-50'
      case 'success':
        return 'border-green-200 bg-green-50'
      case 'info':
        return 'border-blue-200 bg-blue-50'
      default:
        return 'border-gray-200 bg-gray-50'
    }
  }

  // 获取状态徽章
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge variant="destructive" className="text-xs">活跃</Badge>
      case 'acknowledged':
        return <Badge variant="outline" className="text-xs">已确认</Badge>
      case 'resolved':
        return <Badge variant="default" className="text-xs">已解决</Badge>
      default:
        return <Badge variant="secondary" className="text-xs">{status}</Badge>
    }
  }

  // 渲染告警项
  const renderAlert = (alert: SystemAlert) => (
    <Alert key={alert.id} className={`mb-3 ${getAlertColor(alert.type)}`}>
      <div className="flex items-start justify-between">
        <div className="flex items-start gap-3 flex-1">
          {getAlertIcon(alert.type)}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2 mb-1">
              <h4 className="text-sm font-medium leading-5">{alert.title}</h4>
              {getStatusBadge(alert.status)}
            </div>
            
            <AlertDescription className="text-sm text-gray-600 mb-2">
              {alert.message}
            </AlertDescription>

            {/* 指标信息 */}
            {alert.metricName && (
              <div className="flex items-center gap-4 text-xs text-muted-foreground mb-2">
                <span>指标: <span className="font-mono">{alert.metricName}</span></span>
                {alert.currentValue && alert.thresholdValue && (
                  <>
                    <span>当前值: <span className="font-mono">{alert.currentValue}</span></span>
                    <span>阈值: <span className="font-mono">{alert.thresholdValue}</span></span>
                  </>
                )}
              </div>
            )}

            {/* 时间信息 */}
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Clock className="h-3 w-3" />
              <span>创建: {new Date(alert.timestamp).toLocaleString()}</span>
              {alert.acknowledgedAt && (
                <span>确认: {new Date(alert.acknowledgedAt).toLocaleString()}</span>
              )}
              {alert.resolvedAt && (
                <span>解决: {new Date(alert.resolvedAt).toLocaleString()}</span>
              )}
            </div>
          </div>
        </div>

        {/* 操作按钮 */}
        <div className="flex gap-1 ml-4 flex-shrink-0">
          {alert.status === 'active' && (
            <>
              <Button
                variant="outline"
                size="sm"
                className="h-7 px-2 text-xs"
                onClick={() => onAcknowledge(alert.id)}
                disabled={loading}
              >
                确认
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="h-7 px-2 text-xs"
                onClick={() => onResolve(alert.id)}
                disabled={loading}
              >
                解决
              </Button>
            </>
          )}
          {alert.status === 'acknowledged' && (
            <Button
              variant="outline"
              size="sm"
              className="h-7 px-2 text-xs"
              onClick={() => onResolve(alert.id)}
              disabled={loading}
            >
              解决
            </Button>
          )}
        </div>
      </div>
    </Alert>
  )

  return (
    <div className="space-y-6">
      {/* 头部统计 */}
      <div className="grid grid-cols-2 md:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-blue-600">{alertStats.total}</div>
            <p className="text-xs text-muted-foreground">总告警数</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-red-600">{alertStats.active}</div>
            <p className="text-xs text-muted-foreground">活跃告警</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-yellow-600">{alertStats.acknowledged}</div>
            <p className="text-xs text-muted-foreground">已确认</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-green-600">{alertStats.resolved}</div>
            <p className="text-xs text-muted-foreground">已解决</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-red-500">{alertStats.critical}</div>
            <p className="text-xs text-muted-foreground">严重告警</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-yellow-500">{alertStats.warning}</div>
            <p className="text-xs text-muted-foreground">警告告警</p>
          </CardContent>
        </Card>
      </div>

      {/* 筛选和搜索 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Filter className="h-5 w-5" />
            告警筛选
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center gap-2">
              <Search className="h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="搜索告警标题、消息或指标..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-64"
              />
            </div>
            <Select value={selectedType} onValueChange={setSelectedType}>
              <SelectTrigger className="w-32">
                <SelectValue placeholder="告警类型" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">所有类型</SelectItem>
                <SelectItem value="error">错误</SelectItem>
                <SelectItem value="warning">警告</SelectItem>
                <SelectItem value="info">信息</SelectItem>
                <SelectItem value="success">成功</SelectItem>
              </SelectContent>
            </Select>
            {(searchQuery || selectedType !== 'all') && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setSearchQuery('')
                  setSelectedType('all')
                }}
              >
                <X className="h-4 w-4 mr-1" />
                清除筛选
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* 告警列表 */}
      <Card>
        <CardHeader>
          <CardTitle>告警列表</CardTitle>
          <CardDescription>
            显示 {filteredAlerts.length} 条告警，共 {alertStats.total} 条
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="all">
                全部 ({alertStats.total})
              </TabsTrigger>
              <TabsTrigger value="active">
                活跃 ({alertStats.active})
              </TabsTrigger>
              <TabsTrigger value="acknowledged">
                已确认 ({alertStats.acknowledged})
              </TabsTrigger>
              <TabsTrigger value="resolved">
                已解决 ({alertStats.resolved})
              </TabsTrigger>
            </TabsList>

            <TabsContent value={activeTab} className="mt-4">
              {loading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Card key={i} className="animate-pulse">
                      <CardContent className="p-4">
                        <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                        <div className="h-3 bg-gray-200 rounded w-full mb-2"></div>
                        <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : filteredAlerts.length === 0 ? (
                <Card>
                  <CardContent className="flex items-center justify-center py-12">
                    <div className="text-center">
                      <CheckCircle className="h-12 w-12 text-green-500 mx-auto mb-4" />
                      <h3 className="text-lg font-medium text-green-600 mb-2">
                        {activeTab === 'all' ? '没有告警' : `没有${activeTab === 'active' ? '活跃' : activeTab === 'acknowledged' ? '已确认' : '已解决'}的告警`}
                      </h3>
                      <p className="text-muted-foreground">
                        {searchQuery ? '没有符合搜索条件的告警' : '系统运行正常'}
                      </p>
                    </div>
                  </CardContent>
                </Card>
              ) : (
                <div className="space-y-2">
                  {filteredAlerts.map(renderAlert)}
                </div>
              )}
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  )
}