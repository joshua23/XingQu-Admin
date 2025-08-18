import React, { useState, useMemo } from 'react';
import {
  Users,
  Search,
  Download,
  Plus,
  MoreHorizontal,
  Edit,
  Shield,
  Ban,
  Star,
  Calendar,
  Phone
} from 'lucide-react';
import useSWR from 'swr';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { format } from 'date-fns';
import { dataService } from '@xingqu/shared/src/services/supabase';
import { User, FeishuContext, SortConfig } from '@xingqu/shared/src/types';

interface UserManagementComponentProps {
  feishuContext?: FeishuContext;
  className?: string;
}

// 筛选表单Schema
const filterSchema = z.object({
  search: z.string().optional(),
  membershipLevel: z.enum(['all', 'free', 'basic', 'premium', 'lifetime']).default('all'),
  dateRange: z.enum(['all', '24h', '7d', '30d']).default('all'),
  status: z.enum(['all', 'active', 'inactive']).default('all')
});

type FilterFormData = z.infer<typeof filterSchema>;

const UserManagementComponent: React.FC<UserManagementComponentProps> = ({
  feishuContext,
  className = ''
}) => {
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [sortConfig, setSortConfig] = useState<SortConfig>({
    field: 'createdAt',
    direction: 'desc'
  });
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 20;

  // 筛选表单
  const filterForm = useForm<FilterFormData>({
    resolver: zodResolver(filterSchema),
    defaultValues: {
      search: '',
      membershipLevel: 'all',
      dateRange: 'all',
      status: 'all'
    }
  });

  const filters = filterForm.watch();

  // 构建查询参数
  const queryParams = useMemo(() => {
    const params: any = {
      page: currentPage,
      pageSize,
      sort: sortConfig
    };

    if (filters.search) {
      params.search = filters.search;
    }
    
    if (filters.membershipLevel !== 'all') {
      params.membershipLevel = filters.membershipLevel;
    }
    
    if (filters.dateRange !== 'all') {
      params.dateRange = filters.dateRange;
    }
    
    if (filters.status !== 'all') {
      params.status = filters.status;
    }

    return params;
  }, [currentPage, sortConfig, filters]);

  // 获取用户列表数据
  const { 
    data: userData, 
    error: _error, 
    mutate: refreshUsers 
  } = useSWR(
    ['users', queryParams],
    () => dataService.getComponentData('user_management', queryParams)
  );

  const users = userData?.items || [];
  const total = userData?.total || 0;

  // 会员等级映射
  const membershipLevelMap = {
    free: { label: '免费用户', color: 'text-text-tertiary', bgColor: 'bg-bg-tertiary' },
    basic: { label: '基础会员', color: 'text-status-info', bgColor: 'bg-blue-50' },
    premium: { label: '高级会员', color: 'text-status-warning', bgColor: 'bg-orange-50' },
    lifetime: { label: '终身会员', color: 'text-status-success', bgColor: 'bg-accent-light' }
  };

  // 处理排序
  const handleSort = (field: string) => {
    setSortConfig(prev => ({
      field,
      direction: prev.field === field && prev.direction === 'asc' ? 'desc' : 'asc'
    }));
  };

  // 处理用户操作
  const handleUserAction = async (userId: string, action: string) => {
    try {
      await dataService.getComponentData('user_management', {
        action,
        userId,
        operatorId: feishuContext?.userId
      });
      
      refreshUsers();
      
      // 记录操作日志
      await dataService.logComponentUsage('user_management', action, {
        userId,
        operator: feishuContext?.userId
      });
    } catch (error) {
      console.error(`Failed to ${action} user:`, error);
    }
  };

  // 处理批量操作
  const handleBatchAction = async (action: string) => {
    if (selectedUsers.length === 0) return;

    try {
      await dataService.getComponentData('user_management', {
        action: `batch_${action}`,
        userIds: selectedUsers,
        operatorId: feishuContext?.userId
      });
      
      refreshUsers();
      setSelectedUsers([]);
      
      await dataService.logComponentUsage('user_management', `batch_${action}`, {
        userCount: selectedUsers.length,
        operator: feishuContext?.userId
      });
    } catch (error) {
      console.error(`Failed to batch ${action}:`, error);
    }
  };

  // 导出用户数据
  const handleExportUsers = async () => {
    try {
      const exportData = users.map((user: User) => ({
        用户ID: user.id,
        昵称: user.nickname,
        手机号: user.phone,
        会员等级: membershipLevelMap[user.membershipLevel as keyof typeof membershipLevelMap].label,
        注册时间: format(new Date(user.createdAt), 'yyyy-MM-dd HH:mm:ss'),
        最后活跃: format(new Date(user.lastSeenAt), 'yyyy-MM-dd HH:mm:ss'),
        星点余额: user.starPointsBalance,
        总消费: user.totalSpent
      }));

      const csvContent = [
        Object.keys(exportData[0]).join(','),
        ...exportData.map((row: any) => Object.values(row).join(','))
      ].join('\n');

      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `users-${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      await dataService.logComponentUsage('user_management', 'export', {
        userCount: users.length,
        filters: queryParams
      });
    } catch (error) {
      console.error('Export failed:', error);
    }
  };

  return (
    <div className={`min-h-screen bg-bg-secondary ${className}`}>
      {/* 页面头部 */}
      <div className="bg-bg-primary border-b border-border-primary px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary flex items-center">
              <Users className="w-6 h-6 mr-2 text-accent-primary" />
              用户管理中心
            </h1>
            <p className="text-sm text-text-tertiary mt-1">
              管理和分析用户数据 • 总计 {total.toLocaleString()} 用户
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <button
              onClick={handleExportUsers}
              className="flex items-center px-3 py-2 border border-border-primary rounded-lg hover:bg-bg-hover transition-colors text-sm"
            >
              <Download className="w-4 h-4 mr-1" />
              导出数据
            </button>
            
            <button className="flex items-center px-3 py-2 bg-accent-primary text-white rounded-lg hover:bg-accent-hover transition-colors text-sm">
              <Plus className="w-4 h-4 mr-1" />
              添加用户
            </button>
          </div>
        </div>
      </div>

      {/* 筛选工具栏 */}
      <div className="bg-bg-primary border-b border-border-secondary px-6 py-4">
        <div className="flex items-center justify-between space-x-4">
          <div className="flex items-center space-x-4 flex-1">
            {/* 搜索框 */}
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-text-tertiary w-4 h-4" />
              <input
                type="text"
                placeholder="搜索用户昵称或手机号..."
                className="pl-10 pr-4 py-2 w-full border border-border-primary rounded-lg focus:ring-2 focus:ring-accent-primary focus:border-transparent"
                {...filterForm.register('search')}
              />
            </div>

            {/* 会员等级筛选 */}
            <select
              className="px-3 py-2 border border-border-primary rounded-lg text-sm bg-bg-primary"
              {...filterForm.register('membershipLevel')}
            >
              <option value="all">全部等级</option>
              <option value="free">免费用户</option>
              <option value="basic">基础会员</option>
              <option value="premium">高级会员</option>
              <option value="lifetime">终身会员</option>
            </select>

            {/* 时间范围筛选 */}
            <select
              className="px-3 py-2 border border-border-primary rounded-lg text-sm bg-bg-primary"
              {...filterForm.register('dateRange')}
            >
              <option value="all">全部时间</option>
              <option value="24h">最近24小时</option>
              <option value="7d">最近7天</option>
              <option value="30d">最近30天</option>
            </select>
          </div>

          {/* 批量操作 */}
          {selectedUsers.length > 0 && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-text-secondary">
                已选择 {selectedUsers.length} 个用户
              </span>
              <button
                onClick={() => handleBatchAction('activate')}
                className="px-3 py-1 text-sm bg-status-success text-white rounded hover:opacity-80"
              >
                激活
              </button>
              <button
                onClick={() => handleBatchAction('deactivate')}
                className="px-3 py-1 text-sm bg-status-warning text-white rounded hover:opacity-80"
              >
                停用
              </button>
              <button
                onClick={() => handleBatchAction('upgrade')}
                className="px-3 py-1 text-sm bg-accent-primary text-white rounded hover:bg-accent-hover"
              >
                升级
              </button>
            </div>
          )}
        </div>
      </div>

      {/* 用户列表表格 */}
      <div className="px-6 py-6">
        <div className="bg-bg-primary border border-border-primary rounded-lg overflow-hidden shadow-card">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-bg-secondary border-b border-border-secondary">
                <tr>
                  <th className="px-4 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedUsers.length === users.length && users.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedUsers(users.map((u: User) => u.id));
                        } else {
                          setSelectedUsers([]);
                        }
                      }}
                      className="rounded border-border-primary text-accent-primary focus:ring-accent-primary"
                    />
                  </th>
                  <th 
                    className="px-4 py-3 text-left text-sm font-semibold text-text-secondary cursor-pointer hover:text-text-primary"
                    onClick={() => handleSort('nickname')}
                  >
                    用户信息
                  </th>
                  <th 
                    className="px-4 py-3 text-left text-sm font-semibold text-text-secondary cursor-pointer hover:text-text-primary"
                    onClick={() => handleSort('membershipLevel')}
                  >
                    会员等级
                  </th>
                  <th 
                    className="px-4 py-3 text-left text-sm font-semibold text-text-secondary cursor-pointer hover:text-text-primary"
                    onClick={() => handleSort('totalSpent')}
                  >
                    消费数据
                  </th>
                  <th 
                    className="px-4 py-3 text-left text-sm font-semibold text-text-secondary cursor-pointer hover:text-text-primary"
                    onClick={() => handleSort('lastSeenAt')}
                  >
                    活跃状态
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-text-secondary">
                    操作
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-secondary">
                {users.map((user: User) => (
                  <tr key={user.id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-4 py-4">
                      <input
                        type="checkbox"
                        checked={selectedUsers.includes(user.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedUsers([...selectedUsers, user.id]);
                          } else {
                            setSelectedUsers(selectedUsers.filter(id => id !== user.id));
                          }
                        }}
                        className="rounded border-border-primary text-accent-primary focus:ring-accent-primary"
                      />
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-accent-light rounded-full flex items-center justify-center">
                          {user.avatar ? (
                            <img src={user.avatar} alt={user.nickname} className="w-10 h-10 rounded-full" />
                          ) : (
                            <Users className="w-5 h-5 text-accent-primary" />
                          )}
                        </div>
                        <div>
                          <p className="font-medium text-text-primary">{user.nickname}</p>
                          <p className="text-sm text-text-tertiary flex items-center">
                            <Phone className="w-3 h-3 mr-1" />
                            {user.phone}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${membershipLevelMap[user.membershipLevel].bgColor} ${membershipLevelMap[user.membershipLevel].color}`}>
                        {user.membershipLevel === 'lifetime' && <Star className="w-3 h-3 mr-1" />}
                        {membershipLevelMap[user.membershipLevel].label}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="text-sm">
                        <p className="font-medium text-text-primary">¥{user.totalSpent.toLocaleString()}</p>
                        <p className="text-text-tertiary">{user.starPointsBalance} 星点</p>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="text-sm">
                        <p className="text-text-primary">
                          {format(new Date(user.lastSeenAt), 'MM/dd HH:mm')}
                        </p>
                        <p className="text-text-tertiary flex items-center">
                          <Calendar className="w-3 h-3 mr-1" />
                          注册 {format(new Date(user.createdAt), 'yyyy/MM/dd')}
                        </p>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => handleUserAction(user.id, 'edit')}
                          className="p-1 text-text-tertiary hover:text-accent-primary hover:bg-accent-background rounded transition-colors"
                          title="编辑用户"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleUserAction(user.id, 'view_profile')}
                          className="p-1 text-text-tertiary hover:text-status-info hover:bg-blue-50 rounded transition-colors"
                          title="查看详情"
                        >
                          <Shield className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleUserAction(user.id, 'ban')}
                          className="p-1 text-text-tertiary hover:text-status-error hover:bg-red-50 rounded transition-colors"
                          title="封禁用户"
                        >
                          <Ban className="w-4 h-4" />
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

export default UserManagementComponent;