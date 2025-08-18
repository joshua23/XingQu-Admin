import { default as React } from 'react';

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
declare const ChartContainer: React.FC<ChartContainerProps>;
export default ChartContainer;
