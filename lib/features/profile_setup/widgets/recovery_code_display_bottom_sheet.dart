import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/device_auth_service.dart';

class RecoveryCodeDisplayBottomSheet extends StatefulWidget {
  final String recoveryCode;

  const RecoveryCodeDisplayBottomSheet({
    super.key,
    required this.recoveryCode,
  });

  @override
  State<RecoveryCodeDisplayBottomSheet> createState() => _RecoveryCodeDisplayBottomSheetState();
}

class _RecoveryCodeDisplayBottomSheetState extends State<RecoveryCodeDisplayBottomSheet> with TickerProviderStateMixin {
  bool _isCopied = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _infoAnimationController;
  late AnimationController _dropdownAnimationController;
  bool _showInfoDropdown = false;
  String? _expandedSection;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _infoAnimationController = AnimationController(vsync: this);
    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _infoAnimationController.dispose();
    _dropdownAnimationController.dispose();
    super.dispose();
  }

  void _playInfoAnimation() {
    _infoAnimationController.reset();
    _infoAnimationController.forward();
    
    if (_showInfoDropdown) {
      _dropdownAnimationController.reverse().then((_) {
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

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.recoveryCode));
    setState(() {
      _isCopied = true;
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
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
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);
    final authService = DeviceAuthService();
    final formattedCode = authService.formatRecoveryCode(widget.recoveryCode);

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
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
        color: Colors.white,
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
            child: Stack(
              children: [
                SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 16 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Column(
                    children: [
                      Transform.translate(
                        offset: Offset(0, -20 * scale),
                        child: SizedBox(
                          width: 140 * scale,
                          height: 100 * scale,
                          child: OverflowBox(
                            maxWidth: 150 * scale,
                            maxHeight: 150 * scale,
                            child: Lottie.asset(
                              'assets/icons/Accepted.json',
                              fit: BoxFit.contain,
                              repeat: false,
                              frameRate: FrameRate.max,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -40 * scale),
                        child: Text(
                          '! هەژمارەکەت درووست کرا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  Transform.translate(
                    offset: Offset(0, -30 * scale),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  onPressed: () => _copyToClipboard(context),
                                  icon: Icon(
                                    Icons.copy,
                                    size: 14 * scale,
                                    color: _isCopied ? Colors.green : null,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  style: IconButton.styleFrom(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'کۆدی گەڕاندنەوەی هەژمار',
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 9 * scale,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formattedCode,
                              style: TextStyle(
                                fontFamily: 'Prototype',
                                fontSize: 22 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Transform.translate(
                    offset: Offset(0, -20 * scale),
                    child: Text(
                      'ئەم کۆدە بە تەنها ڕێگەیە بۆ گەڕاندنەوەی هەژمارەکەت. تکایە لە شوێنێکی پارێزراو هەڵیبگرە',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Peshang',
                        fontSize: 11 * scale,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  Transform.translate(
                    offset: Offset(0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'تێگەشتم',
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
                ),
              ),
            ),
            
            // Info icon and dropdown at top right
            Positioned(
              top: 8 * scale,
              right: 24 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _playInfoAnimation,
                    child: SizedBox(
                      width: 24 * scale,
                      height: 24 * scale,
                      child: Lottie.asset(
                        'assets/icons/info-icon.json',
                        controller: _infoAnimationController,
                        onLoaded: (composition) {
                          _infoAnimationController.duration = composition.duration;
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
                              _buildHelpSection(
                                scale: scale,
                                sectionId: 'what_is_code',
                                title: 'کۆدی گەڕاندنەوەی هەژمار چیە ؟',
                                content: 'ئەم کۆدە تەنها ڕێگەیە بۆ گەڕاندنەوەی هەژمارەکەت ئەگەر ئامێرەکەت لەدەست بدەیت یان ئەپەکە بسڕیتەوە',
                              ),
                              Divider(height: 1 * scale, color: Colors.grey.shade300),
                              
                              _buildHelpSection(
                                scale: scale,
                                sectionId: 'how_to_save',
                                title: 'چۆن هەڵیبگرم ؟',
                                content: 'کلیک بکە لەسەر وێنەی "کۆپی" لە لای چەپ بۆ کۆپیکردنی کۆدەکە، پاشان لە شوێنێکی پارێزراو وەک "نۆت" یان "وێنە" هەڵیبگرە',
                              ),
                              Divider(height: 1 * scale, color: Colors.grey.shade300),
                              
                              _buildHelpSection(
                                scale: scale,
                                sectionId: 'why_important',
                                title: 'بۆچی گرنگە ؟',
                                content: 'بەبێ ئەم کۆدە ناتوانیت هەژمارەکەت بگەڕێنیتەوە. هیچ ڕێگەیەکی تر نییە بۆ گەڕاندنەوەی هەژمار',
                              ),
                              Divider(height: 1 * scale, color: Colors.grey.shade300),
                              
                              _buildHelpSection(
                                scale: scale,
                                sectionId: 'when_to_use',
                                title: 'کەی بەکاری دێنم ؟',
                                content: 'ئەم کۆدە بەکاردێنە کاتێک دەتەوێت هەژمارەکەت لەسەر ئامێرێکی نوێ بگەڕێنیتەوە یان دوای سڕینەوەی ئەپەکە',
                              ),
                              Divider(height: 1 * scale, color: Colors.grey.shade300),
                              
                              _buildHelpSection(
                                scale: scale,
                                sectionId: 'how_to_continue',
                                title: 'چۆن بەردەوام بم ؟',
                                content: 'دوای هەڵگرتنی کۆدەکە، کلیک بکە لەسەر دوگمەی "تێگەشتم" بۆ دەستپێکردنی بەکارهێنانی ئەپەکە',
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
        ],
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
    final spans = <TextSpan>[];
    final parts = text.split('"');
    
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Text inside quotes - make it black and bold
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 10 * scale,
            color: Colors.black,
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
