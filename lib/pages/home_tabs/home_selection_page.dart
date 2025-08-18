import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/interaction_menu/universal_interaction_menu.dart';
import '../../widgets/interaction_menu/interaction_menu_config.dart';
import '../../widgets/star_animation.dart';
import '../../widgets/comment_bottom_sheet.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';

/// 首页精选页面 - AI角色个性化推荐与互动核心入口
/// 基于星趣App品牌与界面设计规范设计
/// 支持AI动漫形象展示、对话气泡、语音消息、快捷建议、附件上传等多模态交互
class HomeSelectionPage extends StatefulWidget {
  const HomeSelectionPage({super.key});

  @override
  State<HomeSelectionPage> createState() => _HomeSelectionPageState();
}

class _HomeSelectionPageState extends State<HomeSelectionPage> {
  // 功能菜单显示状态
  bool _isMenuVisible = false;
  // 快捷回复显示状态
  bool _isQuickRepliesVisible = false;
  bool _isFunctionMenuVisible = false;
  bool _isKeyboardVisible = false;
  bool _isInteractionMenuVisible = false;
  // 设置面板显示状态
  bool _isSettingsPanelVisible = false;
  
  // 对话设置状态
  bool _continueFeatureEnabled = false;
  bool _fullScreenDialogEnabled = false;
  bool _aiActiveMessageEnabled = true;
  bool _autoPlayVoiceEnabled = false;
  bool _multiTriggerEnabled = true;
  
  // 服务实例
  final SupabaseService _supabaseService = SupabaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  // 交互状态
  bool _isLiked = false;
  bool _isFollowed = false;
  int _likeCount = 21000;
  int _commentCount = 3695;
  String? _characterId; // 寂文泽的角色ID

  // 角色信息
  final Map<String, dynamic> _character = {
    'name': '寂文泽',
    'avatar': '寂',
    'followers': '92.4万',
    'messages': '3695',
    'description': '21岁，有占有欲，霸道，只对你撒娇',
    'tags': ['恋爱', '男友', '占有欲', '霸道'],
    'note': '该角色仅支持文字交流，不支持图片和语音',
  };
  
  @override
  void initState() {
    super.initState();
    _ensureUserAndLoadStatus();
    
    // 记录页面访问埋点
    _trackPageView();
  }
  
  /// 记录页面访问埋点（增强版 - 异步处理不阻塞页面加载）
  Future<void> _trackPageView() async {
    // 异步处理埋点，不阻塞页面初始化
    Future.microtask(() async {
      try {
        await _analyticsService.trackPageView(
          'home_selection_page',
          additionalData: {
            'page_title': '首页-精选',
            'feature_type': 'ai_character_interaction',
            'content_category': 'featured_characters',
            'character_name': _character['name'],
            'load_time': DateTime.now().toIso8601String(),
          },
        );
        print('✅ 页面访问埋点已发送: 首页-精选页');
        
        // 异步检查数据入库情况（不阻塞主流程）
        _checkRecentAnalyticsDataAsync();
        
      } catch (e) {
        print('⚠️ 页面访问埋点失败 (不影响页面加载): $e');
      }
    });
  }
  
  /// 异步检查最近的埋点数据（不阻塞主流程）
  void _checkRecentAnalyticsDataAsync() {
    Future.microtask(() async {
      try {
        final recentData = await _supabaseService.client
            .from('user_analytics')
            .select('event_type, page_name, created_at')
            .order('created_at', ascending: false)
            .limit(5);
        
        print('📊 最近5条埋点数据:');
        for (final record in recentData) {
          print('  ${record['event_type']} - ${record['page_name']} at ${record['created_at']}');
        }
      } catch (e) {
        print('⚠️ 无法查询埋点数据 (不影响功能): $e');
      }
    });
  }
  
