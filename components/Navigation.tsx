'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter, usePathname } from 'next/navigation'
import { useAuth } from '@/components/providers/AuthProvider'
import { useSidebar } from '@/components/providers/SidebarProvider'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  BarChart3,
  Users,
  Settings,
  LogOut,
  Menu,
  X,
  ChevronDown,
  Activity,
  Shield,
  Music,
  PanelLeftClose,
  PanelLeft
} from 'lucide-react'

interface NavigationProps {
  children?: React.ReactNode
}

const Navigation = ({ children }: NavigationProps) => {
  const [isMobileOpen, setIsMobileOpen] = useState(false)
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false)
  const { isCollapsed, toggleCollapse } = useSidebar()
  const { user, signOut } = useAuth()
  const pathname = usePathname()
  const router = useRouter()

  const navigation = [
    {
      name: '数据总览',
      href: '/dashboard',
      icon: LayoutDashboard,
      current: pathname === '/dashboard'
    },
    {
      name: '数据分析',
      href: '/analytics',
      icon: BarChart3,
      current: pathname === '/analytics'
    },
    {
      name: '用户管理',
      href: '/users',
      icon: Users,
      current: pathname === '/users'
    },
    {
      name: '素材管理',
      href: '/materials',
      icon: Music,
      current: pathname === '/materials'
    },
    {
      name: '内容审核',
      href: '/moderation',
      icon: Shield,
      current: pathname === '/moderation'
    },
    {
      name: '系统设置',
      href: '/settings',
      icon: Settings,
      current: pathname === '/settings'
    }
  ]

  const handleLogout = async () => {
    try {
      await signOut()
      router.push('/login')
    } catch (error) {
      console.error('注销失败:', error)
    }
  }

  return (
    <div className="flex h-screen bg-background">
      {/* Mobile menu backdrop */}
      {isMobileOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black bg-opacity-50 lg:hidden"
          onClick={() => setIsMobileOpen(false)}
        />
      )}

      {/* Sidebar - Always fixed */}
      <aside className={cn(
        "fixed inset-y-0 left-0 z-50 bg-card border-r border-border transform transition-all duration-300 ease-in-out",
        // Mobile behavior
        isMobileOpen ? "translate-x-0" : "-translate-x-full",
        // Desktop behavior  
        "lg:translate-x-0",
        isCollapsed ? "lg:w-16" : "lg:w-64",
        // Mobile width
        "w-80 max-w-[280px]"
      )}>
        <div className="flex flex-col h-screen">
          {/* Logo */}
          <div className={cn(
            "flex items-center h-16 border-b border-border transition-all duration-300",
            isCollapsed ? "justify-center px-4" : "justify-between px-6"
          )}>
            <Link href="/dashboard" className={cn(
              "flex items-center transition-all duration-300",
              isCollapsed ? "" : "space-x-3"
            )}>
              <div className="w-10 h-10 bg-gradient-to-br from-primary to-secondary rounded-xl flex items-center justify-center shadow-lg">
                <Activity size={20} className="text-primary-foreground" />
              </div>
              {!isCollapsed && (
                <div className="transition-all duration-300">
                  <span className="text-xl font-bold text-foreground">星趣管理</span>
                  <div className="text-xs text-muted-foreground">社区管理平台</div>
                </div>
              )}
            </Link>
            <div className="hidden lg:flex items-center space-x-2">
              <button
                onClick={toggleCollapse}
                className="p-1.5 rounded-md hover:bg-muted transition-colors"
                title={isCollapsed ? "展开侧边栏" : "折叠侧边栏"}
              >
                {isCollapsed ? (
                  <PanelLeft size={18} className="text-muted-foreground" />
                ) : (
                  <PanelLeftClose size={18} className="text-muted-foreground" />
                )}
              </button>
            </div>
            <button
              onClick={() => setIsMobileOpen(false)}
              className="lg:hidden p-1 rounded-md hover:bg-muted"
            >
              <X size={20} className="text-muted-foreground" />
            </button>
          </div>

          {/* Navigation */}
          <nav className={cn(
            "flex-1 py-6 space-y-2 transition-all duration-300",
            isCollapsed ? "px-2" : "px-4"
          )}>
            {navigation.map((item) => {
              const Icon = item.icon
              return (
                <div key={item.name} className="relative group">
                  <Link
                    href={item.href}
                    className={cn(
                      "flex items-center rounded-lg text-sm font-medium transition-all duration-200",
                      "relative overflow-hidden",
                      isCollapsed ? "justify-center p-3" : "space-x-3 px-3 py-3",
                      item.current
                        ? "bg-primary/10 text-primary border border-primary/20"
                        : "text-muted-foreground hover:bg-muted hover:text-foreground"
                    )}
                    onClick={() => setIsMobileOpen(false)}
                    title={isCollapsed ? item.name : undefined}
                  >
                    <Icon size={20} className="flex-shrink-0" />
                    {!isCollapsed && (
                      <span className="transition-all duration-300 whitespace-nowrap">
                        {item.name}
                      </span>
                    )}
                  </Link>
                  {/* Tooltip for collapsed state */}
                  {isCollapsed && (
                    <div className="absolute left-full top-1/2 -translate-y-1/2 ml-2 px-2 py-1 bg-popover border border-border rounded-md shadow-md opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-50">
                      <span className="text-sm text-foreground">{item.name}</span>
                    </div>
                  )}
                </div>
              )
            })}
          </nav>

          {/* User Menu */}
          <div className={cn(
            "py-4 border-t border-border transition-all duration-300",
            isCollapsed ? "px-2" : "px-4"
          )}>
            <div className="relative group">
              <button
                onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                className={cn(
                  "flex items-center w-full text-left rounded-lg hover:bg-muted transition-all duration-200",
                  isCollapsed ? "justify-center p-3" : "px-3 py-3"
                )}
                title={isCollapsed ? (user?.email || '用户') : undefined}
              >
                <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-sm font-medium text-primary">
                    {user?.email?.[0]?.toUpperCase() || 'U'}
                  </span>
                </div>
                {!isCollapsed && (
                  <>
                    <div className="flex-1 min-w-0 ml-3">
                      <p className="text-sm font-medium text-foreground truncate">
                        {user?.email || '用户'}
                      </p>
                      <p className="text-xs text-muted-foreground">管理员</p>
                    </div>
                    <ChevronDown 
                      size={16} 
                      className={cn(
                        "text-muted-foreground transition-transform",
                        isUserMenuOpen && "transform rotate-180"
                      )}
                    />
                  </>
                )}
              </button>

              {/* User Dropdown */}
              {isUserMenuOpen && (
                <div className={cn(
                  "absolute bottom-full mb-2 bg-popover border border-border rounded-lg shadow-lg py-2 z-50",
                  isCollapsed ? "left-full ml-2 w-40" : "left-0 right-0"
                )}>
                  <button
                    onClick={handleLogout}
                    className="flex items-center w-full px-4 py-2 text-sm text-muted-foreground hover:bg-muted hover:text-foreground"
                  >
                    <LogOut size={16} className="mr-3" />
                    退出登录
                  </button>
                </div>
              )}

              {/* Tooltip for collapsed state */}
              {isCollapsed && (
                <div className="absolute left-full top-1/2 -translate-y-1/2 ml-2 px-2 py-1 bg-popover border border-border rounded-md shadow-md opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-50">
                  <span className="text-sm text-foreground">{user?.email || '用户'}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </aside>

      {/* Mobile menu button */}
      <button
        onClick={() => setIsMobileOpen(true)}
        className="lg:hidden fixed top-4 left-4 z-30 p-2 bg-card border border-border rounded-lg shadow-sm"
      >
        <Menu size={20} className="text-foreground" />
      </button>

      {/* Main content wrapper */}
      <main className={cn(
        "flex-1 overflow-auto bg-background transition-all duration-300 ease-in-out",
        // Margin for sidebar
        isCollapsed ? "lg:ml-16" : "lg:ml-64",
        // No margin on mobile
        "ml-0"
      )}>
        <div className="p-4 sm:p-6">
          {children}
        </div>
      </main>
    </div>
  )
}

export default Navigation