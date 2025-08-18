import { createClient, SupabaseClient, RealtimeChannel } from '@supabase/supabase-js';

interface SupabaseConfig {
  url: string;
  anonKey: string;
}

// 获取环境变量的安全方法
const getEnvVar = (key: string, defaultValue: string) => {
  return (import.meta as any).env?.[key] || defaultValue;
};

// Supabase配置
const supabaseConfig: SupabaseConfig = {
  url: getEnvVar('VITE_SUPABASE_URL', 'https://your-project.supabase.co'),
  anonKey: getEnvVar('VITE_SUPABASE_ANON_KEY', 'your-anon-key')
};

// Supabase客户端实例
export const supabase: SupabaseClient = createClient(
  supabaseConfig.url,
  supabaseConfig.anonKey,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true
    },
    realtime: {
      params: {
        eventsPerSecond: 10
      }
    }
  }
);

// 数据服务基类
export class SupabaseDataService {
  protected client: SupabaseClient;
  private channels: Map<string, RealtimeChannel> = new Map();
  private static instance: SupabaseDataService;

  constructor() {
    this.client = supabase;
  }

  // 获取单例实例
  static getInstance(): SupabaseDataService {
    if (!SupabaseDataService.instance) {
      SupabaseDataService.instance = new SupabaseDataService();
    }
    return SupabaseDataService.instance;
  }

  // 实时数据订阅
  subscribeToTable<T = any>(
    tableName: string,
    callback: (payload: T) => void,
    filter?: { column: string; value: any }
  ): RealtimeChannel {
    const channelName = `${tableName}_${filter?.column || 'all'}`;
    
    // 如果已有订阅，先取消
    if (this.channels.has(channelName)) {
      this.channels.get(channelName)?.unsubscribe();
    }

    const channel = this.client
      .channel(channelName)
      .on(
        'postgres_changes' as any,
        {
          event: '*',
          schema: 'public',
          table: tableName,
          ...(filter && { filter: `${filter.column}=eq.${filter.value}` })
        },
        callback
      )
      .subscribe();

    this.channels.set(channelName, channel);
    return channel;
  }

  // 取消订阅
  unsubscribe(channelName?: string): void {
    if (channelName && this.channels.has(channelName)) {
      this.channels.get(channelName)?.unsubscribe();
      this.channels.delete(channelName);
    } else {
      // 取消所有订阅
      this.channels.forEach(channel => channel.unsubscribe());
      this.channels.clear();
    }
  }

  // 获取组件数据
  async getComponentData(componentType: string, filters: any = {}) {
    try {
      const { data, error } = await this.client.rpc('get_component_data', {
        component_type: componentType,
        filters
      });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error(`Error fetching ${componentType} data:`, error);
      throw error;
    }
  }

  // 更新组件配置
  async updateComponentConfig(componentId: string, config: any) {
    try {
      const { data, error } = await this.client
        .from('component_configs')
        .update({ 
          config_data: config,
          updated_at: new Date().toISOString()
        })
        .eq('id', componentId)
        .select()
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error updating component config:', error);
      throw error;
    }
  }

  // 记录组件使用日志
  async logComponentUsage(
    componentId: string, 
    actionType: string, 
    actionData: any = {}
  ) {
    try {
      const { error } = await this.client
        .from('component_usage_logs')
        .insert({
          component_id: componentId,
          feishu_user_id: this.getCurrentFeishuUserId(),
          action_type: actionType,
          action_data: actionData,
          ip_address: await this.getClientIP(),
          user_agent: navigator.userAgent
        });

      if (error) throw error;
    } catch (error) {
      console.error('Error logging component usage:', error);
      // 不抛出错误，避免影响主功能
    }
  }

  // 获取飞书用户ID
  private getCurrentFeishuUserId(): string | null {
    // 从URL参数或localStorage中获取飞书用户ID
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('feishu_user_id') || 
           localStorage.getItem('feishu_user_id');
  }

  // 获取客户端IP (简化版)
  private async getClientIP(): Promise<string | null> {
    try {
      const response = await fetch('https://api.ipify.org?format=json');
      const data = await response.json();
      return data.ip;
    } catch {
      return null;
    }
  }
}

// 实时指标服务
export class RealtimeMetricsService extends SupabaseDataService {
  // 获取实时指标
  async getRealTimeMetrics(metricNames: string[] = []) {
    try {
      let query = this.client
        .from('realtime_metrics')
        .select('*')
        .gte('expires_at', new Date().toISOString())
        .order('calculated_at', { ascending: false });

      if (metricNames.length > 0) {
        query = query.in('metric_name', metricNames);
      }

      const { data, error } = await query;
      if (error) throw error;

      // 将数据转换为更友好的格式
      const metricsMap = new Map();
      data?.forEach(item => {
        metricsMap.set(item.metric_name, {
          value: item.metric_value,
          calculatedAt: item.calculated_at,
          expiresAt: item.expires_at
        });
      });

      return Object.fromEntries(metricsMap);
    } catch (error) {
      console.error('Error fetching real-time metrics:', error);
      throw error;
    }
  }

  // 订阅实时指标更新
  subscribeToMetrics(callback: (metrics: any) => void) {
    return this.subscribeToTable('realtime_metrics', async () => {
      const metrics = await this.getRealTimeMetrics();
      callback(metrics);
    });
  }
}

// 导出服务实例
export const dataService = new SupabaseDataService();
export const metricsService = new RealtimeMetricsService();