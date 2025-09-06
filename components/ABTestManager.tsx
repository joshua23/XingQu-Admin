'use client'

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { AnalyticsChart } from './AnalyticsChart';
import { cn } from '../lib/utils';
import { 
  Plus, 
  Play, 
  Pause, 
  Stop, 
  Settings, 
  BarChart3, 
  Users, 
  Target,
  Clock,
  TrendingUp,
  AlertTriangle,
  CheckCircle,
  Edit3,
  Trash2,
  PieChart
} from 'lucide-react';

interface ABTestVariant {
  id: string;
  name: string;
  description: string;
  trafficAllocation: number; // 0-100
  conversionRate?: number;
  participants?: number;
  isControl: boolean;
}

interface ABTest {
  id: string;
  name: string;
  description: string;
  status: 'draft' | 'running' | 'paused' | 'completed' | 'stopped';
  startDate?: Date;
  endDate?: Date;
  variants: ABTestVariant[];
  targetMetric: string;
  minSampleSize: number;
  confidenceLevel: number;
  statisticalSignificance?: number;
  winner?: string;
  createdAt: Date;
  updatedAt: Date;
}

interface ABTestManagerProps {
  className?: string;
}

const mockTests: ABTest[] = [
  {
    id: '1',
    name: '首页按钮颜色测试',
    description: '测试不同颜色按钮对点击率的影响',
    status: 'running',
    startDate: new Date('2024-01-15'),
    endDate: new Date('2024-02-15'),
    variants: [
      {
        id: 'v1',
        name: '蓝色按钮（对照组）',
        description: '原始蓝色按钮设计',
        trafficAllocation: 50,
        conversionRate: 3.2,
        participants: 1250,
        isControl: true
      },
      {
        id: 'v2',
        name: '红色按钮',
        description: '改为红色按钮设计',
        trafficAllocation: 50,
        conversionRate: 4.1,
        participants: 1180,
        isControl: false
      }
    ],
    targetMetric: '按钮点击率',
    minSampleSize: 1000,
    confidenceLevel: 95,
    statisticalSignificance: 92,
    createdAt: new Date('2024-01-10'),
    updatedAt: new Date('2024-01-20')
  },
  {
    id: '2',
    name: '注册流程优化',
    description: '简化注册步骤对转化率的影响',
    status: 'completed',
    startDate: new Date('2024-01-01'),
    endDate: new Date('2024-01-31'),
    variants: [
      {
        id: 'v1',
        name: '传统三步注册',
        description: '原有的三步注册流程',
        trafficAllocation: 33,
        conversionRate: 12.5,
        participants: 2100,
        isControl: true
      },
      {
        id: 'v2',
        name: '两步注册',
        description: '简化为两步注册',
        trafficAllocation: 34,
        conversionRate: 18.3,
        participants: 2200,
        isControl: false
      },
      {
        id: 'v3',
        name: '一步注册',
        description: '极简一步注册',
        trafficAllocation: 33,
        conversionRate: 15.7,
        participants: 2050,
        isControl: false
      }
    ],
    targetMetric: '注册转化率',
    minSampleSize: 2000,
    confidenceLevel: 95,
    statisticalSignificance: 98,
    winner: 'v2',
    createdAt: new Date('2023-12-20'),
    updatedAt: new Date('2024-02-01')
  }
];

