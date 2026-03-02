import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/device_auth_service.dart';
import 'recovery_code_display_bottom_sheet.dart';

class ProvinceSelectionBottomSheet extends StatefulWidget {
  final String kurdishName;
  final String? avatarUrl;
  final String? gender;
  final String? dialect;

  const ProvinceSelectionBottomSheet({
    super.key,
    required this.kurdishName,
    this.avatarUrl,
    this.gender,
    this.dialect,
  });

  @override
  State<ProvinceSelectionBottomSheet> createState() => _ProvinceSelectionBottomSheetState();
}

class _ProvinceSelectionBottomSheetState extends State<ProvinceSelectionBottomSheet> with TickerProviderStateMixin {
  final DeviceAuthService _authService = DeviceAuthService();
  
  String? _selectedProvince;
  bool _isLoading = false;
  String? _errorMessage;
  String _displayedText = '';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startTypewriterEffect(String text) async {
    // Fade out existing text
    if (_displayedText.isNotEmpty) {
      await _fadeController.reverse();
    }
    
    // Cancel any existing timer and reset
    _typewriterTimer?.cancel();
    _charIndex = 0;
    _displayedText = '';
    
    // Fade in and start typing
    _fadeController.forward();
    
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_charIndex < text.length) {
        setState(() {
          _displayedText = text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _completeSetup() async {
    if (_selectedProvince == null) {
      setState(() {
        _errorMessage = 'تکایە پارێزگایەک هەڵبژێرە';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user account with all data
      final result = await _authService.createNewUser(
        kurdishName: widget.kurdishName,
        avatarUrl: widget.avatarUrl,
        gender: widget.gender,
        province: _selectedProvince,
        dialect: widget.dialect,
      );

      if (result['success'] == true) {
        // Close bottom sheet
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show recovery code display bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RecoveryCodeDisplayBottomSheet(
              recoveryCode: result['recoveryCode'],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'هەڵەیەک ڕوویدا، دووبارە هەوڵ بدەرەوە';
      });
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
      height: screenHeight * 0.5,
      decoration: BoxDecoration(
        color: Color(0xFFF1F1F1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24 * scale),
          topRight: Radius.circular(24 * scale),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
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
              padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Column(
                    children: [
                      Text(
                        'پارێزگاکەت هەڵبژێرە',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      SizedBox(
                        height: 18 * scale,
                        child: _selectedProvince != null
                            ? FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  _displayedText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 12 * scale,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8 * scale),
                  
                  // Interactive map
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, -15 * scale),
                      child: Center(
                        child: SizedBox(
                          width: screenWidth * 0.75,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Map image
                                  Image.asset(
                                    'assets/images/Map-Kurdistan.PNG',
                                    fit: BoxFit.contain,
                                  ),
                                  
                                  // Clickable province regions positioned on map
                                  _buildProvinceButton('duhok', 'دهۆک', scale, 
                                    top: constraints.maxHeight * 0.12,
                                    left: constraints.maxWidth * 0.35,
                                  ),
                                  _buildProvinceButton('erbil', 'هەولێر', scale,
                                    top: constraints.maxHeight * 0.25,
                                    left: constraints.maxWidth * 0.45,
                                  ),
                                  _buildProvinceButton('sulaymaniyah', 'سلێمانی', scale,
                                    top: constraints.maxHeight * 0.35,
                                    right: constraints.maxWidth * 0.20,
                                  ),
                                  _buildProvinceButton('halabja', 'هەڵەبجە', scale,
                                    top: constraints.maxHeight * 0.47,
                                    right: constraints.maxWidth * 0.23,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(6 * scale),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 11 * scale,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  
                  // Continue button
                  Transform.translate(
                    offset: Offset(0, -20 * scale),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10 * scale),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.4),
                      child: InkWell(
                        onTap: _isLoading ? null : _completeSetup,
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
                            child: _isLoading
                                ? SizedBox(
                                    height: 16 * scale,
                                    width: 16 * scale,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2 * scale,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'دەستپێبکە',
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

  Widget _buildProvinceButton(String value, String label, double scale, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final isSelected = _selectedProvince == value;
    
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProvince = value;
            _errorMessage = null;
          });
          _startTypewriterEffect(_getProvinceDescription(value));
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 2 * scale,
            horizontal: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? Color(0xFFD4A574)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15 * scale),
            border: Border.all(
              color: isSelected ? Color(0xFFB8935F) : Colors.black38,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: Offset(0, 2 * scale),
                blurRadius: 4 * scale,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  String _getProvinceDescription(String province) {
    switch (province) {
      case 'sulaymaniyah':
        return 'شاری هەڵمەت و قوربانی';
      case 'erbil':
        return 'شاری هۆلاکۆ بەزێن';
      case 'duhok':
        return 'دهۆکی ڕەنگین و جوان';
      case 'halabja':
        return 'شاری شەهیدان';
      default:
        return '';
    }
  }
}
