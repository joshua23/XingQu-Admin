import { SupabaseClient, RealtimeChannel } from '@supabase/supabase-js';

export declare const supabase: SupabaseClient;
export declare class SupabaseDataService {
    protected client: SupabaseClient;
    private channels;
    private static instance;
    constructor();
    static getInstance(): SupabaseDataService;
    subscribeToTable<T = any>(tableName: string, callback: (payload: T) => void, filter?: {
        column: string;
        value: any;
    }): RealtimeChannel;
    unsubscribe(channelName?: string): void;
    getComponentData(componentType: string, filters?: any): Promise<any>;
    updateComponentConfig(componentId: string, config: any): Promise<any>;
    logComponentUsage(componentId: string, actionType: string, actionData?: any): Promise<void>;
    private getCurrentFeishuUserId;
    private getClientIP;
}
export declare class RealtimeMetricsService extends SupabaseDataService {
    getRealTimeMetrics(metricNames?: string[]): Promise<any>;
    subscribeToMetrics(callback: (metrics: any) => void): RealtimeChannel;
}
export declare const dataService: SupabaseDataService;
export declare const metricsService: RealtimeMetricsService;
