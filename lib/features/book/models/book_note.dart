class BookNote {
  final String id;
  final String chapterId;
  final int page;
  final double xPercent;
  final double yPercent;
  final String text;
  final int colorValue;
  final double size;
  final DateTime createdAt;

  BookNote({
    required this.id,
    required this.chapterId,
    required this.page,
    required this.xPercent,
    required this.yPercent,
    required this.text,
    required this.colorValue,
    this.size = 32,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'page': page,
    'xPercent': xPercent,
    'yPercent': yPercent,
    'text': text,
    'colorValue': colorValue,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookNote.fromJson(Map<String, dynamic> json) => BookNote(
    id: json['id'] as String,
    chapterId: json['chapterId'] as String,
    page: json['page'] as int,
    xPercent: (json['xPercent'] as num).toDouble(),
    yPercent: (json['yPercent'] as num).toDouble(),
    text: json['text'] as String,
    colorValue: json['colorValue'] as int,
    size: (json['size'] as num?)?.toDouble() ?? 32,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
