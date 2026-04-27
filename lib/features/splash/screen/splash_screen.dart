import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/device_auth_service.dart';
import '../../../core/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  int activeLight = 0;
  late AnimationController _loadingController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final DeviceAuthService _authService = DeviceAuthService();

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleController.forward();
    _startAnimation();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    setState(() => activeLight = 0);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    setState(() => activeLight = 1);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() => activeLight = 2);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    // Check authentication status
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Check if user has seen welcome screens
      final hasSeenWelcome = await _authService.hasSeenWelcome();
      
      // If haven't seen welcome, go there first
      if (!hasSeenWelcome) {
        await _fadeController.forward();
        if (!mounted) return;
        context.go('/welcome');
        return;
      }
      
      // Check authentication status
      final isAuth = await _authService.isAuthenticated();
      
      if (isAuth) {
        // User is authenticated - update last login and preload data
        await _authService.updateLastLogin();
        
        // Preload user data and chapters in the background for faster home screen loading
        // Only if Supabase is initialized
        try {
          try {
            final _ = Supabase.instance.client;
            final supabaseService = SupabaseService();
            // Fetch user data and chapters in parallel - this will be cached
            await Future.wait([
              supabaseService.getUserKurdishName(),
              supabaseService.hasActiveSubscription(),
              supabaseService.getUnreadNotificationCount(),
              supabaseService.getChaptersWithProgress(), // Preload chapters with thumbnails
            ]);
          } catch (e) {
            // Supabase not initialized - skip preloading
          }
        } catch (e) {
          // Ignore errors - data will be fetched again on home screen if needed
        }
      }
      
      // Always go to home (whether authenticated or not)
      await _fadeController.forward();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      // On error, go to home
      await _fadeController.forward();
      if (!mounted) return;
      context.go('/home');
    }
  }

  Widget _buildLight(Color color, bool isActive, double scale) {
    final visorOuterWidth = 105.0 * scale;
    final visorOuterHeight = 105.0 * scale;
    final visorMainWidth = 101.0 * scale;
    final visorMainHeight = 101.0 * scale;
    final visorInnerWidth = 93.0 * scale;
    final visorInnerHeight = 93.0 * scale;
    final containerWidth = 85.0 * scale;
    final containerHeight = 85.0 * scale;
    final innerCircleWidth = 70.0 * scale;
    final innerCircleHeight = 70.0 * scale;
    final centerHighlightWidth = 20.0 * scale;
    final centerHighlightHeight = 20.0 * scale;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 3D Visor - outer shadow layer
        Positioned(
          top: -12 * scale,
          left: -10 * scale,
          right: -10 * scale,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.6,
              child: Container(
                width: visorOuterWidth,
                height: visorOuterHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.9),
                      blurRadius: 15 * scale,
                      offset: Offset(0, 8 * scale),
                      spreadRadius: 3 * scale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 3D Visor - main body
        Positioned(
          top: -10 * scale,
          left: -8 * scale,
          right: -8 * scale,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.58,
              child: Container(
                width: visorMainWidth,
                height: visorMainHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    center: Alignment.center,
                    startAngle: 3.14,
                    endAngle: 6.28,
                    colors: [
                      Color(0xFF050505),
                      Color(0xFF1A1A1A),
                      Color(0xFF2D2D2D),
                      Color(0xFF1A1A1A),
                      Color(0xFF050505),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 3D Visor - inner edge highlight
        Positioned(
          top: -6 * scale,
          left: -4 * scale,
          right: -4 * scale,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.52,
              child: Container(
                width: visorInnerWidth,
                height: visorInnerHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 6 * scale),
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D0D0D),
            border: Border.all(
              color: Colors.black,
              width: 4 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8 * scale,
                offset: Offset(0, 4 * scale),
                spreadRadius: -2 * scale,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15 * scale,
                offset: Offset(0, 8 * scale),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inactive state
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                opacity: isActive ? 0.0 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.25, 0.65, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Pixelated grid overlay
                      ClipOval(
                        child: CustomPaint(
                          painter: _PixelGridPainter(scale),
                          size: Size(containerWidth, containerHeight),
                        ),
                      ),
                      // Dotted outline
                      Center(
                        child: Container(
                          width: innerCircleWidth,
                          height: innerCircleHeight,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.15),
                              width: 1.5 * scale,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Active state
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                opacity: isActive ? 1.0 : 0.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bottom half glow
                    CustomPaint(
                      painter: _BottomGlowPainter(color, scale),
                      size: Size(containerWidth, containerHeight),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.95),
                            color.withValues(alpha: 1.0),
                            color.withValues(alpha: 0.85),
                            color.withValues(alpha: 0.6),
                          ],
                          stops: const [0.0, 0.25, 0.65, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Pixelated grid overlay
                          ClipOval(
                            child: CustomPaint(
                              painter: _PixelGridPainter(scale),
                              size: Size(containerWidth, containerHeight),
                            ),
                          ),
                          // Dotted outline
                          Center(
                            child: Container(
                              width: innerCircleWidth,
                              height: innerCircleHeight,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  width: 1.5 * scale,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                              ),
                            ),
                          ),
                          // Center highlight
                          Center(
                            child: Container(
                              width: centerHighlightWidth,
                              height: centerHighlightHeight,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.7),
                                    Colors.white.withValues(alpha: 0.2),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDot(int index, double scale) {
    final dotSize = 10.0 * scale;
    
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_loadingController.value - delay) % 1.0;
        final scaleValue = value < 0.5
            ? 1.0 + (value * 2) * 0.6
            : 1.6 - ((value - 0.5) * 2) * 0.6;

        return Transform.scale(
          scale: scaleValue.clamp(1.0, 1.6),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);
    
    // Adjust scale more aggressively for very small screens
    final isSmallScreen = screenHeight < 700;
    final adjustedScale = isSmallScreen ? scale * 0.85 : scale;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPainter(),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * (isSmallScreen ? 0.08 : 0.15)),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF1A1A1A),
                          Color(0xFF4A4A4A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Rêga',
                        style: TextStyle(
                          fontFamily: 'Prototype',
                          fontSize: 64 * adjustedScale,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          letterSpacing: 8 * adjustedScale,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: Offset(4 * adjustedScale, 4 * adjustedScale),
                              blurRadius: 12 * adjustedScale,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: Offset(2 * adjustedScale, 2 * adjustedScale),
                              blurRadius: 6 * adjustedScale,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 30 * adjustedScale : 50 * adjustedScale),
                    Container(
                      width: 165 * adjustedScale,
                      padding: EdgeInsets.symmetric(
                        vertical: 28 * adjustedScale,
                        horizontal: 40 * adjustedScale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(18 * adjustedScale),
                        border: Border.all(
                          color: Colors.black,
                          width: 3 * adjustedScale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 30 * adjustedScale,
                            offset: Offset(0, 15 * adjustedScale),
                            spreadRadius: -5 * adjustedScale,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15 * adjustedScale,
                            offset: Offset(0, 8 * adjustedScale),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLight(Colors.red.shade700, activeLight == 0, adjustedScale),
                          Container(
                            height: 2.5 * adjustedScale,
                            width: 85 * adjustedScale,
                            margin: EdgeInsets.symmetric(vertical: 8 * adjustedScale),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2 * adjustedScale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 2 * adjustedScale,
                                  offset: Offset(0, 1 * adjustedScale),
                                ),
                              ],
                            ),
                          ),
                          _buildLight(Colors.amber.shade500, activeLight == 1, adjustedScale),
                          Container(
                            height: 2.5 * adjustedScale,
                            width: 85 * adjustedScale,
                            margin: EdgeInsets.symmetric(vertical: 8 * adjustedScale),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2 * adjustedScale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 2 * adjustedScale,
                                  offset: Offset(0, 1 * adjustedScale),
                                ),
                              ],
                            ),
                          ),
                          _buildLight(Colors.green.shade600, activeLight == 2, adjustedScale),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(bottom: isSmallScreen ? screenHeight * 0.08 : screenHeight * 0.12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLoadingDot(0, adjustedScale),
                          SizedBox(width: 14 * adjustedScale),
                          _buildLoadingDot(1, adjustedScale),
                          SizedBox(width: 14 * adjustedScale),
                          _buildLoadingDot(2, adjustedScale),
                        ],
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
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topCenter,
        radius: 1.5,
        colors: [
          Colors.white,
          Color(0xFFFAFAFA),
          Color(0xFFF5F5F5),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomGlowPainter extends CustomPainter {
  final Color color;
  final double scale;

  _BottomGlowPainter(this.color, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple layers for smooth fade
    for (int i = 3; i > 0; i--) {
      final layerRadius = radius + (i * 15.0 * scale);
      final opacity = 0.15 / i;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * i * scale);

      // Draw only bottom half arc
      final path = Path();
      path.addArc(
        Rect.fromCircle(center: center, radius: layerRadius),
        0,
        3.14159,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PixelGridPainter extends CustomPainter {
  final double scale;

  _PixelGridPainter(this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.0 * scale
      ..style = PaintingStyle.stroke;

    final gridSize = 6.0 * scale;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
