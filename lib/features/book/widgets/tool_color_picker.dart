import 'package:flutter/material.dart';
import '../models/book_drawing.dart';

class ToolColorPicker extends StatelessWidget {
  final int selectedColor;
  final Function(int) onColorSelected;
  final String activeTool;
  final ShapeType activeShape;
  final Function(ShapeType) onShapeSelected;

  const ToolColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.activeTool,
    required this.activeShape,
    required this.onShapeSelected,
  });

  static const List<int> colors = [
    0xFFFFEB3B, // yellow
    0xFF4CAF50, // green
    0xFF2196F3, // blue
    0xFFF44336, // red
    0xFF9C27B0, // purple
    0xFFFF9800, // orange
    0xFF00BCD4, // cyan
    0xFFE91E63, // pink
    0xFF795548, // brown
    0xFF000000, // black
    0xFFFFFFFF, // white
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shape selector — only for shapes tool
        if (activeTool == 'shapes') ...[
          _shapeBtn(ShapeType.rectangle, Icons.rectangle_outlined),
          _shapeBtn(ShapeType.circle, Icons.circle_outlined),
          SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
        // Colors
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: colors.map((c) {
                  final isSelected = c == selectedColor;
                  return GestureDetector(
                    onTap: () => onColorSelected(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 24 : 18,
                      height: isSelected ? 24 : 18,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0080C8) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(c).withValues(alpha: 0.4), blurRadius: 4)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shapeBtn(ShapeType shape, IconData icon) {
    final isSelected = activeShape == shape;
    return GestureDetector(
      onTap: () => onShapeSelected(shape),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C6EA3), Color(0xFF1F5E8E)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Icon(icon, size: 18,
            color: isSelected ? Colors.white : Colors.white70),
      ),
    );
  }
}
