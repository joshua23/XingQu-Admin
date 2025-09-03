import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { cn } from '@/lib/utils'

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  description?: string;
  // variant?: 'default' | 'success' | 'warning' | 'destructive';
}

export function MetricCard({
  title,
  value,
  change,
  changeLabel,
  description,
  // _variant = 'default'
}: MetricCardProps) {
  const getTrendIcon = () => {
    if (change === undefined || change === 0) return <Minus className="w-3 h-3" />;
    return change > 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />;
  };


  const formatChange = () => {
    if (change === undefined) return null;
    const sign = change > 0 ? '+' : '';
    return `${sign}${change}%`;
  };

  return (
    <div className="card-interactive bg-gradient-to-br from-card to-card/95">
      <div className="p-6">
        <div className="flex items-start justify-between mb-4">
          <div className="flex flex-col">
            <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
              {title}
            </h3>
            <div className="text-3xl font-black text-foreground mt-2 tracking-tight">
              {typeof value === 'number' ? value.toLocaleString() : value}
            </div>
          </div>
          {change !== undefined && (
            <div className={cn(
              "flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold border-2",
              change > 0 
                ? "bg-success/10 border-success/30 text-success"
                : change < 0 
                  ? "bg-destructive/10 border-destructive/30 text-destructive"
                  : "bg-muted border-border text-muted-foreground"
            )}>
              {getTrendIcon()}
              {formatChange()}
            </div>
          )}
        </div>

        <div className="space-y-1">
          {description && (
            <p className="text-sm text-muted-foreground font-medium">{description}</p>
          )}
          {changeLabel && (
            <p className="text-xs text-muted-foreground">{changeLabel}</p>
          )}
        </div>
      </div>
    </div>
  );
}
