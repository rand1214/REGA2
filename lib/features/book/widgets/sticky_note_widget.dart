import 'package:flutter/material.dart';
import '../models/book_note.dart';

class StickyNoteWidget extends StatefulWidget {
  final BookNote note;
  final BoxConstraints constraints;
  final VoidCallback onDelete;
  final Function(double xPercent, double yPercent, double size) onMoved;
  final ValueChanged<bool> onEditingChanged;

  const StickyNoteWidget({
    super.key,
    required this.note,
    required this.constraints,
    required this.onDelete,
    required this.onMoved,
    required this.onEditingChanged,
  });

  @override
  State<StickyNoteWidget> createState() => _StickyNoteWidgetState();
}

class _StickyNoteWidgetState extends State<StickyNoteWidget> {
  late double _cx;
  late double _cy;
  late double _iconSize;
  bool _isEditing = false;

  static const double _minSize = 24;
  static const double _maxSize = 64;
  static const double _pad = 16.0;
  // Extra space around frame for buttons
  static const double _btnR = 18.0; // button radius
  static const double _overflow = _btnR; // how much buttons stick out

  double _resizeStartSize = 32;
  double _resizeStartDy = 0;

  @override
  void initState() {
    super.initState();
    _iconSize = widget.note.size.clamp(_minSize, _maxSize);
    final w = widget.constraints.maxWidth;
    final h = widget.constraints.maxHeight;
    if (w.isFinite && h.isFinite && w > 0 && h > 0) {
      _cx = (widget.note.xPercent * w).clamp(_iconSize / 2, w - _iconSize / 2);
      _cy = (widget.note.yPercent * h).clamp(_iconSize / 2, h - _iconSize / 2);
    } else {
      _cx = 50;
      _cy = 50;
    }
  }

  void _confirmPosition() {
    final w = widget.constraints.maxWidth;
    final h = widget.constraints.maxHeight;
    if (!w.isFinite || !h.isFinite || w == 0 || h == 0) return;
    widget.onMoved((_cx / w).clamp(0.0, 1.0), (_cy / h).clamp(0.0, 1.0), _iconSize);
    setState(() => _isEditing = false);
    widget.onEditingChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = _iconSize + _pad * 2;
    // Total widget size includes button overflow on all sides
    final totalSize = frameSize + _overflow * 2;
    // Position so the frame is centered in the total widget
    final left = _cx - _iconSize / 2 - _pad - _overflow;
    final top = _cy - _iconSize / 2 - _pad - _overflow;

    return Positioned(
      left: left,
      top: top,
      width: totalSize,
      height: totalSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Frame — offset by _overflow to center it
          Positioned(
            left: _overflow,
            top: _overflow,
            width: frameSize,
            height: frameSize,
            child: GestureDetector(
              onTap: () { if (!_isEditing) _showNote(context); },
              onPanStart: (_) {
                setState(() => _isEditing = true);
                widget.onEditingChanged(true);
              },
              onPanUpdate: (details) {
                final w = widget.constraints.maxWidth;
                final h = widget.constraints.maxHeight;
                if (!w.isFinite || !h.isFinite) return;
                setState(() {
                  _cx = (_cx + details.delta.dx).clamp(_iconSize / 2, w - _iconSize / 2);
                  _cy = (_cy + details.delta.dy).clamp(_iconSize / 2, h - _iconSize / 2);
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_isEditing)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(widget.note.colorValue), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                          color: Color(widget.note.colorValue).withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  // Pin centered in frame
                  Positioned(
                    left: _pad, top: _pad,
                    child: Container(
                      width: _iconSize,
                      height: _iconSize,
                      decoration: BoxDecoration(
                        color: Color(widget.note.colorValue),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.sticky_note_2_rounded,
                          size: _iconSize * 0.55, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Buttons — positioned within totalSize so hit tests work
          if (_isEditing) ...[
            // Top-left: delete (at corner of frame = _overflow, _overflow)
            Positioned(
              left: _overflow - _btnR,
              top: _overflow - _btnR,
              child: _btn(
                color: Colors.red,
                icon: Icons.close,
                onTap: () {
                  widget.onEditingChanged(false);
                  widget.onDelete();
                },
              ),
            ),
            // Bottom-right: confirm
            Positioned(
              left: _overflow + frameSize - _btnR,
              top: _overflow + frameSize - _btnR,
              child: _btn(
                color: Colors.green,
                icon: Icons.check,
                onTap: _confirmPosition,
              ),
            ),
            // Bottom-left: resize
            Positioned(
              left: _overflow - _btnR,
              top: _overflow + frameSize - _btnR,
              child: GestureDetector(
                onPanStart: (d) {
                  _resizeStartSize = _iconSize;
                  _resizeStartDy = d.globalPosition.dy;
                },
                onPanUpdate: (d) {
                  final delta = d.globalPosition.dy - _resizeStartDy;
                  setState(() {
                    _iconSize = (_resizeStartSize + delta).clamp(_minSize, _maxSize);
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: _btnR * 2,
                  height: _btnR * 2,
                  child: Center(
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: Color(widget.note.colorValue),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.open_in_full_rounded, size: 11, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _btn({required Color color, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _btnR * 2,
        height: _btnR * 2,
        child: Center(
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 11, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Color(widget.note.colorValue),
        content: Text(widget.note.text,
            style: const TextStyle(fontFamily: 'Peshang', fontSize: 14, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('داخستن',
                style: TextStyle(fontFamily: 'Peshang', color: Colors.white)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); widget.onDelete(); },
            child: const Text('سڕینەوە',
                style: TextStyle(fontFamily: 'Peshang', color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
