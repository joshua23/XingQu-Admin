/// 故事数据模型
/// 包含故事的所有信息
class Story {
  /// 故事唯一标识符
  final String id;

  /// 故事标题
  final String title;

  /// 故事内容
  final String content;

  /// 故事配图URL
  final String? imageUrl;

  /// 故事标签列表
  final List<String> tags;

  /// 发布用户信息
  final User user;

  /// 创建时间
  final DateTime createdAt;

  /// 点赞数量
  final int likeCount;

  /// 评论数量
  final int commentCount;

  /// 当前用户是否已点赞
  final bool isLiked;

  /// 浏览次数
  final int views;

  const Story({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.tags,
    required this.user,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.views,
  });

  /// 从JSON创建Story实例
  /// [json] JSON数据映射
  /// 返回Story对象
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [],
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      views: json['views'] as int? ?? 0,
    );
  }

  /// 将Story转换为JSON
  /// 返回JSON数据映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'tags': tags,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'views': views,
    };
  }

  /// 复制Story对象并修改部分属性
  /// 返回新的Story对象
  Story copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    List<String>? tags,
    User? user,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    int? views,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      views: views ?? this.views,
    );
  }
}

/// 用户数据模型
/// 包含用户的基本信息
class User {
  /// 用户唯一标识符
  final String id;

  /// 用户昵称
  final String nickname;

  /// 用户头像URL
  final String? avatarUrl;

  /// 当前用户是否已关注此用户
  final bool isFollowed;

  const User({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.isFollowed,
  });

  /// 从JSON创建User实例
  /// [json] JSON数据映射
  /// 返回User对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isFollowed: json['isFollowed'] as bool? ?? false,
    );
  }

  /// 将User转换为JSON
  /// 返回JSON数据映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'isFollowed': isFollowed,
    };
  }

  /// 复制User对象并修改部分属性
  /// 返回新的User对象
  User copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    bool? isFollowed,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}
