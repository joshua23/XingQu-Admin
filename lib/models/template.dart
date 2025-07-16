/// 故事模板数据模型
/// 用于存储和管理故事创作模板信息
class StoryTemplate {
  /// 模板唯一标识符
  final String id;

  /// 模板标题
  final String title;

  /// 模板描述
  final String description;

  /// 模板封面图URL
  final String? coverImageUrl;

  /// 模板分类
  final TemplateCategory category;

  /// 模板标签列表
  final List<String> tags;

  /// 章节数量
  final int chapterCount;

  /// 推荐角色数量
  final int characterCount;

  /// 模板评分（1-5星）
  final double rating;

  /// 使用次数统计
  final int usageCount;

  /// 模板作者ID
  final String? authorId;

  /// 模板作者名称
  final String? authorName;

  /// 是否为官方模板
  final bool isOfficial;

  /// 是否免费
  final bool isFree;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 模板内容结构（章节列表）
  final List<TemplateChapter> chapters;

  /// 构造函数
  /// 所有必需参数都有明确的类型声明
  const StoryTemplate({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.category,
    required this.tags,
    required this.chapterCount,
    required this.characterCount,
    required this.rating,
    required this.usageCount,
    this.authorId,
    this.authorName,
    this.isOfficial = false,
    this.isFree = true,
    required this.createdAt,
    required this.updatedAt,
    required this.chapters,
  });

  /// 从JSON创建StoryTemplate对象
  /// [json] JSON格式的模板数据
  /// 返回StoryTemplate实例
  factory StoryTemplate.fromJson(Map<String, dynamic> json) {
    return StoryTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      category: TemplateCategory.fromString(
          json['category'] as String? ?? 'adventure'),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag as String)
              .toList() ??
          [],
      chapterCount: json['chapter_count'] as int? ?? 0,
      characterCount: json['character_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      usageCount: json['usage_count'] as int? ?? 0,
      authorId: json['author_id'] as String?,
      authorName: json['author_name'] as String?,
      isOfficial: json['is_official'] as bool? ?? false,
      isFree: json['is_free'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((chapter) =>
                  TemplateChapter.fromJson(chapter as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 转换为JSON格式
  /// 返回包含所有模板信息的Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'category': category.value,
      'tags': tags,
      'chapter_count': chapterCount,
      'character_count': characterCount,
      'rating': rating,
      'usage_count': usageCount,
      'author_id': authorId,
      'author_name': authorName,
      'is_official': isOfficial,
      'is_free': isFree,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  /// 创建模板副本，允许修改部分属性
  /// 返回新的StoryTemplate实例
  StoryTemplate copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    TemplateCategory? category,
    List<String>? tags,
    int? chapterCount,
    int? characterCount,
    double? rating,
    int? usageCount,
    String? authorId,
    String? authorName,
    bool? isOfficial,
    bool? isFree,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TemplateChapter>? chapters,
  }) {
    return StoryTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      chapterCount: chapterCount ?? this.chapterCount,
      characterCount: characterCount ?? this.characterCount,
      rating: rating ?? this.rating,
      usageCount: usageCount ?? this.usageCount,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isOfficial: isOfficial ?? this.isOfficial,
      isFree: isFree ?? this.isFree,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chapters: chapters ?? this.chapters,
    );
  }

  @override
  String toString() {
    return 'StoryTemplate(id: $id, title: $title, category: ${category.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoryTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 模板章节数据模型
/// 表示模板中的单个章节结构
class TemplateChapter {
  /// 章节唯一标识符
  final String id;

  /// 章节标题
  final String title;

  /// 章节描述或大纲
  final String description;

  /// 章节序号
  final int order;

  /// 章节内容提示
  final String contentHint;

  /// 推荐字数范围
  final int? minWords;
  final int? maxWords;

  /// 构造函数
  /// 所有必需参数都有明确的类型声明
  const TemplateChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.contentHint,
    this.minWords,
    this.maxWords,
  });

  /// 从JSON创建TemplateChapter对象
  /// [json] JSON格式的章节数据
  /// 返回TemplateChapter实例
  factory TemplateChapter.fromJson(Map<String, dynamic> json) {
    return TemplateChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      contentHint: json['content_hint'] as String? ?? '',
      minWords: json['min_words'] as int?,
      maxWords: json['max_words'] as int?,
    );
  }

  /// 转换为JSON格式
  /// 返回包含章节信息的Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'content_hint': contentHint,
      'min_words': minWords,
      'max_words': maxWords,
    };
  }

  /// 创建章节副本，允许修改部分属性
  /// 返回新的TemplateChapter实例
  TemplateChapter copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    String? contentHint,
    int? minWords,
    int? maxWords,
  }) {
    return TemplateChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      contentHint: contentHint ?? this.contentHint,
      minWords: minWords ?? this.minWords,
      maxWords: maxWords ?? this.maxWords,
    );
  }

  @override
  String toString() {
    return 'TemplateChapter(id: $id, title: $title, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateChapter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 模板分类枚举
/// 定义不同类型的故事模板
enum TemplateCategory {
  /// 冒险类
  adventure('adventure', '冒险'),

  /// 浪漫类
  romance('romance', '浪漫'),

  /// 悬疑类
  mystery('mystery', '悬疑'),

  /// 科幻类
  sciFi('sci_fi', '科幻'),

  /// 奇幻类
  fantasy('fantasy', '奇幻'),

  /// 现实类
  realistic('realistic', '现实'),

  /// 历史类
  historical('historical', '历史'),

  /// 喜剧类
  comedy('comedy', '喜剧'),

  /// 恐怖类
  horror('horror', '恐怖'),

  /// 其他类
  other('other', '其他');

  /// 枚举值对应的字符串
  final String value;

  /// 显示名称
  final String displayName;

  const TemplateCategory(this.value, this.displayName);

  /// 从字符串创建分类枚举
  /// [value] 分类字符串值
  /// 返回对应的TemplateCategory枚举值
  static TemplateCategory fromString(String value) {
    for (TemplateCategory category in TemplateCategory.values) {
      if (category.value == value) {
        return category;
      }
    }
    return TemplateCategory.other;
  }

  /// 获取分类对应的图标
  /// 返回Material Icons图标名称
  String get iconName {
    switch (this) {
      case TemplateCategory.adventure:
        return 'explore';
      case TemplateCategory.romance:
        return 'favorite';
      case TemplateCategory.mystery:
        return 'search';
      case TemplateCategory.sciFi:
        return 'rocket_launch';
      case TemplateCategory.fantasy:
        return 'auto_awesome';
      case TemplateCategory.realistic:
        return 'article';
      case TemplateCategory.historical:
        return 'account_balance';
      case TemplateCategory.comedy:
        return 'mood';
      case TemplateCategory.horror:
        return 'warning';
      case TemplateCategory.other:
        return 'category';
    }
  }
}
