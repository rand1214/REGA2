import 'package:flutter/material.dart';

class Welcomer3Screen extends StatelessWidget {
  final int currentPage;
  final VoidCallback onNextPressed;

  const Welcomer3Screen({
    super.key,
    required this.currentPage,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);
    
    // Adjust for small screens
    final isSmallScreen = screenHeight < 700;
    final adjustedScale = isSmallScreen ? scale * 0.9 : scale;
    
    // Better handling for medium screens (iPhone 14 Pro, etc.)
    final isMediumScreen = screenWidth >= 390 && screenWidth <= 430;
    
    // Detect tall narrow screens (Z Fold)
    final aspectRatio = screenHeight / screenWidth;
    final isTallNarrow = aspectRatio > 2.0;
    
    // Adjust font size more aggressively for medium screens
    final descriptionFontSize = isMediumScreen
        ? 16.0 * adjustedScale
        : (screenWidth < 375
            ? 16.0 * adjustedScale
            : (screenWidth < 400 ? 18.0 * adjustedScale : 20.0 * adjustedScale));
    
    // Make Kurdish title responsive
    final titleFontSize = isMediumScreen
        ? 24.0 * adjustedScale
        : (isSmallScreen ? 24.0 * adjustedScale : 28.0 * adjustedScale);
    
    // Better vertical spacing for tall narrow screens
    final topSpacing = isTallNarrow ? screenHeight * 0.08 : 10 * adjustedScale;
    final imageHeight = isTallNarrow 
        ? 280 * adjustedScale 
        : (isSmallScreen ? 280 * adjustedScale : 350 * adjustedScale);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: topSpacing),
            Text(
              'Rêga',
              style: TextStyle(
                fontFamily: 'Prototype',
                fontSize: 40 * adjustedScale,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
                letterSpacing: 4 * adjustedScale,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: Offset(2 * adjustedScale, 2 * adjustedScale),
                    blurRadius: 4 * adjustedScale,
                  ),
                ],
              ),
            ),
            Image.asset(
              "assets/images/welcomer-3.png",
              height: imageHeight,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10 * adjustedScale),
            Padding(
              padding: EdgeInsets.only(right: 22 * adjustedScale),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "ئامادەیت بۆ سەرکەوتن",
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: Offset(2 * adjustedScale, 2 * adjustedScale),
                        blurRadius: 4 * adjustedScale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12 * adjustedScale),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20 * adjustedScale,
                    right: 40 * adjustedScale,
                  ),
                  child: IntrinsicHeight(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20 * adjustedScale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16 * adjustedScale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: Offset(0, 2 * adjustedScale),
                                blurRadius: 8 * adjustedScale,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            "دوای تەواوکردنی فێربوون و تاقیکردنەوەکان، ئێستا ئامادەیت بۆ هەنگاوی دوا. بە باوەڕ بە زانیاری و تواناکانت بچۆ بۆ تاقیکردنەوەی ڕاستەقینە و بێبەش مەبە لە وەرگرتنی مۆڵەتی شۆفێری. سەرکەوتن چاوەڕێت دەکات",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: descriptionFontSize,
                              fontWeight: FontWeight.normal,
                              height: 1.6,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20 * adjustedScale,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 6 * adjustedScale,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(3 * adjustedScale),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20 * adjustedScale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30 * adjustedScale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildDot(Colors.red, currentPage == 0, adjustedScale),
                      _buildDot(Colors.orange, currentPage == 1, adjustedScale),
                      _buildDot(Colors.green, currentPage == 2, adjustedScale),
                    ],
                  ),
                  GestureDetector(
                    onTap: onNextPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24 * adjustedScale,
                        vertical: 12 * adjustedScale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20 * adjustedScale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 4 * adjustedScale),
                            blurRadius: 8 * adjustedScale,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'دواتر',
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 18 * adjustedScale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40 * adjustedScale),
          ],
        ),
      ),
    );
  }

  static Widget _buildDot(Color color, bool isActive, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6 * scale),
      width: isActive ? 14 * scale : 10 * scale,
      height: isActive ? 14 * scale : 10 * scale,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
