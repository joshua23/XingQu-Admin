import React, { useState, useEffect } from 'react';
import { MetricCard } from '../components/MetricCard';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { DataTable, type TableColumn } from '../components/DataTable';
import { contentService } from '../services/contentService';
import { 
  ContentItem, 
  ContentStatus, 
  ContentPriority, 
  ContentCategory,
  ModerationStats,
  ContentFilter
} from '../types/content';
import {
  Shield,
  CheckCircle,
  XCircle,
  Flag,
  Clock,
  Search,
  RefreshCw,
  Eye,
  MessageSquare,
  Image,
  Video,
  Link,
  User,
  TrendingUp,
  Activity
} from 'lucide-react';

const ContentModeration: React.FC = () => {
  const [contentItems, setContentItems] = useState<ContentItem[]>([]);
  const [stats, setStats] = useState<ModerationStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<ContentFilter>({});
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);

  // 加载数据
  const loadData = async () => {
    try {
      setLoading(true);
      
      const [contentResult, statsResult] = await Promise.all([
        contentService.getContentItems(filter, currentPage, 20),
        contentService.getModerationStats('24h')
      ]);

      if (contentResult) {
        setContentItems(contentResult.data);
      }

      if (statsResult.data) {
        setStats(statsResult.data);
      }
    } catch (error) {
      console.error('加载数据失败:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [filter, currentPage]);

  // 状态映射
  const getStatusBadge = (status: ContentStatus) => {
    const statusMap = {
      [ContentStatus.PENDING]: { label: '待审核', variant: 'secondary' as const },
      [ContentStatus.APPROVED]: { label: '已通过', variant: 'success' as const },
      [ContentStatus.REJECTED]: { label: '已拒绝', variant: 'destructive' as const },
      [ContentStatus.FLAGGED]: { label: '已标记', variant: 'warning' as const },
      [ContentStatus.ESCALATED]: { label: '已升级', variant: 'destructive' as const },
      [ContentStatus.REVIEWING]: { label: '审核中', variant: 'secondary' as const }
    };

    const config = statusMap[status] || { label: status, variant: 'secondary' as const };
    return <Badge variant={config.variant}>{config.label}</Badge>;
  };

  // 优先级映射
  const getPriorityBadge = (priority: ContentPriority) => {
    const priorityMap = {
      [ContentPriority.LOW]: { label: '低', color: 'text-blue-600 bg-blue-100' },
      [ContentPriority.MEDIUM]: { label: '中', color: 'text-yellow-600 bg-yellow-100' },
      [ContentPriority.HIGH]: { label: '高', color: 'text-orange-600 bg-orange-100' },
      [ContentPriority.URGENT]: { label: '紧急', color: 'text-red-600 bg-red-100' }
    };

    const config = priorityMap[priority] || { label: priority, color: 'text-gray-600 bg-gray-100' };
    return (
      <span className={`px-2 py-1 text-xs rounded-full ${config.color}`}>
        {config.label}
      </span>
    );
  };

  // 内容类型图标
  const getContentTypeIcon = (type: string) => {
    const iconMap = {
      'text': <MessageSquare size={16} />,
      'image': <Image size={16} />,
      'video': <Video size={16} />,
      'link': <Link size={16} />,
      'user_profile': <User size={16} />
    };
    return iconMap[type as keyof typeof iconMap] || <MessageSquare size={16} />;
  };

  // 处理内容审核
  const handleModeration = async (contentId: string, action: string, reason?: string) => {
    try {
      const result = await contentService.moderateContent(contentId, action, reason, 'current_admin');
      if (result.success) {
        loadData(); // 重新加载数据
      }
    } catch (error) {
      console.error('审核操作失败:', error);
    }
  };

  // 批量处理
  const handleBatchModeration = async (action: string, reason?: string) => {
    if (selectedItems.length === 0) return;

    try {
      const result = await contentService.batchModerateContent({
        content_ids: selectedItems,
        action,
        reason
      }, 'current_admin');

      if (result.success) {
        setSelectedItems([]);
        loadData();
      }
    } catch (error) {
      console.error('批量操作失败:', error);
    }
  };

  // 表格列配置
  const columns: TableColumn[] = [
    {
      key: 'select',
      label: (
        <input
          type="checkbox"
          onChange={(e) => {
            if (e.target.checked) {
              setSelectedItems(contentItems.map(item => item.id));
            } else {
              setSelectedItems([]);
            }
          }}
          checked={selectedItems.length === contentItems.length && contentItems.length > 0}
        />
      ),
      width: '50px',
      render: (_value, row: any) => (
        <input
          type="checkbox"
          checked={selectedItems.includes(row.id)}
          onChange={(e) => {
            if (e.target.checked) {
              setSelectedItems(prev => [...prev, row.id]);
            } else {
              setSelectedItems(prev => prev.filter(id => id !== row.id));
            }
          }}
        />
      )
    },
    { 
      key: 'content_type', 
      label: '类型', 
      width: '80px',
      render: (value: any) => (
        <div className="flex items-center justify-center text-muted-foreground">
          {getContentTypeIcon(value)}
        </div>
      )
    },
    { 
      key: 'content_text', 
      label: '内容', 
      width: '300px',
      render: (value: any, row: any) => (
        <div className="max-w-xs">
          <p className="text-sm text-foreground truncate">
            {value || row.content_url || '无文本内容'}
          </p>
          <p className="text-xs text-muted-foreground">
            用户: {row.user_nickname || 'Unknown'}
          </p>
        </div>
      )
    },
    { 
      key: 'status', 
      label: '状态', 
      width: '100px',
      render: (value: any) => getStatusBadge(value)
    },
    { 
      key: 'priority', 
      label: '优先级', 
      width: '80px',
      render: (value: any) => getPriorityBadge(value)
    },
    { 
      key: 'category', 
      label: '分类', 
      width: '100px',
      render: (value: any) => {
        const categoryMap = {
          [ContentCategory.SPAM]: '垃圾信息',
          [ContentCategory.HARASSMENT]: '骚扰',
          [ContentCategory.HATE_SPEECH]: '仇恨言论',
          [ContentCategory.VIOLENCE]: '暴力内容',
          [ContentCategory.ADULT_CONTENT]: '成人内容',
          [ContentCategory.OTHER]: '其他'
        };
        return <span className="text-sm">{categoryMap[value as keyof typeof categoryMap] || value}</span>;
      }
    },
    { 
      key: 'submitted_at', 
      label: '提交时间', 
      width: '120px',
      render: (value: any) => new Date(value).toLocaleString('zh-CN', {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    {
      key: 'actions',
      label: '操作',
      width: '200px',
      render: (_value: any, row: any) => (
        <div className="flex items-center space-x-2">
          <button
            onClick={() => handleModeration(row.id, 'approved')}
            className="p-1 text-green-600 hover:text-green-800"
            title="通过"
          >
            <CheckCircle size={16} />
          </button>
          <button
            onClick={() => handleModeration(row.id, 'rejected')}
            className="p-1 text-red-600 hover:text-red-800"
            title="拒绝"
          >
            <XCircle size={16} />
          </button>
          <button
            onClick={() => handleModeration(row.id, 'flagged')}
            className="p-1 text-yellow-600 hover:text-yellow-800"
            title="标记"
          >
            <Flag size={16} />
          </button>
          <button
            onClick={() => {/* 打开详情模态框 */}}
            className="p-1 text-blue-600 hover:text-blue-800"
            title="查看详情"
          >
            <Eye size={16} />
          </button>
        </div>
      )
    }
  ];

  // 统计指标
  const overviewMetrics = stats ? [
    {
      title: '待处理',
      value: stats.pendingItems,
      change: 0,
      changeLabel: '需要处理',
      icon: <Clock size={20} />,
      color: 'warning' as const,
      description: '等待审核的内容'
    },
    {
      title: '今日处理',
      value: stats.todayProcessed,
      change: 15.2,
      changeLabel: '较昨日',
      icon: <Activity size={20} />,
      color: 'success' as const,
      description: '今日已处理内容数量'
    },
    {
      title: '平均响应',
      value: `${stats.avgResponseTime}分钟`,
      change: -8.3,
      changeLabel: '较昨日',
      icon: <TrendingUp size={20} />,
      color: 'primary' as const,
      description: '平均审核响应时间'
    },
    {
      title: 'AI准确率',
      value: `${stats.aiAccuracy}%`,
      change: 2.1,
      changeLabel: '本周提升',
      icon: <Shield size={20} />,
      color: 'default' as const,
      description: 'AI预审核准确率'
    }
  ] : [];

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">内容审核</h1>
          <p className="text-muted-foreground mt-1">管理和审核用户提交的内容</p>
        </div>
        <div className="flex items-center space-x-3">
          {selectedItems.length > 0 && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-muted-foreground">
                已选中 {selectedItems.length} 项
              </span>
              <button
                onClick={() => handleBatchModeration('approved')}
                className="px-3 py-2 bg-green-500 hover:bg-green-600 text-white text-sm rounded-lg"
              >
                批量通过
              </button>
              <button
                onClick={() => handleBatchModeration('rejected')}
                className="px-3 py-2 bg-red-500 hover:bg-red-600 text-white text-sm rounded-lg"
              >
                批量拒绝
              </button>
            </div>
          )}
          <button
            onClick={loadData}
            disabled={loading}
            className="flex items-center space-x-2 px-4 py-2 bg-secondary hover:bg-secondary/80 text-secondary-foreground rounded-lg"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>刷新</span>
          </button>
        </div>
      </div>

      {/* 概览指标 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {overviewMetrics.map((metric, index) => (
          <MetricCard key={index} {...metric} />
        ))}
      </div>

      {/* 内容审核主界面 */}
      <Card>
        <CardHeader>
          <CardTitle>审核工作台</CardTitle>
          <CardDescription>查看和处理需要审核的内容</CardDescription>
        </CardHeader>
        <CardContent>
          {/* 搜索和筛选 */}
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="flex-1">
              <div className="relative">
                <Search size={20} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
                <input
                  type="text"
                  placeholder="搜索内容或用户..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-background border border-input rounded-lg"
                />
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <select
                value={filter.status?.[0] || ''}
                onChange={(e) => setFilter(prev => ({ 
                  ...prev, 
                  status: e.target.value ? [e.target.value as ContentStatus] : undefined 
                }))}
                className="px-3 py-2 bg-background border border-input rounded-lg"
              >
                <option value="">全部状态</option>
                <option value="pending">待审核</option>
                <option value="flagged">已标记</option>
                <option value="escalated">已升级</option>
              </select>
              <select
                value={filter.priority?.[0] || ''}
                onChange={(e) => setFilter(prev => ({ 
                  ...prev, 
                  priority: e.target.value ? [e.target.value as ContentPriority] : undefined 
                }))}
                className="px-3 py-2 bg-background border border-input rounded-lg"
              >
                <option value="">全部优先级</option>
                <option value="urgent">紧急</option>
                <option value="high">高</option>
                <option value="medium">中</option>
                <option value="low">低</option>
              </select>
            </div>
          </div>

          {/* 内容列表 */}
          <DataTable
            title="待审核内容"
            columns={columns}
            data={contentItems}
          />
        </CardContent>
      </Card>
    </div>
  );
};

export default ContentModeration;