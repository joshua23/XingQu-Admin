import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';

/// 评论数据模型
class Comment {
  final String id;
  final String content;
  final String author;
  final DateTime publishTime;
  final int likes;
  final bool isLiked;
  final String? replyTo;
  final List<Comment> replies;
  final String? avatarUrl;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.publishTime,
    this.likes = 0,
    this.isLiked = false,
    this.replyTo,
    this.replies = const [],
    this.avatarUrl,
  });

  /// 创建副本
  Comment copyWith({
    String? id,
    String? content,
    String? author,
    DateTime? publishTime,
    int? likes,
    bool? isLiked,
    String? replyTo,
    List<Comment>? replies,
    String? avatarUrl,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      publishTime: publishTime ?? this.publishTime,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      replyTo: replyTo ?? this.replyTo,
      replies: replies ?? this.replies,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// 故事评论页面
/// 提供评论列表、互动回复、长按菜单、评论发布等功能
class StoryCommentPage extends StatefulWidget {
  final Story story;

  const StoryCommentPage({super.key, required this.story});

  @override
  State<StoryCommentPage> createState() => _StoryCommentPageState();
}

class _StoryCommentPageState extends State<StoryCommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // 评论列表
  List<Comment> _comments = [];

  // 回复状态
  Comment? _replyingTo;

  // 输入框状态
  bool _isCommentEmpty = true;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onCommentChanged);
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 评论内容变化监听
  void _onCommentChanged() {
    setState(() {
      _isCommentEmpty = _commentController.text.trim().isEmpty;
    });
  }

  /// 加载评论数据
  void _loadComments() {
    // 模拟加载评论数据
    setState(() {
      _comments = _getMockComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildCommentList()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '评论 (${_comments.length})',
        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
      ),
      centerTitle: true,
    );
  }

  /// 构建评论列表
  Widget _buildCommentList() {
    if (_comments.isEmpty) {
      return _buildEmptyComments();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  /// 构建空评论状态
  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '暂无评论',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            '快来发表第一条评论吧',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  /// 构建评论项
  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(comment),
          const SizedBox(height: AppDimensions.paddingS),
          _buildCommentContent(comment),
          const SizedBox(height: AppDimensions.paddingS),
          _buildCommentActions(comment),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingM),
            _buildReplies(comment.replies),
          ],
        ],
      ),
    );
  }

  /// 构建评论头部
  Widget _buildCommentHeader(Comment comment) {
    return Row(
      children: [
        _buildAvatar(comment.author),
        const SizedBox(width: AppDimensions.paddingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.author,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _formatTime(comment.publishTime),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          color: AppColors.surface,
          onSelected: (value) => _onCommentMenuSelected(value, comment),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'reply',
              child: Row(
                children: [
                  const Icon(Icons.reply, color: AppColors.textSecondary),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text('回复', style: AppTextStyles.body1),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.flag, color: AppColors.textSecondary),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text('举报', style: AppTextStyles.body1),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text('删除',
                      style: AppTextStyles.body1.copyWith(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建用户头像
  Widget _buildAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建评论内容
  Widget _buildCommentContent(Comment comment) {
    return Text(
      comment.content,
      style: AppTextStyles.body1,
    );
  }

  /// 构建评论操作
  Widget _buildCommentActions(Comment comment) {
    return Row(
      children: [
        _buildActionButton(
          icon: comment.isLiked ? Icons.favorite : Icons.favorite_border,
          text: '${comment.likes}',
          color: comment.isLiked ? AppColors.accent : AppColors.textSecondary,
          onTap: () => _toggleLike(comment),
        ),
        const SizedBox(width: AppDimensions.paddingL),
        _buildActionButton(
          icon: Icons.reply,
          text: '回复',
          color: AppColors.textSecondary,
          onTap: () => _startReply(comment),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppDimensions.paddingXS),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// 构建回复列表
  Widget _buildReplies(List<Comment> replies) {
    return Container(
      margin: const EdgeInsets.only(left: AppDimensions.paddingL),
      child: Column(
        children: replies.map((reply) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(reply.author),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.body2,
                              children: [
                                TextSpan(
                                  text: reply.author,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (reply.replyTo != null) ...[
                                  const TextSpan(text: ' 回复 '),
                                  TextSpan(
                                    text: reply.replyTo!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            _formatTime(reply.publishTime),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  reply.content,
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                _buildCommentActions(reply),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建评论输入框
  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingM,
        right: AppDimensions.paddingM,
        top: AppDimensions.paddingM,
        bottom:
            AppDimensions.paddingM + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingTo != null) _buildReplyHeader(),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    style: AppTextStyles.body1,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? '回复 ${_replyingTo!.author}'
                          : '发表你的看法...',
                      hintStyle: AppTextStyles.body2,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.all(AppDimensions.paddingM),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建回复头部
  Widget _buildReplyHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              '回复 ${_replyingTo!.author}',
              style: AppTextStyles.caption.copyWith(color: AppColors.accent),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: const Icon(Icons.close,
                size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _isCommentEmpty ? AppColors.surface : AppColors.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        onPressed: _isCommentEmpty ? null : _sendComment,
        icon: Icon(
          Icons.send,
          color: _isCommentEmpty ? AppColors.textSecondary : Colors.white,
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}月${time.day}日';
    }
  }

  /// 评论菜单选择
  void _onCommentMenuSelected(String value, Comment comment) {
    switch (value) {
      case 'reply':
        _startReply(comment);
        break;
      case 'report':
        _reportComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
    }
  }

  /// 切换点赞状态
  void _toggleLike(Comment comment) {
    setState(() {
      final index = _comments.indexOf(comment);
      if (index >= 0) {
        _comments[index] = comment.copyWith(
          isLiked: !comment.isLiked,
          likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
        );
      }
    });

    // 触觉反馈
    HapticFeedback.lightImpact();
  }

  /// 开始回复
  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    _focusNode.requestFocus();
  }

  /// 取消回复
  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
    _focusNode.unfocus();
  }

  /// 发送评论
  void _sendComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      author: '当前用户',
      publishTime: DateTime.now(),
      replyTo: _replyingTo?.author,
    );

    setState(() {
      if (_replyingTo != null) {
        // 添加回复
        final parentIndex = _comments.indexOf(_replyingTo!);
        if (parentIndex >= 0) {
          final updatedReplies =
              List<Comment>.from(_comments[parentIndex].replies)
                ..add(newComment);
          _comments[parentIndex] =
              _comments[parentIndex].copyWith(replies: updatedReplies);
        }
      } else {
        // 添加新评论
        _comments.insert(0, newComment);
      }

      _replyingTo = null;
    });

    _commentController.clear();
    _focusNode.unfocus();

    // 触觉反馈
    HapticFeedback.lightImpact();
  }

  /// 举报评论
  void _reportComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('举报评论', style: AppTextStyles.h3),
        content: Text('确定要举报这条评论吗？', style: AppTextStyles.body1),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现举报逻辑
            },
            child: Text('举报',
                style: AppTextStyles.button.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  /// 删除评论
  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('删除评论', style: AppTextStyles.h3),
        content: Text('确定要删除这条评论吗？', style: AppTextStyles.body1),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _comments.remove(comment);
              });
            },
            child: Text('删除',
                style: AppTextStyles.button.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 获取模拟评论数据
  List<Comment> _getMockComments() {
    return [
      Comment(
        id: '1',
        content: '这个故事写得真好，情节紧凑，人物刻画生动，让人欲罢不能！',
        author: '科幻迷',
        publishTime: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 15,
        isLiked: false,
        replies: [
          Comment(
            id: '1-1',
            content: '我也觉得，特别是主角的成长过程描写得很棒',
            author: '小说爱好者',
            publishTime: DateTime.now().subtract(const Duration(hours: 1)),
            likes: 3,
            replyTo: '科幻迷',
          ),
          Comment(
            id: '1-2',
            content: '同感，作者的想象力真的很丰富',
            author: '读者A',
            publishTime: DateTime.now().subtract(const Duration(minutes: 30)),
            likes: 1,
            replyTo: '科幻迷',
          ),
        ],
      ),
      Comment(
        id: '2',
        content: '期待后续章节，希望作者能保持更新频率',
        author: '忠实读者',
        publishTime: DateTime.now().subtract(const Duration(hours: 4)),
        likes: 8,
        isLiked: true,
      ),
      Comment(
        id: '3',
        content: '世界观设定很有新意，不过某些地方的逻辑还可以再完善一下',
        author: '文学青年',
        publishTime: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 12,
        isLiked: false,
      ),
    ];
  }
}
