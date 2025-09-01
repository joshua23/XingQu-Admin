import React from 'react'
import { useAuth } from '../contexts/AuthContext'
import { LogOut, User } from 'lucide-react'

const Header: React.FC = () => {
  const { user, signOut } = useAuth()

  const handleSignOut = async () => {
    await signOut()
  }

  return (
    <header className="bg-gray-800 border-b border-gray-700 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <h1 className="text-xl font-semibold text-white">星趣App后台管理系统</h1>
          <div className="text-sm text-gray-400">
            数据驱动的运营管理平台
          </div>
        </div>

        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2 text-sm text-gray-300">
            <User size={16} />
            <span>{user?.name || user?.email}</span>
          </div>
          <button
            onClick={handleSignOut}
            className="flex items-center space-x-2 px-3 py-2 text-sm text-gray-300 hover:text-white hover:bg-gray-700 rounded-lg transition-colors"
          >
            <LogOut size={16} />
            <span>退出</span>
          </button>
        </div>
      </div>
    </header>
  )
}

export default Header
