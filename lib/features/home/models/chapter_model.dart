import '../config/chapters_config.dart';

class Chapter {
  final int id;
  final String circleTitle; // From database (can have line breaks for circles 4,6,9,11)
  final String largeTitle; // Hardcoded from config (no line breaks, for display above description)
  final String description; // Hardcoded from config
  final String color; // Hardcoded from config
  final String iconPath; // Hardcoded from config
  final int order; // From database
  final bool isLocked;
  final bool requiresSubscription; // From database
  final String videoUrl; // From database
  final String videoThumbnailUrl; // From database
  final String videoTitle; // Hardcoded from config
  final bool videoWatched; // From user progress
  final int videoWatchProgress; // From user progress

  Chapter({
    required this.id,
    required this.circleTitle,
    required this.largeTitle,
    required this.description,
    required this.color,
    required this.iconPath,
    required this.order,
    required this.isLocked,
    required this.requiresSubscription,
    required this.videoUrl,
    required this.videoThumbnailUrl,
    required this.videoTitle,
    this.videoWatched = false,
    this.videoWatchProgress = 0,
  });

  // Factory constructor to create Chapter from Supabase JSON + hardcoded config
  factory Chapter.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as int;
    final config = ChaptersConfig.getByOrder(order);

    // If no config found, use defaults
    final largeTitle = config?.title ?? ''; // Hardcoded without line breaks
    final description = config?.description ?? '';
    final color = config?.color ?? '#000000';
    final iconPath = config?.iconPath ?? '';
    final videoTitle = config?.videoTitle ?? '';

    return Chapter(
      id: json['id'] as int,
      circleTitle: json['title'] as String, // From database (can have line breaks)
      largeTitle: largeTitle, // From hardcoded config (no line breaks)
      description: description, // From hardcoded config
      color: color, // From hardcoded config
      iconPath: iconPath, // From hardcoded config
      order: order, // From database
      isLocked: json['is_locked'] as bool? ?? false,
      requiresSubscription: json['requires_subscription'] as bool? ?? false,
      videoUrl: json['video_url'] as String? ?? '',
      videoThumbnailUrl: json['video_thumbnail_url'] as String? ?? '', // From database
      videoTitle: videoTitle, // From hardcoded config
      videoWatched: json['video_watched'] as bool? ?? false,
      videoWatchProgress: json['video_watch_progress'] as int? ?? 0,
    );
  }

  // Convert Chapter to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': circleTitle,
      'order': order,
      'is_locked': isLocked,
      'requires_subscription': requiresSubscription,
      'video_url': videoUrl,
      'video_watched': videoWatched,
      'video_watch_progress': videoWatchProgress,
    };
  }

  // Helper method to create a copy with updated fields
  Chapter copyWith({
    int? id,
    String? circleTitle,
    String? largeTitle,
    String? description,
    String? color,
    String? iconPath,
    int? order,
    bool? isLocked,
    bool? requiresSubscription,
    String? videoUrl,
    String? videoThumbnailUrl,
    String? videoTitle,
    bool? videoWatched,
    int? videoWatchProgress,
  }) {
    return Chapter(
      id: id ?? this.id,
      circleTitle: circleTitle ?? this.circleTitle,
      largeTitle: largeTitle ?? this.largeTitle,
      description: description ?? this.description,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
      order: order ?? this.order,
      isLocked: isLocked ?? this.isLocked,
      requiresSubscription: requiresSubscription ?? this.requiresSubscription,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      videoTitle: videoTitle ?? this.videoTitle,
      videoWatched: videoWatched ?? this.videoWatched,
      videoWatchProgress: videoWatchProgress ?? this.videoWatchProgress,
    );
  }
}
