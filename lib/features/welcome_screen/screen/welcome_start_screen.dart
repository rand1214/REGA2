import 'package:flutter/material.dart';
import '../../profile_setup/widgets/dialect_selection_bottom_sheet.dart';
import '../../profile_setup/widgets/recovery_code_entry_bottom_sheet.dart';

class WelcomeStartScreen extends StatelessWidget {
  const WelcomeStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.1),
              
              // Logo/Title
              Text(
                'Rêga',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Prototype',
                  fontSize: 48 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 4,
                ),
              ),
              
              SizedBox(height: 16 * scale),
              
              Text(
                'فێربوونی شۆفێری',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 20 * scale,
                  color: Colors.black54,
                ),
              ),
              
              Spacer(),
              
              // Start button
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: false,
                    enableDrag: false,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const DialectSelectionBottomSheet(),
                  );
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
              
              // Recovery button
              OutlinedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: false,
                    enableDrag: false,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const RecoveryCodeEntryBottomSheet(),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  side: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Text(
                  'گەڕانەوەی هەژمار',
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
