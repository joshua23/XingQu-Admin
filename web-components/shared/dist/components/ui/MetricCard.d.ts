import { default as React } from 'react';

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
declare const MetricCard: React.FC<MetricCardProps>;
export default MetricCard;
