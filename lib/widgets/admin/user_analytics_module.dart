import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

/// 用户分析模块
/// 基于xq_user_profiles表的用户数据分析
class UserAnalyticsModule extends StatelessWidget {
  const UserAnalyticsModule({super.key});

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
          '用户分析',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '基于用户资料数据的详细分析报告',
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
            onPressed: () => provider.refreshModule('user-analytics'),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsProvider provider) {
    final userAnalytics = provider.userAnalytics;
    if (userAnalytics == null) {
      return const Center(child: Text('暂无用户数据'));
    }

    return Column(
      children: [
        // 用户概览指标
        Row(
          children: [
            Expanded(child: _buildMetricCard('总用户数', userAnalytics.totalUsers.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('活跃用户', userAnalytics.activeUsers.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('会员用户', userAnalytics.memberUsers.toString())),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('会员率', '${((userAnalytics.memberUsers / userAnalytics.totalUsers) * 100).toStringAsFixed(1)}%')),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 性别分布
        if (userAnalytics.genderDistribution.isNotEmpty)
          _buildGenderDistribution(userAnalytics.genderDistribution),
        
        const SizedBox(height: 32),
        
        // 用户详细列表
        _buildUsersList(userAnalytics.userProfiles),
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

  Widget _buildGenderDistribution(Map<String, int> distribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '性别分布',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final percentage = (entry.value / distribution.values.fold(0, (a, b) => a + b) * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(_getGenderLabel(entry.key)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(List<dynamic> users) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '用户详情',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (users.isEmpty)
              const Text('暂无用户数据')
            else
              ...users.take(10).map((user) => _buildUserItem(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(dynamic user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFD700),
            child: Text(
              user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${user.accountStatus} • ${user.isMember ? '会员' : '普通用户'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              user.accountStatus == 'active' ? '活跃' : '非活跃',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: user.accountStatus == 'active' 
                ? Colors.green[100]
                : Colors.grey[100],
          ),
        ],
      ),
    );
  }

  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'male': return '男性';
      case 'female': return '女性';
      case 'other': return '其他';
      default: return '未知';
    }
  }
}