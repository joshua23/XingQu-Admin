'use client'

import React, { useState, useEffect } from 'react'
import { Users, Search, Filter, UserPlus, Ban, CheckCircle, XCircle, FileText, Upload, Download, Eye, Edit, Calendar, Clock } from 'lucide-react'
import { AddUserModal } from '@/components/modals/AddUserModal'
import { adminUserService } from '@/lib/services/adminUserService'
import { AdminUser } from '@/lib/types'

interface User {
  id: string
  nickname: string
  email: string
  avatar_url?: string
  created_at: string
  account_status: 'active' | 'inactive' | 'banned'
  is_member: boolean
  phone?: string
  last_login?: string
  agreement_accepted: boolean
  agreement_version?: string
  role: 'user' | 'premium' | 'admin'
}

const mockUsers: User[] = [
  {
    id: '1',
    nickname: '张三',
    email: 'zhangsan@example.com',
    created_at: '2024-01-15',
    account_status: 'active',
    is_member: true,
    phone: '138****1234',
    last_login: '2024-01-20 10:30',
    agreement_accepted: true,
    agreement_version: 'v2.1',
    role: 'premium'
  },
  {
    id: '2', 
    nickname: '李四',
    email: 'lisi@example.com',
    created_at: '2024-02-20',
    account_status: 'active',
    is_member: false,
    phone: '139****5678',
    last_login: '2024-02-25 14:20',
    agreement_accepted: true,
    agreement_version: 'v2.0',
    role: 'user'
  },
  {
    id: '3',
    nickname: '王五',
    email: 'wangwu@example.com', 
    created_at: '2024-03-10',
    account_status: 'inactive',
    is_member: true,
    last_login: '2024-03-05 09:15',
    agreement_accepted: false,
    agreement_version: 'v1.5',
    role: 'user'
  },
  {
    id: '4',
    nickname: '赵六',
    email: 'zhaoliu@example.com',
    created_at: '2024-03-15',
    account_status: 'banned',
    is_member: false,
    phone: '137****9012',
    last_login: '2024-03-14 16:45',
    agreement_accepted: true,
    agreement_version: 'v2.1',
    role: 'user'
  }
]

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set())
  const [showUserDetail, setShowUserDetail] = useState<AdminUser | null>(null)
  const [showAddUserModal, setShowAddUserModal] = useState(false)
  const [activeTab, setActiveTab] = useState('users')
  const [showDocumentViewer, setShowDocumentViewer] = useState(false)
  const [selectedDocument, setSelectedDocument] = useState<any>(null)

  // 加载用户数据
  const loadUsers = async () => {
    try {
      setLoading(true)
      const { data, error } = await adminUserService.getAllAdminUsers()
      
      if (error) {
        console.error('Error loading users:', error)
        // 如果数据库还没有表，使用mock数据作为fallback
        setUsers(mockUsers as any[])
      } else if (data) {
        setUsers(data)
      }
    } catch (error) {
      console.error('Error loading users:', error)
      // 使用mock数据作为fallback
      setUsers(mockUsers as any[])
    } finally {
      setLoading(false)
    }
  }

  // 页面加载时获取数据
  useEffect(() => {
    loadUsers()
  }, [])

  // 用户添加成功后重新加载数据
  const handleUserAdded = () => {
    loadUsers()
  }

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.nickname.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || user.account_status === statusFilter
    return matchesSearch && matchesStatus
  })

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800 border-green-200',
      inactive: 'bg-gray-100 text-gray-800 border-gray-200', 
      banned: 'bg-red-100 text-red-800 border-red-200'
    }
    const labels = {
      active: '活跃',
      inactive: '非活跃',
      banned: '已封禁'
    }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${styles[status as keyof typeof styles]}`}>
        {labels[status as keyof typeof labels]}
      </span>
    )
  }

  const getMembershipBadge = (isMember: boolean) => {
    return isMember ? (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-primary/10 text-primary border border-primary/20">
        会员
      </span>
    ) : (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-border">
        普通用户
      </span>
    )
  }

  const getAgreementBadge = (accepted: boolean, version?: string) => {
    return accepted ? (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-success/10 text-success border border-success/20">
        已同意 {version}
      </span>
    ) : (
      <span className="px-3 py-1 rounded-full text-xs font-medium bg-warning/10 text-warning border border-warning/20">
        未同意
      </span>
    )
  }

  const handleUserAction = async (userId: string, action: string) => {
    try {
      let updateData: Partial<AdminUser> = {}
      
      switch (action) {
        case 'activate':
          updateData = { account_status: 'active' }
          break
        case 'deactivate':
          updateData = { account_status: 'inactive' }
          break
        case 'ban':
          updateData = { account_status: 'banned' }
          break
        default:
          return
      }

      const { error } = await adminUserService.updateAdminUser(userId, updateData)
      
      if (error) {
        console.error('Error updating user:', error)
        return
      }

      // 重新加载数据
      loadUsers()
    } catch (error) {
      console.error('Error updating user:', error)
    }
  }

  // 模拟的文档数据（包含docs中的实际文档）
  const documents = [
    {
      id: '1',
      name: '星趣用户协议',
      type: '用户协议',
      version: 'v2.1',
      status: 'active',
      lastUpdated: '2025-09-01',
      fileSize: '12.5KB',
      description: '星趣平台用户协议，包含用户权利义务、服务条款等',
      content: `星趣用户协议

