import React, { useState } from 'react'
import { 
  X, 
  Users, 
  Ban, 
  Unlock, 
  Mail, 
  Download,
  Crown,
  AlertTriangle,
  CheckCircle
} from 'lucide-react'
import { supabase } from '../../services/supabase'

interface BatchOperationsModalProps {
  selectedUsers: string[]
  onClose: () => void
  onSuccess: () => void
}

type BatchOperation = 
  | 'suspend'
  | 'activate' 
  | 'ban'
  | 'unban'
  | 'make_member'
  | 'remove_member'
  | 'send_notification'
  | 'export'

interface BatchOperationConfig {
  id: BatchOperation
  name: string
  description: string
  icon: React.ReactNode
  color: string
  requiresReason?: boolean
  requiresContent?: boolean
  confirmText?: string
}

const BATCH_OPERATIONS: BatchOperationConfig[] = [
  {
    id: 'suspend',
    name: '批量暂停',
    description: '暂停选中用户的使用权限',
    icon: <Ban size={20} />,
    color: 'bg-yellow-500',
    requiresReason: true,
    confirmText: '确定要暂停这些用户吗？'
  },
  {
    id: 'activate',
    name: '批量激活',
    description: '激活选中用户，恢复正常使用',
    icon: <Unlock size={20} />,
    color: 'bg-green-500',
    confirmText: '确定要激活这些用户吗？'
  },
  {
    id: 'ban',
    name: '批量封禁',
    description: '封禁选中用户，禁止使用',
    icon: <AlertTriangle size={20} />,
    color: 'bg-red-500',
    requiresReason: true,
    confirmText: '确定要封禁这些用户吗？此操作较严重，请谨慎使用。'
  },
  {
    id: 'unban',
    name: '批量解封',
    description: '解除选中用户的封禁状态',
    icon: <CheckCircle size={20} />,
    color: 'bg-blue-500',
    confirmText: '确定要解封这些用户吗？'
  },
  {
    id: 'make_member',
    name: '批量设为会员',
    description: '将选中用户设置为会员',
    icon: <Crown size={20} />,
    color: 'bg-purple-500',
    confirmText: '确定要将这些用户设为会员吗？'
  },
  {
    id: 'remove_member',
    name: '批量取消会员',
    description: '取消选中用户的会员资格',
    icon: <Crown size={20} />,
    color: 'bg-gray-500',
    confirmText: '确定要取消这些用户的会员资格吗？'
  },
  {
    id: 'send_notification',
    name: '批量发送通知',
    description: '向选中用户发送系统通知',
    icon: <Mail size={20} />,
    color: 'bg-indigo-500',
    requiresContent: true
  },
  {
    id: 'export',
    name: '导出用户数据',
    description: '导出选中用户的详细信息',
    icon: <Download size={20} />,
    color: 'bg-teal-500'
  }
]

