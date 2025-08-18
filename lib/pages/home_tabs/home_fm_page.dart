import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/interaction_menu/universal_interaction_menu.dart';
import '../../widgets/interaction_menu/interaction_menu_config.dart';

/// 首页FM音频页面 - 音频播放和电台功能
/// 基于原型文件home-fm.html设计
class HomeFMPage extends StatefulWidget {
  const HomeFMPage({super.key});

  @override
  State<HomeFMPage> createState() => _HomeFMPageState();
}

class _HomeFMPageState extends State<HomeFMPage> {
  
  // 播放控制
  bool _isPlaying = false;
  double _progress = 0.2;
  
  // 互动状态
  bool _isLiked = false;
  bool _isFavorited = false;
  bool _isFollowing = false;
  bool _showCommentHint = true;
  
  // 互动数据
  int _likeCount = 21000;
  int _favoriteCount = 18000;
  int _commentCount = 856;
  int _shareCount = 0;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景模糊图片
          _buildBackgroundImage(),
          
          // 主要内容
          Column(
            children: [
              // 内容滚动区域
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 封面图片区域
                      _buildAlbumCoverSection(),
                      
                      // 标题与作者信息
                      _buildTitleAuthorSection(),
                      
                      // 互动图标区
                      _buildInteractionBar(),
                    ],
                  ),
                ),
              ),
              
              // 播放控制区
              _buildPlayerControls(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建背景模糊图片
  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建封面图片区域
  Widget _buildAlbumCoverSection() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.6, // 1:1.2 比例
      child: Stack(
        children: [
          // 封面图片
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/image.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // 评论输入提示
          if (_showCommentHint)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildCommentInputHint(),
            ),
        ],
      ),
    );
  }
  
  /// 构建评论输入提示
  Widget _buildCommentInputHint() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '@苏怜芗^: W靠,',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showCommentHint = false;
              });
            },
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标题与作者信息
  Widget _buildTitleAuthorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black.withOpacity(0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 歌曲标题
          const Text(
            'Sweets Parade（节选）',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 作者信息行
          Row(
            children: [
              // 分类标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '脑洞',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 作者名称
              const Text(
                '洛文·阿斯特',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              
              const Spacer(),
              
              // 关注按钮
              GestureDetector(
                onTap: _toggleFollow,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    color: _isFollowing ? Colors.white : Colors.transparent,
                  ),
                  child: Text(
                    _isFollowing ? '已关注' : '关注',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isFollowing ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  /// 构建互动图标区
  Widget _buildInteractionBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: const Border(
          top: BorderSide(
            color: Colors.white12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInteractionItem('🔄', '转发', _shareCount, _onShare),
          _buildInteractionItem('❤️', '81', 81, _onLike),
          _buildInteractionItem('⭐', '79', 79, _onFavorite),
          _buildInteractionItem('💬', '8', 8, _onComment),
          // 添加通用交互菜单触发器
          GestureDetector(
            onTap: () {
              InteractionMenuTrigger.showMenu(
                context: context,
                pageType: PageType.aiInteraction,
                onActionSelected: (InteractionType type) {
                  _handleInteractionAction(type);
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建互动项
  Widget _buildInteractionItem(String icon, String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建播放控制区
  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF443D45),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 互动图标行
          _buildPlayerInteractionIcons(),
          
          const SizedBox(height: 16),
          
          // 进度条
          _buildPlayerProgressSection(),
          
          const SizedBox(height: 20),
          
          // 播放按键
          _buildControlButtons(),
        ],
      ),
    );
  }
  
  /// 构建播放器内互动图标
  Widget _buildPlayerInteractionIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildPlayerInteractionItem(
          _isLiked ? Icons.favorite : Icons.favorite_border,
          _formatCount(_likeCount),
          _isLiked,
          _onPlayerLike,
        ),
        _buildPlayerInteractionItem(
          _isFavorited ? Icons.star : Icons.star_border,
          _formatCount(_favoriteCount),
          _isFavorited,
          _onPlayerFavorite,
        ),
        _buildPlayerInteractionItem(
          Icons.chat_bubble_outline,
          _commentCount.toString(),
          false,
          _onPlayerComment,
        ),
      ],
    );
  }
  
  /// 构建播放器互动项
  Widget _buildPlayerInteractionItem(IconData icon, String count, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive ? Colors.orange.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.orange : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建播放器进度条区域
  Widget _buildPlayerProgressSection() {
    return Column(
      children: [
        // 进度条
        GestureDetector(
          onTapDown: _onProgressTap,
          child: Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: (MediaQuery.of(context).size.width - 40) * _progress - 6,
                  top: -3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 时间显示
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '00:03',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              '00:21',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建播放按键区
  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPlayerControlButton(Icons.repeat, _onRepeat),
        _buildPlayerControlButton(Icons.skip_previous, _onPrevious),
        _buildPlayButton(),
        _buildPlayerControlButton(Icons.skip_next, _onNext),
        _buildPlayerControlButton(Icons.playlist_play, _onPlaylist),
      ],
    );
  }
  
  /// 构建播放器控制按钮
  Widget _buildPlayerControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  /// 构建主播放按钮
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _onPlayPause,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
  
  /// 处理交互动作
  void _handleInteractionAction(InteractionType type) {
    switch (type) {
      case InteractionType.reload:
        debugPrint('🔄 重新加载被点击');
        // 重新加载音频内容
        break;
      case InteractionType.voiceCall:
        debugPrint('📞 语音通话被点击');
        // 启动语音通话功能
        break;
      case InteractionType.image:
        debugPrint('🖼️ 图片被点击');
        // 分享音频图片
        break;
      case InteractionType.camera:
        debugPrint('📸 相机被点击');
        // 拍照分享
        break;
      case InteractionType.gift:
        debugPrint('🎁 礼物被点击');
        // 给作者送礼物
        break;
      case InteractionType.share:
        debugPrint('📱 分享被点击');
        // 分享音频内容
        _onShare();
        break;
      default:
        debugPrint('未知交互类型: $type');
    }
  }

  // 事件处理方法
  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }
  
  void _onShare() {
    setState(() {
      _shareCount++;
    });
  }
  
  void _onLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }
  
  void _onFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }
  
  void _onComment() {
    // 打开评论
  }
  
  void _onPlayerLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }
  
  void _onPlayerFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
      if (_isFavorited) {
        _favoriteCount++;
      } else {
        _favoriteCount--;
      }
    });
  }
  
  void _onPlayerComment() {
    // 打开评论
  }
  
  void _onRepeat() {
    // 切换重复模式
  }
  
  void _onPlaylist() {
    // 显示播放列表
  }
  
  void _onPlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _onPrevious() {
    // 上一曲
  }

  void _onNext() {
    // 下一曲
  }

  void _onProgressTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final tapPosition = details.localPosition.dx / box.size.width;
    setState(() {
      _progress = tapPosition.clamp(0.0, 1.0);
    });
  }

  /// 格式化数字
  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 1000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}