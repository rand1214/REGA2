import 'package:flutter/material.dart';

class SectionsTitle extends StatelessWidget {
  final double scale;

  const SectionsTitle({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 30 * scale, top: 10 * scale),
      child: Text(
        'بەشەکان',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Peshang',
          fontSize: 23 * scale,
          fontWeight: FontWeight.w900,
          height: 1.5,
          color: Colors.black,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(38),
              offset: Offset(2 * scale, 2 * scale),
              blurRadius: 4 * scale,
            ),
          ],
        ),
      ),
    );
  }
}
