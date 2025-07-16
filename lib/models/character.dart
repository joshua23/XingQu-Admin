/// 角色数据模型
/// 用于存储和管理故事创作中的角色信息
class Character {
  /// 角色唯一标识符
  final String id;

  /// 角色名称
  final String name;

  /// 角色描述
  final String description;

  /// 角色头像URL或本地图片路径
  final String? avatarUrl;

  /// 角色性格标签列表
  final List<String> personalityTags;

  /// 角色背景故事
  final String backgroundStory;

  /// 角色职业/身份
  final String profession;

  /// 角色年龄
  final int? age;

  /// 角色性别
  final CharacterGender gender;

  /// 角色声音类型（用于语音合成）
  final CharacterVoiceType voiceType;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 是否为默认角色（系统预设）
  final bool isDefault;

  /// 角色使用次数统计
  final int usageCount;

  /// 构造函数
  /// 所有必需参数都有明确的类型声明
  const Character({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.personalityTags,
    required this.backgroundStory,
    required this.profession,
    this.age,
    required this.gender,
    required this.voiceType,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.usageCount = 0,
  });

  /// 从JSON创建Character对象
  /// [json] JSON格式的角色数据
  /// 返回Character实例
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      avatarUrl: json['avatar_url'] as String?,
      personalityTags: (json['personality_tags'] as List<dynamic>?)
              ?.map((tag) => tag as String)
              .toList() ??
          [],
      backgroundStory: json['background_story'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      age: json['age'] as int?,
      gender:
          CharacterGender.fromString(json['gender'] as String? ?? 'unknown'),
      voiceType: CharacterVoiceType.fromString(
          json['voice_type'] as String? ?? 'neutral'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDefault: json['is_default'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  /// 转换为JSON格式
  /// 返回包含所有角色信息的Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'personality_tags': personalityTags,
      'background_story': backgroundStory,
      'profession': profession,
      'age': age,
      'gender': gender.value,
      'voice_type': voiceType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_default': isDefault,
      'usage_count': usageCount,
    };
  }

  /// 创建角色副本，允许修改部分属性
  /// 返回新的Character实例
  Character copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    List<String>? personalityTags,
    String? backgroundStory,
    String? profession,
    int? age,
    CharacterGender? gender,
    CharacterVoiceType? voiceType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
    int? usageCount,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      personalityTags: personalityTags ?? this.personalityTags,
      backgroundStory: backgroundStory ?? this.backgroundStory,
      profession: profession ?? this.profession,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      voiceType: voiceType ?? this.voiceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  String toString() {
    return 'Character(id: $id, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Character && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 角色性别枚举
/// 定义角色可选的性别类型
enum CharacterGender {
  /// 男性
  male('male', '男'),

  /// 女性
  female('female', '女'),

  /// 未知/不详
  unknown('unknown', '未知');

  /// 枚举值对应的字符串
  final String value;

  /// 显示名称
  final String displayName;

  const CharacterGender(this.value, this.displayName);

  /// 从字符串创建性别枚举
  /// [value] 性别字符串值
  /// 返回对应的CharacterGender枚举值
  static CharacterGender fromString(String value) {
    for (CharacterGender gender in CharacterGender.values) {
      if (gender.value == value) {
        return gender;
      }
    }
    return CharacterGender.unknown;
  }
}

/// 角色声音类型枚举
/// 定义角色可选的声音特征
enum CharacterVoiceType {
  /// 中性音
  neutral('neutral', '中性音'),

  /// 温柔音
  gentle('gentle', '温柔音'),

  /// 活力音
  energetic('energetic', '活力音'),

  /// 成熟音
  mature('mature', '成熟音'),

  /// 童声音
  childlike('childlike', '童声音'),

  /// 磁性音
  magnetic('magnetic', '磁性音');

  /// 枚举值对应的字符串
  final String value;

  /// 显示名称
  final String displayName;

  const CharacterVoiceType(this.value, this.displayName);

  /// 从字符串创建声音类型枚举
  /// [value] 声音类型字符串值
  /// 返回对应的CharacterVoiceType枚举值
  static CharacterVoiceType fromString(String value) {
    for (CharacterVoiceType voiceType in CharacterVoiceType.values) {
      if (voiceType.value == value) {
        return voiceType;
      }
    }
    return CharacterVoiceType.neutral;
  }
}
