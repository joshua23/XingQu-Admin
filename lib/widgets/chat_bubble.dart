import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

/// 聊天气泡组件，支持AI和用户两种样式
class ChatBubble extends StatelessWidget {
  final String content;
  final bool isAi;
  final DateTime time;
  final bool isRevoked;
  final String? aiAvatarUrl;
  final VoidCallback? onRevoke;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isAi,
    required this.time,
    this.isRevoked = false,
    this.aiAvatarUrl,
    this.onRevoke,
  });

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isRevoked
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isAi ? 0 : 40,
          right: isAi ? 40 : 0,
        ),
        child: Column(
          crossAxisAlignment:
              isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min, // 防止Row主轴拉伸
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment:
                  isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                if (isAi) AIAvatar(avatarUrl: aiAvatarUrl),
                // 气泡
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.7, // 自适应屏幕宽度
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isAi
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isAi ? AppColors.surfaceVariant : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isAi ? 4 : 18),
                        bottomRight: Radius.circular(isAi ? 18 : 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isRevoked
                        ? Text('已撤回',
                            style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic))
                        : Text(
                            content,
                            style: AppTextStyles.body1.copyWith(
                              color: isAi
                                  ? AppColors.textPrimary
                                  : AppColors.background,
                            ),
                          ),
                  ),
                ),
                if (!isAi)
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceVariant,
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.textSecondary, size: 20),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
                  child: Text(_formatTime(time),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
                if (!isAi && !isRevoked && onRevoke != null)
                  GestureDetector(
                    onTap: onRevoke,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('撤回',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// AI头像组件
class AIAvatar extends StatelessWidget {
  final String? avatarUrl;
  const AIAvatar({super.key, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarUrl == null
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl == null
          ? const FaIcon(FontAwesomeIcons.robot,
              color: AppColors.background, size: 20)
          : null,
    );
  }
}
