import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/device_auth_service.dart';
import 'welcomer_1_screen.dart';
import 'welcomer_2_screen.dart';
import 'welcomer_3_screen.dart';

// Custom ScrollPhysics to prevent scrolling before first page
class CustomPageScrollPhysics extends ScrollPhysics {
  const CustomPageScrollPhysics({super.parent});

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Prevent scrolling to the left of the first page
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class WelcomeScreenWrapper extends StatefulWidget {
  const WelcomeScreenWrapper({super.key});

  @override
  State<WelcomeScreenWrapper> createState() => _WelcomeScreenWrapperState();
}

class _WelcomeScreenWrapperState extends State<WelcomeScreenWrapper> {
  final PageController _pageController = PageController();
  final DeviceAuthService _authService = DeviceAuthService();
  int _currentPage = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    // Detect when user tries to swipe beyond last page
    if (_pageController.hasClients && !_isNavigating) {
      final position = _pageController.position;
      
      // Check if user is trying to scroll past the last page (page 2)
      if (_currentPage == 2 && position.pixels > position.maxScrollExtent) {
        // User is over-scrolling on the last page
        final overScroll = position.pixels - position.maxScrollExtent;
        
        // Navigate when over-scroll exceeds threshold (50 pixels)
        if (overScroll > 50) {
          _navigateToHome();
        }
      }
    }
  }

  void _navigateToHome() {
    if (!_isNavigating) {
      _isNavigating = true;
      // Mark welcome as seen before navigating
      _authService.markWelcomeAsSeen();
      context.go('/home');
    }
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      // Go to next page with smooth animation
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page - navigate to home
      _navigateToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const CustomPageScrollPhysics(parent: BouncingScrollPhysics()),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          Welcomer1Screen(
            currentPage: _currentPage,
            onNextPressed: _onNextPressed,
          ),
          Welcomer2Screen(
            currentPage: _currentPage,
            onNextPressed: _onNextPressed,
          ),
          Welcomer3Screen(
            currentPage: _currentPage,
            onNextPressed: _onNextPressed,
          ),
        ],
      ),
    );
  }
}
