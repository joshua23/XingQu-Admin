import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';

/// 指标卡片组件
/// 用于展示关键数据指标
class MetricCard extends StatelessWidget {
  final MetricCardData data;

  const MetricCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 标题和图标
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (data.icon != null)
                  Icon(
                    _getIconData(data.icon!),
                    size: 20,
                    color: const Color(0xFFFFD700),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 主要数值
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 变化趋势和描述
            Row(
              children: [
                if (data.changePercentage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: data.isPositiveChange
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.isPositiveChange
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 12,
                          color: data.isPositiveChange
                              ? Colors.green[600]
                              : Colors.red[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${data.changePercentage!.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: data.isPositiveChange
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (data.changeLabel != null)
                  Expanded(
                    child: Text(
                      data.changeLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'users':
        return Icons.people_outline;
      case 'sessions':
        return Icons.access_time_outlined;
      case 'events':
        return Icons.analytics_outlined;
      case 'active':
        return Icons.monitor_heart_outlined;
      case 'revenue':
        return Icons.attach_money_outlined;
      case 'growth':
        return Icons.trending_up_outlined;
      default:
        return Icons.bar_chart_outlined;
    }
  }
}