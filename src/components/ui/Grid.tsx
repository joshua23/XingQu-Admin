import React from 'react'
import { cn } from '@/lib/utils'

// Container component with responsive max-width and padding
interface ContainerProps extends React.HTMLAttributes<HTMLDivElement> {
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'
}

export const Container: React.FC<ContainerProps> = ({ 
  className, 
  size = 'xl',
  children, 
  ...props 
}) => {
  const containerClasses = {
    sm: 'max-w-2xl',
    md: 'max-w-4xl', 
    lg: 'max-w-6xl',
    xl: 'max-w-7xl',
    full: 'max-w-none'
  }

  return (
    <div
      className={cn(
        'mx-auto px-4 sm:px-6 lg:px-8',
        containerClasses[size],
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

// Grid component with responsive columns
interface GridProps extends React.HTMLAttributes<HTMLDivElement> {
  cols?: 1 | 2 | 3 | 4 | 5 | 6 | 12
  gap?: 'sm' | 'md' | 'lg' | 'xl'
  responsive?: {
    sm?: 1 | 2 | 3 | 4 | 5 | 6 | 12
    md?: 1 | 2 | 3 | 4 | 5 | 6 | 12
    lg?: 1 | 2 | 3 | 4 | 5 | 6 | 12
    xl?: 1 | 2 | 3 | 4 | 5 | 6 | 12
  }
}

export const Grid: React.FC<GridProps> = ({ 
  className,
  cols = 1,
  gap = 'md',
  responsive,
  children,
  ...props 
}) => {
  const gapClasses = {
    sm: 'gap-4',
    md: 'gap-6',
    lg: 'gap-8',
    xl: 'gap-12'
  }

  const colClasses = {
    1: 'grid-cols-1',
    2: 'grid-cols-2',
    3: 'grid-cols-3',
    4: 'grid-cols-4',
    5: 'grid-cols-5',
    6: 'grid-cols-6',
    12: 'grid-cols-12'
  }

  const responsiveClasses = responsive ? [
    responsive.sm && `sm:${colClasses[responsive.sm]}`,
    responsive.md && `md:${colClasses[responsive.md]}`,
    responsive.lg && `lg:${colClasses[responsive.lg]}`,
    responsive.xl && `xl:${colClasses[responsive.xl]}`
  ].filter(Boolean) : []

  return (
    <div
      className={cn(
        'grid',
        colClasses[cols],
        gapClasses[gap],
        ...responsiveClasses,
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

// Section component with standardized spacing
interface SectionProps extends React.HTMLAttributes<HTMLElement> {
  spacing?: 'sm' | 'md' | 'lg'
  as?: 'section' | 'div' | 'article' | 'aside'
}

export const Section: React.FC<SectionProps> = ({ 
  className,
  spacing = 'md',
  as: Component = 'section',
  children,
  ...props 
}) => {
  const spacingClasses = {
    sm: 'py-8 lg:py-12',
    md: 'py-12 lg:py-16', 
    lg: 'py-16 lg:py-24'
  }

  return (
    <Component
      className={cn(spacingClasses[spacing], className)}
      {...props}
    >
      {children}
    </Component>
  )
}

// Stack component for vertical layouts
interface StackProps extends React.HTMLAttributes<HTMLDivElement> {
  spacing?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  align?: 'start' | 'center' | 'end' | 'stretch'
}

export const Stack: React.FC<StackProps> = ({ 
  className,
  spacing = 'md',
  align = 'stretch',
  children,
  ...props 
}) => {
  const spacingClasses = {
    xs: 'space-y-2',
    sm: 'space-y-3',
    md: 'space-y-4',
    lg: 'space-y-6',
    xl: 'space-y-8'
  }

  const alignClasses = {
    start: 'items-start',
    center: 'items-center',
    end: 'items-end',
    stretch: 'items-stretch'
  }

  return (
    <div
      className={cn(
        'flex flex-col',
        spacingClasses[spacing],
        alignClasses[align],
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

// Flex component for horizontal layouts
interface FlexProps extends React.HTMLAttributes<HTMLDivElement> {
  align?: 'start' | 'center' | 'end' | 'baseline' | 'stretch'
  justify?: 'start' | 'center' | 'end' | 'between' | 'around' | 'evenly'
  wrap?: boolean
  gap?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
}

export const Flex: React.FC<FlexProps> = ({ 
  className,
  align = 'center',
  justify = 'start',
  wrap = false,
  gap = 'md',
  children,
  ...props 
}) => {
  const alignClasses = {
    start: 'items-start',
    center: 'items-center',
    end: 'items-end',
    baseline: 'items-baseline',
    stretch: 'items-stretch'
  }

  const justifyClasses = {
    start: 'justify-start',
    center: 'justify-center',
    end: 'justify-end',
    between: 'justify-between',
    around: 'justify-around',
    evenly: 'justify-evenly'
  }

  const gapClasses = {
    xs: 'gap-1',
    sm: 'gap-2',
    md: 'gap-4',
    lg: 'gap-6',
    xl: 'gap-8'
  }

  return (
    <div
      className={cn(
        'flex',
        alignClasses[align],
        justifyClasses[justify],
        gapClasses[gap],
        wrap && 'flex-wrap',
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}