import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chapter_model.dart';
import '../models/sponser_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/home_refresh_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/url_launcher_helper.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../notifications/screen/notification_screen.dart';

class HomeController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  String selectedChapterTitle = "";
  String selectedChapterDescription = "";
  int selectedChapterIndex = 0;
  bool isScrollAtEnd = false;

  List<Chapter> chapters = [];
  List<SponserModel> sponsors = [];
  bool isLoading = true;
  String? errorMessage;

  String userName = "بەخێربێیت";
  bool hasActiveSubscription = false;
  int notificationCount = 0;

  RealtimeChannel? _notificationChannel;

  void init(BuildContext context) {
    _initializeUserDataFromCache();
    _loadUserInfo();
    loadData();
    FcmService.registerTokenForCurrentUser();
    homeRefreshNotifier.addListener(_onRefreshTriggered);
    _subscribeToNotifications(context);
  }

  @override
  void dispose() {
    homeRefreshNotifier.removeListener(_onRefreshTriggered);
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToNotifications(BuildContext context) {
    _notificationChannel = Supabase.instance.client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final row = payload.newRecord;
            // SECURITY: Notification targeting is enforced server-side via Supabase RLS policies.
            // The notifications table has RLS policies that ensure:
            // - user_type='all' notifications are visible to all users
            // - user_type='pro' notifications are only visible to users with active subscriptions
            // - user_type='free' notifications are only visible to users without subscriptions
            // This prevents untrusted payloads from bypassing targeting.
            notificationCount++;
            notifyListeners();
            final duration = row['display_duration'] as int? ?? 5;
            NotificationBanner.show(
              context,
              title: row['title'] as String? ?? '',
              text: row['text'] as String? ?? '',
              durationSeconds: duration,
            );
          },
        )
        .subscribe();
  }

  void _onRefreshTriggered() {
    SupabaseService.clearCache();
    _loadAllTogether();
  }

  Future<void> _loadAllTogether() async {
    try {
      final isAuth = await _supabaseService.isAuthenticated;
      final results = await Future.wait([
        isAuth ? _supabaseService.getUserKurdishName() : Future.value('بەخێربێیت'),
        isAuth ? _supabaseService.hasActiveSubscription() : Future.value(false),
        isAuth ? _supabaseService.getUnreadNotificationCount() : Future.value(0),
        _supabaseService.getChaptersWithProgress(),
        _supabaseService.getActiveSponsors(),
      ]);
      userName = results[0] as String;
      hasActiveSubscription = results[1] as bool;
      notificationCount = results[2] as int;
      chapters = results[3] as List<Chapter>;
      sponsors = results[4] as List<SponserModel>;  // Already filtered server-side by SupabaseService
      isLoading = false;
      if (chapters.isNotEmpty) {
        selectedChapterTitle = chapters[0].largeTitle;
        selectedChapterDescription = chapters[0].description;
        selectedChapterIndex = 0;
      }
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _initializeUserDataFromCache() {
    final cachedName = SupabaseService.getCachedUserName();
    final cachedSubscription = SupabaseService.getCachedSubscription();
    final cachedNotifications = SupabaseService.getCachedNotificationCount();
    final cachedChapters = SupabaseService.getCachedChapters();
    if (cachedName != null) userName = cachedName;
    if (cachedSubscription != null) hasActiveSubscription = cachedSubscription;
    if (cachedNotifications != null) notificationCount = cachedNotifications;
    if (cachedChapters != null && cachedChapters.isNotEmpty) {
      chapters = cachedChapters;
      selectedChapterTitle = chapters[0].largeTitle;
      selectedChapterDescription = chapters[0].description;
      selectedChapterIndex = 0;
    }
    notifyListeners();
  }

  Future<void> _loadUserInfo() async {
    try {
      final isAuth = await _supabaseService.isAuthenticated;
      if (!isAuth) {
        userName = 'بەخێربێیت';
        hasActiveSubscription = false;
        notificationCount = 0;
        notifyListeners();
        return;
      }
      final results = await Future.wait([
        _supabaseService.getUserKurdishName(),
        _supabaseService.hasActiveSubscription(),
        _supabaseService.getUnreadNotificationCount(),
      ]);
      userName = results[0] as String;
      hasActiveSubscription = results[1] as bool;
      notificationCount = results[2] as int;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _supabaseService.getChaptersWithProgress(),
        _supabaseService.getActiveSponsors(),
      ]);
      chapters = results[0] as List<Chapter>;
      sponsors = results[1] as List<SponserModel>;  // Already filtered server-side by SupabaseService
      isLoading = false;
      if (chapters.isNotEmpty) {
        selectedChapterTitle = chapters[0].largeTitle;
        selectedChapterDescription = chapters[0].description;
        selectedChapterIndex = 0;
      }
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectChapter(int index, String title) {
    // Validate index before setting
    if (index < 0 || index >= chapters.length) return;
    selectedChapterTitle = title;
    selectedChapterIndex = index;
    selectedChapterDescription = chapters[index].description;
    notifyListeners();
  }

  void setScrollAtEnd(bool value) {
    isScrollAtEnd = value;
    notifyListeners();
  }

  void refreshUserInfo() => _loadUserInfo();

  /// Triggers a full refresh — re-registers FCM, reloads all data.
  /// Waits at least 3 seconds so the overlay doesn't flash.
  Future<void> triggerRefresh() async {
    final dataFuture = _loadAllTogether();
    await Future.wait([
      dataFuture,
      Future.delayed(const Duration(seconds: 3)),
    ]);
  }

  String getFirstName(String fullName) {
    if (fullName.isEmpty) return fullName;
    return fullName.trim().split(' ').first;
  }

  String get planLabel => hasActiveSubscription ? 'Pro' : 'Free';

  void openVideo(BuildContext context, String videoUrl) {
    UrlLauncherHelper.openYouTubeVideo(context, videoUrl);
  }

  void navigateToNotifications(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const NotificationScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          final fade = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => refreshUserInfo());
  }

}
