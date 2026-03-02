import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'province_selection_bottom_sheet.dart';
import 'recovery_code_entry_bottom_sheet.dart';

class ProfileSetupBottomSheet extends StatefulWidget {
  final String? dialect;
  
  const ProfileSetupBottomSheet({
    super.key,
    this.dialect,
  });

  @override
  State<ProfileSetupBottomSheet> createState() => _ProfileSetupBottomSheetState();
}

class _ProfileSetupBottomSheetState extends State<ProfileSetupBottomSheet> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _infoAnimationController;
  late AnimationController _dropdownAnimationController;

  String? _errorMessage;
  String? _selectedGender = 'male'; // Default to male
  bool _showInfoDropdown = false;
  String? _expandedSection; // Track which section is expanded
  
  // Typewriter effect for description
  String _displayedDescription = 'تکایە زانیاری درووست داخل بکە';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasEnglishCharacters = false;
  bool _isShowingErrorMessage = false;

  bool get _isNameValid {
    final name = _nameController.text.trim();
    return name.split(' ').where((word) => word.isNotEmpty).length >= 3 && !_hasEnglishCharacters;
  }

  bool get _isFormValid => _isNameValid && _selectedGender != null;
  
  bool _containsEnglishCharacters(String text) {
    // Check if text contains English letters (a-z, A-Z)
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

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
    _fadeController.forward(); // Start with text visible
  }

  @override
  void dispose() {
    _nameController.dispose();
    _infoAnimationController.dispose();
    _dropdownAnimationController.dispose();
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startTypewriterEffect(String text, {bool isError = false}) async {
    // Fade out existing text
    if (_displayedDescription.isNotEmpty) {
      await _fadeController.reverse();
    }
    
    // Cancel any existing timer and reset
    _typewriterTimer?.cancel();
    _charIndex = 0;
    _displayedDescription = '';
    
    // Update error state AFTER fade out completes
    setState(() {
      _isShowingErrorMessage = isError;
    });
    
    // Fade in and start typing
    _fadeController.forward();
    
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (_charIndex < text.length) {
        setState(() {
          _displayedDescription = text.substring(0, _charIndex + 1);
        });
        _charIndex++;
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
          _expandedSection = null; // Close all sections when dropdown closes
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

  void _navigateToProvinceSelection() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'تکایە ناوی خۆت بنووسە';
      });
      return;
    }

    // Validate name has at least 3 words (first + middle + last)
    if (name.split(' ').where((word) => word.isNotEmpty).length < 3) {
      setState(() {
        _errorMessage = 'تکایە ناوی تەواو بنووسە (ناوی یەکەم و دووەم و سێیەم)';
      });
      return;
    }

    // Close current sheet
    Navigator.of(context).pop();

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 300));

    // Show province selection sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
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
        builder: (context) => ProvinceSelectionBottomSheet(
          kurdishName: name,
          avatarUrl: null,
          gender: _selectedGender,
          dialect: widget.dialect,
        ),
      );
    }
  }

  void _navigateToRecovery() async {
    // Close current sheet
    Navigator.of(context).pop();

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 300));

    // Show recovery code entry sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
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
        builder: (context) => const RecoveryCodeEntryBottomSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
        height: screenHeight * 0.4, // 40% of screen height
        decoration: BoxDecoration(
          color: Color(0xFFF1F1F1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24 * scale),
            topRight: Radius.circular(24 * scale),
          ),
        ),
        child: Stack(
          children: [
            // Drag handle
            Positioned(
              top: 8 * scale,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40 * scale,
                  height: 4 * scale,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Title with Lottie animation
                Column(
                  children: [
                    Lottie.asset(
                      'assets/icons/profile-icon-reveal.json',
                      width: 80 * scale,
                      height: 80 * scale,
                      fit: BoxFit.contain,
                      repeat: false,
                    ),
                    SizedBox(height: 4 * scale),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _displayedDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 12 * scale,
                          color: _isShowingErrorMessage ? Colors.red.shade700 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Name input with gender selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: Offset(0, 2 * scale),
                            blurRadius: 8 * scale,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        onChanged: (value) {
                          final hasEnglish = _containsEnglishCharacters(value);
                          final previousHasEnglish = _hasEnglishCharacters;
                          
                          setState(() {
                            _hasEnglishCharacters = hasEnglish;
                            // Clear error when form becomes valid
                            if (_isFormValid) {
                              _errorMessage = null;
                            }
                          });
                          
                          // Only trigger message change when state actually changes
                          if (hasEnglish && !previousHasEnglish && !_isShowingErrorMessage) {
                            // First English character detected - show error
                            _startTypewriterEffect('تکایە ناوەکەت بە زمانی شیرینی کوردی بنووسە', isError: true);
                          } else if (!hasEnglish && previousHasEnglish && _isShowingErrorMessage) {
                            // All English removed - go back to default message
                            _startTypewriterEffect('تکایە زانیاری درووست داخل بکە');
                          }
                        },
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 13 * scale,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ناوی تەواو',
                          hintStyle: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 13 * scale,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10 * scale),
                            borderSide: _isFormValid 
                                ? BorderSide(color: Colors.green, width: 2 * scale)
                                : _hasEnglishCharacters
                                    ? BorderSide(color: Colors.red, width: 2 * scale)
                                    : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10 * scale),
                            borderSide: _isFormValid 
                                ? BorderSide(color: Colors.green, width: 2 * scale)
                                : _hasEnglishCharacters
                                    ? BorderSide(color: Colors.red, width: 2 * scale)
                                    : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10 * scale),
                            borderSide: _isFormValid 
                                ? BorderSide(color: Colors.green, width: 2 * scale)
                                : _hasEnglishCharacters
                                    ? BorderSide(color: Colors.red, width: 2 * scale)
                                    : BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14 * scale,
                            vertical: 12 * scale,
                          ),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 8 * scale, right: 8 * scale),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Male icon
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = 'male';
                                      // Clear error when form becomes valid
                                      if (_isFormValid) {
                                        _errorMessage = null;
                                      }
                                    });
                                  },
                                  child: Icon(
                                    Icons.male,
                                    size: 20 * scale,
                                    color: _selectedGender == 'male' ? Colors.blue : Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                // Female icon
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = 'female';
                                      // Clear error when form becomes valid
                                      if (_isFormValid) {
                                        _errorMessage = null;
                                      }
                                    });
                                  },
                                  child: Icon(
                                    Icons.female,
                                    size: 20 * scale,
                                    color: _selectedGender == 'female' ? Colors.pink : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3 * scale),
                    Padding(
                      padding: EdgeInsets.only(right: 4 * scale),
                      child: Text(
                        'نموونە: ئازاد محەمەد ئەحمەد',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Peshang',
                          fontSize: 10 * scale,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(6 * scale),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFF1F1F1), // Same as sheet background
                          Colors.red.shade50,
                          Colors.red.shade50,
                          Color(0xFFF1F1F1), // Same as sheet background
                        ],
                        stops: const [0.0, 0.1, 0.9, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
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
                
                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Continue button
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10 * scale),
                      elevation: _isFormValid ? 4 : 0,
                      shadowColor: Colors.black.withValues(alpha: 0.4),
                      child: InkWell(
                          onTap: _isFormValid ? _navigateToProvinceSelection : null,
                          borderRadius: BorderRadius.circular(10 * scale),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: _isFormValid
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
                                      colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade400,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(10 * scale),
                              border: Border.all(
                                color: _isFormValid 
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Container(
                              height: 40 * scale,
                              alignment: Alignment.center,
                              child: Text(
                                'خۆ تۆمارکردن',
                                style: TextStyle(
                                  fontFamily: 'Peshang',
                                  fontSize: 15 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: _isFormValid ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 8 * scale),
                    // Recovery text button
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              offset: Offset(0, 1 * scale),
                              blurRadius: 3 * scale,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: _navigateToRecovery,
                          child: Text(
                            'هێنانەوەی هەژمار ؟',
                            style: TextStyle(
                              fontFamily: 'Peshang',
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.normal,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
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
                            // Section 1: Why do we need your name?
                            _buildHelpSection(
                              scale: scale,
                              sectionId: 'name_reason',
                              title: 'بۆچی پێویستان بە ناومە ؟',
                              content: 'ناوەکەت بۆ دروستکردنی پرۆفایلی تایبەت بە خۆت بەکاردێت و یارمەتیدەرە بۆ ناسینەوەی هەژمارەکەت',
                            ),
                            Divider(height: 1 * scale, color: Colors.grey.shade300),
                            
                            // Section 2: How to write your name?
                            _buildHelpSection(
                              scale: scale,
                              sectionId: 'name_format',
                              title: 'چۆن ناوەکەم بنووسم ؟',
                              content: 'تکایە ناوی تەواوت بنووسە بە سێ بەش: ناوی یەکەم، ناوی دووەم و ناوی سێیەم\nنموونە: ئازاد محەمەد ئەحمەد',
                            ),
                            Divider(height: 1 * scale, color: Colors.grey.shade300),
                            
                            // Section 3: How to choose gender?
                            _buildHelpSection(
                              scale: scale,
                              sectionId: 'gender_selection',
                              title: 'چۆن ڕەگەز هەڵبژێرم ؟',
                              content: 'لە لای چەپی خانەی ناو، دوو وێنەی ڕەگەز هەیە. کلیک بکە لەسەر وێنەی "نێر" یان "مێ" بۆ هەڵبژاردنی ڕەگەزەکەت',
                            ),
                            Divider(height: 1 * scale, color: Colors.grey.shade300),
                            
                            // Section 4: How should I proceed?
                            _buildHelpSection(
                              scale: scale,
                              sectionId: 'proceed',
                              title: 'چۆن بەردەوام بم ؟',
                              content: 'دوای نووسینی ناوی تەواو و هەڵبژاردنی ڕەگەز، دوگمەی "خۆ تۆمارکردن" داگرە و دەتوانیت بەردەوام بیت',
                            ),
                            Divider(height: 1 * scale, color: Colors.grey.shade300),
                            
                            // Section 5: How to get back old account?
                            _buildHelpSection(
                              scale: scale,
                              sectionId: 'recovery',
                              title: 'چۆن هەژماری کۆنم بگەڕێنمەوە ؟',
                              content: 'ئەگەر هەژمارێکی کۆنت هەیە، کلیک بکە لەسەر "هێنانەوەی هەژمار ؟" لە خوارەوە و کۆدی گەڕانەوەکەت و ناوەکەت بنووسە',
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
        if (parts[i] == 'خۆ تۆمارکردن') {
          color = Colors.black;
        } else if (parts[i] == 'هێنانەوەی هەژمار ؟') {
          color = Colors.blue;
        } else if (parts[i] == 'نێر') {
          color = Colors.blue;
        } else if (parts[i] == 'مێ') {
          color = Colors.pink;
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
