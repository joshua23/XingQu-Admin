import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../models/analytics_models.dart';
import 'metric_card.dart';

/// 数据总览模块
/// 展示系统关键指标和实时数据监控
class OverviewModule extends StatelessWidget {
  const OverviewModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '数据加载失败',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => provider.refreshModule('overview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('重新加载'),
                ),
              ],
            ),
          );
        }

        final overview = provider.overviewData;
        final realTime = provider.realTimeMetrics;
        final realBasicStats = provider.realBasicStats;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              _buildHeader(context, provider),
              
              const SizedBox(height: 24),
              
              // 真实数据指标卡片
              if (realBasicStats != null) 
                _buildRealMetricCards(realBasicStats)
              else if (overview != null) 
                _buildMetricCards(overview, realTime),
              
              const SizedBox(height: 32),
              
              // 详细数据区域
              _buildDetailedDataSection(provider),
              
              const SizedBox(height: 32),
              
              // 实时活动和系统状态
              _buildRealTimeSection(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AnalyticsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据总览',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '系统关键指标和实时数据监控',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // 刷新按钮
            IconButton(
              onPressed: () => provider.refreshModule('overview'),
              icon: const Icon(Icons.refresh),
              tooltip: '刷新数据',
            ),
            const SizedBox(width: 8),
            // 最后更新时间
            if (provider.overviewData != null)
              Text(
                '最后更新: ${_formatTime(provider.overviewData!.lastUpdated)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealMetricCards(Map<String, dynamic> realBasicStats) {
    final metrics = [
      MetricCardData(
        title: '总用户数',
        value: '${realBasicStats['totalUsers'] ?? 0}',
        changePercentage: null,
        changeLabel: '基于 xq_user_profiles',
        isPositiveChange: true,
        icon: 'users',
      ),
      MetricCardData(
        title: '总会话数',
        value: '${realBasicStats['totalSessions'] ?? 0}',
        changePercentage: null,
        changeLabel: '基于 xq_user_sessions',
        isPositiveChange: true,
        icon: 'sessions',
      ),
      MetricCardData(
        title: '总事件数',
        value: '${realBasicStats['totalEvents'] ?? 0}',
        changePercentage: null,
        changeLabel: '基于 xq_tracking_events',
        isPositiveChange: true,
        icon: 'events',
      ),
      MetricCardData(
        title: '最后更新',
        value: _formatUpdateTime(realBasicStats['lastUpdated']),
        changePercentage: null,
        changeLabel: '数据同步时间',
        isPositiveChange: true,
        icon: 'active',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => MetricCard(data: metrics[index]),
    );
  }

  Widget _buildMetricCards(OverviewData overview, RealTimeMetrics? realTime) {
    final metrics = [
      MetricCardData(
        title: '总用户数',
        value: overview.totalUsers.toString(),
        changePercentage: null,
        changeLabel: '累计注册用户',
        isPositiveChange: true,
        icon: 'users',
      ),
      MetricCardData(
        title: '活跃会话',
        value: overview.totalSessions.toString(),
        changePercentage: null,
        changeLabel: '总会话数',
        isPositiveChange: true,
        icon: 'sessions',
      ),
      MetricCardData(
        title: '事件追踪',
        value: overview.totalEvents.toString(),
        changePercentage: null,
        changeLabel: '总事件数',
        isPositiveChange: true,
        icon: 'events',
      ),
      MetricCardData(
        title: '今日活跃',
        value: overview.activeUsersToday.toString(),
        changePercentage: null,
        changeLabel: '今日活跃用户',
        isPositiveChange: true,
        icon: 'active',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => MetricCard(data: metrics[index]),
    );
  }

  Widget _buildDetailedDataSection(AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '详细统计',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // 用户统计卡片 - 使用真实数据
            Expanded(
              child: _buildStatsCard(
                title: '用户统计',
                icon: Icons.people,
                stats: _buildUserStats(provider),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 行为统计卡片 - 使用真实数据
            Expanded(
              child: _buildStatsCard(
                title: '行为统计',
                icon: Icons.analytics,
                stats: _buildEventStats(provider),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 会话统计卡片 - 使用真实数据
            Expanded(
              child: _buildStatsCard(
                title: '会话统计',
                icon: Icons.access_time,
                stats: _buildSessionStats(provider),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_StatItem> _buildUserStats(AnalyticsProvider provider) {
    final realUsersData = provider.realUsersData;
    if (realUsersData != null) {
      final genderDist = realUsersData['genderDistribution'] as Map<String, dynamic>? ?? {};
      final memberDist = realUsersData['membershipDistribution'] as Map<String, dynamic>? ?? {};
      
      return [
        _StatItem(
          label: '总用户数',
          value: '${realUsersData['totalUsers'] ?? 0}',
        ),
        _StatItem(
          label: '会员用户',
          value: '${memberDist['members'] ?? 0}',
        ),
        _StatItem(
          label: '普通用户',
          value: '${memberDist['regular'] ?? 0}',
        ),
      ];
    }
    
    // 备用方案：使用原有数据
    if (provider.userAnalytics != null) {
      return [
        _StatItem(
          label: '总用户数',
          value: provider.userAnalytics!.totalUsers.toString(),
        ),
        _StatItem(
          label: '活跃用户',
          value: provider.userAnalytics!.activeUsers.toString(),
        ),
        _StatItem(
          label: '会员用户',
          value: provider.userAnalytics!.memberUsers.toString(),
        ),
      ];
    }
    
    return [];
  }

  List<_StatItem> _buildEventStats(AnalyticsProvider provider) {
    final realEventsData = provider.realEventsData;
    if (realEventsData != null) {
      final eventTypeStats = realEventsData['eventTypeStats'] as Map<String, dynamic>? ?? {};
      final platformStats = realEventsData['platformStats'] as Map<String, dynamic>? ?? {};
      
      return [
        _StatItem(
          label: '总事件数',
          value: '${realEventsData['totalEvents'] ?? 0}',
        ),
        _StatItem(
          label: '事件类型',
          value: '${eventTypeStats.length}',
        ),
        _StatItem(
          label: '平台数量',
          value: '${platformStats.length}',
        ),
      ];
    }
    
    // 备用方案：使用原有数据
    if (provider.behaviorAnalytics != null) {
      return [
        _StatItem(
          label: '总事件数',
          value: provider.behaviorAnalytics!.totalEvents.toString(),
        ),
        _StatItem(
          label: '事件类型',
          value: provider.behaviorAnalytics!.eventTypeStats.length.toString(),
        ),
        _StatItem(
          label: '平台数',
          value: provider.behaviorAnalytics!.platformStats.length.toString(),
        ),
      ];
    }
    
    return [];
  }

  List<_StatItem> _buildSessionStats(AnalyticsProvider provider) {
    final realSessionsData = provider.realSessionsData;
    if (realSessionsData != null) {
      final avgDuration = realSessionsData['averageDuration'] as double? ?? 0.0;
      
      return [
        _StatItem(
          label: '总会话数',
          value: '${realSessionsData['totalSessions'] ?? 0}',
        ),
        _StatItem(
          label: '活跃会话',
          value: '${realSessionsData['activeSessions'] ?? 0}',
        ),
        _StatItem(
          label: '平均时长',
          value: '${avgDuration.toInt()}秒',
        ),
      ];
    }
    
    // 备用方案：使用原有数据
    if (provider.sessionAnalytics != null) {
      return [
        _StatItem(
          label: '总会话数',
          value: provider.sessionAnalytics!.totalSessions.toString(),
        ),
        _StatItem(
          label: '活跃会话',
          value: provider.sessionAnalytics!.activeSessions.toString(),
        ),
        _StatItem(
          label: '平均时长',
          value: '${provider.sessionAnalytics!.averageDuration.toInt()}秒',
        ),
      ];
    }
    
    return [];
  }

  Widget _buildStatsCard({
    required String title,
    required IconData icon,
    required List<_StatItem> stats,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.map((stat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeSection(AnalyticsProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 实时指标
        Expanded(
          flex: 1,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monitor_heart, size: 20, color: Color(0xFFFFD700)),
                      SizedBox(width: 8),
                      Text(
                        '实时指标',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (provider.realTimeMetrics != null) ...[
                    _buildRealTimeMetric(
                      '当前活跃用户',
                      provider.realTimeMetrics!.currentActiveUsers.toString(),
                      Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildRealTimeMetric(
                      '每小时事件数',
                      provider.realTimeMetrics!.eventsPerHour.toString(),
                      Icons.timeline,
                    ),
                    const SizedBox(height: 12),
                    _buildRealTimeMetric(
                      '系统状态',
                      _getStatusLabel(provider.realTimeMetrics!.systemStatus),
                      Icons.health_and_safety,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 快速操作
        Expanded(
          flex: 1,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flash_on, size: 20, color: Color(0xFFFFD700)),
                      SizedBox(width: 8),
                      Text(
                        '快速操作',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildQuickAction(
                    '导出数据报告',
                    Icons.file_download,
                    () {
                      // TODO: 实现导出功能
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildQuickAction(
                    '数据备份',
                    Icons.backup,
                    () {
                      // TODO: 实现备份功能
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildQuickAction(
                    '清理缓存',
                    Icons.cleaning_services,
                    () {
                      // TODO: 实现清理功能
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFFD700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatUpdateTime(dynamic timestamp) {
    if (timestamp == null) return '未知';
    try {
      final time = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inMinutes < 1) {
        return '刚刚';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}分钟前';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}小时前';
      } else {
        return '${diff.inDays}天前';
      }
    } catch (e) {
      return '解析错误';
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return '正常';
      case 'warning':
        return '警告';
      case 'error':
        return '错误';
      default:
        return '未知';
    }
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem({required this.label, required this.value});
}