/// AI角色数据模型
/// 基于设计规范和原型文件定义的角色属性
class AICharacter {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final List<String> tags;
  final int followers;
  final int messages;
  bool isFollowed;
  final String personality;
  final String background;
  final String? coverImage;
  final DateTime? lastActiveTime;
  final double? rating;
  
  AICharacter({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.tags,
    required this.followers,
    required this.messages,
    required this.isFollowed,
    required this.personality,
    required this.background,
    this.coverImage,
    this.lastActiveTime,
    this.rating,
  });

  /// 从JSON创建AICharacter实例
  factory AICharacter.fromJson(Map<String, dynamic> json) {
    return AICharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      avatar: json['avatar'] as String,
      tags: List<String>.from(json['tags'] as List),
      followers: json['followers'] as int,
      messages: json['messages'] as int,
      isFollowed: json['is_followed'] as bool,
      personality: json['personality'] as String,
      background: json['background'] as String,
      coverImage: json['cover_image'] as String?,
      lastActiveTime: json['last_active_time'] != null 
          ? DateTime.parse(json['last_active_time'] as String)
          : null,
      rating: json['rating']?.toDouble(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'tags': tags,
      'followers': followers,
      'messages': messages,
      'is_followed': isFollowed,
      'personality': personality,
      'background': background,
      'cover_image': coverImage,
      'last_active_time': lastActiveTime?.toIso8601String(),
      'rating': rating,
    };
  }

  /// 创建副本并修改部分属性
  AICharacter copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    List<String>? tags,
    int? followers,
    int? messages,
    bool? isFollowed,
    String? personality,
    String? background,
    String? coverImage,
    DateTime? lastActiveTime,
    double? rating,
  }) {
    return AICharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      tags: tags ?? this.tags,
      followers: followers ?? this.followers,
      messages: messages ?? this.messages,
      isFollowed: isFollowed ?? this.isFollowed,
      personality: personality ?? this.personality,
      background: background ?? this.background,
      coverImage: coverImage ?? this.coverImage,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      rating: rating ?? this.rating,
    );
  }

  @override
  String toString() {
    return 'AICharacter(id: $id, name: $name, followers: $followers, isFollowed: $isFollowed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AICharacter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}