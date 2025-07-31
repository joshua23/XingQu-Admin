import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/creation_item.dart';

/// 重构后的创作中心页面 - 创作工具和内容管理
/// 基于原型文件creation.html设计
class CreationCenterRefactored extends StatefulWidget {
  const CreationCenterRefactored({super.key});

  @override
  State<CreationCenterRefactored> createState() => _CreationCenterRefactoredState();
}

class _CreationCenterRefactoredState extends State<CreationCenterRefactored> {
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  // 选中的创作模式
  String _selectedMode = 'character';
  
  // 创作模式数据
  final List<Map<String, dynamic>> _creationModes = [
    {
      'id': 'character',
      'title': 'AI角色',
      'desc': '创建专属AI伙伴',
      'icon': '🤖',
    },
    {
      'id': 'story',
      'title': '创意故事',
      'desc': '编写精彩故事',
      'icon': '📖',
    },
    {
      'id': 'audio',
      'title': 'FM电台',
      'desc': '制作音频内容',
      'icon': '🎙️',
    },
    {
      'id': 'game',
      'title': '互动游戏',
      'desc': '设计游戏体验',
      'icon': '🎮',
    },
  ];
  
  // 快速创作工具
  final List<Map<String, dynamic>> _quickTools = [
    {
      'name': 'AI角色生成器',
      'description': '快速创建有趣的AI角色，自定义性格和外观',
      'icon': '🤖',
      'route': '/character_generator',
    },
    {
      'name': '故事大纲助手',
      'description': 'AI帮你构思故事情节，生成创作大纲',
      'icon': '📝',
      'route': '/story_outline',
    },
    {
      'name': '语音合成工具',
      'description': '将文字转换为自然的语音，制作音频内容',
      'icon': '🎵',
      'route': '/voice_synthesis',
    },
    {
      'name': '素材库',
      'description': '丰富的图片、音效、背景素材任你选择',
      'icon': '🎨',
      'route': '/asset_library',
    },
    {
      'name': '协作邀请',
      'description': '邀请朋友一起创作，分享创意灵感',
      'icon': '👥',
      'route': '/collaboration',
    },
  ];
  
  // 最近创作列表
  List<CreationItem> _recentCreations = [];

  @override
  void initState() {
    super.initState();
    _loadRecentCreations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载最近创作
  void _loadRecentCreations() {
    _recentCreations = [
      CreationItem(
        id: '1',
        title: '智能学习助手小智',
        type: 'AI角色',
        status: '已发布',
        thumbnail: '🧠',
        lastModified: DateTime.now().subtract(const Duration(hours: 2)),
        views: 156,
      ),
      CreationItem(
        id: '2',
        title: '星空下的奇幻冒险',
        type: '创意故事',
        status: '草稿',
        thumbnail: '✨',
        lastModified: DateTime.now().subtract(const Duration(days: 1)),
        views: 0,
      ),
      CreationItem(
        id: '3',
        title: '深夜谈心电台',
        type: 'FM电台',
        status: '已发布',
        thumbnail: '🌙',
        lastModified: DateTime.now().subtract(const Duration(days: 3)),
        views: 89,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 顶部导航栏
          _buildNavHeader(),
          
          // 主要内容区域
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 创作模式选择
                _buildCreationModes(),
                
                // 快速创作工具
                _buildQuickTools(),
                
                // 最近创作
                _buildRecentCreations(),
                
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

  /// 构建顶部导航栏
  Widget _buildNavHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // 返回按钮占位
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.accent,
                    size: 16,
                  ),
                ),
              ),
              
              // 标题
              Expanded(
                child: Text(
                  '创作中心',
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 设置按钮
              GestureDetector(
                onTap: () => _onSettingsTap(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: AppColors.accent,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建创作模式选择
  Widget _buildCreationModes() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.create,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '创作模式',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _creationModes.length,
              itemBuilder: (context, index) {
                return _buildModeCard(_creationModes[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模式卡片
  Widget _buildModeCard(Map<String, dynamic> mode) {
    final isSelected = _selectedMode == mode['id'];
    
    return GestureDetector(
      onTap: () => _onModeSelected(mode['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Text(
                mode['icon'],
                style: const TextStyle(fontSize: 28),
              ),
              
              const SizedBox(height: 8),
              
              // 标题
              Text(
                mode['title'],
                style: AppTextStyles.body1.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // 描述
              Text(
                mode['desc'],
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建快速创作工具
  Widget _buildQuickTools() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '快速创作工具',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ...(_quickTools.map((tool) => _buildToolItem(tool))),
          ],
        ),
      ),
    );
  }

  /// 构建工具项
  Widget _buildToolItem(Map<String, dynamic> tool) {
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
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _onToolTap(tool['route']),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              tool['icon'],
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        title: Text(
          tool['name'],
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tool['description'],
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary.withOpacity(0.6),
          size: 16,
        ),
      ),
    );
  }

  /// 构建最近创作
  Widget _buildRecentCreations() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '最近创作',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _onViewAllCreations(),
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
            
            if (_recentCreations.isEmpty)
              _buildEmptyState()
            else
              ...(_recentCreations.map((item) => _buildRecentItem(item))),
          ],
        ),
      ),
    );
  }

  /// 构建最近创作项
  Widget _buildRecentItem(CreationItem item) {
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
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _onCreationTap(item),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              item.thumbnail,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        title: Text(
          item.title,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                item.type,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.background,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (item.views > 0) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.visibility_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 2),
                Text(
                  item.views.toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(
          Icons.more_vert,
          color: AppColors.textSecondary.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.create_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有创作内容',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始你的第一个创作吧！',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _onStartCreating(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '开始创作',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case '已发布':
        return AppColors.success;
      case '草稿':
        return AppColors.warning;
      case '审核中':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  // 事件处理方法
  void _onSettingsTap() {
    Navigator.pushNamed(context, '/creation_settings');
  }

  void _onModeSelected(String modeId) {
    setState(() {
      _selectedMode = modeId;
    });
    // TODO: 根据选择的模式切换内容
  }

  void _onToolTap(String route) {
    Navigator.pushNamed(context, route);
  }

  void _onViewAllCreations() {
    Navigator.pushNamed(context, '/all_creations');
  }

  void _onCreationTap(CreationItem item) {
    Navigator.pushNamed(
      context,
      '/creation_detail',
      arguments: item,
    );
  }

  void _onStartCreating() {
    // 根据当前选中的模式跳转到对应创作页面
    switch (_selectedMode) {
      case 'character':
        Navigator.pushNamed(context, '/character_create');
        break;
      case 'story':
        Navigator.pushNamed(context, '/story_creation');
        break;
      case 'audio':
        Navigator.pushNamed(context, '/audio_creation');
        break;
      case 'game':
        Navigator.pushNamed(context, '/game_creation');
        break;
    }
  }
}