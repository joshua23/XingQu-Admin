import React, { useState } from 'react';
import { MoreHorizontal, Download, Maximize2, RefreshCw } from 'lucide-react';

interface ChartContainerProps {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  loading?: boolean;
  error?: string;
  className?: string;
  onRefresh?: () => void;
  onExport?: () => void;
  onFullscreen?: () => void;
  actions?: React.ReactNode;
  height?: number | string;
}

const ChartContainer: React.FC<ChartContainerProps> = ({
  title,
  subtitle,
  children,
  loading = false,
  error,
  className,
  onRefresh,
  onExport,
  onFullscreen,
  actions,
  height = 300
}) => {
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = async () => {
    if (!onRefresh || isRefreshing) return;
    
    setIsRefreshing(true);
    try {
      await onRefresh();
    } finally {
      setIsRefreshing(false);
    }
  };

  // 组合类名的辅助函数
  const combineClassNames = (...classes: (string | undefined)[]) => {
    return classes.filter(Boolean).join(' ');
  };

  return (
    <div className={combineClassNames(
      "bg-bg-elevated border border-border-primary rounded-lg shadow-card",
      "overflow-hidden",
      className
    )}>
      {/* 图表头部 */}
      <div className="px-6 py-4 border-b border-border-secondary">
        <div className="flex items-center justify-between">
          <div className="flex-1 min-w-0">
            <h3 className="text-lg font-semibold text-text-primary truncate">
              {title}
            </h3>
            {subtitle && (
              <p className="text-sm text-text-tertiary mt-1">
                {subtitle}
              </p>
            )}
          </div>
          
          <div className="flex items-center space-x-2 ml-4">
            {/* 自定义操作 */}
            {actions}
            
            {/* 刷新按钮 */}
            {onRefresh && (
              <button
                onClick={handleRefresh}
                disabled={isRefreshing}
                className={combineClassNames(
                  "p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md",
                  "transition-colors duration-200",
                  isRefreshing ? "animate-spin" : ""
                )}
                title="刷新数据"
              >
                <RefreshCw className="w-4 h-4" />
              </button>
            )}
            
            {/* 导出按钮 */}
            {onExport && (
              <button
                onClick={onExport}
                className="p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md transition-colors duration-200"
                title="导出数据"
              >
                <Download className="w-4 h-4" />
              </button>
            )}
            
            {/* 全屏按钮 */}
            {onFullscreen && (
              <button
                onClick={onFullscreen}
                className="p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md transition-colors duration-200"
                title="全屏查看"
              >
                <Maximize2 className="w-4 h-4" />
              </button>
            )}
            
            {/* 更多操作 */}
            <button className="p-2 text-text-tertiary hover:text-text-primary hover:bg-bg-hover rounded-md transition-colors duration-200">
              <MoreHorizontal className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* 图表内容区 */}
      <div 
        className="relative"
        style={{ height: typeof height === 'number' ? `${height}px` : height }}
      >
        {loading ? (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="flex flex-col items-center space-y-3">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-accent-primary border-t-transparent"></div>
              <p className="text-sm text-text-tertiary">加载中...</p>
            </div>
          </div>
        ) : error ? (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center">
              <div className="w-12 h-12 mx-auto mb-4 text-status-error">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                </svg>
              </div>
              <p className="text-sm text-status-error font-medium mb-2">数据加载失败</p>
              <p className="text-xs text-text-tertiary mb-4">{error}</p>
              {onRefresh && (
                <button
                  onClick={handleRefresh}
                  className="text-sm text-accent-primary hover:text-accent-hover font-medium"
                >
                  重新加载
                </button>
              )}
            </div>
          </div>
        ) : (
          <div className="h-full w-full p-6">
            {children}
          </div>
        )}
        
        {/* 加载覆盖层 */}
        {isRefreshing && !loading && (
          <div className="absolute inset-0 bg-bg-primary bg-opacity-50 flex items-center justify-center">
            <div className="animate-spin rounded-full h-6 w-6 border-2 border-accent-primary border-t-transparent"></div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ChartContainer;