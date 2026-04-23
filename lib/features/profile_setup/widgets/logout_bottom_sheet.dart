import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/device_auth_service.dart';
import '../../../core/services/home_refresh_service.dart';

class LogoutBottomSheet extends StatefulWidget {
  final VoidCallback onShowRecoveryCode;

  const LogoutBottomSheet({super.key, required this.onShowRecoveryCode});

  @override
  State<LogoutBottomSheet> createState() => _LogoutBottomSheetState();
}

class _LogoutBottomSheetState extends State<LogoutBottomSheet> {
  final DeviceAuthService _authService = DeviceAuthService();
  bool _codeRequested = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        setState(() => _countdown = 0);
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    if (_countdown > 0) return;
    final nav = Navigator.of(context);
    nav.pop();
    await _authService.signOut();
    await Future.delayed(const Duration(milliseconds: 500));
    triggerHomeRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.85, 1.15);

    return Container(
      height: screenHeight * 0.25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24 * scale),
          topRight: Radius.circular(24 * scale),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 8 * scale),
              width: 40 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 16 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 6 * scale),
                        Text(
                          'تکایە ئاگەدار بە ئەگەر بچیتە دەرەوە، ناتوانیت بگەڕێیتەوە بۆ ناو هەژمارەکەت ئەگەر کۆدی تایبەتی خۆت هەبێت کە لە کاتی دروستکردنی هەژمار پێت دەدرێت.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 12.4 * scale,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        GestureDetector(
                          onTap: _codeRequested ? null : () {
                            setState(() => _codeRequested = true);
                            widget.onShowRecoveryCode();
                          },
                          child: Text(
                            'کۆدەکەم چەندە؟',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.normal,
                              color: _codeRequested ? Colors.grey.shade400 : Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: _codeRequested ? Colors.grey.shade400 : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48 * scale,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                backgroundColor: const Color(0xFFF9FAFB),
                                foregroundColor: const Color(0xFF111827),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14 * scale),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'پاشگەزبوونەوە',
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: SizedBox(
                            height: 48 * scale,
                            child: GestureDetector(
                              onTap: _confirmLogout,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14 * scale),
                                child: Stack(
                                  children: [
                                    // Button background
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      color: const Color(0xFFDC2626),
                                    ),
                                    // Label always visible
                                    Center(
                                      child: Text(
                                        'دەرچوون',
                                        style: TextStyle(
                                          fontFamily: 'Peshang',
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                                        ),
                                      ),
                                    ),
                                    // Countdown overlay
                                    if (_countdown > 0)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$_countdown',
                                            style: TextStyle(
                                              fontSize: 22 * scale,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