export const BatchOperationsModal: React.FC<BatchOperationsModalProps> = ({
  selectedUsers,
  onClose,
  onSuccess
}) => {
  const [selectedOperation, setSelectedOperation] = useState<BatchOperation | null>(null)
  const [reason, setReason] = useState('')
  const [content, setContent] = useState('')
  const [processing, setProcessing] = useState(false)
  const [step, setStep] = useState<'select' | 'configure' | 'confirm'>('select')

  const getOperationConfig = (id: BatchOperation) => {
    return BATCH_OPERATIONS.find(op => op.id === id)!
  }

  const handleOperationSelect = (operation: BatchOperation) => {
    setSelectedOperation(operation)
    setStep('configure')
  }

  const handleExecute = async () => {
    if (!selectedOperation) return

    const config = getOperationConfig(selectedOperation)
    
    // 确认操作
    if (config.confirmText && !window.confirm(config.confirmText)) {
      return
    }

    setProcessing(true)
    
    try {
      let success = false
      
      switch (selectedOperation) {
        case 'suspend':
          success = await executeSuspend()
          break
        case 'activate':
          success = await executeActivate()
          break
        case 'ban':
          success = await executeBan()
          break
        case 'unban':
          success = await executeUnban()
          break
        case 'make_member':
          success = await executeMakeMember()
          break
        case 'remove_member':
          success = await executeRemoveMember()
          break
        case 'send_notification':
          success = await executeSendNotification()
          break
        case 'export':
          success = await executeExport()
          break
      }

      if (success) {
        alert(`批量操作成功，共处理 ${selectedUsers.length} 个用户`)
        onSuccess()
        onClose()
      } else {
        alert('批量操作失败，请重试')
      }
    } catch (error) {
      console.error('Batch operation error:', error)
      alert('批量操作失败，请重试')
    } finally {
      setProcessing(false)
    }
  }

  const executeSuspend = async () => {
    const { error } = await supabase
      .from('xq_user_profiles')
      .update({
        account_status: 'suspended',
        violation_reason: reason,
        updated_at: new Date().toISOString()
      })
      .in('user_id', selectedUsers)

    return !error
  }

  const executeActivate = async () => {
    const { error } = await supabase
      .from('xq_user_profiles')
      .update({
        account_status: 'active',
        violation_reason: null,
        updated_at: new Date().toISOString()
      })
      .in('user_id', selectedUsers)

    return !error
  }

  const executeBan = async () => {
    const { error } = await supabase
      .from('xq_user_profiles')
      .update({
        account_status: 'violation',
        violation_reason: reason,
        updated_at: new Date().toISOString()
      })
      .in('user_id', selectedUsers)

    return !error
  }

  const executeUnban = async () => {
    const { error } = await supabase
      .from('xq_user_profiles')
      .update({
        account_status: 'active',
        violation_reason: null,
        updated_at: new Date().toISOString()
      })
      .in('user_id', selectedUsers)

    return !error
  }

  const executeMakeMember = async () => {
    const membershipExpires = new Date()
    membershipExpires.setMonth(membershipExpires.getMonth() + 1) // 默认1个月会员

    const { error } = await supabase
      .from('xq_user_profiles')
      .update({
        is_member: true,
        membership_expires_at: membershipExpires.toISOString(),
        updated_at: new Date().toISOString()
      })
      .in('user_id', selectedUsers)

    return !error
  }

  const executeRemoveMember = async () => {
    const { error } = await supabase
      .from('xq_user_profiles')
      .update({
        is_member: false,
        membership_expires_at: null,
        updated_at: new Date().toISOString()
      })
      .in('user_id', selectedUsers)

    return !error
  }

  const executeSendNotification = async () => {
    // 这里应该调用发送通知的API
    // 暂时模拟成功
    console.log('发送通知给用户：', selectedUsers, '内容：', content)
    return true
  }

  const executeExport = async () => {
    try {
      const { data, error } = await supabase
        .from('xq_user_profiles')
        .select('*')
        .in('user_id', selectedUsers)

      if (error) {
        console.error('Export error:', error)
        return false
      }

      // 创建CSV内容
      const csvContent = [
        // CSV标题行
        '用户ID,昵称,性别,账户状态,会员状态,注册时间,最后更新',
        // 数据行
        ...data.map(user => [
          user.user_id,
          user.nickname || '',
          user.gender || '',
          user.account_status,
          user.is_member ? '会员' : '非会员',
          user.created_at,
          user.updated_at || ''
        ].join(','))
      ].join('\n')

      // 下载CSV文件
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `用户数据_${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)

      return true
    } catch (error) {
      console.error('Export error:', error)
      return false
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-auto">
        {/* 标题栏 */}
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center space-x-3">
            <Users className="text-primary-500" size={24} />
            <div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white">批量操作</h2>
              <p className="text-gray-600 dark:text-gray-400">
                已选中 {selectedUsers.length} 个用户
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <X size={24} />
          </button>
        </div>

        {/* 步骤指示器 */}
        <div className="flex items-center justify-center mb-8">
          <div className="flex items-center space-x-4">
            <div className={`flex items-center justify-center w-8 h-8 rounded-full ${
              step === 'select' ? 'bg-primary-500 text-white' : 'bg-gray-300 dark:bg-gray-600 text-gray-600 dark:text-gray-300'
            }`}>
              1
            </div>
            <div className="h-px w-12 bg-gray-300 dark:bg-gray-600"></div>
            <div className={`flex items-center justify-center w-8 h-8 rounded-full ${
              step === 'configure' ? 'bg-primary-500 text-white' : 'bg-gray-300 dark:bg-gray-600 text-gray-600 dark:text-gray-300'
            }`}>
              2
            </div>
            <div className="h-px w-12 bg-gray-300 dark:bg-gray-600"></div>
            <div className={`flex items-center justify-center w-8 h-8 rounded-full ${
              step === 'confirm' ? 'bg-primary-500 text-white' : 'bg-gray-300 dark:bg-gray-600 text-gray-600 dark:text-gray-300'
            }`}>
              3
            </div>
          </div>
        </div>

        {/* 步骤1：选择操作 */}
        {step === 'select' && (
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              选择要执行的操作
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {BATCH_OPERATIONS.map((operation) => (
                <button
                  key={operation.id}
                  onClick={() => handleOperationSelect(operation.id)}
                  className="flex items-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:border-primary-500 dark:hover:border-primary-400 transition-colors group"
                >
                  <div className={`flex items-center justify-center w-12 h-12 rounded-lg ${operation.color} text-white mr-4 group-hover:scale-110 transition-transform`}>
                    {operation.icon}
                  </div>
                  <div className="flex-1 text-left">
                    <h4 className="text-gray-900 dark:text-white font-semibold">{operation.name}</h4>
                    <p className="text-gray-600 dark:text-gray-400 text-sm">{operation.description}</p>
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* 步骤2：配置参数 */}
        {step === 'configure' && selectedOperation && (
          <div>
            <div className="mb-6">
              <div className="flex items-center space-x-3 mb-4">
                <div className={`flex items-center justify-center w-12 h-12 rounded-lg ${getOperationConfig(selectedOperation).color} text-white`}>
                  {getOperationConfig(selectedOperation).icon}
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                    {getOperationConfig(selectedOperation).name}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-400">
                    {getOperationConfig(selectedOperation).description}
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              {getOperationConfig(selectedOperation).requiresReason && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    操作原因 *
                  </label>
                  <input
                    type="text"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="请输入操作原因..."
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    required
                  />
                </div>
              )}

              {getOperationConfig(selectedOperation).requiresContent && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    通知内容 *
                  </label>
                  <textarea
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    placeholder="请输入要发送的通知内容..."
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    rows={4}
                    required
                  />
                </div>
              )}

              <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                <div className="flex items-start space-x-2">
                  <AlertTriangle className="text-yellow-600 dark:text-yellow-400 mt-0.5" size={16} />
                  <div>
                    <h4 className="text-yellow-800 dark:text-yellow-200 font-medium text-sm">注意事项</h4>
                    <p className="text-yellow-700 dark:text-yellow-300 text-sm mt-1">
                      此操作将影响 {selectedUsers.length} 个用户，执行后无法撤销，请确认操作正确。
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between mt-8">
              <button
                onClick={() => setStep('select')}
                className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
              >
                上一步
              </button>
              <button
                onClick={() => setStep('confirm')}
                disabled={
                  (getOperationConfig(selectedOperation).requiresReason && !reason.trim()) ||
                  (getOperationConfig(selectedOperation).requiresContent && !content.trim())
                }
                className="px-6 py-2 bg-primary-500 hover:bg-primary-600 disabled:bg-gray-400 disabled:cursor-not-allowed text-white rounded-lg"
              >
                下一步
              </button>
            </div>
          </div>
        )}

        {/* 步骤3：确认执行 */}
        {step === 'confirm' && selectedOperation && (
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
              确认操作信息
            </h3>

            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 mb-6">
              <div className="flex items-center space-x-3 mb-4">
                <div className={`flex items-center justify-center w-12 h-12 rounded-lg ${getOperationConfig(selectedOperation).color} text-white`}>
                  {getOperationConfig(selectedOperation).icon}
                </div>
                <div>
                  <h4 className="text-lg font-semibold text-gray-900 dark:text-white">
                    {getOperationConfig(selectedOperation).name}
                  </h4>
                  <p className="text-gray-600 dark:text-gray-400">
                    影响用户数量：{selectedUsers.length} 个
                  </p>
                </div>
              </div>

              {reason && (
                <div className="mb-3">
                  <span className="text-sm font-medium text-gray-700 dark:text-gray-300">操作原因：</span>
                  <span className="text-gray-900 dark:text-white ml-2">{reason}</span>
                </div>
              )}

              {content && (
                <div>
                  <span className="text-sm font-medium text-gray-700 dark:text-gray-300">通知内容：</span>
                  <div className="mt-2 p-3 bg-white dark:bg-gray-800 rounded border">
                    <p className="text-gray-900 dark:text-white whitespace-pre-wrap">{content}</p>
                  </div>
                </div>
              )}
            </div>

            <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
              <div className="flex items-start space-x-2">
                <AlertTriangle className="text-red-600 dark:text-red-400 mt-0.5" size={16} />
                <div>
                  <h4 className="text-red-800 dark:text-red-200 font-medium text-sm">最终确认</h4>
                  <p className="text-red-700 dark:text-red-300 text-sm mt-1">
                    请再次确认操作信息无误，点击"执行操作"后将立即生效，无法撤销。
                  </p>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <button
                onClick={() => setStep('configure')}
                className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
              >
                上一步
              </button>
              <div className="space-x-3">
                <button
                  onClick={onClose}
                  className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                >
                  取消
                </button>
                <button
                  onClick={handleExecute}
                  disabled={processing}
                  className="px-6 py-2 bg-red-500 hover:bg-red-600 disabled:bg-red-500/50 disabled:cursor-not-allowed text-white rounded-lg"
                >
                  {processing ? '执行中...' : '执行操作'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}