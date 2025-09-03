// 内容审核系统类型定义

export interface ContentItem {
  id: string;
  content_id: string;
  content_type: 'text' | 'image' | 'video' | 'audio' | 'link' | 'user_profile';
  content_text?: string;
  content_url?: string;
  content_metadata?: Record<string, any>;
  user_id: string;
  user_nickname?: string;
  submitted_at: string;
  status: ContentStatus;
  priority: ContentPriority;
  category: ContentCategory;
  ai_confidence?: number;
  ai_reason?: string;
  moderator_id?: string;
  moderator_reason?: string;
  reviewed_at?: string;
  resolved_at?: string;
}

export enum ContentStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  FLAGGED = 'flagged',
  ESCALATED = 'escalated',
  REVIEWING = 'reviewing'
}

export enum ContentPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent'
}

export enum ContentCategory {
  SPAM = 'spam',
  HARASSMENT = 'harassment', 
  HATE_SPEECH = 'hate_speech',
  VIOLENCE = 'violence',
  ADULT_CONTENT = 'adult_content',
  MISINFORMATION = 'misinformation',
  COPYRIGHT = 'copyright',
  PERSONAL_INFO = 'personal_info',
  SCAM = 'scam',
  OTHER = 'other'
}

export interface ModerationRule {
  id: string;
  name: string;
  description: string;
  category: ContentCategory;
  keywords?: string[];
  patterns?: string[];
  ai_model?: string;
  confidence_threshold?: number;
  auto_action?: 'approve' | 'reject' | 'flag' | 'escalate';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ModerationAction {
  id: string;
  content_id: string;
  action: 'approve' | 'reject' | 'flag' | 'escalate' | 'ban_user' | 'delete_content';
  reason?: string;
  moderator_id: string;
  created_at: string;
}

export interface ModerationStats {
  totalItems: number;
  pendingItems: number;
  approvedItems: number;
  rejectedItems: number;
  flaggedItems: number;
  escalatedItems: number;
  avgResponseTime: number; // in minutes
  todayProcessed: number;
  aiAccuracy?: number;
}

export interface BatchModerationRequest {
  content_ids: string[];
  action: 'approve' | 'reject' | 'flag' | 'escalate';
  reason?: string;
}

export interface ContentFilter {
  status?: ContentStatus[];
  category?: ContentCategory[];
  priority?: ContentPriority[];
  content_type?: string[];
  date_range?: {
    start: string;
    end: string;
  };
  moderator_id?: string;
  search?: string;
}