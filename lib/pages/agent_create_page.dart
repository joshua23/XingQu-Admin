import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/custom_agent.dart';
import '../providers/agent_provider.dart';
import '../providers/auth_provider.dart';

/// 智能体创建页面
/// 用户可以创建自定义AI智能体
class AgentCreatePage extends StatefulWidget {
  final CustomAgent? editingAgent;

  const AgentCreatePage({
    super.key,
    this.editingAgent,
  });

  @override
  State<AgentCreatePage> createState() => _AgentCreatePageState();
}

class _AgentCreatePageState extends State<AgentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedType = 'assistant';
  String _selectedAvatar = '🤖';
  String _selectedVisibility = 'private';
  
  // 能力开关
  bool _hasCreativeCapability = true;
  bool _hasAnalysisCapability = false;
  bool _hasConversationCapability = true;
  bool _hasKnowledgeCapability = false;
  
  bool _isCreating = false;

  final List<String> _agentTypes = [
    'assistant',
    'creative',
    'analytical',
    'educational',
    'entertainment',
  ];

  final List<String> _typeDisplayNames = [
    '通用助手',
    '创意助手',
    '分析助手',
    '教育助手',
    '娱乐助手',
  ];

  final List<String> _avatarEmojis = [
    '🤖', '👨‍💻', '👩‍💻', '🧠', '💡',
    '📚', '🎭', '🎨', '🔬', '🎯',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingAgent != null) {
      _loadEditingAgent();
    }
  }

  void _loadEditingAgent() {
    final agent = widget.editingAgent!;
    _nameController.text = agent.agentName;
    _descriptionController.text = agent.description;
    _instructionsController.text = agent.systemPrompt;
    _selectedType = agent.agentType.value;
    _selectedAvatar = agent.avatarUrl ?? '🤖';
    _selectedVisibility = agent.isPublic ? 'public' : 'private';
    _hasCreativeCapability = agent.hasCapability('creative_writing');
    _hasAnalysisCapability = agent.hasCapability('data_analysis');
    _hasConversationCapability = agent.hasCapability('conversation');
    _hasKnowledgeCapability = agent.hasCapability('problem_solving');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingAgent != null;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? '编辑智能体' : '创建智能体'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _saveAgent,
            child: Text(
              isEditing ? '保存' : '创建',
              style: AppTextStyles.body1.copyWith(
                color: _isCreating ? AppColors.textSecondary : AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildTypeAndAvatarSection(),
              const SizedBox(height: 24),
              _buildCapabilitiesSection(),
              const SizedBox(height: 24),
              _buildInstructionsSection(),
              const SizedBox(height: 24),
              _buildVisibilitySection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基本信息',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          
          // 智能体名称
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '智能体名称',
              hintText: '为你的智能体起个名字',
              prefixIcon: const Icon(Icons.smart_toy),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入智能体名称';
              }
              if (value.trim().length < 2) {
                return '名称至少需要2个字符';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 智能体描述
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '智能体描述',
              hintText: '描述你的智能体能做什么',
              prefixIcon: const Icon(Icons.description),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入智能体描述';
              }
              if (value.trim().length < 10) {
                return '描述至少需要10个字符';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '类型和头像',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          
          // 智能体类型
          Text(
            '智能体类型',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_agentTypes.length, (index) {
              final type = _agentTypes[index];
              final displayName = _typeDisplayNames[index];
              final isSelected = _selectedType == type;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 20),
          
          // 头像选择
          Text(
            '选择头像',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatarEmojis.map((emoji) {
              final isSelected = _selectedAvatar == emoji;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = emoji),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '能力配置',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          
          _buildCapabilitySwitch(
            '创作能力',
            '生成故事、诗歌、文章等创意内容',
            _hasCreativeCapability,
            (value) => setState(() => _hasCreativeCapability = value),
          ),
          
          _buildCapabilitySwitch(
            '分析能力',
            '数据分析、逻辑推理、问题解决',
            _hasAnalysisCapability,
            (value) => setState(() => _hasAnalysisCapability = value),
          ),
          
          _buildCapabilitySwitch(
            '对话能力',
            '日常聊天、情感交流、陪伴互动',
            _hasConversationCapability,
            (value) => setState(() => _hasConversationCapability = value),
          ),
          
          _buildCapabilitySwitch(
            '知识问答',
            '回答问题、提供信息、教学辅导',
            _hasKnowledgeCapability,
            (value) => setState(() => _hasKnowledgeCapability = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitySwitch(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统指令（可选）',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            '为智能体定义特殊的行为规则和人格特征',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _instructionsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '例如：你是一个友善的助手，总是用积极的语气回答问题...',
              prefixIcon: const Icon(Icons.code),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '可见性设置',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          
          RadioListTile<String>(
            title: const Text('私有'),
            subtitle: const Text('只有你可以使用'),
            value: 'private',
            groupValue: _selectedVisibility,
            onChanged: (value) => setState(() => _selectedVisibility = value!),
            activeColor: AppColors.accent,
          ),
          
          RadioListTile<String>(
            title: const Text('公开'),
            subtitle: const Text('其他用户可以发现和使用'),
            value: 'public',
            groupValue: _selectedVisibility,
            onChanged: (value) => setState(() => _selectedVisibility = value!),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final agentData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'avatar': _selectedAvatar,
        'visibility': _selectedVisibility,
        'system_prompt': _instructionsController.text.trim(),
        'capabilities': {
          'creative': _hasCreativeCapability,
          'analysis': _hasAnalysisCapability,
          'conversation': _hasConversationCapability,
          'knowledge': _hasKnowledgeCapability,
        },
      };

      if (widget.editingAgent != null) {
        await agentProvider.updateAgent(
          agentId: widget.editingAgent!.agentId,
          agentName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          systemPrompt: _instructionsController.text.trim(),
          configuration: agentData,
        );
      } else {
        await agentProvider.createAgent(
          userId: authProvider.currentUserId!,
          agentName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          systemPrompt: _instructionsController.text.trim(),
          configuration: agentData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingAgent != null ? '智能体更新成功' : '智能体创建成功'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}