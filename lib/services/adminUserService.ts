import { supabase } from './supabase'
import { AdminUser, CreateAdminUserData } from '../types'

export const adminUserService = {
  // 获取所有管理员用户
  async getAllAdminUsers(): Promise<{ data: AdminUser[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_admin_users')
        .select('*')
        .order('created_at', { ascending: false })
      
      return { data, error }
    } catch (error) {
      console.error('Error fetching admin users:', error)
      return { data: null, error }
    }
  },

  // 根据ID获取管理员用户
  async getAdminUserById(id: string): Promise<{ data: AdminUser | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_admin_users')
        .select('*')
        .eq('id', id)
        .single()
      
      return { data, error }
    } catch (error) {
      console.error('Error fetching admin user:', error)
      return { data: null, error }
    }
  },

  // 创建新的管理员用户
  async createAdminUser(userData: CreateAdminUserData): Promise<{ data: AdminUser | null; error: any }> {
    try {
      const newUser: Omit<AdminUser, 'id' | 'created_at' | 'updated_at'> = {
        ...userData,
        account_status: 'active',
        agreement_accepted: false,
        agreement_version: 'v1.0'
      }

      const { data, error } = await supabase
        .from('xq_admin_users')
        .insert([newUser])
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('Error creating admin user:', error)
      return { data: null, error }
    }
  },

  // 更新管理员用户
  async updateAdminUser(id: string, updates: Partial<AdminUser>): Promise<{ data: AdminUser | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_admin_users')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single()

      return { data, error }
    } catch (error) {
      console.error('Error updating admin user:', error)
      return { data: null, error }
    }
  },

  // 删除管理员用户（软删除 - 设置为inactive）
  async deleteAdminUser(id: string): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('xq_admin_users')
        .update({ 
          account_status: 'inactive',
          updated_at: new Date().toISOString()
        })
        .eq('id', id)

      return { error }
    } catch (error) {
      console.error('Error deleting admin user:', error)
      return { error }
    }
  },

  // 批量操作
  async batchUpdateAdminUsers(userIds: string[], updates: Partial<AdminUser>): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('xq_admin_users')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .in('id', userIds)

      return { error }
    } catch (error) {
      console.error('Error batch updating admin users:', error)
      return { error }
    }
  },

  // 搜索管理员用户
  async searchAdminUsers(searchTerm: string): Promise<{ data: AdminUser[] | null; error: any }> {
    try {
      const { data, error } = await supabase
        .from('xq_admin_users')
        .select('*')
        .or(`nickname.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%,phone.ilike.%${searchTerm}%`)
        .order('created_at', { ascending: false })

      return { data, error }
    } catch (error) {
      console.error('Error searching admin users:', error)
      return { data: null, error }
    }
  },

  // 更新最后登录时间
  async updateLastLogin(id: string): Promise<{ error: any }> {
    try {
      const { error } = await supabase
        .from('xq_admin_users')
        .update({ 
          last_login: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', id)

      return { error }
    } catch (error) {
      console.error('Error updating last login:', error)
      return { error }
    }
  }
}

// 用于创建表的SQL（供参考）
export const createAdminUsersTableSQL = `
  CREATE TABLE IF NOT EXISTS xq_admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'admin',
    account_status VARCHAR(20) NOT NULL DEFAULT 'active',
    permissions JSONB DEFAULT '[]'::JSONB,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    agreement_accepted BOOLEAN DEFAULT FALSE,
    agreement_version VARCHAR(10) DEFAULT 'v1.0'
  );

  -- 创建索引
  CREATE INDEX IF NOT EXISTS idx_xq_admin_users_email ON xq_admin_users(email);
  CREATE INDEX IF NOT EXISTS idx_xq_admin_users_status ON xq_admin_users(account_status);
  CREATE INDEX IF NOT EXISTS idx_xq_admin_users_role ON xq_admin_users(role);
  
  -- 启用RLS（行级安全）
  ALTER TABLE xq_admin_users ENABLE ROW LEVEL SECURITY;
  
  -- 创建基本的RLS政策（管理员可以查看和修改所有用户）
  CREATE POLICY "Admin users can view all admin users" ON xq_admin_users
    FOR SELECT USING (true);
    
  CREATE POLICY "Admin users can insert admin users" ON xq_admin_users
    FOR INSERT WITH CHECK (true);
    
  CREATE POLICY "Admin users can update admin users" ON xq_admin_users
    FOR UPDATE USING (true);
`;