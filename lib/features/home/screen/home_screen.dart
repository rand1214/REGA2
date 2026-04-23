import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../../core/services/device_auth_service.dart';
import '../../../core/services/home_refresh_service.dart';
import '../logic/home_logic.dart';
import '../widgets/top_bar.dart';
import '../widgets/sponser_photo.dart';
import '../widgets/sections_title.dart';
import '../widgets/circle_navigator.dart';
import '../widgets/chapter_info_card.dart';
import '../widgets/video_section.dart';
import '../../profile_setup/widgets/logout_bottom_sheet.dart';
import '../../profile_setup/widgets/dialect_selection_bottom_sheet.dart';
import '../../profile_setup/widgets/recovery_request_status_bottom_sheet.dart';
import '../../questions/screen/questions_screen.dart';
import '../../book/screen/book_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  final Set<int> _visitedTabs = {0};
  final DeviceAuthService _authService = DeviceAuthService();

  // Refresh overlay
  late AnimationController _overlayController;
  bool _showOverlay = false;

  // Home logic
  late final HomeController _homeLogic;
  late final AnimationController _loadingFadeController;
  late final Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _loadingFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
      value: 1.0,
    );
    _loadingFadeAnimation = CurvedAnimation(
      parent: _loadingFadeController,
      curve: Curves.easeOut,
    );

    _homeLogic = HomeController();
    _homeLogic.addListener(_onHomeLogicUpdate);
    _homeLogic.init(context);

    homeRefreshNotifier.addListener(_onRefresh);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // TODO: Move recovery request and dialect sheet logic to HomeController
      // These are business logic decisions that belong in the controller, not the screen
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
            sheetAnimationStyle: AnimationStyle(
              duration: const Duration(milliseconds: 650),
              reverseDuration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
            builder: (_) => RecoveryRequestStatusBottomSheet(recoveryCode: recoveryCode),
          );
          return;
        }
      }

      final hasSeenDialect = await _authService.hasSeenDialectSheet();
      if (!hasSeenDialect && mounted) {
        await _authService.markDialectSheetAsSeen();
        if (!mounted) return;
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
          builder: (_) => const DialectSelectionBottomSheet(),
        );
      }
    });
  }

  void _onHomeLogicUpdate() {
    if (!mounted) return;
    if (!_homeLogic.isLoading && _loadingFadeController.value > 0) {
      _loadingFadeController.reverse();
    }
    setState(() {});
  }

  @override
  void dispose() {
    homeRefreshNotifier.removeListener(_onRefresh);
    _homeLogic.removeListener(_onHomeLogicUpdate);
    _homeLogic.dispose();
    _overlayController.dispose();
    _loadingFadeController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    setState(() => _showOverlay = true);
    _overlayController.value = 0.0;
    await _overlayController.forward();
    await _homeLogic.triggerRefresh();
    await _overlayController.reverse();
    if (mounted) setState(() => _showOverlay = false);
  }

  void _showRecoveryCodeBanner() {
    _authService.scheduleRecoveryCodeNotification();
    NotificationBanner.show(
      context,
      title: 'کۆدی گەڕانەوەی هەژمار',
      text: 'کۆدی گەڕانەوە لە ماوەی پێنج خولەکدا دەچێتە بەشی ئاگاداری',
    );
  }

  void _handleLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 650),
        reverseDuration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (_) => LogoutBottomSheet(onShowRecoveryCode: _showRecoveryCodeBanner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF1F1F1),
              child: Opacity(
                opacity: 0.04,
                child: Image.asset(
                  'assets/icons/blue-traffic-pattern-for-bg.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentNavIndex,
                  children: [
                    _buildHomeTab(scale),
                    _visitedTabs.contains(1) ? const QuestionsScreen() : const SizedBox.shrink(),
                    _visitedTabs.contains(2) ? const BookScreen() : const SizedBox.shrink(),
                    _visitedTabs.contains(3) ? const Center(child: Text('پرۆفایل', style: TextStyle(fontFamily: 'Peshang', fontSize: 24))) : const SizedBox.shrink(),
                  ],
                ),
              ),
              BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: (index) => setState(() {
                  _currentNavIndex = index;
                  _visitedTabs.add(index);
                }),
              ),
            ],
          ),
          // Refresh overlay
          if (_showOverlay) _buildRefreshOverlay(scale),
        ],
      ),
    );
  }

  Widget _buildHomeTab(double scale) {
    final c = _homeLogic;
    final topBar = _buildTopBar(c);

    return Stack(
      children: [
        Column(
          children: [
            topBar,
            Expanded(
              child: c.isLoading
                  ? const SizedBox.shrink()
                  : c.errorMessage != null
                      ? _buildErrorState(c, scale)
                      : c.chapters.isEmpty
                          ? _buildEmptyState(scale)
                          : _buildHomeContent(c, scale),
            ),
          ],
        ),
        if (_loadingFadeController.value > 0)
          FadeTransition(
            opacity: _loadingFadeAnimation,
            child: Column(
              children: [
                topBar,
                Expanded(child: _buildLoadingState(scale)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(HomeController c) {
    return TopBar(
      firstName: c.getFirstName(c.userName),
      planLabel: c.planLabel,
      notificationCount: c.notificationCount,
      onNotificationTap: () => c.navigateToNotifications(context),
      onLogoutTap: _handleLogout,
    );
  }

  Widget _buildHomeContent(HomeController c, double scale) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SponserPhoto(sponsors: c.sponsors),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SectionsTitle(scale: scale),
              Transform.translate(
                offset: Offset(0, -14 * scale),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20 * scale, 0, 15 * scale, 0),
                  child: SizedBox(
                    height: 150 * scale,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        if (c.isScrollAtEnd) {
                          return const LinearGradient(
                            colors: [Colors.white, Colors.white],
                          ).createShader(bounds);
                        }
                        return const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Colors.white, Colors.white, Colors.transparent],
                          stops: [0.0, 0.75, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: CircleNavigator(
                        chapters: c.chapters,
                        onChapterSelected: (index, title) => c.selectChapter(index, title),
                        onScrollAtEnd: (isAtEnd) => c.setScrollAtEnd(isAtEnd),
                      ),
                    ),
                  ),
                ),
              ),
              if (c.selectedChapterTitle.isNotEmpty && c.chapters.isNotEmpty && c.selectedChapterIndex < c.chapters.length) ...[
                ChapterInfoCard(
                  scale: scale,
                  title: c.selectedChapterTitle,
                  description: c.selectedChapterDescription,
                ),
                VideoSection(
                  videoThumbnailUrl: c.chapters[c.selectedChapterIndex].videoThumbnailUrl,
                  videoTitle: c.chapters[c.selectedChapterIndex].videoTitle,
                  onVideoTap: () => c.openVideo(context, c.chapters[c.selectedChapterIndex].videoUrl),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200 * scale,
            height: 200 * scale,
            child: Lottie.asset(
              'assets/icons/getting-data.json',
              fit: BoxFit.contain,
              renderCache: RenderCache.raster,
            ),
          ),
          SizedBox(height: 20 * scale),
          Text('تکایە چاوەڕوان بە...',
              style: TextStyle(fontFamily: 'Peshang', fontSize: 16 * scale, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildErrorState(HomeController c, double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60 * scale, color: Colors.red.shade400),
            SizedBox(height: 20 * scale),
            Text('هەڵەیەک ڕوویدا',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Peshang', fontSize: 20 * scale,
                    fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 10 * scale),
            Text('تکایە دووبارە هەوڵ بدەرەوە',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Peshang', fontSize: 14 * scale, color: Colors.black54)),
            SizedBox(height: 30 * scale),
            ElevatedButton(
              onPressed: c.loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0080C8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scale)),
                padding: EdgeInsets.symmetric(horizontal: 30 * scale, vertical: 14 * scale),
              ),
              child: Text('دووبارە هەوڵ بدەرەوە',
                  style: TextStyle(fontFamily: 'Peshang', fontSize: 16 * scale, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 60 * scale, color: Colors.grey.shade400),
          SizedBox(height: 20 * scale),
          Text('هیچ بەشێک نییە',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Peshang', fontSize: 20 * scale,
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 10 * scale),
          Text('تکایە دواتر بگەڕێوە',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Peshang', fontSize: 14 * scale, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildRefreshOverlay(double scale) {
    return AnimatedBuilder(
      animation: _overlayController,
      builder: (context, child) {
        final slideVal = Tween<double>(begin: 0.06, end: 0.0)
            .animate(CurvedAnimation(
              parent: _overlayController,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ))
            .value;
        final fadeVal = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(
              parent: _overlayController,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ))
            .value;
        return Opacity(
          opacity: fadeVal,
          child: Transform.translate(
            offset: Offset(0, slideVal * MediaQuery.of(context).size.height),
            child: child,
          ),
        );
      },
      child: Container(
        color: const Color(0xFFF1F1F1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200 * scale,
                height: 200 * scale,
                child: Lottie.asset(
                  'assets/icons/getting-data.json',
                  fit: BoxFit.contain,
                  renderCache: RenderCache.raster,
                ),
              ),
              SizedBox(height: 20 * scale),
              Text('تکایە چاوەڕوان بە...',
                  style: TextStyle(fontFamily: 'Peshang', fontSize: 16 * scale, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
