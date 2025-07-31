/// 音频内容数据模型
/// 用于FM电台、播客等音频内容
class AudioContent {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String cover; // emoji或图片URL
  final Duration duration;
  final String category;
  final String description;
  final int? playCount;
  final int? likeCount;
  final DateTime? publishTime;
  final String? audioUrl;
  final List<String>? tags;
  
  AudioContent({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.cover,
    required this.duration,
    required this.category,
    required this.description,
    this.playCount,
    this.likeCount,
    this.publishTime,
    this.audioUrl,
    this.tags,
  });

  /// 从JSON创建AudioContent实例
  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      cover: json['cover'] as String,
      duration: Duration(milliseconds: json['duration_ms'] as int),
      category: json['category'] as String,
      description: json['description'] as String,
      playCount: json['play_count'] as int?,
      likeCount: json['like_count'] as int?,
      publishTime: json['publish_time'] != null 
          ? DateTime.parse(json['publish_time'] as String)
          : null,
      audioUrl: json['audio_url'] as String?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'cover': cover,
      'duration_ms': duration.inMilliseconds,
      'category': category,
      'description': description,
      'play_count': playCount,
      'like_count': likeCount,
      'publish_time': publishTime?.toIso8601String(),
      'audio_url': audioUrl,
      'tags': tags,
    };
  }

  /// 创建副本并修改部分属性
  AudioContent copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? cover,
    Duration? duration,
    String? category,
    String? description,
    int? playCount,
    int? likeCount,
    DateTime? publishTime,
    String? audioUrl,
    List<String>? tags,
  }) {
    return AudioContent(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      cover: cover ?? this.cover,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      description: description ?? this.description,
      playCount: playCount ?? this.playCount,
      likeCount: likeCount ?? this.likeCount,
      publishTime: publishTime ?? this.publishTime,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'AudioContent(id: $id, title: $title, artist: $artist, duration: ${duration.inMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioContent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}