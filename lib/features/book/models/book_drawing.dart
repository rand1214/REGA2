enum DrawingType { highlight, pencil, shape }
enum ShapeType { rectangle, circle }

class BookDrawing {
  final String id;
  final String chapterId;
  final int page;
  final DrawingType type;
  final int colorValue;
  final double opacity;
  // For highlight & shape: bounding rect as percentages
  final double x1Percent;
  final double y1Percent;
  final double x2Percent;
  final double y2Percent;
  // For pencil: list of points as percentages
  final List<List<double>> points; // [[x%, y%], ...]
  // For shape type
  final ShapeType? shapeType;
  // For arrow: tip size as percentage of arrow length
  final double tipSize;
  final DateTime createdAt;

  BookDrawing({
    required this.id,
    required this.chapterId,
    required this.page,
    required this.type,
    required this.colorValue,
    this.opacity = 0.4,
    this.x1Percent = 0,
    this.y1Percent = 0,
    this.x2Percent = 0,
    this.y2Percent = 0,
    this.points = const [],
    this.shapeType,
    this.tipSize = 0.15,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'page': page,
    'type': type.index,
    'colorValue': colorValue,
    'opacity': opacity,
    'x1Percent': x1Percent,
    'y1Percent': y1Percent,
    'x2Percent': x2Percent,
    'y2Percent': y2Percent,
    'points': points,
    'shapeType': shapeType?.index,
    'tipSize': tipSize,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookDrawing.fromJson(Map<String, dynamic> json) => BookDrawing(
    id: json['id'] as String,
    chapterId: json['chapterId'] as String,
    page: json['page'] as int,
    type: DrawingType.values[json['type'] as int],
    colorValue: json['colorValue'] as int,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 0.4,
    x1Percent: (json['x1Percent'] as num?)?.toDouble() ?? 0,
    y1Percent: (json['y1Percent'] as num?)?.toDouble() ?? 0,
    x2Percent: (json['x2Percent'] as num?)?.toDouble() ?? 0,
    y2Percent: (json['y2Percent'] as num?)?.toDouble() ?? 0,
    points: (json['points'] as List?)
        ?.map((p) => (p as List).map((v) => (v as num).toDouble()).toList())
        .toList() ?? [],
    shapeType: json['shapeType'] != null
        ? _parseShapeType(json['shapeType'] as int)
        : null,
    tipSize: (json['tipSize'] as num?)?.toDouble() ?? 0.15,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  static ShapeType? _parseShapeType(int index) {
    if (index < 0 || index >= ShapeType.values.length) {
      return ShapeType.rectangle; // Default to rectangle for invalid indices
    }
    return ShapeType.values[index];
  }
}
