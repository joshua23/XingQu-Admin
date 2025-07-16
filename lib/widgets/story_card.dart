import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';

/// 故事卡片组件
/// 用于在首页显示故事内容的卡片
class StoryCard extends StatefulWidget {
  /// 故事数据
  final Story story;

  /// 点赞回调函数
  final VoidCallback? onLike;

  /// 评论回调函数
  final VoidCallback? onComment;

  /// 分享回调函数
  final VoidCallback? onShare;

  /// 关注回调函数
  final VoidCallback? onFollow;

  const StoryCard({
    super.key,
    required this.story,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onFollow,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with SingleTickerProviderStateMixin {
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画
  /// 配置点赞时的缩放动画
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 故事卡片整体可点击，跳转到详情页
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .pushNamed('/story_detail', arguments: widget.story);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 故事头部（用户信息）
            _buildStoryHeader(),
            // 故事内容
            _buildStoryContent(),
            // 故事操作栏
            _buildStoryActions(),
          ],
        ),
      ),
    );
  }

  /// 构建故事头部
  /// 包含用户头像、用户名、发布时间和关注按钮
  Widget _buildStoryHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          // 用户头像
          _buildUserAvatar(),

          const SizedBox(width: 12),

          // 用户信息
          Expanded(
            child: _buildUserInfo(),
          ),

          // 关注按钮
          _buildFollowButton(),
        ],
      ),
    );
  }

  /// 构建用户头像
  /// 圆形头像，支持网络图片或默认字母头像
  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
        ),
      ),
      child: widget.story.user.avatarUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: widget.story.user.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildAvatarPlaceholder(),
                errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
              ),
            )
          : _buildAvatarPlaceholder(),
    );
  }

  /// 构建头像占位符
  /// 显示用户名的第一个字符
  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        widget.story.user.nickname.isNotEmpty
            ? widget.story.user.nickname[0].toUpperCase()
            : '用',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.background,
        ),
      ),
    );
  }

  /// 构建用户信息
  /// 显示用户名和发布时间
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 用户名
        Text(
          widget.story.user.nickname,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 2),

        // 发布时间
        Text(
          _formatTime(widget.story.createdAt),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  /// 构建关注按钮
  /// 显示关注或已关注状态
  Widget _buildFollowButton() {
    final bool isFollowed = widget.story.user.isFollowed;
    // 极简风格：未关注为logo色线框按钮，已关注为灰色线框
    return IntrinsicWidth(
      child: SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: widget.onFollow,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isFollowed ? AppColors.textSecondary : AppColors.primary,
              width: 1.5,
            ),
            backgroundColor:
                isFollowed ? Colors.transparent : Colors.transparent,
            foregroundColor:
                isFollowed ? AppColors.textSecondary : AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            isFollowed ? '已关注' : '关注',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: isFollowed ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建故事内容
  /// 包含标题、正文、图片和标签
  Widget _buildStoryContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 故事标题
          if (widget.story.title.isNotEmpty) _buildStoryTitle(),

          // 故事正文
          _buildStoryText(),

          // 故事图片
          if (widget.story.imageUrl != null) _buildStoryImage(),

          // 故事标签
          if (widget.story.tags.isNotEmpty) _buildStoryTags(),
        ],
      ),
    );
  }

  /// 构建故事标题
  /// 显示故事的主标题
  Widget _buildStoryTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        widget.story.title,
        style: AppTextStyles.h3.copyWith(
          fontSize: 18,
        ),
      ),
    );
  }

  /// 构建故事正文
  /// 显示故事的主要内容文本
  Widget _buildStoryText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        widget.story.content,
        style: AppTextStyles.body1.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建故事图片
  /// 显示故事配图，支持网络图片
  Widget _buildStoryImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: widget.story.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceVariant,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: AppColors.textHint,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建故事标签
  /// 显示故事相关的标签列表
  Widget _buildStoryTags() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.story.tags.map((tag) => _buildTag(tag)).toList(),
      ),
    );
  }

  /// 构建单个标签
  /// [tag] 标签文本
  /// 返回标签组件
  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.secondary,
        ),
      ),
    );
  }

  /// 构建故事操作栏
  /// 包含点赞、评论、分享等操作按钮
  Widget _buildStoryActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // 点赞按钮
          _buildActionButton(
            icon: widget.story.isLiked
                ? FontAwesomeIcons.solidHeart
                : FontAwesomeIcons.heart,
            count: widget.story.likeCount.toString(),
            isActive: widget.story.isLiked,
            onTap: _handleLike,
          ),

          const SizedBox(width: 20),

          // 评论按钮
          _buildActionButton(
            icon: FontAwesomeIcons.comment,
            count: widget.story.commentCount.toString(),
            onTap: widget.onComment,
          ),

          const SizedBox(width: 20),

          // 分享按钮
          _buildActionButton(
            icon: FontAwesomeIcons.share,
            text: '分享',
            onTap: widget.onShare,
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  /// [icon] 图标
  /// [count] 数量文本
  /// [text] 文本
  /// [isActive] 是否激活状态
  /// [onTap] 点击回调
  /// 返回操作按钮组件
  Widget _buildActionButton({
    required IconData icon,
    String? count,
    String? text,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          ScaleTransition(
            scale: _scaleAnimation,
            child: FaIcon(
              icon,
              size: 16,
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 6),

          // 文本或数量
          Text(
            count ?? text ?? '',
            style: AppTextStyles.body2.copyWith(
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 处理点赞操作
  /// 包含点赞动画效果
  void _handleLike() {
    // 播放动画
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // 调用点赞回调
    widget.onLike?.call();
  }

  /// 格式化时间显示
  /// [dateTime] 日期时间
  /// 返回格式化后的时间字符串
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
}
