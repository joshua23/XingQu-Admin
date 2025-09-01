import React, { useState } from 'react'
import { Settings as SettingsIcon, Save, Key, Database, Bell, Shield } from 'lucide-react'

const Settings: React.FC = () => {
  const [settings, setSettings] = useState({
    // 系统设置
    appName: '星趣App',
    enableRegistration: true,
    enableNotifications: true,
    maxFileSize: 10,

    // API设置
    supabaseUrl: 'https://wqdpqhfqrxvssxifpmvt.supabase.co',
    enableApiLogs: true,

    // 安全设置
    enableTwoFactor: false,
    sessionTimeout: 30,
    maxLoginAttempts: 5,

    // 通知设置
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false
  })

  const [saving, setSaving] = useState(false)

  const handleSave = async () => {
    setSaving(true)
    try {
      // 这里应该调用API保存设置
      await new Promise(resolve => setTimeout(resolve, 1000))
      alert('设置保存成功！')
    } catch (error) {
      alert('保存失败，请重试')
    } finally {
      setSaving(false)
    }
  }

  const SettingSection: React.FC<{
    title: string
    icon: React.ReactNode
    children: React.ReactNode
  }> = ({ title, icon, children }) => (
    <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
      <div className="flex items-center space-x-3 mb-6">
        {icon}
        <h3 className="text-lg font-semibold text-white">{title}</h3>
      </div>
      <div className="space-y-4">
        {children}
      </div>
    </div>
  )

  const SettingItem: React.FC<{
    label: string
    description?: string
    children: React.ReactNode
  }> = ({ label, description, children }) => (
    <div className="flex items-center justify-between py-2">
      <div className="flex-1">
        <label className="text-white font-medium">{label}</label>
        {description && (
          <p className="text-gray-400 text-sm mt-1">{description}</p>
        )}
      </div>
      <div className="ml-4">
        {children}
      </div>
    </div>
  )

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">系统设置</h1>
          <p className="text-gray-400 mt-1">管理系统配置和参数</p>
        </div>
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex items-center space-x-2 px-6 py-3 bg-primary-500 hover:bg-primary-600 disabled:bg-primary-500/50 disabled:cursor-not-allowed text-white rounded-lg transition-colors"
        >
          <Save size={18} />
          <span>{saving ? '保存中...' : '保存设置'}</span>
        </button>
      </div>

      {/* 设置区域 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 基本设置 */}
        <SettingSection
          title="基本设置"
          icon={<SettingsIcon size={20} className="text-primary-500" />}
        >
          <SettingItem
            label="应用名称"
            description="显示在后台管理系统中的应用名称"
          >
            <input
              type="text"
              value={settings.appName}
              onChange={(e) => setSettings(prev => ({ ...prev, appName: e.target.value }))}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </SettingItem>

          <SettingItem
            label="允许新用户注册"
            description="控制是否允许新用户注册账号"
          >
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.enableRegistration}
                onChange={(e) => setSettings(prev => ({ ...prev, enableRegistration: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-500/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-500"></div>
            </label>
          </SettingItem>

          <SettingItem
            label="最大文件上传大小"
            description="用户上传文件的最大大小限制（MB）"
          >
            <input
              type="number"
              value={settings.maxFileSize}
              onChange={(e) => setSettings(prev => ({ ...prev, maxFileSize: parseInt(e.target.value) }))}
              className="w-20 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </SettingItem>
        </SettingSection>

        {/* API设置 */}
        <SettingSection
          title="API设置"
          icon={<Key size={20} className="text-blue-500" />}
        >
          <SettingItem
            label="Supabase URL"
            description="Supabase项目的基础URL"
          >
            <input
              type="text"
              value={settings.supabaseUrl}
              onChange={(e) => setSettings(prev => ({ ...prev, supabaseUrl: e.target.value }))}
              className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </SettingItem>

          <SettingItem
            label="启用API日志"
            description="记录所有API调用的日志信息"
          >
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.enableApiLogs}
                onChange={(e) => setSettings(prev => ({ ...prev, enableApiLogs: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-500/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-500"></div>
            </label>
          </SettingItem>
        </SettingSection>

        {/* 安全设置 */}
        <SettingSection
          title="安全设置"
          icon={<Shield size={20} className="text-red-500" />}
        >
          <SettingItem
            label="启用双因素认证"
            description="要求管理员使用双因素认证登录"
          >
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.enableTwoFactor}
                onChange={(e) => setSettings(prev => ({ ...prev, enableTwoFactor: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-red-500/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500"></div>
            </label>
          </SettingItem>

          <SettingItem
            label="会话超时时间"
            description="管理员登录会话的超时时间（分钟）"
          >
            <input
              type="number"
              value={settings.sessionTimeout}
              onChange={(e) => setSettings(prev => ({ ...prev, sessionTimeout: parseInt(e.target.value) }))}
              className="w-20 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </SettingItem>

          <SettingItem
            label="最大登录尝试次数"
            description="登录失败的最大重试次数"
          >
            <input
              type="number"
              value={settings.maxLoginAttempts}
              onChange={(e) => setSettings(prev => ({ ...prev, maxLoginAttempts: parseInt(e.target.value) }))}
              className="w-20 px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </SettingItem>
        </SettingSection>

        {/* 通知设置 */}
        <SettingSection
          title="通知设置"
          icon={<Bell size={20} className="text-yellow-500" />}
        >
          <SettingItem
            label="邮件通知"
            description="发送系统事件的邮件通知"
          >
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.emailNotifications}
                onChange={(e) => setSettings(prev => ({ ...prev, emailNotifications: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-yellow-500/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-yellow-500"></div>
            </label>
          </SettingItem>

          <SettingItem
            label="推送通知"
            description="发送浏览器推送通知"
          >
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.pushNotifications}
                onChange={(e) => setSettings(prev => ({ ...prev, pushNotifications: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-yellow-500/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-yellow-500"></div>
            </label>
          </SettingItem>

          <SettingItem
            label="短信通知"
            description="发送重要事件的短信通知"
          >
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.smsNotifications}
                onChange={(e) => setSettings(prev => ({ ...prev, smsNotifications: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-yellow-500/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-yellow-500"></div>
            </label>
          </SettingItem>
        </SettingSection>
      </div>

      {/* 数据库设置 */}
      <SettingSection
        title="数据库设置"
        icon={<Database size={20} className="text-green-500" />}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 bg-gray-700 rounded-lg">
            <h4 className="text-white font-medium mb-2">连接状态</h4>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-green-400 text-sm">已连接</span>
            </div>
          </div>
          <div className="p-4 bg-gray-700 rounded-lg">
            <h4 className="text-white font-medium mb-2">数据同步</h4>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
              <span className="text-blue-400 text-sm">同步中</span>
            </div>
          </div>
        </div>
      </SettingSection>
    </div>
  )
}

export default Settings
