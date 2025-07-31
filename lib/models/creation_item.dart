/// 创作项数据模型
/// 用于管理用户的创作内容
class CreationItem {
  final String id;
  final String title;
  final String type;
  final String status;
  final String thumbnail;
  final DateTime lastModified;
  final int views;
  final int? likes;
  final String? description;
  final List<String>? tags;
  final String? content;
  final bool? isPublic;

  CreationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.thumbnail,
    required this.lastModified,
    this.views = 0,
    this.likes,
    this.description,
    this.tags,
    this.content,
    this.isPublic,
  });

  /// 从JSON创建CreationItem实例
  factory CreationItem.fromJson(Map<String, dynamic> json) {
    return CreationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      thumbnail: json['thumbnail'] as String,
      lastModified: DateTime.parse(json['last_modified'] as String),
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int?,
      description: json['description'] as String?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : null,
      content: json['content'] as String?,
      isPublic: json['is_public'] as bool?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'status': status,
      'thumbnail': thumbnail,
      'last_modified': lastModified.toIso8601String(),
      'views': views,
      'likes': likes,
      'description': description,
      'tags': tags,
      'content': content,
      'is_public': isPublic,
    };
  }

  /// 创建副本并修改部分属性
  CreationItem copyWith({
    String? id,
    String? title,
    String? type,
    String? status,
    String? thumbnail,
    DateTime? lastModified,
    int? views,
    int? likes,
    String? description,
    List<String>? tags,
    String? content,
    bool? isPublic,
  }) {
    return CreationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      thumbnail: thumbnail ?? this.thumbnail,
      lastModified: lastModified ?? this.lastModified,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  /// 判断是否为已发布状态
  bool get isPublished => status == '已发布';

  /// 判断是否为草稿状态
  bool get isDraft => status == '草稿';

  /// 判断是否为审核中状态
  bool get isUnderReview => status == '审核中';

  /// 获取格式化的最后修改时间
  String get formattedLastModified {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 获取类型对应的颜色
  String get typeColor {
    switch (type) {
      case 'AI角色':
        return '#6E5CFE';
      case '创意故事':
        return '#FF6B6B';
      case 'FM电台':
        return '#FFC542';
      case '互动游戏':
        return '#4ECDC4';
      default:
        return '#8E8E93';
    }
  }

  /// 获取状态对应的颜色
  String get statusColor {
    switch (status) {
      case '已发布':
        return '#34C759';
      case '草稿':
        return '#FF9500';
      case '审核中':
        return '#007AFF';
      default:
        return '#8E8E93';
    }
  }

  @override
  String toString() {
    return 'CreationItem(id: $id, title: $title, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreationItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}