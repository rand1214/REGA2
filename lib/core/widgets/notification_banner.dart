import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Shows an iOS-style banner notification.
/// Use [NotificationBanner.show] to display any notification.
class NotificationBanner {
  static void show(
    BuildContext context, {
    required String title,
    required String text,
    int durationSeconds = 5,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final scale = (screenWidth / 375).clamp(0.85, 1.15);

    final shownAt = DateTime.now();
    final timestampNotifier = ValueNotifier<String>('ئێستا');

    String elapsed() {
      final diff = DateTime.now().difference(shownAt);
      if (diff.inMinutes < 1) return 'ئێستا';
      if (diff.inMinutes < 60) return '${diff.inMinutes} خولەک';
      if (diff.inHours < 24) return '${diff.inHours} کاتژمێر';
      return '${diff.inDays} ڕۆژ';
    }

    final tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      timestampNotifier.value = elapsed();
    });

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _BannerWidget(
        topPadding: topPadding,
        scale: scale,
        title: title,
        text: text,
        visibleDuration: Duration(seconds: durationSeconds),
        timestampNotifier: timestampNotifier,
        onDismiss: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            entry.remove();
            tickTimer.cancel();
            timestampNotifier.dispose();
          });
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _BannerWidget extends StatefulWidget {
  final double topPadding;
  final double scale;
  final String title;
  final String text;
  final Duration visibleDuration;
  final ValueNotifier<String> timestampNotifier;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.topPadding,
    required this.scale,
    required this.title,
    required this.text,
    required this.visibleDuration,
    required this.timestampNotifier,
    required this.onDismiss,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _bellCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  double _dragOffset = 0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _bellCtrl = AnimationController(vsync: this);
    _progressCtrl = AnimationController(
        vsync: this, duration: widget.visibleDuration);
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));

    _enterCtrl.forward();
    _progressCtrl.forward();

    Future.delayed(widget.visibleDuration, () {
      if (mounted && !_isDismissing) _startExit();
    });

    _exitCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDismiss();
    });
  }

  void _startExit() {
    if (_isDismissing) return;
    _isDismissing = true;
    _exitCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _exitCtrl.dispose();
    _bellCtrl.dispose();
    _progressCtrl.dispose();
    _snapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final top = widget.topPadding;

    return AnimatedBuilder(
      animation: Listenable.merge([_enterCtrl, _exitCtrl]),
      builder: (context, child) {
        const bannerH = 100.0;
        final enterT = Curves.easeOutQuart.transform(_enterCtrl.value);
        final exitT = Curves.easeInCubic.transform(_exitCtrl.value);
        final totalOffset = -(1 - enterT) * (top + bannerH) +
            (-exitT * (top + bannerH)) +
            _dragOffset;

        return Positioned(
          top: top + 10 * s + totalOffset,
          left: 12 * s,
          right: 12 * s,
          child: child!,
        );
      },
      child: GestureDetector(
        onVerticalDragUpdate: (d) {
          if (_isDismissing) return;
          _snapCtrl.stop();
          final resistance = 1.0 / (1.0 + (_dragOffset.abs() / 80));
          setState(() => _dragOffset =
              (_dragOffset + d.delta.dy * resistance).clamp(
                  -double.infinity, 0.0));
        },
        onVerticalDragEnd: (d) {
          if (_isDismissing) return;
          if (_dragOffset < -55 || (d.primaryVelocity ?? 0) < -400) {
            _startExit();
          } else {
            final from = _dragOffset;
            _snapAnim = Tween<double>(begin: from, end: 0).animate(
              CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
            );
            _snapCtrl
              ..reset()
              ..forward();
            _snapCtrl.addListener(
                () => setState(() => _dragOffset = _snapAnim.value));
          }
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14 * s),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20 * s,
                  offset: Offset(0, 6 * s),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          12 * s, 10 * s, 12 * s, 10 * s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: icon + label + timestamp
                          Row(
                            children: [
                              Container(
                                width: 20 * s,
                                height: 20 * s,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0080C8),
                                  borderRadius:
                                      BorderRadius.circular(5 * s),
                                ),
                                child: Center(
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                    child: Lottie.asset(
                                      'assets/icons/notfication_bell.json',
                                      controller: _bellCtrl,
                                      onLoaded: (c) {
                                        _bellCtrl.duration = c.duration;
                                        _bellCtrl.value = 27 / 90;
                                        _bellCtrl
                                            .animateTo(74 / 90,
                                                duration: const Duration(
                                                    milliseconds: 783))
                                            .then((_) =>
                                                _bellCtrl.value = 1.0);
                                      },
                                      fit: BoxFit.contain,
                                      repeat: false,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6 * s),
                              Transform.translate(
                                offset: const Offset(0, 2),
                                child: Text(
                                  'ئاگاداری',
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 11 * s,
                                    color: const Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ValueListenableBuilder<String>(
                                valueListenable: widget.timestampNotifier,
                                builder: (_, val, __) => Text(
                                  val,
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 11 * s,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6 * s),
                          // Title
                          Text(
                            widget.title,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 13 * s,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 3 * s),
                          // Body
                          Text(
                            widget.text,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 12 * s,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => LayoutBuilder(
                      builder: (_, constraints) {
                        final w = constraints.maxWidth;
                        return SizedBox(
                          height: 3,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                    color: const Color(0xFFF1F1F1)),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: w * _progressCtrl.value,
                                child: Container(
                                    color: const Color(0xFF0080C8)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
