import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/device_auth_service.dart';
import 'profile_setup_bottom_sheet.dart';

class RecoveryRejectedBottomSheet extends StatefulWidget {
  final String? rejectionReason;

  const RecoveryRejectedBottomSheet({super.key, this.rejectionReason});

  @override
  State<RecoveryRejectedBottomSheet> createState() =>
      _RecoveryRejectedBottomSheetState();
}

class _RecoveryRejectedBottomSheetState
    extends State<RecoveryRejectedBottomSheet>
    with TickerProviderStateMixin {
  final DeviceAuthService _authService = DeviceAuthService();

  late AnimationController _infoAnimationController;
  late AnimationController _dropdownAnimationController;

  bool _showInfoDropdown = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _infoAnimationController = AnimationController(vsync: this);
    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _infoAnimationController.dispose();
    _dropdownAnimationController.dispose();
    super.dispose();
  }

  void _playInfoAnimation() {
    _infoAnimationController.reset();
    _infoAnimationController.forward();

    if (_showInfoDropdown) {
      _dropdownAnimationController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _showInfoDropdown = false;
        });
      });
    } else {
      setState(() {
        _showInfoDropdown = true;
      });
      _dropdownAnimationController.forward();
    }
  }

  Future<void> _retryRecovery() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final NavigatorState localNavigator = Navigator.of(context);
      final NavigatorState rootNavigator =
          Navigator.of(context, rootNavigator: true);

      await _authService.clearPendingRecoveryRequest();

      if (!mounted) return;

      if (localNavigator.canPop()) {
        localNavigator.pop();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      await showModalBottomSheet(
        context: rootNavigator.context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 650),
          reverseDuration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        builder: (_) => const ProfileSetupBottomSheet(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double scale = (screenWidth / 375).clamp(0.8, 1.5);

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
          if (_showInfoDropdown) {
            _dropdownAnimationController.reverse().then((_) {
              if (!mounted) return;
              setState(() {
                _showInfoDropdown = false;
              });
            });
          }
        },
        child: Container(
          height: screenHeight * 0.30,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scale),
              topRight: Radius.circular(24 * scale),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 8 * scale),
                      width: 40 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24 * scale,
                        vertical: 12 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 1),
                          Center(
                            child: Transform.translate(
                              offset: Offset(0, -6 * scale),
                              child: SizedBox(
                                width: 80 * scale,
                                height: 80 * scale,
                                child: Lottie.asset(
                                  'assets/icons/rejected.json',
                                  fit: BoxFit.contain,
                                  repeat: false,
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, -7 * scale),
                            child: Text(
                              'داواکارییەکەت ڕەتکرایەوە',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          if (widget.rejectionReason != null) ...[
                            SizedBox(height: 6 * scale),
                            Text(
                              widget.rejectionReason!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 11 * scale,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                          const Spacer(flex: 1),
                          Transform.translate(
                            offset: Offset(0, -5 * scale),
                            child: Text(
                              'داواکارییەکەت ڕەتکرایەوە. دەتوانیت دووبارە هەوڵ بدەیتەوە یان هەژمارێکی نوێ دروست بکەیت',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 11 * scale,
                                color: Colors.black54,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const Spacer(flex: 2),
                          Material(
                            color: Colors.transparent,
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10 * scale),
                            child: InkWell(
                              onTap: _isLoading ? null : _retryRecovery,
                              borderRadius: BorderRadius.circular(10 * scale),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0080C8),
                                      Color(0xFF004A73),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(10 * scale),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Container(
                                  height: 40 * scale,
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 16 * scale,
                                          height: 16 * scale,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'هەژمارێکی نوێ درووست بکە',
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
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 20 * scale,
                right: 24 * scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _playInfoAnimation,
                      child: SizedBox(
                        width: 26 * scale,
                        height: 26 * scale,
                        child: Lottie.asset(
                          'assets/icons/info-icon.json',
                          controller: _infoAnimationController,
                          onLoaded: (composition) {
                            _infoAnimationController.duration =
                                composition.duration;
                            _infoAnimationController.value = 1.0;
                          },
                          repeat: false,
                        ),
                      ),
                    ),
                    if (_showInfoDropdown) ...[
                      SizedBox(height: 8 * scale),
                      FadeTransition(
                        opacity: _dropdownAnimationController,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _dropdownAnimationController,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 240 * scale,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 10 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  offset: Offset(0, 4 * scale),
                                  blurRadius: 12 * scale,
                                ),
                              ],
                            ),
                            child: Text(
                              'ئەگەر داواکارییەکەت ڕەتکرابێتەوە، دەتوانیت هەژمارێکی نوێ دروست بکەیت و زانیارییەکانت بە دروستی بنووسیت.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 11 * scale,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}