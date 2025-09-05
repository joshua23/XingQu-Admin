'use client'

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
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
    <div className="h-40"> {/* 增加总高度以容纳标签 */}
      {/* 图表区域 */}
      <div className="flex items-end justify-between space-x-1 h-32 px-2 mb-2">
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
                  <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity z-10">
                    <div className="bg-popover text-popover-foreground px-2 py-1 rounded text-xs font-medium shadow-md border whitespace-nowrap">
                      {point.value.toLocaleString()}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      
      {/* X轴标签区域 - 与柱状图对齐 */}
      <div className="flex justify-between px-2">
        {data.map((point, index) => (
          <div key={index} className="flex-1 flex flex-col items-center">
            <span className="text-xs text-muted-foreground font-medium text-center leading-tight">
              {point.label}
            </span>
            {showTrend && point.trend && (
              <div className={cn(
                "flex items-center justify-center mt-1",
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
        ))}
      </div>
    </div>
  );

  const LineChart = () => {
    // 计算点位置，留出边距以避免标签重叠
    const points = data.map((point, index) => {
      const x = 5 + (index / Math.max(data.length - 1, 1)) * 90; // 左右各留5%空间
      const y = 75 - ((point.value - minValue) / range) * 55; // 顶部10%，底部15%空间
      return `${x},${y}`;
    }).join(' ');

    const areaPoints = `5,90 ${points} 95,90`;

    return (
      <div className="h-40 relative"> {/* 增加总高度 */}
        {/* 图表区域 */}
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
              const x = 5 + (index / Math.max(data.length - 1, 1)) * 90;
              const y = 75 - ((point.value - minValue) / range) * 55;
              return (
                <g key={index}>
                  <circle
                    cx={x}
                    cy={y}
                    r="3"
                    className={cn(colorClasses.line, "fill-current drop-shadow-sm")}
                  />
                  {/* 悬浮显示数值 */}
                  <g className="opacity-0 hover:opacity-100 transition-opacity">
                    <rect
                      x={x - 15}
                      y={y - 20}
                      width="30"
                      height="16"
                      rx="2"
                      className="fill-popover stroke-border stroke-[0.5]"
                    />
                    <text
                      x={x}
                      y={y - 10}
                      textAnchor="middle"
                      className="text-[4px] fill-popover-foreground font-medium"
                    >
                      {point.value.toLocaleString()}
                    </text>
                  </g>
                </g>
              );
            })}
          </svg>
        </div>
        
        {/* X轴标签区域 - 完美对齐 */}
        <div className="flex justify-between items-center px-2 pt-2">
          {data.map((point, index) => (
            <div key={index} className="flex-1 flex flex-col items-center">
              <span className="text-xs text-muted-foreground font-medium text-center leading-tight">
                {point.label}
              </span>
              {showTrend && point.trend && (
                <div className={cn(
                  "flex items-center justify-center mt-1",
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