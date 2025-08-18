import React, { useState, useEffect } from 'react';
import {
  Smartphone,
  Users,
  Activity,
  TrendingUp,
  Eye,
  MessageCircle,
  Heart,
  UserPlus,
  PlayCircle,
  Clock,
  Wifi,
  WifiOff
} from 'lucide-react';
import { mobileSyncService } from '@xingqu/shared/src/services/mobile-sync';
import type { UserActivityData, ContentInteraction } from '@xingqu/shared/src/services/mobile-sync';

interface MobileDataMonitorProps {
  className?: string;
}

interface RealtimeStats {
  activeUsers: number;
  todayInteractions: number;
  onlineUsers: string[];
}

interface ActivityFeed {
  id: string;
  type: 'user_activity' | 'content_interaction' | 'user_change' | 'creation_activity' | 'membership_activity';
  data: any;
  timestamp: string;
}

const MobileDataMonitor: React.FC<MobileDataMonitorProps> = ({ className = '' }) => {
  const [isConnected, setIsConnected] = useState(false);
  const [realtimeStats, setRealtimeStats] = useState<RealtimeStats>({
    activeUsers: 0,
    todayInteractions: 0,
    onlineUsers: []
  });
  const [activityFeed, setActivityFeed] = useState<ActivityFeed[]>([]);
  const [recentInteractions, setRecentInteractions] = useState<{
    likes: number;
    comments: number;
    follows: number;
    plays: number;
  }>({
    likes: 0,
    comments: 0,
    follows: 0,
    plays: 0
  });

  // 初始化移动端同步服务
  useEffect(() => {
    const initializeSync = async () => {
      try {
        await mobileSyncService.initialize();
        setIsConnected(true);
        
        // 获取初始统计数据
        const stats = await mobileSyncService.getRealtimeStats();
        setRealtimeStats(stats);
        
        console.log('Mobile data monitor initialized');
      } catch (error) {
        console.error('Failed to initialize mobile sync:', error);
        setIsConnected(false);
      }
    };

    initializeSync();
  }, []);

  // 设置实时数据监听
  useEffect(() => {
    if (!isConnected) return;

    // 监听用户活动
    mobileSyncService.onSync('user_activity', (data: UserActivityData) => {
      setActivityFeed(prev => [{
        id: Date.now().toString(),
        type: 'user_activity',
        data,
        timestamp: data.timestamp
      }, ...prev.slice(0, 9)]); // 保持最新10条记录

      // 更新统计数据
      setRealtimeStats(prev => ({
        ...prev,
        todayInteractions: prev.todayInteractions + 1
      }));
    });

    // 监听内容交互
    mobileSyncService.onSync('content_interaction', (data: ContentInteraction) => {
      setActivityFeed(prev => [{
        id: Date.now().toString(),
        type: 'content_interaction',
        data,
        timestamp: data.timestamp
      }, ...prev.slice(0, 9)]);

      // 更新交互统计
      setRecentInteractions(prev => {
        const newStats = { ...prev };
        switch (data.interaction_type) {
          case 'like':
            newStats.likes += 1;
            break;
          case 'comment':
            newStats.comments += 1;
            break;
          case 'follow':
            newStats.follows += 1;
            break;
          case 'play':
            newStats.plays += 1;
            break;
        }
        return newStats;
      });
    });

    // 监听用户变更
    mobileSyncService.onSync('user_change', (data: any) => {
      setActivityFeed(prev => [{
        id: Date.now().toString(),
        type: 'user_change',
        data,
        timestamp: data.timestamp
      }, ...prev.slice(0, 9)]);

      // 如果是新用户注册，更新活跃用户数
      if (data.change_type === 'INSERT') {
        setRealtimeStats(prev => ({
          ...prev,
          activeUsers: prev.activeUsers + 1
        }));
      }
    });

    // 监听创作活动
    mobileSyncService.onSync('creation_activity', (data: any) => {
      setActivityFeed(prev => [{
        id: Date.now().toString(),
        type: 'creation_activity',
        data,
        timestamp: data.timestamp
      }, ...prev.slice(0, 9)]);
    });

    // 监听会员活动
    mobileSyncService.onSync('membership_activity', (data: any) => {
      setActivityFeed(prev => [{
        id: Date.now().toString(),
        type: 'membership_activity',
        data,
        timestamp: data.timestamp
      }, ...prev.slice(0, 9)]);
    });

    // 定期更新统计数据
    const statsInterval = setInterval(async () => {
      try {
        const stats = await mobileSyncService.getRealtimeStats();
        setRealtimeStats(stats);
      } catch (error) {
        console.error('Failed to update stats:', error);
      }
    }, 30000); // 每30秒更新一次

    return () => {
      clearInterval(statsInterval);
    };
  }, [isConnected]);

  // 渲染活动类型图标
  const renderActivityIcon = (activity: ActivityFeed) => {
    switch (activity.type) {
      case 'user_activity':
        return <Activity className="w-4 h-4 text-accent-primary" />;
      case 'content_interaction':
        switch (activity.data.interaction_type) {
          case 'like':
            return <Heart className="w-4 h-4 text-red-500" />;
          case 'comment':
            return <MessageCircle className="w-4 h-4 text-blue-500" />;
          case 'follow':
            return <UserPlus className="w-4 h-4 text-green-500" />;
          case 'play':
            return <PlayCircle className="w-4 h-4 text-purple-500" />;
          default:
            return <Eye className="w-4 h-4 text-gray-500" />;
        }
      case 'user_change':
        return <Users className="w-4 h-4 text-status-info" />;
      case 'creation_activity':
        return <TrendingUp className="w-4 h-4 text-status-warning" />;
      case 'membership_activity':
        return <Smartphone className="w-4 h-4 text-status-success" />;
      default:
        return <Activity className="w-4 h-4 text-text-tertiary" />;
    }
  };

  // 渲染活动描述
  const renderActivityDescription = (activity: ActivityFeed): string => {
    switch (activity.type) {
      case 'user_activity':
        return `用户 ${activity.data.activity_type} 活动`;
      case 'content_interaction':
        return `用户${activity.data.interaction_type}了${activity.data.content_type}`;
      case 'user_change':
        return activity.data.change_type === 'INSERT' ? '新用户注册' : '用户信息更新';
      case 'creation_activity':
        return `${activity.data.action === 'INSERT' ? '创建' : '更新'}了${activity.data.content_type}`;
      case 'membership_activity':
        return `${activity.data.action === 'INSERT' ? '购买' : '更新'}了会员服务`;
      default:
        return '未知活动';
    }
  };

  return (
    <div className={`space-y-6 ${className}`}>
      {/* 连接状态指示器 */}
      <div className="bg-bg-primary border border-border-primary rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Smartphone className="w-6 h-6 text-accent-primary" />
            <div>
              <h3 className="text-lg font-semibold text-text-primary">移动端数据监控</h3>
              <p className="text-sm text-text-tertiary">iOS模拟器实时数据同步</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            {isConnected ? (
              <>
                <Wifi className="w-5 h-5 text-status-success" />
                <span className="text-sm text-status-success">已连接</span>
              </>
            ) : (
              <>
                <WifiOff className="w-5 h-5 text-status-error" />
                <span className="text-sm text-status-error">连接中...</span>
              </>
            )}
          </div>
        </div>
      </div>

      {/* 实时统计数据 */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-bg-primary border border-border-primary rounded-lg p-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-2xl font-bold text-text-primary">{realtimeStats.activeUsers}</h3>
              <p className="text-sm text-text-secondary">今日活跃用户</p>
            </div>
            <Users className="w-8 h-8 text-accent-primary opacity-50" />
          </div>
        </div>

        <div className="bg-bg-primary border border-border-primary rounded-lg p-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-2xl font-bold text-text-primary">{realtimeStats.todayInteractions}</h3>
              <p className="text-sm text-text-secondary">今日互动次数</p>
            </div>
            <Activity className="w-8 h-8 text-status-info opacity-50" />
          </div>
        </div>

        <div className="bg-bg-primary border border-border-primary rounded-lg p-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-2xl font-bold text-text-primary">{realtimeStats.onlineUsers.length}</h3>
              <p className="text-sm text-text-secondary">当前在线用户</p>
            </div>
            <Clock className="w-8 h-8 text-status-warning opacity-50" />
          </div>
        </div>
      </div>

      {/* 交互类型统计 */}
      <div className="bg-bg-primary border border-border-primary rounded-lg p-6">
        <h4 className="text-lg font-semibold text-text-primary mb-4">实时交互统计</h4>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="flex items-center space-x-3">
            <Heart className="w-5 h-5 text-red-500" />
            <div>
              <p className="text-lg font-semibold text-text-primary">{recentInteractions.likes}</p>
              <p className="text-sm text-text-tertiary">点赞</p>
            </div>
          </div>

          <div className="flex items-center space-x-3">
            <MessageCircle className="w-5 h-5 text-blue-500" />
            <div>
              <p className="text-lg font-semibold text-text-primary">{recentInteractions.comments}</p>
              <p className="text-sm text-text-tertiary">评论</p>
            </div>
          </div>

          <div className="flex items-center space-x-3">
            <UserPlus className="w-5 h-5 text-green-500" />
            <div>
              <p className="text-lg font-semibold text-text-primary">{recentInteractions.follows}</p>
              <p className="text-sm text-text-tertiary">关注</p>
            </div>
          </div>

          <div className="flex items-center space-x-3">
            <PlayCircle className="w-5 h-5 text-purple-500" />
            <div>
              <p className="text-lg font-semibold text-text-primary">{recentInteractions.plays}</p>
              <p className="text-sm text-text-tertiary">播放</p>
            </div>
          </div>
        </div>
      </div>

      {/* 实时活动流 */}
      <div className="bg-bg-primary border border-border-primary rounded-lg p-6">
        <h4 className="text-lg font-semibold text-text-primary mb-4">实时活动流</h4>
        
        <div className="space-y-3">
          {activityFeed.length > 0 ? (
            activityFeed.map((activity) => (
              <div key={activity.id} className="flex items-center space-x-3 p-3 bg-bg-secondary rounded-lg">
                {renderActivityIcon(activity)}
                
                <div className="flex-1">
                  <p className="text-sm text-text-primary">
                    {renderActivityDescription(activity)}
                  </p>
                  <p className="text-xs text-text-tertiary">
                    {new Date(activity.timestamp).toLocaleTimeString('zh-CN')}
                  </p>
                </div>
                
                <div className="text-xs text-text-tertiary">
                  刚刚
                </div>
              </div>
            ))
          ) : (
            <div className="text-center py-8">
              <Activity className="w-12 h-12 text-text-tertiary mx-auto mb-3 opacity-50" />
              <p className="text-text-tertiary">等待移动端数据...</p>
              <p className="text-sm text-text-tertiary mt-1">
                在iOS模拟器中使用星趣App，数据将实时显示在这里
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MobileDataMonitor;