更新日期：2025年9月1日
欢迎您使用星趣！

特别提示

为了更好地为您提供服务，请您在开始使用星趣产品和服务之前，认真阅读并充分理解《星趣用户协议》（"本协议"或"用户协议"）及《星趣隐私政策》（"隐私政策"），特别是涉及免除或者限制责任的条款、权利许可和信息使用的条款、同意开通和使用特殊单项服务的条款、法律适用和争议解决条款等。该等内容将以加粗和/或划线形式提示您注意，您应重点阅读。

您点击确认本协议、以其他方式同意本协议或实际使用星趣产品和服务的，即表示您同意、接受并承诺遵守本协议的全部内容。

一、协议的范围

1.1 本协议是您（即用户）与上海启垒应网络科技有限公司及其关联公司（合称"我们"）之间关于用户使用星趣产品和服务所订立的协议。
1.3 我们根据本协议，通过星趣向用户提供的服务（"本服务"），包括但不限于人工智能（"AI"）相关的智能对话、问答等服务。
1.4 就具体服务，您可能需要在与我们订立特定服务条款或具体产品协议（统称"具体产品协议"）后方可使用。

二、服务内容

2.1 用户在使用本服务前需要提前使用手机号注册认证以获得【星趣】账户。
2.2 本产品的具体功能由星趣根据实际情况提供，包括但不限于虚拟智能体连结、对话、获得成就、客服服务等。
2.3 我们将按照《个人信息保护法》等相关法律法规保护您的个人信息。

三、服务使用规则

3.1 用户在本服务中或通过本服务所传送、发布的任何内容并不反映或代表，也不得被视为反映或代表我们的观点、立场或政策。
3.2 用户在本产品注册时，不得使用虚假身份信息。用户应当妥善保管其账户信息和密码。

四、知识产权声明

4.1 星趣在星趣软件及相关服务中提供的自有内容的知识产权及相关权益归属于我们。
4.2 您理解并承诺，您在使用星趣软件及相关服务时上传的内容均由您原创或已获得合法授权。

