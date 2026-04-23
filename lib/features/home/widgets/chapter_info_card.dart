import 'package:flutter/material.dart';

class ChapterInfoCard extends StatelessWidget {
  final double scale;
  final String title;
  final String description;

  const ChapterInfoCard({
    super.key,
    required this.scale,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -10 * scale),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20 * scale, 0, 20 * scale, 10 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                offset: Offset(0, 2 * scale),
                blurRadius: 8 * scale,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -15 * scale,
                bottom: -40 * scale,
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    'assets/images/car-traffic-image-blue.png',
                    width: 110 * scale,
                    height: 110 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 110 * scale,
                      height: 110 * scale,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    description,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 13 * scale,
                      height: 1.5,
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
