import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 聊天输入栏组件，支持多行输入和发送按钮动画
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Animation<double> sendAnim;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.sendAnim,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: AppTextStyles.body1,
              decoration: const InputDecoration(
                hintText: '请输入内容...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          ScaleTransition(
            scale: sendAnim,
            child: GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.send,
                    color: AppColors.background, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
