'use client'

import { Moon, Sun } from 'lucide-react'
import { useTheme } from 'next-themes'
import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

interface ThemeToggleProps {
  className?: string
  size?: 'sm' | 'md' | 'lg'
}

export function ThemeToggle({ className, size = 'md' }: ThemeToggleProps) {
  const { theme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <div className={cn(
        "rounded-lg border border-border bg-background hover:bg-muted",
        size === 'sm' && "p-2",
        size === 'md' && "p-2.5",
        size === 'lg' && "p-3",
        className
      )}>
        <div className={cn(
          size === 'sm' && "w-4 h-4",
          size === 'md' && "w-5 h-5", 
          size === 'lg' && "w-6 h-6"
        )} />
      </div>
    )
  }

  return (
    <button
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      className={cn(
        "rounded-lg border border-border bg-background hover:bg-muted transition-colors duration-200",
        size === 'sm' && "p-2",
        size === 'md' && "p-2.5", 
        size === 'lg' && "p-3",
        className
      )}
      title={theme === 'dark' ? '切换到浅色模式' : '切换到深色模式'}
    >
      {theme === 'dark' ? (
        <Sun className={cn(
          "text-foreground",
          size === 'sm' && "w-4 h-4",
          size === 'md' && "w-5 h-5",
          size === 'lg' && "w-6 h-6"
        )} />
      ) : (
        <Moon className={cn(
          "text-foreground", 
          size === 'sm' && "w-4 h-4",
          size === 'md' && "w-5 h-5",
          size === 'lg' && "w-6 h-6"
        )} />
      )}
    </button>
  )
}