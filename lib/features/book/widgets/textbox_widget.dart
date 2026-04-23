import 'package:flutter/material.dart';
import '../models/book_textbox.dart';

class TextBoxWidget extends StatefulWidget {
  final BookTextBox textBox;
  final BoxConstraints constraints;
  final Function(BookTextBox updated) onUpdate;
  final VoidCallback onDelete;

  const TextBoxWidget({
    super.key,
    required this.textBox,
    required this.constraints,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TextBoxWidget> createState() => _TextBoxWidgetState();
}

class _TextBoxWidgetState extends State<TextBoxWidget> {
  late double _cx;
  late double _cy;
  late String _text;
  late int _textColor;
  late int _bgColor;
  late double _fontSize;
  bool _isEditing = false;
  late TextEditingController _controller;

  static const double _pad = 16.0;
  static const double _minW = 80.0;

  static const List<int> _colors = [
    0xFFFFEB3B, 0xFF4CAF50, 0xFF2196F3, 0xFFF44336,
    0xFF9C27B0, 0xFFFF9800, 0xFF000000, 0xFFFFFFFF,
  ];

  @override
  void initState() {
    super.initState();
    final w = widget.constraints.maxWidth;
    final h = widget.constraints.maxHeight;
    _cx = widget.textBox.xPercent * w;
    _cy = widget.textBox.yPercent * h;
    _text = widget.textBox.text;
    _textColor = widget.textBox.textColorValue;
    _bgColor = widget.textBox.bgColorValue;
    _fontSize = widget.textBox.fontSize;
    _controller = TextEditingController(text: _text == 'کلیک بکە بۆ نووسین' ? '' : _text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final w = widget.constraints.maxWidth;
    final h = widget.constraints.maxHeight;
    widget.onUpdate(BookTextBox(
      id: widget.textBox.id,
      chapterId: widget.textBox.chapterId,
      page: widget.textBox.page,
      xPercent: _cx / w,
      yPercent: _cy / h,
      text: _text.isEmpty ? 'کلیک بکە بۆ نووسین' : _text,
      textColorValue: _textColor,
      bgColorValue: _bgColor,
      fontSize: _fontSize,
      createdAt: widget.textBox.createdAt,
    ));
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.constraints.maxWidth;
    final h = widget.constraints.maxHeight;
    final isPlaceholder = _text == 'کلیک بکە بۆ نووسین';

    return Positioned(
      left: _cx - _pad,
      top: _cy - _pad,
      child: GestureDetector(
        onTap: () {
          setState(() => _isEditing = true);
          _showEditDialog(context);
        },
        onPanStart: (_) => setState(() => _isEditing = true),
        onPanUpdate: (d) {
          setState(() {
            _cx = (_cx + d.delta.dx).clamp(_pad, w - _pad);
            _cy = (_cy + d.delta.dy).clamp(_pad, h - _pad);
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Text box
            Container(
              constraints: BoxConstraints(minWidth: _minW, maxWidth: w * 0.6),
              padding: EdgeInsets.all(_pad / 2),
              decoration: BoxDecoration(
                color: Color(_bgColor).withValues(alpha: _bgColor == 0xFFFFFFFF ? 0.9 : 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isEditing ? const Color(0xFF0080C8) : Color(_bgColor == 0xFFFFFFFF ? 0xFF000000 : _bgColor),
                  width: _isEditing ? 1.5 : 1,
                ),
              ),
              child: Text(
                _text,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: _fontSize,
                  color: isPlaceholder
                      ? Color(_textColor).withValues(alpha: 0.4)
                      : Color(_textColor),
                  fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            // Editing buttons
            if (_isEditing) ...[
              // Delete — top left
              Positioned(
                left: -11, top: -11,
                child: _actionBtn(Colors.red, Icons.close, widget.onDelete),
              ),
              // Confirm — bottom right (approximate)
              Positioned(
                right: -11, bottom: -11,
                child: _actionBtn(Colors.green, Icons.check, _save),
              ),
            ],
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

  void _showEditDialog(BuildContext context) {
    int tempTextColor = _textColor;
    int tempBgColor = _bgColor;
    double tempFontSize = _fontSize;
    _controller.text = _text == 'کلیک بکە بۆ نووسین' ? '' : _text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text field
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 4,
                  style: TextStyle(fontFamily: 'Peshang', fontSize: 14, color: Color(tempTextColor)),
                  decoration: InputDecoration(
                    hintText: 'کلیک بکە بۆ نووسین',
                    hintStyle: const TextStyle(fontFamily: 'Peshang', color: Colors.grey),
                    filled: true,
                    fillColor: Color(tempBgColor).withValues(alpha: 0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0080C8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Font size
                Row(
                  children: [
                    const Text('Size:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: tempFontSize,
                        min: 10, max: 28,
                        divisions: 18,
                        activeColor: const Color(0xFF0080C8),
                        onChanged: (v) => setModalState(() => tempFontSize = v),
                      ),
                    ),
                    Text('${tempFontSize.round()}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                // Text color
                Row(
                  children: [
                    const Text('Text:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    ..._colors.map((c) => GestureDetector(
                      onTap: () => setModalState(() => tempTextColor = c),
                      child: Container(
                        width: tempTextColor == c ? 24 : 18,
                        height: tempTextColor == c ? 24 : 18,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempTextColor == c ? const Color(0xFF0080C8) : Colors.grey.shade300,
                            width: tempTextColor == c ? 2 : 1,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                // BG color
                Row(
                  children: [
                    const Text('BG:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    ..._colors.map((c) => GestureDetector(
                      onTap: () => setModalState(() => tempBgColor = c),
                      child: Container(
                        width: tempBgColor == c ? 24 : 18,
                        height: tempBgColor == c ? 24 : 18,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempBgColor == c ? const Color(0xFF0080C8) : Colors.grey.shade300,
                            width: tempBgColor == c ? 2 : 1,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _text = _controller.text.trim().isEmpty ? 'کلیک بکە بۆ نووسین' : _controller.text.trim();
                        _textColor = tempTextColor;
                        _bgColor = tempBgColor;
                        _fontSize = tempFontSize;
                      });
                      Navigator.pop(ctx);
                      _save();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0080C8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('پاشەکەوتکردن', style: TextStyle(fontFamily: 'Peshang', color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => setState(() => _isEditing = false));
  }
}
