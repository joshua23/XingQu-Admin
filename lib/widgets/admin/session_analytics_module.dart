import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

/// 会话分析模块
/// 基于xq_user_sessions表的会话数据分析
class SessionAnalyticsModule extends StatelessWidget {
  const SessionAnalyticsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.error != null)
                _buildErrorWidget(provider)
              else
                _buildContent(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '会话分析',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '基于用户会话数据的详细分析统计',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(AnalyticsProvider provider) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: ${provider.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refreshModule('session-analytics'),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsProvider provider) {
    final sessionData = provider.sessionAnalytics;
    final sessions = provider.userSessions;
    
    if (sessionData == null) {
      return const Center(child: Text('暂无会话数据'));
    }

    return Column(
      children: [
        // 会话概览指标
        Row(
          children: [
            Expanded(child: _buildMetricCard('总会话数', sessionData.totalSessions.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('活跃会话', sessionData.activeSessions.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('平均时长', '${sessionData.averageDuration.toInt()}秒')),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('活跃率', '${((sessionData.activeSessions / sessionData.totalSessions) * 100).toStringAsFixed(1)}%')),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 平台和时间分布
        Row(
          children: [
            Expanded(child: _buildPlatformDistribution(sessionData.platformDistribution)),
            const SizedBox(width: 16),
            Expanded(child: _buildHourlyDistribution(sessionData.hourlyDistribution)),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 会话详细列表
        _buildSessionsList(sessions),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformDistribution(Map<String, int> platformDistribution) {
    final sortedEntries = platformDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '平台分布',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (sortedEntries.isEmpty)
              const Text('暂无平台数据')
            else
              ...sortedEntries.map((entry) {
                final total = platformDistribution.values.fold(0, (a, b) => a + b);
                final percentage = (entry.value / total * 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getPlatformIcon(entry.key),
                                size: 16,
                                color: const Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getPlatformLabel(entry.key),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Text(
                            '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyDistribution(Map<int, int> hourlyDistribution) {
    final sortedEntries = hourlyDistribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '24小时活跃度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (sortedEntries.isEmpty)
              const Text('暂无时间分布数据')
            else
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    final hour = index;
                    final count = hourlyDistribution[hour] ?? 0;
                    final maxCount = hourlyDistribution.values.isEmpty 
                        ? 1 
                        : hourlyDistribution.values.reduce((a, b) => a > b ? a : b);
                    final height = count == 0 ? 2.0 : (count / maxCount * 150).clamp(2.0, 150.0);
                    
                    return Container(
                      width: 20,
                      margin: const EdgeInsets.only(right: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Text(
                              count.toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hour.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<dynamic> sessions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近会话',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (sessions.isEmpty)
              const Text('暂无会话数据')
            else
              Container(
                height: 400,
                child: ListView.builder(
                  itemCount: sessions.length.clamp(0, 20),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _buildSessionItem(session);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(dynamic session) {
    final deviceInfo = session.deviceInfo;
    final deviceModel = deviceInfo['model'] ?? '';
    final appVersion = session.appVersion;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPlatformIcon(session.platform),
                size: 16,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '会话 ${session.sessionId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: session.isActive ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.isActive ? '活跃' : '结束',
                  style: TextStyle(
                    fontSize: 11,
                    color: session.isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSessionDetail(Icons.access_time, '${session.durationSeconds}秒'),
              const SizedBox(width: 16),
              _buildSessionDetail(Icons.visibility, '${session.pageViews}次浏览'),
              const SizedBox(width: 16),
              _buildSessionDetail(Icons.tab, '${session.tabSwitches}次切换'),
            ],
          ),
          if (deviceModel.isNotEmpty || appVersion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (deviceModel.isNotEmpty) ...[
                  Chip(
                    label: Text(deviceModel, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.blue[100],
                  ),
                  const SizedBox(width: 8),
                ],
                if (appVersion.isNotEmpty)
                  Chip(
                    label: Text('v$appVersion', style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getPlatformLabel(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios': return 'iOS';
      case 'android': return 'Android';
      case 'web': return 'Web';
      default: return platform.toUpperCase();
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios': return Icons.phone_iphone;
      case 'android': return Icons.android;
      case 'web': return Icons.web;
      default: return Icons.device_unknown;
    }
  }
}