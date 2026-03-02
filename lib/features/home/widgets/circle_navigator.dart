import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/chapter_model.dart';

class CircleNavigator extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(int, String) onChapterSelected;

  const CircleNavigator({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
  });

  @override
  State<CircleNavigator> createState() => _CircleNavigatorState();
}

class _CircleNavigatorState extends State<CircleNavigator> {
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to show the first chapter (rightmost in RTL) after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure layout is fully complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients && widget.chapters.isNotEmpty) {
          // In RTL with Directionality, position 0.0 is the start (right side)
          // This shows the first chapter on the right
          _scrollController.jumpTo(0.0);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _getItemWidth(double scale) {
    // Circle width (70) + padding (12) = 82
    return (70 * scale) + (12 * scale);
  }

  void _scrollToIndex(int index, double scale) {
    if (!_scrollController.hasClients || widget.chapters.isEmpty) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = _getItemWidth(scale);
    final horizontalPadding = 20.0 * scale;

    final itemPosition = index * itemWidth;
    final centerOffset = itemPosition - (screenWidth / 2) + (itemWidth / 2) + horizontalPadding;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = centerOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onChapterTap(int index) {
    // Don't allow selection of locked chapters
    if (widget.chapters[index].isLocked) return;

    setState(() {
      selectedIndex = index;
    });

    final scale = (MediaQuery.of(context).size.width / 375).clamp(0.8, 1.5);
    _scrollToIndex(index, scale);

    widget.onChapterSelected(index, widget.chapters[index].largeTitle);
  }

  Color _parseColor(String hexColor) {
    // Convert hex string like "#B7D63E" to Color
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Widget _buildChapterIcon(String iconPath, double scale) {
    // Check if it's a URL or asset path
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      // It's a URL, use Image.network
      return Image.network(
        iconPath,
        width: 32 * scale,
        height: 32 * scale,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback icon if network image fails
          return Icon(
            Icons.image_not_supported,
            size: 32 * scale,
            color: Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 32 * scale,
            height: 32 * scale,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // It's an asset path, use Image.asset
      return Image.asset(
        iconPath,
        width: 32 * scale,
        height: 32 * scale,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback icon if asset fails
          return Icon(
            Icons.image_not_supported,
            size: 32 * scale,
            color: Colors.grey,
          );
        },
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

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20 * scale),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
          child: Row(
            children: List.generate(
              widget.chapters.length,
              (index) {
                final chapter = widget.chapters[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: EdgeInsets.only(right: 12 * scale),
                  child: SizedBox(
                    width: 70 * scale, // Fixed width to ensure consistent spacing
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _onChapterTap(index),
                          child: Stack(
                            children: [
                              Container(
                                width: 70 * scale,
                                height: 70 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF1F1F1),
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.grey.shade300,
                                    width: isSelected ? 3 * scale : 2 * scale,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      offset: Offset(0, 2 * scale),
                                      blurRadius: 6 * scale,
                                    ),
                                  ],
                                ),
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
                              // Lock overlay
                              if (chapter.isLocked)
                                _LockedChapterOverlay(scale: scale),
                            ],
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        SizedBox(
                          height: 40 * scale,
                          child: Text(
                            chapter.circleTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: chapter.isLocked 
                                  ? Colors.grey.shade400 
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
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


// Separate widget for locked chapter overlay with Lottie animation
class _LockedChapterOverlay extends StatefulWidget {
  final double scale;

  const _LockedChapterOverlay({required this.scale});

  @override
  State<_LockedChapterOverlay> createState() => _LockedChapterOverlayState();
}

class _LockedChapterOverlayState extends State<_LockedChapterOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _lockController;

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70 * widget.scale,
      height: 70 * widget.scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
      ),
      padding: EdgeInsets.all(15 * widget.scale),
      child: Lottie.asset(
        'assets/icons/Lock.json',
        fit: BoxFit.contain,
        controller: _lockController,
        onLoaded: (composition) {
          _lockController.duration = composition.duration;
          // Set to frame 1 (value 0.0 is frame 0, so we need a tiny value for frame 1)
          _lockController.value = 1.0 / composition.duration.inMilliseconds;
        },
        repeat: false,
      ),
    );
  }
}
