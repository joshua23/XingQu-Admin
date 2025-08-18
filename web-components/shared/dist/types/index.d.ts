export interface ComponentProps {
    className?: string;
    children?: React.ReactNode;
}
export interface FeishuContext {
    userId: string;
    userName: string;
    tableId: string;
    permissions: string[];
    locale: 'zh-CN' | 'en-US';
    theme: 'light' | 'dark';
}
export interface ComponentConfig {
    id: string;
    componentType: string;
    componentName: string;
    feishuTableId?: string;
    configData: Record<string, any>;
    permissions: Record<string, any>;
    isActive: boolean;
    createdBy: string;
    createdAt: string;
    updatedAt: string;
}
export interface RealtimeMetric {
    id: string;
    metricName: string;
    metricValue: any;
    componentId: string;
    calculatedAt: string;
    expiresAt: string;
}
export interface User {
    id: string;
    phone: string;
    nickname: string;
    avatar?: string;
    gender?: 'male' | 'female' | 'unknown';
    birthday?: string;
    location?: string;
    bio?: string;
    vipLevel: number;
    membershipLevel: 'free' | 'basic' | 'premium' | 'lifetime';
    membershipStartDate?: string;
    membershipEndDate?: string;
    totalSpent: number;
    starPointsBalance: number;
    starRiverCount: number;
    createdAt: string;
    updatedAt: string;
    lastSeenAt: string;
}
export interface UserAnalytics {
    totalUsers: number;
    activeUsers: number;
    newUsersToday: number;
    membershipConversion: number;
    retention: {
        day1: number;
        day7: number;
        day30: number;
    };
    userSegments: {
        segment: string;
        count: number;
        percentage: number;
    }[];
}
export interface AICharacter {
    id: string;
    name: string;
    avatar: string;
    description: string;
    personality: string;
    voiceId?: string;
    creatorId: string;
    isPublic: boolean;
    tags: string[];
    category: string;
    usageCount: number;
    rating: number;
    followerCount: number;
    createdAt: string;
    updatedAt: string;
}
export interface ContentModerationItem {
    id: string;
    contentId: string;
    contentType: 'text' | 'image' | 'audio' | 'video';
    content: string;
    authorId: string;
    status: 'pending' | 'approved' | 'rejected' | 'flagged';
    priority: 'low' | 'medium' | 'high' | 'urgent';
    aiScore: number;
    humanReviewed: boolean;
    reviewerId?: string;
    reviewedAt?: string;
    reason?: string;
    createdAt: string;
    updatedAt: string;
}
export interface MonetizationData {
    revenue: {
        today: number;
        thisMonth: number;
        lastMonth: number;
        growth: number;
    };
    subscriptions: {
        total: number;
        active: number;
        cancelled: number;
        pending: number;
    };
    conversion: {
        rate: number;
        funnel: {
            step: string;
            users: number;
            conversion: number;
        }[];
    };
    arpu: number;
    ltv: number;
}
export interface ApiResponse<T = any> {
    data?: T;
    error?: string;
    message?: string;
    success: boolean;
    timestamp: string;
}
export interface PaginatedData<T> {
    items: T[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
}
export interface ChartDataPoint {
    x: string | number;
    y: number;
    label?: string;
    color?: string;
}
export interface TimeSeriesData {
    timestamp: string;
    value: number;
    label?: string;
}
export type LoadingState = 'idle' | 'loading' | 'success' | 'error';
export interface ComponentState<T = any> {
    data: T | null;
    loading: boolean;
    error: string | null;
    lastUpdated: string | null;
}
export interface Filter {
    field: string;
    operator: 'eq' | 'neq' | 'gt' | 'gte' | 'lt' | 'lte' | 'like' | 'in';
    value: any;
}
export interface SortConfig {
    field: string;
    direction: 'asc' | 'desc';
}
export interface TableConfig {
    columns: {
        key: string;
        title: string;
        width?: number;
        sortable?: boolean;
        filterable?: boolean;
        render?: (value: any, record: any) => React.ReactNode;
    }[];
    pagination?: {
        pageSize: number;
        showSizeChanger?: boolean;
        showQuickJumper?: boolean;
    };
    selection?: {
        type: 'checkbox' | 'radio';
        onSelectionChange?: (selectedKeys: string[]) => void;
    };
}
export interface ActionLog {
    id: string;
    adminId: string;
    action: string;
    resource: string;
    resourceId: string;
    details: Record<string, any>;
    ipAddress: string;
    userAgent: string;
    createdAt: string;
}
export interface SystemConfig {
    id: string;
    category: string;
    key: string;
    value: any;
    description: string;
    isActive: boolean;
    updatedBy: string;
    createdAt: string;
    updatedAt: string;
}
