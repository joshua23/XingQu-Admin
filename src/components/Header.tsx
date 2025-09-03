import React from 'react'
import { useAuth } from '../contexts/AuthContext'
import { LogOut, User } from 'lucide-react'
import { ThemeToggle } from './ThemeToggle'
import { Button } from './ui/Button'
import { Flex } from './ui/Grid'

const Header: React.FC = () => {
  const { user, signOut } = useAuth()

  const handleSignOut = async () => {
    await signOut()
  }

  return (
    <header className="bg-card border-b border-border px-6 py-5 animate-fade-in">
      <div className="max-w-9xl mx-auto">
        <Flex justify="between" align="center">
          <div className="flex flex-col space-y-1">
            <h1 className="text-2xl font-bold tracking-tight text-foreground">
              星趣App后台管理系统
            </h1>
            <p className="text-sm text-muted-foreground leading-relaxed">
              数据驱动的运营管理平台
            </p>
          </div>

          <Flex align="center" gap="lg">
            <ThemeToggle />
            
            <div className="flex items-center space-x-3 px-3 py-2 bg-muted/50 rounded-lg border border-border/50">
              <div className="flex items-center justify-center w-8 h-8 bg-primary/10 rounded-full">
                <User size={16} className="text-primary" />
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-medium text-foreground">
                  {user?.nickname || '管理员'}
                </span>
                <span className="text-xs text-muted-foreground">
                  {user?.user_id ? `ID: ${user.user_id}` : '系统管理员'}
                </span>
              </div>
            </div>

            <Button
              variant="ghost"
              size="sm"
              onClick={handleSignOut}
              className="flex items-center space-x-2"
            >
              <LogOut size={16} />
              <span>退出</span>
            </Button>
          </Flex>
        </Flex>
      </div>
    </header>
  )
}

export default Header
