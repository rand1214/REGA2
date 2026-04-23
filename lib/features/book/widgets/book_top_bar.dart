import 'package:flutter/material.dart';
import '../../../core/services/book_service.dart';
import '../models/book_drawing.dart';
import 'tool_color_picker.dart';

class BookTopBar extends StatelessWidget {
  final double scale;
  final List<BookChapter> chapters;
  final int selectedIndex;
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final String activeTool;
  final int activeColor;
  final ShapeType activeShape;
  final Function(int) onChapterSelected;
  final VoidCallback onBookmarkTap;
  final VoidCallback onBookmarkListTap;
  final VoidCallback onAddNoteTap;
  final Function(String) onToolSelected;
  final Function(int) onColorSelected;
  final Function(ShapeType) onShapeSelected;

  const BookTopBar({
    super.key,
    required this.scale,
    required this.chapters,
    required this.selectedIndex,
    required this.currentPage,
    required this.totalPages,
    required this.isBookmarked,
    required this.onChapterSelected,
    required this.onBookmarkTap,
    required this.onBookmarkListTap,
    required this.onAddNoteTap,
    required this.activeTool,
    required this.activeColor,
    required this.activeShape,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onShapeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E7BBF), Color(0xFF0E5A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20 * s),
          bottomRight: Radius.circular(20 * s),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B8C).withValues(alpha: 0.3),
            blurRadius: 20 * s,
            offset: Offset(0, 8 * s),
            spreadRadius: -4 * s,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20 * s),
                bottomRight: Radius.circular(20 * s),
              ),
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/icons/blue-traffic-pattern-for-bg.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          // Glow circle
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 14 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _iconBtn(Icons.bookmarks_rounded, scale, onBookmarkListTap),
                      SizedBox(width: 8 * scale),
                      _iconBtn(Icons.sticky_note_2_rounded, scale, onAddNoteTap),
                      const Spacer(),
                      Text(
                        '$currentPage / $totalPages',
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 12 * scale,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      _iconBtn(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        scale,
                        onBookmarkTap,
                        color: isBookmarked ? Colors.amber : Colors.white,
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  // Divider
                  Container(
                    height: 1 * scale,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  // Tool icons row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _toolIconImage('assets/icons/marker-pen.png', 'highlight', scale),
                        SizedBox(width: 6 * scale),
                        _toolIcon(Icons.edit_rounded, 'pencil', scale),
                        SizedBox(width: 6 * scale),
                        _toolIcon(Icons.category_rounded, 'shapes', scale),
                        SizedBox(width: 6 * scale),
                        _toolIcon(Icons.text_fields_rounded, 'textbox', scale),
                        SizedBox(width: 6 * scale),
                        _toolIcon(Icons.auto_fix_high_rounded, 'eraser', scale),
                        SizedBox(width: 6 * scale),
                        _toolIcon(Icons.sticky_note_2_rounded, 'note', scale),
                      ],
                    ),
                  ),
                  // Color picker
                  if (['highlight', 'pencil', 'shapes', 'textbox'].contains(activeTool))
                    Padding(
                      padding: EdgeInsets.only(top: 8 * scale),
                      child: Center(
                        child: ToolColorPicker(
                          selectedColor: activeColor,
                          onColorSelected: (c) => onColorSelected(c),
                          activeTool: activeTool,
                          activeShape: activeShape,
                          onShapeSelected: (s) => onShapeSelected(s),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolIcon(IconData icon, String toolId, double s) {
    final isActive = activeTool == toolId;
    final labels = {
      'highlight': 'ق.دیاریکردن',
      'pencil': 'قەڵەم',
      'shapes': 'شێوە',
      'textbox': 'نووسین',
      'eraser': 'سڕینەوە',
      'note': 'تێبینی',
    };
    return GestureDetector(
      onTap: () {
        if (toolId == 'sticky') {
          onAddNoteTap();
        } else {
          onToolSelected(isActive ? 'none' : toolId);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Icon(
              icon,
              size: 18 * s,
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            labels[toolId] ?? '',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 8 * s,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolIconImage(String imagePath, String toolId, double s) {
    final isActive = activeTool == toolId;
    final labels = {
      'highlight': 'ق.دیاریکردن',
      'pencil': 'قەڵەم',
      'shapes': 'شێوە',
      'textbox': 'نووسین',
      'eraser': 'سڕینەوە',
      'note': 'تێبینی',
    };
    return GestureDetector(
      onTap: () {
        onToolSelected(isActive ? 'none' : toolId);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isActive ? Colors.white : Colors.white70,
                BlendMode.srcIn,
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 2 * s),
                child: Image.asset(
                  imagePath,
                  width: 16 * s,
                  height: 16 * s,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            labels[toolId] ?? '',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 8 * s,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, double s, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38 * s,
        height: 38 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * s),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C6EA3), Color(0xFF1F5E8E)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12 * s,
              offset: Offset(0, 4 * s),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 18 * s),
      ),
    );
  }
}
