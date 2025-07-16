import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

/// 角色创建页面
/// 包含分步创建、性格标签、技能设置等功能
class CharacterCreatePage extends StatefulWidget {
  const CharacterCreatePage({super.key});

  @override
  State<CharacterCreatePage> createState() => _CharacterCreatePageState();
}

class _CharacterCreatePageState extends State<CharacterCreatePage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // 角色基本信息
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedAvatar = '🤖';

  // 性格标签
  final List<String> _availablePersonalities = [
    '温柔',
    '活泼',
    '冷静',
    '幽默',
    '严肃',
    '友善',
    '神秘',
    '智慧',
    '勇敢',
    '害羞',
    '自信',
    '细心',
    '热情',
    '理性',
    '感性',
    '创意',
    '坚强',
    '温暖',
    '独立',
    '耐心',
    '乐观',
    '现实',
    '浪漫',
    '实用'
  ];
  final List<String> _selectedPersonalities = [];

  // 技能设置
  final List<Map<String, dynamic>> _availableSkills = [
    {'name': '创意写作', 'description': '擅长创作故事和文章', 'icon': '✍️'},
    {'name': '情感分析', 'description': '理解和分析情感状态', 'icon': '💝'},
    {'name': '学习辅导', 'description': '提供学习指导和答疑', 'icon': '📚'},
    {'name': '生活建议', 'description': '给出实用的生活建议', 'icon': '🏠'},
    {'name': '娱乐陪伴', 'description': '提供有趣的娱乐内容', 'icon': '🎮'},
    {'name': '专业咨询', 'description': '专业领域知识咨询', 'icon': '💼'},
    {'name': '心理支持', 'description': '提供心理疏导和支持', 'icon': '🧠'},
    {'name': '创意思考', 'description': '协助创意思考和决策', 'icon': '💡'},
  ];
  final List<String> _selectedSkills = [];

  // 头像选项
  final List<String> _avatarOptions = [
    '🤖',
    '👨‍💻',
    '👩‍💻',
    '🧑‍🎓',
    '👨‍🏫',
    '👩‍🏫',
    '🧑‍🎨',
    '👨‍🔬',
    '👩‍🔬',
    '🧑‍⚕️',
    '👨‍⚖️',
    '👩‍⚖️',
    '🧑‍🍳',
    '👨‍🎵',
    '👩‍🎵',
    '🧑‍🌾'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.userPlus,
                color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text('角色创建', style: AppTextStyles.h3),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isFormValid() ? _saveCharacter : null,
            child: Text(
              '保存',
              style: TextStyle(
                color:
                    _isFormValid() ? AppColors.accent : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 步骤指示器
          _buildStepIndicator(),

          // 表单内容
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildBasicInfoStep(),
                _buildPersonalityStep(),
                _buildSkillsStep(),
                _buildPreviewStep(),
              ],
            ),
          ),

          // 底部按钮
          _buildBottomActions(),
        ],
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : isActive
                          ? AppColors.accent
                          : AppColors.surface,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.success
                        : isActive
                            ? AppColors.accent
                            : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const FaIcon(FontAwesomeIcons.check,
                          color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (index < 3) ...[
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 2,
                  color: index < _currentStep
                      ? AppColors.success
                      : AppColors.border,
                ),
                const SizedBox(width: 8),
              ],
            ],
          );
        }),
      ),
    );
  }

  /// 构建基本信息步骤
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text('基本信息', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('设置角色的基本信息和外观',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // 头像选择
          _buildFormGroup(
            label: '选择头像',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _avatarOptions.length,
              itemBuilder: (context, index) {
                final avatar = _avatarOptions[index];
                final isSelected = avatar == _selectedAvatar;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatar = avatar);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 角色名称
          _buildFormGroup(
            label: '角色名称',
            child: TextField(
              controller: _nameController,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: '请输入角色名称',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 角色描述
          _buildFormGroup(
            label: '角色描述',
            child: TextField(
              controller: _descriptionController,
              style: AppTextStyles.body,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '请描述角色的特点、背景或设定',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建性格标签步骤
  Widget _buildPersonalityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text('性格标签', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('选择角色的性格特征（最多选择6个）',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // 性格标签网格
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePersonalities.map((personality) {
              final isSelected = _selectedPersonalities.contains(personality);
              final canSelect = _selectedPersonalities.length < 6 || isSelected;

              return GestureDetector(
                onTap: canSelect
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedPersonalities.remove(personality);
                          } else {
                            _selectedPersonalities.add(personality);
                          }
                        });
                        HapticFeedback.lightImpact();
                      }
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.1)
                        : canSelect
                            ? AppColors.surface
                            : AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : canSelect
                              ? AppColors.border
                              : AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    personality,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.accent
                          : canSelect
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 已选择的标签
          if (_selectedPersonalities.isNotEmpty) ...[
            Text('已选择的标签：', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedPersonalities
                    .map((personality) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Text(
                            personality,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontSize: 11,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建技能设置步骤
  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text('技能设置', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('选择角色擅长的技能领域（最多选择4个）',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // 技能列表
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _availableSkills.length,
            itemBuilder: (context, index) {
              final skill = _availableSkills[index];
              final isSelected = _selectedSkills.contains(skill['name']);
              final canSelect = _selectedSkills.length < 4 || isSelected;

              return GestureDetector(
                onTap: canSelect
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill['name']);
                          } else {
                            _selectedSkills.add(skill['name']);
                          }
                        });
                        HapticFeedback.lightImpact();
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.1)
                        : canSelect
                            ? AppColors.surface
                            : AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : canSelect
                              ? AppColors.border
                              : AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 技能图标
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.accent
                              : canSelect
                                  ? AppColors.accent.withOpacity(0.2)
                                  : AppColors.border,
                        ),
                        child: Center(
                          child: Text(
                            skill['icon'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 技能名称
                      Text(
                        skill['name'],
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? AppColors.accent
                              : canSelect
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // 技能描述
                      Text(
                        skill['description'],
                        style: AppTextStyles.caption.copyWith(
                          color: canSelect
                              ? AppColors.textSecondary
                              : AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建预览步骤
  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text('预览角色', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('确认角色信息并保存',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // 预览卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // 头像
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.1),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _selectedAvatar,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 角色名称
                Text(
                  _nameController.text.isEmpty ? '未命名角色' : _nameController.text,
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // 角色描述
                if (_descriptionController.text.isNotEmpty) ...[
                  Text(
                    _descriptionController.text,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                // 性格标签
                if (_selectedPersonalities.isNotEmpty) ...[
                  Text('性格标签', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedPersonalities
                        .map((personality) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3)),
                              ),
                              child: Text(
                                personality,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 技能
                if (_selectedSkills.isNotEmpty) ...[
                  Text('擅长技能', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _selectedSkills.map((skillName) {
                      final skill = _availableSkills.firstWhere(
                        (s) => s['name'] == skillName,
                        orElse: () => {'icon': '🔧'},
                      );
                      return Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            skill['icon'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建表单分组
  Widget _buildFormGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.h4),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// 构建底部按钮
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // 上一步按钮
          if (_currentStep > 0) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
                child: const Text('上一步'),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // 下一步/完成按钮
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed()
                  ? (_currentStep < 3 ? _nextStep : _saveCharacter)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _canProceed() ? AppColors.accent : AppColors.surface,
                foregroundColor:
                    _canProceed() ? Colors.white : AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_currentStep < 3 ? '下一步' : '完成'),
            ),
          ),
        ],
      ),
    );
  }

  /// 检查是否可以进行下一步
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty;
      case 1:
        return _selectedPersonalities.isNotEmpty;
      case 2:
        return _selectedSkills.isNotEmpty;
      case 3:
        return _isFormValid();
      default:
        return false;
    }
  }

  /// 检查表单是否有效
  bool _isFormValid() {
    return _nameController.text.isNotEmpty &&
        _selectedPersonalities.isNotEmpty &&
        _selectedSkills.isNotEmpty;
  }

  /// 下一步
  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 上一步
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 保存角色
  void _saveCharacter() {
    if (!_isFormValid()) return;

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('角色创建成功', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.1),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Center(
                child: Text(
                  _selectedAvatar,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '角色 "${_nameController.text}" 已创建成功！',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('确定', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
