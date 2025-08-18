import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/custom_agent.dart';

/// AI智能体卡片组件
class AgentCard extends StatelessWidget {
  final CustomAgent agent;
  final VoidCallback? onTap;
  final VoidCallback? onUse;
  final VoidCallback? onClone;
  final bool isCompact;

  const AgentCard({
    Key? key,
    required this.agent,
    this.onTap,
    this.onUse,
    this.onClone,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：头像、状态标识和操作菜单
              _buildHeader(context),
              
              const SizedBox(height: 12),
              
              // 智能体名称
              _buildName(),
              
              const SizedBox(height: 6),
              
              // 描述
              _buildDescription(),
              
              const SizedBox(height: 12),
              
              // 能力标签
              _buildCapabilities(),
              
              const Spacer(),
              
              // 底部：评分、使用量和操作按钮
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              _buildAvatar(size: 40),
              
              const SizedBox(height: 8),
              
              // 名称
              Text(
                agent.agentName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // 类型标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getAgentTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  agent.agentType.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getAgentTypeColor(),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // 简化的评分信息
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    agent.ratingScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    agent.usageDisplayText,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像
        _buildAvatar(),
        
        const SizedBox(width: 12),
        
        // 状态指示器
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusIndicators(),
            ],
          ),
        ),
        
        // 操作菜单
        _buildActionMenu(context),
      ],
    );
  }

  Widget _buildAvatar({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getAgentTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getAgentTypeColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
            ? Image.network(
                agent.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(size),
              )
            : _buildDefaultAvatar(size),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Icon(
      _getAgentTypeIcon(),
      size: size * 0.5,
      color: _getAgentTypeColor(),
    );
  }

  Widget _buildStatusIndicators() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // 智能体类型
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getAgentTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            agent.agentType.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _getAgentTypeColor(),
            ),
          ),
        ),
        
        // 高评分标识
        if (agent.isHighRated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 10,
                  color: Colors.amber,
                ),
                const SizedBox(width: 2),
                const Text(
                  '优质',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        
        // 热门标识
        if (agent.isPopular)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 10,
                  color: Colors.red,
                ),
                const SizedBox(width: 2),
                const Text(
                  '热门',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildName() {
    return Text(
      agent.agentName,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      agent.description,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCapabilities() {
    final displayCapabilities = agent.capabilityDisplayNames.take(2).toList();
    
    if (displayCapabilities.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...displayCapabilities.map((capability) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            capability,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        )).toList(),
        
        // 显示更多能力的指示器
        if (agent.capabilities.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${agent.capabilities.length - 2}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        // 统计信息行
        Row(
          children: [
            // 评分
            Icon(
              Icons.star,
              size: 14,
              color: Colors.amber,
            ),
            const SizedBox(width: 2),
            Text(
              agent.ratingScore.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 使用量
            Icon(
              Icons.trending_up,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 2),
            Text(
              agent.usageDisplayText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            
            const Spacer(),
            
            // 最后使用时间
            Text(
              agent.lastUsedDisplayText,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 操作按钮行
        Row(
          children: [
            // 使用按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onUse,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('使用'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 克隆按钮
            if (onClone != null)
              OutlinedButton.icon(
                onPressed: onClone,
                icon: const Icon(Icons.content_copy, size: 14),
                label: const Text('克隆'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: AppColors.textSecondary,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('分享', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('举报', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleMenuAction(context, value),
    );
  }

  Color _getAgentTypeColor() {
    switch (agent.agentType) {
      case AgentType.creative:
        return Colors.purple;
      case AgentType.technical:
        return Colors.blue;
      case AgentType.educational:
        return Colors.green;
      case AgentType.business:
        return Colors.orange;
      case AgentType.entertainment:
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }

  IconData _getAgentTypeIcon() {
    switch (agent.agentType) {
      case AgentType.creative:
        return Icons.palette;
      case AgentType.technical:
        return Icons.code;
      case AgentType.educational:
        return Icons.school;
      case AgentType.business:
        return Icons.business;
      case AgentType.entertainment:
        return Icons.games;
      default:
        return Icons.smart_toy;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享智能体: ${agent.agentName}'),
            backgroundColor: AppColors.primary,
          ),
        );
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('举报功能开发中'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
    }
  }
}

/// 智能体列表卡片（横向布局）
class AgentCardHorizontal extends StatelessWidget {
  final CustomAgent agent;
  final VoidCallback? onTap;
  final VoidCallback? onUse;

  const AgentCardHorizontal({
    Key? key,
    required this.agent,
    this.onTap,
    this.onUse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 头像
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAgentTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getAgentTypeColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
                      ? Image.network(
                          agent.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getAgentTypeIcon(),
                            size: 24,
                            color: _getAgentTypeColor(),
                          ),
                        )
                      : Icon(
                          _getAgentTypeIcon(),
                          size: 24,
                          color: _getAgentTypeColor(),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            agent.agentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // 评分
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              agent.ratingScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      agent.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        // 类型标签
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getAgentTypeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            agent.agentType.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getAgentTypeColor(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 使用量
                        Text(
                          agent.usageDisplayText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 使用按钮
              if (onUse != null)
                ElevatedButton(
                  onPressed: onUse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    elevation: 0,
                  ),
                  child: const Text('使用'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAgentTypeColor() {
    switch (agent.agentType) {
      case AgentType.creative:
        return Colors.purple;
      case AgentType.technical:
        return Colors.blue;
      case AgentType.educational:
        return Colors.green;
      case AgentType.business:
        return Colors.orange;
      case AgentType.entertainment:
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }

  IconData _getAgentTypeIcon() {
    switch (agent.agentType) {
      case AgentType.creative:
        return Icons.palette;
      case AgentType.technical:
        return Icons.code;
      case AgentType.educational:
        return Icons.school;
      case AgentType.business:
        return Icons.business;
      case AgentType.entertainment:
        return Icons.games;
      default:
        return Icons.smart_toy;
    }
  }
}