如对本协议内容有任何疑问、意见或建议，您可发送邮件至 report@xingquai.com 与星趣联系。`
    },
    {
      id: '2', 
      name: '隐私政策',
      type: '隐私政策',
      version: 'v1.8',
      status: 'active',
      lastUpdated: '2025-08-15',
      fileSize: '8.2KB',
      description: '数据收集、处理、存储和保护的相关规定',
      content: '# 隐私政策\n\n生效日期：2025年8月15日\n\n我们非常重视您的隐私保护...'
    },
    {
      id: '3',
      name: '服务条款',
      type: '服务条款', 
      version: 'v1.5',
      status: 'draft',
      lastUpdated: '2025-08-30',
      fileSize: '6.8KB',
      description: '服务提供、使用规范和限制条款',
      content: '# 服务条款\n\n更新日期：2025年8月30日\n\n本服务条款适用于...'
    }
  ]

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (files && files.length > 0) {
      const file = files[0]
      // 这里可以添加文件上传逻辑
      console.log('上传文件:', file.name)
      // 重置输入框
      event.target.value = ''
    }
  }

  const handleViewDocument = (doc: any) => {
    setSelectedDocument(doc)
    setShowDocumentViewer(true)
  }

  if (activeTab === 'documents') {
    return (
      <div className="space-y-3">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-foreground">用户管理</h1>
            <p className="text-sm text-muted-foreground">管理系统中的所有用户账户和隐私协议</p>
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-card border border-border rounded-lg">
          <div className="flex border-b border-border">
            <button
              onClick={() => setActiveTab('users')}
              className="px-6 py-4 font-medium text-sm transition-colors text-muted-foreground hover:text-foreground"
            >
              <div className="flex items-center space-x-2">
                <Users size={16} />
                <span>用户列表</span>
              </div>
            </button>
            <button
              onClick={() => setActiveTab('documents')}
              className="px-6 py-4 font-medium text-sm transition-colors border-b-2 border-primary text-primary bg-primary/5"
            >
              <div className="flex items-center space-x-2">
                <FileText size={16} />
                <span>隐私/用户协议管理</span>
              </div>
            </button>
          </div>
        </div>

        {/* Upload Section */}
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-foreground">文档上传</h3>
            <div className="flex items-center space-x-3">
              <input
                type="file"
                id="document-upload"
                accept=".md,.txt,.pdf,.doc,.docx"
                onChange={handleFileUpload}
                className="hidden"
              />
              <label
                htmlFor="document-upload"
                className="flex items-center space-x-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors cursor-pointer"
              >
                <Upload size={16} />
                <span>上传文档</span>
              </label>
            </div>
          </div>
          <p className="text-sm text-muted-foreground">
            支持上传 .md、.txt、.pdf、.doc、.docx 格式的文档，用于更新用户协议和隐私政策。
          </p>
        </div>

        {/* Documents List */}
        <div className="bg-card border border-border rounded-lg overflow-hidden">
          <div className="p-6 border-b border-border">
            <h3 className="text-lg font-semibold text-foreground">协议文档管理</h3>
            <p className="text-sm text-muted-foreground mt-1">管理当前生效的用户协议、隐私政策等法律文档</p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-muted/50 border-b border-border">
                <tr>
                  <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">文档信息</th>
                  <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">类型</th>
                  <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">版本</th>
                  <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">状态</th>
                  <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">最后更新</th>
                  <th className="text-center py-4 px-6 font-medium text-sm text-muted-foreground">操作</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {documents.map((doc) => (
                  <tr key={doc.id} className="hover:bg-muted/30 transition-colors">
                    <td className="py-4 px-6">
                      <div className="space-y-1">
                        <div className="font-medium text-foreground">{doc.name}</div>
                        <div className="text-xs text-muted-foreground">{doc.description}</div>
                        <div className="text-xs text-muted-foreground">大小: {doc.fileSize}</div>
                      </div>
                    </td>
                    <td className="py-4 px-6">
                      <span className="px-2 py-1 rounded-full text-xs font-medium bg-primary/10 text-primary border border-primary/20">
                        {doc.type}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      <span className="text-sm font-medium text-foreground">{doc.version}</span>
                    </td>
                    <td className="py-4 px-6">
                      {doc.status === 'active' ? (
                        <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                          生效中
                        </span>
                      ) : (
                        <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 border border-gray-200">
                          草稿
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-6">
                      <div className="flex items-center space-x-2 text-sm text-muted-foreground">
                        <Calendar size={14} />
                        <span>{doc.lastUpdated}</span>
                      </div>
                    </td>
                    <td className="py-4 px-6">
                      <div className="flex items-center justify-center space-x-2">
                        <button
                          onClick={() => handleViewDocument(doc)}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="查看内容"
                        >
                          <Eye size={16} className="text-primary" />
                        </button>
                        <button
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="编辑文档"
                        >
                          <Edit size={16} className="text-blue-500" />
                        </button>
                        <button
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="下载文档"
                        >
                          <Download size={16} className="text-green-500" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {documents.length === 0 && (
            <div className="text-center py-12">
              <FileText size={48} className="mx-auto text-muted-foreground mb-4" />
              <h3 className="text-lg font-medium text-foreground mb-2">暂无协议文档</h3>
              <p className="text-muted-foreground">请上传用户协议或隐私政策文档</p>
            </div>
          )}
        </div>

        {/* Document Viewer Modal */}
        {showDocumentViewer && selectedDocument && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-card border border-border rounded-lg max-w-4xl w-full max-h-[90vh] flex flex-col">
              {/* Modal Header */}
              <div className="p-6 border-b border-border flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold text-foreground">{selectedDocument.name}</h3>
                  <p className="text-sm text-muted-foreground">
                    {selectedDocument.type} · 版本 {selectedDocument.version} · 更新于 {selectedDocument.lastUpdated}
                  </p>
                </div>
                <button
                  onClick={() => setShowDocumentViewer(false)}
                  className="p-2 rounded-lg hover:bg-muted transition-colors"
                >
                  <XCircle size={20} className="text-muted-foreground" />
                </button>
              </div>

              {/* Modal Content */}
              <div className="flex-1 p-6 overflow-y-auto">
                <div className="prose prose-sm max-w-none">
                  <pre className="whitespace-pre-wrap font-sans text-sm leading-relaxed text-foreground">
                    {selectedDocument.content}
                  </pre>
                </div>
              </div>

              {/* Modal Footer */}
              <div className="p-6 border-t border-border flex items-center justify-end space-x-3">
                <button
                  onClick={() => setShowDocumentViewer(false)}
                  className="px-4 py-2 text-muted-foreground hover:text-foreground transition-colors"
                >
                  关闭
                </button>
                <button className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors">
                  编辑文档
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">用户管理</h1>
          <p className="text-sm text-muted-foreground">管理系统中的所有用户账户和隐私协议</p>
        </div>
        <button 
          onClick={() => setShowAddUserModal(true)}
          className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-primary to-secondary text-primary-foreground rounded-xl hover:shadow-lg hover:shadow-primary/25 transition-all duration-200 font-medium"
        >
          <UserPlus size={18} />
          <span>添加用户</span>
        </button>
      </div>

      {/* Tabs */}
      <div className="bg-card border border-border rounded-lg">
        <div className="flex border-b border-border">
          <button
            onClick={() => setActiveTab('users')}
            className="px-6 py-4 font-medium text-sm transition-colors border-b-2 border-primary text-primary bg-primary/5"
          >
            <div className="flex items-center space-x-2">
              <Users size={16} />
              <span>用户列表</span>
            </div>
          </button>
          <button
            onClick={() => setActiveTab('documents')}
            className="px-6 py-4 font-medium text-sm transition-colors text-muted-foreground hover:text-foreground"
          >
            <div className="flex items-center space-x-2">
              <FileText size={16} />
              <span>隐私/用户协议管理</span>
            </div>
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-card border border-border rounded-lg p-6 mt-3">
        <div className="flex flex-col sm:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="搜索用户..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            />
          </div>
          
          {/* Status Filter */}
          <div className="flex items-center space-x-2">
            <Filter size={16} className="text-muted-foreground" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-3 bg-background border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-colors"
            >
              <option value="all">所有状态</option>
              <option value="active">活跃</option>
              <option value="inactive">非活跃</option>
              <option value="banned">已封禁</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-card border border-border rounded-lg overflow-hidden mt-3">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-muted/50 border-b border-border">
              <tr>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">用户</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">联系信息</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">账户状态</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">会员类型</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">用户协议</th>
                <th className="text-left py-4 px-6 font-medium text-sm text-muted-foreground">最后登录</th>
                <th className="text-center py-4 px-6 font-medium text-sm text-muted-foreground">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-muted/30 transition-colors">
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                        <span className="text-sm font-medium text-primary">
                          {user.nickname[0]}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium text-foreground">{user.nickname}</div>
                        <div className="text-xs text-muted-foreground">ID: {user.id}</div>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="space-y-1">
                      <div className="text-sm text-foreground">{user.email}</div>
                      {user.phone && (
                        <div className="text-xs text-muted-foreground">{user.phone}</div>
                      )}
                    </div>
                  </td>
                  <td className="py-4 px-6">{getStatusBadge(user.account_status)}</td>
                  <td className="py-4 px-6">{getMembershipBadge(user.role === 'premium' || user.role === 'admin')}</td>
                  <td className="py-4 px-6">{getAgreementBadge(user.agreement_accepted || false, user.agreement_version)}</td>
                  <td className="py-4 px-6">
                    <div className="text-sm text-muted-foreground">
                      {user.last_login || '未登录'}
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex items-center justify-center space-x-2">
                      {user.account_status === 'active' ? (
                        <button 
                          onClick={() => handleUserAction(user.id, 'deactivate')}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="停用账户"
                        >
                          <XCircle size={16} className="text-orange-500" />
                        </button>
                      ) : user.account_status === 'inactive' ? (
                        <button 
                          onClick={() => handleUserAction(user.id, 'activate')}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="激活账户"
                        >
                          <CheckCircle size={16} className="text-green-500" />
                        </button>
                      ) : null}
                      {user.account_status !== 'banned' && (
                        <button 
                          onClick={() => handleUserAction(user.id, 'ban')}
                          className="p-1 rounded-lg hover:bg-muted transition-colors"
                          title="封禁账户"
                        >
                          <Ban size={16} className="text-red-500" />
                        </button>
                      )}
                      <button 
                        onClick={() => setShowUserDetail(user)}
                        className="p-1 rounded-lg hover:bg-muted transition-colors"
                        title="查看详情"
                      >
                        <FileText size={16} className="text-primary" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {filteredUsers.length === 0 && (
          <div className="text-center py-12">
            <Users size={48} className="mx-auto text-muted-foreground mb-4" />
            <h3 className="text-lg font-medium text-foreground mb-2">没有找到用户</h3>
            <p className="text-muted-foreground">请尝试调整搜索条件或添加新用户</p>
          </div>
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mt-3">
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-foreground">{users.length}</div>
          <div className="text-sm text-muted-foreground">总用户数</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-success">
            {users.filter(u => u.account_status === 'active').length}
          </div>
          <div className="text-sm text-muted-foreground">活跃用户</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-primary">
            {users.filter(u => u.role === 'premium' || u.role === 'admin').length}
          </div>
          <div className="text-sm text-muted-foreground">会员用户</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-6">
          <div className="text-2xl font-bold text-warning">
            {users.filter(u => u.account_status === 'inactive').length}
          </div>
          <div className="text-sm text-muted-foreground">非活跃用户</div>
        </div>
      </div>

      {/* Add User Modal */}
      <AddUserModal
        isOpen={showAddUserModal}
        onClose={() => setShowAddUserModal(false)}
        onUserAdded={handleUserAdded}
      />

      {/* Loading overlay */}
      {loading && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-40">
          <div className="bg-card rounded-lg p-6 flex items-center space-x-3">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            <span className="text-foreground">加载中...</span>
          </div>
        </div>
      )}
    </div>
  )
}