import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/audio_content.dart';
import '../../widgets/audio_player_widget.dart';
import '../../widgets/channel_card.dart';

/// 首页FM音频页面 - 音频播放和电台功能
/// 基于原型文件home-fm.html设计
class HomeFMPage extends StatefulWidget {
  const HomeFMPage({super.key});

  @override
  State<HomeFMPage> createState() => _HomeFMPageState();
}

class _HomeFMPageState extends State<HomeFMPage>
    with TickerProviderStateMixin {
  
  // 播放控制
  bool _isPlaying = false;
  double _progress = 0.3;
  AudioContent? _currentAudio;
  
  // 动画控制器
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  // 模拟数据
  List<AudioContent> _channels = [];
  List<AudioContent> _recentPlayed = [];
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadMockData();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (_isPlaying) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  /// 加载模拟数据
  void _loadMockData() {
    _channels = [
      AudioContent(
        id: '1',
        title: '星空夜语',
        artist: '星语电台',
        album: '深夜电台',
        cover: '🌙',
        duration: Duration(minutes: 45),
        category: '深夜电台',
        description: '温柔的夜晚陪伴，用星空的语言治愈你的心灵',
      ),
      AudioContent(
        id: '2',
        title: '古风雅韵',
        artist: '墨染FM',
        album: '古典音乐',
        cover: '🎵',
        duration: Duration(minutes: 32),
        category: '古典音乐',
        description: '传统文化的音乐之旅，感受古典雅韵的魅力',
      ),
      AudioContent(
        id: '3',
        title: '知识电台',
        artist: '智慧之声',
        album: '教育频道',
        cover: '📚',
        duration: Duration(minutes: 28),
        category: '教育学习',
        description: '每日一课，用知识充实你的每一天',
      ),
      AudioContent(
        id: '4',
        title: '冥想时光',
        artist: '静心电台',
        album: '放松音乐',
        cover: '🧘',
        duration: Duration(minutes: 60),
        category: '冥想放松',
        description: '引导式冥想，找回内心的宁静与平衡',
      ),
    ];
    
    _recentPlayed = _channels.take(3).toList();
    
    // 设置当前播放
    if (_channels.isNotEmpty) {
      _currentAudio = _channels.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 当前播放区域
          _buildNowPlayingSection(),
          
          // 主要内容区域
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 频道列表
                _buildChannelsSection(),
                
                // 最近播放
                _buildRecentPlayedSection(),
                
                // 底部间距
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建当前播放区域
  Widget _buildNowPlayingSection() {
    if (_currentAudio == null) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 专辑封面
            _buildAlbumCover(),
            
            const SizedBox(height: 20),
            
            // 歌曲信息
            _buildSongInfo(),
            
            const SizedBox(height: 20),
            
            // 进度条
            _buildProgressSection(),
            
            const SizedBox(height: 20),
            
            // 播放控制
            _buildPlaybackControls(),
            
            const SizedBox(height: 24),
            
            // 统计数据
            _buildStatsArea(),
          ],
        ),
      ),
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumCover() {
    return Center(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      _currentAudio!.cover,
                      style: const TextStyle(
                        fontSize: 48,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                  // 中心圆点
                  Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建歌曲信息
  Widget _buildSongInfo() {
    return Column(
      children: [
        Text(
          _currentAudio!.title,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _currentAudio!.artist,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _currentAudio!.album,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.accent,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建进度条区域
  Widget _buildProgressSection() {
    return Column(
      children: [
        // 进度条
        GestureDetector(
          onTapDown: (details) => _onProgressTap(details),
          child: Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 时间显示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(
                Duration(
                  milliseconds: (_currentAudio!.duration.inMilliseconds * _progress).round(),
                ),
              ),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _formatDuration(_currentAudio!.duration),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建播放控制
  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: _onPrevious,
        ),
        
        const SizedBox(width: 24),
        
        // 主播放按钮
        GestureDetector(
          onTap: _onPlayPause,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? 1.0 + (_pulseController.value * 0.05) : 1.0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.background,
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(width: 24),
        
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: _onNext,
        ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  /// 构建统计数据区域
  Widget _buildStatsArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('1.2k', '收听'),
        _buildStatItem('89', '喜欢'),
        _buildStatItem('45', '分享'),
        _buildStatItem('12', '评论'),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String value, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建频道列表区域
  Widget _buildChannelsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '热门频道',
                  style: AppTextStyles.h3,
                ),
                GestureDetector(
                  onTap: () => _onViewAllChannels(),
                  child: Text(
                    '查看全部',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 频道网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                return ChannelCard(
                  audio: _channels[index],
                  isActive: _currentAudio?.id == _channels[index].id,
                  onTap: () => _onChannelSelected(_channels[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建最近播放区域
  Widget _buildRecentPlayedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近播放',
              style: AppTextStyles.h3,
            ),
            
            const SizedBox(height: 16),
            
            // 最近播放列表
            ...(_recentPlayed.map((audio) => _buildRecentItem(audio))),
          ],
        ),
      ),
    );
  }

  /// 构建最近播放项
  Widget _buildRecentItem(AudioContent audio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: AppColors.primaryGradient,
          ),
          child: Center(
            child: Text(
              audio.cover,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        title: Text(
          audio.title,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          audio.artist,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          _formatDuration(audio.duration),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        onTap: () => _onChannelSelected(audio),
      ),
    );
  }

  // 事件处理方法
  void _onPlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _pulseController.stop();
    }
  }

  void _onPrevious() {
    if (_currentAudio != null) {
      final currentIndex = _channels.indexOf(_currentAudio!);
      if (currentIndex > 0) {
        setState(() {
          _currentAudio = _channels[currentIndex - 1];
          _progress = 0.0;
        });
      }
    }
  }

  void _onNext() {
    if (_currentAudio != null) {
      final currentIndex = _channels.indexOf(_currentAudio!);
      if (currentIndex < _channels.length - 1) {
        setState(() {
          _currentAudio = _channels[currentIndex + 1];
          _progress = 0.0;
        });
      }
    }
  }

  void _onProgressTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final tapPosition = details.localPosition.dx / box.size.width;
    setState(() {
      _progress = tapPosition.clamp(0.0, 1.0);
    });
  }

  void _onChannelSelected(AudioContent audio) {
    setState(() {
      _currentAudio = audio;
      _progress = 0.0;
      _isPlaying = true;
    });
    
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _onViewAllChannels() {
    Navigator.pushNamed(context, '/channels_list');
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}