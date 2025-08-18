import React from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: string;
  trend?: 'up' | 'down' | 'neutral';
  suffix?: string;
  prefix?: string;
  icon?: React.ReactNode;
  loading?: boolean;
  className?: string;
  onClick?: () => void;
}

const MetricCard: React.FC<MetricCardProps> = ({
  title,
  value,
  change,
  trend = 'neutral',
  suffix = '',
  prefix = '',
  icon,
  loading = false,
  className,
  onClick
}) => {
  // 趋势颜色映射
  const trendColorMap = {
    up: 'text-status-success',
    down: 'text-status-error',
    neutral: 'text-text-tertiary'
  };

  // 趋势图标映射
  const TrendIcon = {
    up: TrendingUp,
    down: TrendingDown,
    neutral: Minus
  }[trend];

  // 格式化数值
  const formatValue = (val: string | number): string => {
    if (typeof val === 'number') {
      if (val >= 1000000) {
        return `${(val / 1000000).toFixed(1)}M`;
      } else if (val >= 1000) {
        return `${(val / 1000).toFixed(1)}K`;
      }
      return val.toLocaleString();
    }
    return val.toString();
  };

  // 组合类名的辅助函数
  const combineClassNames = (...classes: (string | undefined)[]) => {
    return classes.filter(Boolean).join(' ');
  };

  if (loading) {
    return (
      <div className={combineClassNames(
        "bg-bg-elevated border border-border-primary rounded-lg p-6 shadow-card",
        "animate-pulse",
        className
      )}>
        <div className="flex items-center justify-between mb-2">
          <div className="h-4 bg-bg-tertiary rounded w-24"></div>
          {icon && <div className="h-5 w-5 bg-bg-tertiary rounded"></div>}
        </div>
        <div className="h-8 bg-bg-tertiary rounded w-16 mb-2"></div>
        <div className="h-4 bg-bg-tertiary rounded w-20"></div>
      </div>
    );
  }

  return (
    <div 
      className={combineClassNames(
        "bg-bg-elevated border border-border-primary rounded-lg p-6 shadow-card",
        "transition-all duration-200",
        "hover:shadow-hover hover:border-border-focus",
        onClick && "cursor-pointer",
        className
      )}
      onClick={onClick}
    >
      {/* 标题和图标 */}
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-sm font-medium text-text-secondary">
          {title}
        </h3>
        {icon && (
          <div className="flex-shrink-0 text-text-tertiary">
            {icon}
          </div>
        )}
      </div>

      {/* 主要数值 */}
      <div className="mb-2">
        <span className="text-3xl font-bold text-text-primary">
          {prefix}{formatValue(value)}{suffix}
        </span>
      </div>

      {/* 变化趋势 */}
      {change && (
        <div className={combineClassNames(
          "flex items-center text-sm",
          trendColorMap[trend]
        )}>
          <TrendIcon className="w-4 h-4 mr-1" />
          <span className="font-medium">{change}</span>
          <span className="ml-1 text-text-tertiary">vs 昨日</span>
        </div>
      )}
    </div>
  );
};

export default MetricCard;