# 星趣App 项目 Supabase 快速指南

## 🎯 项目特定配置

### 数据库表结构

```typescript
// 根据实际调试发现的表结构
interface XqUserProfile {
  id: string                    // 主键 UUID
  user_id: string              // 外键关联 auth.users
  nickname?: string            // 用户昵称
  avatar_url?: string          // 头像 URL
  bio?: string                 // 个人简介
  wechat_openid?: string       // 微信 OpenID
  wechat_unionid?: string      // 微信 UnionID  
  wechat_nickname?: string     // 微信昵称
  wechat_avatar_url?: string   // 微信头像
  apple_user_id?: string       // Apple 用户 ID
  apple_email?: string         // Apple 邮箱
  apple_full_name?: string     // Apple 全名
  likes_received_count: number // 收到的点赞数
  agents_usage_count: number   // AI 代理使用次数
  account_status: 'active' | 'inactive' | 'suspended'
  deactivated_at?: string      // 停用时间
  violation_reason?: string    // 违规原因
  created_at: string           // 创建时间
  updated_at: string           // 更新时间
  is_member: boolean           // 是否会员
  membership_expires_at?: string // 会员到期时间
  gender?: 'male' | 'female' | 'other' // 性别
}
```

### 常用查询模式

```typescript
// 1. 获取用户统计数据
export const getUserStats = async () => {
  const { data, error } = await supabase
    .from('xq_user_profiles')
    .select(`
      id,
      user_id,
      nickname,
      avatar_url,
      created_at,
      updated_at,
      account_status,
      is_member,
      membership_expires_at
    `)
    .order('created_at', { ascending: false })
    .limit(100);
  
  return { data, error };
};

// 2. 获取会话统计
export const getSessionStats = async () => {
  const { data, error } = await supabase
    .from('xq_user_sessions')
    .select('session_duration, created_at', { count: 'exact' })
    .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());
  
  return { data, error };
};

// 3. 获取行为事件
export const getTrackingEvents = async () => {
  const { data, error } = await supabase
    .from('xq_tracking_events')
    .select('user_id, event_type, created_at')
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
    .order('created_at', { ascending: false });
  
  return { data, error };
};
```

## 🚨 避免的常见错误

### 1. 字段名称错误
```typescript
// ❌ 错误 - 这些字段不存在
const badQuery = await supabase
  .from('xq_user_profiles')
  .select('email, username, last_sign_in_at, subscription_type, is_active');

// ✅ 正确 - 使用实际存在的字段
const goodQuery = await supabase
  .from('xq_user_profiles')
  .select('user_id, nickname, updated_at, account_status, is_member');
```

### 2. 类型定义不匹配
```typescript
// ❌ 错误的接口定义
interface BadUser {
  email: string;           // 不存在
  username: string;        // 应该是 nickname
  is_active: boolean;      // 应该是 account_status
  subscription_type: string; // 应该是 is_member
}

// ✅ 正确的接口定义
interface GoodUser {
  user_id: string;
  nickname?: string;
  account_status: 'active' | 'inactive' | 'suspended';
  is_member: boolean;
}
```

## 🔧 项目专用工具函数

### 调试助手
```typescript
// 调试数据库表结构
export const debugTableStructure = async (tableName: string) => {
  const { data, error } = await supabase
    .from(tableName)
    .select('*')
    .limit(1);
  
  if (data && data.length > 0) {
    console.log(`📋 Table "${tableName}" structure:`, Object.keys(data[0]));
    console.log('📄 Sample data:', data[0]);
  } else {
    console.log(`❌ Table "${tableName}" is empty or error:`, error);
  }
};

// 使用示例
// debugTableStructure('xq_user_profiles');
```

### 数据验证工具
```typescript
// 验证用户数据完整性
export const validateUserProfile = (profile: Partial<XqUserProfile>) => {
  const errors: string[] = [];

  if (!profile.user_id) {
    errors.push('user_id is required');
  }

  if (profile.account_status && 
      !['active', 'inactive', 'suspended'].includes(profile.account_status)) {
    errors.push('Invalid account_status');
  }

  if (profile.nickname && profile.nickname.length > 100) {
    errors.push('nickname too long');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};
```

## 📊 项目特定查询示例

