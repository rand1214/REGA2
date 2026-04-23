class BookTextBox {
  final String id;
  final String chapterId;
  final int page;
  final double xPercent;
  final double yPercent;
  final String text;
  final int textColorValue;
  final int bgColorValue;
  final double fontSize;
  final DateTime createdAt;

  BookTextBox({
    required this.id,
    required this.chapterId,
    required this.page,
    required this.xPercent,
    required this.yPercent,
    required this.text,
    required this.textColorValue,
    required this.bgColorValue,
    this.fontSize = 14,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'page': page,
    'xPercent': xPercent,
    'yPercent': yPercent,
    'text': text,
    'textColorValue': textColorValue,
    'bgColorValue': bgColorValue,
    'fontSize': fontSize,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookTextBox.fromJson(Map<String, dynamic> json) => BookTextBox(
    id: json['id'] as String,
    chapterId: json['chapterId'] as String,
    page: json['page'] as int,
    xPercent: (json['xPercent'] as num).toDouble(),
    yPercent: (json['yPercent'] as num).toDouble(),
    text: json['text'] as String,
    textColorValue: json['textColorValue'] as int,
    bgColorValue: json['bgColorValue'] as int,
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
