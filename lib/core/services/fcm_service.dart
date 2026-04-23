// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_auth_service.dart';

class FcmService {
  // static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final DeviceAuthService _authService = DeviceAuthService();

  static Future<void> initialize() async {
    // Firebase messaging disabled for testing
    // await _messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // await _messaging.setForegroundNotificationPresentationOptions(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // final token = await _messaging.getToken();
    // if (token != null) await _saveToken(token);

    // _messaging.onTokenRefresh.listen(_saveToken);
    // FirebaseMessaging.onMessage.listen((_) {});
  }

  static Future<void> registerTokenForCurrentUser() async {
    // final token = await _messaging.getToken();
    // if (token != null) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    try {
      // Get actual user ID from auth service (SECURITY FIX: was reading token key instead of user ID)
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;

      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,  // Now correctly stores actual user ID
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }

}
