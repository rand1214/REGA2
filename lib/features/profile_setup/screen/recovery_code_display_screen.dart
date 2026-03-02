import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/device_auth_service.dart';

class RecoveryCodeDisplayScreen extends StatelessWidget {
  final String recoveryCode;

  const RecoveryCodeDisplayScreen({
    super.key,
    required this.recoveryCode,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: recoveryCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'کۆدەکە کۆپی کرا',
          style: TextStyle(fontFamily: 'Peshang'),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);
    final authService = DeviceAuthService();
    final formattedCode = authService.formatRecoveryCode(recoveryCode);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.08),
              
              // Success icon
              Center(
                child: Container(
                  width: 100 * scale,
                  height: 100 * scale,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60 * scale,
                    color: Colors.green,
                  ),
                ),
              ),
              
              SizedBox(height: 32 * scale),
              
              // Title
              Text(
                'هەژمارەکەت دروست کرا!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 28 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              SizedBox(height: 16 * scale),
              
              Text(
                'ئەم کۆدە گرنگە بۆ گەڕانەوەی هەژمارەکەت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 16 * scale,
                  color: Colors.black54,
                ),
              ),
              
              SizedBox(height: 48 * scale),
              
              // Recovery code display
              Container(
                padding: EdgeInsets.all(24 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20 * scale),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'کۆدی گەڕانەوە',
                      style: TextStyle(
                        fontFamily: 'Peshang',
                        fontSize: 14 * scale,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    Text(
                      formattedCode,
                      style: TextStyle(
                        fontFamily: 'Prototype',
                        fontSize: 48 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: Icon(Icons.copy, size: 18 * scale),
                      label: Text(
                        'کۆپیکردن',
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32 * scale),
              
              // Warning message
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16 * scale),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 24 * scale,
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Text(
                        'ئەم کۆدە پاشەکەوت بکە! پێویستت پێی دەبێت ئەگەر ئەپەکە سڕیتەوە',
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 13 * scale,
                          color: Colors.orange.shade900,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              
              Spacer(),
              
              // Continue button
              ElevatedButton(
                onPressed: () {
                  // Navigate to home
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 18 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'دەست پێبکە',
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              SizedBox(height: 16 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
