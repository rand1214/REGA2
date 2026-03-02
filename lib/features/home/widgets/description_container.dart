import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DescriptionContainer extends StatefulWidget {
  final String description;
  final bool hasActiveSubscription; // TODO: Get from Supabase
  final VoidCallback? onBuyTap; // TODO: Navigate to subscription/purchase screen

  const DescriptionContainer({
    super.key,
    required this.description,
    this.hasActiveSubscription = false,
    this.onBuyTap,
  });

  @override
  State<DescriptionContainer> createState() => _DescriptionContainerState();
}

class _DescriptionContainerState extends State<DescriptionContainer> with SingleTickerProviderStateMixin {
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
    // Don't show if user has active subscription
    if (widget.hasActiveSubscription) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 20 * scale,
      ),
      child: Container(
        clipBehavior: Clip.none,
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
        child: ClipRect(
          clipBehavior: Clip.none,
          child: Row(
            children: [
              // Buy button
              Container(
                clipBehavior: Clip.none,
                child: GestureDetector(
                  onTap: widget.onBuyTap ?? () {
                    // TODO: Navigate to subscription/purchase screen
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20 * scale,
                      vertical: 10 * scale,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2d2d2d),
                          Color(0xFF1a1a1a),
                          Color(0xFF0d0d0d),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(12 * scale),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: Offset(0, 3 * scale),
                          blurRadius: 6 * scale,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          offset: Offset(0, -1 * scale),
                          blurRadius: 2 * scale,
                        ),
                      ],
                    ),
                    child: Text(
                      'کڕین',
                      style: TextStyle(
                        fontFamily: 'Peshang',
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(width: 12 * scale),
            // Description text
            Expanded(
              child: Text(
                widget.description,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            // Lock icon
            Container(
              width: 45 * scale,
              height: 45 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Lottie.asset(
                'assets/icons/Lock.json',
                width: 45 * scale,
                height: 45 * scale,
                fit: BoxFit.contain,
                controller: _lockController,
                onLoaded: (composition) {
                  _lockController.duration = composition.duration;
                  // Set to frame 1 (value 0.0 is frame 0, so we need a tiny value for frame 1)
                  _lockController.value = 1.0 / composition.duration.inMilliseconds;
                },
                repeat: false,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