### Dashboard 数据获取
```typescript
export const getDashboardStats = async () => {
  try {
    const [usersResult, sessionsResult, eventsResult] = await Promise.all([
      // 用户总数和基本信息
      supabase
        .from('xq_user_profiles')
        .select('id, created_at, account_status', { count: 'exact' }),
      
      // 会话数据
      supabase
        .from('xq_user_sessions')
        .select('session_duration, created_at', { count: 'exact' })
        .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()),
      
      // 行为事件
      supabase
        .from('xq_tracking_events')
        .select('user_id, event_type, created_at')
        .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
    ]);

    // 计算活跃用户
    const activeUserIds = new Set(
      eventsResult.data?.map(event => event.user_id) || []
    );

    // 计算会员用户
    const memberUsers = usersResult.data?.filter(user => 
      user.account_status === 'active'
    ).length || 0;

    return {
      data: {
        totalUsers: usersResult.count || 0,
        activeUsers: activeUserIds.size,
        memberUsers,
        totalSessions: sessionsResult.count || 0,
      },
      error: null
    };
  } catch (error) {
    console.error('Dashboard stats error:', error);
    return { data: null, error };
  }
};
```

### 用户搜索功能
```typescript
export const searchUsers = async (searchTerm: string, statusFilter: string = 'all') => {
  let query = supabase
    .from('xq_user_profiles')
    .select(`
      id,
      user_id,
      nickname,
      avatar_url,
      account_status,
      is_member,
      created_at
    `);

  // 搜索条件
  if (searchTerm) {
    query = query.or(`nickname.ilike.%${searchTerm}%,user_id.ilike.%${searchTerm}%`);
  }

  // 状态筛选
  if (statusFilter !== 'all') {
    query = query.eq('account_status', statusFilter);
  }

  // 排序和分页
  query = query
    .order('created_at', { ascending: false })
    .limit(50);

  return await query;
};
```

## 🔐 项目认证配置

### 开发环境认证
```typescript
// 开发环境快速登录
export const devSignIn = async () => {
  if (import.meta.env.DEV) {
    const mockUser = {
      id: 'dev-admin-001',
      user_id: 'dev-admin-001',
      nickname: '开发管理员',
      avatar_url: undefined,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      account_status: 'active' as const,
      is_member: false
    };

    localStorage.setItem('dev_admin_user', JSON.stringify(mockUser));
    return { success: true, user: mockUser };
  }
  
  throw new Error('Dev sign-in only available in development');
};
```

### 生产环境认证
```typescript
// 生产环境认证逻辑
export const productionSignIn = async (email: string, password: string) => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });

  if (error) {
    return { success: false, error: error.message };
  }

  // 检查管理员权限
  const { data: adminProfile } = await supabase
    .from('admin_profiles')  // 假设有管理员表
    .select('*')
    .eq('user_id', data.user.id)
    .single();

  if (!adminProfile) {
    await supabase.auth.signOut();
    return { success: false, error: 'No admin access' };
  }

  return { success: true, user: data.user, profile: adminProfile };
};
```

## 📝 快速故障排除

### 1. 数据库连接问题
```bash
# 检查环境变量
echo $VITE_SUPABASE_URL
echo $VITE_SUPABASE_ANON_KEY

# 测试连接
curl -H "Authorization: Bearer YOUR_ANON_KEY" \
     -H "apikey: YOUR_ANON_KEY" \
     "YOUR_SUPABASE_URL/rest/v1/xq_user_profiles?select=id&limit=1"
```

### 2. 表结构检查
```sql
-- 在 Supabase SQL 编辑器中运行
\d xq_user_profiles;

-- 或查看列信息
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'xq_user_profiles';
```

### 3. RLS 策略检查
```sql
-- 查看表的 RLS 状态
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'xq_user_profiles';

-- 查看策略
SELECT * FROM pg_policies WHERE tablename = 'xq_user_profiles';
```

## 🎯 项目特定最佳实践

1. **总是使用 `user_id` 而不是 `id` 进行用户关联**
2. **使用 `nickname` 而不是 `username` 显示用户名**
3. **使用 `account_status` 而不是布尔值检查用户状态**
4. **会员状态用 `is_member` 而不是 `subscription_type`**
5. **时间字段优先使用 `updated_at` 而不是 `last_sign_in_at`**

这个快速指南专门针对你的项目结构和数据库配置，应该能避免类似今天遇到的字段名称错误问题！