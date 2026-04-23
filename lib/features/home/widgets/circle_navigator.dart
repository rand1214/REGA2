import 'package:flutter/material.dart';
import '../models/chapter_model.dart';

class CircleNavigator extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(int, String) onChapterSelected;
  final Function(bool)? onScrollAtEnd;

  const CircleNavigator({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
    this.onScrollAtEnd,
  });

  @override
  State<CircleNavigator> createState() => _CircleNavigatorState();
}

class _CircleNavigatorState extends State<CircleNavigator> {
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted &&
            _scrollController.hasClients &&
            widget.chapters.isNotEmpty) {
          _scrollController.jumpTo(0.0);
        }
      });
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isAtEnd = _scrollController.offset >= _scrollController.position.maxScrollExtent - 1;
    widget.onScrollAtEnd?.call(isAtEnd);
  }

  @override
  void didUpdateWidget(CircleNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear color cache if chapters changed
    if (oldWidget.chapters != widget.chapters) {
      _colorCache.clear();
      // Validate selectedIndex against new chapters list
      if (selectedIndex >= widget.chapters.length) {
        selectedIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _colorCache.clear();
    super.dispose();
  }

  void _scrollToIndex(int index, double scale) {
    if (!_scrollController.hasClients || widget.chapters.isEmpty) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const double itemWidth = 86.0;
    final scaledItemWidth = itemWidth * scale;
    final horizontalPadding = 20.0 * scale;

    final itemPosition = index * scaledItemWidth;
    final centerOffset =
        itemPosition - (screenWidth / 2) + (scaledItemWidth / 2) + horizontalPadding;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = centerOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onChapterTap(int index) {
    // Validate index is within bounds
    if (index < 0 || index >= widget.chapters.length) return;
    if (widget.chapters[index].isLocked) return;
    setState(() { selectedIndex = index; });
    final scale = (MediaQuery.of(context).size.width / 375).clamp(0.8, 1.5);
    _scrollToIndex(index, scale);
    widget.onChapterSelected(index, widget.chapters[index].largeTitle);
  }

  Color _parseColor(String hexColor) {
    if (_colorCache.containsKey(hexColor)) {
      return _colorCache[hexColor]!;
    }
    try {
      final hex = hexColor.replaceAll('#', '');
      final color = Color(int.parse('FF$hex', radix: 16));
      _colorCache[hexColor] = color;
      return color;
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildChapterIcon(String iconPath, double scale) {
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      return Image.network(
        iconPath,
        width: 32 * scale, height: 32 * scale, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 32 * scale, color: Colors.grey),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 32 * scale, height: 32 * scale,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        iconPath,
        width: 32 * scale, height: 32 * scale, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 32 * scale, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    // Show empty state if no chapters
    if (widget.chapters.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 40 * scale),
        child: Center(
          child: Text(
            'هیچ بەشێک نییە',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 16 * scale,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRect(
          clipper: _LeftOnlyClipper(),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: 8 * scale),
            clipBehavior: Clip.none,
            child: Row(
            children: List.generate(
              widget.chapters.length,
              (index) {
                final chapter = widget.chapters[index];
                final isSelected = selectedIndex == index;

                return SizedBox(
                    width: 86 * scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _onChapterTap(index),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(5 * scale, 0, 5 * scale, 0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  painter: _NotchedCirclePainter(
                                    isSelected: isSelected,
                                    hasNotch: chapter.isLocked,
                                    scale: scale,
                                    bgColor: Color(int.parse('FF${chapter.color.replaceAll('#', '')}', radix: 16)).withValues(alpha: 0.15),
                                    shadowColor: isSelected ? _parseColor(chapter.color) : Colors.black,
                                  ),
                                  child: SizedBox(
                                    width: 66 * scale,
                                    height: 66 * scale,
                                    child: ClipOval(
                                      child: Center(
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            _parseColor(chapter.color),
                                            BlendMode.srcIn,
                                          ),
                                          child: _buildChapterIcon(chapter.iconPath, scale),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (chapter.isLocked)
                                  Positioned(
                                    top: -8 * scale,
                                    left: -2 * scale,
                                    child: _LockedChapterOverlay(scale: scale, chapterColor: _parseColor(chapter.color)),
                                  )
                                else if (isSelected)
                                  Positioned(
                                    top: -8 * scale,
                                    left: -2 * scale,
                                    child: _LockedChapterOverlay(scale: scale, isSelected: true, chapterColor: _parseColor(chapter.color)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 5 * scale),
                        SizedBox(
                          height: 36 * scale,
                          child: Align(
                            alignment: Alignment(0, -0.7),
                            child: Text(
                              chapter.circleTitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w600,
                                color: chapter.isLocked
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftOnlyClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // Clip only the left edge; allow overflow on right, top, and bottom
    return Rect.fromLTWH(0, -size.height, size.width, size.height * 3);
  }

  @override
  bool shouldReclip(_LeftOnlyClipper oldClipper) => false;
}

class _LockedChapterOverlay extends StatelessWidget {
  final double scale;
  final bool isSelected;
  final Color? chapterColor;

  const _LockedChapterOverlay({required this.scale, this.isSelected = false, this.chapterColor});

  @override
  Widget build(BuildContext context) {
    final double size = 22 * scale;
    final double iconSize = size * 0.6;

    final List<Color> gradientColors = [chapterColor ?? const Color(0xFF3D82B8), (chapterColor ?? const Color(0xFF2C6EA3)).withValues(alpha: 0.8)];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Icon(
        isSelected ? Icons.check : Icons.lock,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class _NotchedCirclePainter extends CustomPainter {
  final bool isSelected;
  final bool hasNotch;
  final double scale;
  final Color bgColor;
  final Color shadowColor;

  _NotchedCirclePainter({
    required this.isSelected,
    required this.hasNotch,
    required this.scale,
    this.bgColor = const Color(0xFFF1F1F1),
    this.shadowColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset center = Offset(r, r);
    final double badgeR = 11.0 * scale;
    final Offset leftNotchCenter = Offset(9 * scale, 3 * scale);

    canvas.drawCircle(
      center + Offset(0, 2 * scale),
      r,
      Paint()
        ..color = shadowColor.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale),
    );

    Path path = Path()..addOval(Rect.fromCircle(center: center, radius: r));

    if (hasNotch || isSelected) {
      final notchPath = Path()
        ..addOval(Rect.fromCircle(center: leftNotchCenter, radius: badgeR + 2 * scale));
      path = Path.combine(PathOperation.difference, path, notchPath);
    }

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bgColor, bgColor.withValues(alpha: 0.8)],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NotchedCirclePainter old) =>
      old.isSelected != isSelected || old.hasNotch != hasNotch || old.bgColor != bgColor || old.shadowColor != shadowColor;
}
