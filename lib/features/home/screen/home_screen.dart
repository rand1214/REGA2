import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_content.dart';
import '../../../core/services/device_auth_service.dart';
import '../../profile_setup/widgets/dialect_selection_bottom_sheet.dart';
import '../../profile_setup/widgets/recovery_request_status_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int currentNavIndex = 0;
  final DeviceAuthService _authService = DeviceAuthService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    // Start fade-in animation
    _fadeController.forward();
    
    // Check for pending recovery request or first visit
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check for pending recovery request first
      final hasPendingRecovery = await _authService.hasPendingRecoveryRequest();
      if (hasPendingRecovery && mounted) {
        final recoveryCode = await _authService.getPendingRecoveryCode();
        if (recoveryCode != null && mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            sheetAnimationStyle: const AnimationStyle(
              duration: Duration(milliseconds: 650),
              reverseDuration: Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
            builder: (context) => RecoveryRequestStatusBottomSheet(
              recoveryCode: recoveryCode,
            ),
          );
          return;
        }
      }
      
      // Check if user has seen dialect sheet (first visit)
      final hasSeenDialect = await _authService.hasSeenDialectSheet();
      if (!hasSeenDialect && mounted) {
        // Mark as seen before showing
        await _authService.markDialectSheetAsSeen();
        
        // Show dialect selection sheet on first visit
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          sheetAnimationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 650),
            reverseDuration: Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          builder: (context) => const DialectSelectionBottomSheet(),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _getScreen() {
    // Always show appropriate content based on current tab
    switch (currentNavIndex) {
      case 0:
        return HomeContent(onLogoutTap: _handleLogout);
      case 1:
        // TODO: Implement QuizHomeScreen
        return const Center(
          child: Text(
            'تاقیکردنەوە',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 24,
            ),
          ),
        );
      case 2:
        // TODO: Implement BookScreen
        return const Center(
          child: Text(
            'کتێب',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 24,
            ),
          ),
        );
      case 3:
        // TODO: Implement ProfileScreen
        return const Center(
          child: Text(
            'پرۆفایل',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 24,
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'دەرچوون',
          style: TextStyle(fontFamily: 'Peshang'),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'دڵنیایت لە دەرچوون؟',
          style: TextStyle(fontFamily: 'Peshang'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'پاشگەزبوونەوە',
              style: TextStyle(fontFamily: 'Peshang'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'دەرچوون',
              style: TextStyle(fontFamily: 'Peshang', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        body: Column(
          children: [
            Expanded(child: _getScreen()),
            BottomNavBar(
              currentIndex: currentNavIndex,
              onTap: (index) {
                setState(() {
                  currentNavIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
