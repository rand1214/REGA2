import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/device_auth_service.dart';
import '../../../core/services/fcm_service.dart';
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
  State<ProvinceSelectionBottomSheet> createState() =>
      _ProvinceSelectionBottomSheetState();
}

class _ProvinceSelectionBottomSheetState
    extends State<ProvinceSelectionBottomSheet>
    with TickerProviderStateMixin {
  final DeviceAuthService _authService = DeviceAuthService();

  String? _selectedProvince;
  bool _isLoading = false;
  String _displayedText = '';
  bool _isShowingErrorMessage = false;
  Timer? _typewriterTimer;
  int _charIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _infoAnimationController;
  late AnimationController _dropdownAnimationController;

  bool _showInfoDropdown = false;
  String? _expandedSection;

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

    _infoAnimationController = AnimationController(vsync: this);

    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    _infoAnimationController.dispose();
    _dropdownAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startTypewriterEffect(String text, {bool isError = false}) async {
    if (_displayedText.isNotEmpty) {
      await _fadeController.reverse();
      if (!mounted) return;
    }

    _typewriterTimer?.cancel();
    _charIndex = 0;
    _displayedText = '';

    if (!mounted) return;
    setState(() {
      _isShowingErrorMessage = isError;
    });

    _fadeController.forward();

    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

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

  Future<void> _completeSetup() async {
    if (_selectedProvince == null) {
      await _startTypewriterEffect(
        'تکایە پارێزگایەک هەڵبژێرە',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final NavigatorState localNavigator = Navigator.of(context);
      final NavigatorState rootNavigator =
          Navigator.of(context, rootNavigator: true);

      final result = await _authService.createNewUser(
        kurdishName: widget.kurdishName,
        avatarUrl: widget.avatarUrl,
        gender: widget.gender,
        province: _selectedProvince,
        dialect: widget.dialect,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        FcmService.registerTokenForCurrentUser();

        final recoveryCode = result['recoveryCode'];

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
          builder: (_) => RecoveryCodeDisplayBottomSheet(
            recoveryCode: recoveryCode,
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        await _startTypewriterEffect(
          'هەڵەیەک ڕوویدا، دووبارە هەوڵ بدەرەوە',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await _startTypewriterEffect(
        'هەڵەیەک ڕوویدا، دووبارە هەوڵ بدەرەوە',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double scale = (screenWidth / 375).clamp(0.8, 1.5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300 &&
              mounted) {
            Navigator.of(context).pop();
          }
        },
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
        child: Container(
          height: screenHeight * 0.5,
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
                                child: _selectedProvince != null ||
                                        _isShowingErrorMessage
                                    ? FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: Text(
                                          _displayedText,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Peshang',
                                            fontSize: 12 * scale,
                                            color: _isShowingErrorMessage
                                                ? Colors.red.shade700
                                                : Colors.black54,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scale),
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
                                          Image.asset(
                                            'assets/images/Map-Kurdistan.PNG',
                                            fit: BoxFit.contain,
                                          ),
                                          _buildProvinceButton(
                                            'duhok',
                                            'دهۆک',
                                            scale,
                                            top: constraints.maxHeight * 0.12 + 3,
                                            left: constraints.maxWidth * 0.35,
                                          ),
                                          _buildProvinceButton(
                                            'erbil',
                                            'هەولێر',
                                            scale,
                                            top: constraints.maxHeight * 0.25,
                                            left: constraints.maxWidth * 0.45,
                                          ),
                                          _buildProvinceButton(
                                            'sulaymaniyah',
                                            'سلێمانی',
                                            scale,
                                            top: constraints.maxHeight * 0.35 + 3,
                                            right:
                                                constraints.maxWidth * 0.20 - 3,
                                          ),
                                          _buildProvinceButton(
                                            'halabja',
                                            'هەڵەبجە',
                                            scale,
                                            top: constraints.maxHeight * 0.47 + 4,
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
                          Transform.translate(
                            offset: Offset(0, -20 * scale),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10 * scale),
                              elevation: 4,
                              shadowColor:
                                  Colors.black.withValues(alpha: 0.4),
                              child: InkWell(
                                onTap: _isLoading ? null : _completeSetup,
                                borderRadius: BorderRadius.circular(10 * scale),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0080C8),
                                        Color(0xFF004A73),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(10 * scale),
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
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 240 * scale,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.15),
                                  offset: Offset(0, 4 * scale),
                                  blurRadius: 12 * scale,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildHelpSection(
                                  scale: scale,
                                  sectionId: 'what_province',
                                  title: 'پارێزگا چییە ؟',
                                  content:
                                      'پارێزگا ناوچەیەکی ئیداری یە لە هەرێمی کوردستان، هەر پارێزگایەک شارەکانی خۆی هەیە',
                                ),
                                Divider(
                                  height: 1 * scale,
                                  color: Colors.grey.shade300,
                                ),
                                _buildHelpSection(
                                  scale: scale,
                                  sectionId: 'why_province',
                                  title: 'بۆچی پارێزگام پێویستە ؟',
                                  content:
                                      'پارێزگاکەت یارمەتیدەرە بۆ دیاریکردنی زاراوە و ناوچەی تۆ بۆ باشترکردنی ئەزموونەکەت',
                                ),
                                Divider(
                                  height: 1 * scale,
                                  color: Colors.grey.shade300,
                                ),
                                _buildHelpSection(
                                  scale: scale,
                                  sectionId: 'how_select',
                                  title: 'چۆن هەڵبژێرم ؟',
                                  content:
                                      'کلیک بکە لەسەر ناوی پارێزگاکەت لەسەر نەخشەکە',
                                ),
                                Divider(
                                  height: 1 * scale,
                                  color: Colors.grey.shade300,
                                ),
                                _buildHelpSection(
                                  scale: scale,
                                  sectionId: 'how_proceed',
                                  title: 'چۆن بەردەوام بم ؟',
                                  content:
                                      'دوای هەڵبژاردنی پارێزگا، دوگمەی "دەستپێبکە" داگرە بۆ دروستکردنی هەژمارەکەت',
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

  Widget _buildProvinceButton(
    String value,
    String label,
    double scale, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final bool isSelected = _selectedProvince == value;

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProvince = value;
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
                ? const Color(0xFFD4A574)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15 * scale),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFB8935F)
                  : Colors.black38,
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
              fontSize: 9.5 * scale,
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

  Widget _buildHelpSection({
    required double scale,
    required String sectionId,
    required String title,
    required String content,
  }) {
    final bool isExpanded = _expandedSection == sectionId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _expandedSection = isExpanded ? null : sectionId;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 8 * scale,
          horizontal: 4 * scale,
        ),
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
                        Text(
                          content,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 10 * scale,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}