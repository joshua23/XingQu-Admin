import React, { useEffect, useState } from 'react';
import { 
  Users, 
  TrendingUp, 
  DollarSign, 
  Activity,
  Calendar,
  Filter,
  Download
} from 'lucide-react';
import useSWR from 'swr';
import MetricCard from '@xingqu/shared/src/components/ui/MetricCard';
import ChartContainer from '@xingqu/shared/src/components/charts/ChartContainer';
import UserGrowthChart from '@xingqu/shared/src/components/charts/UserGrowthChart';
import { 
  metricsService, 
  dataService 
} from '@xingqu/shared/src/services/supabase';
import { 
  TimeSeriesData,
  FeishuContext 
} from '@xingqu/shared/src/types';

interface DashboardComponentProps {
  feishuContext?: FeishuContext;
  className?: string;
  autoRefresh?: boolean;
  refreshInterval?: number;
}

const DashboardComponent: React.FC<DashboardComponentProps> = ({
  feishuContext,
  className = '',
  autoRefresh = true,
  refreshInterval = 30000 // 30秒
}) => {
  const [timeRange, setTimeRange] = useState<'24h' | '7d' | '30d'>('7d');
  const [realTimeData, setRealTimeData] = useState<any>(null);

  // 获取实时指标数据
  const { data: metrics, error: metricsError, mutate: refreshMetrics } = useSWR(
    'realtime-metrics',
    () => metricsService.getRealTimeMetrics([
      'dau', 'new_users_today', 'conversion_rate', 'daily_revenue', 'active_rate'
    ]),
    { 
      refreshInterval: autoRefresh ? refreshInterval : 0,
      revalidateOnFocus: false
    }
  );

  // 获取用户增长趋势数据
  const { data: userGrowthData, error: growthError } = useSWR(
    ['user-growth', timeRange],
    () => dataService.getComponentData('dashboard', { 
      type: 'user_growth_trend',
      timeRange 
    }),
    { refreshInterval: autoRefresh ? refreshInterval : 0 }
  );

  // 获取用户分析数据
  const { data: userAnalytics, error: analyticsError } = useSWR(
    'user-analytics',
    () => dataService.getComponentData('dashboard', { 
      type: 'user_analytics' 
    }),
    { refreshInterval: autoRefresh ? refreshInterval : 0 }
  );

  // 设置实时数据订阅
  useEffect(() => {
    if (!autoRefresh) return;

    const subscription = metricsService.subscribeToMetrics((newMetrics) => {
      setRealTimeData(newMetrics);
      refreshMetrics(); // 触发SWR重新获取
    });

    return () => {
      subscription?.unsubscribe();
    };
  }, [autoRefresh, refreshMetrics]);

  // 记录组件使用日志
  useEffect(() => {
    dataService.logComponentUsage('dashboard', 'view', {
      timeRange,
      feishuUserId: feishuContext?.userId
    });
  }, [timeRange, feishuContext]);

  // 处理导出功能
  const handleExportData = async () => {
    try {
      const exportData = {
        metrics,
        userGrowthData,
        userAnalytics,
        exportedAt: new Date().toISOString(),
        exportedBy: feishuContext?.userId
      };

      const blob = new Blob([JSON.stringify(exportData, null, 2)], {
        type: 'application/json'
      });
      
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `dashboard-data-${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      // 记录导出操作
      await dataService.logComponentUsage('dashboard', 'export', {
        dataTypes: ['metrics', 'userGrowth', 'analytics'],
        timeRange
      });
    } catch (error) {
      console.error('Export failed:', error);
    }
  };

  // 转换用户增长数据格式
  const formatUserGrowthData = (data: any[]): TimeSeriesData[] => {
    if (!data) return [];
    return data.map(item => ({
      timestamp: item.date,
      value: item.users,
      label: `${item.users} 用户`
    }));
  };

  return (
    <div className={`min-h-screen bg-bg-secondary ${className}`}>
      {/* 页面头部 */}
      <div className="bg-bg-primary border-b border-border-primary px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary flex items-center">
              <Activity className="w-6 h-6 mr-2 text-accent-primary" />
              实时数据看板
            </h1>
            <p className="text-sm text-text-tertiary mt-1">
              星趣App运营数据实时监控 • 
              {realTimeData ? (
                <span className="text-accent-primary">● 实时更新</span>
              ) : (
                <span className="text-text-tertiary">○ 等待连接</span>
              )}
            </p>
          </div>
          
          <div className="flex items-center space-x-3">
            {/* 时间范围选择器 */}
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value as any)}
              className="px-3 py-2 border border-border-primary rounded-lg text-sm bg-bg-primary text-text-primary"
            >
              <option value="24h">最近24小时</option>
              <option value="7d">最近7天</option>
              <option value="30d">最近30天</option>
            </select>
            
            {/* 导出按钮 */}
            <button
              onClick={handleExportData}
              className="flex items-center px-3 py-2 bg-accent-primary text-white rounded-lg hover:bg-accent-hover transition-colors text-sm"
            >
              <Download className="w-4 h-4 mr-1" />
              导出数据
            </button>
          </div>
        </div>
      </div>

      {/* 核心指标卡片 */}
      <div className="px-6 py-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <MetricCard
            title="日活用户"
            value={metrics?.dau?.value || 0}
            change={metrics?.dau?.change || '+0%'}
            trend={metrics?.dau?.trend || 'neutral'}
            icon={<Users className="w-5 h-5" />}
            loading={!metrics && !metricsError}
          />
          
          <MetricCard
            title="新增用户"
            value={metrics?.new_users_today?.value || 0}
            change={metrics?.new_users_today?.change || '+0%'}
            trend={metrics?.new_users_today?.trend || 'neutral'}
            icon={<TrendingUp className="w-5 h-5" />}
            loading={!metrics && !metricsError}
          />
          
          <MetricCard
            title="付费转化率"
            value={metrics?.conversion_rate?.value || 0}
            suffix="%"
            change={metrics?.conversion_rate?.change || '+0%'}
            trend={metrics?.conversion_rate?.trend || 'neutral'}
            icon={<DollarSign className="w-5 h-5" />}
            loading={!metrics && !metricsError}
          />
          
          <MetricCard
            title="今日收入"
            value={metrics?.daily_revenue?.value || 0}
            prefix="¥"
            change={metrics?.daily_revenue?.change || '+0%'}
            trend={metrics?.daily_revenue?.trend || 'neutral'}
            icon={<Calendar className="w-5 h-5" />}
            loading={!metrics && !metricsError}
          />
        </div>

        {/* 图表区域 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* 用户增长趋势图 */}
          <ChartContainer
            title="用户增长趋势"
            subtitle={`${timeRange === '24h' ? '24小时' : timeRange === '7d' ? '7天' : '30天'}数据趋势`}
            loading={!userGrowthData && !growthError}
            error={growthError?.message}
            onRefresh={() => window.location.reload()}
            onExport={handleExportData}
            height={350}
          >
            <UserGrowthChart
              data={formatUserGrowthData(userGrowthData)}
              variant="area"
              animate={true}
            />
          </ChartContainer>

          {/* 用户分布饼图占位 */}
          <ChartContainer
            title="用户构成分析"
            subtitle="用户类型和活跃度分布"
            loading={!userAnalytics && !analyticsError}
            error={analyticsError?.message}
            height={350}
          >
            <div className="h-full flex items-center justify-center text-text-tertiary">
              <div className="text-center">
                <Filter className="w-12 h-12 mx-auto mb-3 opacity-50" />
                <p>用户分布图表</p>
                <p className="text-sm mt-1">开发中...</p>
              </div>
            </div>
          </ChartContainer>
        </div>

        {/* 实时活动流 */}
        <div className="bg-bg-primary border border-border-primary rounded-lg p-6">
          <h3 className="text-lg font-semibold text-text-primary mb-4 flex items-center">
            <Activity className="w-5 h-5 mr-2 text-accent-primary" />
            实时活动
            {realTimeData && (
              <span className="ml-2 px-2 py-1 bg-accent-light text-accent-primary text-xs rounded-full">
                LIVE
              </span>
            )}
          </h3>
          
          <div className="space-y-3">
            {/* 活动流项目 - 模拟数据 */}
            {[
              { time: '2分钟前', event: '新用户注册', detail: 'user_12345 完成注册', type: 'success' },
              { time: '5分钟前', event: '会员升级', detail: 'user_67890 升级为高级会员', type: 'info' },
              { time: '8分钟前', event: 'AI对话开始', detail: '与角色 小雅 开始对话', type: 'neutral' },
              { time: '12分钟前', event: '内容创作', detail: '发布新的故事内容', type: 'success' }
            ].map((activity, index) => (
              <div key={index} className="flex items-start space-x-3 p-3 hover:bg-bg-hover rounded-lg transition-colors">
                <div className={`w-2 h-2 rounded-full mt-2 ${
                  activity.type === 'success' ? 'bg-status-success' :
                  activity.type === 'info' ? 'bg-status-info' : 'bg-border-primary'
                }`}></div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium text-text-primary">{activity.event}</p>
                    <span className="text-xs text-text-tertiary">{activity.time}</span>
                  </div>
                  <p className="text-sm text-text-secondary mt-1">{activity.detail}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardComponent;