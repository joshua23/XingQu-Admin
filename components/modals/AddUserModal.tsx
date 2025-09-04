'use client'

import React, { useState } from 'react'
import { X, User, Mail, Phone, Shield, Save } from 'lucide-react'
import { adminUserService } from '@/lib/services/adminUserService'
import { CreateAdminUserData } from '@/lib/types'

interface AddUserModalProps {
  isOpen: boolean
  onClose: () => void
  onUserAdded: () => void
}

export const AddUserModal: React.FC<AddUserModalProps> = ({
  isOpen,
  onClose,
  onUserAdded
}) => {
  const [formData, setFormData] = useState<CreateAdminUserData>({
    email: '',
    nickname: '',
    phone: '',
    role: 'admin',
    permissions: ['read', 'write']
  })
  
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const { data, error } = await adminUserService.createAdminUser(formData)
      
      if (error) {
        setError(error.message || '创建用户失败')
        return
      }

      if (data) {
        onUserAdded()
        onClose()
        setFormData({
          email: '',
          nickname: '',
          phone: '',
          role: 'admin',
          permissions: ['read', 'write']
        })
      }
    } catch (err) {
      setError('创建用户时发生错误')
      console.error('Error creating user:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (field: keyof CreateAdminUserData, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-card border border-border rounded-xl shadow-xl w-full max-w-md mx-4">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-border">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
              <User size={20} className="text-primary" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-foreground">添加新用户</h2>
              <p className="text-sm text-muted-foreground">创建新的管理员账户</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-muted rounded-lg transition-colors"
          >
            <X size={20} className="text-muted-foreground" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {error && (
            <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg text-destructive text-sm">
              {error}
            </div>
          )}

          {/* Email */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              <Mail size={16} className="inline mr-2" />
              邮箱地址
            </label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => handleInputChange('email', e.target.value)}
              className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
              placeholder="user@xingqu.com"
            />
          </div>

          {/* Nickname */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              <User size={16} className="inline mr-2" />
              用户昵称
            </label>
            <input
              type="text"
              required
              value={formData.nickname}
              onChange={(e) => handleInputChange('nickname', e.target.value)}
              className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
              placeholder="输入用户昵称"
            />
          </div>

          {/* Phone */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              <Phone size={16} className="inline mr-2" />
              手机号码
            </label>
            <input
              type="tel"
              value={formData.phone || ''}
              onChange={(e) => handleInputChange('phone', e.target.value)}
              className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
              placeholder="输入手机号码（可选）"
            />
          </div>

          {/* Role */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              <Shield size={16} className="inline mr-2" />
              用户角色
            </label>
            <select
              value={formData.role}
              onChange={(e) => handleInputChange('role', e.target.value as 'admin' | 'super_admin' | 'moderator')}
              className="w-full px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            >
              <option value="admin">普通管理员</option>
              <option value="moderator">内容审核员</option>
              <option value="super_admin">超级管理员</option>
            </select>
          </div>

          {/* Permissions */}
          <div>
            <label className="block text-sm font-medium text-foreground mb-3">
              权限设置
            </label>
            <div className="space-y-2">
              {[
                { key: 'read', label: '查看权限' },
                { key: 'write', label: '编辑权限' },
                { key: 'delete', label: '删除权限' },
                { key: 'manage_users', label: '用户管理' },
                { key: 'manage_content', label: '内容管理' }
              ].map(permission => (
                <label key={permission.key} className="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.permissions.includes(permission.key)}
                    onChange={(e) => {
                      const currentPermissions = formData.permissions
                      if (e.target.checked) {
                        handleInputChange('permissions', [...currentPermissions, permission.key])
                      } else {
                        handleInputChange('permissions', currentPermissions.filter(p => p !== permission.key))
                      }
                    }}
                    className="w-4 h-4 text-primary bg-background border-border rounded focus:ring-primary focus:ring-2"
                  />
                  <span className="text-sm text-foreground">{permission.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end space-x-3 pt-4 border-t border-border">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              取消
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-primary to-secondary text-primary-foreground rounded-xl hover:shadow-lg hover:shadow-primary/25 transition-all duration-200 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Save size={16} />
              <span>{loading ? '创建中...' : '创建用户'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}