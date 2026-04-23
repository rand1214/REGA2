import 'chapters_config.dart';

class Chapter {
  final int id;
  final String circleTitle;
  final String largeTitle;
  final String description;
  final String color;
  final String iconPath;
  final int order;
  final bool isLocked;
  final String videoUrl;
  final String videoThumbnailUrl;
  final String videoTitle;

  Chapter({
    required this.id,
    required this.circleTitle,
    required this.largeTitle,
    required this.description,
    required this.color,
    required this.iconPath,
    required this.order,
    required this.isLocked,
    required this.videoUrl,
    required this.videoThumbnailUrl,
    required this.videoTitle,
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
      circleTitle: json['title'] as String,
      largeTitle: largeTitle,
      description: description,
      color: color,
      iconPath: iconPath,
      order: order,
      isLocked: json['is_locked'] as bool? ?? true,
      videoUrl: json['video_url'] as String? ?? '',
      videoThumbnailUrl: json['video_thumbnail_url'] as String? ?? '',
      videoTitle: videoTitle,
    );
  }

}
