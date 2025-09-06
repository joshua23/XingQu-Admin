/**
 * 星趣后台管理系统 - 内容审核页面
 * 集成AI智能审核、用户举报处理和统计分析
 * Created: 2025-09-05
 * Updated: 2025-09-05 - 集成AI审核和举报处理组件
 */

'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { AlertTriangle, BarChart3, Bot, Flag, Shield, Users, Clock, CheckCircle, XCircle } from 'lucide-react'
import AIContentModeration from '@/components/AIContentModeration'
import UserReportHandler from '@/components/UserReportHandler'
import ContentModerationDashboard from '@/components/moderation/ContentModerationDashboard'

interface ModerationStats {
  totalReviewed: number
  pendingReview: number
  aiProcessed: number
  humanReviewed: number
  reportsReceived: number
  reportsResolved: number
  violationsFound: number
  appealsPending: number
}

export default function ModerationPage() {
  const [stats, setStats] = useState<ModerationStats>({
    totalReviewed: 0,
    pendingReview: 0,
    aiProcessed: 0,
    humanReviewed: 0,
    reportsReceived: 0,
    reportsResolved: 0,
    violationsFound: 0,
    appealsPending: 0
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchModerationStats()
  }, [])

  const fetchModerationStats = async () => {
    try {
      setLoading(true)
      // 模拟API调用获取审核统计数据
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setStats({
        totalReviewed: 15420,
        pendingReview: 234,
        aiProcessed: 12890,
        humanReviewed: 2530,
        reportsReceived: 456,
        reportsResolved: 398,
        violationsFound: 89,
        appealsPending: 12
      })
    } catch (error) {
      console.error('获取审核统计失败:', error)
    } finally {
      setLoading(false)
    }
  }

  const StatCard = ({ 
    title, 
    value, 
    description, 
    icon: Icon, 
    color = "default" 
  }: {
    title: string
    value: number | string
    description: string
    icon: React.ElementType
    color?: "default" | "success" | "warning" | "danger"
  }) => (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className={`h-4 w-4 ${
          color === 'success' ? 'text-green-600' :
          color === 'warning' ? 'text-yellow-600' :
          color === 'danger' ? 'text-red-600' :
          'text-muted-foreground'
        }`} />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value.toLocaleString()}</div>
        <p className="text-xs text-muted-foreground">{description}</p>
      </CardContent>
    </Card>
  )

  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        {/* 页面标题 */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">内容审核中心</h1>
            <p className="text-muted-foreground">
              AI智能审核、用户举报处理和内容安全管理
            </p>
          </div>
          <div className="flex items-center space-x-2">
            <Badge variant="outline" className="text-green-600">
              <CheckCircle className="w-3 h-3 mr-1" />
              系统正常
            </Badge>
            <Button onClick={fetchModerationStats} disabled={loading}>
              <BarChart3 className="w-4 h-4 mr-2" />
              刷新统计
            </Button>
          </div>
        </div>

        {/* 统计卡片 */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="待审核内容"
            value={stats.pendingReview}
            description="需要人工审核"
            icon={Clock}
            color="warning"
          />
          <StatCard
            title="AI已处理"
            value={stats.aiProcessed}
            description="自动审核通过"
            icon={Bot}
            color="success"
          />
          <StatCard
            title="用户举报"
            value={stats.reportsReceived}
            description={`已解决 ${stats.reportsResolved} 个`}
            icon={Flag}
            color={stats.reportsReceived > stats.reportsResolved ? "warning" : "default"}
          />
          <StatCard
            title="违规内容"
            value={stats.violationsFound}
            description="本月发现"
            icon={AlertTriangle}
            color="danger"
          />
        </div>

        {/* 主要内容区域 */}
        <Tabs defaultValue="ai-moderation" className="space-y-4">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="ai-moderation" className="flex items-center">
              <Bot className="w-4 h-4 mr-2" />
              AI审核
            </TabsTrigger>
            <TabsTrigger value="reports" className="flex items-center">
              <Flag className="w-4 h-4 mr-2" />
              用户举报
            </TabsTrigger>
            <TabsTrigger value="dashboard" className="flex items-center">
              <Shield className="w-4 h-4 mr-2" />
              审核面板
            </TabsTrigger>
            <TabsTrigger value="analytics" className="flex items-center">
              <BarChart3 className="w-4 h-4 mr-2" />
              数据分析
            </TabsTrigger>
          </TabsList>

          <TabsContent value="ai-moderation" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Bot className="w-5 h-5 mr-2" />
                  AI智能审核系统
                </CardTitle>
                <CardDescription>
                  自动检测和处理违规内容，支持文本、图片、音频和视频审核
                </CardDescription>
              </CardHeader>
              <CardContent>
                <AIContentModeration />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="reports" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Flag className="w-5 h-5 mr-2" />
                  用户举报处理中心
                </CardTitle>
                <CardDescription>
                  处理用户举报、分配审核员和跟踪处理进度
                </CardDescription>
              </CardHeader>
              <CardContent>
                <UserReportHandler />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="dashboard" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Shield className="w-5 h-5 mr-2" />
                  内容审核面板
                </CardTitle>
                <CardDescription>
                  综合内容审核管理和监控面板
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ContentModerationDashboard />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="analytics" className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle>审核效率统计</CardTitle>
                  <CardDescription>AI和人工审核的处理效率对比</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <Bot className="w-4 h-4 mr-2 text-blue-600" />
                        <span>AI自动审核</span>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold">{stats.aiProcessed.toLocaleString()}</div>
                        <div className="text-sm text-muted-foreground">
                          {((stats.aiProcessed / stats.totalReviewed) * 100).toFixed(1)}%
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <Users className="w-4 h-4 mr-2 text-green-600" />
                        <span>人工审核</span>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold">{stats.humanReviewed.toLocaleString()}</div>
                        <div className="text-sm text-muted-foreground">
                          {((stats.humanReviewed / stats.totalReviewed) * 100).toFixed(1)}%
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>举报处理统计</CardTitle>
                  <CardDescription>用户举报的处理情况和趋势</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <span>总举报数</span>
                      <Badge variant="outline">{stats.reportsReceived}</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>已解决</span>
                      <Badge variant="outline" className="text-green-600">
                        {stats.reportsResolved}
                      </Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>处理中</span>
                      <Badge variant="outline" className="text-yellow-600">
                        {stats.reportsReceived - stats.reportsResolved}
                      </Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>解决率</span>
                      <Badge variant="outline" className="text-blue-600">
                        {((stats.reportsResolved / stats.reportsReceived) * 100).toFixed(1)}%
                      </Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle>安全威胁概览</CardTitle>
                <CardDescription>近期发现的安全威胁和处理状态</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid gap-4 md:grid-cols-3">
                  <div className="text-center p-4 border rounded-lg">
                    <AlertTriangle className="w-8 h-8 mx-auto mb-2 text-red-600" />
                    <div className="font-semibold text-2xl">{stats.violationsFound}</div>
                    <div className="text-sm text-muted-foreground">违规内容</div>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <Clock className="w-8 h-8 mx-auto mb-2 text-yellow-600" />
                    <div className="font-semibold text-2xl">{stats.appealsPending}</div>
                    <div className="text-sm text-muted-foreground">待处理申诉</div>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <CheckCircle className="w-8 h-8 mx-auto mb-2 text-green-600" />
                    <div className="font-semibold text-2xl">
                      {stats.totalReviewed - stats.violationsFound}
                    </div>
                    <div className="text-sm text-muted-foreground">安全内容</div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}