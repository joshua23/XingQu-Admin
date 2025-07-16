import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/loading_animation.dart';

/// AI聊天页
/// 包含AI对话界面、输入框、消息气泡、AI头像、发送动画等
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

/// 聊天消息模型
class ChatMessage {
  /// 消息内容
  final String content;

  /// 是否为AI消息
  final bool isAi;

  /// 发送时间
  final DateTime time;
  final bool isRevoked; // 是否已撤回
  final String? aiAvatarUrl; // AI头像自定义
  /// 构造函数
  ChatMessage({
    required this.content,
    required this.isAi,
    required this.time,
    this.isRevoked = false,
    this.aiAvatarUrl,
  });
  // 复制方法，便于撤回
  ChatMessage copyWith({String? content, bool? isRevoked}) {
    return ChatMessage(
      content: content ?? this.content,
      isAi: isAi,
      time: time,
      isRevoked: isRevoked ?? this.isRevoked,
      aiAvatarUrl: aiAvatarUrl,
    );
  }
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  // 聊天消息列表
  final List<ChatMessage> _messages = [
    ChatMessage(
        content: '你好，我是星趣AI，有什么可以帮你？',
        isAi: true,
        time: DateTime.now(),
        aiAvatarUrl: null),
  ];
  // 输入框控制器
  final TextEditingController _controller = TextEditingController();
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  // 发送动画控制器
  late AnimationController _sendAnimController;
  late Animation<double> _sendAnim;

  @override
  void initState() {
    super.initState();
    _sendAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sendAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _sendAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sendAnimController.dispose();
    super.dispose();
  }

  /// 发送消息
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages
          .add(ChatMessage(content: text, isAi: false, time: DateTime.now()));
      _controller.clear();
    });
    _scrollToBottom();
    _sendAnimController.forward(from: 0);
    // 模拟AI回复
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _messages.add(ChatMessage(
          content: 'AI回复：$text',
          isAi: true,
          time: DateTime.now(),
          aiAvatarUrl: null));
    });
    _scrollToBottom();
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.robot,
                color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text('AI聊天', style: AppTextStyles.h3),
          ],
        ),
        centerTitle: true,
        actions: [
          // 角色管理按钮
          IconButton(
            onPressed: () => _navigateToCharacterManagement(),
            icon: const FaIcon(FontAwesomeIcons.userGroup,
                color: AppColors.textSecondary, size: 20),
            tooltip: '角色管理',
          ),
          // 设置按钮
          IconButton(
            onPressed: () => _navigateToSettings(),
            icon: const FaIcon(FontAwesomeIcons.cog,
                color: AppColors.textSecondary, size: 20),
            tooltip: '聊天设置',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 聊天消息列表
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return ChatBubble(
                    content: msg.content,
                    isAi: msg.isAi,
                    time: msg.time,
                    isRevoked: msg.isRevoked,
                    aiAvatarUrl: msg.aiAvatarUrl,
                    onRevoke: (!msg.isAi && !msg.isRevoked)
                        ? () => _revokeMessage(index)
                        : null,
                  );
                },
              ),
            ),
            // 输入栏
            ChatInputBar(
              controller: _controller,
              sendAnim: _sendAnim,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  /// 撤回消息
  void _revokeMessage(int index) {
    setState(() {
      _messages[index] =
          _messages[index].copyWith(content: '', isRevoked: true);
    });
  }

  /// 导航到角色管理页面
  void _navigateToCharacterManagement() {
    Navigator.pushNamed(context, '/character_management');
  }

  /// 导航到聊天设置页面
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/ai_chat_settings');
  }
}
