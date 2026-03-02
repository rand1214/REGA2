import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/device_auth_service.dart';
import 'dialect_selection_bottom_sheet.dart';

class RecoveryRequestStatusBottomSheet extends StatefulWidget {
  final String recoveryCode;
  
  const RecoveryRequestStatusBottomSheet({
    super.key,
    required this.recoveryCode,
  });

  @override
  State<RecoveryRequestStatusBottomSheet> createState() => _RecoveryRequestStatusBottomSheetState();
}

class _RecoveryRequestStatusBottomSheetState extends State<RecoveryRequestStatusBottomSheet> {
  final DeviceAuthService _authService = DeviceAuthService();
  Timer? _statusCheckTimer;
  
  String _status = 'pending';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkStatus(),
    );
  }

  Future<void> _checkStatus() async {
    try {
      final result = await _authService.checkRecoveryRequestStatus();
      
      if (result['success'] == true && mounted) {
        final newStatus = result['status'] as String;
        
        setState(() {
          _status = newStatus;
          _rejectionReason = result['rejection_reason'];
        });

        // Handle accepted status
        if (newStatus == 'accepted') {
          _statusCheckTimer?.cancel();
          
          // Get user_id from the recovery request result
          // The database function should return the user_id when status is accepted
          // We need to fetch the user profile to get the user_id
          try {
            // Find user by recovery code to get user_id
            final userResult = await _authService.getUserIdByRecoveryCode(widget.recoveryCode);
            
            if (userResult != null) {
              // Store user credentials locally
              await _authService.handleApprovedRecovery(userResult, widget.recoveryCode);
              
              // Clear pending recovery request
              await _authService.clearPendingRecoveryRequest();
              
              await Future.delayed(const Duration(seconds: 2));
              
              if (mounted) {
                Navigator.of(context).pop();
                context.pushReplacement('/home');
              }
            }
          } catch (e) {
            print('Error handling approved recovery: $e');
          }
        }
      }
    } catch (e) {
      // Silently handle errors during polling
    }
  }

  void _retryRecovery() async {
    // Clear pending recovery request
    await _authService.clearPendingRecoveryRequest();
    
    if (!mounted) return;
    
    // Find the root navigator context
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    
    // Pop current sheet
    Navigator.of(context).pop();
    
    // Wait for pop animation to complete
    await Future.delayed(const Duration(milliseconds: 450));
    
    // Show dialect selection bottom sheet using root navigator context
    showModalBottomSheet(
      context: navigatorContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 650),
        reverseDuration: Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (newContext) => const DialectSelectionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return PopScope(
      canPop: false,
      child: Container(
      height: screenHeight * 0.5,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey<String>(_status),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_status == 'pending') ...[
                      _buildPendingStatus(scale),
                    ] else if (_status == 'rejected') ...[
                      _buildRejectedStatus(scale),
                    ] else if (_status == 'accepted') ...[
                      _buildAcceptedStatus(scale),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPendingStatus(double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100 * scale,
          height: 100 * scale,
          child: Lottie.asset(
            'assets/icons/Sandy-Loading.json',
            fit: BoxFit.contain,
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
        SizedBox(height: 24 * scale),
        Container(
          padding: EdgeInsets.all(14 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: Offset(0, 2 * scale),
                blurRadius: 8 * scale,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'کۆدی گەڕانەوە',
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 11 * scale,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                _authService.formatRecoveryCode(widget.recoveryCode),
                style: TextStyle(
                  fontFamily: 'Prototype',
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedStatus(double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cancel_outlined,
          size: 60 * scale,
          color: Colors.red,
        ),
        SizedBox(height: 24 * scale),
        Text(
          'داواکارییەکەت ڕەتکرایەوە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        SizedBox(height: 10 * scale),
        if (_rejectionReason != null) ...[
          Container(
            padding: EdgeInsets.all(12 * scale),
            margin: EdgeInsets.symmetric(horizontal: 16 * scale),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Text(
              _rejectionReason!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 12 * scale,
                color: Colors.red.shade900,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
        ],
        Text(
          'تکایە زانیارییەکانت بپشکنەرەوە و\nدووبارە هەوڵ بدەرەوە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 12 * scale,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24 * scale),
        Material(
          color: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10 * scale),
          child: InkWell(
            onTap: _retryRecovery,
            borderRadius: BorderRadius.circular(10 * scale),
            child: Ink(
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
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Container(
                height: 40 * scale,
                alignment: Alignment.center,
                child: Text(
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
      ],
    );
  }

  Widget _buildAcceptedStatus(double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 60 * scale,
          color: Colors.green,
        ),
        SizedBox(height: 24 * scale),
        Text(
          'داواکارییەکەت پەسەندکرا',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          'هەژمارەکەت بە سەرکەوتوویی گەڕایەوە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 12 * scale,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24 * scale),
        SizedBox(
          width: 30 * scale,
          height: 30 * scale,
          child: CircularProgressIndicator(
            strokeWidth: 3 * scale,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ],
    );
  }
}
