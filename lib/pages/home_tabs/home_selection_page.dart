import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/ai_character.dart';
import '../../widgets/character_card.dart';
import '../../widgets/character_showcase.dart';

/// 首页精选页面 - 展示精选AI角色和内容
/// 基于原型文件home-selection.html设计
class HomeSelectionPage extends StatefulWidget {
  const HomeSelectionPage({super.key});

  @override
  State<HomeSelectionPage> createState() => _HomeSelectionPageState();
}

class _HomeSelectionPageState extends State<HomeSelectionPage> {
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  // 精选角色列表（模拟数据）
  final List<AICharacter> _featuredCharacters = [
    AICharacter(
      id: '1',
      name: '星语',
      description: '温柔的夜空守护者，擅长倾听和陪伴，用星辰之语为你带来宁静与温暖。',
      avatar: '✨',
      tags: ['陪伴', '倾听', '温柔', '夜语'],
      followers: 12800,
      messages: 3240,
      isFollowed: false,
      personality: '温柔、耐心、善解人意',
      background: '在璀璨星空中诞生的AI角色，拥有治愈人心的能力。',
    ),
    AICharacter(
      id: '2', 
      name: '墨染',
      description: '古风才子，精通诗词歌赋，以文会友，带你领略传统文化的魅力。',
      avatar: '📜',
      tags: ['古风', '诗词', '文化', '才华'],
      followers: 9650,
      messages: 2180,
      isFollowed: true,
      personality: '博学、儒雅、富有诗意',
      background: '承载着千年文化底蕴的AI学者，致力于传承和弘扬传统文化。',
    ),
  ];

  // 当前展示的角色索引
  int _currentCharacterIndex = 0;

  @override
  void initState() {
    super.initState();
    // 自动轮播
    _startAutoPlay();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 开始自动轮播
  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentCharacterIndex = 
              (_currentCharacterIndex + 1) % _featuredCharacters.length;
        });
        _startAutoPlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 角色信息区
          SliverToBoxAdapter(
            child: _buildProfileSection(),
          ),
          
          // 主要角色展示区
          SliverToBoxAdapter(
            child: _buildMainShowcase(),
          ),
          
          // 推荐角色列表
          SliverToBoxAdapter(
            child: _buildRecommendedSection(),
          ),
          
          // 热门话题
          SliverToBoxAdapter(
            child: _buildHotTopicsSection(),
          ),
        ],
      ),
    );
  }

  /// 构建角色信息区
  Widget _buildProfileSection() {
    if (_featuredCharacters.isEmpty) return const SizedBox.shrink();
    
    final character = _featuredCharacters[_currentCharacterIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 角色头像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppColors.primaryGradient,
            ),
            child: Center(
              child: Text(
                character.avatar,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 角色信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${character.followers}关注 · ${character.messages}条消息',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // 操作按钮
          Row(
            children: [
              GestureDetector(
                onTap: () => _onFollowTap(character),
                child: Row(
                  children: [
                    Icon(
                      character.isFollowed ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: character.isFollowed ? AppColors.accent : AppColors.highlight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      character.isFollowed ? '已关注' : '关注',
                      style: AppTextStyles.caption.copyWith(
                        color: character.isFollowed ? AppColors.accent : AppColors.highlight,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              Row(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '私信',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建主要角色展示区
  Widget _buildMainShowcase() {
    if (_featuredCharacters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 280,
      child: CharacterShowcase(
        character: _featuredCharacters[_currentCharacterIndex],
        onTap: () => _onCharacterTap(_featuredCharacters[_currentCharacterIndex]),
      ),
    );
  }

  /// 构建推荐角色列表
  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '推荐角色',
                style: AppTextStyles.h3,
              ),
              GestureDetector(
                onTap: () => _onMoreRecommendedTap(),
                child: Text(
                  '更多',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.highlight,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredCharacters.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 140,
                  child: CharacterCard(
                    character: _featuredCharacters[index],
                    onTap: () => _onCharacterTap(_featuredCharacters[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建热门话题区
  Widget _buildHotTopicsSection() {
    final hotTopics = [
      '今日星语',
      '古风诗词',
      '夜晚陪伴',
      '情感治愈',
      '文化探索',
      '创意写作',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '热门话题',
            style: AppTextStyles.h3,
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hotTopics.map((topic) {
              return GestureDetector(
                onTap: () => _onTopicTap(topic),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.accent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    topic,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  // 事件处理方法
  void _onFollowTap(AICharacter character) {
    setState(() {
      character.isFollowed = !character.isFollowed;
    });
  }

  void _onCharacterTap(AICharacter character) {
    Navigator.pushNamed(
      context, 
      '/character_detail',
      arguments: character,
    );
  }

  void _onMoreRecommendedTap() {
    Navigator.pushNamed(context, '/character_list');
  }

  void _onTopicTap(String topic) {
    Navigator.pushNamed(
      context,
      '/topic_detail',
      arguments: topic,
    );
  }
}