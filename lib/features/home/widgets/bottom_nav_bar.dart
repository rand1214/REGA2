import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: Offset(0, -2 * scale),
            blurRadius: 8 * scale,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20 * scale,
            vertical: 4 * scale,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'سەرەکی',
                index: 0,
                scale: scale,
              ),
              _buildNavItem(
                icon: Icons.assignment_rounded,
                label: 'تاقیکردنەوە',
                index: 1,
                scale: scale,
              ),
              _buildNavItem(
                icon: Icons.book_rounded,
                label: 'کتێب',
                index: 2,
                scale: scale,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'پرۆفایل',
                index: 3,
                scale: scale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required double scale,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26 * scale,
              color: isSelected ? Colors.black : Colors.grey.shade400,
            ),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 12 * scale,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
