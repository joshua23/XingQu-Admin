import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 音频播放器组件 - 占位实现
/// 未来可扩展为完整的音频播放功能
class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          '音频播放器组件 - 开发中',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}