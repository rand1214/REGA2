import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DialectSelectionBottomSheet extends StatefulWidget {
  const DialectSelectionBottomSheet({super.key});

  @override
  State<DialectSelectionBottomSheet> createState() => _DialectSelectionBottomSheetState();
}

class _DialectSelectionBottomSheetState extends State<DialectSelectionBottomSheet> with TickerProviderStateMixin {
  String? _selectedDialect;
  late AnimationController _infoAnimationController;
  late AnimationController _dropdownAnimationController;
  bool _showInfoDropdown = false;
  String? _expandedSection;
  String _displayedSubtitle = '';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _infoAnimationController = AnimationController(vsync: this);
    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
    _infoAnimationController.dispose();
    _dropdownAnimationController.dispose();
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startTypewriterEffect(String text) async {
    // Fade out existing text
    if (_displayedSubtitle.isNotEmpty) {
      await _fadeController.reverse();
    }
    
    // Cancel any existing timer and reset
    _typewriterTimer?.cancel();
    _charIndex = 0;
    _displayedSubtitle = '';
    
    // Fade in and start typing
    _fadeController.forward();
    
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_charIndex < text.length) {
        setState(() {
          _displayedSubtitle = text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _playInfoAnimation() {
    _infoAnimationController.reset();
    _infoAnimationController.forward();
    
    if (_showInfoDropdown) {
      // Closing: animate out first, then hide
      _dropdownAnimationController.reverse().then((_) {
        setState(() {
          _showInfoDropdown = false;
          _expandedSection = null;
        });
      });
    } else {
      // Opening: show first, then animate in
      setState(() {
        _showInfoDropdown = true;
      });
      _dropdownAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return PopScope(
      canPop: false,
      child: GestureDetector(
      onTap: () {
        // Close dropdown when tapping anywhere in the sheet
        if (_showInfoDropdown) {
          _dropdownAnimationController.reverse().then((_) {
            setState(() {
              _showInfoDropdown = false;
              _expandedSection = null;
            });
          });
        }
      },
      child: Container(
      height: screenHeight * 0.4,
      decoration: BoxDecoration(
        color: Color(0xFFF1F1F1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24 * scale),
          topRight: Radius.circular(24 * scale),
        ),
      ),
      child: Stack(
        children: [
          Column(
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
                      Transform.translate(
                        offset: Offset(0, -15 * scale),
                        child: Image.asset(
                          'assets/images/Flag-Map_Kurdistan.png',
                          width: 120 * scale,
                          height: 120 * scale,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -23 * scale),
                        child: Text(
                          'زارەوەی شیرینت هەڵبژێرە',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 12 * scale,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12 * scale),
                  
                  // Dialect options
                  Transform.translate(
                    offset: Offset(0, -20 * scale),
                    child: Column(
                      children: [
                        _buildDialectOption('sorani', 'سۆرانی', scale, subtitle: 'بە هیوای سەرکەوتن'),
                        SizedBox(height: 12 * scale),
                        _buildDialectOption('badini', 'بادینی', scale, subtitle: 'بە هیوای سەرکەوتن'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 12 * scale),
                  
                  // Continue button
                  Transform.translate(
                    offset: Offset(0, -20 * scale),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10 * scale),
                      elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    child: InkWell(
                      onTap: _selectedDialect == null ? null : () {
                        // Just close the sheet - no navigation
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(10 * scale),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _selectedDialect != null
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF2d2d2d),
                                    Color(0xFF1a1a1a),
                                    Color(0xFF0d0d0d),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.0, 0.5, 1.0],
                                )
                              : LinearGradient(
                                  colors: [Colors.grey.shade400, Colors.grey.shade400],
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
                            'دواتر',
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
      
      // Info icon and dropdown at top right (in top layer)
      Positioned(
        top: 20 * scale,
        right: 24 * scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                _playInfoAnimation();
              },
              child: SizedBox(
                width: 24 * scale,
                height: 24 * scale,
                child: Lottie.asset(
                  'assets/icons/info-icon.json',
                  controller: _infoAnimationController,
                  onLoaded: (composition) {
                    _infoAnimationController.duration = composition.duration;
                    _infoAnimationController.value = 1.0; // Start at end (bold state)
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
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: Offset(0, 4 * scale),
                          blurRadius: 12 * scale,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Section 1: What is dialect?
                        _buildHelpSection(
                          scale: scale,
                          sectionId: 'what_dialect',
                          title: 'زاراوە چییە ؟',
                          content: 'زاراوە جۆرێکە لە زمانی کوردی کە لە هەرێمێکدا بە شێوەیەکی جیاواز قسە دەکرێت',
                        ),
                        Divider(height: 1 * scale, color: Colors.grey.shade300),
                        
                        // Section 2: Difference between Sorani and Badini
                        _buildHelpSection(
                          scale: scale,
                          sectionId: 'difference',
                          title: 'جیاوازی "سۆرانی" و "بادینی" چییە ؟',
                          content: '"سۆرانی" لە سلێمانی و هەولێر قسەی پێ دەکرێت، "بادینی" لە دهۆک و زۆربەی باکووری کوردستان قسەی پێ دەکرێت',
                        ),
                        Divider(height: 1 * scale, color: Colors.grey.shade300),
                        
                        // Section 3: Which one should I choose?
                        _buildHelpSection(
                          scale: scale,
                          sectionId: 'which_choose',
                          title: 'کامیان هەڵبژێرم ؟',
                          content: 'ئەو زاراوەیە هەڵبژێرە کە تۆ قسەی پێ دەکەیت یان باشتر لێی تێدەگەیت',
                        ),
                        Divider(height: 1 * scale, color: Colors.grey.shade300),
                        
                        // Section 4: How to select?
                        _buildHelpSection(
                          scale: scale,
                          sectionId: 'how_select',
                          title: 'چۆن هەڵبژێرم ؟',
                          content: 'کلیک بکە لەسەر "سۆرانی" یان "بادینی" بۆ هەڵبژاردنی زاراوەکەت',
                        ),
                        Divider(height: 1 * scale, color: Colors.grey.shade300),
                        
                        // Section 5: How to proceed?
                        _buildHelpSection(
                          scale: scale,
                          sectionId: 'how_proceed',
                          title: 'چۆن بەردەوام بم ؟',
                          content: 'دوای هەڵبژاردنی زاراوە، دوگمەی "دواتر" داگرە بۆ بەردەوامبوون',
                        ),
                      ],
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

  Widget _buildDialectOption(String value, String label, double scale, {String? subtitle}) {
    final isSelected = _selectedDialect == value;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: SizedBox(
        width: screenWidth * 0.7,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDialect = value;
            });
            if (subtitle != null) {
              _startTypewriterEffect(subtitle);
            }
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 12 * scale),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: Offset(0, 2 * scale),
                    blurRadius: 8 * scale,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 20 * scale), // Spacer for balance
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.green.shade700 : Colors.black,
                            ),
                          ),
                          if (isSelected && _displayedSubtitle.isNotEmpty) ...[
                            SizedBox(height: 2 * scale),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                _displayedSubtitle,
                                style: TextStyle(
                                  fontFamily: 'Peshang',
                                  fontSize: 10 * scale,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2 * scale),
                    child: Image.asset(
                      'assets/images/Flag_of_Kurdistan.png',
                      width: 20 * scale,
                      height: 14 * scale,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(width: 20 * scale, height: 14 * scale);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required double scale,
    required String sectionId,
    required String title,
    required String content,
  }) {
    final isExpanded = _expandedSection == sectionId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedSection = isExpanded ? null : sectionId;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 4 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16 * scale,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 6 * scale),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 11 * scale,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(height: 6 * scale),
                        _buildStyledText(content, scale),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledText(String text, double scale) {
    // Split text and apply colors to specific phrases
    final spans = <TextSpan>[];
    final parts = text.split('"');
    
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Text inside quotes
        Color color = Colors.black54;
        if (parts[i] == 'سۆرانی') {
          color = Colors.green.shade700;
        } else if (parts[i] == 'بادینی') {
          color = Colors.orange.shade700;
        } else if (parts[i] == 'دواتر') {
          color = Colors.black;
        }
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 10 * scale,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else {
        // Regular text
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 10 * scale,
            color: Colors.black54,
            height: 1.4,
          ),
        ));
      }
    }
    
    return RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }
}