  /// 检查最近的埋点数据（保留同步版本用于测试）
  Future<void> _checkRecentAnalyticsData() async {
    try {
      final recentData = await _supabaseService.client
          .from('user_analytics')
          .select('event_type, page_name, created_at')
          .order('created_at', ascending: false)
          .limit(5);
      
      print('📊 最近5条埋点数据:');
      for (final record in recentData) {
        print('  ${record['event_type']} - ${record['page_name']} at ${record['created_at']}');
      }
    } catch (e) {
      print('❌ 无法查询埋点数据: $e');
    }
  }
  
  /// 确保用户已登录并加载状态
  Future<void> _ensureUserAndLoadStatus() async {
    try {
      // 检查是否已登录
      if (_supabaseService.currentUserId == null) {
        // 如果未登录，使用匿名登录
        final response = await _supabaseService.client.auth.signInAnonymously();
        print('✅ Signed in anonymously');
      }
      
      // 确保用户档案存在
      final userId = _supabaseService.currentUserId;
      if (userId != null) {
        await _ensureUserProfileExists(userId);
      }
      
      // 获取角色ID
      await _loadCharacterData();
      
      // 加载交互状态
      await _loadInteractionStatus();
    } catch (e) {
      print('Failed to ensure user: $e');
    }
  }
  
