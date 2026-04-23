import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/device_auth_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/home_refresh_service.dart';

class RecoveryApprovedBottomSheet extends StatefulWidget {
  final String recoveryCode;

  const RecoveryApprovedBottomSheet({super.key, required this.recoveryCode});

  @override
  State<RecoveryApprovedBottomSheet> createState() => _RecoveryApprovedBottomSheetState();
}

class _RecoveryApprovedBottomSheetState extends State<RecoveryApprovedBottomSheet>
    with SingleTickerProviderStateMixin {
  final DeviceAuthService _authService = DeviceAuthService();
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _handleApproved();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _handleApproved() async {
    try {
      final userResult = await _authService.getUserIdByRecoveryCode(widget.recoveryCode);
      if (userResult != null) {
        await _authService.handleApprovedRecovery(userResult, widget.recoveryCode);
        await _authService.clearPendingRecoveryRequest();
        // Register new device's FCM token now that user_id is saved
        await FcmService.registerTokenForCurrentUser();
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final nav = Navigator.of(context);
      nav.pop();
      await Future.delayed(const Duration(milliseconds: 500));
      triggerHomeRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return PopScope(
      canPop: false,
      child: Container(
        height: screenHeight * 0.35,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24 * scale),
            topRight: Radius.circular(24 * scale),
          ),
        ),
        child: Column(
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
                padding: EdgeInsets.all(24 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -16 * scale),
                      child: SizedBox(
                        width: 140 * scale,
                        height: 140 * scale,
                        child: Lottie.asset(
                          'assets/icons/Approved.json',
                          controller: _lottieController,
                          fit: BoxFit.contain,
                          repeat: false,
                          frameRate: const FrameRate(60),
                          onLoaded: (composition) {
                            _lottieController.duration = composition.duration * 2;
                            _lottieController.forward();
                          },
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -16 * scale),
                      child: Column(
                        children: [
                          SizedBox(height: 12 * scale),
                          Text(
                            'داواکارییەکەت پەسەندکرا',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          Text(
                            'هەژمارەکەت بە سەرکەوتوویی گەڕایەوە',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 12 * scale,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
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
