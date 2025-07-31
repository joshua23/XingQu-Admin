import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 首页助理页面 - AI助理交互界面
/// 基于原型文件home-assistant.html设计
class HomeAssistantPage extends StatefulWidget {
  const HomeAssistantPage({super.key});

  @override
  State<HomeAssistantPage> createState() => _HomeAssistantPageState();
}

class _HomeAssistantPageState extends State<HomeAssistantPage>
    with TickerProviderStateMixin {
  
  // 动画控制器
  late AnimationController _glowController;
  late AnimationController _pulseController;
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  // 状态控制
  bool _isVoiceMode = true;
  bool _isSpeakerOn = true;
  
  // 系统功能列表
  final List<Map<String, dynamic>> _systemFunctions = [
    {'icon': Icons.lightbulb_outline, 'label': '智能建议', 'highlight': true},
    {'icon': Icons.schedule, 'label': '日程管理', 'highlight': false},
    {'icon': Icons.translate, 'label': '语言翻译', 'highlight': false},
    {'icon': Icons.psychology, 'label': '情感陪伴', 'highlight': false},
    {'icon': Icons.library_books, 'label': '知识问答', 'highlight': false},
    {'icon': Icons.create, 'label': '创意写作', 'highlight': false},
  ];
  
  // 预设问题列表
  final List<String> _presetQuestions = [
    '今天的天气怎么样？',
    '帮我制定一个学习计划',
    '推荐一些放松心情的音乐',
    '讲一个有趣的故事',
    '如何保持健康的生活方式？',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initAnimations() {
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 宇宙背景效果
          _buildCosmicBackground(),
          
          // 主要内容
          Column(
            children: [
              // 导航操作区
              _buildNavActions(),
              
              // 助理信息区
              _buildAssistantProfile(),
              
              // 系统功能区
              _buildSystemFunctions(),
              
              // 主要内容区域
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // 欢迎语区域
                    _buildWelcomeCard(),
                    
                    // 预设问题区
                    _buildPresetQuestions(),
                    
                    // 底部间距
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 底部交互控制区
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInputControls(),
          ),
        ],
      ),
    );
  }

  /// 构建宇宙背景效果
  Widget _buildCosmicBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 径向渐变背景
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, -0.2),
                radius: 1.0,
                colors: [
                  const Color(0xFF6E5CFE).withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4],
              ),
            ),
          ),
          
          // 第二个径向渐变
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, 0.7),
                radius: 0.8,
                colors: [
                  const Color(0xFF38D4FF).withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
          
          // 霓虹光效
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.1,
                right: -50 + (_glowController.value * 20),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6E5CFE).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 第二个霓虹光效
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Positioned(
                bottom: MediaQuery.of(context).size.height * 0.3,
                left: -50 + (_pulseController.value * 15),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38D4FF).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建导航操作区
  Widget _buildNavActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _onHighlightTap(),
                child: Icon(
                  Icons.highlight_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _onMenuTap(),
                child: Icon(
                  Icons.menu,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              GestureDetector(
                onTap: () => _onSearchTap(),
                child: Icon(
                  Icons.search,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _onNotificationTap(),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建助理信息区
  Widget _buildAssistantProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          // 助理头像
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6E5CFE),
                      Color(0xFF38D4FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6E5CFE).withOpacity(0.5 + _glowController.value * 0.3),
                      blurRadius: 15 + _glowController.value * 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '星',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 高光效果
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.3),
                            radius: 0.5,
                            colors: [
                              AppColors.textPrimary.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(width: 16),
          
          // 助理信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.textPrimary,
                      Color(0xFFFFCF6F),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    '星趣AI助理',
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '12.8万关注者',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // 关注按钮
          GestureDetector(
            onTap: () => _onSubscribeTap(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.add,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建系统功能区
  Widget _buildSystemFunctions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _systemFunctions.length,
        itemBuilder: (context, index) {
          final function = _systemFunctions[index];
          final isHighlight = function['highlight'] as bool;
          
          return GestureDetector(
            onTap: () => _onFunctionTap(function['label']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isHighlight
                    ? LinearGradient(
                        colors: [
                          Color(0xFF6E5CFE).withOpacity(0.3),
                          Color(0xFF38D4FF).withOpacity(0.3),
                        ],
                      ).colors.first
                    : AppColors.textSecondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHighlight
                      ? Color(0xFF6E5CFE).withOpacity(0.5)
                      : AppColors.textSecondary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: isHighlight ? [
                  BoxShadow(
                    color: Color(0xFF6E5CFE).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    function['icon'] as IconData,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    function['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
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

  /// 构建欢迎语卡片
  Widget _buildWelcomeCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF141420).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF6E5CFE).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.background.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6E5CFE).withOpacity(0.1),
                    Color(0xFF38D4FF).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '你好！我是星趣AI助理，一个专为你设计的智能伙伴。无论是日常问题、创意灵感，还是情感陪伴，我都在这里为你提供帮助。让我们开始一段有趣的对话吧！',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预设问题区
  Widget _buildPresetQuestions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: _presetQuestions.map((question) {
            return GestureDetector(
              onTap: () => _onQuestionTap(question),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6E5CFE), Color(0xFF38D4FF)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question,
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建底部交互控制区
  Widget _buildInputControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 输入模式切换
                  GestureDetector(
                    onTap: () => _onInputModeToggle(),
                    child: Row(
                      children: [
                        Icon(
                          _isVoiceMode ? Icons.mic : Icons.keyboard,
                          color: AppColors.textSecondary.withOpacity(0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isVoiceMode ? '语音' : '文字',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 中间提示文字
                  Expanded(
                    child: Center(
                      child: Text(
                        _isVoiceMode ? '点击开始语音对话' : '输入你的问题...',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  
                  // 扬声器切换
                  GestureDetector(
                    onTap: () => _onSpeakerToggle(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSpeakerOn
                            ? Color(0xFFFFCF6F).withOpacity(0.2)
                            : AppColors.textSecondary.withOpacity(0.1),
                      ),
                      child: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        color: _isSpeakerOn
                            ? Color(0xFFFFCF6F)
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 事件处理方法
  void _onHighlightTap() {
    // TODO: 实现高亮功能
  }

  void _onMenuTap() {
    // TODO: 实现菜单功能
  }

  void _onSearchTap() {
    Navigator.pushNamed(context, '/search');
  }

  void _onNotificationTap() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _onSubscribeTap() {
    // TODO: 实现关注功能
  }

  void _onFunctionTap(String functionName) {
    // TODO: 实现对应功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$functionName 功能开发中...'),
        backgroundColor: AppColors.highlight,
      ),
    );
  }

  void _onQuestionTap(String question) {
    // TODO: 发送预设问题
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('发送问题: $question'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _onInputModeToggle() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });
  }

  void _onSpeakerToggle() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }
}