import * as React from "react"
import { cn } from "@/lib/utils"

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'destructive' | 'outline'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', loading = false, children, disabled, ...props }, ref) => {
    const variants = {
      primary: "bg-primary hover:bg-primary-hover text-primary-foreground shadow-sm hover:shadow-md focus:ring-ring",
      secondary: "bg-secondary hover:bg-secondary/80 text-secondary-foreground border border-border hover:border-border/60 focus:ring-ring",
      ghost: "bg-transparent hover:bg-muted text-foreground focus:ring-ring",
      destructive: "bg-destructive hover:bg-destructive/90 text-destructive-foreground shadow-sm hover:shadow-md focus:ring-destructive",
      outline: "bg-transparent border border-border hover:bg-muted text-foreground focus:ring-ring"
    }

    const sizes = {
      sm: "px-4 py-2 text-sm font-medium",
      md: "px-6 py-3 text-base font-semibold", 
      lg: "px-8 py-4 text-lg font-bold"
    }

    return (
      <button
        className={cn(
          "inline-flex items-center justify-center rounded-lg transition-all duration-200 ease-out",
          "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-background",
          "disabled:opacity-50 disabled:cursor-not-allowed",
          variants[variant],
          sizes[size],
          loading && "cursor-not-allowed",
          className
        )}
        ref={ref}
        disabled={disabled || loading}
        {...props}
      >
        {loading && (
          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2" />
        )}
        {children}
      </button>
    )
  }
)

Button.displayName = "Button"

export { Button }