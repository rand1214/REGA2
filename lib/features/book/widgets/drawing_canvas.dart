import 'package:flutter/material.dart';
import '../models/book_drawing.dart';

class DrawingCanvas extends StatefulWidget {
  final String activeTool;
  final int colorValue;
  final ShapeType activeShape;
  final List<BookDrawing> drawings;
  final BoxConstraints constraints;
  final Function(BookDrawing) onDrawingComplete;
  final Function(String) onDrawingDelete;
  final Function(bool)? onEditingChanged;

  const DrawingCanvas({
    super.key,
    required this.activeTool,
    required this.colorValue,
    required this.activeShape,
    required this.drawings,
    required this.constraints,
    required this.onDrawingComplete,
    required this.onDrawingDelete,
    this.onEditingChanged,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Offset? _start;
  Offset? _current;
  List<Offset> _pencilPoints = [];

  // Editing state for newly created rect-based drawings
  BookDrawing? _editingDrawing;
  
  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update editing drawing color if color changed while editing
    if (_editingDrawing != null && oldWidget.colorValue != widget.colorValue) {
      setState(() {
        _editingDrawing = BookDrawing(
          id: _editingDrawing!.id,
          chapterId: _editingDrawing!.chapterId,
          page: _editingDrawing!.page,
          type: _editingDrawing!.type,
          colorValue: widget.colorValue,
          opacity: _editingDrawing!.opacity,
          x1Percent: _editingDrawing!.x1Percent,
          y1Percent: _editingDrawing!.y1Percent,
          x2Percent: _editingDrawing!.x2Percent,
          y2Percent: _editingDrawing!.y2Percent,
          shapeType: _editingDrawing!.shapeType,
          createdAt: _editingDrawing!.createdAt,
        );
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final w = widget.constraints.maxWidth;
    final h = widget.constraints.maxHeight;
    if (w <= 0 || h <= 0 || !w.isFinite || !h.isFinite) return const SizedBox.shrink();
    final isRectTool = widget.activeTool == 'highlight' || widget.activeTool == 'shapes';
    final isPencil = widget.activeTool == 'pencil';
    final isEraser = widget.activeTool == 'eraser';
    final isTextbox = widget.activeTool == 'textbox';

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
        // Existing drawings
        Positioned.fill(
          child: CustomPaint(
            painter: _DrawingsPainter(
              drawings: _editingDrawing != null 
                ? [...widget.drawings, _editingDrawing!]
                : widget.drawings,
              width: w,
              height: h,
              editingId: _editingDrawing?.id,
            ),
          ),
        ),

        // Eraser: tap to delete
        if (isEraser)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                for (final drawing in widget.drawings.reversed) {
                  if (_hitTest(drawing, d.localPosition, w, h)) {
                    widget.onDrawingDelete(drawing.id);
                    break;
                  }
                }
              },
            ),
          ),

        // Pencil drawing
        if (isPencil)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => setState(() {
                _start = d.localPosition;
                _pencilPoints = [d.localPosition];
              }),
              onPanUpdate: (d) => setState(() => _pencilPoints.add(d.localPosition)),
              onPanEnd: (_) {
                if (_pencilPoints.length < 2) {
                  setState(() { _pencilPoints = []; _start = null; });
                  return;
                }
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                widget.onDrawingComplete(BookDrawing(
                  id: id, chapterId: '', page: 0,
                  type: DrawingType.pencil,
                  colorValue: widget.colorValue,
                  opacity: 1.0,
                  points: _pencilPoints.map((p) => [p.dx / w, p.dy / h]).toList(),
                  createdAt: DateTime.now(),
                ));
                // Clear after a frame to avoid flicker
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) setState(() { _pencilPoints = []; _start = null; });
                });
              },
              child: Positioned.fill(
                child: CustomPaint(
                  painter: _ActiveDrawingPainter(
                    tool: 'pencil',
                    color: Color(widget.colorValue),
                    start: _start,
                    current: _current,
                    pencilPoints: _pencilPoints,
                  ),
                ),
              ),
            ),
          ),

        // Rect-based drawing (highlight / shapes)
        if (isRectTool && _editingDrawing == null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => setState(() { _start = d.localPosition; _current = d.localPosition; }),
              onPanUpdate: (d) => setState(() => _current = d.localPosition),
              onPanEnd: (_) {
                if (_start == null || _current == null) return;
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final drawing = BookDrawing(
                  id: id, chapterId: '', page: 0,
                  type: widget.activeTool == 'highlight' ? DrawingType.highlight : DrawingType.shape,
                  colorValue: widget.colorValue,
                  opacity: widget.activeTool == 'highlight' ? 0.5 : 0.15,
                  x1Percent: _start!.dx / w,
                  y1Percent: _start!.dy / h,
                  x2Percent: _current!.dx / w,
                  y2Percent: _current!.dy / h,
                  shapeType: widget.activeTool == 'shapes' ? widget.activeShape : null,
                  tipSize: 0.15,
                  createdAt: DateTime.now(),
                );
                setState(() { _editingDrawing = drawing; _start = null; _current = null; });
                widget.onEditingChanged?.call(true);
              },
              child: Positioned.fill(
                child: CustomPaint(
                  painter: _ActiveDrawingPainter(
                    tool: widget.activeTool,
                    color: Color(widget.colorValue),
                    start: _start,
                    current: _current,
                    pencilPoints: [],
                    shapeType: widget.activeShape,
                  ),
                ),
              ),
            ),
          ),

        // Editing frame for newly created rect drawing
        if (_editingDrawing != null)
          _buildEditingFrame(_editingDrawing!, w, h),

        // Textbox
        if (isTextbox)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _showTextInput(context, d.localPosition, w, h),
            ),
          ),
      ],
      ),
    );
  }

  bool _hitTest(BookDrawing d, Offset pos, double w, double h) {
    if (d.type == DrawingType.pencil) {
      for (final p in d.points) {
        final dx = p[0] * w - pos.dx;
        final dy = p[1] * h - pos.dy;
        if (dx * dx + dy * dy < 400) return true;
      }
      return false;
    }
    final rect = _drawingRect(d, w, h);
    return rect.contains(pos);
  }

  Rect _drawingRect(BookDrawing d, double w, double h) {
    return Rect.fromPoints(
      Offset(d.x1Percent * w, d.y1Percent * h),
      Offset(d.x2Percent * w, d.y2Percent * h),
    );
  }

  Widget _buildEditingFrame(BookDrawing drawing, double w, double h) {
    final x1 = drawing.x1Percent * w;
    final y1 = drawing.y1Percent * h;
    final x2 = drawing.x2Percent * w;
    final y2 = drawing.y2Percent * h;
    final left = x1 < x2 ? x1 : x2;
    final top = y1 < y2 ? y1 : y2;
    final right = x1 > x2 ? x1 : x2;
    final bottom = y1 > y2 ? y1 : y2;
    final rw = right - left;
    final rh = bottom - top;
    const overflow = 20.0;

    return Positioned(
      left: left - overflow,
      top: top - overflow,
      width: rw + overflow * 2,
      height: rh + overflow * 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          setState(() {
            _editingDrawing = BookDrawing(
              id: drawing.id, chapterId: drawing.chapterId, page: drawing.page,
              type: drawing.type, colorValue: drawing.colorValue, opacity: drawing.opacity,
              x1Percent: (_editingDrawing?.x1Percent ?? drawing.x1Percent) + d.delta.dx / w,
              y1Percent: (_editingDrawing?.y1Percent ?? drawing.y1Percent) + d.delta.dy / h,
              x2Percent: (_editingDrawing?.x2Percent ?? drawing.x2Percent) + d.delta.dx / w,
              y2Percent: (_editingDrawing?.y2Percent ?? drawing.y2Percent) + d.delta.dy / h,
              shapeType: drawing.shapeType,
              createdAt: drawing.createdAt,
            );
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Border
            Positioned(
              left: overflow, top: overflow,
              width: rw, height: rh,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(drawing.colorValue), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Delete — top left
            Positioned(
              left: overflow - 18, top: overflow - 18,
              child: _actionBtn(Colors.red, Icons.close, () {
                setState(() => _editingDrawing = null);
                widget.onEditingChanged?.call(false);
              }),
            ),
            // Confirm — bottom right
            Positioned(
              right: overflow - 18, bottom: overflow - 18,
              child: _actionBtn(Colors.green, Icons.check, () {
                final drawingToSave = _editingDrawing!;
                setState(() => _editingDrawing = null);
                widget.onEditingChanged?.call(false);
                widget.onDrawingComplete(drawingToSave);
              }),
            ),
            // Resize — bottom left corner with double arrow (same as sticky note)
            Positioned(
              left: overflow - 18, bottom: overflow - 18,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _editingDrawing = BookDrawing(
                      id: _editingDrawing!.id, chapterId: _editingDrawing!.chapterId, page: _editingDrawing!.page,
                      type: _editingDrawing!.type, colorValue: _editingDrawing!.colorValue, opacity: _editingDrawing!.opacity,
                      x1Percent: (_editingDrawing!.x1Percent + d.delta.dx / w).clamp(0.0, 1.0),
                      y1Percent: _editingDrawing!.y1Percent,
                      x2Percent: _editingDrawing!.x2Percent,
                      y2Percent: (_editingDrawing!.y2Percent + d.delta.dy / h).clamp(0.0, 1.0),
                      shapeType: _editingDrawing!.shapeType,
                      createdAt: _editingDrawing!.createdAt,
                    );
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 36, height: 36,
                  child: Center(
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: Color(_editingDrawing!.colorValue),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.open_in_full_rounded, size: 11, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36, height: 36,
        child: Center(
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showTextInput(BuildContext context, Offset pos, double w, double h) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Text', style: TextStyle(fontFamily: 'Peshang', fontSize: 14)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Type here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) { Navigator.pop(context); return; }
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final xp = pos.dx / w;
              final yp = pos.dy / h;
              widget.onDrawingComplete(BookDrawing(
                id: id, chapterId: '', page: 0,
                type: DrawingType.shape, // reuse shape type for text
                colorValue: widget.colorValue,
                opacity: 1.0,
                x1Percent: xp, y1Percent: yp,
                x2Percent: xp + 0.3, y2Percent: yp + 0.08,
                shapeType: null,
                points: [[controller.text.trim().codeUnits.first.toDouble()]],
                createdAt: DateTime.now(),
              ));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DrawingsPainter extends CustomPainter {
  final List<BookDrawing> drawings;
  final double width;
  final double height;
  final String? editingId;

  _DrawingsPainter({
    required this.drawings,
    required this.width,
    required this.height,
    this.editingId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in drawings) {
      _paintDrawing(canvas, d, width, height);
    }
  }

  void _paintDrawing(Canvas canvas, BookDrawing d, double w, double h) {
    final color = Color(d.colorValue).withValues(alpha: d.opacity);

    if (d.type == DrawingType.highlight) {
      canvas.drawRect(
        _drawingRect(d, w, h),
        Paint()..color = color,
      );
    } else if (d.type == DrawingType.pencil) {
      final paint = Paint()
        ..color = Color(d.colorValue)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (int i = 0; i < d.points.length; i++) {
        final x = d.points[i][0] * w;
        final y = d.points[i][1] * h;
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    } else if (d.type == DrawingType.shape) {
      final rect = _drawingRect(d, w, h);
      final fill = Paint()..color = Color(d.colorValue).withValues(alpha: 0.15);
      final border = Paint()..color = Color(d.colorValue)..strokeWidth = 2..style = PaintingStyle.stroke;
      if (d.shapeType == ShapeType.circle) {
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, border);
      } else {
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, border);
      }
    }
  }

  Rect _drawingRect(BookDrawing d, double w, double h) {
    return Rect.fromPoints(
      Offset(d.x1Percent * w, d.y1Percent * h),
      Offset(d.x2Percent * w, d.y2Percent * h),
    );
  }

  @override
  bool shouldRepaint(_DrawingsPainter old) => true;
}

class _ActiveDrawingPainter extends CustomPainter {
  final String tool;
  final Color color;
  final Offset? start;
  final Offset? current;
  final List<Offset> pencilPoints;
  final ShapeType shapeType;

  _ActiveDrawingPainter({
    required this.tool,
    required this.color,
    this.start,
    this.current,
    required this.pencilPoints,
    this.shapeType = ShapeType.rectangle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tool == 'pencil') {
      if (pencilPoints.isNotEmpty) {
        final paint = Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
        final path = Path()..moveTo(pencilPoints[0].dx, pencilPoints[0].dy);
        for (int i = 1; i < pencilPoints.length; i++) path.lineTo(pencilPoints[i].dx, pencilPoints[i].dy);
        canvas.drawPath(path, paint);
      }
    } else if (tool == 'shapes' && start != null && current != null) {
      final rect = Rect.fromPoints(start!, current!);
      final fill = Paint()..color = color.withValues(alpha: 0.15);
      final border = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      if (shapeType == ShapeType.circle) {
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, border);
      } else {
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, border);
      }
    } else if (tool == 'highlight' && start != null && current != null) {
      final rect = Rect.fromPoints(start!, current!);
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.35));
    }
  }

  @override
  bool shouldRepaint(_ActiveDrawingPainter old) => true;
}
