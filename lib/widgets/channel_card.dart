import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/audio_content.dart';

/// 频道卡片组件 - 用于FM页面的频道展示
/// 基于原型文件home-fm.html的channel-card设计
class ChannelCard extends StatelessWidget {
  final AudioContent audio;
  final bool isActive;
  final VoidCallback? onTap;

  const ChannelCard({
    super.key,
    required this.audio,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.divider,
            width: isActive ? 1.5 : 0.5,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 频道图标
              _buildChannelIcon(),
              
              const SizedBox(height: 12),
              
              // 频道信息
              _buildChannelInfo(),
              
              const Spacer(),
              
              // 播放状态指示器
              if (isActive)
                _buildPlayingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建频道图标
  Widget _buildChannelIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isActive 
            ? AppColors.accentGradient
            : AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.accent : AppColors.primary)
                .withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          audio.cover,
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建频道信息
  Widget _buildChannelInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 频道名称
        Text(
          audio.title,
          style: AppTextStyles.body1.copyWith(
            color: isActive ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // 频道描述
        Text(
          audio.description,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // 分类标签
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: (isActive ? AppColors.accent : AppColors.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (isActive ? AppColors.accent : AppColors.primary)
                  .withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            audio.category,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.accent : AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建播放状态指示器
  Widget _buildPlayingIndicator() {
    return Row(
      children: [
        // 播放动画指示器
        SizedBox(
          width: 16,
          height: 12,
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 2 ? 2 : 0,
                  ),
                  child: _AnimatedBar(
                    delay: Duration(milliseconds: index * 100),
                  ),
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(width: 8),
        
        Text(
          '正在播放',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 动画播放条组件
class _AnimatedBar extends StatefulWidget {
  final Duration delay;

  const _AnimatedBar({required this.delay});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 延迟启动动画
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 2,
          height: 12 * _animation.value,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }
}