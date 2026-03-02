import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'top_bar.dart';
import 'description_container.dart';
import 'circle_navigator.dart';
import 'content_section.dart';
import '../models/chapter_model.dart';
import '../../../core/services/supabase_service.dart';

class HomeContent extends StatefulWidget {
  final VoidCallback? onLogoutTap;
  
  const HomeContent({
    super.key,
    this.onLogoutTap,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();

  // State variables
  String selectedChapterTitle = "";
  String selectedChapterDescription = "";
  int selectedChapterIndex = 0;

  List<Chapter> chapters = [];
  bool isLoading = true;
  String? errorMessage;
  
  // User data
  String userName = "بەکارهێنەر";
  bool hasActiveSubscription = false;
  int notificationCount = 0;

  // Loading animation controller
  late AnimationController _loadingFadeController;
  late Animation<double> _loadingFadeAnimation;
  DateTime? _loadingStartTime;

  @override
  void initState() {
    super.initState();
    
    // Initialize loading fade animation
    _loadingFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _loadingFadeAnimation = CurvedAnimation(
      parent: _loadingFadeController,
      curve: Curves.easeOut,
    );
    
    // Start with loading visible
    _loadingFadeController.value = 1.0;
    _loadingStartTime = DateTime.now();
    
    // Initialize with cached data immediately (synchronous)
    _initializeUserDataFromCache();
    // Then load/refresh data in background
    _loadUserInfo();
    _loadData();
  }

  @override
  void dispose() {
    _loadingFadeController.dispose();
    super.dispose();
  }

  /// Initialize user data from cache synchronously (no await)
  void _initializeUserDataFromCache() {
    // Access cached data directly without async
    final cachedName = SupabaseService.getCachedUserName();
    final cachedSubscription = SupabaseService.getCachedSubscription();
    final cachedNotifications = SupabaseService.getCachedNotificationCount();
    final cachedChapters = SupabaseService.getCachedChapters();
    
    if (cachedName != null || cachedSubscription != null || cachedNotifications != null || cachedChapters != null) {
      setState(() {
        userName = cachedName ?? userName;
        hasActiveSubscription = cachedSubscription ?? hasActiveSubscription;
        notificationCount = cachedNotifications ?? notificationCount;
        
        // If chapters are cached, use them immediately
        if (cachedChapters != null && cachedChapters.isNotEmpty) {
          chapters = cachedChapters;
          selectedChapterTitle = chapters[0].largeTitle;
          selectedChapterDescription = chapters[0].description;
          selectedChapterIndex = 0;
          // Don't set isLoading to false yet - let _loadData handle it
        }
      });
    }
  }

  /// Load user info first (name, notifications) - this should be fast/cached
  Future<void> _loadUserInfo() async {
    try {
      final isAuth = await _supabaseService.isAuthenticated;
      
      if (!isAuth) {
        setState(() {
          userName = 'بەخێربێیت';
          hasActiveSubscription = false;
          notificationCount = 0;
        });
        return;
      }

      // Fetch user info only (should be cached from splash screen)
      final results = await Future.wait([
        _supabaseService.getUserKurdishName(),
        _supabaseService.hasActiveSubscription(),
        _supabaseService.getUnreadNotificationCount(),
      ]);

      setState(() {
        userName = results[0] as String;
        hasActiveSubscription = results[1] as bool;
        notificationCount = results[2] as int;
      });
    } catch (e) {
      // Ignore errors, keep default values
      print('Error loading user info: $e');
    }
  }

  /// Load all data from Supabase
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch chapters for all users (authenticated or not)
      final chaptersData = await _supabaseService.getChaptersWithProgress();

      // Ensure minimum loading time of 1 second
      await _ensureMinimumLoadingTime();
      
      // Fade out loading screen
      await _loadingFadeController.reverse();

      setState(() {
        chapters = chaptersData;
        isLoading = false;

        // Auto-select first chapter if available
        if (chapters.isNotEmpty) {
          selectedChapterTitle = chapters[0].largeTitle;
          selectedChapterDescription = chapters[0].description;
          selectedChapterIndex = 0;
        }
      });
    } catch (e) {
      await _ensureMinimumLoadingTime();
      await _loadingFadeController.reverse();
      
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  /// Ensure loading screen is shown for at least 1 second
  Future<void> _ensureMinimumLoadingTime() async {
    if (_loadingStartTime == null) return;
    
    final elapsed = DateTime.now().difference(_loadingStartTime!);
    const minDuration = Duration(seconds: 1);
    
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
  }

  /// Handle notification bell tap
  void _onNotificationTap() {
    // TODO: Navigate to notifications screen
    // context.go('/notifications');
  }

  /// Handle buy subscription tap
  void _onBuySubscriptionTap() {
    // TODO: Navigate to subscription/purchase screen
    // context.go('/subscription');
  }

  @override
  Widget build(BuildContext context) {
    // Loading state - show TopBar with loading content
    if (isLoading) {
      return Column(
        children: [
          TopBar(
            kurdishName: userName,
            hasProSubscription: hasActiveSubscription,
            notificationCount: notificationCount,
            onNotificationTap: _onNotificationTap,
            onLogoutTap: widget.onLogoutTap,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _loadingFadeAnimation,
              child: _buildLoadingState(),
            ),
          ),
        ],
      );
    }

    // All other states
    return Column(
      children: [
        TopBar(
          kurdishName: userName,
          hasProSubscription: hasActiveSubscription,
          notificationCount: notificationCount,
          onNotificationTap: _onNotificationTap,
          onLogoutTap: widget.onLogoutTap,
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Error state
    if (errorMessage != null) {
      return _buildErrorState();
    }

    // Empty state
    if (chapters.isEmpty) {
      return _buildEmptyState();
    }

    // Success state - show content
    return SingleChildScrollView(
      child: Column(
        children: [
          DescriptionContainer(
            description: "هەموو بەشە قفڵکراوەکان بکەرەوە و ڕاهێنانیان لەسەر بکە",
            hasActiveSubscription: hasActiveSubscription,
            onBuyTap: _onBuySubscriptionTap,
          ),
          CircleNavigator(
            chapters: chapters,
            onChapterSelected: (index, title) {
              setState(() {
                selectedChapterTitle = title;
                selectedChapterIndex = index;
                if (chapters.isNotEmpty && index < chapters.length) {
                  selectedChapterDescription = chapters[index].description;
                }
              });
            },
          ),
          // Only show ContentSection if a chapter is selected
          if (selectedChapterTitle.isNotEmpty && chapters.isNotEmpty)
            ContentSection(
              title: selectedChapterTitle,
              description: selectedChapterDescription,
              videoThumbnailUrl: chapters[selectedChapterIndex].videoThumbnailUrl,
              videoTitle: chapters[selectedChapterIndex].videoTitle,
              videoUrl: chapters[selectedChapterIndex].videoUrl,
            ),
        ],
      ),
    );
  }

  /// Loading state widget
  Widget _buildLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/icons/getting-data.json',
            width: 300 * scale,
            height: 300 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20 * scale),
          Text(
            'تکایە چاوەڕوان بە...',
            style: TextStyle(
              fontFamily: 'Peshang',
              fontSize: 16 * scale,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Error state widget
  Widget _buildErrorState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(20 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60 * scale,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 20 * scale),
            Text(
              'هەڵەیەک ڕوویدا',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              'تکایە دووبارە هەوڵ بدەرەوە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 14 * scale,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 30 * scale),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                elevation: 0,
              ),
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
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: Offset(0, 3 * scale),
                      blurRadius: 6 * scale,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      offset: Offset(0, -1 * scale),
                      blurRadius: 2 * scale,
                    ),
                  ],
                ),
                child: Container(
                  height: 50 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 30 * scale),
                  alignment: Alignment.center,
                  child: Text(
                    'دووبارە هەوڵ بدەرەوە',
                    style: TextStyle(
                      fontFamily: 'Peshang',
                      fontSize: 16 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(20 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 60 * scale,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 20 * scale),
            Text(
              'هیچ بەشێک نییە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              'تکایە دواتر بگەڕێوە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 14 * scale,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
