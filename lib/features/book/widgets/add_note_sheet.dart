import 'package:flutter/material.dart';

class AddNoteSheet extends StatefulWidget {
  final Function(String text, Color color) onSave;

  const AddNoteSheet({super.key, required this.onSave});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _controller = TextEditingController();
  Color _selectedColor = const Color(0xFFF59E0B);

  final List<Color> _colors = [
    const Color(0xFFF59E0B), // amber
    const Color(0xFF10B981), // green
    const Color(0xFF3B82F6), // blue
    const Color(0xFFEF4444), // red
    const Color(0xFF8B5CF6), // purple
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تێبینی زیادبکە',
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 12 * scale),
              TextField(
                controller: _controller,
                maxLines: 4,
                autofocus: true,
                style: TextStyle(fontFamily: 'Peshang', fontSize: 14 * scale),
                decoration: InputDecoration(
                  hintText: 'تێبینیەکەت بنووسە...',
                  hintStyle: TextStyle(fontFamily: 'Peshang', color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * scale)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                    borderSide: const BorderSide(color: Color(0xFF0080C8)),
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Row(
                children: [
                  Text('ڕەنگ:', style: TextStyle(fontFamily: 'Peshang', fontSize: 13 * scale)),
                  SizedBox(width: 8 * scale),
                  ..._colors.map((c) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 28 * scale,
                      height: 28 * scale,
                      margin: EdgeInsets.only(left: 6 * scale),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColor == c
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  )),
                ],
              ),
              SizedBox(height: 16 * scale),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSave(_controller.text.trim(), _selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0080C8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scale)),
                    padding: EdgeInsets.symmetric(vertical: 14 * scale),
                  ),
                  child: Text(
                    'پاشەکەوتکردن',
                    style: TextStyle(fontFamily: 'Peshang', fontSize: 14 * scale, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
