import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TopBar extends StatefulWidget {
  final String firstName;
  final String planLabel;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLogoutTap;

  const TopBar({
    super.key,
    required this.firstName,
    required this.planLabel,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onLogoutTap,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with TickerProviderStateMixin {
  late AnimationController _bellController;
  late AnimationController _profileController;
  final LayerLink _menuLink = LayerLink();
  OverlayEntry? _menuEntry;
  late final AnimationController _menuAnimController;
  late final Animation<double> _menuScale;
  late final Animation<double> _menuOpacity;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(vsync: this);
    _profileController = AnimationController(vsync: this);
    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _menuScale = CurvedAnimation(
      parent: _menuAnimController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    _menuOpacity = CurvedAnimation(
      parent: _menuAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _removeMenu(immediate: true);
    _bellController.dispose();
    _profileController.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  void _triggerBell() {
    const startFraction = 27 / 90;
    const endFraction = 74 / 90;
    _bellController.value = startFraction;
    _bellController
        .animateTo(endFraction, duration: const Duration(milliseconds: 783))
        .then((_) { if (mounted) _bellController.value = 1.0; });
    widget.onNotificationTap?.call();
  }

  void _toggleMenu() {
    if (_menuEntry != null) {
      _removeMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    if (_menuEntry != null) return;
    _menuEntry = OverlayEntry(
      builder: (context) {
        final scale = (MediaQuery.of(context).size.width / 375).clamp(0.8, 1.5);
        const cardBg = Colors.white;
        const border = Color(0xFFE6E8EC);
        const textMain = Color(0xFF111827);
        const textSub = Color(0xFF6B7280);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _menuLink,
              showWhenUnlinked: false,
              offset: Offset(0, 54 * scale),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _menuOpacity,
                  child: ScaleTransition(
                    scale: _menuScale,
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 210 * scale,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14 * scale),
                        border: Border.all(color: border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 22 * scale,
                            offset: Offset(0, 10 * scale),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8 * scale),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuItem(
                            scale: scale,
                            icon: Icons.person_outline_rounded,
                            label: 'Profile',
                            enabled: false,
                            onTap: null,
                            textMain: textMain,
                            textSub: textSub,
                          ),
                          _MenuItem(
                            scale: scale,
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            enabled: false,
                            onTap: null,
                            textMain: textMain,
                            textSub: textSub,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Divider(height: 1, thickness: 1, color: border),
                          ),
                          _MenuItem(
                            scale: scale,
                            icon: Icons.logout_rounded,
                            label: 'Logout',
                            enabled: widget.onLogoutTap != null,
                            isDestructive: widget.onLogoutTap != null,
                            onTap: widget.onLogoutTap != null ? () {
                              _removeMenu();
                              widget.onLogoutTap?.call();
                            } : null,
                            textMain: textMain,
                            textSub: textSub,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_menuEntry!);
    _menuAnimController.forward(from: 0);
  }

  Future<void> _removeMenu({bool immediate = false}) async {
    if (_menuEntry == null) return;
    if (immediate) {
      _menuEntry?.remove();
      _menuEntry = null;
      return;
    }
    await _menuAnimController.reverse(from: _menuAnimController.value);
    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E7BBF), Color(0xFF0E5A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20 * scale),
          bottomRight: Radius.circular(20 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B8C).withValues(alpha: 0.3),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
            spreadRadius: -4 * scale,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20 * scale),
                bottomRight: Radius.circular(20 * scale),
              ),
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/icons/blue-traffic-pattern-for-bg.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 18 * scale,
                right: 18 * scale,
                top: 12 * scale,
                bottom: 10 * scale,
              ),
              child: Row(
                children: [
                  // Bell icon (left)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -1 * scale),
                        child: GestureDetector(
                          onTap: _triggerBell,
                          child: Container(
                            width: 42 * scale,
                            height: 42 * scale,
                            alignment: Alignment.center,
                            child: Container(
                              width: 38 * scale,
                              height: 38 * scale,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12 * scale),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF2C6EA3), Color(0xFF1F5E8E)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12 * scale,
                                    offset: Offset(0, 4 * scale),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(9 * scale),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                child: Lottie.asset(
                                  'assets/icons/notfication_bell.json',
                                  controller: _bellController,
                                  onLoaded: (composition) {
                                    _bellController.duration = composition.duration;
                                    _bellController.value = 1.0;
                                  },
                                  fit: BoxFit.contain,
                                  repeat: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.notificationCount > 0)
                        Positioned(
                          top: 1 * scale,
                          right: -3 * scale,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6 * scale,
                              vertical: 3 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white, width: 2 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 10 * scale,
                                  offset: Offset(0, 4 * scale),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              minHeight: 18 * scale,
                              minWidth: 18 * scale,
                            ),
                            child: Text(
                              widget.notificationCount > 99
                                  ? '99+'
                                  : widget.notificationCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Profile area (right)
                  Transform.translate(
                    offset: Offset(15 * scale, 0),
                    child: CompositedTransformTarget(
                      link: _menuLink,
                      child: GestureDetector(
                        onTap: _toggleMenu,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale,
                            vertical: 8 * scale,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 32 * scale),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: screenWidth * 0.42),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        widget.firstName,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: 'Peshang',
                                          color: Colors.white,
                                          fontSize: 14.5 * scale,
                                          fontWeight: FontWeight.w800,
                                          height: 1.05,
                                        ),
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        widget.planLabel,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 5 * scale),
                              SizedBox(
                                width: 36 * scale,
                                height: 36 * scale,
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    child: Lottie.asset(
                                      'assets/icons/profile-icon.json',
                                      controller: _profileController,
                                      onLoaded: (composition) {
                                        _profileController.duration = composition.duration;
                                        _profileController.forward();
                                      },
                                      fit: BoxFit.cover,
                                      repeat: false,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              Icon(
                                _menuEntry == null
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                color: Colors.white,
                                size: 20 * scale,
                              ),
                            ],
                          ),
                        ),
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

class _MenuItem extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback? onTap;
  final Color textMain;
  final Color textSub;

  const _MenuItem({
    required this.scale,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.textMain,
    required this.textSub,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDestructive
        ? const Color(0xFFEF4444)
        : (enabled ? textMain : textSub);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20 * scale),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13.5 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!enabled && !isDestructive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Soon',
                  style: TextStyle(
                    color: textSub,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
