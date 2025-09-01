import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

/// 实时监控模块
/// 展示系统实时指标和状态监控
class RealTimeModule extends StatelessWidget {
  const RealTimeModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
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

  Widget _buildHeader(AnalyticsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '实时监控',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '系统实时指标监控和状态追踪',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // 自动刷新开关
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('自动刷新', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Switch(
                  value: true, // TODO: 从provider获取状态
                  onChanged: (value) {
                    // TODO: 实现自动刷新功能
                  },
                  activeColor: const Color(0xFFFFD700),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 手动刷新按钮
            IconButton(
              onPressed: () => provider.refreshModule('realtime'),
              icon: const Icon(Icons.refresh),
              tooltip: '刷新数据',
            ),
          ],
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
            onPressed: () => provider.refreshModule('realtime'),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsProvider provider) {
    final realTimeMetrics = provider.realTimeMetrics;
    
    return Column(
      children: [
        // 实时指标卡片
        if (realTimeMetrics != null)
          _buildRealTimeMetrics(realTimeMetrics),
        
        const SizedBox(height: 32),
        
        // 系统状态和监控面板
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSystemStatus(realTimeMetrics)),
            const SizedBox(width: 16),
            Expanded(child: _buildMonitoringPanel(provider)),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 实时活动流
        _buildRealTimeActivity(provider),
      ],
    );
  }

  Widget _buildRealTimeMetrics(dynamic realTimeMetrics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            '当前活跃用户',
            realTimeMetrics.currentActiveUsers.toString(),
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            '每小时事件',
            realTimeMetrics.eventsPerHour.toString(),
            Icons.timeline,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            '系统状态',
            _getStatusLabel(realTimeMetrics.systemStatus),
            Icons.health_and_safety,
            _getStatusColor(realTimeMetrics.systemStatus),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            '最后更新',
            _formatTime(realTimeMetrics.lastUpdateTime),
            Icons.update,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus(dynamic realTimeMetrics) {
    final status = realTimeMetrics?.systemStatus ?? 'unknown';
    final statusColor = _getStatusColor(status);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '系统状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 整体状态
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '系统运行${_getStatusLabel(status)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 各个服务状态
            _buildServiceStatus('数据库连接', true),
            _buildServiceStatus('API服务', true),
            _buildServiceStatus('实时推送', true),
            _buildServiceStatus('文件存储', true),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus(String serviceName, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(serviceName),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isHealthy ? '正常' : '异常',
                style: TextStyle(
                  fontSize: 12,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringPanel(AnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '监控面板',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 性能指标
            _buildPerformanceMetric('API响应时间', '95ms', Icons.speed),
            _buildPerformanceMetric('数据库连接', '12ms', Icons.storage),
            _buildPerformanceMetric('内存使用率', '68%', Icons.memory),
            _buildPerformanceMetric('CPU使用率', '23%', Icons.computer),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 实现系统诊断
                    },
                    icon: const Icon(Icons.health_and_safety, size: 16),
                    label: const Text('系统诊断'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 实现清理缓存
                    },
                    icon: const Icon(Icons.cleaning_services, size: 16),
                    label: const Text('清理缓存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[100],
                      foregroundColor: Colors.orange[700],
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

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeActivity(AnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '实时活动流',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: 实现暂停/恢复功能
                  },
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('暂停'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: 8, // 模拟实时活动
                itemBuilder: (context, index) {
                  return _buildActivityItem(
                    _getMockActivity(index),
                    DateTime.now().subtract(Duration(minutes: index)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            _formatTime(timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _getMockActivity(int index) {
    final activities = [
      '用户登录系统',
      '新用户注册',
      'API调用成功',
      '数据同步完成',
      '用户浏览页面',
      '系统自动备份',
      '缓存清理完成',
      '健康检查通过',
    ];
    return activities[index % activities.length];
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'healthy': return '正常';
      case 'warning': return '警告';
      case 'error': return '错误';
      default: return '未知';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}