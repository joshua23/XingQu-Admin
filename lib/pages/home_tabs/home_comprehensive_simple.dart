import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/sprint3_design_tokens.dart' as sprint3;
import '../../services/auth_guard_service.dart';

/// 首页综合页面 - 包含6个子模块的三级Tab导航
/// 根据PRD要求：推荐、订阅、智能体、记忆簿、双语、挑战
class HomeComprehensivePageSimple extends StatefulWidget {
  const HomeComprehensivePageSimple({super.key});

  @override
  State<HomeComprehensivePageSimple> createState() => _HomeComprehensivePageSimpleState();
}

class _HomeComprehensivePageSimpleState extends State<HomeComprehensivePageSimple>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 1; // 默认显示"推荐"页面

  // 6个子模块标题 - 调整顺序，订阅在推荐左侧
  final List<String> _tabTitles = ['订阅', '推荐', '智能体', '记忆簿', '双语', '挑战'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: 1, // 默认显示"推荐"页面
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // 使用应用统一的深色背景
      child: Column(
        children: [
          // 三级Tab导航栏
          _buildTabBar(),
          // Tab内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabTitles.map((title) => _buildTabContent(title)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Tab导航栏 - 与首页风格保持一致
  Widget _buildTabBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent, // 透明背景
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: _tabTitles.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            final isActive = _currentTabIndex == index;
            
            return GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: sprint3.AppTextStyles.tabText.copyWith(
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: sprint3.AppSpacing.xs),
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: sprint3.AppColors.goldGradient, // 使用设计令牌中的渐变
                        borderRadius: BorderRadius.circular(2),
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

  /// 构建Tab内容页面
  Widget _buildTabContent(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 网格布局的AI角色卡片 - 移除页面标题，让界面更简洁
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: 8, // 示例显示8个卡片
              itemBuilder: (context, index) => _buildAIRoleCard(title, index),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建AI角色卡片 - 深色主题风格
  Widget _buildAIRoleCard(String category, int index) {
    return GestureDetector(
      onTap: () {
        // 根据分类确定需要的权限
        String action = _getActionForCategory(category);
        
        // 使用认证守卫检查权限
        context.checkAuth(action, () {
          debugPrint('🎭 点击了$category角色${index + 1}');
          // 这里可以导航到角色详情页或执行相应操作
          _handleRoleCardTap(category, index);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: sprint3.AppColors.surfaceColor, // 使用Sprint3设计令牌
          borderRadius: sprint3.AppRadius.cardRadius,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2), // 金色边框
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 角色头像区域
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Icon(
                  _getIconForCategory(category),
                  size: 48,
                  color: AppColors.primary, // 金色图标
                ),
              ),
            ),
            // 角色信息区域
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$category角色${index + 1}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(index + 1) * 1.2}万连接者',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据分类返回对应图标
  IconData _getIconForCategory(String category) {
    switch (category) {
      case '推荐':
        return Icons.recommend;
      case '订阅':
        return Icons.subscriptions;
      case '智能体':
        return Icons.smart_toy;
      case '记忆簿':
        return Icons.auto_stories;
      case '双语':
        return Icons.translate;
      case '挑战':
        return Icons.emoji_events;
      default:
        return Icons.apps;
    }
  }

  /// 根据分类确定需要的权限操作
  String _getActionForCategory(String category) {
    switch (category) {
      case '订阅':
        return 'subscribe'; // 订阅需要登录
      case '推荐':
        return 'view'; // 推荐可以游客浏览
      case '智能体':
        return 'view'; // 智能体可以游客浏览
      case '记忆簿':
        return 'view'; // 记忆簿可以游客浏览
      case '双语':
        return 'view'; // 双语可以游客浏览
      case '挑战':
        return 'view'; // 挑战可以游客浏览
      default:
        return 'view';
    }
  }

  /// 处理角色卡片点击
  void _handleRoleCardTap(String category, int index) {
    // 这里可以根据不同分类导航到不同页面
    switch (category) {
      case '订阅':
        // 导航到订阅管理页面
        debugPrint('📋 导航到订阅管理页面');
        break;
      case '推荐':
        // 导航到推荐详情页面
        debugPrint('🎯 导航到推荐详情页面');
        break;
      case '智能体':
        // 导航到智能体详情页面
        debugPrint('🤖 导航到智能体详情页面');
        // Navigator.of(context).pushNamed('/character/detail', arguments: 'character_${index + 1}');
        break;
      case '记忆簿':
        // 导航到记忆簿页面
        debugPrint('📖 导航到记忆簿页面');
        break;
      case '双语':
        // 导航到双语学习页面
        debugPrint('🌐 导航到双语学习页面');
        break;
      case '挑战':
        // 导航到挑战页面
        debugPrint('🏆 导航到挑战页面');
        break;
      default:
        debugPrint('❓ 未知分类: $category');
    }
  }
}