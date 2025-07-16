import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/template.dart';

/// 模板中心页面
/// 提供故事模板的浏览、筛选和使用功能
class TemplateCenterPage extends StatefulWidget {
  const TemplateCenterPage({super.key});

  @override
  State<TemplateCenterPage> createState() => _TemplateCenterPageState();
}

/// 模板中心页面状态类
/// 管理模板数据、分类筛选和用户交互
class _TemplateCenterPageState extends State<TemplateCenterPage> {
  // 模板列表数据
  List<StoryTemplate> _templates = [];

  // 筛选后的模板列表
  List<StoryTemplate> _filteredTemplates = [];

  // 当前选中的分类
  TemplateCategory _selectedCategory = TemplateCategory.adventure;

  // 加载状态
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  /// 加载模板数据
  /// 从本地或服务器获取模板列表
  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 实际项目中应该从API获取数据
      // 这里使用模拟数据进行演示
      await Future.delayed(const Duration(seconds: 1));

      _templates = _getMockTemplates();
      _filterTemplatesByCategory(_selectedCategory);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载模板数据失败: $e');
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('加载模板数据失败，请重试');
    }
  }

  /// 获取模拟模板数据
  /// 返回预设的模板列表用于演示
  List<StoryTemplate> _getMockTemplates() {
    final now = DateTime.now();
    return [
      StoryTemplate(
        id: '1',
        title: '魔法王国历险记',
        description: '一个关于勇敢少年在魔法王国中冒险的经典故事模板，包含完整的角色设定和情节框架。',
        category: TemplateCategory.adventure,
        tags: ['魔法', '冒险', '成长'],
        chapterCount: 5,
        characterCount: 6,
        rating: 4.8,
        usageCount: 234,
        isOfficial: true,
        isFree: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
        chapters: [],
      ),
      StoryTemplate(
        id: '2',
        title: '校园青春恋曲',
        description: '描述高中生活中纯真爱情的浪漫故事模板，包含经典的校园场景和角色关系。',
        category: TemplateCategory.romance,
        tags: ['校园', '青春', '恋爱'],
        chapterCount: 8,
        characterCount: 4,
        rating: 4.5,
        usageCount: 189,
        isOfficial: true,
        isFree: true,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
        chapters: [],
      ),
      StoryTemplate(
        id: '3',
        title: '古宅悬疑案',
        description: '发生在古老宅邸中的悬疑推理故事，充满谜团和意外转折。',
        category: TemplateCategory.mystery,
        tags: ['悬疑', '推理', '古宅'],
        chapterCount: 10,
        characterCount: 8,
        rating: 4.7,
        usageCount: 156,
        isOfficial: false,
        isFree: false,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 1)),
        chapters: [],
      ),
      StoryTemplate(
        id: '4',
        title: '星际探索之旅',
        description: '未来科幻背景下的太空探索故事，包含丰富的科技元素和宇宙设定。',
        category: TemplateCategory.sciFi,
        tags: ['科幻', '太空', '探索'],
        chapterCount: 12,
        characterCount: 5,
        rating: 4.6,
        usageCount: 298,
        isOfficial: true,
        isFree: true,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 3)),
        chapters: [],
      ),
    ];
  }

  /// 根据分类筛选模板
  /// [category] 选择的分类
  void _filterTemplatesByCategory(TemplateCategory category) {
    if (category == TemplateCategory.other) {
      // "全部"分类显示所有模板
      _filteredTemplates = List.from(_templates);
    } else {
      _filteredTemplates = _templates
          .where((template) => template.category == category)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildBody(),
    );
  }

  /// 构建应用栏
  /// 使用标准 AppBar，避免溢出
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 56,
      leadingWidth: 44,
      leading: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.arrow_back_ios,
            color: AppColors.primary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const Text('📋',
              style: TextStyle(color: AppColors.success, fontSize: 22)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('模板中心',
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.bold)),
                Text('使用现成模板快速开始创作',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载指示器
  /// 显示数据加载中的状态
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.success,
          ),
          SizedBox(height: AppDimensions.paddingM),
          Text(
            '正在加载模板数据...',
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  /// 构建主体内容
  /// 包含分类选择器和模板列表
  Widget _buildBody() {
    return Column(
      children: [
        // 模板分类选择器
        _buildCategorySelector(),

        // 模板列表
        Expanded(
          child: _buildTemplateList(),
        ),
      ],
    );
  }

  /// 构建分类选择器
  /// 水平滚动的分类标签列表
  Widget _buildCategorySelector() {
    // 显示的分类（添加"全部"选项）
    final displayCategories = [
      TemplateCategory.other, // 用作"全部"
      ...TemplateCategory.values.where((c) => c != TemplateCategory.other),
    ];

    return Container(
      height: 60,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final isSelected = _selectedCategory == category;
          final displayName =
              category == TemplateCategory.other ? '全部' : category.displayName;

          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingS),
            child: Center(
              child: GestureDetector(
                onTap: () => _selectCategory(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: AppTextStyles.body1.copyWith(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建模板列表
  /// 网格布局显示模板卡片
  Widget _buildTemplateList() {
    if (_filteredTemplates.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      color: AppColors.success,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.2,
          mainAxisSpacing: AppDimensions.paddingM,
        ),
        itemCount: _filteredTemplates.length,
        itemBuilder: (context, index) {
          final template = _filteredTemplates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  /// 构建空状态页面
  /// 当没有模板时显示的提示界面
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '📋',
              style: TextStyle(
                fontSize: 80,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              '暂无模板',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              '这个分类下还没有模板，试试其他分类吧',
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模板卡片
  /// [template] 模板数据
  Widget _buildTemplateCard(StoryTemplate template) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模板封面
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusL),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary,
                    AppColors.accent,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // 模板图标
                  const Center(
                    child: Text(
                      '🏰',
                      style: TextStyle(fontSize: 60),
                    ),
                  ),

                  // 分类标签
                  Positioned(
                    top: AppDimensions.paddingS,
                    right: AppDimensions.paddingS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        template.category.displayName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 官方标识
                  if (template.isOfficial)
                    Positioned(
                      top: AppDimensions.paddingS,
                      left: AppDimensions.paddingS,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          '官方',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 模板信息
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 关键：压缩高度
                children: [
                  // 标题
                  Text(
                    template.title,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // 描述
                  Flexible(
                    child: Text(
                      template.description,
                      style: AppTextStyles.body2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 统计信息
                  Row(
                    children: [
                      Text(
                        '📖 ${template.chapterCount}章节',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        '👥 ${template.characterCount}角色',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // 评分和使用按钮
                  Row(
                    children: [
                      Text(
                        '⭐ ${template.rating} (${template.usageCount})',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success),
                      ),

                      const Spacer(),

                      // 使用模板按钮
                      ElevatedButton(
                        onPressed: () => _useTemplate(template),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.background,
                          minimumSize: const Size(72, 28),
                          textStyle: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('使用模板'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 事件处理方法 ====================

  /// 选择分类
  /// [category] 选择的分类
  void _selectCategory(TemplateCategory category) {
    setState(() {
      _selectedCategory = category;
      _filterTemplatesByCategory(category);
    });
  }

  /// 使用模板
  /// [template] 选择的模板
  void _useTemplate(StoryTemplate template) {
    debugPrint('使用模板: ${template.title}');

    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '使用模板',
          style: AppTextStyles.h3,
        ),
        content: Text(
          '确定要使用模板 "${template.title}" 创建新故事吗？',
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
              _createStoryFromTemplate(template);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 从模板创建故事
  /// [template] 选择的模板
  void _createStoryFromTemplate(StoryTemplate template) {
    // TODO: 实现基于模板创建故事的功能
    // 这里应该跳转到故事创作页面，并预填充模板内容

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在基于模板 "${template.title}" 创建故事...'),
        backgroundColor: AppColors.success,
      ),
    );

    // 跳转到故事创作页面
    Navigator.of(context).pushNamed('/story_creation');
  }

  /// 显示错误提示
  /// [message] 错误信息
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
