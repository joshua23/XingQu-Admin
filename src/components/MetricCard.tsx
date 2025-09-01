import React from 'react'
import { Badge } from './ui/Badge'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { cn } from '@/lib/utils'

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  description?: string;
  variant?: 'default' | 'success' | 'warning' | 'destructive';
}

export function MetricCard({
  title,
  value,
  change,
  changeLabel,
  description,
  variant = 'default'
}: MetricCardProps) {
  const getTrendIcon = () => {
    if (change === undefined || change === 0) return <Minus className="w-3 h-3" />;
    return change > 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />;
  };

  const getTrendColor = () => {
    if (change === undefined || change === 0) return 'metric-neutral';
    return change > 0 ? 'metric-positive' : 'metric-negative';
  };

  const formatChange = () => {
    if (change === undefined) return null;
    const sign = change > 0 ? '+' : '';
    return `${sign}${change}%`;
  };

  return (
    <div className="bg-card text-card-foreground border border-border rounded-lg shadow-sm transition-all duration-200 hover:shadow-md">
      <div className="p-6">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-medium text-muted-foreground">
            {title}
          </h3>
          {change !== undefined && (
            <Badge
              variant="secondary"
              className={cn(
                "flex items-center gap-1 text-xs",
                `text-${getTrendColor()}`
              )}
            >
              {getTrendIcon()}
              {formatChange()}
            </Badge>
          )}
        </div>

        <div className="space-y-2">
          <div className="text-2xl font-bold text-foreground">
            {typeof value === 'number' ? value.toLocaleString() : value}
          </div>
          {description && (
            <p className="text-xs text-muted-foreground">{description}</p>
          )}
          {changeLabel && (
            <p className="text-xs text-muted-foreground">{changeLabel}</p>
          )}
        </div>
      </div>
    </div>
  );
}
