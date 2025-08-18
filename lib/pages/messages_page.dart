import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 消息页（Messages Page）
/// 展示私信列表和通知入口 - 现代化设计风格
class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> 
    with TickerProviderStateMixin {
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;
  
  // 动画控制器
  late AnimationController _searchController2;
  late Animation<double> _searchAnimation;
  
  @override
  void initState() {
    super.initState();
    _searchController2 = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchController2,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 示例私信数据
    final List<_MessageItem> messages = [
      _MessageItem(
        avatarUrl: null,
        name: '星趣AI',
        lastMsg: '你好，有什么可以帮你？',
        time: '09:30',
        unread: 2,
        isOnline: true,
        avatarEmoji: '🤖',
      ),
      _MessageItem(
        avatarUrl: null,
        name: '智能助手小爱',
        lastMsg: '今天的学习计划准备好了',
        time: '08:45',
        unread: 1,
        isOnline: true,
        avatarEmoji: '📚',
      ),
      _MessageItem(
        avatarUrl: null,
        name: '星空夜语电台',
        lastMsg: '今晚的节目很精彩哦',
        time: '08:15',
        unread: 0,
        isOnline: false,
        avatarEmoji: '🌙',
      ),
      _MessageItem(
        avatarUrl: null,
        name: '创意写作助手',
        lastMsg: '你的故事灵感来了！',
        time: '昨天',
        unread: 0,
        isOnline: false,
        avatarEmoji: '✍️',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 主要内容
          Column(
            children: [
              // 自定义头部
              _buildCustomHeader(),
              
              // 搜索栏（可展开）
              _buildSearchSection(),
              
              // 通知入口卡片
              _buildNotificationCard(),
              
              // 私信列表
              Expanded(
                child: _buildMessagesList(messages),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建自定义头部
  Widget _buildCustomHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '消息',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '与AI伙伴的对话',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 搜索按钮
              GestureDetector(
                onTap: _toggleSearchMode,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isSearchMode ? Icons.close : Icons.search,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 更多选项
              GestureDetector(
                onTap: () {
                  _showMoreOptions(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建搜索区域
  Widget _buildSearchSection() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _searchAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.body1,
                decoration: InputDecoration(
                  hintText: '搜索对话...',
                  hintStyle: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// 构建通知卡片
  Widget _buildNotificationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: AppColors.accent,
            size: 24,
          ),
        ),
        title: Text(
          '系统通知',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '查看系统消息和重要通知',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        onTap: () {
          // 处理系统通知点击
        },
      ),
    );
  }
  
  /// 构建消息列表
  Widget _buildMessagesList(List<_MessageItem> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageCard(msg, index);
      },
    );
  }
  
  /// 构建消息卡片
  Widget _buildMessageCard(_MessageItem msg, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            // 头像
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: msg.isOnline ? Colors.green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  msg.avatarEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            // 在线状态指示器
            if (msg.isOnline)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                msg.name,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              msg.time,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  msg.lastMsg,
                  style: AppTextStyles.body2.copyWith(
                    color: msg.unread > 0 
                        ? AppColors.textPrimary 
                        : AppColors.textSecondary,
                    fontWeight: msg.unread > 0 
                        ? FontWeight.w500 
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 未读消息数量
              if (msg.unread > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${msg.unread}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: () {
          // 跳转到聊天详情
          _onMessageTap(msg);
        },
      ),
    );
  }
  
  /// 切换搜索模式
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
    });
    
    if (_isSearchMode) {
      _searchController2.forward();
    } else {
      _searchController2.reverse();
      _searchController.clear();
    }
  }
  
  /// 显示更多选项
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Icon(
                Icons.mark_as_unread,
                color: AppColors.primary,
              ),
              title: Text(
                '标记所有为已读',
                style: AppTextStyles.body1,
              ),
              onTap: () {
                Navigator.pop(context);
                // 处理标记已读
              },
            ),
            
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              title: Text(
                '清空聊天记录',
                style: AppTextStyles.body1,
              ),
              onTap: () {
                Navigator.pop(context);
                // 处理清空记录
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  /// 处理消息点击
  void _onMessageTap(_MessageItem msg) {
    debugPrint('点击消息: ${msg.name}');
    // TODO: 导航到具体的聊天页面
  }
}

/// 私信数据模型
class _MessageItem {
  final String? avatarUrl;
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  final bool isOnline;
  final String avatarEmoji;
  
  _MessageItem({
    required this.avatarUrl,
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.avatarEmoji,
  });
}
