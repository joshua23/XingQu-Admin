import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';

/// 分享选项数据模型
class ShareOption {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ShareOption({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// 故事分享页面
/// 提供多平台分享、复制链接、分享反馈等功能
class StorySharePage extends StatefulWidget {
  final Story story;

  const StorySharePage({super.key, required this.story});

  @override
  State<StorySharePage> createState() => _StorySharePageState();
}

class _StorySharePageState extends State<StorySharePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // 分享状态
  bool _isSharing = false;
  String _shareMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 启动动画
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: GestureDetector(
        onTap: () => _closeSheet(),
        child: Stack(
          children: [
            // 背景遮罩
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
            // 分享面板
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 400 * _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildSharePanel(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分享面板
  Widget _buildSharePanel() {
    return Container(
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
          _buildHeader(),
          _buildStoryPreview(),
          _buildShareOptions(),
          _buildMoreOptions(),
          _buildCopyLinkButton(),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          const Icon(
            Icons.share,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            '分享故事',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          IconButton(
            onPressed: _closeSheet,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建故事预览
  Widget _buildStoryPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 故事封面
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: AppColors.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          // 故事信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story.title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  '作者：${widget.story.user.nickname}',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.paddingXS),
                    Text(
                      '${widget.story.likeCount}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.paddingXS),
                    Text(
                      '${widget.story.views}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分享选项
  Widget _buildShareOptions() {
    final mainShareOptions = [
      ShareOption(
        id: 'wechat',
        title: '微信',
        icon: Icons.chat,
        color: const Color(0xFF07C160),
        onTap: () => _shareToWechat(),
      ),
      ShareOption(
        id: 'moments',
        title: '朋友圈',
        icon: Icons.group,
        color: const Color(0xFF07C160),
        onTap: () => _shareToMoments(),
      ),
      ShareOption(
        id: 'link',
        title: '复制链接',
        icon: Icons.link,
        color: AppColors.accent,
        onTap: () => _copyLink(),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: mainShareOptions.map((option) {
          return _buildShareOptionItem(option);
        }).toList(),
      ),
    );
  }

  /// 构建更多分享选项
  Widget _buildMoreOptions() {
    final moreOptions = [
      ShareOption(
        id: 'qq',
        title: 'QQ',
        icon: Icons.chat_bubble,
        color: const Color(0xFF12B7F5),
        onTap: () => _shareToQQ(),
      ),
      ShareOption(
        id: 'weibo',
        title: '微博',
        icon: Icons.public,
        color: const Color(0xFFE6162D),
        onTap: () => _shareToWeibo(),
      ),
      ShareOption(
        id: 'douyin',
        title: '抖音',
        icon: Icons.video_library,
        color: const Color(0xFF000000),
        onTap: () => _shareToDouyin(),
      ),
      ShareOption(
        id: 'xiaohongshu',
        title: '小红书',
        icon: Icons.bookmark,
        color: const Color(0xFFFF2442),
        onTap: () => _shareToXiaohongshu(),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        mainAxisSpacing: AppDimensions.paddingM,
        crossAxisSpacing: AppDimensions.paddingM,
        children: moreOptions.map((option) {
          return _buildMoreOptionItem(option);
        }).toList(),
      ),
    );
  }

  /// 构建分享选项项
  Widget _buildShareOptionItem(ShareOption option) {
    return GestureDetector(
      onTap: option.onTap,
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: option.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                option.icon,
                color: option.color,
                size: 28,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              option.title,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建更多选项项
  Widget _buildMoreOptionItem(ShareOption option) {
    return GestureDetector(
      onTap: option.onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: option.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: option.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              option.icon,
              color: option.color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            option.title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建复制链接按钮
  Widget _buildCopyLinkButton() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _copyLink,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link, size: 20),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              '复制链接',
              style: AppTextStyles.button,
            ),
          ],
        ),
      ),
    );
  }

  /// 关闭分享面板
  void _closeSheet() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  /// 分享到微信
  void _shareToWechat() {
    _performShare('微信', () {
      // TODO: 实现微信分享
      debugPrint('分享到微信');
    });
  }

  /// 分享到朋友圈
  void _shareToMoments() {
    _performShare('朋友圈', () {
      // TODO: 实现朋友圈分享
      debugPrint('分享到朋友圈');
    });
  }

  /// 分享到QQ
  void _shareToQQ() {
    _performShare('QQ', () {
      // TODO: 实现QQ分享
      debugPrint('分享到QQ');
    });
  }

  /// 分享到微博
  void _shareToWeibo() {
    _performShare('微博', () {
      // TODO: 实现微博分享
      debugPrint('分享到微博');
    });
  }

  /// 分享到抖音
  void _shareToDouyin() {
    _performShare('抖音', () {
      // TODO: 实现抖音分享
      debugPrint('分享到抖音');
    });
  }

  /// 分享到小红书
  void _shareToXiaohongshu() {
    _performShare('小红书', () {
      // TODO: 实现小红书分享
      debugPrint('分享到小红书');
    });
  }

  /// 复制链接
  void _copyLink() {
    final link = 'https://xinqu.app/story/${widget.story.id}';

    Clipboard.setData(ClipboardData(text: link)).then((_) {
      _showSuccessMessage('链接已复制到剪贴板');
      HapticFeedback.lightImpact();
    });
  }

  /// 执行分享
  void _performShare(String platform, VoidCallback shareAction) {
    setState(() {
      _isSharing = true;
      _shareMessage = '正在分享到$platform...';
    });

    // 模拟分享过程
    Future.delayed(const Duration(milliseconds: 1500), () {
      shareAction();

      if (mounted) {
        setState(() {
          _isSharing = false;
          _shareMessage = '';
        });

        _showSuccessMessage('分享成功');
        HapticFeedback.lightImpact();

        // 延迟关闭面板
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _closeSheet();
          }
        });
      }
    });
  }

  /// 显示成功消息
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: AppDimensions.paddingS),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示分享状态
  Widget _buildShareStatus() {
    if (!_isSharing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            _shareMessage,
            style: AppTextStyles.body2.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

/// 显示分享面板的便捷方法
void showStoryShareSheet(BuildContext context, Story story) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => StorySharePage(story: story),
  );
}
