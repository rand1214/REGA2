import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/utils/url_launcher_helper.dart';

class ContentSection extends StatelessWidget {
  final String title;
  final String description;
  final String videoThumbnailUrl;
  final String videoTitle;
  final String videoUrl; // YouTube URL
  final VoidCallback? onVideoTap; // Optional custom callback

  const ContentSection({
    super.key,
    required this.title,
    required this.description,
    required this.videoThumbnailUrl,
    required this.videoTitle,
    required this.videoUrl,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Padding(
      padding: EdgeInsets.only(
        left: 20 * scale,
        right: 20 * scale,
        top: 0,
        bottom: 10 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chapter title
          Padding(
            padding: EdgeInsets.only(right: 10 * scale),
            child: Text(
              title,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 24 * scale,
                fontWeight: FontWeight.w900,
                height: 1.5,
                color: Colors.black,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: Offset(2 * scale, 2 * scale),
                    blurRadius: 4 * scale,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          // Description container
          Container(
            padding: EdgeInsets.all(20 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: Offset(0, 2 * scale),
                  blurRadius: 8 * scale,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              description,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 18 * scale,
                fontWeight: FontWeight.normal,
                height: 1.6,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          // Video thumbnail section
          Container(
            height: 200 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: Offset(0, 2 * scale),
                  blurRadius: 8 * scale,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * scale),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video thumbnail image - using hardcoded asset
                  Image.asset(
                    'assets/images/video-thumbnail.png',
                    width: double.infinity,
                    height: 200 * scale,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to placeholder if image fails to load
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.video_library,
                          size: 60 * scale,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                  // Blur overlay
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 3 * scale,
                      sigmaY: 3 * scale,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Video title label
                  if (videoTitle.isNotEmpty)
                    Positioned(
                      top: 16 * scale,
                      right: 16 * scale,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 6 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                        child: Text(
                          videoTitle,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Play button
                  GestureDetector(
                    onTap: () {
                      // Use custom callback if provided, otherwise open YouTube
                      if (onVideoTap != null) {
                        onVideoTap!();
                      } else {
                        UrlLauncherHelper.openYouTubeVideo(context, videoUrl);
                      }
                    },
                    child: Container(
                      width: 70 * scale,
                      height: 70 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 4 * scale),
                            blurRadius: 12 * scale,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 45 * scale,
                        color: Colors.white,
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
}
