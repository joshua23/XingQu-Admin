import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 消息页（Messages Page）
/// 展示私信列表和通知入口
class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

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
      ),
      _MessageItem(
        avatarUrl: null,
        name: '小明',
        lastMsg: '晚上一起吃饭吗？',
        time: '08:15',
        unread: 0,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 通知入口
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColors.accent),
            title: const Text('系统通知', style: AppTextStyles.body1),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {},
          ),
          const Divider(height: 1, color: AppColors.border),
          // 私信列表
          Expanded(
            child: ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    child: msg.avatarUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.textSecondary)
                        : null,
                  ),
                  title: Text(msg.name, style: AppTextStyles.body1),
                  subtitle: Text(msg.lastMsg, style: AppTextStyles.body2),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(msg.time, style: AppTextStyles.caption),
                      if (msg.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${msg.unread}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white)),
                        ),
                    ],
                  ),
                  onTap: () {
                    // 跳转到聊天详情
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 私信数据模型
class _MessageItem {
  final String? avatarUrl;
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  _MessageItem({
    required this.avatarUrl,
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
  });
}
