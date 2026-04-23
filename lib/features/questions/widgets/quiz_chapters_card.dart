import 'package:flutter/material.dart';
import 'package:flutter_supabase_app/features/home/models/chapter_model.dart';

class QuizChaptersCard extends StatelessWidget {
  final List<Chapter> chapters;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;
  final VoidCallback onStart;
  final double scale;

  const QuizChaptersCard({
    super.key,
    required this.chapters,
    required this.selectedIndices,
    required this.onToggle,
    required this.onStart,
    required this.scale,
  });

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Widget _buildChapterIcon(String iconPath, double s) {
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      return Image.network(iconPath,
          width: 32 * s, height: 32 * s, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.image_not_supported, size: 32 * s, color: Colors.grey));
    }
    return Image.asset(iconPath,
        width: 32 * s, height: 32 * s, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.image_not_supported, size: 32 * s, color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final hasSelection = selectedIndices.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          const cols = 4;
          final itemWidth = constraints.maxWidth / cols;
          return Wrap(
            spacing: 0,
            runSpacing: 16 * s,
            children: List.generate(chapters.length, (i) {
              final ch = chapters[i];
              final isSelected = selectedIndices.contains(i);
              final isLocked = ch.isLocked;
              final chColor = _parseColor(ch.color);
              final bgColor = chColor.withValues(alpha: 0.15);

              return GestureDetector(
                onTap: isLocked ? null : () => onToggle(i),
                child: SizedBox(
                  width: itemWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 8 * s),
                        child: SizedBox(
                          width: 62 * s,
                          height: 62 * s,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                painter: _QuizNotchedCirclePainter(
                                  hasNotch: isLocked || isSelected,
                                  scale: s,
                                  bgColor: bgColor,
                                ),
                                child: SizedBox(
                                  width: 62 * s,
                                  height: 62 * s,
                                  child: ClipOval(
                                    child: Center(
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          chColor,
                                          BlendMode.srcIn,
                                        ),
                                        child: _buildChapterIcon(ch.iconPath, s),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Lock or check badge at top-left
                              if (isLocked || isSelected)
                                Positioned(
                                  top: -8 * s,
                                  left: -2 * s,
                                  child: _QuizBadge(
                                    scale: s,
                                    isLocked: isLocked,
                                    chapterColor: chColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 5 * s),
                      SizedBox(
                        height: 34 * s,
                        child: Text(
                          ch.circleTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w600,
                            color: isLocked ? Colors.grey.shade400 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        }),
        SizedBox(height: 20 * s),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14 * s),
          elevation: hasSelection ? 4 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: InkWell(
            onTap: hasSelection ? onStart : null,
            borderRadius: BorderRadius.circular(14 * s),
            child: Ink(
              decoration: BoxDecoration(
                gradient: hasSelection
                    ? const LinearGradient(
                        colors: [Color(0xFF0080C8), Color(0xFF004A73)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade300,
                      ]),
                borderRadius: BorderRadius.circular(14 * s),
              ),
              child: Container(
                height: 50 * s,
                alignment: Alignment.center,
                child: Text(
                  hasSelection ? 'دەستپێبکە' : 'بەشێک هەڵبژێرە',
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: 15 * s,
                    fontWeight: FontWeight.bold,
                    color: hasSelection ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizBadge extends StatelessWidget {
  final double scale;
  final bool isLocked;
  final Color chapterColor;

  const _QuizBadge({required this.scale, required this.isLocked, required this.chapterColor});

  @override
  Widget build(BuildContext context) {
    final double size = 22 * scale;
    final double iconSize = size * 0.6;

    final colors = isLocked
        ? const [Color(0xFF3D82B8), Color(0xFF2C6EA3)]
        : [chapterColor.withValues(alpha: 0.9), chapterColor];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(
        isLocked ? Icons.lock : Icons.check,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class _QuizNotchedCirclePainter extends CustomPainter {
  final bool hasNotch;
  final double scale;
  final Color bgColor;

  _QuizNotchedCirclePainter({required this.hasNotch, required this.scale, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset center = Offset(r, r);
    final double badgeR = 11.0 * scale;
    final Offset notchCenter = Offset(9 * scale, 3 * scale);

    // Shadow
    canvas.drawCircle(
      center + Offset(0, 2 * scale),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale),
    );

    Path path = Path()..addOval(Rect.fromCircle(center: center, radius: r));

    if (hasNotch) {
      final notch = Path()..addOval(Rect.fromCircle(center: notchCenter, radius: badgeR + 2 * scale));
      path = Path.combine(PathOperation.difference, path, notch);
    }

    canvas.drawPath(path, Paint()..color = bgColor);
  }

  @override
  bool shouldRepaint(_QuizNotchedCirclePainter old) =>
      old.hasNotch != hasNotch || old.bgColor != bgColor;
}
