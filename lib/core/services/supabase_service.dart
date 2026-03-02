import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/models/chapter_model.dart';
import 'device_auth_service.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceAuthService _authService = DeviceAuthService();

  // Cache for user data
  static String? _cachedUserName;
  static bool? _cachedHasSubscription;
  static int? _cachedNotificationCount;
  static List<Chapter>? _cachedChapters;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  // Get current user ID from device auth service
  Future<String?> get currentUserId async => await _authService.getCurrentUserId();

  // Check if user is authenticated
  Future<bool> get isAuthenticated async => await _authService.isAuthenticated();

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
      final response = await _supabase.rpc(
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

      print('Fetching chapters without progress for unauthorized user');
      
      // Fetch chapters directly from the chapters table
      // Use "order" in quotes since it's a reserved keyword
      final response = await _supabase
          .from('chapters')
          .select('*')
          .order('"order"', ascending: true);

      print('Chapters response: $response');

      final chapters = response.map((json) {
        // Add default values for user-specific fields
        final chapterData = Map<String, dynamic>.from(json);
        
        // Calculate is_locked for unauthorized users:
        // If chapter requires subscription, it's locked (unauthorized users have no subscription)
        final requiresSubscription = chapterData['requires_subscription'] as bool? ?? false;
        chapterData['is_locked'] = requiresSubscription;
        
        chapterData['progress_percentage'] = 0;
        chapterData['completed_lessons'] = 0;
        chapterData['total_lessons'] = 0;
        chapterData['video_watched'] = false;
        chapterData['video_watch_progress'] = 0;
        return Chapter.fromJson(chapterData);
      }).toList();
      
      print('Parsed ${chapters.length} chapters');
      _cachedChapters = chapters;
      _cacheTimestamp = DateTime.now();
      return _cachedChapters!;
    } catch (e) {
      print('Error fetching chapters without progress: $e');
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

      final response = await _supabase.rpc(
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

      final response = await _supabase.rpc(
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

      final response = await _supabase
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
      _cachedUserName = profile?['kurdish_name'] as String? ?? 'بەکارهێنەر';
      _cacheTimestamp = DateTime.now();
      return _cachedUserName!;
    } catch (e) {
      return 'بەکارهێنەر'; // Default: "User"
    }
  }

  /// Clear user data cache (call when user logs out or data changes)
  static void clearCache() {
    _cachedUserName = null;
    _cachedHasSubscription = null;
    _cachedNotificationCount = null;
    _cachedChapters = null;
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

  /// Update video watch progress
  Future<void> updateVideoProgress({
    required int chapterId,
    required int progress,
    bool? watched,
  }) async {
    try {
      final userId = await currentUserId;
      if (userId == null) return;

      await _supabase.from('user_chapter_progress').upsert({
        'user_id': userId,
        'chapter_id': chapterId,
        'video_watch_progress': progress,
        'video_watched': ?watched,
        'last_watched_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update video progress: ${e.toString()}');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = await currentUserId;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  /// Get all notifications for user
  Future<List<Map<String, dynamic>>> getNotifications({
    bool? isRead,
    int limit = 50,
  }) async {
    try {
      final userId = await currentUserId;
      if (userId == null) {
        return [];
      }

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Subscribe to chapter changes (real-time)
  RealtimeChannel subscribeToChapters(Function(List<Chapter>) onUpdate) {
    return _supabase
        .channel('chapters_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chapters',
          callback: (payload) async {
            // Refetch chapters when any change occurs
            final chapters = await getChaptersWithProgress();
            onUpdate(chapters);
          },
        )
        .subscribe();
  }

  /// Subscribe to notifications (real-time)
  Future<RealtimeChannel> subscribeToNotifications(
      Function(Map<String, dynamic>) onNewNotification) async {
    final userId = await currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .channel('user_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNewNotification(payload.newRecord);
          },
        )
        .subscribe();
  }
}