export const ABTestManager: React.FC<ABTestManagerProps> = ({ className }) => {
  const [tests, setTests] = useState<ABTest[]>(mockTests);
  const [selectedTest, setSelectedTest] = useState<ABTest | null>(null);
  const [isCreatingTest, setIsCreatingTest] = useState(false);
  const [activeTab, setActiveTab] = useState<'overview' | 'tests' | 'analytics'>('overview');

  const getStatusBadge = (status: ABTest['status']) => {
    const statusConfig = {
      draft: { label: '草稿', color: 'bg-gray-100 text-gray-600 border-gray-300' },
      running: { label: '运行中', color: 'bg-green-100 text-green-700 border-green-300' },
      paused: { label: '已暂停', color: 'bg-yellow-100 text-yellow-700 border-yellow-300' },
      completed: { label: '已完成', color: 'bg-blue-100 text-blue-700 border-blue-300' },
      stopped: { label: '已停止', color: 'bg-red-100 text-red-700 border-red-300' }
    };

    const config = statusConfig[status];
    return (
      <Badge className={cn('text-xs font-medium border', config.color)}>
        {config.label}
      </Badge>
    );
  };

  const getStatusIcon = (status: ABTest['status']) => {
    switch (status) {
      case 'draft': return <Edit3 size={16} className="text-gray-500" />;
      case 'running': return <Play size={16} className="text-green-500" />;
      case 'paused': return <Pause size={16} className="text-yellow-500" />;
      case 'completed': return <CheckCircle size={16} className="text-blue-500" />;
      case 'stopped': return <Stop size={16} className="text-red-500" />;
      default: return null;
    }
  };

  const runningTests = tests.filter(test => test.status === 'running');
  const completedTests = tests.filter(test => test.status === 'completed');
  const totalParticipants = tests.reduce((sum, test) => 
    sum + test.variants.reduce((varSum, variant) => varSum + (variant.participants || 0), 0), 0
  );

  const OverviewTab = () => (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {/* 统计卡片 */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">总测试数</CardTitle>
          <BarChart3 className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{tests.length}</div>
          <p className="text-xs text-muted-foreground">
            {runningTests.length} 个运行中
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">总参与用户</CardTitle>
          <Users className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{totalParticipants.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground">
            跨 {tests.length} 个测试
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">平均提升率</CardTitle>
          <TrendingUp className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">+28%</div>
          <p className="text-xs text-muted-foreground">
            基于已完成测试
          </p>
        </CardContent>
      </Card>

      {/* 运行中的测试 */}
      <div className="md:col-span-2 lg:col-span-3">
        <Card>
          <CardHeader>
            <CardTitle>运行中的测试</CardTitle>
            <CardDescription>当前正在进行的A/B测试</CardDescription>
          </CardHeader>
          <CardContent>
            {runningTests.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <Target className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>暂无运行中的测试</p>
              </div>
            ) : (
              <div className="space-y-4">
                {runningTests.map(test => (
                  <div key={test.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex-1">
                      <div className="flex items-center space-x-2 mb-2">
                        <h3 className="font-semibold">{test.name}</h3>
                        {getStatusBadge(test.status)}
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">{test.description}</p>
                      <div className="flex items-center space-x-4 text-xs text-muted-foreground">
                        <span>目标指标: {test.targetMetric}</span>
                        <span>置信度: {test.confidenceLevel}%</span>
                        {test.statisticalSignificance && (
                          <span>显著性: {test.statisticalSignificance}%</span>
                        )}
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setSelectedTest(test)}
                    >
                      查看详情
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );

  const TestsTab = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-xl font-semibold">测试管理</h2>
          <p className="text-sm text-muted-foreground">管理所有A/B测试</p>
        </div>
        <Button onClick={() => setIsCreatingTest(true)}>
          <Plus className="h-4 w-4 mr-2" />
          创建测试
        </Button>
      </div>

      <div className="grid gap-4">
        {tests.map(test => (
          <Card key={test.id} className="transition-all hover:shadow-md">
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-2 mb-2">
                    {getStatusIcon(test.status)}
                    <CardTitle className="text-lg">{test.name}</CardTitle>
                    {getStatusBadge(test.status)}
                  </div>
                  <CardDescription className="mb-3">{test.description}</CardDescription>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <span className="text-muted-foreground">变体数量:</span>
                      <span className="ml-1 font-medium">{test.variants.length}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">目标指标:</span>
                      <span className="ml-1 font-medium">{test.targetMetric}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">参与用户:</span>
                      <span className="ml-1 font-medium">
                        {test.variants.reduce((sum, v) => sum + (v.participants || 0), 0).toLocaleString()}
                      </span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">置信度:</span>
                      <span className="ml-1 font-medium">{test.confidenceLevel}%</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2 ml-4">
                  <Button variant="outline" size="sm" onClick={() => setSelectedTest(test)}>
                    查看
                  </Button>
                  <Button variant="outline" size="sm">
                    <Settings className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">变体表现对比</span>
                  {test.winner && (
                    <Badge className="bg-green-100 text-green-700">
                      获胜变体: {test.variants.find(v => v.id === test.winner)?.name}
                    </Badge>
                  )}
                </div>
                <div className="grid gap-2">
                  {test.variants.map(variant => (
                    <div key={variant.id} className="flex items-center justify-between p-2 bg-muted/30 rounded">
                      <div className="flex-1">
                        <div className="flex items-center space-x-2">
                          <span className="font-medium text-sm">{variant.name}</span>
                          {variant.isControl && (
                            <Badge variant="outline" className="text-xs">对照组</Badge>
                          )}
                        </div>
                        <div className="text-xs text-muted-foreground mt-1">
                          流量分配: {variant.trafficAllocation}%
                        </div>
                      </div>
                      <div className="text-right">
                        {variant.conversionRate && (
                          <div className="text-sm font-medium">
                            {variant.conversionRate}%
                          </div>
                        )}
                        <div className="text-xs text-muted-foreground">
                          {variant.participants?.toLocaleString()} 用户
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );

  const AnalyticsTab = () => {
    const conversionData = [
      { label: '1月1日', value: 12.5 },
      { label: '1月8日', value: 14.2 },
      { label: '1月15日', value: 15.8 },
      { label: '1月22日', value: 17.1 },
      { label: '1月29日', value: 18.3 }
    ];

    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-semibold">测试分析</h2>
          <p className="text-sm text-muted-foreground">查看A/B测试的详细数据分析</p>
        </div>
        
        <div className="grid gap-6">
          <AnalyticsChart
            title="整体转化率趋势"
            description="所有测试的平均转化率变化"
            data={conversionData}
            type="line"
            color="primary"
          />
          
          <div className="grid md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>测试状态分布</CardTitle>
                <CardDescription>各状态测试数量统计</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {Object.entries({
                    running: { count: runningTests.length, label: '运行中', color: 'bg-green-500' },
                    completed: { count: completedTests.length, label: '已完成', color: 'bg-blue-500' },
                    draft: { count: tests.filter(t => t.status === 'draft').length, label: '草稿', color: 'bg-gray-500' },
                    paused: { count: tests.filter(t => t.status === 'paused').length, label: '暂停', color: 'bg-yellow-500' }
                  }).map(([key, { count, label, color }]) => (
                    <div key={key} className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <div className={cn('w-3 h-3 rounded-full', color)} />
                        <span className="text-sm">{label}</span>
                      </div>
                      <span className="font-medium">{count}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>成功率统计</CardTitle>
                <CardDescription>测试效果表现</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">显著提升</span>
                    <span className="text-lg font-bold text-green-600">67%</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">无显著差异</span>
                    <span className="text-lg font-bold text-gray-600">25%</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">显著下降</span>
                    <span className="text-lg font-bold text-red-600">8%</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className={cn('space-y-6', className)}>
      {/* 头部导航 */}
      <div className="border-b">
        <div className="flex space-x-8">
          {[
            { key: 'overview', label: '概览', icon: BarChart3 },
            { key: 'tests', label: '测试管理', icon: Target },
            { key: 'analytics', label: '数据分析', icon: PieChart }
          ].map(({ key, label, icon: Icon }) => (
            <button
              key={key}
              onClick={() => setActiveTab(key as any)}
              className={cn(
                'flex items-center space-x-2 pb-3 px-1 border-b-2 transition-colors',
                activeTab === key
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground'
              )}
            >
              <Icon size={16} />
              <span>{label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* 内容区域 */}
      {activeTab === 'overview' && <OverviewTab />}
      {activeTab === 'tests' && <TestsTab />}
      {activeTab === 'analytics' && <AnalyticsTab />}

      {/* 测试详情弹窗 */}
      {selectedTest && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <CardHeader>
              <div className="flex items-start justify-between">
                <div>
                  <CardTitle className="text-xl">{selectedTest.name}</CardTitle>
                  <CardDescription className="mt-2">{selectedTest.description}</CardDescription>
                </div>
                <Button variant="outline" onClick={() => setSelectedTest(null)}>
                  关闭
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-6">
                <div className="grid md:grid-cols-3 gap-4">
                  <div>
                    <Label className="text-sm font-medium">状态</Label>
                    <div className="mt-1">{getStatusBadge(selectedTest.status)}</div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">目标指标</Label>
                    <div className="mt-1 text-sm">{selectedTest.targetMetric}</div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">置信度</Label>
                    <div className="mt-1 text-sm">{selectedTest.confidenceLevel}%</div>
                  </div>
                </div>

                <div>
                  <Label className="text-sm font-medium mb-3 block">变体详情</Label>
                  <div className="space-y-3">
                    {selectedTest.variants.map(variant => (
                      <div key={variant.id} className="p-4 border rounded-lg">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-2 mb-2">
                              <h4 className="font-medium">{variant.name}</h4>
                              {variant.isControl && (
                                <Badge variant="outline" className="text-xs">对照组</Badge>
                              )}
                            </div>
                            <p className="text-sm text-muted-foreground mb-3">{variant.description}</p>
                            <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                              <div>
                                <span className="text-muted-foreground">流量分配:</span>
                                <span className="ml-1 font-medium">{variant.trafficAllocation}%</span>
                              </div>
                              {variant.participants && (
                                <div>
                                  <span className="text-muted-foreground">参与用户:</span>
                                  <span className="ml-1 font-medium">{variant.participants.toLocaleString()}</span>
                                </div>
                              )}
                              {variant.conversionRate && (
                                <div>
                                  <span className="text-muted-foreground">转化率:</span>
                                  <span className="ml-1 font-medium">{variant.conversionRate}%</span>
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {selectedTest.statisticalSignificance && (
                  <div className="p-4 bg-muted/30 rounded-lg">
                    <div className="flex items-center space-x-2 mb-2">
                      <CheckCircle className="h-5 w-5 text-green-500" />
                      <h4 className="font-medium">统计显著性</h4>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      当前测试结果的统计显著性达到 {selectedTest.statisticalSignificance}%，
                      {selectedTest.statisticalSignificance >= 95 ? '结果可信度高' : '建议继续收集数据'}
                    </p>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
};

export default ABTestManager;