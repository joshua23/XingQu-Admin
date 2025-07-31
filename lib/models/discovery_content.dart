/// 发现页面内容数据模型
/// 用于展示各类型的发现内容
class DiscoveryContent {
  final String id;
  final String title;
  final String description;
  final String type;
  final String author;
  final String coverEmoji;
  final int viewCount;
  final int likeCount;
  final String? duration;
  final List<String> tags;
  final DateTime? publishTime;
  final String? audioUrl;
  final String? imageUrl;
  final bool? isHot;
  final bool? isNew;

  DiscoveryContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.author,
    required this.coverEmoji,
    required this.viewCount,
    required this.likeCount,
    this.duration,
    required this.tags,
    this.publishTime,
    this.audioUrl,
    this.imageUrl,
    this.isHot,
    this.isNew,
  });

  /// 从JSON创建DiscoveryContent实例
  factory DiscoveryContent.fromJson(Map<String, dynamic> json) {
    return DiscoveryContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      author: json['author'] as String,
      coverEmoji: json['cover_emoji'] as String,
      viewCount: json['view_count'] as int,
      likeCount: json['like_count'] as int,
      duration: json['duration'] as String?,
      tags: List<String>.from(json['tags'] as List),
      publishTime: json['publish_time'] != null 
          ? DateTime.parse(json['publish_time'] as String)
          : null,
      audioUrl: json['audio_url'] as String?,
      imageUrl: json['image_url'] as String?,
      isHot: json['is_hot'] as bool?,
      isNew: json['is_new'] as bool?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'author': author,
      'cover_emoji': coverEmoji,
      'view_count': viewCount,
      'like_count': likeCount,
      'duration': duration,
      'tags': tags,
      'publish_time': publishTime?.toIso8601String(),
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'is_hot': isHot,
      'is_new': isNew,
    };
  }

  /// 创建副本并修改部分属性
  DiscoveryContent copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? author,
    String? coverEmoji,
    int? viewCount,
    int? likeCount,
    String? duration,
    List<String>? tags,
    DateTime? publishTime,
    String? audioUrl,
    String? imageUrl,
    bool? isHot,
    bool? isNew,
  }) {
    return DiscoveryContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      author: author ?? this.author,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      publishTime: publishTime ?? this.publishTime,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isHot: isHot ?? this.isHot,
      isNew: isNew ?? this.isNew,
    );
  }

  /// 判断是否为音频内容
  bool get isAudioContent => type == 'FM电台' || audioUrl != null;

  /// 判断是否为AI角色
  bool get isAICharacter => type == 'AI角色';

  /// 判断是否为故事内容
  bool get isStoryContent => type == '创意故事';

  /// 获取内容类型颜色
  String get typeColor {
    switch (type) {
      case 'AI角色':
        return '#6E5CFE';
      case 'FM电台':
        return '#FFC542';
      case '创意故事':
        return '#FF6B6B';
      case '游戏世界':
        return '#4ECDC4';
      case '学习助手':
        return '#45B7D1';
      case '生活服务':
        return '#96CEB4';
      default:
        return '#8E8E93';
    }
  }

  @override
  String toString() {
    return 'DiscoveryContent(id: $id, title: $title, type: $type, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveryContent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}