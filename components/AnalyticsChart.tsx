'use client'

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/Card';
import { Badge } from './ui/Badge';
import { cn } from '../lib/utils';
import { TrendingUp, TrendingDown, BarChart3, Users, Activity, Eye, DollarSign } from 'lucide-react';

interface ChartDataPoint {
  label: string;
  value: number;
  trend?: 'up' | 'down' | 'neutral';
}

interface AnalyticsChartProps {
  title: string;
  description?: string;
  data: ChartDataPoint[];
  type?: 'bar' | 'line' | 'area';
  color?: 'primary' | 'success' | 'warning' | 'danger';
  showTrend?: boolean;
}

export const AnalyticsChart: React.FC<AnalyticsChartProps> = ({
  title,
  description,
  data,
  type = 'bar',
  color = 'primary',
  showTrend = true
}) => {
  const [selectedPeriod, setSelectedPeriod] = useState('7d');
  
  const maxValue = Math.max(...data.map(d => d.value));
  const minValue = Math.min(...data.map(d => d.value));
  const range = maxValue - minValue || 1;

  const getColorClasses = () => {
    switch (color) {
      case 'success':
        return {
          bar: 'bg-success/20 border-success/40',
          line: 'stroke-success',
          fill: 'fill-success/10',
          text: 'text-success'
        };
      case 'warning':
        return {
          bar: 'bg-warning/20 border-warning/40',
          line: 'stroke-warning',
          fill: 'fill-warning/10',
          text: 'text-warning'
        };
      case 'danger':
        return {
          bar: 'bg-destructive/20 border-destructive/40',
          line: 'stroke-destructive',
          fill: 'fill-destructive/10',
          text: 'text-destructive'
        };
      default:
        return {
          bar: 'bg-primary/20 border-primary/40',
          line: 'stroke-primary',
          fill: 'fill-primary/10',
          text: 'text-primary'
        };
    }
  };

  const colorClasses = getColorClasses();

  const BarChart = () => (
    <div className="flex items-end justify-between space-x-1 h-32 px-2">
      {data.map((point, index) => {
        const height = ((point.value - minValue) / range) * 100;
        return (
          <div key={index} className="flex flex-col items-center flex-1 group">
            <div className="relative w-full bg-muted/30 rounded-t-md overflow-hidden">
              <div 
                className={cn(
                  "rounded-t-md border-t-2 transition-all duration-500 ease-out group-hover:opacity-80 relative",
                  colorClasses.bar
                )}
                style={{ 
                  height: `${Math.max(height, 5)}%`,
                  minHeight: '4px'
                }}
              >
                {/* Value label on hover */}
                <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <div className="bg-popover text-popover-foreground px-2 py-1 rounded text-xs font-medium shadow-md border">
                    {point.value}
                  </div>
                </div>
              </div>
            </div>
            <div className="flex flex-col items-center mt-2 w-full">
              <span className="text-xs text-muted-foreground font-medium text-center w-full">
                {point.label}
              </span>
              {showTrend && point.trend && (
                <div className={cn(
                  "flex items-center mt-1",
                  point.trend === 'up' ? 'text-success' :
                  point.trend === 'down' ? 'text-destructive' :
                  'text-muted-foreground'
                )}>
                  {point.trend === 'up' ? <TrendingUp size={10} /> :
                   point.trend === 'down' ? <TrendingDown size={10} /> :
                   null}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );

  const LineChart = () => {
    const points = data.map((point, index) => {
      const x = (index / (data.length - 1)) * 100;
      const y = 85 - ((point.value - minValue) / range) * 65; // 顶部15%，底部20%空间
      return `${x},${y}`;
    }).join(' ');

    const areaPoints = `0,100 ${points} 100,100`;

    return (
      <div className="h-32 relative">
        <svg viewBox="0 0 100 100" className="w-full h-full">
          {type === 'area' && (
            <polygon
              points={areaPoints}
              className={colorClasses.fill}
            />
          )}
          <polyline
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            points={points}
            className={cn(colorClasses.line, "drop-shadow-sm")}
          />
          {data.map((point, index) => {
            const x = (index / (data.length - 1)) * 100;
            const y = 85 - ((point.value - minValue) / range) * 65;
            return (
              <circle
                key={index}
                cx={x}
                cy={y}
                r="2"
                className={cn(colorClasses.line, "fill-current")}
              />
            );
          })}
        </svg>
        
        {/* Labels */}
        <div className="absolute bottom-0 left-0 right-0 flex justify-between px-1">
          {data.map((point, index) => (
            <span key={index} className="text-xs text-muted-foreground font-medium">
              {point.label}
            </span>
          ))}
        </div>
      </div>
    );
  };

  const totalValue = data.reduce((sum, point) => sum + point.value, 0);
  const averageValue = Math.round(totalValue / data.length);
  const lastValue = data[data.length - 1]?.value || 0;
  const previousValue = data[data.length - 2]?.value || lastValue;
  const changePercent = previousValue !== 0 ? ((lastValue - previousValue) / previousValue * 100).toFixed(1) : '0';

  return (
    <Card className="transition-all duration-200 hover:shadow-md">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-lg font-bold">{title}</CardTitle>
            {description && (
              <CardDescription className="mt-1">{description}</CardDescription>
            )}
          </div>
          <div className="flex items-center space-x-2">
            <select
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="px-2 py-1 text-xs border border-input rounded bg-background"
            >
              <option value="24h">24小时</option>
              <option value="7d">7天</option>
              <option value="30d">30天</option>
            </select>
          </div>
        </div>
        
        {/* Summary stats */}
        <div className="flex items-center space-x-4 mt-3">
          <div className="flex items-center space-x-1">
            <span className="text-sm text-muted-foreground">总计:</span>
            <span className="font-semibold text-foreground">{totalValue.toLocaleString()}</span>
          </div>
          <div className="flex items-center space-x-1">
            <span className="text-sm text-muted-foreground">平均:</span>
            <span className="font-semibold text-foreground">{averageValue.toLocaleString()}</span>
          </div>
          {showTrend && (
            <Badge
              variant="outline"
              className={cn(
                "text-xs font-medium",
                Number(changePercent) > 0 
                  ? "border-success/50 text-success bg-success/10"
                  : Number(changePercent) < 0
                    ? "border-destructive/50 text-destructive bg-destructive/10"
                    : "border-muted-foreground/50 text-muted-foreground bg-muted/10"
              )}
            >
              {Number(changePercent) > 0 ? '+' : ''}{changePercent}%
            </Badge>
          )}
        </div>
      </CardHeader>
      <CardContent>
        {type === 'bar' ? <BarChart /> : <LineChart />}
      </CardContent>
    </Card>
  );
};

// 预设的分析图表组件
export const UserGrowthChart = ({ data }: { data: ChartDataPoint[] }) => (
  <AnalyticsChart
    title="用户增长趋势"
    description="新注册用户数量变化"
    data={data}
    type="area"
    color="primary"
  />
);

export const ActivityChart = ({ data }: { data: ChartDataPoint[] }) => (
  <AnalyticsChart
    title="用户活跃度"
    description="每日活跃用户统计"
    data={data}
    type="bar"
    color="success"
  />
);

export const RevenueChart = ({ data }: { data: ChartDataPoint[] }) => (
  <AnalyticsChart
    title="收入统计"
    description="每日收入变化趋势"
    data={data}
    type="line"
    color="warning"
  />
);