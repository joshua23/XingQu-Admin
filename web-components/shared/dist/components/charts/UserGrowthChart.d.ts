import { default as React } from 'react';
import { TimeSeriesData } from '../../types';

interface UserGrowthChartProps {
    data: TimeSeriesData[];
    variant?: 'line' | 'area';
    showGrid?: boolean;
    animate?: boolean;
    height?: number;
}
declare const UserGrowthChart: React.FC<UserGrowthChartProps>;
export default UserGrowthChart;
