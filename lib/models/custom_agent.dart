import 'package:json_annotation/json_annotation.dart';

part 'custom_agent.g.dart';

/// 自定义AI智能体数据模型
/// 对应数据库 custom_agents 表
@JsonSerializable()
class CustomAgent {
  @JsonKey(name: 'agent_id')
  final String agentId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'agent_name')
  final String agentName;
  
  final String description;
  
  @JsonKey(name: 'system_prompt')
  final String systemPrompt;
  
  final Map<String, dynamic> configuration;
  
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  
  final List<String> capabilities;
  
  final List<String> tags;
  
  @JsonKey(name: 'is_public')
  final bool isPublic;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'usage_count')
  final int usageCount;
  
  @JsonKey(name: 'rating_score')
  final double ratingScore;
  
  @JsonKey(name: 'rating_count')
  final int ratingCount;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;

  const CustomAgent({
    required this.agentId,
    required this.userId,
    required this.agentName,
    required this.description,
    required this.systemPrompt,
    required this.configuration,
    this.avatarUrl,
    required this.capabilities,
    required this.tags,
    required this.isPublic,
    required this.isActive,
    required this.usageCount,
    required this.ratingScore,
    required this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  factory CustomAgent.fromJson(Map<String, dynamic> json) =>
      _$CustomAgentFromJson(json);

  Map<String, dynamic> toJson() => _$CustomAgentToJson(this);

  /// 检查智能体是否可用
  bool get isAvailable {
    return isActive && (isPublic || userId.isNotEmpty);
  }

  /// 获取智能体状态显示文本
  String get statusDisplayText {
    if (!isActive) {
      return '已停用';
    } else if (isPublic) {
      return '公开';
    } else {
      return '私有';
    }
  }

  /// 获取评分显示文本
  String get ratingDisplayText {
    if (ratingCount == 0) {
      return '暂无评分';
    }
    return '${ratingScore.toStringAsFixed(1)}分 (${ratingCount}人评价)';
  }

  /// 获取使用次数显示文本
  String get usageDisplayText {
    if (usageCount == 0) {
      return '尚未使用';
    } else if (usageCount < 1000) {
      return '$usageCount次使用';
    } else if (usageCount < 10000) {
      final k = (usageCount / 1000).toStringAsFixed(1);
      return '${k}K次使用';
    } else {
      final k = (usageCount / 1000).round();
      return '${k}K次使用';
    }
  }

  /// 获取最后使用时间显示文本
  String get lastUsedDisplayText {
    if (lastUsedAt == null) {
      return '从未使用';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);
    
    if (difference.inMinutes < 1) {
      return '刚刚使用';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return lastUsedAt!.toString().substring(0, 10);
    }
  }

  /// 获取智能体类型（从配置中推断）
  AgentType get agentType {
    final typeValue = configuration['type']?.toString() ?? 'general';
    return AgentType.fromString(typeValue);
  }

  /// 获取智能体专长领域
  String get specialization {
    final spec = configuration['specialization']?.toString();
    if (spec != null && spec.isNotEmpty) {
      return spec;
    }
    
    // 从能力和标签推断专长
    if (capabilities.contains('creative_writing')) {
      return '创意写作';
    } else if (capabilities.contains('code_generation')) {
      return '代码生成';
    } else if (capabilities.contains('data_analysis')) {
      return '数据分析';
    } else if (capabilities.contains('language_translation')) {
      return '语言翻译';
    } else {
      return '通用助手';
    }
  }

  /// 获取智能体温度设置（创造性程度）
  double get temperature {
    final temp = configuration['temperature'];
    if (temp is num) {
      return temp.toDouble();
    }
    return 0.7; // 默认温度
  }

  /// 获取最大令牌数设置
  int get maxTokens {
    final tokens = configuration['max_tokens'];
    if (tokens is num) {
      return tokens.toInt();
    }
    return 2048; // 默认令牌数
  }

  /// 检查是否支持特定能力
  bool hasCapability(String capability) {
    return capabilities.contains(capability);
  }

  /// 检查是否包含特定标签
  bool hasTag(String tag) {
    return tags.any((t) => t.toLowerCase() == tag.toLowerCase());
  }

  /// 获取能力显示列表
  List<String> get capabilityDisplayNames {
    return capabilities.map((cap) {
      switch (cap) {
        case 'creative_writing':
          return '创意写作';
        case 'code_generation':
          return '代码生成';
        case 'data_analysis':
          return '数据分析';
        case 'language_translation':
          return '语言翻译';
        case 'image_description':
          return '图像描述';
        case 'problem_solving':
          return '问题解决';
        case 'storytelling':
          return '故事创作';
        case 'conversation':
          return '对话交流';
        default:
          return cap;
      }
    }).toList();
  }

  /// 获取智能体配置摘要
  String get configurationSummary {
    final parts = <String>[];
    
    parts.add('温度: ${temperature.toStringAsFixed(1)}');
    parts.add('最大令牌: $maxTokens');
    
    if (configuration['response_format'] != null) {
      parts.add('响应格式: ${configuration['response_format']}');
    }
    
    return parts.join(' | ');
  }

  /// 检查是否为高评分智能体
  bool get isHighRated {
    return ratingCount >= 10 && ratingScore >= 4.0;
  }

  /// 检查是否为热门智能体
  bool get isPopular {
    return usageCount >= 100;
  }

  /// 检查是否为近期活跃智能体
  bool get isRecentlyActive {
    if (lastUsedAt == null) return false;
    final daysSinceLastUse = DateTime.now().difference(lastUsedAt!).inDays;
    return daysSinceLastUse <= 7;
  }

  @override
  String toString() {
    return 'CustomAgent(name: $agentName, type: ${agentType.displayName}, usage: $usageCount, rating: ${ratingScore.toStringAsFixed(1)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomAgent && other.agentId == agentId;
  }

  @override
  int get hashCode => agentId.hashCode;

  /// 复制并修改部分属性
  CustomAgent copyWith({
    String? agentId,
    String? userId,
    String? agentName,
    String? description,
    String? systemPrompt,
    Map<String, dynamic>? configuration,
    String? avatarUrl,
    List<String>? capabilities,
    List<String>? tags,
    bool? isPublic,
    bool? isActive,
    int? usageCount,
    double? ratingScore,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return CustomAgent(
      agentId: agentId ?? this.agentId,
      userId: userId ?? this.userId,
      agentName: agentName ?? this.agentName,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      configuration: configuration ?? this.configuration,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      capabilities: capabilities ?? this.capabilities,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
      ratingScore: ratingScore ?? this.ratingScore,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// 增加使用次数
  CustomAgent incrementUsage() {
    return copyWith(
      usageCount: usageCount + 1,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 更新评分
  CustomAgent updateRating(double newRating) {
    final totalScore = ratingScore * ratingCount + newRating;
    final newRatingCount = ratingCount + 1;
    final newAverageRating = totalScore / newRatingCount;
    
    return copyWith(
      ratingScore: newAverageRating,
      ratingCount: newRatingCount,
    );
  }
}

/// 智能体类型枚举
enum AgentType {
  general('general', '通用助手'),
  creative('creative', '创意助手'),
  technical('technical', '技术助手'),
  educational('educational', '教育助手'),
  business('business', '商务助手'),
  entertainment('entertainment', '娱乐助手');

  const AgentType(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static AgentType fromString(String type) {
    return AgentType.values.firstWhere(
      (t) => t.value == type,
      orElse: () => AgentType.general,
    );
  }
}

/// 智能体能力枚举
enum AgentCapability {
  creativeWriting('creative_writing', '创意写作'),
  codeGeneration('code_generation', '代码生成'),
  dataAnalysis('data_analysis', '数据分析'),
  languageTranslation('language_translation', '语言翻译'),
  imageDescription('image_description', '图像描述'),
  problemSolving('problem_solving', '问题解决'),
  storytelling('storytelling', '故事创作'),
  conversation('conversation', '对话交流');

  const AgentCapability(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static AgentCapability fromString(String capability) {
    return AgentCapability.values.firstWhere(
      (cap) => cap.value == capability,
      orElse: () => AgentCapability.conversation,
    );
  }
  
  static List<AgentCapability> fromStringList(List<String> capabilities) {
    return capabilities.map(AgentCapability.fromString).toList();
  }
}