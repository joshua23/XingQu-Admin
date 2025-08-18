import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/character.dart';

/// 角色管理页面
/// 提供角色的创建、编辑、删除和查看功能
class CharacterManagementPage extends StatefulWidget {
  const CharacterManagementPage({super.key});

  @override
  State<CharacterManagementPage> createState() =>
      _CharacterManagementPageState();
}

/// 角色管理页面状态类
/// 管理角色列表数据和用户交互
class _CharacterManagementPageState extends State<CharacterManagementPage> {
  // 角色列表数据
  List<Character> _characters = [];

  // 加载状态
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  /// 加载角色数据
  /// 从本地存储或服务器获取用户的角色列表
  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 实际项目中应该从数据库或API获取数据
      // 这里使用模拟数据进行演示
      await Future.delayed(const Duration(seconds: 1));

      _characters = _getMockCharacters();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载角色数据失败: $e');
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('加载角色数据失败，请重试');
    }
  }

  /// 获取模拟角色数据
  /// 返回预设的角色列表用于演示
  List<Character> _getMockCharacters() {
    final now = DateTime.now();
    return [
      Character(
        id: '1',
        name: '智者梅林',
        description: '古老的魔法师，拥有深邃的智慧和强大的魔法力量',
        personalityTags: ['智慧', '神秘', '慈祥'],
        backgroundStory:
            '梅林是传说中的魔法师，曾经指导过无数英雄完成使命。他掌握着古老的魔法知识，总是在关键时刻为冒险者提供指引。',
        profession: '魔法师',
        age: 150,
        gender: CharacterGender.male,
        voiceType: CharacterVoiceType.mature,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
        usageCount: 12,
      ),
      Character(
        id: '2',
        name: '精灵公主艾莉亚',
        description: '优雅的精灵公主，拥有治愈魔法和弓箭技能',
        personalityTags: ['优雅', '善良', '勇敢'],
        backgroundStory: '艾莉亚是精灵王国的公主，从小接受严格的战斗和魔法训练。她心地善良，总是愿意帮助需要帮助的人。',
        profession: '精灵射手',
        age: 120,
        gender: CharacterGender.female,
        voiceType: CharacterVoiceType.gentle,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
        usageCount: 8,
      ),
      Character(
        id: '3',
        name: '龙骑士卡尔',
        description: '勇敢的龙骑士，与火龙结为伙伴征战四方',
        personalityTags: ['勇敢', '正义', '坚强'],
        backgroundStory: '卡尔是来自北方王国的龙骑士，他与火龙赤焰建立了深厚的友谊。他们一起保卫着王国的和平。',
        profession: '龙骑士',
        age: 28,
        gender: CharacterGender.male,
        voiceType: CharacterVoiceType.energetic,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
        usageCount: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildBody(),
      floatingActionButton: _buildCreateCharacterButton(),
    );
  }

  /// 构建应用栏
  /// 使用标准 AppBar，避免自定义布局溢出
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
          const Text('👤',
              style: TextStyle(color: AppColors.secondary, fontSize: 22)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('角色管理',
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.bold)),
                Text('创建和管理你的故事角色',
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
            color: AppColors.secondary,
          ),
          SizedBox(height: AppDimensions.paddingM),
          Text(
            '正在加载角色数据...',
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  /// 构建主体内容
  /// 根据数据状态显示角色列表或空状态
  Widget _buildBody() {
    if (_characters.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // 创建角色提示区域
        _buildCreatePromptSection(),

        // 角色列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCharacters,
            color: AppColors.secondary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: _characters.length,
              itemBuilder: (context, index) {
                final character = _characters[index];
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.paddingM),
                  child: _buildCharacterCard(character),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空状态页面
  /// 当没有角色时显示的引导界面
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '👤',
              style: TextStyle(
                fontSize: 80,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              '还没有创建角色',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              '创建你的第一个故事角色，让创作更生动有趣',
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingXL),
            ElevatedButton.icon(
              onPressed: _showCreateCharacterDialog,
              icon: const Icon(Icons.add),
              label: const Text('创建角色'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建创建角色提示区域
  /// 显示角色数量和快速创建入口
  Widget _buildCreatePromptSection() {
    return Container(
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
                  '我的角色',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  '已创建 ${_characters.length} 个角色',
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: _showCreateCharacterDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.background,
              ),
              child: const Text('+ 创建新角色'),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建角色卡片
  /// [character] 要显示的角色数据
  Widget _buildCharacterCard(Character character) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        children: [
          // 角色头部信息
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                // 角色头像
                _buildCharacterAvatar(character),

                const SizedBox(width: AppDimensions.paddingM),

                // 角色基本信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        character.description,
                        style: AppTextStyles.body2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      _buildCharacterTags(character),
                    ],
                  ),
                ),

                // 操作按钮
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  color: AppColors.surface,
                  onSelected: (value) =>
                      _handleCharacterAction(value, character),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.secondary),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('复制'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('删除'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 角色详细信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCharacterDetailRow('职业', character.profession),
                _buildCharacterDetailRow(
                    '年龄', character.age?.toString() ?? '未知'),
                _buildCharacterDetailRow('性别', character.gender.displayName),
                _buildCharacterDetailRow('声音', character.voiceType.displayName),
                _buildCharacterDetailRow('使用次数', '${character.usageCount} 次'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建角色头像
  /// [character] 角色数据
  Widget _buildCharacterAvatar(Character character) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.accent,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getCharacterEmoji(character),
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  /// 获取角色对应的表情符号
  /// [character] 角色数据
  /// 返回适合角色的表情符号
  String _getCharacterEmoji(Character character) {
    if (character.profession.contains('魔法') ||
        character.profession.contains('法师')) {
      return '🧙‍♂️';
    } else if (character.profession.contains('精灵')) {
      return '🧝‍♀️';
    } else if (character.profession.contains('骑士')) {
      return '⚔️';
    } else if (character.gender == CharacterGender.female) {
      return '👩';
    } else if (character.gender == CharacterGender.male) {
      return '👨';
    } else {
      return '👤';
    }
  }

  /// 构建角色标签
  /// [character] 角色数据
  Widget _buildCharacterTags(Character character) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: character.personalityTags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            tag,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建角色详细信息行
  /// [label] 标签文字
  /// [value] 值文字
  Widget _buildCharacterDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.body2,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  /// 构建创建角色按钮
  /// 悬浮操作按钮，提供快速创建入口
  Widget _buildCreateCharacterButton() {
    return FloatingActionButton(
      onPressed: _showCreateCharacterDialog,
      backgroundColor: AppColors.secondary,
      child: const Icon(
        Icons.add,
        color: AppColors.background,
        size: 28,
      ),
    );
  }

  /// 处理角色操作
  /// [action] 操作类型
  /// [character] 目标角色
  void _handleCharacterAction(String action, Character character) {
    switch (action) {
      case 'edit':
        _editCharacter(character);
        break;
      case 'duplicate':
        _duplicateCharacter(character);
        break;
      case 'delete':
        _showDeleteConfirmDialog(character);
        break;
    }
  }

  /// 显示创建角色对话框
  /// 导航到角色创建页面
  void _showCreateCharacterDialog() {
    debugPrint('导航到角色创建页面');

    // 跳转到角色创建页面
    Navigator.pushNamed(context, '/character_create');
  }

  /// 编辑角色
  /// [character] 要编辑的角色
  void _editCharacter(Character character) {
    debugPrint('编辑角色: ${character.name}');

    // TODO: 实现角色编辑功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('编辑角色 "${character.name}" 功能开发中...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  /// 复制角色
  /// [character] 要复制的角色
  void _duplicateCharacter(Character character) {
    debugPrint('复制角色: ${character.name}');

    // TODO: 实现角色复制功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制角色 "${character.name}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// 显示删除确认对话框
  /// [character] 要删除的角色
  void _showDeleteConfirmDialog(Character character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '删除角色',
          style: AppTextStyles.h3,
        ),
        content: Text(
          '确定要删除角色 "${character.name}" 吗？此操作无法撤销。',
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
              _deleteCharacter(character);
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

  /// 删除角色
  /// [character] 要删除的角色
  void _deleteCharacter(Character character) {
    setState(() {
      _characters.removeWhere((c) => c.id == character.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除角色 "${character.name}"'),
        backgroundColor: AppColors.accent,
        action: SnackBarAction(
          label: '撤销',
          textColor: AppColors.background,
          onPressed: () {
            // TODO: 实现撤销删除功能
            setState(() {
              _characters.add(character);
            });
          },
        ),
      ),
    );
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
