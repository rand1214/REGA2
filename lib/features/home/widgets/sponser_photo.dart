import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sponser_model.dart';

class SponserPhoto extends StatefulWidget {
  final List<SponserModel> sponsors;
  const SponserPhoto({super.key, required this.sponsors});

  @override
  State<SponserPhoto> createState() => _SponserPhotoState();
}

class _SponserPhotoState extends State<SponserPhoto> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.sponsors.length > 1) { _startAutoPlay(); }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final s in widget.sponsors) {
        precacheImage(NetworkImage(s.imageUrl), context);
      }
    });
  }

  @override
  void didUpdateWidget(SponserPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart carousel if sponsors list changed (length or content)
    if (oldWidget.sponsors.length != widget.sponsors.length ||
        (oldWidget.sponsors.isNotEmpty && widget.sponsors.isNotEmpty &&
         oldWidget.sponsors.first.id != widget.sponsors.first.id)) {
      _currentPage = 0;
      if (widget.sponsors.length > 1) {
        _startAutoPlay();
      } else {
        _stopAutoPlay();
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.sponsors.isEmpty) return;

    // Use _currentPage directly (updated via onPageChanged) instead of _pageController.page
    // which can be a fractional value during scroll and cause incorrect index rounding
    final currentSponsor = widget.sponsors[_currentPage % widget.sponsors.length];
    // Clamp displayDuration to minimum 1 second to prevent infinite loops
    final displayDuration = Duration(seconds: currentSponsor.displayDuration.clamp(1, 3600));

    _autoPlayTimer = Timer(displayDuration, () {
      if (!_pageController.hasClients || widget.sponsors.isEmpty) return;
      // Recompute nextPage inside callback to handle sponsor list changes during animation
      final nextPage = (_currentPage + 1) % widget.sponsors.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      ).then((_) => _startAutoPlay());
    });
  }

  void _stopAutoPlay() => _autoPlayTimer?.cancel();

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sponsors.isEmpty) return const SizedBox.shrink();

    final n = widget.sponsors.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 10 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16 * scale),
            child: SizedBox(
              height: 150 * scale,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) { _stopAutoPlay(); }
                  else if (notification is ScrollEndNotification && n > 1) { _startAutoPlay(); }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: n,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final imageUrl = widget.sponsors[index].imageUrl;
                    if (imageUrl.isEmpty) {
                      return Container(
                        color: Colors.white,
                        child: Center(child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400, size: 32 * scale)),
                      );
                    }
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(color: Colors.white,
                          child: const Center(child: CircularProgressIndicator(
                              color: Color(0xFF0080C8), strokeWidth: 2)));
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: Center(child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400, size: 32 * scale)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (n > 1) ...[
            SizedBox(height: 10 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(n, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isActive
                        ? const Color(0xFF0E5A8A)
                        : const Color.fromRGBO(14, 90, 138, 0.25),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