  /// 确保用户档案存在
  Future<void> _ensureUserProfileExists(String userId) async {
    print('🔍 检查用户档案: $userId');
    
    try {
      // 简化逻辑：直接尝试插入，如果存在则忽略错误
      await _supabaseService.client.from('users').upsert({
        'id': userId,
        'phone': '', // 使用空字符串而不是 null
        'nickname': '精选页用户_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      
      print('✅ 用户档案已确保存在: $userId');
      
    } catch (e) {
      print('⚠️  用户档案操作异常（可能正常）: $e');
      
      // 不管成功失败，都继续运行
      // 大多数情况下，即使报错，用户记录也已经存在
    }
    
    // 无论如何都尝试验证用户存在性
    try {
      final userCheck = await _supabaseService.client
          .from('users')
          .select('id')
          .eq('id', userId)
          .limit(1);
      
      if (userCheck.isNotEmpty) {
        print('✅ 验证确认：用户档案存在');
      } else {
        print('❌ 警告：用户档案可能不存在，但继续运行');
      }
    } catch (checkError) {
      print('❌ 无法验证用户档案状态: $checkError');
    }
  }
  
  /// 加载角色数据
  Future<void> _loadCharacterData() async {
    try {
      final characters = await _supabaseService.client
          .from('ai_characters')
          .select('id')
          .eq('name', '寂文泽')
          .limit(1);
      
      if (characters.isNotEmpty) {
        _characterId = characters.first['id'];
        print('✅ Found character ID: $_characterId');
      } else {
        print('❌ Character 寂文泽 not found in database');
      }
    } catch (e) {
      print('Failed to load character data: $e');
    }
  }
  
  /// 加载用户交互状态
  Future<void> _loadInteractionStatus() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null || _characterId == null) return;
      
      // 检查是否已点赞
      final isLiked = await _supabaseService.isLiked(
        userId: userId,
        targetType: 'character',
        targetId: _characterId!,
      );
      
      // 检查是否已关注
      final isFollowed = await _supabaseService.isCharacterFollowed(
        userId: userId,
        characterId: _characterId!,
      );
      
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isFollowed = isFollowed;
        });
      }
    } catch (e) {
      print('Failed to load interaction status: $e');
    }
  }

  // 快捷回复
  final List<String> _quickReplies = [
    '我在图书馆自习呢',
    '今天有事请假了',
    '想我了？',
  ];

  /// 处理汉堡菜单点击事件
  void _onMenuTap() {
    debugPrint('🍔 汉堡菜单被点击');
    _showSettingsPanel();
  }

  /// 处理交互动作
  void _handleInteractionAction(InteractionType type) {
    switch (type) {
      case InteractionType.reload:
        debugPrint('🔄 重新加载被点击');
        // 重新加载对话内容
        break;
      case InteractionType.voiceCall:
        debugPrint('📞 语音通话被点击');
        // 启动语音通话功能
        break;
      case InteractionType.image:
        debugPrint('🖼️ 图片被点击');
        // 打开图片选择器
        break;
      case InteractionType.camera:
        debugPrint('📸 相机被点击');
        // 打开相机功能
        break;
      case InteractionType.gift:
        debugPrint('🎁 礼物被点击');
        // 打开礼物选择
        break;
      case InteractionType.share:
        debugPrint('📱 分享被点击');
        // 分享对话内容
        break;
      default:
        debugPrint('未知交互类型: $type');
    }
  }

  /// 显示抽屉菜单
  void _showDrawerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _buildDrawerMenu();
      },
    );
  }

  /// 构建抽屉菜单
  Widget _buildDrawerMenu() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 抽屉手柄
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 菜单项目
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildDrawerItem(
                  icon: Icons.person,
                  title: '个人资料',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('个人资料被点击');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: '设置',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('设置被点击');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  title: '我的收藏',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('我的收藏被点击');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: '聊天记录',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('聊天记录被点击');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: '帮助与反馈',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('帮助与反馈被点击');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info,
                  title: '关于我们',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('关于我们被点击');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建抽屉菜单项
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarParticleEffect(
        enabled: true,
        child: Column(
          children: [
            // 角色信息区 - 恢复人物昵称和点赞评论订阅
            _buildProfileSection(),

            // 主要内容展示区
            Expanded(
              child: _buildMainShowcase(),
            ),

            // 对话交互区
            _buildConversationArea(),

            // 输入控制区
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  /// 构建角色信息区 - 透明漂浮效果，汉堡图标与角色信息在同一行
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent, // 完全透明
      ),
      child: Row(
        children: [
          // 角色头像 - 使用真实图片缩小版，带星形装饰
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.8),
                              AppColors.accent.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _character['avatar'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 星形装饰
              Positioned(
                top: -2,
                right: -2,
                child: StarAnimation(
                  size: 16,
                  color: Colors.amber,
                  duration: const Duration(seconds: 3),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // 角色信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _character['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_character['followers']}连接者',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // 操作按钮
          Row(
            children: [
              // 点赞按钮
              GestureDetector(
                onTap: _handleLike,
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: _isLiked ? Colors.red : Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(_likeCount),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 关注按钮
              GestureDetector(
                onTap: _handleFollow,
                child: Row(
                  children: [
                    Icon(
                      _isFollowed ? Icons.check : Icons.add,
                      size: 16,
                      color: _isFollowed ? AppColors.primary : Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isFollowed ? '已关注' : '关注',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isFollowed ? AppColors.primary : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 评论按钮
              GestureDetector(
                onTap: _handleComment,
                child: Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(_commentCount),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // 汉堡图标 - 角色信息栏最右侧
          GestureDetector(
            onTap: () {
              _onMenuTap();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.menu,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容展示区 - 纯背景图片区域，移除所有文字内容
  Widget _buildMainShowcase() {
    return Container(
      // 移除内边距，让背景图片完全显示
      child: Stack(
        children: [
          // 背景图片已经通过Stack的Positioned.fill设置
          // 移除所有角色详情覆盖层，让背景图片完全显示
        ],
      ),
    );
  }

  /// 构建对话交互区 - 完全透明
  Widget _buildConversationArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent, // 完全透明
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7), // 半透明黑色背景
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息头部
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _character['name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  '00:32',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 消息内容
            Text(
              '"嘿，我刚下课，你在干嘛呢？今天怎么没看到你？我找了你好久，还以为你不想理我了。"',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建输入控制区 - 完全透明
  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent, // 完全透明
      ),
      child: Column(
        children: [
          // 输入控制栏 - 长条形设计
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800], // 深灰色背景
              borderRadius: BorderRadius.circular(25), // 圆角设计
              border: Border.all(
                color: Colors.grey[600]!, // 浅灰色边框
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 左侧键盘图标
                GestureDetector(
                  onTap: () {
                    debugPrint('⌨️ 键盘按钮被点击');
                    setState(() {
                      _isKeyboardVisible = !_isKeyboardVisible;
                      _isQuickRepliesVisible = false;
                      _isFunctionMenuVisible = false;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.keyboard,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                
                // 中间输入区域
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('🎤 按住说话被点击');
                      // 这里可以添加语音录制逻辑
                    },
                    child: Container(
                      height: 50,
                      child: Center(
                        child: Text(
                          '按住说话',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 右侧灯泡+闪电图标
                GestureDetector(
                  onTap: () {
                    debugPrint('💡 智能建议按钮被点击');
                    setState(() {
                      _isQuickRepliesVisible = !_isQuickRepliesVisible;
                      _isFunctionMenuVisible = false;
                      _isKeyboardVisible = false;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                
                // 右侧加号图标 - 使用新的通用交互菜单
                GestureDetector(
                  onTap: () {
                    debugPrint('➕ 添加按钮被点击');
                    InteractionMenuTrigger.showMenu(
                      context: context,
                      pageType: PageType.aiInteraction,
                      onActionSelected: (InteractionType type) {
                        _handleInteractionAction(type);
                      },
                    );
                  },
                  child: InteractionMenuTrigger.buildPlusButton(
                    onTap: () {
                      InteractionMenuTrigger.showMenu(
                        context: context,
                        pageType: PageType.aiInteraction,
                        onActionSelected: (InteractionType type) {
                          _handleInteractionAction(type);
                        },
                      );
                    },
                    isActive: _isInteractionMenuVisible,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 快捷回复
          if (_isQuickRepliesVisible)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReplies.map((reply) {
                  return GestureDetector(
                    onTap: () {
                      // 处理快捷回复点击
                      debugPrint('💬 快捷回复被点击: $reply');
                      // 这里可以添加发送消息逻辑
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // 半透明黑色背景
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        reply,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          
          // 键盘输入区域
          if (_isKeyboardVisible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '键盘输入区域',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这里可以集成真实的键盘输入功能',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  /// 显示设置面板（增加埋点调试功能）
  void _showSettingsPanel() {
    setState(() {
      _isSettingsPanelVisible = true;
    });
    
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      barrierLabel: 'Settings',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return _buildSettingsPanel(setModalState);
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    ).then((_) {
      setState(() {
        _isSettingsPanelVisible = false;
      });
    });
  }

  /// 构建设置面板
  Widget _buildSettingsPanel(StateSetter setModalState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.85; // 占用屏幕宽度的85%
    
    return Container(
      height: MediaQuery.of(context).size.height,
      width: panelWidth,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 关闭按钮和标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '角色设定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 移除状态栏显示
              
              // 主内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      // 我的对话设置区块
                      _buildMyDialogSettingsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // 对话设置区块
                      _buildDialogSettingsSection(setModalState),
                      
                      const SizedBox(height: 24),
                      
                      // 埋点调试区块
                      _buildAnalyticsDebugSection(setModalState),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// 构建我的对话设置区块
  Widget _buildMyDialogSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '我的对话设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildSettingsListItem(
                title: '称呼',
                subtitle: '智能体对我的称呼',
                onTap: () => debugPrint('称呼设置被点击'),
              ),
              _buildDivider(),
              _buildSettingsListItem(
                title: '性别',
                subtitle: '智能体对我的性别认知',
                onTap: () => debugPrint('性别设置被点击'),
              ),
              _buildDivider(),
              _buildSettingsListItem(
                title: '我是谁',
                subtitle: '智能体对我的身份认知',
                onTap: () => debugPrint('身份设置被点击'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建对话设置区块
  Widget _buildDialogSettingsSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '对话设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 对话模型
              _buildSettingsListItem(
                title: '对话模型',
                subtitle: '角色扮演模型',
                showBadge: true,
                badgeText: 'New',
                onTap: () => debugPrint('对话模型被点击'),
              ),
              _buildDivider(),
              
              // 聊天气泡
              _buildSettingsListItem(
                title: '聊天气泡',
                showRedDot: true,
                onTap: () => debugPrint('聊天气泡被点击'),
              ),
              _buildDivider(),
              
              // 对话背景设置
              _buildSettingsListItem(
                title: '对话背景设置',
                showBadge: true,
                badgeText: 'New',
                onTap: () => debugPrint('对话背景设置被点击'),
              ),
              _buildDivider(),
              
              // 继续说功能开启
              _buildSwitchListItem(
                title: '继续说功能开启',
                value: _continueFeatureEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _continueFeatureEnabled = value;
                  });
                  setState(() {
                    _continueFeatureEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              
              // 始终全屏展示对话
              _buildSwitchListItem(
                title: '始终全屏展示对话',
                value: _fullScreenDialogEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _fullScreenDialogEnabled = value;
                  });
                  setState(() {
                    _fullScreenDialogEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              
              // 智能体主动发消息
              _buildSwitchListItem(
                title: '智能体主动发消息',
                value: _aiActiveMessageEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _aiActiveMessageEnabled = value;
                  });
                  setState(() {
                    _aiActiveMessageEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              
              // 自动播放语音消息
              _buildSwitchListItem(
                title: '自动播放语音消息',
                value: _autoPlayVoiceEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _autoPlayVoiceEnabled = value;
                  });
                  setState(() {
                    _autoPlayVoiceEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              
              // 允许同一时刻多次触发
              _buildSwitchListItem(
                title: '允许同一时刻多次触发',
                value: _multiTriggerEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _multiTriggerEnabled = value;
                  });
                  setState(() {
                    _multiTriggerEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建设置列表项
  Widget _buildSettingsListItem({
    required String title,
    String? subtitle,
    bool showBadge = false,
    String badgeText = '',
    bool showRedDot = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 右侧控件
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBadge) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                if (showRedDot) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.6),
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建开关列表项
  Widget _buildSwitchListItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFC107), // 黄色
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// 构建分隔线
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }
  
  /// 构建埋点调试区块
  Widget _buildAnalyticsDebugSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '埋点调试工具',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 埋点状态
              _buildSettingsListItem(
                title: '埋点服务状态',
                subtitle: '查看当前埋点服务运行状态',
                onTap: () {
                  _showAnalyticsStatus();
                },
              ),
              _buildDivider(),
              
              // 测试连通性
              _buildSettingsListItem(
                title: '测试埋点连通性',
                subtitle: '发送测试埋点验证连接',
                onTap: () {
                  _testAnalyticsConnection();
                },
              ),
              _buildDivider(),
              
              // 查看离线队列
              _buildSettingsListItem(
                title: '离线队列状态',
                subtitle: '查看未上传的埋点数据',
                onTap: () {
                  _showOfflineQueueStatus();
                },
              ),
              _buildDivider(),
              
              // 强制处理队列
              _buildSettingsListItem(
                title: '处理离线队列',
                subtitle: '手动触发离线数据上传',
                onTap: () {
                  _forceProcessOfflineQueue();
                },
              ),
              _buildDivider(),
              
              // 清空队列
              _buildSettingsListItem(
                title: '清空离线队列',
                subtitle: '删除所有未上传数据',
                onTap: () {
                  _clearOfflineQueue();
                },
              ),
              _buildDivider(),
              
              // 查看最近埋点
              _buildSettingsListItem(
                title: '查看最近埋点',
                subtitle: '检查最近5条埋点记录',
                onTap: () {
                  _checkRecentAnalyticsData();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 显示分析服务状态
  void _showAnalyticsStatus() {
    final status = _analyticsService.getServiceStatus();
    final queueStatus = _analyticsService.getOfflineQueueStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text(
          '埋点服务状态',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusItem('服务启用', status['service_enabled'].toString()),
              _buildStatusItem('用户登录', status['user_logged_in'].toString()),
              _buildStatusItem('用户ID', status['current_user_id'] ?? 'null'),
              _buildStatusItem('会话ID', status['session_id'] ?? 'null'),
              _buildStatusItem('设备信息', status['device_info_loaded'].toString()),
              _buildStatusItem('降级机制', status['fallback_enabled'].toString()),
              _buildStatusItem('队列长度', queueStatus['queue_length'].toString()),
              _buildStatusItem('正在处理', queueStatus['is_processing'].toString()),
              _buildStatusItem('服务版本', status['service_version']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// 构建状态显示项
  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 测试埋点连通性
  void _testAnalyticsConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.black,
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在测试连通性...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    
    final success = await _analyticsService.testAnalyticsConnection();
    
    Navigator.of(context).pop(); // 关闭加载对话框
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: Text(
          success ? '连通性测试成功' : '连通性测试失败',
          style: TextStyle(
            color: success ? Colors.green : Colors.red,
          ),
        ),
        content: Text(
          success 
            ? '埋点服务工作正常，数据可以正常上报'
            : '埋点服务连接异常，请检查网络和配置',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// 显示离线队列状态
  void _showOfflineQueueStatus() {
    final queueStatus = _analyticsService.getOfflineQueueStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text(
          '离线队列状态',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusItem('队列长度', queueStatus['queue_length'].toString()),
            _buildStatusItem('正在处理', queueStatus['is_processing'].toString()),
            _buildStatusItem('降级启用', queueStatus['enabled_fallback'].toString()),
            _buildStatusItem('最大重试', queueStatus['max_retry_attempts'].toString()),
            _buildStatusItem('重试延迟', '${queueStatus['retry_delay_ms']}ms'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// 强制处理离线队列
  void _forceProcessOfflineQueue() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.black,
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在处理离线队列...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    
    await _analyticsService.forceProcessOfflineQueue();
    
    Navigator.of(context).pop(); // 关闭加载对话框
    
    _showErrorMessage('离线队列处理完成');
  }
  
  /// 清空离线队列
  void _clearOfflineQueue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text(
          '确认清空队列',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '这将删除所有未上传的埋点数据，此操作不可恢复。确定要继续吗？',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              _analyticsService.clearOfflineQueue();
              Navigator.of(context).pop();
              _showErrorMessage('离线队列已清空');
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  /// 格式化数字显示
  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
  
  /// 处理点赞（增强版 - 埋点失败不影响用户操作）
  Future<void> _handleLike() async {
    final String originalActionType = _isLiked ? 'unlike' : 'like';
    
    try {
      // 1. 先乐观更新UI（即时响应用户操作）
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });
      
      // 2. 确保用户认证（在后台处理）
      await _ensureUserAuthentication();
      
      // 3. 执行核心业务逻辑（点赞/取消点赞）
      await _performLikeOperation();
      
      // 4. 异步记录埋点（不阻塞用户操作，错误不影响主功能）
      _trackLikeAnalyticsAsync(originalActionType);
      
      print('✅ ${_isLiked ? 'Liked' : 'Unliked'} character: $_characterId');
      
    } catch (e) {
      // 业务逻辑失败才回滚UI
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });
      
      print('❌ Like operation failed: $e');
      _showErrorMessage('点赞操作失败，请稍后重试');
    }
  }
  
  /// 确保用户认证
  Future<void> _ensureUserAuthentication() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      // 尝试匿名登录
      await _supabaseService.client.auth.signInAnonymously();
      final newUserId = _supabaseService.currentUserId;
      if (newUserId == null) {
        throw Exception('无法创建用户会话');
      }
      // 确保新用户档案存在
      await _ensureUserProfileExists(newUserId);
    } else {
      // 确保现有用户档案存在
      await _ensureUserProfileExists(userId);
    }
  }
  
  /// 执行点赞操作的核心业务逻辑
  Future<void> _performLikeOperation() async {
    final currentUserId = _supabaseService.currentUserId;
    if (currentUserId == null || _characterId == null) {
      throw Exception('用户ID或角色ID未加载');
    }
    
    await _supabaseService.toggleLike(
      userId: currentUserId,
      targetType: 'character',
      targetId: _characterId!,
      isLiked: _isLiked,
    );
  }
  
  /// 异步记录点赞埋点（不影响主流程）
  void _trackLikeAnalyticsAsync(String actionType) {
    // 在后台异步执行，不等待结果
    Future.microtask(() async {
      try {
        if (_characterId != null) {
          await _analyticsService.trackSocialInteraction(
            actionType: actionType,
            targetType: 'character',
            targetId: _characterId!,
            pageName: 'home_selection_page',
            additionalData: {
              'character_name': _character['name'],
              'source': 'featured_page',
              'like_count': _likeCount,
              'operation_result': 'success',
            },
          );
          print('📊 点赞埋点记录成功: $actionType');
        }
      } catch (e) {
        // 埋点失败不影响用户体验，仅记录日志
        print('⚠️ 点赞埋点记录失败 (不影响功能): $e');
      }
    });
  }
  
  /// 处理关注（增强版 - 埋点失败不影响用户操作）
  Future<void> _handleFollow() async {
    final String originalActionType = _isFollowed ? 'unfollow' : 'follow';
    
    try {
      // 1. 先乐观更新UI（即时响应用户操作）
      setState(() {
        _isFollowed = !_isFollowed;
      });
      
      // 2. 确保用户认证
      await _ensureUserAuthentication();
      
      // 3. 执行核心业务逻辑（关注/取消关注）
      await _performFollowOperation();
      
      // 4. 异步记录埋点（不阻塞用户操作）
      _trackFollowAnalyticsAsync(originalActionType);
      
      print('✅ ${_isFollowed ? 'Followed' : 'Unfollowed'} character: $_characterId');
      
    } catch (e) {
      // 业务逻辑失败才回滚UI
      setState(() {
        _isFollowed = !_isFollowed;
      });
      print('❌ Follow operation failed: $e');
      _showErrorMessage('关注操作失败，请稍后重试');
    }
  }
  
  /// 执行关注操作的核心业务逻辑
  Future<void> _performFollowOperation() async {
    final currentUserId = _supabaseService.currentUserId;
    if (currentUserId == null || _characterId == null) {
      throw Exception('用户ID或角色ID未加载');
    }
    
    await _supabaseService.toggleCharacterFollow(
      userId: currentUserId,
      characterId: _characterId!,
      isFollowing: _isFollowed,
    );
  }
  
  /// 异步记录关注埋点（不影响主流程）
  void _trackFollowAnalyticsAsync(String actionType) {
    Future.microtask(() async {
      try {
        if (_characterId != null) {
          await _analyticsService.trackCharacterInteraction(
            characterId: _characterId!,
            interactionType: actionType,
            pageName: 'home_selection_page',
            additionalData: {
              'character_name': _character['name'],
              'source': 'featured_page',
              'operation_result': 'success',
            },
          );
          print('📊 关注埋点记录成功: $actionType');
        }
      } catch (e) {
        print('⚠️ 关注埋点记录失败 (不影响功能): $e');
      }
    });
  }
  
  /// 处理评论（增强版 - 埋点失败不影响用户操作）
  void _handleComment() {
    if (_characterId == null) {
      print('❌ Character ID not loaded, cannot show comments');
      _showErrorMessage('角色信息未加载，无法显示评论');
      return;
    }
    
    // 显示评论底部弹窗（主功能不依赖埋点）
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        characterId: _characterId!,
        characterName: _character['name'],
        onCommentAdded: () {
          // 1. 先更新UI（即时响应）
          setState(() {
            _commentCount++;
          });
          
          // 2. 异步记录埋点（不阻塞界面）
          _trackCommentAnalyticsAsync();
        },
      ),
    );
  }
  
  /// 异步记录评论埋点（不影响主流程）
  void _trackCommentAnalyticsAsync() {
    Future.microtask(() async {
      try {
        if (_characterId != null) {
          await _analyticsService.trackSocialInteraction(
            actionType: 'comment',
            targetType: 'character',
            targetId: _characterId!,
            pageName: 'home_selection_page',
            additionalData: {
              'character_name': _character['name'],
              'source': 'featured_page',
              'comment_count': _commentCount,
              'operation_result': 'success',
            },
          );
          print('📊 评论埋点记录成功');
        }
      } catch (e) {
        print('⚠️ 评论埋点记录失败 (不影响功能): $e');
      }
    });
  }
  
  /// 显示错误消息
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}
