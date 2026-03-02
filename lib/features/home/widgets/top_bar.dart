import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TopBar extends StatefulWidget {
  final String kurdishName;
  /// If true => show "Pro", else => "Free"
  /// (Unauthorized OR authorized but unpaid => false)
  final bool hasProSubscription;
  final int notificationCount; // TODO: Get from Supabase
  final VoidCallback? onNotificationTap; // TODO: Navigate to notifications screen
  final VoidCallback? onLogoutTap;

  const TopBar({
    super.key,
    required this.kurdishName,
    this.hasProSubscription = false,
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

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return fullName;
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  String get _planLabel => widget.hasProSubscription ? 'Pro' : 'Free';

  void _triggerBell() {
    // Play only the swing animation (frames 27-74 out of 90 total)
    const startFraction = 27 / 90;
    const endFraction = 74 / 90;
    _bellController.value = startFraction;
    _bellController
        .animateTo(
      endFraction,
      duration: const Duration(milliseconds: 783),
    )
        .then((_) {
      if (mounted) _bellController.value = 1.0;
    });
    if (widget.onNotificationTap != null) {
      widget.onNotificationTap!();
    }
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
        // UI tokens (light mode, professional)
        const cardBg = Colors.white;
        const border = Color(0xFFE6E8EC);
        const textMain = Color(0xFF111827);
        const textSub = Color(0xFF6B7280);

        return Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeMenu,
                child: const SizedBox.expand(),
              ),
            ),
            // Anchored dropdown
            CompositedTransformFollower(
              link: _menuLink,
              showWhenUnlinked: false,
              offset: Offset(0, 54 * scale), // dropdown below profile area
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
                            enabled: false, // placeholder
                            onTap: null,
                            textMain: textMain,
                            textSub: textSub,
                          ),
                          _MenuItem(
                            scale: scale,
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            enabled: false, // placeholder
                            onTap: null,
                            textMain: textMain,
                            textSub: textSub,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: border,
                            ),
                          ),
                          _MenuItem(
                            scale: scale,
                            icon: Icons.logout_rounded,
                            label: 'Logout',
                            enabled: widget.onLogoutTap != null,
                            isDestructive: true,
                            onTap: () {
                              _removeMenu();
                              widget.onLogoutTap?.call();
                            },
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

    // UI tokens
    const iconTint = Color(0xFF6B7280);
    const ink = Color(0xFF111827);
    const sub = Color(0xFF6B7280);

    Widget circleButton({
      required VoidCallback onTap,
      required Widget child,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42 * scale,
          height: 42 * scale,
          alignment: Alignment.center,
          child: child,
        ),
      );
    }

    final firstName = _getFirstName(widget.kurdishName);

    return Container(
      color: Colors.white,
      child: SafeArea(
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
            // Notification only (left)
            Stack(
              clipBehavior: Clip.none,
              children: [
                circleButton(
                  onTap: _triggerBell,
                  child: Padding(
                    padding: EdgeInsets.all(9 * scale),
                    child: ColorFiltered(
                      colorFilter:
                          const ColorFilter.mode(iconTint, BlendMode.srcIn),
                      child: Lottie.asset(
                        'assets/icons/notfication_bell.json',
                        controller: _bellController,
                        onLoaded: (composition) {
                          _bellController.duration = composition.duration;
                          _bellController.value = 1.0; // resting frame
                        },
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                    ),
                  ),
                ),
                // Badge
                if (widget.notificationCount > 0)
                  Positioned(
                    top: -3 * scale,
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
                          )
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
            // Profile area (right) + dropdown anchor
            CompositedTransformTarget(
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
                      // Name + plan stacked
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.42,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                color: ink,
                                fontSize: 14.5 * scale,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              _planLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: sub,
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      // Avatar on the right
                      Container(
                        width: 36 * scale,
                        height: 36 * scale,
                        child: Transform.scale(
                          scale: 1.2,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              iconTint,
                              BlendMode.srcIn,
                            ),
                            child: Lottie.asset(
                              'assets/icons/profile-icon.json',
                              controller: _profileController,
                              onLoaded: (composition) {
                                _profileController.duration =
                                    composition.duration;
                                _profileController.forward();
                              },
                              fit: BoxFit.cover,
                              repeat: false,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      // Small chevron
                      Icon(
                        _menuEntry == null
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: iconTint,
                        size: 20 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 10 * scale,
        ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
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
