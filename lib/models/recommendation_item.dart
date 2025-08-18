import 'package:json_annotation/json_annotation.dart';

part 'recommendation_item.g.dart';

/// 推荐内容项数据模型
/// 对应数据库 recommendation_items 表和相关推荐算法
@JsonSerializable()
class RecommendationItem {
  @JsonKey(name: 'recommendation_id')
  final String recommendationId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'content_id')
  final String contentId;
  
  @JsonKey(name: 'content_type')
  final String contentType;
  
  @JsonKey(name: 'recommendation_score')
  final double recommendationScore;
  
  @JsonKey(name: 'algorithm_type')
  final String algorithmType;
  
  @JsonKey(name: 'recommendation_reason')
  final String? recommendationReason;
  
  @JsonKey(name: 'position_rank')
  final int positionRank;
  
  @JsonKey(name: 'is_clicked')
  final bool isClicked;
  
  @JsonKey(name: 'click_time')
  final DateTime? clickTime;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  
  // 内容详细信息 (动态填充)
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic>? contentDetails;

  RecommendationItem({
    required this.recommendationId,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.recommendationScore,
    required this.algorithmType,
    this.recommendationReason,
    required this.positionRank,
    required this.isClicked,
    this.clickTime,
    required this.createdAt,
    required this.expiresAt,
    this.contentDetails,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$RecommendationItemFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationItemToJson(this);

  /// 检查推荐是否仍然有效
  bool get isValid {
    return DateTime.now().isBefore(expiresAt);
  }

  /// 检查推荐是否已过期
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// 获取推荐算法显示名称
  String get algorithmDisplayName {
    switch (algorithmType) {
      case 'collaborative_filtering':
        return '协同过滤';
      case 'content_based':
        return '内容推荐';
      case 'hybrid':
        return '智能推荐';
      case 'popularity':
        return '热门推荐';
      case 'trending':
        return '趋势推荐';
      default:
        return '个性化推荐';
    }
  }

  /// 获取内容类型显示名称
  String get contentTypeDisplayName {
    switch (contentType) {
      case 'story':
        return '故事';
      case 'character':
        return '角色';
      case 'template':
        return '模板';
      case 'ai_agent':
        return 'AI智能体';
      case 'audio':
        return '音频内容';
      case 'creation':
        return '创作作品';
      default:
        return contentType;
    }
  }

  /// 获取推荐评分等级
  RecommendationLevel get recommendationLevel {
    if (recommendationScore >= 0.8) {
      return RecommendationLevel.high;
    } else if (recommendationScore >= 0.6) {
      return RecommendationLevel.medium;
    } else {
      return RecommendationLevel.low;
    }
  }

  /// 获取推荐评分显示文本
  String get scoreDisplayText {
    final percentage = (recommendationScore * 100).round();
    return '$percentage%匹配';
  }

  /// 获取推荐原因显示文本
  String get reasonDisplayText {
    if (recommendationReason != null && recommendationReason!.isNotEmpty) {
      return recommendationReason!;
    }
    
    switch (algorithmType) {
      case 'collaborative_filtering':
        return '基于相似用户喜好推荐';
      case 'content_based':
        return '基于您的兴趣偏好推荐';
      case 'hybrid':
        return '基于智能分析推荐';
      case 'popularity':
        return '当前热门内容';
      case 'trending':
        return '正在流行的内容';
      default:
        return '为您精选推荐';
    }
  }

  /// 获取内容标题（从详细信息中）
  String get contentTitle {
    if (contentDetails != null) {
      return contentDetails!['title']?.toString() ?? 
             contentDetails!['name']?.toString() ?? 
             '未知内容';
    }
    return '加载中...';
  }

  /// 获取内容描述（从详细信息中）
  String get contentDescription {
    if (contentDetails != null) {
      return contentDetails!['description']?.toString() ?? 
             contentDetails!['summary']?.toString() ?? 
             '';
    }
    return '';
  }

  /// 获取内容作者（从详细信息中）
  String get contentAuthor {
    if (contentDetails != null) {
      return contentDetails!['author']?.toString() ?? 
             contentDetails!['creator']?.toString() ?? 
             '匿名作者';
    }
    return '';
  }

  /// 获取内容缩略图URL（从详细信息中）
  String? get contentThumbnailUrl {
    if (contentDetails != null) {
      return contentDetails!['thumbnail_url']?.toString() ?? 
             contentDetails!['image_url']?.toString() ?? 
             contentDetails!['avatar_url']?.toString();
    }
    return null;
  }

  /// 获取内容标签列表（从详细信息中）
  List<String> get contentTags {
    if (contentDetails != null) {
      final tags = contentDetails!['tags'];
      if (tags is List) {
        return tags.map((tag) => tag.toString()).toList();
      } else if (tags is String) {
        return tags.split(',').map((tag) => tag.trim()).toList();
      }
    }
    return [];
  }

  /// 检查是否有内容详情
  bool get hasContentDetails {
    return contentDetails != null && contentDetails!.isNotEmpty;
  }

  @override
  String toString() {
    return 'RecommendationItem(contentId: $contentId, type: $contentType, score: ${scoreDisplayText}, rank: $positionRank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendationItem && 
           other.recommendationId == recommendationId;
  }

  @override
  int get hashCode => recommendationId.hashCode;

  /// 复制并修改部分属性
  RecommendationItem copyWith({
    String? recommendationId,
    String? userId,
    String? contentId,
    String? contentType,
    double? recommendationScore,
    String? algorithmType,
    String? recommendationReason,
    int? positionRank,
    bool? isClicked,
    DateTime? clickTime,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? contentDetails,
  }) {
    return RecommendationItem(
      recommendationId: recommendationId ?? this.recommendationId,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      algorithmType: algorithmType ?? this.algorithmType,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      positionRank: positionRank ?? this.positionRank,
      isClicked: isClicked ?? this.isClicked,
      clickTime: clickTime ?? this.clickTime,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      contentDetails: contentDetails ?? this.contentDetails,
    );
  }

  /// 设置内容详细信息
  RecommendationItem withContentDetails(Map<String, dynamic> details) {
    return copyWith(contentDetails: details);
  }

  /// 标记为已点击
  RecommendationItem markAsClicked() {
    return copyWith(
      isClicked: true,
      clickTime: DateTime.now(),
    );
  }
}

/// 推荐等级枚举
enum RecommendationLevel {
  high('high', '强力推荐', 0.8),
  medium('medium', '推荐', 0.6),
  low('low', '可能感兴趣', 0.0);

  const RecommendationLevel(this.value, this.displayName, this.minScore);
  
  final String value;
  final String displayName;
  final double minScore;
  
  static RecommendationLevel fromScore(double score) {
    if (score >= RecommendationLevel.high.minScore) {
      return RecommendationLevel.high;
    } else if (score >= RecommendationLevel.medium.minScore) {
      return RecommendationLevel.medium;
    } else {
      return RecommendationLevel.low;
    }
  }
}

/// 推荐算法类型枚举
enum RecommendationAlgorithm {
  collaborativeFiltering('collaborative_filtering', '协同过滤'),
  contentBased('content_based', '内容推荐'),
  hybrid('hybrid', '智能推荐'),
  popularity('popularity', '热门推荐'),
  trending('trending', '趋势推荐');

  const RecommendationAlgorithm(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static RecommendationAlgorithm fromString(String algorithm) {
    return RecommendationAlgorithm.values.firstWhere(
      (alg) => alg.value == algorithm,
      orElse: () => RecommendationAlgorithm.hybrid,
    );
  }
}

/// 内容类型枚举
enum RecommendationContentType {
  story('story', '故事'),
  character('character', '角色'),
  template('template', '模板'),
  aiAgent('ai_agent', 'AI智能体'),
  audio('audio', '音频内容'),
  creation('creation', '创作作品');

  const RecommendationContentType(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static RecommendationContentType fromString(String contentType) {
    return RecommendationContentType.values.firstWhere(
      (type) => type.value == contentType,
      orElse: () => RecommendationContentType.story,
    );
  }
}