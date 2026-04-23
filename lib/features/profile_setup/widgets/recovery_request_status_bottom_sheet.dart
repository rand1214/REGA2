import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import '../../../core/services/device_auth_service.dart';
import 'recovery_approved_bottom_sheet.dart';
import 'recovery_rejected_bottom_sheet.dart';

class RecoveryRequestStatusBottomSheet extends StatefulWidget {
  final String recoveryCode;

  const RecoveryRequestStatusBottomSheet({
    super.key,
    required this.recoveryCode,
  });

  @override
  State<RecoveryRequestStatusBottomSheet> createState() =>
      _RecoveryRequestStatusBottomSheetState();
}

class _RecoveryRequestStatusBottomSheetState
    extends State<RecoveryRequestStatusBottomSheet> {
  final DeviceAuthService _authService = DeviceAuthService();
  Timer? _statusCheckTimer;
  bool _isHandlingResult = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_isHandlingResult) return;

    try {
      final NavigatorState localNavigator = Navigator.of(context);
      final NavigatorState rootNavigator =
          Navigator.of(context, rootNavigator: true);

      final result = await _authService.checkRecoveryRequestStatus();

      if (!mounted) return;
      if (result['success'] != true) return;

      final String status = result['status'] as String;
      if (status == 'pending') return;

      _isHandlingResult = true;
      _statusCheckTimer?.cancel();

      final String code = widget.recoveryCode;
      final String? reason = result['rejection_reason'] as String?;

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
        builder: (_) => status == 'accepted'
            ? RecoveryApprovedBottomSheet(recoveryCode: code)
            : RecoveryRejectedBottomSheet(rejectionReason: reason),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double scale = (screenWidth / 375).clamp(0.8, 1.5);

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
                    SizedBox(
                      width: 100 * scale,
                      height: 100 * scale,
                      child: DotLottieView(
                        sourceType: 'asset',
                        source: 'assets/icons/Sandy Loading.lottie',
                        autoplay: true,
                        loop: true,
                      ),
                    ),
                    Text(
                      '...تکایە چاوەڕوانبە',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Peshang',
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      'داواکارییەکەت لە ماوەی ٢٤ کاتژمێردا\nپێداچوونەوەی بۆ دەکرێت',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Peshang',
                        fontSize: 12 * scale,
                        color: Colors.black54,
                        height: 1.5,
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