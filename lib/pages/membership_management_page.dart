import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/vip_membership_card.dart';
import 'subscription_plans_page.dart';

/// 会员管理页面
class MembershipManagementPage extends StatefulWidget {
  const MembershipManagementPage({Key? key}) : super(key: key);

  @override
  State<MembershipManagementPage> createState() => _MembershipManagementPageState();
}

class _MembershipManagementPageState extends State<MembershipManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.initialize(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('会员中心', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '会员概览'),
            Tab(text: '使用统计'),
            Tab(text: '订阅管理'),
          ],
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(subscriptionProvider),
              _buildUsageStatsTab(subscriptionProvider),
              _buildSubscriptionManagementTab(subscriptionProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(SubscriptionProvider subscriptionProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser != null) {
          await subscriptionProvider.refresh(authProvider.currentUser!.id);
        }
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VIP会员卡
            VipMembershipCard(
              membership: subscriptionProvider.currentMembership,
              onUpgradePressed: () => _navigateToSubscriptionPlans(),
              onManagePressed: () => _tabController.animateTo(2),
            ),
            
            const SizedBox(height: 24),
            
            // 会员权益展示
            _buildBenefitsSection(subscriptionProvider),
            
            const SizedBox(height: 24),
            
            // 快速功能入口
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // 推荐升级
            if (!subscriptionProvider.isPremiumUser)
              _buildUpgradeRecommendation(subscriptionProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsTab(SubscriptionProvider subscriptionProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本月使用情况',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 使用统计卡片
          _buildUsageStatsCards(subscriptionProvider),
          
          const SizedBox(height: 24),
          
          // 使用趋势图表（占位）
          _buildUsageTrendChart(),
          
          const SizedBox(height: 24),
          
          // 功能使用排行
          _buildFeatureUsageRanking(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagementTab(SubscriptionProvider subscriptionProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前订阅信息
          if (subscriptionProvider.hasActiveMembership)
            _buildCurrentSubscriptionInfo(subscriptionProvider),
          
          const SizedBox(height: 24),
          
          // 订阅管理操作
          _buildSubscriptionActions(subscriptionProvider),
          
          const SizedBox(height: 24),
          
          // 订阅历史
          _buildSubscriptionHistory(),
          
          const SizedBox(height: 24),
          
          // 帮助与支持
          _buildHelpAndSupport(),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(SubscriptionProvider subscriptionProvider) {
    final benefits = subscriptionProvider.membershipBenefits;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '会员权益',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 权益网格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildBenefitItem(
                icon: Icons.smart_toy,
                title: 'AI智能体',
                value: benefits['ai_agent_limit'] == -1 
                    ? '无限' 
                    : '${benefits['ai_agent_limit'] ?? 1}个',
                isActive: true,
              ),
              _buildBenefitItem(
                icon: Icons.create,
                title: '创作次数',
                value: benefits['creation_limit'] == -1 
                    ? '无限' 
                    : '${benefits['creation_limit'] ?? 5}次/月',
                isActive: true,
              ),
              _buildBenefitItem(
                icon: Icons.download,
                title: '导出次数',
                value: benefits['export_limit'] == -1 
                    ? '无限' 
                    : '${benefits['export_limit'] ?? 2}次/月',
                isActive: true,
              ),
              _buildBenefitItem(
                icon: Icons.priority_high,
                title: '优先处理',
                value: benefits['has_priority_processing'] == true ? '已开启' : '未开启',
                isActive: benefits['has_priority_processing'] == true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary.withOpacity(0.1) 
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.upgrade,
        'title': '升级套餐',
        'subtitle': '解锁更多功能',
        'onTap': () => _navigateToSubscriptionPlans(),
      },
      {
        'icon': Icons.history,
        'title': '使用记录',
        'subtitle': '查看详细记录',
        'onTap': () => _tabController.animateTo(1),
      },
      {
        'icon': Icons.settings,
        'title': '订阅设置',
        'subtitle': '管理自动续费',
        'onTap': () => _tabController.animateTo(2),
      },
      {
        'icon': Icons.help_outline,
        'title': '帮助中心',
        'subtitle': '常见问题解答',
        'onTap': () => _showHelpCenter(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action['icon'] as IconData,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              action['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              action['subtitle'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            onTap: action['onTap'] as VoidCallback,
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildUpgradeRecommendation(SubscriptionProvider subscriptionProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '升级到专业版',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '解锁无限AI智能体、高级功能和优先处理',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateToSubscriptionPlans(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '立即升级',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsCards(SubscriptionProvider subscriptionProvider) {
    // 模拟使用统计数据
    final stats = [
      {'title': 'AI对话次数', 'value': '142', 'limit': '200', 'icon': Icons.chat},
      {'title': '智能体使用', 'value': '8', 'limit': '10', 'icon': Icons.smart_toy},
      {'title': '内容创作', 'value': '23', 'limit': '30', 'icon': Icons.create},
      {'title': '文件导出', 'value': '5', 'limit': '10', 'icon': Icons.download},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: stats.map((stat) {
        final current = int.parse(stat['value'] as String);
        final limit = int.parse(stat['limit'] as String);
        final progress = current / limit;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                stat['title'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/${stat['limit']}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8 ? Colors.orange : AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsageTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '使用趋势',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_chart,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '图表功能开发中',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageRanking() {
    final ranking = [
      {'feature': 'AI对话', 'usage': '142次', 'percentage': 0.85},
      {'feature': '内容创作', 'usage': '23次', 'percentage': 0.65},
      {'feature': '智能体使用', 'usage': '8次', 'percentage': 0.45},
      {'feature': '文件导出', 'usage': '5次', 'percentage': 0.25},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '功能使用排行',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...ranking.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: index == 0 
                          ? Colors.amber 
                          : (index == 1 ? Colors.grey : Colors.brown),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['feature'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: item['percentage'] as double,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item['usage'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionInfo(SubscriptionProvider subscriptionProvider) {
    final membership = subscriptionProvider.currentMembership!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前订阅',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.membershipTypeDisplay,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      membership.remainingDaysText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: membership.autoRenewal 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      membership.autoRenewal ? '自动续费' : '手动续费',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: membership.autoRenewal ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionActions(SubscriptionProvider subscriptionProvider) {
    final actions = [
      if (subscriptionProvider.hasActiveMembership) ...[
        {
          'icon': Icons.autorenew,
          'title': subscriptionProvider.isAutoRenewal ? '关闭自动续费' : '开启自动续费',
          'subtitle': subscriptionProvider.isAutoRenewal ? '下次到期后不会自动续费' : '到期前自动续费',
          'onTap': () => _toggleAutoRenewal(subscriptionProvider),
          'trailing': Switch(
            value: subscriptionProvider.isAutoRenewal,
            onChanged: (value) => _toggleAutoRenewal(subscriptionProvider),
            activeColor: AppColors.primary,
          ),
        },
        {
          'icon': Icons.cancel,
          'title': '取消订阅',
          'subtitle': '立即取消订阅，到期后停止服务',
          'onTap': () => _cancelSubscription(subscriptionProvider),
          'trailing': const Icon(Icons.chevron_right, color: Colors.red),
        },
      ],
      {
        'icon': Icons.upgrade,
        'title': '升级套餐',
        'subtitle': '升级到更高级别的套餐',
        'onTap': () => _navigateToSubscriptionPlans(),
        'trailing': const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      },
      {
        'icon': Icons.receipt,
        'title': '发票管理',
        'subtitle': '查看和下载发票',
        'onTap': () => _showInvoiceManagement(),
        'trailing': const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '订阅管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) {
          final isDestructive = action['title'].toString().contains('取消');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? Colors.red.withOpacity(0.1) 
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: isDestructive ? Colors.red : AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                action['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                action['subtitle'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: action['trailing'] as Widget?,
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              onTap: action['onTap'] as VoidCallback?,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSubscriptionHistory() {
    // 模拟订阅历史数据
    final history = [
      {
        'date': '2024-02-15',
        'plan': '专业版',
        'amount': '¥88',
        'status': '已支付',
        'period': '2024-02-15 至 2024-03-15',
      },
      {
        'date': '2024-01-15',
        'plan': '基础版',
        'amount': '¥38',
        'status': '已支付',
        'period': '2024-01-15 至 2024-02-15',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '订阅历史',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...history.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['plan']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['period']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    item['date']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item['amount']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildHelpAndSupport() {
    final helpItems = [
      {'title': '如何取消订阅？', 'onTap': () => _showHelpDialog('取消订阅')},
      {'title': '如何更改付款方式？', 'onTap': () => _showHelpDialog('更改付款方式')},
      {'title': '订阅到期后会怎样？', 'onTap': () => _showHelpDialog('订阅到期')},
      {'title': '联系客服', 'onTap': () => _contactSupport()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '帮助与支持',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...helpItems.map((item) => ListTile(
          title: Text(
            item['title'] as String,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          onTap: item['onTap'] as VoidCallback,
        )).toList(),
      ],
    );
  }

  void _navigateToSubscriptionPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()),
    );
  }

  void _toggleAutoRenewal(SubscriptionProvider subscriptionProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    final newValue = !subscriptionProvider.isAutoRenewal;
    final success = await subscriptionProvider.toggleAutoRenewal(
      authProvider.currentUser!.id,
      newValue,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue ? '自动续费已开启' : '自动续费已关闭'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _cancelSubscription(SubscriptionProvider subscriptionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('确认取消订阅'),
        content: const Text('取消后将在当前计费周期结束后停止服务，确定要取消订阅吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('再考虑一下'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.currentUser != null) {
                final success = await subscriptionProvider.cancelSubscription(authProvider.currentUser!.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('订阅已取消'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('确定取消', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('帮助中心功能开发中'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showInvoiceManagement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('发票管理功能开发中'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showHelpDialog(String topic) {
    String content = '';
    switch (topic) {
      case '取消订阅':
        content = '您可以在"订阅管理"页面随时取消订阅。取消后，您仍可使用服务至当前计费周期结束。';
        break;
      case '更改付款方式':
        content = '目前暂不支持更改付款方式，请联系客服协助处理。';
        break;
      case '订阅到期':
        content = '订阅到期后，您将无法使用会员专享功能，但历史数据会保留。您可以随时重新订阅。';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(topic),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('客服功能开发中，请通过应用内反馈联系我们'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// 扩展Colors类以支持金银铜色
extension on Colors {
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
}