import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

/// 增强版AI对话气泡组件
/// 支持火山引擎流式响应、多种消息类型和交互功能
class AiChatBubbleEnhanced extends StatefulWidget {
  /// 消息数据
  final ChatMessage message;
  
  /// 是否显示时间戳
  final bool showTimestamp;
  
  /// 是否显示状态指示器
  final bool showStatus;
  
  /// 重试回调
  final VoidCallback? onRetry;
  
  /// 删除回调
  final VoidCallback? onDelete;
  
  /// 复制回调
  final VoidCallback? onCopy;

  const AiChatBubbleEnhanced({
    super.key,
    required this.message,
    this.showTimestamp = false,
    this.showStatus = true,
    this.onRetry,
    this.onDelete,
    this.onCopy,
  });

  @override
  State<AiChatBubbleEnhanced> createState() => _AiChatBubbleEnhancedState();
}

class _AiChatBubbleEnhancedState extends State<AiChatBubbleEnhanced>
    with SingleTickerProviderStateMixin {
  
  /// 动画控制器（用于流式响应打字效果）
  late AnimationController _animationController;
  
  /// 是否显示操作菜单
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 如果是流式消息，开始动画
    if (widget.message.isStreaming) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AiChatBubbleEnhanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 流式状态变化时控制动画
    if (widget.message.isStreaming != oldWidget.message.isStreaming) {
      if (widget.message.isStreaming) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _toggleActions,
      onTap: () {
        if (_showActions) {
          setState(() => _showActions = false);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          crossAxisAlignment: _getAlignment(),
          children: [
            if (widget.showTimestamp) _buildTimestamp(),
            Row(
              mainAxisAlignment: _getMainAxisAlignment(),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.message.type == MessageType.assistant) _buildAvatar(),
                const SizedBox(width: 8),
                Flexible(child: _buildMessageBubble()),
                const SizedBox(width: 8),
                if (widget.message.type == MessageType.user) _buildAvatar(),
              ],
            ),
            if (_showActions) _buildActionMenu(),
            if (widget.showStatus) _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  /// 获取对齐方式
  CrossAxisAlignment _getAlignment() {
    switch (widget.message.type) {
      case MessageType.user:
        return CrossAxisAlignment.end;
      case MessageType.assistant:
        return CrossAxisAlignment.start;
      case MessageType.system:
        return CrossAxisAlignment.center;
    }
  }

  /// 获取主轴对齐方式
  MainAxisAlignment _getMainAxisAlignment() {
    switch (widget.message.type) {
      case MessageType.user:
        return MainAxisAlignment.end;
      case MessageType.assistant:
        return MainAxisAlignment.start;
      case MessageType.system:
        return MainAxisAlignment.center;
    }
  }

  /// 构建头像
  Widget _buildAvatar() {
    if (widget.message.type == MessageType.assistant) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: AppColors.background,
          size: 18,
        ),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withOpacity(0.2),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.accent,
          size: 18,
        ),
      );
    }
  }

  /// 构建消息气泡
  Widget _buildMessageBubble() {
    Color bubbleColor;
    Color textColor;
    EdgeInsetsGeometry padding;

    switch (widget.message.type) {
      case MessageType.user:
        bubbleColor = AppColors.accent;
        textColor = AppColors.background;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        break;
      case MessageType.assistant:
        bubbleColor = AppColors.cardBackground;
        textColor = AppColors.textPrimary;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        break;
      case MessageType.system:
        bubbleColor = AppColors.surface.withOpacity(0.5);
        textColor = AppColors.textSecondary;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        break;
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: _getBorderRadius(),
        border: widget.message.status == MessageStatus.failed
            ? Border.all(color: AppColors.error, width: 1)
            : null,
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(textColor),
          if (widget.message.type == MessageType.assistant) 
            _buildAiMessageFooter(),
        ],
      ),
    );
  }

  /// 获取边框圆角
  BorderRadius _getBorderRadius() {
    const radius = 16.0;
    switch (widget.message.type) {
      case MessageType.user:
        return const BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
      case MessageType.assistant:
        return const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
      case MessageType.system:
        return BorderRadius.circular(8);
    }
  }

  /// 构建消息内容
  Widget _buildMessageContent(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.message.content,
            style: AppTextStyles.body1.copyWith(color: textColor),
          ),
        ),
        if (widget.message.isStreaming) _buildTypingIndicator(),
      ],
    );
  }

  /// 构建打字指示器
  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(left: 8),
          child: Text(
            '●',
            style: TextStyle(
              color: AppColors.accent.withOpacity(
                0.3 + (_animationController.value * 0.7),
              ),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  /// 构建AI消息底部信息
  Widget _buildAiMessageFooter() {
    if (widget.message.tokensUsed == null && widget.message.cost == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 8),
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
          if (widget.message.tokensUsed != null)
            Text(
              'Token: ${widget.message.tokensUsed}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          if (widget.message.tokensUsed != null && widget.message.cost != null)
            const SizedBox(width: 12),
          if (widget.message.cost != null)
            Text(
              '成本: ¥${widget.message.cost!.toStringAsFixed(4)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建时间戳
  Widget _buildTimestamp() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Text(
        _formatTimestamp(widget.message.timestamp),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator() {
    if (!widget.showStatus) return const SizedBox.shrink();

    IconData icon;
    Color color;
    
    switch (widget.message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = AppColors.textTertiary;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = AppColors.success;
        break;
      case MessageStatus.receiving:
        icon = Icons.downloading_rounded;
        color = AppColors.accent;
        break;
      case MessageStatus.received:
        icon = Icons.done_all;
        color = AppColors.success;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.error;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  /// 构建操作菜单
  Widget _buildActionMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: '复制',
            onTap: _copyMessage,
          ),
          if (widget.message.status == MessageStatus.failed && widget.onRetry != null)
            _buildActionButton(
              icon: Icons.refresh_rounded,
              label: '重试',
              onTap: widget.onRetry!,
            ),
          if (widget.onDelete != null)
            _buildActionButton(
              icon: Icons.delete_outline_rounded,
              label: '删除',
              onTap: widget.onDelete!,
              color: AppColors.error,
            ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() => _showActions = false);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换操作菜单显示状态
  void _toggleActions() {
    setState(() => _showActions = !_showActions);
  }

  /// 复制消息内容
  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已复制到剪贴板'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}