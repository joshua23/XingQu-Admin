import React, { useState, useEffect } from 'react'
import { 
  X, 
  User, 
  Mail, 
  Phone, 
  MapPin, 
  Calendar, 
  Shield, 
  Crown,
  Activity,
  MessageSquare,
  FileText,
  DollarSign,
  Edit,
  Ban,
  Unlock
} from 'lucide-react'
import { Badge } from '../ui/Badge'
import { supabase } from '../../services/supabase'

interface UserDetailModalProps {
  userId: string
  onClose: () => void
  onUpdate?: () => void
}

interface UserDetail {
  // 基本信息
  id: string
  user_id: string
  nickname?: string
  avatar_url?: string
  bio?: string
  gender?: 'male' | 'female' | 'other' | 'hidden'
  
  // 账户信息
  account_status: 'active' | 'inactive' | 'suspended' | 'violation' | 'deactivated'
  is_member: boolean
  membership_expires_at?: string
  created_at: string
  updated_at?: string
  deactivated_at?: string
  violation_reason?: string
  
  // 微信集成
  wechat_openid?: string
  wechat_nickname?: string
  wechat_avatar_url?: string
  
  // Apple集成
  apple_user_id?: string
  apple_email?: string
  apple_full_name?: string
  
  // 统计数据
  likes_received_count?: number
  agents_usage_count?: number
  
  // 使用统计（需要从其他表查询）
  totalSessions?: number
  totalMessages?: number
  totalRevenue?: number
  lastActiveAt?: string
}

