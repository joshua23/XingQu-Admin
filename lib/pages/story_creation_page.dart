import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 故事创作页面
/// 提供故事的创建、编辑、章节管理等功能
class StoryCreationPage extends StatefulWidget {
  const StoryCreationPage({super.key});

  @override
  State<StoryCreationPage> createState() => _StoryCreationPageState();
}

/// 故事创作页面状态类
/// 管理故事创作的状态和用户交互
class _StoryCreationPageState extends State<StoryCreationPage>
    with SingleTickerProviderStateMixin {
  // 表单控制器
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // 选项卡控制器
  late TabController _tabController;

  // 章节列表数据
  List<Map<String, dynamic>> _chapters = [];

  // 已添加角色数量
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();

    // 初始化选项卡控制器
    _tabController = TabController(length: 4, vsync: this);

    // 初始化示例数据
    _initializeMockData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 初始化模拟数据
  /// 添加一些示例章节和角色数据
  void _initializeMockData() {
    _chapters = [
      {
        'title': '第一章：开始的冒险',
        'wordCount': 1245,
        'lastEdited': '2小时前',
        'status': '已完成',
      },
      {
        'title': '第二章：神秘的森林',
        'wordCount': 0,
        'lastEdited': '从未编辑',
        'status': '待编写',
      },
    ];

    _characterCount = 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 选项卡栏
          _buildTabBar(),

          // 选项卡内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildChapterTab(),
                _buildCharacterTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  /// 构建应用栏
  /// 使用标准 AppBar 避免溢出
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
          const Text('📝',
              style: TextStyle(color: AppColors.accent, fontSize: 22)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('故事创作',
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.bold)),
                Text('编写你的精彩故事',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          color: AppColors.surface,
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.preview, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text('预览')
                  ],
                )),
            const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('导出')
                  ],
                )),
            const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text('删除')
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// 构建选项卡栏
  /// 包含基本信息、章节管理、角色设定、故事设置四个选项卡
  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        dividerColor: Colors.transparent, // 移除底部分隔线
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.body2,
        tabs: const [
          Tab(text: '基本信息'),
          Tab(text: '章节管理'),
          Tab(text: '故事元素'),
          Tab(text: '设置'),
        ],
      ),
    );
  }

  /// 构建基本信息选项卡
  /// 包含故事标题、简介等基础信息编辑
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 故事标题
          Text(
            '故事标题',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          TextField(
            controller: _titleController,
            style: AppTextStyles.body1,
            decoration: InputDecoration(
              hintText: '输入故事标题',
              hintStyle:
                  AppTextStyles.body1.copyWith(color: AppColors.textHint),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // 故事简介
          Text(
            '故事简介',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          TextField(
            controller: _descriptionController,
            style: AppTextStyles.body1,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '简要描述你的故事...',
              hintStyle:
                  AppTextStyles.body1.copyWith(color: AppColors.textHint),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // 故事分类
          _buildCategorySelector(),

          const SizedBox(height: AppDimensions.paddingL),

          // 故事标签
          _buildTagSelector(),
        ],
      ),
    );
  }

  /// 构建章节管理选项卡
  /// 显示章节列表和管理功能
  Widget _buildChapterTab() {
    return Column(
      children: [
        // 章节统计信息
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(AppDimensions.paddingM),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '章节管理',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '共 ${_chapters.length} 个章节',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _addNewChapter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('+ 添加章节'),
              ),
            ],
          ),
        ),

        // 章节列表
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            itemCount: _chapters.length,
            itemBuilder: (context, index) {
              final chapter = _chapters[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                child: _buildChapterCard(chapter, index),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建故事元素选项卡
  /// 包含角色、背景音乐、背景图等元素管理
  Widget _buildCharacterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '故事元素',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // 元素卡片网格
          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.5,
            mainAxisSpacing: AppDimensions.paddingM,
            children: [
              _buildElementCard(
                icon: '👥',
                title: '添加角色',
                subtitle: '已添加 $_characterCount 个角色',
                color: AppColors.success,
                onTap: _addCharacters,
              ),
              _buildElementCard(
                icon: '🎵',
                title: '背景音乐',
                subtitle: '选择音乐氛围',
                color: AppColors.secondary,
                onTap: _selectBackgroundMusic,
              ),
              _buildElementCard(
                icon: '🖼️',
                title: '背景图',
                subtitle: '设置场景背景',
                color: AppColors.warning,
                onTap: _selectBackgroundImage,
              ),
              _buildElementCard(
                icon: '🎨',
                title: '绘图风格',
                subtitle: '选择插画风格',
                color: AppColors.accent,
                onTap: _selectDrawingStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建设置选项卡
  /// 包含故事的各种设置选项
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '故事设置',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _buildSettingItem(
            icon: Icons.visibility,
            title: '隐私设置',
            subtitle: '公开',
            onTap: _changePrivacySetting,
          ),
          _buildSettingItem(
            icon: Icons.comment,
            title: '评论设置',
            subtitle: '允许评论',
            onTap: _changeCommentSetting,
          ),
          _buildSettingItem(
            icon: Icons.share,
            title: '分享设置',
            subtitle: '允许分享',
            onTap: _changeShareSetting,
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: '语言设置',
            subtitle: '中文',
            onTap: _changeLanguageSetting,
          ),
        ],
      ),
    );
  }

  /// 构建分类选择器
  /// 让用户选择故事的类别
  Widget _buildCategorySelector() {
    final categories = ['冒险', '浪漫', '悬疑', '科幻', '奇幻', '现实'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '故事分类',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Wrap(
          spacing: AppDimensions.paddingS,
          runSpacing: AppDimensions.paddingS,
          children: categories.map((category) {
            return FilterChip(
              label: Text(category),
              selected: category == '冒险', // 默认选中冒险
              onSelected: (selected) {
                // TODO: 实现分类选择逻辑
              },
              selectedColor: AppColors.accent.withOpacity(0.2),
              checkmarkColor: AppColors.accent,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建标签选择器
  /// 让用户为故事添加标签
  Widget _buildTagSelector() {
    final tags = ['魔法', '冒险', '友情', '成长', '幽默'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '故事标签',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Wrap(
          spacing: AppDimensions.paddingS,
          runSpacing: AppDimensions.paddingS,
          children: [
            ...tags.map((tag) {
              return FilterChip(
                label: Text(tag),
                selected: false,
                onSelected: (selected) {
                  // TODO: 实现标签选择逻辑
                },
              );
            }),
            ActionChip(
              label: const Text('+ 添加标签'),
              onPressed: () {
                // TODO: 实现添加自定义标签功能
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 构建章节卡片
  /// [chapter] 章节数据
  /// [index] 章节索引
  Widget _buildChapterCard(Map<String, dynamic> chapter, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            // 章节信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter['title'],
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chapter['wordCount']} 字 · 最后编辑：${chapter['lastEdited']}',
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: chapter['status'] == '已完成'
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.warning.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      chapter['status'],
                      style: AppTextStyles.caption.copyWith(
                        color: chapter['status'] == '已完成'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 操作按钮
            Column(
              children: [
                IconButton(
                  onPressed: () => _editChapter(index),
                  icon: const Icon(Icons.edit, color: AppColors.secondary),
                ),
                IconButton(
                  onPressed: () => _deleteChapter(index),
                  icon: const Icon(Icons.delete, color: AppColors.accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建元素卡片
  /// [icon] 图标
  /// [title] 标题
  /// [subtitle] 副标题
  /// [color] 主题色
  /// [onTap] 点击回调
  Widget _buildElementCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置项
  /// [icon] 图标
  /// [title] 标题
  /// [subtitle] 副标题
  /// [onTap] 点击回调
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.body1),
      subtitle: Text(subtitle, style: AppTextStyles.body2),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// 构建保存按钮
  /// 悬浮操作按钮，用于保存故事
  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _saveStory,
      backgroundColor: AppColors.accent,
      icon: const Icon(Icons.save, color: AppColors.background),
      label: const Text(
        '保存',
        style: TextStyle(color: AppColors.background),
      ),
    );
  }

  // ==================== 事件处理方法 ====================

  /// 处理菜单操作
  /// [action] 操作类型
  void _handleMenuAction(String action) {
    switch (action) {
      case 'preview':
        _previewStory();
        break;
      case 'export':
        _exportStory();
        break;
      case 'delete':
        _showDeleteStoryDialog();
        break;
    }
  }

  /// 添加新章节
  void _addNewChapter() {
    setState(() {
      _chapters.add({
        'title': '第${_chapters.length + 1}章：新章节',
        'wordCount': 0,
        'lastEdited': '从未编辑',
        'status': '待编写',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已添加新章节'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// 编辑章节
  /// [index] 章节索引
  void _editChapter(int index) {
    debugPrint('编辑章节: ${_chapters[index]['title']}');
    // TODO: 实现章节编辑功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('章节编辑功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 删除章节
  /// [index] 章节索引
  void _deleteChapter(int index) {
    final chapterTitle = _chapters[index]['title'];
    setState(() {
      _chapters.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除章节 "$chapterTitle"'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  /// 添加角色
  void _addCharacters() {
    Navigator.of(context).pushNamed('/character_management');
  }

  /// 选择背景音乐
  void _selectBackgroundMusic() {
    debugPrint('选择背景音乐');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('背景音乐功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 选择背景图
  void _selectBackgroundImage() {
    debugPrint('选择背景图');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('背景图功能开发中...'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  /// 选择绘图风格
  void _selectDrawingStyle() {
    debugPrint('选择绘图风格');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('绘图风格功能开发中...'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  /// 更改隐私设置
  void _changePrivacySetting() {
    debugPrint('更改隐私设置');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('隐私设置功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 更改评论设置
  void _changeCommentSetting() {
    debugPrint('更改评论设置');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('评论设置功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 更改分享设置
  void _changeShareSetting() {
    debugPrint('更改分享设置');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享设置功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 更改语言设置
  void _changeLanguageSetting() {
    debugPrint('更改语言设置');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('语言设置功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 预览故事
  void _previewStory() {
    debugPrint('预览故事');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('故事预览功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 导出故事
  void _exportStory() {
    debugPrint('导出故事');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('故事导出功能开发中...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// 显示删除故事确认对话框
  void _showDeleteStoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '删除故事',
          style: AppTextStyles.h3,
        ),
        content: Text(
          '确定要删除这个故事吗？此操作无法撤销。',
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
              Navigator.of(context).pop(); // 返回上一页
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 保存故事
  void _saveStory() {
    debugPrint('保存故事');
    // TODO: 实现故事保存功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('故事已保存'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
