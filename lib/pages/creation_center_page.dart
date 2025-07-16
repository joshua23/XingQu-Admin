import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// 创作中心页面
/// 提供故事创作、角色管理、模板使用等创作相关功能入口
class CreationCenterPage extends StatefulWidget {
  const CreationCenterPage({super.key});

  @override
  State<CreationCenterPage> createState() => _CreationCenterPageState();
}

/// 创作中心页面状态类
/// 管理页面状态、用户交互和数据加载
class _CreationCenterPageState extends State<CreationCenterPage>
    with SingleTickerProviderStateMixin {
  // 认证服务实例
  final AuthService _authService = AuthService();

  // 动画控制器，用于实现星形图标动画效果
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 配置旋转动画（0-45度）
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.125, // 45度转换为弧度比例 (45/360)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 配置缩放动画（1.0-1.1倍）
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 启动循环动画
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 100, // 为悬浮按钮预留空间
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 快速创作入口区域
                    _buildQuickCreationSection(),

                    const SizedBox(height: AppDimensions.paddingS),

                    // 创作助手区域
                    _buildCreationGuideSection(),

                    const SizedBox(height: AppDimensions.paddingS),

                    // 创作工具区域
                    _buildCreationToolsSection(),

                    // 底部安全区域padding
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // 悬浮操作按钮
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// 构建应用栏
  /// 使用标准 AppBar 避免自定义布局溢出
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 56, // 标准高度，保证足够空间
      leadingWidth: 44,
      leading: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.primary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // 星形动画图标
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: const Text(
                    '✦',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          // 标题与副标题
          Expanded(
            child: Row(
              children: [
                Text(
                  '创作中心',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '发挥创意，创造属于你的故事世界',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快速创作区域
  /// 包含创建新故事、创建角色、使用模板三个主要入口
  Widget _buildQuickCreationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速开始',
          style: AppTextStyles.h3,
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // 创作卡片列表 - 使用Column替代GridView以更好控制高度
        Column(
          children: [
            _buildCreationCard(
              icon: '📝',
              title: '创建新故事',
              description: '从零开始创作你的故事',
              borderColor: AppColors.accent,
              iconColor: AppColors.accent,
              onTap: _createNewStory,
            ),
            const SizedBox(height: 6), // 进一步减少间距
            _buildCreationCard(
              icon: '👤',
              title: '创建角色',
              description: '设计你的故事角色',
              borderColor: AppColors.secondary,
              iconColor: AppColors.secondary,
              onTap: _createCharacter,
            ),
            const SizedBox(height: 6), // 进一步减少间距
            _buildCreationCard(
              icon: '📋',
              title: '使用模版',
              description: '基于现有模版快速创作',
              borderColor: AppColors.success,
              iconColor: AppColors.success,
              onTap: _useTemplate,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建创作助手区域
  /// 包含故事创作指南和创作公约链接
  Widget _buildCreationGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '创作助手',
          style: AppTextStyles.h3,
        ),

        const SizedBox(height: AppDimensions.paddingS), // 减少间距

        // 创作指南链接
        Wrap(
          spacing: AppDimensions.paddingS, // 减少水平间距
          runSpacing: 6, // 减少垂直间距
          children: [
            _buildGuideLink(
              icon: '📖',
              label: '故事创作指南',
              color: AppColors.secondary,
              onTap: _openCreationGuide,
            ),
            _buildGuideLink(
              icon: '📜',
              label: '创作公约',
              color: AppColors.accent,
              onTap: _openCreationRules,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建创作工具区域
  /// 包含图片编辑、文本编辑、角色编辑、名称生成等工具
  Widget _buildCreationToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '创作工具',
          style: AppTextStyles.h3,
        ),

        const SizedBox(height: AppDimensions.paddingS), // 减少间距

        // 工具网格
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2, // 更大的宽高比，让卡片更扁平
          crossAxisSpacing: AppDimensions.paddingS,
          mainAxisSpacing: 6, // 进一步减少垂直间距
          children: [
            _buildToolCard(
              icon: '🖼️',
              title: '图片编辑',
              color: AppColors.warning,
              onTap: _openImageEditor,
            ),
            _buildToolCard(
              icon: '📝',
              title: '文本编辑',
              color: AppColors.secondary,
              onTap: _openTextEditor,
            ),
            _buildToolCard(
              icon: '👤',
              title: '角色编辑',
              color: AppColors.accent,
              onTap: _openCharacterEditor,
            ),
            _buildToolCard(
              icon: '🎲',
              title: '名称生成',
              color: AppColors.success,
              onTap: _openNameGenerator,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建创作卡片组件
  /// [icon] 卡片图标
  /// [title] 卡片标题
  /// [description] 卡片描述
  /// [borderColor] 边框颜色
  /// [iconColor] 图标颜色
  /// [onTap] 点击回调
  Widget _buildCreationCard({
    required String icon,
    required String title,
    required String description,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS), // 减少内边距
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40, // 减少图标容器大小
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20), // 减少图标大小
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.paddingS), // 减少间距

            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // 最小化高度
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2), // 减少间距
                  Text(
                    description,
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建指南链接组件
  /// [icon] 链接图标
  /// [label] 链接文字
  /// [color] 主题色
  /// [onTap] 点击回调
  Widget _buildGuideLink({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS, // 减少水平padding
          vertical: 6, // 减少垂直padding
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 14), // 减少图标大小
            ),
            const SizedBox(width: 6), // 减少间距
            Text(
              label,
              style: AppTextStyles.body2.copyWith(color: color), // 使用更小的字体
            ),
          ],
        ),
      ),
    );
  }

  /// 构建工具卡片组件
  /// [icon] 工具图标
  /// [title] 工具名称
  /// [color] 主题色
  /// [onTap] 点击回调
  Widget _buildToolCard({
    required String icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS), // 减少内边距
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // 最小化高度
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24), // 减少图标大小
            ),
            const SizedBox(height: 4), // 减少间距
            Text(
              title,
              style: AppTextStyles.body2.copyWith(
                // 使用更小的字体
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // 限制为单行
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建悬浮操作按钮
  /// 提供快速创作功能入口
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickCreateDialog,
      backgroundColor: AppColors.accent,
      child: const Icon(
        Icons.add,
        color: AppColors.background,
        size: 28,
      ),
    );
  }

  /// 检查用户登录状态
  /// [action] 需要登录验证的操作回调
  /// 如果未登录则显示登录提示对话框
  Future<void> _checkAuthAndExecute(VoidCallback action) async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }
    action();
  }

  /// 显示登录要求对话框
  /// 提示用户登录以使用创作功能
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '需要登录',
          style: AppTextStyles.h3,
        ),
        content: Text(
          '创作功能需要登录后才能使用，请先登录您的账号。',
          style: AppTextStyles.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  /// 显示快速创作对话框
  /// 提供快速创作选项菜单
  void _showQuickCreateDialog() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '快速创作',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            ListTile(
              leading: const Text('📝', style: TextStyle(fontSize: 24)),
              title: const Text('创建新故事'),
              subtitle: const Text('开始一个全新的故事创作'),
              onTap: () {
                Navigator.of(context).pop();
                _createNewStory();
              },
            ),
            ListTile(
              leading: const Text('👤', style: TextStyle(fontSize: 24)),
              title: const Text('创建角色'),
              subtitle: const Text('为你的故事设计角色'),
              onTap: () {
                Navigator.of(context).pop();
                _createCharacter();
              },
            ),
            ListTile(
              leading: const Text('📋', style: TextStyle(fontSize: 24)),
              title: const Text('使用模版'),
              subtitle: const Text('基于模版快速开始'),
              onTap: () {
                Navigator.of(context).pop();
                _useTemplate();
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        ),
      ),
    );
  }

  // ==================== 事件处理方法 ====================

  /// 创建新故事
  void _createNewStory() async {
    await _checkAuthAndExecute(() {
      debugPrint('跳转到故事创作页面');
      Navigator.of(context).pushNamed('/story_creation');
    });
  }

  /// 创建角色
  void _createCharacter() async {
    await _checkAuthAndExecute(() {
      debugPrint('跳转到角色管理页面');
      Navigator.of(context).pushNamed('/character_management');
    });
  }

  /// 使用模版
  void _useTemplate() async {
    await _checkAuthAndExecute(() {
      debugPrint('跳转到模版中心页面');
      Navigator.of(context).pushNamed('/template_center');
    });
  }

  /// 打开创作指南
  void _openCreationGuide() {
    debugPrint('打开故事创作指南');
    // TODO: 实现创作指南页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('故事创作指南功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 打开创作公约
  void _openCreationRules() {
    debugPrint('打开创作公约');
    // TODO: 实现创作公约页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('创作公约功能开发中...'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  /// 打开图片编辑器
  void _openImageEditor() async {
    await _checkAuthAndExecute(() {
      debugPrint('打开图片编辑器');
      // TODO: 实现图片编辑功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('图片编辑功能开发中...'),
          backgroundColor: AppColors.warning,
        ),
      );
    });
  }

  /// 打开文本编辑器
  void _openTextEditor() async {
    await _checkAuthAndExecute(() {
      debugPrint('打开文本编辑器');
      // TODO: 实现文本编辑功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('文本编辑功能开发中...'),
          backgroundColor: AppColors.secondary,
        ),
      );
    });
  }

  /// 打开角色编辑器
  void _openCharacterEditor() async {
    await _checkAuthAndExecute(() {
      debugPrint('打开角色编辑器');
      Navigator.of(context).pushNamed('/character_management');
    });
  }

  /// 打开名称生成器
  void _openNameGenerator() async {
    await _checkAuthAndExecute(() {
      debugPrint('打开名称生成器');
      // TODO: 实现名称生成功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('名称生成器功能开发中...'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }
}
