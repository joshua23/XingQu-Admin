import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart
} from 'recharts';
import { format } from 'date-fns';
import { TimeSeriesData } from '../../types';

interface UserGrowthChartProps {
  data: TimeSeriesData[];
  variant?: 'line' | 'area';
  showGrid?: boolean;
  animate?: boolean;
  height?: number;
}

const UserGrowthChart: React.FC<UserGrowthChartProps> = ({
  data,
  variant = 'area',
  showGrid = true,
  animate = true,
  height = 300
}) => {
  // 格式化时间轴
  const formatXAxisLabel = (timestamp: string) => {
    return format(new Date(timestamp), 'MM/dd');
  };

  // 格式化Y轴数值
  const formatYAxisLabel = (value: number) => {
    if (value >= 1000000) {
      return `${(value / 1000000).toFixed(1)}M`;
    } else if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}K`;
    }
    return value.toString();
  };

  // 自定义Tooltip
  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-bg-elevated border border-border-primary rounded-lg shadow-modal p-3">
          <p className="text-sm font-medium text-text-primary mb-1">
            {format(new Date(label), 'yyyy年MM月dd日')}
          </p>
          <div className="flex items-center">
            <div 
              className="w-3 h-3 rounded-full mr-2"
              style={{ backgroundColor: '#00B96B' }}
            ></div>
            <span className="text-sm text-text-secondary">用户数：</span>
            <span className="text-sm font-semibold text-text-primary ml-1">
              {payload[0].value.toLocaleString()}
            </span>
          </div>
          {data.label && (
            <p className="text-xs text-text-tertiary mt-1">{data.label}</p>
          )}
        </div>
      );
    }
    return null;
  };

  // 渐变定义
  const gradientId = 'userGrowthGradient';

  const commonProps = {
    data,
    margin: { top: 20, right: 30, left: 20, bottom: 5 }
  };

  return (
    <ResponsiveContainer width="100%" height={height}>
      {variant === 'area' ? (
        <AreaChart {...commonProps}>
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#00B96B" stopOpacity={0.3}/>
              <stop offset="95%" stopColor="#00B96B" stopOpacity={0}/>
            </linearGradient>
          </defs>
          
          {showGrid && (
            <CartesianGrid 
              strokeDasharray="3 3" 
              stroke="#E5E6EB" 
              strokeOpacity={0.5}
            />
          )}
          
          <XAxis
            dataKey="timestamp"
            tickFormatter={formatXAxisLabel}
            axisLine={false}
            tickLine={false}
            tick={{ 
              fill: '#8F959E', 
              fontSize: 12,
              fontFamily: 'Inter'
            }}
            dy={10}
          />
          
          <YAxis
            tickFormatter={formatYAxisLabel}
            axisLine={false}
            tickLine={false}
            tick={{ 
              fill: '#8F959E', 
              fontSize: 12,
              fontFamily: 'Inter'
            }}
            width={60}
          />
          
          <Tooltip content={<CustomTooltip />} />
          
          <Area
            type="monotone"
            dataKey="value"
            stroke="#00B96B"
            strokeWidth={3}
            fill={`url(#${gradientId})`}
            dot={false}
            activeDot={{ 
              r: 6, 
              fill: '#00B96B',
              strokeWidth: 2,
              stroke: '#ffffff'
            }}
            animationDuration={animate ? 1000 : 0}
            animationEasing="ease-out"
          />
        </AreaChart>
      ) : (
        <LineChart {...commonProps}>
          {showGrid && (
            <CartesianGrid 
              strokeDasharray="3 3" 
              stroke="#E5E6EB" 
              strokeOpacity={0.5}
            />
          )}
          
          <XAxis
            dataKey="timestamp"
            tickFormatter={formatXAxisLabel}
            axisLine={false}
            tickLine={false}
            tick={{ 
              fill: '#8F959E', 
              fontSize: 12,
              fontFamily: 'Inter'
            }}
          />
          
          <YAxis
            tickFormatter={formatYAxisLabel}
            axisLine={false}
            tickLine={false}
            tick={{ 
              fill: '#8F959E', 
              fontSize: 12,
              fontFamily: 'Inter'
            }}
            width={60}
          />
          
          <Tooltip content={<CustomTooltip />} />
          
          <Line
            type="monotone"
            dataKey="value"
            stroke="#00B96B"
            strokeWidth={3}
            dot={false}
            activeDot={{ 
              r: 6, 
              fill: '#00B96B',
              strokeWidth: 2,
              stroke: '#ffffff'
            }}
            animationDuration={animate ? 1000 : 0}
            animationEasing="ease-out"
          />
        </LineChart>
      )}
    </ResponsiveContainer>
  );
};

export default UserGrowthChart;