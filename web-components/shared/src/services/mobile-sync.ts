/**
 * 移动端数据同步服务
 * 提供Flutter移动应用与Web后台管理系统之间的实时数据同步
 */

import { SupabaseDataService } from './supabase';
import type { RealtimeChannel } from '@supabase/supabase-js';

export interface MobileAppEvent {
  id: string;
  user_id: string;
  event_type: string;
  event_data: Record<string, any>;
  timestamp: string;
  session_id?: string;
  device_info?: {
    platform: 'ios' | 'android';
    app_version: string;
    device_model: string;
    os_version: string;
  };
}

export interface UserActivityData {
  user_id: string;
  activity_type: 'login' | 'logout' | 'page_view' | 'interaction' | 'content_create' | 'content_consume';
  activity_data: Record<string, any>;
  timestamp: string;
}

export interface ContentInteraction {
  user_id: string;
  content_type: 'ai_character' | 'audio_content' | 'creation_item';
  content_id: string;
  interaction_type: 'view' | 'like' | 'comment' | 'follow' | 'play' | 'share';
  interaction_data?: Record<string, any>;
  timestamp: string;
}

/**
 * 移动端数据同步管理器
 * 负责监听移动端事件并同步到后台系统
 */
export class MobileSyncService {
  private static instance: MobileSyncService;
  private dataService: SupabaseDataService;
  private channels: Map<string, RealtimeChannel> = new Map();
  private syncCallbacks: Map<string, ((data: any) => void)[]> = new Map();

  private constructor() {
    this.dataService = SupabaseDataService.getInstance();
  }

  public static getInstance(): MobileSyncService {
    if (!MobileSyncService.instance) {
      MobileSyncService.instance = new MobileSyncService();
    }
    return MobileSyncService.instance;
  }

  /**
   * 初始化移动端同步服务
   */
  public async initialize(): Promise<void> {
    await this.setupRealtimeChannels();
    console.log('Mobile sync service initialized');
  }

  /**
   * 设置实时通信频道
   */
  private async setupRealtimeChannels(): Promise<void> {
    // 监听用户活动事件
    this.setupUserActivityChannel();
    
    // 监听内容交互事件
    this.setupContentInteractionChannel();
    
    // 监听用户认证事件
    this.setupAuthEventsChannel();
    
    // 监听创作活动事件
    this.setupCreationEventsChannel();
    
    // 监听会员购买事件
    this.setupMembershipEventsChannel();
  }

  /**
   * 监听用户活动事件
   */
  private setupUserActivityChannel(): void {
    const channel = this.dataService.subscribeToTable(
      'user_analytics',
      (payload: any) => {
        this.handleUserActivity(payload);
      }
    );
    
    this.channels.set('user_activity', channel);
  }

  /**
   * 监听内容交互事件
   */
  private setupContentInteractionChannel(): void {
    // 监听点赞事件 - 使用增强的监听配置
    const likesChannel = this.dataService.subscribeToTable(
      'likes',
      (payload: any) => {
        console.log('Received likes event:', payload);
        this.handleContentInteraction({
          type: 'like',
          data: payload
        });
      }
    );
    
    // 监听评论事件
    const commentsChannel = this.dataService.subscribeToTable(
      'comments', 
      (payload: any) => {
        console.log('Received comments event:', payload);
        this.handleContentInteraction({
          type: 'comment',
          data: payload
        });
      }
    );
    
    // 监听关注事件
    const followsChannel = this.dataService.subscribeToTable(
      'character_follows',
      (payload: any) => {
        console.log('Received follows event:', payload);
        this.handleContentInteraction({
          type: 'follow',
          data: payload
        });
      }
    );

    // 监听实时交互汇总视图 - 新增
    const realtimeInteractionsChannel = this.dataService.subscribeToTable(
      'realtime_interactions',
      (payload: any) => {
        console.log('Received realtime interactions event:', payload);
        this.handleRealtimeInteraction(payload);
      }
    );

    this.channels.set('likes', likesChannel);
    this.channels.set('comments', commentsChannel);
    this.channels.set('follows', followsChannel);
    this.channels.set('realtime_interactions', realtimeInteractionsChannel);
  }

  /**
   * 监听用户认证事件
   */
  private setupAuthEventsChannel(): void {
    const channel = this.dataService.subscribeToTable(
      'users',
      (payload: any) => {
        this.handleUserChange(payload);
      }
    );
    
    this.channels.set('users', channel);
  }

