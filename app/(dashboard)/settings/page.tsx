'use client'

import React, { useState } from 'react'
import { 
  Settings, 
  Save, 
  Bell, 
  Shield, 
  Database, 
  Mail,
  Globe,
  Palette,
  Key,
  Users,
  Copy,
  CheckCircle,
  AlertCircle,
  ExternalLink
} from 'lucide-react'

export default function SettingsPage() {
  const [settings, setSettings] = useState({
    // 系统设置
    siteName: '星趣社区管理后台',
    siteDescription: '专业的社区管理解决方案',
    adminEmail: 'admin@xingqu.com',
    
    // 通知设置
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false,
    
    // 安全设置
    requireTwoFactor: false,
    passwordPolicy: 'medium',
    sessionTimeout: 30,
    
    // 数据库设置
    backupFrequency: 'daily',
    retentionPeriod: 90,
    
    // 用户设置
    allowUserRegistration: true,
    requireEmailVerification: true,
    defaultUserRole: 'member'
  })

  const [activeTab, setActiveTab] = useState('general')
  const [copied, setCopied] = useState(false)

  const sqlCode = `-- 创建后台管理员用户表
CREATE TABLE IF NOT EXISTS xq_admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin', 'moderator')),
    account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'inactive', 'banned')),
    permissions JSONB DEFAULT '["read", "write"]'::JSONB,
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
CREATE INDEX IF NOT EXISTS idx_xq_admin_users_created_at ON xq_admin_users(created_at);

-- 启用RLS（行级安全）
ALTER TABLE xq_admin_users ENABLE ROW LEVEL SECURITY;

-- 创建基本的RLS政策
CREATE POLICY "Admin users can view all admin users" ON xq_admin_users
    FOR SELECT USING (true);

CREATE POLICY "Admin users can insert admin users" ON xq_admin_users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin users can update admin users" ON xq_admin_users
    FOR UPDATE USING (true);

CREATE POLICY "Super admin users can delete admin users" ON xq_admin_users
    FOR DELETE USING (true);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为表创建更新时间触发器
DROP TRIGGER IF EXISTS update_xq_admin_users_updated_at ON xq_admin_users;
CREATE TRIGGER update_xq_admin_users_updated_at
    BEFORE UPDATE ON xq_admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 插入初始测试数据
INSERT INTO xq_admin_users (email, nickname, role, account_status, permissions, agreement_accepted) VALUES
    ('admin@xingqu.com', '系统管理员', 'super_admin', 'active', '["read", "write", "delete", "manage_users", "manage_content"]', true),
    ('moderator@xingqu.com', '内容审核员', 'moderator', 'active', '["read", "write", "manage_content"]', true),
    ('user@xingqu.com', '普通管理员', 'admin', 'active', '["read", "write"]', true)
ON CONFLICT (email) DO NOTHING;

-- 创建视图用于统计
CREATE OR REPLACE VIEW xq_admin_users_stats AS
SELECT
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE account_status = 'active') as active_users,
    COUNT(*) FILTER (WHERE account_status = 'inactive') as inactive_users,
    COUNT(*) FILTER (WHERE account_status = 'banned') as banned_users,
    COUNT(*) FILTER (WHERE role = 'super_admin') as super_admin_count,
    COUNT(*) FILTER (WHERE role = 'admin') as admin_count,
    COUNT(*) FILTER (WHERE role = 'moderator') as moderator_count,
    COUNT(*) FILTER (WHERE agreement_accepted = true) as agreed_users
FROM xq_admin_users;`

  const handleSave = () => {
    // 这里实现保存逻辑
    console.log('保存设置:', settings)
    // 可以显示成功提示
  }

  const updateSetting = (key: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [key]: value
    }))
  }

  const handleCopySQL = async () => {
    try {
      await navigator.clipboard.writeText(sqlCode)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy text:', err)
    }
  }

  const tabs = [
    { id: 'general', label: '常规设置', icon: Settings },
    { id: 'notifications', label: '通知设置', icon: Bell },
    { id: 'security', label: '安全设置', icon: Shield },
    { id: 'database', label: '数据库设置', icon: Database },
    { id: 'users', label: '用户设置', icon: Users }
  ]

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">系统设置</h1>
          <p className="text-sm text-muted-foreground">配置和管理系统参数</p>
        </div>
        <button 
          onClick={handleSave}
          className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-primary to-secondary text-primary-foreground rounded-xl hover:shadow-lg hover:shadow-primary/25 transition-all duration-200 font-medium"
        >
          <Save size={18} />
          <span>保存设置</span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 mt-3">
        {/* Sidebar */}
        <div className="lg:col-span-1">
          <div className="bg-card border border-border rounded-lg p-4">
            <nav className="space-y-2">
              {tabs.map((tab) => {
                const Icon = tab.icon
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-left transition-colors ${
                      activeTab === tab.id
                        ? 'bg-primary/10 text-primary border border-primary/20'
                        : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                    }`}
                  >
                    <Icon size={18} />
                    <span className="text-sm font-medium">{tab.label}</span>
                  </button>
                )
              })}
            </nav>
          </div>
        </div>

        {/* Content */}
        <div className="lg:col-span-3">
          <div className="bg-card border border-border rounded-lg">
            {/* General Settings */}
            {activeTab === 'general' && (
              <div className="p-6 space-y-6">
                <h2 className="text-lg font-semibold text-foreground">常规设置</h2>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      站点名称
                    </label>
                    <input
                      type="text"
                      value={settings.siteName}
                      onChange={(e) => updateSetting('siteName', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      站点描述
                    </label>
                    <textarea
                      value={settings.siteDescription}
                      onChange={(e) => updateSetting('siteDescription', e.target.value)}
                      rows={3}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      管理员邮箱
                    </label>
                    <input
                      type="email"
                      value={settings.adminEmail}
                      onChange={(e) => updateSetting('adminEmail', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Notification Settings */}
            {activeTab === 'notifications' && (
              <div className="p-6 space-y-6">
                <h2 className="text-lg font-semibold text-foreground">通知设置</h2>
                
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-foreground">邮件通知</div>
                      <div className="text-sm text-muted-foreground">接收重要事件的邮件通知</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.emailNotifications}
                        onChange={(e) => updateSetting('emailNotifications', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-foreground">推送通知</div>
                      <div className="text-sm text-muted-foreground">浏览器推送通知</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.pushNotifications}
                        onChange={(e) => updateSetting('pushNotifications', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-foreground">短信通知</div>
                      <div className="text-sm text-muted-foreground">紧急事件的短信通知</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.smsNotifications}
                        onChange={(e) => updateSetting('smsNotifications', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                </div>
              </div>
            )}

            {/* Security Settings */}
            {activeTab === 'security' && (
              <div className="p-6 space-y-6">
                <h2 className="text-lg font-semibold text-foreground">安全设置</h2>
                
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-foreground">双因素认证</div>
                      <div className="text-sm text-muted-foreground">要求管理员启用双因素认证</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.requireTwoFactor}
                        onChange={(e) => updateSetting('requireTwoFactor', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      密码策略
                    </label>
                    <select
                      value={settings.passwordPolicy}
                      onChange={(e) => updateSetting('passwordPolicy', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    >
                      <option value="low">低 (最少6位)</option>
                      <option value="medium">中 (8位包含数字和字母)</option>
                      <option value="high">高 (12位包含数字、字母和特殊字符)</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      会话超时 (分钟)
                    </label>
                    <input
                      type="number"
                      min="5"
                      max="480"
                      value={settings.sessionTimeout}
                      onChange={(e) => updateSetting('sessionTimeout', parseInt(e.target.value))}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Database Settings */}
            {activeTab === 'database' && (
              <div className="p-6 space-y-6">
                <h2 className="text-lg font-semibold text-foreground">数据库设置</h2>
                
                {/* Database Initialization */}
                <div className="bg-warning/10 border border-warning/20 rounded-lg p-6">
                  <div className="flex items-start space-x-3">
                    <div className="flex items-center justify-center w-12 h-12 bg-warning/10 rounded-xl">
                      <Database size={24} className="text-warning" />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-foreground mb-2">
                        数据库初始化
                      </h3>
                      <p className="text-muted-foreground mb-4">
                        如果系统首次安装，需要在 Supabase Dashboard 中执行以下 SQL 来初始化数据库表：
                      </p>
                      <ol className="list-decimal list-inside space-y-2 text-sm text-muted-foreground mb-4">
                        <li>打开 <a href="https://supabase.com/dashboard" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline inline-flex items-center">
                          Supabase Dashboard <ExternalLink size={14} className="ml-1" />
                        </a></li>
                        <li>选择你的项目 <span className="font-mono bg-muted px-2 py-1 rounded">wqdpqhfqrxvssxifpmvt</span></li>
                        <li>进入 <strong>SQL Editor</strong></li>
                        <li>复制下面的 SQL 代码并执行</li>
                      </ol>
                    </div>
                  </div>
                </div>

                {/* SQL Code Block */}
                <div className="bg-card border border-border rounded-lg overflow-hidden">
                  <div className="flex items-center justify-between p-4 border-b border-border bg-muted/20">
                    <div className="flex items-center space-x-2">
                      <Database size={18} className="text-primary" />
                      <span className="font-medium text-foreground">SQL 初始化脚本</span>
                    </div>
                    <button
                      onClick={handleCopySQL}
                      className="flex items-center space-x-2 px-3 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors text-sm"
                    >
                      {copied ? (
                        <>
                          <CheckCircle size={16} />
                          <span>已复制!</span>
                        </>
                      ) : (
                        <>
                          <Copy size={16} />
                          <span>复制 SQL</span>
                        </>
                      )}
                    </button>
                  </div>
                  
                  <div className="p-0">
                    <pre className="bg-slate-900 text-slate-100 p-6 text-sm overflow-x-auto whitespace-pre-wrap font-mono leading-relaxed max-h-96 overflow-y-auto">
                      <code>{sqlCode}</code>
                    </pre>
                  </div>
                </div>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      备份频率
                    </label>
                    <select
                      value={settings.backupFrequency}
                      onChange={(e) => updateSetting('backupFrequency', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    >
                      <option value="hourly">每小时</option>
                      <option value="daily">每天</option>
                      <option value="weekly">每周</option>
                      <option value="monthly">每月</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      数据保留期 (天)
                    </label>
                    <input
                      type="number"
                      min="7"
                      max="365"
                      value={settings.retentionPeriod}
                      onChange={(e) => updateSetting('retentionPeriod', parseInt(e.target.value))}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* User Settings */}
            {activeTab === 'users' && (
              <div className="p-6 space-y-6">
                <h2 className="text-lg font-semibold text-foreground">用户设置</h2>
                
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-foreground">允许用户注册</div>
                      <div className="text-sm text-muted-foreground">允许新用户自主注册账户</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.allowUserRegistration}
                        onChange={(e) => updateSetting('allowUserRegistration', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-foreground">邮箱验证</div>
                      <div className="text-sm text-muted-foreground">要求新用户验证邮箱地址</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.requireEmailVerification}
                        onChange={(e) => updateSetting('requireEmailVerification', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      默认用户角色
                    </label>
                    <select
                      value={settings.defaultUserRole}
                      onChange={(e) => updateSetting('defaultUserRole', e.target.value)}
                      className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
                    >
                      <option value="member">普通会员</option>
                      <option value="premium">高级会员</option>
                      <option value="guest">访客</option>
                    </select>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}