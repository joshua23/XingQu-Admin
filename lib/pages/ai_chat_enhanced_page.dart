import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';
import '../models/chat_message.dart';
import '../widgets/ai_chat_bubble_enhanced.dart';
import '../widgets/starry_background.dart';
import '../theme/app_theme.dart';

/// 增强版AI聊天页面
/// 集成火山引擎Edge Functions，支持流式响应
class AiChatEnhancedPage extends StatefulWidget {
  /// AI角色ID（可选）
  final String? characterId;
  
  /// 角色名称（用于显示）
  final String? characterName;
  
  /// 会话ID（可选，不提供则创建新会话）
  final String? sessionId;

  const AiChatEnhancedPage({
    super.key,
    this.characterId,
    this.characterName,
    this.sessionId,
  });

  @override
  State<AiChatEnhancedPage> createState() => _AiChatEnhancedPageState();
}

class _AiChatEnhancedPageState extends State<AiChatEnhancedPage>
    with TickerProviderStateMixin {
  
  /// 输入框控制器
  final TextEditingController _inputController = TextEditingController();
  
  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  /// 焦点节点
  final FocusNode _focusNode = FocusNode();
  
  /// 发送按钮动画控制器
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  
  /// 输入框动画控制器（暂未使用，预留扩展）
  // late AnimationController _inputController2;
  // late Animation<double> _inputHeightAnimation;
  
  /// 是否使用流式响应
  bool _useStreamResponse = true;
  
  /// 温度参数
  double _temperature = 0.7;
  
  /// 最大Token数
  int _maxTokens = 2048;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    // _inputController2.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.elasticOut,
    ));

    // 输入框动画（暂未使用，预留扩展）
    // _inputController2 = AnimationController(
    //   duration: const Duration(milliseconds: 300),
    //   vsync: this,
    // );
    // _inputHeightAnimation = Tween<double>(
    //   begin: 56.0,
    //   end: 120.0,
    // ).animate(CurvedAnimation(
    //   parent: _inputController2,
    //   curve: Curves.easeInOut,
    // ));

    // 监听输入框变化
    _inputController.addListener(_onInputChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  /// 初始化聊天
  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AiChatProvider>();
      
      if (widget.sessionId != null) {
        // TODO: 加载指定会话
      } else if (provider.currentSession == null) {
        // 创建新会话
        provider.createNewSession(
          characterId: widget.characterId,
          title: widget.characterName != null ? '与${widget.characterName}的对话' : null,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 星空背景
          const StarryBackground(
            child: SizedBox.expand(),
          ),
          
          // 主要内容
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildChatArea()),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建应用栏
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // AI头像
          Container(
            width: 36,
            height: 36,
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
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 标题和状态
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.characterName ?? 'AI助手',
                  style: AppTextStyles.h3,
                ),
                Consumer<AiChatProvider>(
                  builder: (context, provider, _) {
                    String status = '在线';
                    if (provider.isSending) {
                      status = '思考中...';
                    } else if (provider.isReceivingStream) {
                      status = '正在回复...';
                    }
                    return Text(
                      status,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 更多菜单
          GestureDetector(
            onTap: _showSettingsMenu,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建聊天区域
  Widget _buildChatArea() {
    return Consumer<AiChatProvider>(
      builder: (context, provider, _) {
        if (provider.messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[index];
            return AiChatBubbleEnhanced(
              message: message,
              showTimestamp: _shouldShowTimestamp(index, provider.messages),
              onRetry: message.type == MessageType.user
                  ? () => provider.retryMessage(message)
                  : null,
              onDelete: () => provider.deleteMessage(message),
            );
          },
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.background,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            widget.characterName != null 
                ? '开始与${widget.characterName}对话吧'
                : '开始对话吧',
            style: AppTextStyles.h3,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '由火山引擎AI驱动，支持智能对话',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 错误提示
          Consumer<AiChatProvider>(
            builder: (context, provider, _) {
              if (provider.error == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: provider.clearError,
                      child: Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // 输入框
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildInputField()),
              const SizedBox(width: 12),
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建输入框
  Widget _buildInputField() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 48,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: _inputController,
        focusNode: _focusNode,
        maxLines: null,
        textInputAction: TextInputAction.newline,
        style: AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: '输入消息...',
          hintStyle: AppTextStyles.body1.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton() {
    return Consumer<AiChatProvider>(
      builder: (context, provider, _) {
        final canSend = _inputController.text.trim().isNotEmpty && 
                       !provider.isSending && 
                       !provider.isReceivingStream;

        return GestureDetector(
          onTap: canSend ? _sendMessage : null,
          child: AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, _) {
              return Transform.scale(
                scale: _sendButtonAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: canSend 
                        ? AppColors.primaryGradient
                        : null,
                    color: canSend ? null : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: canSend 
                          ? Colors.transparent 
                          : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: provider.isSending || provider.isReceivingStream
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: canSend 
                                ? AppColors.background 
                                : AppColors.textTertiary,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: canSend 
                              ? AppColors.background 
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 发送消息
  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<AiChatProvider>();
    _inputController.clear();
    
    // 触发发送按钮动画
    _sendButtonController.forward().then((_) {
      _sendButtonController.reverse();
    });

    // 滚动到底部
    _scrollToBottom();

    try {
      if (_useStreamResponse) {
        await provider.sendMessageStream(
          content: text,
          characterId: widget.characterId,
          temperature: _temperature,
          maxTokens: _maxTokens,
        );
      } else {
        await provider.sendMessage(
          content: text,
          characterId: widget.characterId,
          temperature: _temperature,
          maxTokens: _maxTokens,
        );
      }
    } catch (e) {
      // 错误处理由Provider处理
    }

    // 再次滚动到底部（显示AI回复）
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  /// 输入框内容变化回调
  void _onInputChanged() {
    setState(() {}); // 更新发送按钮状态
  }

  /// 输入框焦点变化回调
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 是否显示时间戳
  bool _shouldShowTimestamp(int index, List<ChatMessage> messages) {
    if (index == 0) return true;
    
    final current = messages[index];
    final previous = messages[index - 1];
    
    return current.timestamp.difference(previous.timestamp).inMinutes > 5;
  }

  /// 显示设置菜单
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSettingsPanel(),
    );
  }

  /// 构建设置面板
  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '对话设置',
            style: AppTextStyles.h2,
          ),
          
          const SizedBox(height: 24),
          
          // 流式响应开关
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '流式响应',
                      style: AppTextStyles.body1,
                    ),
                    Text(
                      '逐字显示AI回复，体验更自然',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useStreamResponse,
                onChanged: (value) {
                  setState(() => _useStreamResponse = value);
                  Navigator.of(context).pop();
                },
                activeColor: AppColors.accent,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 温度参数
          Text(
            '创造性 (${_temperature.toStringAsFixed(1)})',
            style: AppTextStyles.body1,
          ),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: AppColors.accent,
            onChanged: (value) {
              setState(() => _temperature = value);
            },
          ),
          
          const SizedBox(height: 20),
          
          // 清空对话
          GestureDetector(
            onTap: () {
              context.read<AiChatProvider>().clearMessages();
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                '清空对话',
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}