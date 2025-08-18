/**
 * 移动端数据同步服务
 * 提供Flutter移动应用与Web后台管理系统之间的实时数据同步
 */
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
export declare class MobileSyncService {
    private static instance;
    private dataService;
    private channels;
    private syncCallbacks;
    private constructor();
    static getInstance(): MobileSyncService;
    /**
     * 初始化移动端同步服务
     */
    initialize(): Promise<void>;
    /**
     * 设置实时通信频道
     */
    private setupRealtimeChannels;
    /**
     * 监听用户活动事件
     */
    private setupUserActivityChannel;
    /**
     * 监听内容交互事件
     */
    private setupContentInteractionChannel;
    /**
     * 监听用户认证事件
     */
    private setupAuthEventsChannel;
    /**
     * 监听创作活动事件
     */
    private setupCreationEventsChannel;
    /**
     * 监听会员购买事件
     */
    private setupMembershipEventsChannel;
    /**
     * 处理用户活动事件
     */
    private handleUserActivity;
    /**
     * 处理内容交互事件
     */
    private handleContentInteraction;
    /**
     * 处理用户变更事件
     */
    private handleUserChange;
    /**
     * 处理创作活动事件
     */
    private handleCreationActivity;
    /**
     * 处理会员活动事件
     */
    private handleMembershipActivity;
    /**
     * 注册同步回调
     */
    onSync(eventType: string, callback: (data: any) => void): void;
    /**
     * 触发回调函数
     */
    private triggerCallbacks;
    /**
     * 记录到后台系统日志
     */
    private logToBackendSystem;
    /**
     * 映射事件类型到活动类型
     */
    private mapEventToActivityType;
    /**
     * 推断内容类型
     */
    private inferContentType;
    /**
     * 获取实时统计数据
     */
    getRealtimeStats(): Promise<{
        activeUsers: number;
        todayInteractions: number;
        onlineUsers: string[];
    }>;
    /**
     * 销毁服务，取消订阅
     */
    destroy(): void;
}
export declare const mobileSyncService: MobileSyncService;
