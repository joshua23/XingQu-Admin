import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_membership.dart';
import '../models/subscription_plan.dart';

/// VIP会员卡片组件
/// 展示用户会员状态、权益和升级选项
class VipMembershipCard extends StatelessWidget {
  final UserMembership? membership;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onManagePressed;
  final bool showUpgradeButton;
  final EdgeInsets? margin;

  const VipMembershipCard({
    Key? key,
    this.membership,
    this.onUpgradePressed,
    this.onManagePressed,
    this.showUpgradeButton = true,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFreeMember = membership == null || !membership!.isActive;
    
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getCardGradient(isFreeMember, membership?.membershipTier ?? 0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isFreeMember),
                const SizedBox(height: 16),
                _buildMembershipInfo(isFreeMember),
                const SizedBox(height: 16),
                _buildBenefitsSection(isFreeMember),
                if (!isFreeMember) ...[
                  const SizedBox(height: 16),
                  _buildExpirationInfo(),
                ],
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建卡片头部
  Widget _buildHeader(bool isFreeMember) {
    return Row(
      children: [
        _buildMembershipIcon(isFreeMember),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                membership?.membershipTypeDisplay ?? '免费用户',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _getMembershipSubtitle(isFreeMember),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        if (!isFreeMember && membership!.isExpiringsoon)
          _buildExpiryWarning(),
      ],
    );
  }

  /// 构建会员图标
  Widget _buildMembershipIcon(bool isFreeMember) {
    IconData iconData;
    Color iconColor = Colors.white;
    
    if (isFreeMember) {
      iconData = Icons.person_outline;
    } else {
      switch (membership!.membershipTier) {
        case 1:
          iconData = Icons.star_outline;
          break;
        case 2:
          iconData = Icons.star;
          break;
        case 3:
          iconData = Icons.diamond;
          break;
        default:
          iconData = Icons.workspace_premium;
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// 构建会员信息
  Widget _buildMembershipInfo(bool isFreeMember) {
    if (isFreeMember) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '升级会员，解锁更多功能',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '享受无限创作、高级AI、优先处理等特权',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '会员状态',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  membership!.statusDisplayText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (membership!.autoRenewal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: const Text(
                '自动续费',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    }
  }

  /// 构建权益部分
  Widget _buildBenefitsSection(bool isFreeMember) {
    final benefits = _getMembershipBenefits(isFreeMember);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '会员权益',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                benefit.isIncluded ? Icons.check_circle : Icons.block,
                size: 16,
                color: benefit.isIncluded 
                    ? Colors.greenAccent 
                    : Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefit.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: benefit.isIncluded 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// 构建到期信息
  Widget _buildExpirationInfo() {
    if (membership == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              membership!.remainingDaysText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (membership != null && membership!.isActive && onManagePressed != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onManagePressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '管理会员',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (membership != null && membership!.isActive && onManagePressed != null && showUpgradeButton)
          const SizedBox(width: 12),
        if (showUpgradeButton && onUpgradePressed != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                membership == null || !membership!.isActive ? '立即升级' : '升级套餐',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建到期警告
  Widget _buildExpiryWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: const Text(
        '即将到期',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 获取卡片渐变色
  LinearGradient _getCardGradient(bool isFreeMember, int membershipTier) {
    if (isFreeMember) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[700]!,
          Colors.grey[900]!,
        ],
      );
    }

    switch (membershipTier) {
      case 1: // 基础版 - 蓝色
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
        );
      case 2: // 专业版 - 紫色
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9C27B0),
            Color(0xFF673AB7),
          ],
        );
      case 3: // 企业版 - 金色
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB300),
            Color(0xFFF57C00),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        );
    }
  }

  /// 获取会员副标题
  String _getMembershipSubtitle(bool isFreeMember) {
    if (isFreeMember) {
      return '基础功能可用';
    } else {
      return '享受全部高级功能';
    }
  }

  /// 获取会员权益列表
  List<MembershipBenefit> _getMembershipBenefits(bool isFreeMember) {
    if (isFreeMember) {
      return [
        MembershipBenefit('1个AI智能体', true),
        MembershipBenefit('5次/月创作', true),
        MembershipBenefit('2次/月导出', true),
        MembershipBenefit('高级AI功能', false),
        MembershipBenefit('优先处理', false),
        MembershipBenefit('无水印导出', false),
      ];
    } else {
      final plan = membership?.subscriptionPlan;
      if (plan == null) return [];

      return [
        MembershipBenefit(
          '${plan.aiAgentLimit == -1 ? "无限" : plan.aiAgentLimit}个AI智能体',
          true,
        ),
        MembershipBenefit(
          '${plan.creationLimit == -1 ? "无限" : plan.creationLimit}次/月创作',
          true,
        ),
        MembershipBenefit(
          '${plan.exportLimit == -1 ? "无限" : plan.exportLimit}次/月导出',
          true,
        ),
        MembershipBenefit('高级AI功能', plan.hasAdvancedAI),
        MembershipBenefit('优先处理', plan.hasPriorityProcessing),
        MembershipBenefit('无水印导出', plan.hasWatermarkFree),
      ];
    }
  }
}

/// 会员权益项
class MembershipBenefit {
  final String description;
  final bool isIncluded;

  const MembershipBenefit(this.description, this.isIncluded);
}

/// 简化版VIP卡片（用于列表显示）
class VipMembershipCardCompact extends StatelessWidget {
  final UserMembership? membership;
  final VoidCallback? onTap;

  const VipMembershipCardCompact({
    Key? key,
    this.membership,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFreeMember = membership == null || !membership!.isActive;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _getCardGradient(isFreeMember, membership?.membershipTier ?? 0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIcon(isFreeMember),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership?.membershipTypeDisplay ?? '免费用户',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (!isFreeMember)
                    Text(
                      membership!.remainingDaysText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isFreeMember) {
    IconData iconData = isFreeMember ? Icons.person_outline : Icons.workspace_premium;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  LinearGradient _getCardGradient(bool isFreeMember, int membershipTier) {
    if (isFreeMember) {
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.grey[700]!,
          Colors.grey[800]!,
        ],
      );
    }

    switch (membershipTier) {
      case 1:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        );
      case 2:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFB300), Color(0xFFF57C00)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
        );
    }
  }
}