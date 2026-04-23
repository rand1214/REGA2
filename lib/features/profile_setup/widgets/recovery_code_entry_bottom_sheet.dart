import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/device_auth_service.dart';
import 'recovery_request_status_bottom_sheet.dart';

class RecoveryCodeEntryBottomSheet extends StatefulWidget {
  const RecoveryCodeEntryBottomSheet({super.key});

  @override
  State<RecoveryCodeEntryBottomSheet> createState() =>
      _RecoveryCodeEntryBottomSheetState();
}

class _RecoveryCodeEntryBottomSheetState
    extends State<RecoveryCodeEntryBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final DeviceAuthService _authService = DeviceAuthService();

  late AnimationController _infoAnimationController;
  late AnimationController _dropdownAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _showInfoDropdown = false;
  String? _expandedSection;

  String _displayedDescription = 'کۆد و ناوی تەواوت بنووسە';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  bool _hasError = false;
  bool _isShowingErrorMessage = false;
  bool _hasEnglishInName = false;

  bool get _isNameValid {
    final name = _nameController.text.trim();
    return name.split(' ').where((word) => word.isNotEmpty).length >= 3 &&
        !_hasEnglishInName;
  }

  bool get _isCodeValid {
    final code = _codeController.text.replaceAll('-', '').trim();
    return code.length == 8;
  }

  bool get _isFormValid => _isCodeValid && _isNameValid;

  bool _containsEnglishCharacters(String text) {
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

    _fadeController.forward();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _codeController.dispose();
    _nameController.dispose();
    _infoAnimationController.dispose();
    _dropdownAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startTypewriterEffect(String text, {bool isError = false}) async {
    if (_displayedDescription.isNotEmpty) {
      await _fadeController.reverse();
      if (!mounted) return;
    }

    _typewriterTimer?.cancel();
    _charIndex = 0;
    _displayedDescription = '';

    if (!mounted) return;
    setState(() {
      _isShowingErrorMessage = isError;
    });

    _fadeController.forward();

    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

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
      _dropdownAnimationController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _showInfoDropdown = false;
          _expandedSection = null;
        });
      });
    } else {
      setState(() {
        _showInfoDropdown = true;
      });
      _dropdownAnimationController.forward();
    }
  }

  Future<void> _submitRecoveryRequest() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    if (code.isEmpty || !_isNameValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final NavigatorState localNavigator = Navigator.of(context);
      final NavigatorState rootNavigator =
          Navigator.of(context, rootNavigator: true);

      final result = await _authService.submitRecoveryRequest(code, name);

      if (!mounted) return;

      if (result['success'] == true) {
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
          builder: (_) => RecoveryRequestStatusBottomSheet(
            recoveryCode: code,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });

        await _startTypewriterEffect('کۆدی گەڕانەوە هەڵەیە', isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      await _startTypewriterEffect('کۆدی گەڕانەوە هەڵەیە', isError: true);
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
          if (_showInfoDropdown) {
            _dropdownAnimationController.reverse().then((_) {
              if (!mounted) return;
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
            height: screenHeight * 0.4,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24 * scale),
                topRight: Radius.circular(24 * scale),
              ),
            ),
            child: Stack(
              children: [
                Column(
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 24 * scale,
                          vertical: 12 * scale,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'گەڕانەوەی هەژمار',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 24 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
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
                                      color: _isShowingErrorMessage
                                          ? Colors.red.shade700
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Center(
                              child: SizedBox(
                                width: screenWidth * 0.9,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10 * scale),
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
                                        controller: _codeController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 9,
                                        onChanged: (value) {
                                          final digitsOnly =
                                              value.replaceAll(RegExp(r'[^0-9]'), '');

                                          if (digitsOnly.length > 4) {
                                            final formatted =
                                                '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
                                            if (formatted != value) {
                                              _codeController.value = TextEditingValue(
                                                text: formatted,
                                                selection: TextSelection.collapsed(
                                                  offset: formatted.length,
                                                ),
                                              );
                                            }
                                          }

                                          setState(() {
                                            if (_hasError &&
                                                digitsOnly.length < 8 &&
                                                _isShowingErrorMessage) {
                                              _hasError = false;
                                            }
                                          });

                                          if (!_hasError &&
                                              _displayedDescription !=
                                                  'کۆد و ناوی تەواوت بنووسە' &&
                                              !_hasEnglishInName &&
                                              !_isShowingErrorMessage) {
                                            return;
                                          }

                                          if (!_hasEnglishInName &&
                                              !_isShowingErrorMessage &&
                                              !_hasError) {
                                            return;
                                          }

                                          if (!_hasEnglishInName &&
                                              !_hasError &&
                                              _isShowingErrorMessage) {
                                            _startTypewriterEffect('کۆد و ناوی تەواوت بنووسە');
                                          }
                                        },
                                        style: TextStyle(
                                          fontFamily: 'Prototype',
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '1234-5678',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Prototype',
                                            fontSize: 16 * scale,
                                            color: Colors.grey.shade300,
                                            letterSpacing: 4,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10 * scale),
                                            borderSide: _hasError
                                                ? BorderSide(
                                                    color: Colors.red,
                                                    width: 2 * scale,
                                                  )
                                                : BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10 * scale),
                                            borderSide: _hasError
                                                ? BorderSide(
                                                    color: Colors.red,
                                                    width: 2 * scale,
                                                  )
                                                : BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10 * scale),
                                            borderSide: _hasError
                                                ? BorderSide(
                                                    color: Colors.red,
                                                    width: 2 * scale,
                                                  )
                                                : BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14 * scale,
                                            vertical: 6 * scale,
                                          ),
                                          counterText: '',
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8 * scale),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10 * scale),
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
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                        onChanged: (value) {
                                          final hasEnglish =
                                              _containsEnglishCharacters(value);
                                          final previousHasEnglish =
                                              _hasEnglishInName;

                                          setState(() {
                                            _hasEnglishInName = hasEnglish;
                                          });

                                          if (hasEnglish &&
                                              !previousHasEnglish &&
                                              !_isShowingErrorMessage) {
                                            _startTypewriterEffect(
                                              'تکایە ناوەکەت بە زمانی شیرینی کوردی بنووسە',
                                              isError: true,
                                            );
                                          } else if (!hasEnglish &&
                                              previousHasEnglish &&
                                              _isShowingErrorMessage &&
                                              !_hasError) {
                                            _startTypewriterEffect(
                                              'کۆد و ناوی تەواوت بنووسە',
                                            );
                                          }
                                        },
                                        style: TextStyle(
                                          fontFamily: 'Peshang',
                                          fontSize: 16 * scale,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'ناوی تەواو',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Peshang',
                                            fontSize: 16 * scale,
                                            color: Colors.grey.shade400,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10 * scale),
                                            borderSide: _isNameValid
                                                ? const BorderSide(
                                                    color: Colors.green,
                                                    width: 2,
                                                  )
                                                : _hasEnglishInName
                                                    ? BorderSide(
                                                        color: Colors.red,
                                                        width: 2 * scale,
                                                      )
                                                    : BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10 * scale),
                                            borderSide: _isNameValid
                                                ? const BorderSide(
                                                    color: Colors.green,
                                                    width: 2,
                                                  )
                                                : _hasEnglishInName
                                                    ? BorderSide(
                                                        color: Colors.red,
                                                        width: 2 * scale,
                                                      )
                                                    : BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10 * scale),
                                            borderSide: _isNameValid
                                                ? const BorderSide(
                                                    color: Colors.green,
                                                    width: 2,
                                                  )
                                                : _hasEnglishInName
                                                    ? BorderSide(
                                                        color: Colors.red,
                                                        width: 2 * scale,
                                                      )
                                                    : BorderSide(
                                                        color: Colors.grey.shade300,
                                                        width: 1,
                                                      ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14 * scale,
                                            vertical: 6 * scale,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 3 * scale),
                                    Padding(
                                      padding: EdgeInsets.only(right: 4 * scale),
                                      child: Text(
                                        'ناوی یەکەم و دووەم و سێیەم',
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
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10 * scale),
                              elevation: _isFormValid ? 4 : 0,
                              shadowColor: Colors.black.withValues(alpha: 0.4),
                              child: InkWell(
                                onTap: (_isLoading || !_isFormValid)
                                    ? null
                                    : _submitRecoveryRequest,
                                borderRadius: BorderRadius.circular(10 * scale),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: _isFormValid
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF0080C8),
                                              Color(0xFF004A73),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey.shade400,
                                              Colors.grey.shade400,
                                            ],
                                          ),
                                    borderRadius:
                                        BorderRadius.circular(10 * scale),
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
                                            'گەڕانەوەی هەژمار',
                                            style: TextStyle(
                                              fontFamily: 'Peshang',
                                              fontSize: 15 * scale,
                                              fontWeight: FontWeight.bold,
                                              color: _isFormValid
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
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
                Positioned(
                  top: 20 * scale,
                  right: 24 * scale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _playInfoAnimation,
                        child: SizedBox(
                          width: 26 * scale,
                          height: 26 * scale,
                          child: Lottie.asset(
                            'assets/icons/info-icon.json',
                            controller: _infoAnimationController,
                            onLoaded: (composition) {
                              _infoAnimationController.duration =
                                  composition.duration;
                              _infoAnimationController.value = 1.0;
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
                            child: Container(
                              width: 240 * scale,
                              constraints: BoxConstraints(
                                maxHeight: screenHeight * 0.25,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12 * scale),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    offset: Offset(0, 4 * scale),
                                    blurRadius: 12 * scale,
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildInfoSection(
                                      sectionId: 'what_is_code',
                                      title: 'کۆدی گەڕانەوە چییە ؟',
                                      content:
                                          'کۆدی گەڕانەوە ژمارەیەکی تایبەتە کە لە کاتی دروستکردنی هەژمارەکەت پێت دراوە بۆ گەڕانەوەی هەژمارەکەت لە ئامێرێکی تر یان لە کاتی سڕینەوە',
                                      scale: scale,
                                    ),
                                    _buildInfoSection(
                                      sectionId: 'why_name',
                                      title: 'بۆچی پێویستە ناوم بنووسم ؟',
                                      content:
                                          'ناوەکەت بۆ دڵنیابوون لە ئەوەیە کە تۆ خاوەنی ڕاستەقینەی ئەم هەژمارەی، داواکارییەکەت پێداچوونەوەی بۆ دەکرێت',
                                      scale: scale,
                                    ),
                                    _buildInfoSection(
                                      sectionId: 'how_long',
                                      title: 'چەند دەخایەنێت بۆ پەسەندکردن ؟',
                                      content:
                                          'داواکارییەکەت لە ماوەی ٢٤ کاتژمێردا پێداچوونەوەی بۆ دەکرێت، ئاگادارت دەکەینەوە کاتێک پەسەندکرا یان ڕەتکرایەوە',
                                      scale: scale,
                                    ),
                                    _buildInfoSection(
                                      sectionId: 'what_after',
                                      title: 'دوای ناردنی داواکاری چی دەبێت ؟',
                                      content:
                                          'داواکارییەکەت چاوەڕوانی پەسەندکردن دەبێت، دەتوانیت بارودۆخەکە لە ئەپەکە ببینیت',
                                      scale: scale,
                                    ),
                                    _buildInfoSection(
                                      sectionId: 'lost_code',
                                      title: 'ئەگەر کۆدەکەم ونبوو چی بکەم ؟',
                                      content:
                                          'بەداخەوە ئەگەر کۆدەکەت ونبوو، ناتوانیت هەژمارەکەت بگەڕێنیتەوە، پێویستە هەژمارێکی نوێ دروست بکەیت',
                                      scale: scale,
                                    ),
                                  ],
                                ),
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

  Widget _buildInfoSection({
    required String sectionId,
    required String title,
    required String content,
    required double scale,
  }) {
    final isExpanded = _expandedSection == sectionId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _expandedSection = isExpanded ? null : sectionId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 4 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20 * scale,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 4 * scale),
              _buildColoredText(content, scale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColoredText(String text, double scale) {
    final parts = text.split('"');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      Color color = Colors.black54;

      if (parts[i] == 'گەڕانەوەی هەژمار') {
        color = Colors.black;
      }

      spans.add(
        TextSpan(
          text: i < parts.length - 1
              ? parts[i] + (i % 2 == 0 ? '"' : '')
              : parts[i],
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 10 * scale,
            color: color,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(children: spans),
    );
  }
}