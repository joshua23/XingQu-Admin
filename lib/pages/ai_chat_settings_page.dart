import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

/// AI聊天设置页面
/// 包含消息设置、语音设置、智能配置等功能
class AiChatSettingsPage extends StatefulWidget {
  const AiChatSettingsPage({super.key});

  @override
  State<AiChatSettingsPage> createState() => _AiChatSettingsPageState();
}

class _AiChatSettingsPageState extends State<AiChatSettingsPage> {
  // 消息设置
  bool _autoReply = true;
  bool _typingIndicator = true;
  bool _messageRead = false;
  bool _messageVibration = true;

  // 语音设置
  bool _voiceEnabled = false;
  String _voiceSpeed = '正常';
  String _voiceStyle = '标准';
  double _voiceVolume = 0.8;

  // 智能配置
  String _responseMode = '平衡';
  double _creativity = 0.7;
  double _contextLength = 0.6;
  bool _smartSuggestions = true;
  bool _learningMode = false;

  // 个性化设置
  String _chatTheme = '深色';
  String _bubbleStyle = '圆润';
  double _fontSize = 16.0;

  // 隐私设置
  bool _dataCollection = false;
  bool _conversationHistory = true;
  bool _shareUsage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.cog,
                color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text('聊天设置', style: AppTextStyles.h3),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _resetSettings,
            child: const Text(
              '重置',
              style: TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 消息设置
            _buildSettingsGroup(
              '消息设置',
              FontAwesomeIcons.envelope,
              [
                _buildSwitchSetting(
                  '自动回复',
                  '开启后AI会自动回复消息',
                  _autoReply,
                  (value) => setState(() => _autoReply = value),
                ),
                _buildSwitchSetting(
                  '输入提示',
                  '显示AI正在输入的提示',
                  _typingIndicator,
                  (value) => setState(() => _typingIndicator = value),
                ),
                _buildSwitchSetting(
                  '已读回执',
                  '显示消息已读状态',
                  _messageRead,
                  (value) => setState(() => _messageRead = value),
                ),
                _buildSwitchSetting(
                  '消息震动',
                  '收到消息时震动提醒',
                  _messageVibration,
                  (value) => setState(() => _messageVibration = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 语音设置
            _buildSettingsGroup(
              '语音设置',
              FontAwesomeIcons.volumeUp,
              [
                _buildSwitchSetting(
                  '语音功能',
                  '开启语音朗读和识别',
                  _voiceEnabled,
                  (value) => setState(() => _voiceEnabled = value),
                ),
                _buildSelectorSetting(
                  '语音速度',
                  '调整语音播放速度',
                  _voiceSpeed,
                  ['很慢', '慢', '正常', '快', '很快'],
                  (value) => setState(() => _voiceSpeed = value),
                  enabled: _voiceEnabled,
                ),
                _buildSelectorSetting(
                  '语音风格',
                  '选择语音朗读风格',
                  _voiceStyle,
                  ['标准', '温柔', '活泼', '磁性', '童声'],
                  (value) => setState(() => _voiceStyle = value),
                  enabled: _voiceEnabled,
                ),
                _buildSliderSetting(
                  '语音音量',
                  '调整语音播放音量',
                  _voiceVolume,
                  (value) => setState(() => _voiceVolume = value),
                  enabled: _voiceEnabled,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 智能配置
            _buildSettingsGroup(
              '智能配置',
              FontAwesomeIcons.brain,
              [
                _buildSelectorSetting(
                  '回复模式',
                  '选择AI回复的倾向性',
                  _responseMode,
                  ['简洁', '平衡', '详细', '创意', '专业'],
                  (value) => setState(() => _responseMode = value),
                ),
                _buildSliderSetting(
                  '创意程度',
                  '调整AI回复的创意水平',
                  _creativity,
                  (value) => setState(() => _creativity = value),
                ),
                _buildSliderSetting(
                  '上下文长度',
                  '调整AI记忆的对话长度',
                  _contextLength,
                  (value) => setState(() => _contextLength = value),
                ),
                _buildSwitchSetting(
                  '智能建议',
                  '提供对话建议和提示',
                  _smartSuggestions,
                  (value) => setState(() => _smartSuggestions = value),
                ),
                _buildSwitchSetting(
                  '学习模式',
                  'AI学习用户偏好优化回复',
                  _learningMode,
                  (value) => setState(() => _learningMode = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 个性化设置
            _buildSettingsGroup(
              '个性化设置',
              FontAwesomeIcons.palette,
              [
                _buildSelectorSetting(
                  '聊天主题',
                  '选择聊天界面主题',
                  _chatTheme,
                  ['深色', '浅色', '自动', '护眼'],
                  (value) => setState(() => _chatTheme = value),
                ),
                _buildSelectorSetting(
                  '气泡样式',
                  '选择消息气泡样式',
                  _bubbleStyle,
                  ['圆润', '方形', '卡片', '简约'],
                  (value) => setState(() => _bubbleStyle = value),
                ),
                _buildSliderSetting(
                  '字体大小',
                  '调整聊天字体大小',
                  (_fontSize - 12) / 8, // 转换为0-1范围
                  (value) => setState(() => _fontSize = 12 + value * 8),
                  min: 12,
                  max: 20,
                  showValue: true,
                  valueFormatter: (value) => '${_fontSize.toInt()}px',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 隐私设置
            _buildSettingsGroup(
              '隐私设置',
              FontAwesomeIcons.shield,
              [
                _buildSwitchSetting(
                  '数据收集',
                  '允许收集数据以改善服务',
                  _dataCollection,
                  (value) => setState(() => _dataCollection = value),
                ),
                _buildSwitchSetting(
                  '对话历史',
                  '保存对话历史记录',
                  _conversationHistory,
                  (value) => setState(() => _conversationHistory = value),
                ),
                _buildSwitchSetting(
                  '使用统计',
                  '分享匿名使用统计信息',
                  _shareUsage,
                  (value) => setState(() => _shareUsage = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 操作按钮
            _buildActionButtons(),

            const SizedBox(height: 100), // 底部安全区域
          ],
        ),
      ),
    );
  }

  /// 构建设置分组
  Widget _buildSettingsGroup(
      String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分组标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                FaIcon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.h4),
              ],
            ),
          ),
          // 设置项列表
          ...children
              .map((child) => Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    child: child,
                  ))
              .toList(),
        ],
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surface.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withOpacity(0.3),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  /// 构建选择器设置项
  Widget _buildSelectorSetting(
    String title,
    String description,
    String value,
    List<String> options,
    ValueChanged<String> onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surface.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: enabled
                ? () => _showSelector(title, value, options, onChanged)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: enabled ? AppColors.background : AppColors.border,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.caption.copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FaIcon(
                    FontAwesomeIcons.chevronDown,
                    size: 12,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建滑块设置项
  Widget _buildSliderSetting(
    String title,
    String description,
    double value,
    ValueChanged<double> onChanged, {
    bool enabled = true,
    double min = 0.0,
    double max = 1.0,
    bool showValue = false,
    String Function(double)? valueFormatter,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surface.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showValue) ...[
                const SizedBox(width: 16),
                Text(
                  valueFormatter?.call(value) ?? '${(value * 100).toInt()}%',
                  style: AppTextStyles.caption.copyWith(
                    color: enabled ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: enabled ? AppColors.accent : AppColors.border,
              inactiveTrackColor: AppColors.border.withOpacity(0.3),
              thumbColor: enabled ? AppColors.accent : AppColors.textSecondary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: AppColors.accent.withOpacity(0.2),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Column(
      children: [
        // 清除数据按钮
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: TextButton(
            onPressed: _clearData,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.trash,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  '清除聊天数据',
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 导出设置按钮
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextButton(
            onPressed: _exportSettings,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.download,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '导出设置',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 显示选择器对话框
  void _showSelector(String title, String currentValue, List<String> options,
      ValueChanged<String> onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((option) => ListTile(
                    title: Text(option, style: AppTextStyles.body),
                    leading: Radio<String>(
                      value: option,
                      groupValue: currentValue,
                      onChanged: (value) {
                        if (value != null) {
                          onChanged(value);
                          Navigator.pop(context);
                        }
                      },
                      activeColor: AppColors.accent,
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  /// 重置设置
  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('重置设置', style: AppTextStyles.h4),
        content: Text('确定要重置所有设置到默认值吗？此操作不可撤销。', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // 重置所有设置到默认值
                _autoReply = true;
                _typingIndicator = true;
                _messageRead = false;
                _messageVibration = true;
                _voiceEnabled = false;
                _voiceSpeed = '正常';
                _voiceStyle = '标准';
                _voiceVolume = 0.8;
                _responseMode = '平衡';
                _creativity = 0.7;
                _contextLength = 0.6;
                _smartSuggestions = true;
                _learningMode = false;
                _chatTheme = '深色';
                _bubbleStyle = '圆润';
                _fontSize = 16.0;
                _dataCollection = false;
                _conversationHistory = true;
                _shareUsage = false;
              });
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('设置已重置', style: AppTextStyles.body),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
            child: Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// 清除数据
  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('清除数据', style: AppTextStyles.h4),
        content: Text('确定要清除所有聊天数据吗？此操作不可撤销。', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('聊天数据已清除', style: AppTextStyles.body),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
            child: Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// 导出设置
  void _exportSettings() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('设置已导出到剪贴板', style: AppTextStyles.body),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
