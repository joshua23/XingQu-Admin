import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_membership.dart';

/// 增强版VIP会员卡片组件
/// 提供流畅的动画效果、详细的权益展示和交互优化
class EnhancedVipMembershipCard extends StatefulWidget {
  final UserMembership? membership;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onManagePressed;
  final VoidCallback? onTap;
  final bool showBenefitsDetail;
  final bool enableAnimation;
  final EdgeInsets? margin;

  const EnhancedVipMembershipCard({
    super.key,
    this.membership,
    this.onUpgradePressed,
    this.onManagePressed,
    this.onTap,
    this.showBenefitsDetail = true,
    this.enableAnimation = true,
    this.margin,
  });

  @override
  State<EnhancedVipMembershipCard> createState() => _EnhancedVipMembershipCardState();
}

class _EnhancedVipMembershipCardState extends State<EnhancedVipMembershipCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _isExpanded = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    if (!widget.enableAnimation) return;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 循环闪烁动画（仅VIP会员）
    if (!_isFreeMember) {
      _shimmerAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.repeat(reverse: true);
    }
  }

  /// 是否为免费用户
  bool get _isFreeMember => widget.membership == null || !widget.membership!.isActive;

  /// 获取会员等级颜色
  Color get _membershipColor {
    if (_isFreeMember) return AppColors.textSecondary;
    
    switch (widget.membership!.membershipTier) {
      case 1: return const Color(0xFFFFD700); // 金色
      case 2: return const Color(0xFFFF6B6B); // 红色
      case 3: return const Color(0xFF9B59B6); // 紫色
      default: return AppColors.accent;
    }
  }

  /// 获取会员等级渐变
  LinearGradient get _membershipGradient {
    if (_isFreeMember) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surface,
          AppColors.cardBackground,
        ],
      );
    }
    
    final baseColor = _membershipColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(0.6),
        baseColor.withOpacity(0.4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onPressedChanged(true),
      onTapUp: (_) => _onPressedChanged(false),
      onTapCancel: () => _onPressedChanged(false),
      onTap: widget.onTap ?? _toggleExpansion,
      child: widget.enableAnimation
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Transform.scale(
                scale: _isPressed ? _scaleAnimation.value : 1.0,
                child: _buildCard(),
              ),
            )
          : _buildCard(),
    );
  }

  /// 构建卡片主体
  Widget _buildCard() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _membershipGradient,
        boxShadow: [
          BoxShadow(
            color: _membershipColor.withOpacity(
              widget.enableAnimation && !_isFreeMember 
                  ? _glowAnimation.value 
                  : 0.2
            ),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 背景装饰
            _buildBackgroundDecoration(),
            
            // 主要内容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildMembershipStatus(),
                  const SizedBox(height: 16),
                  _buildQuickBenefits(),
                  
                  // 展开的详细内容
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded ? _buildExpandedContent() : const SizedBox.shrink(),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建背景装饰
  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 几何图案
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          // VIP星星装饰（仅VIP用户）
          if (!_isFreeMember) ..._buildStarDecorations(),
        ],
      ),
    );
  }

  /// 构建星星装饰
  List<Widget> _buildStarDecorations() {
    return [
      Positioned(
        top: 30,
        right: 30,
        child: Icon(
          Icons.star,
          color: Colors.white.withOpacity(0.3),
          size: 16,
        ),
      ),
      Positioned(
        bottom: 50,
        right: 50,
        child: Icon(
          Icons.star_outline,
          color: Colors.white.withOpacity(0.2),
          size: 12,
        ),
      ),
    ];
  }

  /// 构建头部
  Widget _buildHeader() {
    return Row(
      children: [
        // 会员图标
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            _getMembershipIcon(),
            color: Colors.white,
            size: 28,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 会员信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getMembershipTitle(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getMembershipSubtitle(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        
        // 展开/收起按钮
        GestureDetector(
          onTap: _toggleExpansion,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建会员状态
  Widget _buildMembershipStatus() {
    if (_isFreeMember) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '升级VIP会员，解锁全部功能',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // 有效期
        Expanded(
          child: _buildStatusItem(
            icon: Icons.schedule,
            label: '有效期至',
            value: _formatExpiryDate(),
          ),
        ),
        const SizedBox(width: 16),
        
        // 使用状态
        Expanded(
          child: _buildStatusItem(
            icon: Icons.trending_up,
            label: '本月使用',
            value: '0次', // TODO: 实现使用次数统计
          ),
        ),
      ],
    );
  }

  /// 构建状态项
  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 构建快速权益展示
  Widget _buildQuickBenefits() {
    final benefits = _getQuickBenefits();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: benefits.map((benefit) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              benefit['icon'],
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              benefit['text'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  /// 构建展开内容
  Widget _buildExpandedContent() {
    if (!widget.showBenefitsDetail) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        // 分隔线
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.2),
        ),
        
        const SizedBox(height: 16),
        
        // 详细权益
        const Text(
          '会员权益详情',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ..._getDetailedBenefits().map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benefit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_isFreeMember) ...[
          Expanded(
            child: _buildActionButton(
              text: '立即升级',
              onPressed: widget.onUpgradePressed,
              isPrimary: true,
            ),
          ),
        ] else ...[
          Expanded(
            child: _buildActionButton(
              text: '管理会员',
              onPressed: widget.onManagePressed,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              text: '续费升级',
              onPressed: widget.onUpgradePressed,
              isPrimary: true,
            ),
          ),
        ],
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary 
              ? Colors.white
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22),
          border: isPrimary 
              ? null 
              : Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? _membershipColor : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 处理按压状态变化
  void _onPressedChanged(bool isPressed) {
    if (!widget.enableAnimation) return;
    setState(() => _isPressed = isPressed);
  }

  /// 切换展开状态
  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
  }

  /// 获取会员图标
  IconData _getMembershipIcon() {
    if (_isFreeMember) return Icons.person_outline;
    
    switch (widget.membership!.membershipTier) {
      case 1: return Icons.star_outline;
      case 2: return Icons.star;
      case 3: return Icons.diamond;
      default: return Icons.workspace_premium;
    }
  }

  /// 获取会员标题
  String _getMembershipTitle() {
    if (_isFreeMember) return '免费用户';
    return widget.membership!.membershipTypeDisplay;
  }

  /// 获取会员副标题
  String _getMembershipSubtitle() {
    if (_isFreeMember) return '体验基础功能';
    return '尊享专属权益';
  }

  /// 格式化到期日期
  String _formatExpiryDate() {
    if (widget.membership == null) return '永久';
    
    final expiry = widget.membership!.endDate;
    final now = DateTime.now();
    final difference = expiry.difference(now);
    
    if (difference.inDays > 30) {
      return '${expiry.year}年${expiry.month}月${expiry.day}日';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天后到期';
    } else {
      return '已过期';
    }
  }

  /// 获取快速权益列表
  List<Map<String, dynamic>> _getQuickBenefits() {
    if (_isFreeMember) {
      return [
        {'icon': Icons.chat, 'text': '基础对话'},
        {'icon': Icons.lock, 'text': '功能受限'},
      ];
    }
    
    return [
      {'icon': Icons.chat_bubble, 'text': '无限对话'},
      {'icon': Icons.speed, 'text': '优先响应'},
      {'icon': Icons.star, 'text': '专属角色'},
      {'icon': Icons.cloud_download, 'text': '导出记录'},
    ];
  }

  /// 获取详细权益列表
  List<String> _getDetailedBenefits() {
    if (_isFreeMember) {
      return [
        '每日5次AI对话',
        '基础角色库访问',
        '标准响应速度',
      ];
    }
    
    switch (widget.membership!.membershipTier) {
      case 1:
        return [
          '无限AI对话次数',
          '访问高级角色库',
          '优先响应速度',
          '对话记录导出',
          '去除广告',
        ];
      case 2:
        return [
          '包含黄金会员所有权益',
          '专属定制角色',
          '高级语音合成',
          '多模态对话',
          '专属客服',
        ];
      case 3:
        return [
          '包含钻石会员所有权益',
          '私人定制服务',
          'API接口访问',
          '数据分析报告',
          '优先新功能体验',
        ];
      default:
        return ['未知会员类型'];
    }
  }
}