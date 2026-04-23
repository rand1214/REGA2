import 'package:flutter/material.dart';

class Welcomer2Screen extends StatelessWidget {
  final int currentPage;
  final VoidCallback onNextPressed;

  const Welcomer2Screen({
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

    final imageHeight = screenHeight * 0.28;
    final titleFontSize = (screenWidth * 0.065).clamp(20.0, 30.0);
    final descriptionFontSize = (screenWidth * 0.038).clamp(13.0, 18.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Column(
          children: [
            Spacer(flex: 2),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF0080C8), Color(0xFF004A73)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'Rêga',
                style: TextStyle(
                  fontFamily: 'Prototype',
                  fontSize: 40 * scale,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  letterSpacing: 4 * scale,
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
            Spacer(flex: 2),
            SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: Image.asset(
                "assets/images/welcomer-2.png",
                fit: BoxFit.contain,
              ),
            ),
            Spacer(flex: 2),
            Padding(
              padding: EdgeInsets.only(right: 22 * scale),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "خۆت تاقی بکەرەوە",
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
                        offset: Offset(2 * scale, 2 * scale),
                        blurRadius: 4 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Spacer(flex: 2),
            Padding(
              padding: EdgeInsets.only(
                left: 20 * scale,
                right: 40 * scale,
              ),
              child: IntrinsicHeight(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: Offset(0, 2 * scale),
                            blurRadius: 8 * scale,
                          ),
                        ],
                      ),
                      child: Text(
                        "دەتوانیت تاقیکردنەوەیەکی وەک ڕاستەقینە ئەنجام بدەیت و ئاستی خۆت بزانیت. پرسیارەکان وەڵام بدەیتەوە و هەڵە و ڕاستەکانت ببینیت بۆ ئەوەی باشتر فێربیت و باوەڕت بەخۆت زیاتر ببێت",
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
                      right: -20 * scale,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(3 * scale),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(flex: 3),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildDot(Colors.red, currentPage == 0, scale),
                      _buildDot(Colors.orange, currentPage == 1, scale),
                      _buildDot(Colors.green, currentPage == 2, scale),
                    ],
                  ),
                  GestureDetector(
                    onTap: onNextPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24 * scale,
                        vertical: 10 * scale,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0080C8), Color(0xFF004A73)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(18 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 4 * scale),
                            blurRadius: 8 * scale,
                          ),
                        ],
                      ),
                      child: Text(
                        'دواتر',
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(flex: 2),
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
