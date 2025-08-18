import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/subscription_plan.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/vip_membership_card.dart';
import 'payment_confirmation_page.dart';

/// 订阅套餐选择页面
class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  bool _isYearlyBilling = false;
  String _selectedPaymentMethod = 'wechat';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      subscriptionProvider.initialize(authProvider.currentUser!.id);
    } else {
      subscriptionProvider.loadAvailablePlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('选择会员套餐', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          if (subscriptionProvider.isLoadingPlans) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (subscriptionProvider.error != null) {
            return _buildErrorWidget(subscriptionProvider.error!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 当前会员状态
                if (subscriptionProvider.currentMembership != null)
                  VipMembershipCardCompact(
                    membership: subscriptionProvider.currentMembership,
                    onTap: () => _showMembershipDetails(),
                  ),
                
                const SizedBox(height: 24),
                
                // 计费周期选择
                _buildBillingCycleSelector(),
                
                const SizedBox(height: 24),
                
                // 套餐列表
                _buildPlansList(subscriptionProvider.availablePlans),
                
                const SizedBox(height: 24),
                
                // 支付方式选择
                _buildPaymentMethodSelector(),
                
                const SizedBox(height: 32),
                
                // 功能对比表格
                _buildFeatureComparison(subscriptionProvider.availablePlans),
                
                const SizedBox(height: 24),
                
                // 常见问题
                _buildFAQSection(),
                
                const SizedBox(height: 80), // 为底部按钮留空间
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCycleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '计费周期',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isYearlyBilling = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: !_isYearlyBilling ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '按月计费',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: !_isYearlyBilling ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isYearlyBilling = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isYearlyBilling ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '按年计费',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isYearlyBilling ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (_isYearlyBilling)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '省20%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlansList(List<SubscriptionPlan> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择套餐',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...plans.map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isRecommended = plan.planTier == 2; // 专业版推荐
    final currentPrice = _isYearlyBilling && plan.priceYearly != null
        ? plan.priceYearly!
        : plan.priceMonthly;
    final priceText = _isYearlyBilling && plan.priceYearly != null
        ? '¥${plan.priceYearly!.toStringAsFixed(0)}/年'
        : '¥${plan.priceMonthly.toStringAsFixed(0)}/月';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? AppColors.primary : AppColors.border,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Stack(
        children: [
          if (isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  '推荐',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.planName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.description,
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
                        if (_isYearlyBilling && plan.priceYearly != null && plan.yearlyDiscount > 0)
                          Text(
                            '¥${(plan.priceMonthly * 12).toStringAsFixed(0)}/年',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        Text(
                          priceText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: plan.isFree ? AppColors.textSecondary : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 主要功能列表
                ...plan.features.entries.take(4).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFeatureDisplayText(entry.key, entry.value),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                
                // 选择按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: plan.isFree ? null : () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isFree 
                          ? AppColors.surface 
                          : (isRecommended ? AppColors.primary : AppColors.secondary),
                      foregroundColor: plan.isFree 
                          ? AppColors.textSecondary 
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      plan.isFree ? '当前方案' : '选择此套餐',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final paymentMethods = [
      {'id': 'wechat', 'name': '微信支付', 'icon': Icons.wechat},
      {'id': 'alipay', 'name': '支付宝', 'icon': Icons.payment},
      {'id': 'apple', 'name': 'Apple Pay', 'icon': Icons.apple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '支付方式',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod == method['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = method['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    method['icon'] as IconData,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFeatureComparison(List<SubscriptionPlan> plans) {
    final features = [
      'AI智能体数量',
      '创作次数/月',
      '导出次数/月', 
      '高级AI功能',
      '优先处理',
      '无水印导出',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '功能对比',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Table(
            children: [
              // 表头
              TableRow(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '功能',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ...plans.take(3).map((plan) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      plan.tierName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )).toList(),
                ],
              ),
              // 功能行
              ...features.map((feature) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ...plans.take(3).map((plan) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _getFeatureValueForComparison(feature, plan),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )).toList(),
                ],
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': '可以随时取消订阅吗？',
        'answer': '是的，您可以随时在会员管理页面取消订阅。取消后，您仍可使用至当前计费周期结束。'
      },
      {
        'question': '升级套餐如何计费？',
        'answer': '升级时会按比例计算剩余时间的差价，立即享受新套餐的所有功能。'
      },
      {
        'question': '支持哪些支付方式？',
        'answer': '目前支持微信支付、支付宝和Apple Pay。所有支付都通过安全加密通道处理。'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '常见问题',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...faqs.map((faq) => Container(
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
              Text(
                faq['question']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                faq['answer']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  String _getFeatureDisplayText(String key, dynamic value) {
    switch (key) {
      case 'ai_agent_limit':
        return value == -1 ? '无限AI智能体' : '${value}个AI智能体';
      case 'creation_limit':
        return value == -1 ? '无限次创作' : '${value}次/月创作';
      case 'export_limit':
        return value == -1 ? '无限次导出' : '${value}次/月导出';
      case 'advanced_ai':
        return value ? '高级AI功能' : '基础AI功能';
      case 'priority_processing':
        return value ? '优先处理' : '标准处理';
      case 'watermark_free':
        return value ? '无水印导出' : '带水印导出';
      default:
        return '$key: $value';
    }
  }

  String _getFeatureValueForComparison(String feature, SubscriptionPlan plan) {
    switch (feature) {
      case 'AI智能体数量':
        final limit = plan.aiAgentLimit;
        return limit == -1 ? '无限' : '$limit个';
      case '创作次数/月':
        final limit = plan.creationLimit;
        return limit == -1 ? '无限' : '$limit次';
      case '导出次数/月':
        final limit = plan.exportLimit;
        return limit == -1 ? '无限' : '$limit次';
      case '高级AI功能':
        return plan.hasAdvancedAI ? '✓' : '✗';
      case '优先处理':
        return plan.hasPriorityProcessing ? '✓' : '✗';
      case '无水印导出':
        return plan.hasWatermarkFree ? '✓' : '✗';
      default:
        return '—';
    }
  }

  void _selectPlan(SubscriptionPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationPage(
          plan: plan,
          isYearly: _isYearlyBilling,
          paymentMethod: _selectedPaymentMethod,
        ),
      ),
    );
  }

  void _showMembershipDetails() {
    // 显示会员详情对话框或跳转到会员管理页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('会员详情功能即将推出'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}