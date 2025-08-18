import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/custom_agent.dart';
import '../providers/agent_provider.dart';
import '../providers/auth_provider.dart';

/// 智能体详情页面
/// 显示智能体的详细信息、使用记录和管理功能
class AgentDetailPage extends StatefulWidget {
  final String agentId;
  final CustomAgent? agent;

  const AgentDetailPage({
    super.key,
    required this.agentId,
    this.agent,
  });

  @override
  State<AgentDetailPage> createState() => _AgentDetailPageState();
}

class _AgentDetailPageState extends State<AgentDetailPage> {
  CustomAgent? _agent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _agent = widget.agent;
    if (_agent == null) {
      _loadAgentDetail();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAgentDetail() async {
    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      // 尝试从现有的智能体列表中查找
      final existingAgents = [
        ...agentProvider.userAgents,
        ...agentProvider.publicAgents,
        ...agentProvider.recommendedAgents,
        ...agentProvider.popularAgents,
        ...agentProvider.highRatedAgents,
      ];
      
      final foundAgent = existingAgents.firstWhere(
        (agent) => agent.agentId == widget.agentId,
        orElse: () => throw Exception('智能体未找到'),
      );
      
      if (mounted) {
        setState(() {
          _agent = foundAgent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_agent?.agentName ?? '智能体详情'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAgentDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_agent == null) {
      return const Center(
        child: Text('智能体不存在'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAgentHeader(),
          const SizedBox(height: 24),
          _buildAgentDescription(),
          const SizedBox(height: 24),
          _buildAgentCapabilities(),
          const SizedBox(height: 24),
          _buildUsageStats(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAgentHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _agent!.avatarUrl ?? '🤖',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 名称
          Text(
            _agent!.agentName,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // 类型和状态
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _agent!.agentType.displayName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _agent!.isActive 
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _agent!.isActive ? '已激活' : '未激活',
                  style: AppTextStyles.caption.copyWith(
                    color: _agent!.isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDescription() {
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
            '智能体描述',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 12),
          Text(
            _agent!.description,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCapabilities() {
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
          _buildCapabilityItem('创作能力', _agent!.hasCapability('creative_writing')),
          _buildCapabilityItem('分析能力', _agent!.hasCapability('data_analysis')),
          _buildCapabilityItem('对话能力', _agent!.hasCapability('conversation')),
          _buildCapabilityItem('知识问答', _agent!.hasCapability('problem_solving')),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String name, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: AppTextStyles.body1.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
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
            '使用统计',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '使用次数',
                  _agent!.usageCount.toString(),
                  Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '评分',
                  _agent!.ratingScore.toStringAsFixed(1),
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 主要操作按钮
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _agent!.isActive ? _useAgent : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: const Text('开始使用'),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 次要操作按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cloneAgent,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('克隆'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _shareAgent,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('分享'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _useAgent() {
    // TODO: 实现使用智能体功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('即将开始与智能体对话...'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _cloneAgent() {
    // TODO: 实现克隆智能体功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('克隆功能开发中...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _shareAgent() {
    // TODO: 实现分享智能体功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}