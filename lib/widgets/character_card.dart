import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ai_character.dart';

/// 角色卡片组件 - 用于推荐角色列表等场景
/// 基于设计规范的卡片样式设计
class CharacterCard extends StatelessWidget {
  final AICharacter character;
  final VoidCallback? onTap;
  final bool showFollowButton;

  const CharacterCard({
    super.key,
    required this.character,
    this.onTap,
    this.showFollowButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            // 头像和背景区域
            _buildAvatarSection(),
            
            // 角色信息区域
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  /// 构建头像区域
  Widget _buildAvatarSection() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          // 装饰图案
          Positioned(
            top: 10,
            right: 10,
            child: Text(
              '✨',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ),
          
          // 角色头像
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  character.avatar,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息区域
  Widget _buildInfoSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 角色名称
            Text(
              character.name,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 1),
            
            // 角色描述
            Expanded(
              child: Text(
                character.description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.1,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 2),
            
            // 标签
            _buildTags(),
            
            const SizedBox(height: 2),
            
            // 统计信息和操作按钮
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  /// 构建标签
  Widget _buildTags() {
    if (character.tags.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: character.tags.take(1).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            tag,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建底部区域
  Widget _buildBottomSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 关注数
        Text(
          '${_formatNumber(character.followers)}关注',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
        
        // 关注按钮
        if (showFollowButton)
          GestureDetector(
            onTap: () => _onFollowTap(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: character.isFollowed 
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.highlight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: character.isFollowed 
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.highlight.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                character.isFollowed ? '已关注' : '关注',
                style: AppTextStyles.caption.copyWith(
                  color: character.isFollowed 
                      ? AppColors.accent
                      : AppColors.highlight,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 格式化数字显示
  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  /// 关注按钮点击事件
  void _onFollowTap() {
    // 这里应该触发状态更新，但由于是StatelessWidget，
    // 实际应该通过回调函数传递给父组件处理
    // TODO: 添加关注状态变更回调
  }
}