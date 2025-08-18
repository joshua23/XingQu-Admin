import React, { useState, useMemo } from 'react';
import {
  Shield,
  CheckCircle,
  XCircle,
  Clock,
  Eye,
  Flag,
  Filter,
  MoreHorizontal,
  Image,
  FileText,
  Volume2,
  Play
} from 'lucide-react';
import useSWR from 'swr';
import { format } from 'date-fns';
import { dataService } from '@xingqu/shared/src/services/supabase';
import { ContentModerationItem, FeishuContext } from '@xingqu/shared/src/types';

interface ContentModerationComponentProps {
  feishuContext?: FeishuContext;
  className?: string;
}

const ContentModerationComponent: React.FC<ContentModerationComponentProps> = ({
  feishuContext,
  className = ''
}) => {
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [activeFilter, setActiveFilter] = useState<string>('pending');
  const [priorityFilter, setPriorityFilter] = useState<string>('all');
  const [contentTypeFilter, setContentTypeFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 20;

  // 构建查询参数
  const queryParams = useMemo(() => ({
    page: currentPage,
    pageSize,
    status: activeFilter,
    priority: priorityFilter !== 'all' ? priorityFilter : undefined,
    contentType: contentTypeFilter !== 'all' ? contentTypeFilter : undefined
  }), [currentPage, activeFilter, priorityFilter, contentTypeFilter]);

  // 获取待审核内容数据
  const { 
    data: moderationData, 
    error: _error, 
    mutate: refreshContent 
  } = useSWR(
    ['content-moderation', queryParams],
    () => dataService.getComponentData('content_moderation', queryParams)
  );

  // 获取审核统计数据
  const { data: statsData } = useSWR(
    'moderation-stats',
    () => dataService.getComponentData('content_moderation', { type: 'stats' })
  );

  const items = moderationData?.items || [];
  const total = moderationData?.total || 0;
  const stats = statsData || {
    pending: 0,
    approved: 0,
    rejected: 0,
    flagged: 0
  };

  // 状态映射
  const statusMap = {
    pending: { 
      label: '待审核', 
      color: 'text-status-warning', 
      bgColor: 'bg-orange-50', 
      icon: Clock 
    },
    approved: { 
      label: '已通过', 
      color: 'text-status-success', 
      bgColor: 'bg-accent-light', 
      icon: CheckCircle 
    },
    rejected: { 
      label: '已拒绝', 
      color: 'text-status-error', 
      bgColor: 'bg-red-50', 
      icon: XCircle 
    },
    flagged: { 
      label: '已标记', 
      color: 'text-status-info', 
      bgColor: 'bg-blue-50', 
      icon: Flag 
    }
  };

  // 优先级映射
  const priorityMap = {
    low: { label: '低', color: 'text-text-tertiary', bgColor: 'bg-bg-tertiary' },
    medium: { label: '中', color: 'text-status-info', bgColor: 'bg-blue-50' },
    high: { label: '高', color: 'text-status-warning', bgColor: 'bg-orange-50' },
    urgent: { label: '紧急', color: 'text-status-error', bgColor: 'bg-red-50' }
  };

  // 内容类型图标映射
  const contentTypeIcons = {
    text: FileText,
    image: Image,
    audio: Volume2,
    video: Play
  };

  // 处理单个审核操作
  const handleModerationAction = async (itemId: string, action: 'approve' | 'reject' | 'flag', reason?: string) => {
    try {
      await dataService.getComponentData('content_moderation', {
        action,
        itemId,
        reviewerId: feishuContext?.userId,
        reason
      });
      
      refreshContent();
      
      // 记录操作日志
      await dataService.logComponentUsage('content_moderation', action, {
        itemId,
        reviewer: feishuContext?.userId,
        reason
      });
    } catch (error) {
      console.error(`Failed to ${action} content:`, error);
    }
  };

  // 处理批量审核操作
  const handleBatchModeration = async (action: 'approve' | 'reject' | 'flag') => {
    if (selectedItems.length === 0) return;

    try {
      await dataService.getComponentData('content_moderation', {
        action: `batch_${action}`,
        itemIds: selectedItems,
        reviewerId: feishuContext?.userId
      });
      
      refreshContent();
      setSelectedItems([]);
      
      await dataService.logComponentUsage('content_moderation', `batch_${action}`, {
        itemCount: selectedItems.length,
        reviewer: feishuContext?.userId
      });
    } catch (error) {
      console.error(`Failed to batch ${action}:`, error);
    }
  };

  // 渲染内容预览
  const renderContentPreview = (item: ContentModerationItem) => {
    const ContentIcon = contentTypeIcons[item.contentType];
    
    switch (item.contentType) {
      case 'text':
        return (
          <div className="text-sm text-text-secondary line-clamp-3">
            {item.content}
          </div>
        );
      case 'image':
        return (
          <div className="w-16 h-16 bg-bg-tertiary rounded-lg flex items-center justify-center">
            <Image className="w-6 h-6 text-text-tertiary" />
          </div>
        );
      case 'audio':
        return (
          <div className="w-16 h-16 bg-bg-tertiary rounded-lg flex items-center justify-center">
            <Volume2 className="w-6 h-6 text-text-tertiary" />
          </div>
        );
      case 'video':
        return (
          <div className="w-16 h-16 bg-bg-tertiary rounded-lg flex items-center justify-center">
            <Play className="w-6 h-6 text-text-tertiary" />
          </div>
        );
      default:
        return (
          <div className="w-16 h-16 bg-bg-tertiary rounded-lg flex items-center justify-center">
            <ContentIcon className="w-6 h-6 text-text-tertiary" />
          </div>
        );
    }
  };

  return (
    <div className={`min-h-screen bg-bg-secondary ${className}`}>
      {/* 页面头部 */}
      <div className="bg-bg-primary border-b border-border-primary px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary flex items-center">
              <Shield className="w-6 h-6 mr-2 text-accent-primary" />
              内容审核中心
            </h1>
            <p className="text-sm text-text-tertiary mt-1">
              管理和审核用户生成内容 • 总计 {total.toLocaleString()} 条内容
            </p>
          </div>

          {/* 批量操作 */}
          {selectedItems.length > 0 && (
            <div className="flex items-center space-x-3">
              <span className="text-sm text-text-secondary">
                已选择 {selectedItems.length} 条内容
              </span>
              <button
                onClick={() => handleBatchModeration('approve')}
                className="flex items-center px-3 py-2 bg-status-success text-white rounded-lg hover:opacity-80 transition-opacity text-sm"
              >
                <CheckCircle className="w-4 h-4 mr-1" />
                批量通过
              </button>
              <button
                onClick={() => handleBatchModeration('reject')}
                className="flex items-center px-3 py-2 bg-status-error text-white rounded-lg hover:opacity-80 transition-opacity text-sm"
              >
                <XCircle className="w-4 h-4 mr-1" />
                批量拒绝
              </button>
            </div>
          )}
        </div>
      </div>

      {/* 审核状态统计 */}
      <div className="px-6 py-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div 
            className={`bg-bg-primary border rounded-lg p-6 cursor-pointer transition-all ${
              activeFilter === 'pending' ? 'border-status-warning shadow-hover' : 'border-border-primary hover:border-border-focus'
            }`}
            onClick={() => setActiveFilter('pending')}
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-bold text-status-warning">{stats.pending}</h3>
                <p className="text-sm text-text-secondary">待审核</p>
              </div>
              <Clock className="w-8 h-8 text-status-warning opacity-50" />
            </div>
          </div>

          <div 
            className={`bg-bg-primary border rounded-lg p-6 cursor-pointer transition-all ${
              activeFilter === 'approved' ? 'border-status-success shadow-hover' : 'border-border-primary hover:border-border-focus'
            }`}
            onClick={() => setActiveFilter('approved')}
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-bold text-status-success">{stats.approved}</h3>
                <p className="text-sm text-text-secondary">已通过</p>
              </div>
              <CheckCircle className="w-8 h-8 text-status-success opacity-50" />
            </div>
          </div>

          <div 
            className={`bg-bg-primary border rounded-lg p-6 cursor-pointer transition-all ${
              activeFilter === 'rejected' ? 'border-status-error shadow-hover' : 'border-border-primary hover:border-border-focus'
            }`}
            onClick={() => setActiveFilter('rejected')}
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-bold text-status-error">{stats.rejected}</h3>
                <p className="text-sm text-text-secondary">已拒绝</p>
              </div>
              <XCircle className="w-8 h-8 text-status-error opacity-50" />
            </div>
          </div>

          <div 
            className={`bg-bg-primary border rounded-lg p-6 cursor-pointer transition-all ${
              activeFilter === 'flagged' ? 'border-status-info shadow-hover' : 'border-border-primary hover:border-border-focus'
            }`}
            onClick={() => setActiveFilter('flagged')}
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-bold text-status-info">{stats.flagged}</h3>
                <p className="text-sm text-text-secondary">已标记</p>
              </div>
              <Flag className="w-8 h-8 text-status-info opacity-50" />
            </div>
          </div>
        </div>

        {/* 筛选工具栏 */}
        <div className="bg-bg-primary border border-border-primary rounded-lg p-4 mb-6">
          <div className="flex items-center justify-between space-x-4">
            <div className="flex items-center space-x-4">
              {/* 优先级筛选 */}
              <div className="flex items-center space-x-2">
                <Filter className="w-4 h-4 text-text-tertiary" />
                <select
                  value={priorityFilter}
                  onChange={(e) => setPriorityFilter(e.target.value)}
                  className="px-3 py-2 border border-border-primary rounded-lg text-sm bg-bg-primary"
                >
                  <option value="all">全部优先级</option>
                  <option value="urgent">紧急</option>
                  <option value="high">高</option>
                  <option value="medium">中</option>
                  <option value="low">低</option>
                </select>
              </div>

              {/* 内容类型筛选 */}
              <select
                value={contentTypeFilter}
                onChange={(e) => setContentTypeFilter(e.target.value)}
                className="px-3 py-2 border border-border-primary rounded-lg text-sm bg-bg-primary"
              >
                <option value="all">全部类型</option>
                <option value="text">文本</option>
                <option value="image">图片</option>
                <option value="audio">音频</option>
                <option value="video">视频</option>
              </select>
            </div>

            <div className="text-sm text-text-tertiary">
              当前筛选: {statusMap[activeFilter as keyof typeof statusMap]?.label} • 共 {total} 条
            </div>
          </div>
        </div>

        {/* 内容列表 */}
        <div className="bg-bg-primary border border-border-primary rounded-lg overflow-hidden shadow-card">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-bg-secondary border-b border-border-secondary">
                <tr>
                  <th className="px-4 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedItems.length === items.length && items.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedItems(items.map((item: ContentModerationItem) => item.id));
                        } else {
                          setSelectedItems([]);
                        }
                      }}
                      className="rounded border-border-primary text-accent-primary focus:ring-accent-primary"
                    />
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    内容信息
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    优先级
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    AI评分
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    状态
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    创建时间
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    操作
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-secondary">
                {items.map((item: ContentModerationItem) => (
                  <tr key={item.id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-4 py-4">
                      <input
                        type="checkbox"
                        checked={selectedItems.includes(item.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedItems([...selectedItems, item.id]);
                          } else {
                            setSelectedItems(selectedItems.filter(id => id !== item.id));
                          }
                        }}
                        className="rounded border-border-primary text-accent-primary focus:ring-accent-primary"
                      />
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-start space-x-3">
                        {renderContentPreview(item)}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center space-x-2">
                            {React.createElement(contentTypeIcons[item.contentType], {
                              className: "w-4 h-4 text-text-tertiary"
                            })}
                            <span className="text-sm font-medium text-text-primary">
                              {item.contentType.toUpperCase()} 内容
                            </span>
                          </div>
                          <p className="text-sm text-text-tertiary mt-1">
                            ID: {item.contentId} • 作者: {item.authorId}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${priorityMap[item.priority].bgColor} ${priorityMap[item.priority].color}`}>
                        {priorityMap[item.priority].label}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center space-x-2">
                        <div className="w-16 bg-bg-tertiary rounded-full h-2">
                          <div 
                            className="h-2 rounded-full bg-accent-primary"
                            style={{ width: `${item.aiScore}%` }}
                          ></div>
                        </div>
                        <span className="text-sm font-medium text-text-primary">
                          {item.aiScore}%
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${statusMap[item.status].bgColor} ${statusMap[item.status].color}`}>
                        {React.createElement(statusMap[item.status].icon, {
                          className: "w-3 h-3 mr-1"
                        })}
                        {statusMap[item.status].label}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="text-sm">
                        <p className="text-text-primary">
                          {format(new Date(item.createdAt), 'MM/dd HH:mm')}
                        </p>
                        {item.reviewedAt && (
                          <p className="text-text-tertiary">
                            审核于 {format(new Date(item.reviewedAt), 'MM/dd HH:mm')}
                          </p>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center space-x-2">
                        {item.status === 'pending' && (
                          <>
                            <button
                              onClick={() => handleModerationAction(item.id, 'approve')}
                              className="p-1 text-text-tertiary hover:text-status-success hover:bg-green-50 rounded transition-colors"
                              title="通过审核"
                            >
                              <CheckCircle className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => handleModerationAction(item.id, 'reject')}
                              className="p-1 text-text-tertiary hover:text-status-error hover:bg-red-50 rounded transition-colors"
                              title="拒绝审核"
                            >
                              <XCircle className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => handleModerationAction(item.id, 'flag')}
                              className="p-1 text-text-tertiary hover:text-status-warning hover:bg-orange-50 rounded transition-colors"
                              title="标记内容"
                            >
                              <Flag className="w-4 h-4" />
                            </button>
                          </>
                        )}
                        <button className="p-1 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded transition-colors">
                          <MoreHorizontal className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* 分页 */}
          {total > pageSize && (
            <div className="px-6 py-4 border-t border-border-secondary">
              <div className="flex items-center justify-between">
                <div className="text-sm text-text-tertiary">
                  显示 {((currentPage - 1) * pageSize) + 1} 到 {Math.min(currentPage * pageSize, total)} 条，共 {total} 条记录
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                    disabled={currentPage === 1}
                    className="px-3 py-1 border border-border-primary rounded text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-bg-hover"
                  >
                    上一页
                  </button>
                  <span className="text-sm text-text-secondary">
                    {currentPage} / {Math.ceil(total / pageSize)}
                  </span>
                  <button
                    onClick={() => setCurrentPage(Math.min(Math.ceil(total / pageSize), currentPage + 1))}
                    disabled={currentPage === Math.ceil(total / pageSize)}
                    className="px-3 py-1 border border-border-primary rounded text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-bg-hover"
                  >
                    下一页
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ContentModerationComponent;