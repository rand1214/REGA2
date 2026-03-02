import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/device_auth_service.dart';

class RecoveryRequestStatusScreen extends StatefulWidget {
  final String recoveryCode;
  
  const RecoveryRequestStatusScreen({
    super.key,
    required this.recoveryCode,
  });

  @override
  State<RecoveryRequestStatusScreen> createState() => _RecoveryRequestStatusScreenState();
}

class _RecoveryRequestStatusScreenState extends State<RecoveryRequestStatusScreen> {
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
          
          // Get user ID from the request (we need to fetch it)
          // For now, we'll navigate to home and let the app handle auth
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            context.go('/home');
          }
        }
      } else {
        // No action needed if request not found
      }
    } catch (e) {
      // Silently handle errors during polling
    }
  }

  void _retryRecovery() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
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
    );
  }

  Widget _buildPendingStatus(double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80 * scale,
          height: 80 * scale,
          child: CircularProgressIndicator(
            strokeWidth: 6 * scale,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
        SizedBox(height: 32 * scale),
        Text(
          'چاوەڕوانی پەسەندکردن',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 24 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12 * scale),
        Text(
          'داواکارییەکەت لە ماوەی ٢٤ کاتژمێردا\nپێداچوونەوەی دەکرێت',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 14 * scale,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 32 * scale),
        Container(
          padding: EdgeInsets.all(16 * scale),
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
                  fontSize: 12 * scale,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                _authService.formatRecoveryCode(widget.recoveryCode),
                style: TextStyle(
                  fontFamily: 'Prototype',
                  fontSize: 28 * scale,
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
          size: 80 * scale,
          color: Colors.red,
        ),
        SizedBox(height: 32 * scale),
        Text(
          'داواکارییەکەت ڕەتکرایەوە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 24 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        SizedBox(height: 12 * scale),
        if (_rejectionReason != null) ...[
          Container(
            padding: EdgeInsets.all(16 * scale),
            margin: EdgeInsets.symmetric(horizontal: 24 * scale),
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
                fontSize: 14 * scale,
                color: Colors.red.shade900,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 24 * scale),
        ],
        Text(
          'تکایە زانیارییەکانت بپشکنەرەوە و\nدووبارە هەوڵ بدەرەوە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 14 * scale,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 32 * scale),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: Offset(0, 3 * scale),
                blurRadius: 10 * scale,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _retryRecovery,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 14 * scale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              elevation: 0,
            ),
            child: Text(
              'دووبارە هەوڵ بدەرەوە',
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
          size: 80 * scale,
          color: Colors.green,
        ),
        SizedBox(height: 32 * scale),
        Text(
          'داواکارییەکەت پەسەندکرا',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 24 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 12 * scale),
        Text(
          'هەژمارەکەت بە سەرکەوتوویی گەڕایەوە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 14 * scale,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 32 * scale),
        SizedBox(
          width: 40 * scale,
          height: 40 * scale,
          child: CircularProgressIndicator(
            strokeWidth: 3 * scale,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ],
    );
  }
}
