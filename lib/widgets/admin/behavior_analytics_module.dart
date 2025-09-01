import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

/// 行为分析模块
/// 基于xq_tracking_events表的用户行为数据分析
class BehaviorAnalyticsModule extends StatelessWidget {
  const BehaviorAnalyticsModule({super.key});

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
          '行为分析',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '基于用户行为事件的详细追踪分析',
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
            onPressed: () => provider.refreshModule('behavior-analytics'),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsProvider provider) {
    final behaviorData = provider.behaviorAnalytics;
    final events = provider.trackingEvents;
    
    if (behaviorData == null) {
      return const Center(child: Text('暂无行为数据'));
    }

    return Column(
      children: [
        // 行为概览指标
        Row(
          children: [
            Expanded(child: _buildMetricCard('总事件数', behaviorData.totalEvents.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('事件类型', behaviorData.eventTypeStats.length.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('活跃平台', behaviorData.platformStats.length.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('活跃天数', behaviorData.dailyEventCounts.length.toString())),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 事件类型分布
        Row(
          children: [
            Expanded(child: _buildEventTypeChart(behaviorData.eventTypeStats)),
            const SizedBox(width: 16),
            Expanded(child: _buildPlatformChart(behaviorData.platformStats)),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 最近事件列表
        _buildRecentEventsList(events),
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

  Widget _buildEventTypeChart(Map<String, int> eventTypeStats) {
    final sortedEntries = eventTypeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '事件类型分布',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (sortedEntries.isEmpty)
              const Text('暂无事件数据')
            else
              ...sortedEntries.take(5).map((entry) {
                final total = eventTypeStats.values.fold(0, (a, b) => a + b);
                final percentage = (entry.value / total * 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getEventTypeLabel(entry.key),
                              style: const TextStyle(fontSize: 14),
                            ),
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

  Widget _buildPlatformChart(Map<String, int> platformStats) {
    final sortedEntries = platformStats.entries.toList()
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
                final total = platformStats.values.fold(0, (a, b) => a + b);
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

  Widget _buildRecentEventsList(List<dynamic> events) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近事件',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              const Text('暂无事件数据')
            else
              Container(
                height: 400,
                child: ListView.builder(
                  itemCount: events.length.clamp(0, 20),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventItem(event);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(dynamic event) {
    final platform = event.eventData['device_info']?['platform'] ?? 'unknown';
    final appVersion = event.eventData['device_info']?['appVersion'] ?? '';
    
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
                _getEventIcon(event.eventType),
                size: 16,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getEventTypeLabel(event.eventType),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDateTime(event.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (event.userId != null) ...[
                Chip(
                  label: const Text('注册用户', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.green[100],
                ),
                const SizedBox(width: 8),
              ] else if (event.guestId != null) ...[
                Chip(
                  label: const Text('访客', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.blue[100],
                ),
                const SizedBox(width: 8),
              ],
              Chip(
                label: Text(
                  _getPlatformLabel(platform),
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.grey[200],
              ),
              if (appVersion.isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    'v$appVersion',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getEventTypeLabel(String eventType) {
    switch (eventType) {
      case 'app_launch': return '应用启动';
      case 'page_view': return '页面浏览';
      case 'tab_switch': return '标签切换';
      case 'profile_edit_button_tap': return '编辑资料按钮';
      case 'button_click': return '按钮点击';
      case 'user_login': return '用户登录';
      case 'user_logout': return '用户退出';
      default: return eventType;
    }
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

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'app_launch': return Icons.launch;
      case 'page_view': return Icons.visibility;
      case 'tab_switch': return Icons.tab;
      case 'profile_edit_button_tap': return Icons.edit;
      case 'button_click': return Icons.touch_app;
      case 'user_login': return Icons.login;
      case 'user_logout': return Icons.logout;
      default: return Icons.analytics;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}