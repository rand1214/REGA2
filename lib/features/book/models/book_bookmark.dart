class BookBookmark {
  final String id;
  final String chapterId;
  final int page;
  final String label;
  final DateTime createdAt;

  BookBookmark({
    required this.id,
    required this.chapterId,
    required this.page,
    required this.label,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'page': page,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookBookmark.fromJson(Map<String, dynamic> json) => BookBookmark(
    id: json['id'] as String,
    chapterId: json['chapterId'] as String,
    page: json['page'] as int,
    label: json['label'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
