import { TrendingUp, TrendingDown, Minus, Activity, Target, BarChart3 } from 'lucide-react'
import { cn } from '@/lib/utils'

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  description?: string;
  sparklineData?: number[];
  target?: number;
  icon?: React.ReactNode;
  color?: 'default' | 'primary' | 'success' | 'warning' | 'danger';
}

export function MetricCard({
  title,
  value,
  change,
  changeLabel,
  description,
  sparklineData,
  target,
  icon,
  color = 'default',
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

  const getColorClasses = () => {
    switch (color) {
      case 'primary':
        return {
          card: 'from-primary/5 to-primary/10 border-primary/20',
          icon: 'text-primary bg-primary/10',
          accent: 'bg-primary/5'
        };
      case 'success':
        return {
          card: 'from-success/5 to-success/10 border-success/20',
          icon: 'text-success bg-success/10',
          accent: 'bg-success/5'
        };
      case 'warning':
        return {
          card: 'from-warning/5 to-warning/10 border-warning/20',
          icon: 'text-warning bg-warning/10',
          accent: 'bg-warning/5'
        };
      case 'danger':
        return {
          card: 'from-destructive/5 to-destructive/10 border-destructive/20',
          icon: 'text-destructive bg-destructive/10',
          accent: 'bg-destructive/5'
        };
      default:
        return {
          card: 'from-card to-card/95 border-border/50',
          icon: 'text-muted-foreground bg-muted/50',
          accent: 'bg-muted/20'
        };
    }
  };

  const colorClasses = getColorClasses();

  // Simple sparkline component
  const Sparkline = ({ data }: { data: number[] }) => {
    if (!data || data.length === 0) return null;
    
    const max = Math.max(...data);
    const min = Math.min(...data);
    const range = max - min || 1;
    
    const points = data.map((value, index) => {
      const x = (index / (data.length - 1)) * 100;
      const y = 100 - ((value - min) / range) * 100;
      return `${x},${y}`;
    }).join(' ');

    return (
      <div className="flex items-end h-8 w-20">
        <svg viewBox="0 0 100 100" className="w-full h-full">
          <polyline
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            points={points}
            className="opacity-60"
          />
        </svg>
      </div>
    );
  };

  // Progress bar for target comparison
  const ProgressBar = () => {
    if (!target || typeof value !== 'number') return null;
    
    const percentage = Math.min((value / target) * 100, 100);
    
    return (
      <div className="mt-3">
        <div className="flex items-center justify-between text-xs text-muted-foreground mb-1">
          <span>目标进度</span>
          <span>{Math.round(percentage)}%</span>
        </div>
        <div className="w-full bg-muted rounded-full h-1.5">
          <div 
            className={cn(
              "h-1.5 rounded-full transition-all duration-1000 ease-out",
              color === 'success' ? 'bg-success' :
              color === 'primary' ? 'bg-primary' :
              color === 'warning' ? 'bg-warning' :
              color === 'danger' ? 'bg-destructive' :
              'bg-muted-foreground'
            )}
            style={{ width: `${percentage}%` }}
          />
        </div>
      </div>
    );
  };

  return (
    <div className={cn(
      "card-interactive bg-gradient-to-br border transition-all duration-200 hover:scale-[1.02] hover:shadow-lg",
      colorClasses.card
    )}>
      <div className="p-6">
        {/* Header with icon and trend indicator */}
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center space-x-3">
            {icon && (
              <div className={cn("p-2 rounded-lg", colorClasses.icon)}>
                {icon}
              </div>
            )}
            <div>
              <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
                {title}
              </h3>
              <div className="text-3xl font-black text-foreground mt-1 tracking-tight">
                {typeof value === 'number' ? value.toLocaleString() : value}
              </div>
            </div>
          </div>
          
          <div className="flex flex-col items-end space-y-2">
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
            {sparklineData && (
              <div className="text-muted-foreground">
                <Sparkline data={sparklineData} />
              </div>
            )}
          </div>
        </div>

        {/* Description and labels */}
        <div className="space-y-2">
          {description && (
            <p className="text-sm text-muted-foreground font-medium">{description}</p>
          )}
          {changeLabel && (
            <p className="text-xs text-muted-foreground">{changeLabel}</p>
          )}
          <ProgressBar />
        </div>
      </div>
    </div>
  );
}
