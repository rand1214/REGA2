import 'package:flutter/material.dart';
import 'dart:ui';

class VideoSection extends StatelessWidget {
  final String videoThumbnailUrl;
  final String videoTitle;
  final VoidCallback? onVideoTap;

  const VideoSection({
    super.key,
    required this.videoThumbnailUrl,
    required this.videoTitle,
    required this.onVideoTap,
  });

  Widget _buildFallbackThumbnail(double scale) {
    return Image.asset(
      'assets/images/video-thumbnail.png',
      width: double.infinity,
      height: 200 * scale,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade300,
        width: double.infinity,
        height: 200 * scale,
        child: Icon(Icons.video_library, size: 60 * scale, color: Colors.grey.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * scale, 0, 20 * scale, 10 * scale),
      child: Container(
        height: 200 * scale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: Offset(0, 2 * scale),
              blurRadius: 8 * scale,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16 * scale),
          child: Stack(
            alignment: Alignment.center,
            children: [
              videoThumbnailUrl.isNotEmpty
                  ? Image.network(
                      videoThumbnailUrl,
                      width: double.infinity,
                      height: 200 * scale,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackThumbnail(scale),
                    )
                  : _buildFallbackThumbnail(scale),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3 * scale, sigmaY: 3 * scale),
                child: Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3))),
              ),
              if (videoTitle.isNotEmpty)
                Positioned(
                  top: 16 * scale,
                  right: 16 * scale,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 5 * scale),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6 * scale),
                    ),
                    child: Text(videoTitle,
                        style: TextStyle(fontFamily: 'Peshang', fontSize: 12 * scale, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              GestureDetector(
                onTap: onVideoTap,
                child: Container(
                  width: 60 * scale,
                  height: 60 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.35), offset: Offset(0, 6 * scale), blurRadius: 16 * scale, spreadRadius: -2 * scale),
                    ],
                  ),
                  child: Icon(Icons.play_arrow_rounded, size: 38 * scale, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