  /**
   * 监听创作活动事件
   */
  private setupCreationEventsChannel(): void {
    // 监听AI角色创建
    const charactersChannel = this.dataService.subscribeToTable(
      'ai_characters',
      (payload: any) => {
        this.handleCreationActivity({
          type: 'ai_character',
          data: payload
        });
      }
    );
    
    // 监听创作项目
    const creationsChannel = this.dataService.subscribeToTable(
      'creation_items',
      (payload: any) => {
        this.handleCreationActivity({
          type: 'creation_item', 
          data: payload
        });
      }
    );
    
    // 监听音频内容
    const audioChannel = this.dataService.subscribeToTable(
      'audio_contents',
      (payload: any) => {
        this.handleCreationActivity({
          type: 'audio_content',
          data: payload
        });
      }
    );

    this.channels.set('ai_characters', charactersChannel);
    this.channels.set('creation_items', creationsChannel); 
    this.channels.set('audio_contents', audioChannel);
  }

  /**
   * 监听会员购买事件
   */
  private setupMembershipEventsChannel(): void {
    const channel = this.dataService.subscribeToTable(
      'user_subscriptions',
      (payload: any) => {
        this.handleMembershipActivity(payload);
      }
    );
    
    this.channels.set('user_subscriptions', channel);
  }

  /**
   * 处理用户活动事件
   */
  private handleUserActivity(payload: any): void {
    const activity: UserActivityData = {
      user_id: payload.new?.user_id || payload.old?.user_id,
      activity_type: this.mapEventToActivityType(payload.new?.event_type),
      activity_data: payload.new?.event_data || payload.old?.event_data,
      timestamp: payload.new?.created_at || new Date().toISOString()
    };

    // 触发回调
    this.triggerCallbacks('user_activity', activity);
    
    // 记录到后台系统日志
    this.logToBackendSystem('USER_ACTIVITY', activity);
  }

  /**
   * 处理内容交互事件
   */
  private handleContentInteraction(event: { type: string; data: any }): void {
    const interaction: ContentInteraction = {
      user_id: event.data.new?.user_id || event.data.old?.user_id,
      content_type: this.inferContentType(event.type, event.data),
      content_id: event.data.new?.target_id || event.data.new?.character_id || event.data.new?.id,
      interaction_type: event.type as any,
      interaction_data: event.data.new || event.data.old,
      timestamp: event.data.new?.created_at || new Date().toISOString()
    };

    // 触发回调
    this.triggerCallbacks('content_interaction', interaction);
    
    // 记录到后台系统
    this.logToBackendSystem('CONTENT_INTERACTION', interaction);
  }

  /**
   * 处理用户变更事件
   */
  private handleUserChange(payload: any): void {
    const userChange = {
      user_id: payload.new?.id || payload.old?.id,
      change_type: payload.eventType, // INSERT, UPDATE, DELETE
      user_data: payload.new || payload.old,
      timestamp: new Date().toISOString()
    };

    // 触发回调
    this.triggerCallbacks('user_change', userChange);
    
    // 记录到后台系统
    this.logToBackendSystem('USER_CHANGE', userChange);
  }

  /**
   * 处理创作活动事件
   */
  private handleCreationActivity(event: { type: string; data: any }): void {
    const creation = {
      creator_id: event.data.new?.creator_id || event.data.old?.creator_id,
      content_type: event.type,
      content_id: event.data.new?.id || event.data.old?.id,
      action: event.data.eventType, // INSERT, UPDATE, DELETE
      content_data: event.data.new || event.data.old,
      timestamp: event.data.new?.created_at || event.data.new?.updated_at || new Date().toISOString()
    };

    // 触发回调
    this.triggerCallbacks('creation_activity', creation);
    
    // 记录到后台系统
    this.logToBackendSystem('CREATION_ACTIVITY', creation);
  }

  /**
   * 处理会员活动事件
   */
  private handleMembershipActivity(payload: any): void {
    const membership = {
      user_id: payload.new?.user_id || payload.old?.user_id,
      subscription_type: payload.new?.subscription_type || payload.old?.subscription_type,
      action: payload.eventType,
      subscription_data: payload.new || payload.old,
      timestamp: payload.new?.created_at || payload.new?.updated_at || new Date().toISOString()
    };

    // 触发回调
    this.triggerCallbacks('membership_activity', membership);
    
    // 记录到后台系统
    this.logToBackendSystem('MEMBERSHIP_ACTIVITY', membership);
  }

