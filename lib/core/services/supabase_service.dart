import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/models/chapter_model.dart';
import '../../features/home/models/sponser_model.dart';
import 'device_auth_service.dart';

class SupabaseService {
  SupabaseClient? _supabase;
  final DeviceAuthService _authService = DeviceAuthService();

  SupabaseService() {
    // Initialize Supabase client lazily
    try {
      _supabase = Supabase.instance.client;
    } catch (e) {
      // Supabase not initialized yet - will be null
      _supabase = null;
    }
  }

  /// Get Supabase client, throw if not initialized
  SupabaseClient get supabase {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    return _supabase!;
  }

  /// Expose the Supabase client for direct queries
  SupabaseClient? get supabaseOrNull => _supabase;

  // Cache for user data
  static String? _cachedUserName;
  static bool? _cachedHasSubscription;
  static int? _cachedNotificationCount;
  static List<Chapter>? _cachedChapters;
  static List<SponserModel>? _cachedSponsors;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  // Get current user ID from device auth service
  Future<String?> get currentUserId async =>
      await _authService.getCurrentUserId();

  // Check if user is authenticated
  Future<bool> get isAuthenticated async =>
      await _authService.isAuthenticated();

  /// Fetch chapters with user's progress and lock status
  /// Uses the get_chapters_with_progress() database function
  Future<List<Chapter>> getChaptersWithProgress() async {
    try {
      // Check cache first
      if (_cachedChapters != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedChapters!;
      }

      final userId = await currentUserId;
      if (userId == null) {
        // For unauthorized users, fetch chapters without progress
        return await getChaptersWithoutProgress();
      }

      // Call the database function
      final response = await supabase.rpc(
        'get_chapters_with_progress',
        params: {'p_user_id': userId},
      );

      // Convert response to List<Chapter>
      if (response is List) {
        _cachedChapters = response
            .map((json) => Chapter.fromJson(json as Map<String, dynamic>))
            .toList();
        _cacheTimestamp = DateTime.now();
        return _cachedChapters!;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch chapters: ${e.toString()}');
    }
  }

  /// Fetch chapters without user progress (for unauthorized users)
  Future<List<Chapter>> getChaptersWithoutProgress() async {
    try {
      // Check cache first
      if (_cachedChapters != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedChapters!;
      }

      // Fetch chapters directly from the chapters table
      // Use "order" in quotes since it's a reserved keyword
      final response = await supabase
          .from('chapters')
          .select('*')
          .order('"order"', ascending: true);

      final chapters = response.map((json) {
        // Add default values for user-specific fields
        final chapterData = Map<String, dynamic>.from(json);

        // Calculate is_locked for unauthorized users:
        // If chapter requires subscription, it's locked (unauthorized users have no subscription)
        final requiresSubscription =
            chapterData['requires_subscription'] as bool? ?? false;
        chapterData['is_locked'] = requiresSubscription;

        chapterData['progress_percentage'] = 0;
        chapterData['completed_lessons'] = 0;
        chapterData['total_lessons'] = 0;
        chapterData['video_watched'] = false;
        chapterData['video_watch_progress'] = 0;
        return Chapter.fromJson(chapterData);
      }).toList();

      _cachedChapters = chapters;
      _cacheTimestamp = DateTime.now();
      return _cachedChapters!;
    } catch (e) {
      throw Exception('Failed to fetch chapters: ${e.toString()}');
    }
  }

  /// Check if user has active subscription
  /// Uses the has_active_subscription() database function
  Future<bool> hasActiveSubscription() async {
    try {
      // Check cache first
      if (_cachedHasSubscription != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedHasSubscription!;
      }

      final userId = await currentUserId;
      if (userId == null) {
        return false;
      }

      final response = await supabase.rpc(
        'has_active_subscription',
        params: {'p_user_id': userId},
      );

      _cachedHasSubscription = response as bool? ?? false;
      _cacheTimestamp = DateTime.now();
      return _cachedHasSubscription!;
    } catch (e) {
      // If error, assume no subscription
      return false;
    }
  }

  /// Get unread notification count
  /// Uses the get_unread_notification_count() database function
  Future<int> getUnreadNotificationCount() async {
    try {
      // Check cache first
      if (_cachedNotificationCount != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedNotificationCount!;
      }

      final userId = await currentUserId;
      if (userId == null) {
        return 0;
      }

      final response = await supabase.rpc(
        'get_unread_notification_count',
        params: {'p_user_id': userId},
      );

      _cachedNotificationCount = response as int? ?? 0;
      _cacheTimestamp = DateTime.now();
      return _cachedNotificationCount!;
    } catch (e) {
      return 0;
    }
  }

  /// Get user profile information
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = await currentUserId;
      if (userId == null) {
        return null;
      }

      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Get user's Kurdish name from profile
  Future<String> getUserKurdishName() async {
    try {
      // Check cache first
      if (_cachedUserName != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedUserName!;
      }

      final profile = await getUserProfile();
      _cachedUserName = profile?['kurdish_name'] as String?;
      if (_cachedUserName == null || _cachedUserName!.isEmpty) {
        _cachedUserName = 'بەخێربێیت';
      }
      _cacheTimestamp = DateTime.now();
      return _cachedUserName!;
    } catch (e) {
      return 'بەخێربێیت';
    }
  }

  /// Get active sponsors ordered by display order
  Future<List<SponserModel>> getActiveSponsors() async {
    try {
      if (_cachedSponsors != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedSponsors!;
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final response = await supabase
          .from('sponsers')
          .select()
          .lte('valid_from', now)
          .gte('valid_until', now)
          .order('order', ascending: true);

      _cachedSponsors = (response as List)
          .map((json) => SponserModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedSponsors!;
    } catch (e) {
      return [];
    }
  }

  /// Clear user data cache (call when user logs out or data changes)
  static void clearCache() {
    _cachedUserName = null;
    _cachedHasSubscription = null;
    _cachedNotificationCount = null;
    _cachedChapters = null;
    _cachedSponsors = null;
    _cacheTimestamp = null;
  }

  /// Get cached user name synchronously (no async)
  static String? getCachedUserName() {
    if (_cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedUserName;
    }
    return null;
  }

  /// Get cached subscription status synchronously (no async)
  static bool? getCachedSubscription() {
    if (_cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedHasSubscription;
    }
    return null;
  }

  /// Get cached notification count synchronously (no async)
  static int? getCachedNotificationCount() {
    if (_cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedNotificationCount;
    }
    return null;
  }

  /// Get cached chapters synchronously (no async)
  static List<Chapter>? getCachedChapters() {
    if (_cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedChapters;
    }
    return null;
  }
}
