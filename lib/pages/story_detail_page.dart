import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';
import 'story_share_page.dart';

/// 故事详情页
/// 展示单条故事的完整内容、用户信息、操作等
class StoryDetailPage extends StatefulWidget {
  final Story story;

  const StoryDetailPage({Key? key, required this.story}) : super(key: key);

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  late Story _story;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    // TODO: 从用户偏好或API获取点赞状态
    _isLiked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('故事详情'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _story.user.nickname.isNotEmpty
                          ? _story.user.nickname[0].toUpperCase()
                          : '用',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _story.user.nickname,
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(_story.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 故事标题
            Text(
              _story.title,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 12),
            // 故事配图
            if (_story.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _story.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_story.imageUrl != null) const SizedBox(height: 12),
            // 故事正文
            Text(
              _story.content,
              style: AppTextStyles.body1.copyWith(height: 1.7),
            ),
            const SizedBox(height: 16),
            // 故事标签
            if (_story.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _story.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.accent),
                          ),
                        ))
                    .toList(),
              ),
            if (_story.tags.isNotEmpty) const SizedBox(height: 16),
            // 操作栏
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text('${_story.likeCount}', style: AppTextStyles.body2),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showComments,
                  child: Row(
                    children: [
                      Icon(Icons.comment,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 4),
                      Text('评论', style: AppTextStyles.body2),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showShareSheet,
                  child: Row(
                    children: [
                      Icon(Icons.share,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 4),
                      Text('分享', style: AppTextStyles.body2),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间显示
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  /// 切换点赞状态
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      // 更新点赞数量
      _story = _story.copyWith(
        isLiked: _isLiked,
        likeCount: _isLiked ? _story.likeCount + 1 : _story.likeCount - 1,
      );
    });

    // 触觉反馈
    HapticFeedback.lightImpact();

    // TODO: 调用API更新点赞状态
  }

  /// 显示评论页面
  void _showComments() {
    Navigator.of(context).pushNamed(
      '/story_comment',
      arguments: _story,
    );
  }

  /// 显示分享面板
  void _showShareSheet() {
    showStoryShareSheet(context, _story);
  }

  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusL),
            topRight: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  const Icon(Icons.more_horiz, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    '更多选项',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border,
                  color: AppColors.textSecondary),
              title: Text('收藏', style: AppTextStyles.body1),
              onTap: () {
                Navigator.of(context).pop();
                _bookmarkStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: AppColors.textSecondary),
              title: Text('举报', style: AppTextStyles.body1),
              onTap: () {
                Navigator.of(context).pop();
                _reportStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text('屏蔽作者',
                  style: AppTextStyles.body1.copyWith(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _blockAuthor();
              },
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  /// 收藏故事
  void _bookmarkStory() {
    // TODO: 实现收藏功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已收藏'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 举报故事
  void _reportStory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('举报内容', style: AppTextStyles.h3),
        content: Text('确定要举报这条故事吗？', style: AppTextStyles.body1),
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

  /// 屏蔽作者
  void _blockAuthor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('屏蔽作者', style: AppTextStyles.h3),
        content: Text('确定要屏蔽作者 ${_story.user.nickname} 吗？屏蔽后将不再看到该作者的内容。',
            style: AppTextStyles.body1),
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
              // TODO: 实现屏蔽作者逻辑
            },
            child: Text('屏蔽',
                style: AppTextStyles.button.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
