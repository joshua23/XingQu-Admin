import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/recommendation_item.dart';

/// 推荐内容卡片组件
class RecommendationCard extends StatelessWidget {
  final RecommendationItem recommendation;
  final VoidCallback? onTap;
  final Function(String feedbackType, String? reason)? onFeedback;

  const RecommendationCard({
    Key? key,
    required this.recommendation,
    this.onTap,
    this.onFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
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
                // 头部：内容类型、推荐分数、操作菜单
                _buildHeader(),
                
                const SizedBox(height: 12),
                
                // 主要内容区域
                _buildContent(),
                
                const SizedBox(height: 12),
                
                // 底部：推荐原因和反馈
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 内容类型标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getContentTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getContentTypeColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            recommendation.contentTypeDisplayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _getContentTypeColor(),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // 推荐等级指示器
        _buildRecommendationLevelIndicator(),
        
        const Spacer(),
        
        // 推荐分数
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            recommendation.scoreDisplayText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 更多操作菜单
        _buildMoreMenu(),
      ],
    );
  }

  Widget _buildRecommendationLevelIndicator() {
    Color color;
    IconData icon;
    
    switch (recommendation.recommendationLevel) {
      case RecommendationLevel.high:
        color = Colors.red;
        icon = Icons.local_fire_department;
        break;
      case RecommendationLevel.medium:
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      case RecommendationLevel.low:
        color = AppColors.textSecondary;
        icon = Icons.visibility;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主要内容信息
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图/头像
            _buildThumbnail(),
            
            const SizedBox(width: 12),
            
            // 内容详情
            Expanded(
              child: _buildContentDetails(),
            ),
          ],
        ),
        
        // 标签
        if (recommendation.contentTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildTags(),
        ],
      ],
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: recommendation.contentThumbnailUrl != null
            ? Image.network(
                recommendation.contentThumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
              )
            : _buildDefaultThumbnail(),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    IconData iconData;
    switch (recommendation.contentType) {
      case 'story':
        iconData = Icons.menu_book;
        break;
      case 'character':
        iconData = Icons.person;
        break;
      case 'template':
        iconData = Icons.dashboard_customize;
        break;
      case 'ai_agent':
        iconData = Icons.smart_toy;
        break;
      default:
        iconData = Icons.article;
    }

    return Icon(
      iconData,
      size: 28,
      color: _getContentTypeColor(),
    );
  }

  Widget _buildContentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          recommendation.contentTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // 描述/作者
        if (recommendation.contentDescription.isNotEmpty)
          Text(
            recommendation.contentDescription,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        
        if (recommendation.contentAuthor.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                recommendation.contentAuthor,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTags() {
    final tags = recommendation.contentTags.take(3).toList();
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // 推荐原因
        Expanded(
          child: Row(
            children: [
              Icon(
                _getAlgorithmIcon(),
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  recommendation.reasonDisplayText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // 反馈按钮
        if (onFeedback != null) ...[
          const SizedBox(width: 8),
          _buildFeedbackButtons(),
        ],
      ],
    );
  }

  Widget _buildFeedbackButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 喜欢按钮
        InkWell(
          onTap: () => onFeedback?.call('like', null),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.thumb_up_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 不感兴趣按钮
        InkWell(
          onTap: () => _showDislikeReasonDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.thumb_down_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
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
          value: 'save',
          child: Row(
            children: [
              Icon(Icons.bookmark_outline, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('收藏', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'not_interested',
          child: Row(
            children: [
              Icon(Icons.visibility_off, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('不感兴趣', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleMenuAction(value),
    );
  }

  Color _getContentTypeColor() {
    switch (recommendation.contentType) {
      case 'story':
        return Colors.blue;
      case 'character':
        return Colors.green;
      case 'template':
        return Colors.purple;
      case 'ai_agent':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  IconData _getAlgorithmIcon() {
    switch (recommendation.algorithmType) {
      case 'collaborative_filtering':
        return Icons.people;
      case 'content_based':
        return Icons.recommend;
      case 'hybrid':
        return Icons.psychology;
      case 'popularity':
        return Icons.trending_up;
      case 'trending':
        return Icons.whatshot;
      default:
        return Icons.lightbulb_outline;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        // 实现分享功能
        break;
      case 'save':
        // 实现收藏功能
        break;
      case 'not_interested':
        onFeedback?.call('not_interested', '用户主动标记');
        break;
    }
  }

  void _showDislikeReasonDialog() {
    // 这里应该显示一个对话框让用户选择不喜欢的原因
    // 为了简化，直接调用反馈回调
    onFeedback?.call('dislike', '内容不相关');
  }
}

/// 简化版推荐卡片（用于横向滚动列表）
class RecommendationCardCompact extends StatelessWidget {
  final RecommendationItem recommendation;
  final VoidCallback? onTap;

  const RecommendationCardCompact({
    Key? key,
    required this.recommendation,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 缩略图
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: recommendation.contentThumbnailUrl != null
                        ? Image.network(
                            recommendation.contentThumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
                          )
                        : _buildDefaultIcon(),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 内容类型标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getContentTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recommendation.contentTypeDisplayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getContentTypeColor(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // 标题
                Text(
                  recommendation.contentTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // 推荐分数
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      recommendation.scoreDisplayText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    IconData iconData;
    switch (recommendation.contentType) {
      case 'story':
        iconData = Icons.menu_book;
        break;
      case 'character':
        iconData = Icons.person;
        break;
      case 'template':
        iconData = Icons.dashboard_customize;
        break;
      case 'ai_agent':
        iconData = Icons.smart_toy;
        break;
      default:
        iconData = Icons.article;
    }

    return Icon(
      iconData,
      size: 32,
      color: _getContentTypeColor(),
    );
  }

  Color _getContentTypeColor() {
    switch (recommendation.contentType) {
      case 'story':
        return Colors.blue;
      case 'character':
        return Colors.green;
      case 'template':
        return Colors.purple;
      case 'ai_agent':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}