  /**
   * 处理实时交互汇总数据
   */
  private handleRealtimeInteraction(payload: any): void {
    const interaction = {
      action_type: payload.new?.action_type || payload.old?.action_type,
      user_id: payload.new?.user_id || payload.old?.user_id,
      target_id: payload.new?.target_id || payload.old?.target_id,
      target_type: payload.new?.target_type || payload.old?.target_type,
      character_name: payload.new?.character_name || payload.old?.character_name,
      user_email: payload.new?.user_email || payload.old?.user_email,
      timestamp: payload.new?.timestamp || payload.old?.timestamp,
      eventType: payload.eventType
    };

    console.log('Processing realtime interaction:', interaction);

    // 触发内容交互回调
    this.triggerCallbacks('content_interaction', {
      user_id: interaction.user_id,
      content_type: 'ai_character',
      content_id: interaction.target_id,
      interaction_type: interaction.action_type,
      interaction_data: {
        character_name: interaction.character_name,
        user_email: interaction.user_email,
        event_type: interaction.eventType
      },
      timestamp: interaction.timestamp
    });

    // 同时触发实时交互特定的回调
    this.triggerCallbacks('realtime_interaction', interaction);
    
    // 记录到后台系统
    this.logToBackendSystem('REALTIME_INTERACTION', interaction);
  }

  /**
   * 注册同步回调
   */
  public onSync(eventType: string, callback: (data: any) => void): void {
    if (!this.syncCallbacks.has(eventType)) {
      this.syncCallbacks.set(eventType, []);
    }
    this.syncCallbacks.get(eventType)!.push(callback);
  }

  /**
   * 触发回调函数
   */
  private triggerCallbacks(eventType: string, data: any): void {
    const callbacks = this.syncCallbacks.get(eventType);
    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback(data);
        } catch (error) {
          console.error(`Error in sync callback for ${eventType}:`, error);
        }
      });
    }
  }

  /**
   * 记录到后台系统日志
   */
  private async logToBackendSystem(eventType: string, data: any): Promise<void> {
    try {
      await this.dataService.logComponentUsage('mobile_app', eventType.toLowerCase(), {
        event_type: eventType,
        data: data,
        timestamp: new Date().toISOString(),
        source: 'mobile_app'
      });
    } catch (error) {
      console.error('Failed to log to backend system:', error);
    }
  }

  /**
   * 映射事件类型到活动类型
   */
  private mapEventToActivityType(eventType: string): UserActivityData['activity_type'] {
    const mapping: Record<string, UserActivityData['activity_type']> = {
      'app_launch': 'login',
      'app_close': 'logout', 
      'page_view': 'page_view',
      'button_click': 'interaction',
      'content_create': 'content_create',
      'audio_play': 'content_consume',
      'character_chat': 'content_consume'
    };
    
    return mapping[eventType] || 'interaction';
  }

  /**
   * 推断内容类型
   */
  private inferContentType(_interactionType: string, data: any): ContentInteraction['content_type'] {
    if (data.new?.character_id || data.old?.character_id) {
      return 'ai_character';
    }
    
    if (data.new?.target_type) {
      const targetType = data.new.target_type;
      if (targetType === 'audio') return 'audio_content';
      if (targetType === 'creation') return 'creation_item';
      if (targetType === 'character') return 'ai_character';
    }
    
    return 'ai_character'; // 默认类型
  }

  /**
   * 获取实时统计数据
   */
  public async getRealtimeStats(): Promise<{
    activeUsers: number;
    todayInteractions: number;
    onlineUsers: string[];
  }> {
    try {
      // 获取今日活跃用户数
      const today = new Date().toISOString().split('T')[0];
      const activeUsersData = await this.dataService.getComponentData('user_analytics', {
        date_filter: today,
        type: 'active_users_count'
      });

      // 获取今日交互数
      const interactionsData = await this.dataService.getComponentData('user_analytics', {
        date_filter: today,
        type: 'interactions_count'
      });

      // 获取在线用户列表（最近5分钟有活动的用户）
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
      const onlineUsersData = await this.dataService.getComponentData('user_analytics', {
        timestamp_filter: fiveMinutesAgo,
        type: 'online_users'
      });

      return {
        activeUsers: activeUsersData?.count || 0,
        todayInteractions: interactionsData?.count || 0,
        onlineUsers: onlineUsersData?.users || []
      };
    } catch (error) {
      console.error('Failed to get realtime stats:', error);
      return {
        activeUsers: 0,
        todayInteractions: 0, 
        onlineUsers: []
      };
    }
  }

  /**
   * 销毁服务，取消订阅
   */
  public destroy(): void {
    this.channels.forEach((channel, _key) => {
      channel.unsubscribe();
    });
    this.channels.clear();
    this.syncCallbacks.clear();
  }
}

// 导出单例实例
export const mobileSyncService = MobileSyncService.getInstance();