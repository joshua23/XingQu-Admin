'use client'

interface SkeletonLoaderProps {
  className?: string
  variant?: 'card' | 'text' | 'circle' | 'chart' | 'metric'
}

export function SkeletonLoader({ className = '', variant = 'text' }: SkeletonLoaderProps) {
  const getVariantClass = () => {
    switch (variant) {
      case 'card':
        return 'h-32 rounded-lg'
      case 'circle':
        return 'h-12 w-12 rounded-full'
      case 'chart':
        return 'h-64 rounded-lg'
      case 'metric':
        return 'h-20 rounded-lg'
      default:
        return 'h-4 rounded'
    }
  }

  return (
    <div
      className={`animate-pulse bg-muted ${getVariantClass()} ${className}`}
      aria-label="Loading..."
    />
  )
}

export function MetricCardSkeleton() {
  return (
    <div className="bg-card border border-border rounded-lg p-6 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <SkeletonLoader variant="circle" className="h-10 w-10" />
          <div className="space-y-2">
            <SkeletonLoader className="h-4 w-20" />
            <SkeletonLoader className="h-3 w-16" />
          </div>
        </div>
      </div>
      <div className="space-y-3">
        <SkeletonLoader className="h-8 w-24" />
        <div className="flex items-center space-x-2">
          <SkeletonLoader className="h-3 w-12" />
          <SkeletonLoader className="h-3 w-16" />
        </div>
      </div>
    </div>
  )
}

export function ChartSkeleton() {
  return (
    <div className="bg-card border border-border rounded-lg p-6 shadow-sm">
      <div className="flex items-center justify-between mb-6">
        <div className="space-y-2">
          <SkeletonLoader className="h-5 w-32" />
          <SkeletonLoader className="h-3 w-48" />
        </div>
      </div>
      <SkeletonLoader variant="chart" />
    </div>
  )
}

export function QuickStatsSkeleton() {
  return (
    <div className="bg-card border border-border rounded-lg p-6 shadow-sm">
      <div className="flex items-center space-x-3 mb-6">
        <SkeletonLoader variant="circle" className="h-10 w-10" />
        <SkeletonLoader className="h-5 w-24" />
      </div>
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="flex justify-between items-center p-3 bg-muted/30 rounded-lg">
            <SkeletonLoader className="h-4 w-20" />
            <div className="flex items-center space-x-3">
              <SkeletonLoader className="h-4 w-16" />
              <SkeletonLoader className="h-6 w-12 rounded-full" />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}