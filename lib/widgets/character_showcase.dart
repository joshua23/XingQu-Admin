import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ai_character.dart';

/// 角色展示组件 - 用于首页精选页面的主要角色展示区
/// 基于原型文件home-selection.html的main-showcase设计
class CharacterShowcase extends StatelessWidget {
  final AICharacter character;
  final VoidCallback? onTap;

  const CharacterShowcase({
    super.key,
    required this.character,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              AppColors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰
            _buildBackgroundDecoration(),
            
            // 角色展示区域
            _buildCharacterDisplay(),
            
            // 底部信息区域
            _buildCharacterDetails(),
          ],
        ),
      ),
    );
  }

  /// 构建背景装饰
  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.7, -0.3),
            radius: 0.8,
            colors: [
              AppColors.primary.withOpacity(0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: const Center(
          child: Text(
            '✨',
            style: TextStyle(
              fontSize: 100,
              color: Color(0x1AF5DFAF),
              letterSpacing: -5,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建角色展示区域
  Widget _buildCharacterDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 角色头像
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                character.avatar,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 角色名称
          Text(
            character.name,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 角色性格标签
          Text(
            character.personality,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部角色详情
  Widget _buildCharacterDetails() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.background.withOpacity(0.9),
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 角色描述
            Text(
              character.description,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // 标签列表
            _buildTagsList(),
            
            const SizedBox(height: 12),
            
            // 统计信息
            _buildStatsInfo(),
          ],
        ),
      ),
    );
  }

  /// 构建标签列表
  Widget _buildTagsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: character.tags.take(4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.accent.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建统计信息
  Widget _buildStatsInfo() {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.favorite_border,
          value: _formatNumber(character.followers),
          label: '关注',
        ),
        
        const SizedBox(width: 24),
        
        _buildStatItem(
          icon: Icons.message_outlined,
          value: _formatNumber(character.messages),
          label: '消息',
        ),
        
        const Spacer(),
        
        // 互动按钮
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.background,
              ),
              const SizedBox(width: 6),
              Text(
                '开始对话',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14,
                  color: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
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
}