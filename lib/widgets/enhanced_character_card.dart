import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_character.dart';
import '../theme/app_theme.dart';
import '../pages/ai_chat_enhanced_page.dart';
import '../providers/ai_chat_provider.dart';

/// 增强版角色卡片组件
/// 支持一键对话、关注状态、统计信息等功能
class EnhancedCharacterCard extends StatefulWidget {
  /// AI角色数据
  final AICharacter character;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否显示关注按钮
  final bool showFollowButton;
  
  /// 是否显示统计信息
  final bool showStats;
  
  /// 卡片宽度
  final double? width;
  
  /// 卡片高度
  final double? height;

  const EnhancedCharacterCard({
    super.key,
    required this.character,
    this.onTap,
    this.showFollowButton = true,
    this.showStats = true,
    this.width,
    this.height,
  });

  @override
  State<EnhancedCharacterCard> createState() => _EnhancedCharacterCardState();
}

class _EnhancedCharacterCardState extends State<EnhancedCharacterCard>
    with SingleTickerProviderStateMixin {
  
  /// 动画控制器
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  /// 是否已关注
  bool _isFollowed = false;
  
  /// 关注人数
  int _followerCount = 0;
  
  /// 消息数量
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  /// 初始化数据
  void _initializeData() {
    // 从角色数据中获取统计信息
    _followerCount = widget.character.followerCount ?? 0;
    _messageCount = widget.character.messageCount ?? 0;
    _isFollowed = widget.character.isFollowing ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap ?? _onCardTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? 160,
              height: widget.height ?? 220,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.divider,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(_glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  _buildContentSection(),
                  _buildFooterSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建头部区域（头像和关注按钮）
  Widget _buildHeaderSection() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          // 装饰背景
          _buildDecorationBackground(),
          
          // 角色头像
          Center(
            child: _buildAvatar(),
          ),
          
          // 关注按钮
          if (widget.showFollowButton)
            Positioned(
              top: 12,
              right: 12,
              child: _buildFollowButton(),
            ),
        ],
      ),
    );
  }

  /// 构建装饰背景
  Widget _buildDecorationBackground() {
    return Stack(
      children: [
        Positioned(
          top: 20,
          right: 20,
          child: Icon(
            Icons.auto_awesome,
            color: AppColors.primary.withOpacity(0.2),
            size: 24,
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Icon(
            Icons.star_rounded,
            color: AppColors.accent.withOpacity(0.2),
            size: 16,
          ),
        ),
        Positioned(
          top: 40,
          left: 30,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: widget.character.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                widget.character.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        widget.character.name.isNotEmpty 
            ? widget.character.name[0].toUpperCase()
            : 'A',
        style: AppTextStyles.h2.copyWith(
          color: AppColors.background,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建关注按钮
  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isFollowed ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFollowed ? AppColors.accent : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowed ? Icons.favorite : Icons.favorite_border,
              color: _isFollowed ? AppColors.background : AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _isFollowed ? '已关注' : '关注',
              style: AppTextStyles.caption.copyWith(
                color: _isFollowed ? AppColors.background : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容区域（角色信息）
  Widget _buildContentSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 角色名称
            Text(
              widget.character.name,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
            
            // 角色描述
            if (widget.character.personality?.isNotEmpty == true)
              Text(
                widget.character.personality!,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            
            const Spacer(),
            
            // 标签
            if (widget.character.tags?.isNotEmpty == true)
              _buildTagsRow(),
          ],
        ),
      ),
    );
  }

  /// 构建标签行
  Widget _buildTagsRow() {
    final tags = widget.character.tags!.take(2).toList();
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          tag,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      )).toList(),
    );
  }

  /// 构建底部区域（统计信息和操作按钮）
  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 统计信息
          if (widget.showStats) _buildStatsInfo(),
          
          const Spacer(),
          
          // 一键对话按钮
          _buildChatButton(),
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatsInfo() {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.favorite,
          count: _formatCount(_followerCount),
          color: AppColors.error,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.chat_bubble_outline,
          count: _formatCount(_messageCount),
          color: AppColors.accent,
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 2),
        Text(
          count,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// 构建对话按钮
  Widget _buildChatButton() {
    return GestureDetector(
      onTap: _startChat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_rounded,
              color: AppColors.background,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '对话',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 卡片点击处理
  void _onCardTap() {
    // 默认行为：开始对话
    _startChat();
  }

  /// 开始对话
  void _startChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiChatEnhancedPage(
          characterId: widget.character.id,
          characterName: widget.character.name,
        ),
      ),
    );
  }

  /// 切换关注状态
  void _toggleFollow() {
    setState(() {
      _isFollowed = !_isFollowed;
      if (_isFollowed) {
        _followerCount++;
      } else {
        _followerCount--;
      }
    });
    
    // TODO: 调用API更新关注状态
    // await ApiService.instance.toggleCharacterFollow(widget.character.id);
  }

  /// 格式化数量显示
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 10000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else if (count < 100000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else {
      return '${(count / 10000).toInt()}万';
    }
  }
}