export const UserDetailModal: React.FC<UserDetailModalProps> = ({ 
  userId, 
  onClose, 
  onUpdate 
}) => {
  const [user, setUser] = useState<UserDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [editForm, setEditForm] = useState<Partial<UserDetail>>({})

  useEffect(() => {
    loadUserDetail()
  }, [userId])

  const loadUserDetail = async () => {
    setLoading(true)
    try {
      // 查询用户基本信息
      const { data: userData, error: userError } = await supabase
        .from('xq_user_profiles')
        .select('*')
        .eq('user_id', userId)
        .single()

      if (userError) {
        console.error('Error loading user:', userError)
        return
      }

      // 查询用户会话统计
      const { data: sessionsData } = await supabase
        .from('xq_user_sessions')
        .select('*')
        .eq('user_id', userId)

      // 查询用户行为统计
      const { data: eventsData } = await supabase
        .from('xq_tracking_events')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })

      const userDetail: UserDetail = {
        ...userData,
        totalSessions: sessionsData?.length || 0,
        totalMessages: eventsData?.filter(e => e.event_type === 'message').length || 0,
        totalRevenue: 0, // 暂无支付数据
        lastActiveAt: eventsData?.[0]?.created_at || userData.updated_at
      }

      setUser(userDetail)
      setEditForm({
        nickname: userDetail.nickname,
        bio: userDetail.bio,
        account_status: userDetail.account_status,
        is_member: userDetail.is_member,
        violation_reason: userDetail.violation_reason
      })
    } catch (error) {
      console.error('Error loading user detail:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSaveEdit = async () => {
    if (!user) return

    try {
      const { error } = await supabase
        .from('xq_user_profiles')
        .update(editForm)
        .eq('user_id', userId)

      if (error) {
        console.error('Error updating user:', error)
        alert('更新用户信息失败')
        return
      }

      setUser(prev => prev ? { ...prev, ...editForm } : null)
      setEditing(false)
      onUpdate?.()
      alert('用户信息更新成功')
    } catch (error) {
      console.error('Error updating user:', error)
      alert('更新用户信息失败')
    }
  }

  const handleStatusChange = async (newStatus: string, reason?: string) => {
    if (!user) return

    const updates: any = { 
      account_status: newStatus,
      updated_at: new Date().toISOString()
    }

    if (newStatus === 'suspended' || newStatus === 'violation') {
      updates.violation_reason = reason || '违规操作'
    }

    if (newStatus === 'deactivated') {
      updates.deactivated_at = new Date().toISOString()
    }

    try {
      const { error } = await supabase
        .from('xq_user_profiles')
        .update(updates)
        .eq('user_id', userId)

      if (error) {
        console.error('Error updating user status:', error)
        alert('更新用户状态失败')
        return
      }

      setUser(prev => prev ? { ...prev, ...updates } : null)
      onUpdate?.()
      alert('用户状态更新成功')
    } catch (error) {
      console.error('Error updating user status:', error)
      alert('更新用户状态失败')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-500 text-white'
      case 'inactive': return 'bg-gray-500 text-white'
      case 'suspended': return 'bg-yellow-500 text-white'
      case 'violation': return 'bg-red-500 text-white'
      case 'deactivated': return 'bg-gray-700 text-white'
      default: return 'bg-gray-500 text-white'
    }
  }

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active': return '正常'
      case 'inactive': return '未激活'
      case 'suspended': return '暂停使用'
      case 'violation': return '违规封禁'
      case 'deactivated': return '已注销'
      default: return status
    }
  }

  const formatDateTime = (datetime?: string) => {
    if (!datetime) return '无'
    return new Date(datetime).toLocaleString()
  }

  if (loading) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-4xl max-h-[90vh]">
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-500 dark:text-gray-400">加载中...</div>
          </div>
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-4xl max-h-[90vh]">
          <div className="flex items-center justify-center h-64">
            <div className="text-red-500">用户信息加载失败</div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-5xl max-h-[90vh] overflow-auto">
        {/* 标题栏 */}
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 rounded-full bg-primary-500 flex items-center justify-center text-white">
              {user.avatar_url ? (
                <img src={user.avatar_url} alt="头像" className="w-12 h-12 rounded-full" />
              ) : (
                <User size={24} />
              )}
            </div>
            <div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                {user.nickname || '未设置昵称'}
              </h2>
              <p className="text-gray-600 dark:text-gray-400">ID: {user.user_id}</p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setEditing(!editing)}
              className="flex items-center space-x-1 px-3 py-2 text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
            >
              <Edit size={16} />
              <span>{editing ? '取消编辑' : '编辑'}</span>
            </button>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
            >
              <X size={24} />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* 左侧：基本信息 */}
          <div className="lg:col-span-2 space-y-6">
            {/* 基本信息卡片 */}
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <User className="mr-2" size={20} />
                基本信息
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    昵称
                  </label>
                  {editing ? (
                    <input
                      type="text"
                      value={editForm.nickname || ''}
                      onChange={(e) => setEditForm(prev => ({ ...prev, nickname: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                    />
                  ) : (
                    <p className="text-gray-900 dark:text-white">{user.nickname || '未设置'}</p>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    性别
                  </label>
                  <p className="text-gray-900 dark:text-white">
                    {user.gender === 'male' ? '男' : user.gender === 'female' ? '女' : '未设置'}
                  </p>
                </div>
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    个人简介
                  </label>
                  {editing ? (
                    <textarea
                      value={editForm.bio || ''}
                      onChange={(e) => setEditForm(prev => ({ ...prev, bio: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                      rows={3}
                    />
                  ) : (
                    <p className="text-gray-900 dark:text-white">{user.bio || '未设置'}</p>
                  )}
                </div>
              </div>
            </div>

            {/* 账户信息卡片 */}
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <Shield className="mr-2" size={20} />
                账户信息
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    账户状态
                  </label>
                  {editing ? (
                    <select
                      value={editForm.account_status || ''}
                      onChange={(e) => setEditForm(prev => ({ ...prev, account_status: e.target.value as any }))}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                    >
                      <option value="active">正常</option>
                      <option value="inactive">未激活</option>
                      <option value="suspended">暂停使用</option>
                      <option value="violation">违规封禁</option>
                      <option value="deactivated">已注销</option>
                    </select>
                  ) : (
                    <Badge className={getStatusColor(user.account_status)}>
                      {getStatusText(user.account_status)}
                    </Badge>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    会员状态
                  </label>
                  {editing ? (
                    <div className="flex items-center">
                      <input
                        type="checkbox"
                        checked={editForm.is_member || false}
                        onChange={(e) => setEditForm(prev => ({ ...prev, is_member: e.target.checked }))}
                        className="mr-2"
                      />
                      <span className="text-gray-900 dark:text-white">会员用户</span>
                    </div>
                  ) : (
                    <Badge className={user.is_member ? 'bg-gold-500 text-white' : 'bg-gray-500 text-white'}>
                      {user.is_member ? '会员' : '非会员'}
                    </Badge>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    注册时间
                  </label>
                  <p className="text-gray-900 dark:text-white">{formatDateTime(user.created_at)}</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    最后活跃
                  </label>
                  <p className="text-gray-900 dark:text-white">{formatDateTime(user.lastActiveAt)}</p>
                </div>
                {(user.account_status === 'violation' || user.account_status === 'suspended') && (
                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      违规原因
                    </label>
                    {editing ? (
                      <input
                        type="text"
                        value={editForm.violation_reason || ''}
                        onChange={(e) => setEditForm(prev => ({ ...prev, violation_reason: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                      />
                    ) : (
                      <p className="text-red-600 dark:text-red-400">{user.violation_reason || '无'}</p>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* 第三方集成信息 */}
            {(user.wechat_openid || user.apple_user_id) && (
              <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                  第三方集成
                </h3>
                <div className="space-y-3">
                  {user.wechat_openid && (
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-xs font-bold">微</span>
                      </div>
                      <div>
                        <p className="text-gray-900 dark:text-white">{user.wechat_nickname || '微信用户'}</p>
                        <p className="text-gray-600 dark:text-gray-400 text-sm">OpenID: {user.wechat_openid}</p>
                      </div>
                    </div>
                  )}
                  {user.apple_user_id && (
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 bg-black rounded-full flex items-center justify-center">
                        <span className="text-white text-xs font-bold">A</span>
                      </div>
                      <div>
                        <p className="text-gray-900 dark:text-white">{user.apple_full_name || 'Apple用户'}</p>
                        <p className="text-gray-600 dark:text-gray-400 text-sm">{user.apple_email}</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* 右侧：统计数据和操作 */}
          <div className="space-y-6">
            {/* 使用统计 */}
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <Activity className="mr-2" size={20} />
                使用统计
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">会话次数</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{user.totalSessions}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">消息数量</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{user.totalMessages}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">AI使用次数</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{user.agents_usage_count || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">获赞数量</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{user.likes_received_count || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">总消费</span>
                  <span className="font-semibold text-gray-900 dark:text-white">¥{user.totalRevenue || 0}</span>
                </div>
              </div>
            </div>

            {/* 快速操作 */}
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                快速操作
              </h3>
              <div className="space-y-3">
                {user.account_status === 'active' && (
                  <button
                    onClick={() => handleStatusChange('suspended', '临时暂停')}
                    className="w-full flex items-center justify-center space-x-2 px-4 py-2 bg-yellow-500 hover:bg-yellow-600 text-white rounded-lg"
                  >
                    <Ban size={16} />
                    <span>暂停使用</span>
                  </button>
                )}
                {(user.account_status === 'suspended' || user.account_status === 'violation') && (
                  <button
                    onClick={() => handleStatusChange('active')}
                    className="w-full flex items-center justify-center space-x-2 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg"
                  >
                    <Unlock size={16} />
                    <span>恢复正常</span>
                  </button>
                )}
                {user.account_status === 'active' && (
                  <button
                    onClick={() => {
                      const reason = prompt('请输入违规原因：')
                      if (reason) handleStatusChange('violation', reason)
                    }}
                    className="w-full flex items-center justify-center space-x-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg"
                  >
                    <Ban size={16} />
                    <span>违规封禁</span>
                  </button>
                )}
              </div>
            </div>

            {/* 编辑操作 */}
            {editing && (
              <div className="bg-primary-50 dark:bg-primary-900/20 rounded-lg p-6">
                <div className="flex items-center justify-end space-x-3">
                  <button
                    onClick={() => setEditing(false)}
                    className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                  >
                    取消
                  </button>
                  <button
                    onClick={handleSaveEdit}
                    className="px-6 py-2 bg-primary-500 hover:bg-primary-600 text-white rounded-lg"
                  >
                    保存
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}