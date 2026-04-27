import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceAuthService {
  SupabaseClient? _supabase;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  DeviceAuthService() {
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

  static const String _userTokenKey = 'user_token';
  static const String _recoveryCodeKey = 'recovery_code';
  static const String _pendingRecoveryRequestKey = 'pending_recovery_request';
  static const String _pendingRecoveryCodeKey = 'pending_recovery_code';
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';
  static const String _hasSeenDialectSheetKey = 'has_seen_dialect_sheet';

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _userTokenKey);
    if (token == null) return false;

    try {
      // Check if user profile exists
      final profile = await supabase
          .from('user_profiles')
          .select('id')
          .eq('id', token)
          .maybeSingle();
      
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// Get current user ID async
  Future<String?> getCurrentUserId() async {
    return await _secureStorage.read(key: _userTokenKey);
  }

  /// Generate 8-digit recovery code
  String generateRecoveryCode() {
    final random = Random.secure();
    final code = random.nextInt(90000000) + 10000000; // 10000000 to 99999999
    return code.toString();
  }

  /// Hash recovery code for storage
  String hashRecoveryCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Format recovery code for display (12345678 -> 1234-5678)
  String formatRecoveryCode(String code) {
    if (code.length != 8) return code;
    return '${code.substring(0, 4)}-${code.substring(4)}';
  }

  /// Get device fingerprint
  Future<String> getDeviceFingerprint() async {
    try {
      String fingerprint = '';

      // Try Android first
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}_${androidInfo.version.release}_'
            '${androidInfo.manufacturer}_${androidInfo.id}';
      } catch (e) {
        // If Android fails, try iOS
        try {
          final iosInfo = await _deviceInfo.iosInfo;
          fingerprint = '${iosInfo.model}_${iosInfo.systemVersion}_'
              '${iosInfo.name}_${iosInfo.identifierForVendor}';
        } catch (e) {
          // If both fail, try web
          try {
            final webInfo = await _deviceInfo.webBrowserInfo;
            fingerprint = '${webInfo.browserName}_${webInfo.platform}_'
                '${webInfo.userAgent}';
          } catch (e) {
            rethrow;
          }
        }
      }

      // Hash the fingerprint
      final bytes = utf8.encode(fingerprint);
      final digest = sha256.convert(bytes);
      final hashedFingerprint = digest.toString();
      return hashedFingerprint;
    } catch (e) {
      // Fallback to random ID if device info fails
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Get device info for display
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      // Try Android first
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'os': 'Android ${androidInfo.version.release}',
          'manufacturer': androidInfo.manufacturer,
        };
      } catch (e) {
        // If Android fails, try iOS
        try {
          final iosInfo = await _deviceInfo.iosInfo;
          return {
            'model': iosInfo.model,
            'os': 'iOS ${iosInfo.systemVersion}',
            'manufacturer': 'Apple',
          };
        } catch (e) {
          // If both fail, try web
          try {
            final webInfo = await _deviceInfo.webBrowserInfo;
            return {
              'model': webInfo.browserName.toString(),
              'os': webInfo.platform ?? 'Web',
              'manufacturer': 'Browser',
            };
          } catch (e) {
            // All failed
            return {
              'model': 'Unknown',
              'os': 'Unknown',
              'manufacturer': 'Unknown',
            };
          }
        }
      }
    } catch (e) {
      return {
        'model': 'Unknown',
        'os': 'Unknown',
        'manufacturer': 'Unknown',
      };
    }
  }

  /// Create new anonymous user with recovery code
  Future<Map<String, dynamic>> createNewUser({
    required String kurdishName,
    String? avatarUrl,
    String? gender,
    String? province,
    String? dialect,
  }) async {
    try {
      // Generate recovery code
      final recoveryCode = generateRecoveryCode();
      final recoveryCodeHash = hashRecoveryCode(recoveryCode);

      // Get device info
      final deviceFingerprint = await getDeviceFingerprint();
      final deviceInfo = await getDeviceInfo();

      // Create anonymous user in Supabase Auth
      final authResponse = await supabase.auth.signInAnonymously();
      final userId = authResponse.user?.id;

      if (userId == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile with both plain and hashed recovery code
      await supabase.from('user_profiles').upsert({
        'id': userId,
        'kurdish_name': kurdishName,
        'avatar_url': avatarUrl,
        'gender': gender,
        'province': province,
        'dialect': dialect,
        'recovery_code': recoveryCode, // Plain text for manual comparison
        'recovery_code_hash': recoveryCodeHash, // Hashed for backward compatibility
        'device_fingerprint': deviceFingerprint,
        'last_device_info': deviceInfo,
        'recovery_count': 0,
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Store user token and recovery code locally
      await _secureStorage.write(key: _userTokenKey, value: userId);
      await _secureStorage.write(key: _recoveryCodeKey, value: recoveryCode);

      return {
        'success': true,
        'userId': userId,
        'recoveryCode': recoveryCode,
      };
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  /// Restore account using recovery code
  Future<bool> restoreAccountWithCode(String code) async {
    try {
      // Remove dashes if present
      final cleanCode = code.replaceAll('-', '');

      if (cleanCode.length != 8) {
        throw Exception('Invalid recovery code format');
      }

      // Hash the code
      final codeHash = hashRecoveryCode(cleanCode);

      // Find user by recovery code hash
      final response = await supabase.rpc(
        'find_user_by_recovery_code',
        params: {'p_code_hash': codeHash},
      );

      if (response == null) {
        return false;
      }

      final userId = response as String;

      // Get device info for this device
      final deviceFingerprint = await getDeviceFingerprint();
      final deviceInfo = await getDeviceInfo();

      // Update the user profile using the database function (bypasses RLS)
      final updateResult = await supabase.rpc(
        'update_user_recovery',
        params: {
          'p_user_id': userId,
          'p_device_fingerprint': deviceFingerprint,
          'p_device_info': deviceInfo,
        },
      );

      if (updateResult != true) {
        return false;
      }

      // Store the recovered user ID locally
      await _secureStorage.write(key: _userTokenKey, value: userId);
      await _secureStorage.write(key: _recoveryCodeKey, value: cleanCode);

      return true;
    } catch (e) {
      throw Exception('Failed to restore account: ${e.toString()}');
    }
  }

  /// Get stored recovery code
  Future<String?> getStoredRecoveryCode() async {
    return await _secureStorage.read(key: _recoveryCodeKey);
  }

  /// Update last login time
  Future<void> updateLastLogin() async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    try {
      await supabase.from('user_profiles').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
    await _secureStorage.delete(key: _userTokenKey);
    await _secureStorage.delete(key: _recoveryCodeKey);
  }

  /// Submit recovery request for manual approval
  Future<Map<String, dynamic>> submitRecoveryRequest(
    String code,
    String name,
  ) async {
    try {
      // Remove dashes if present
      final cleanCode = code.replaceAll('-', '');

      if (cleanCode.length != 8) {
        return {
          'success': false,
          'error': 'invalid_format',
          'message': 'کۆدەکە دەبێت ٨ ژمارە بێت',
        };
      }

      // Get device fingerprint for new device
      final deviceFingerprint = await getDeviceFingerprint();

      // Get FCM token for the new device
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      // Call database function to submit recovery request
      final response = await supabase.rpc(
        'submit_recovery_request',
        params: {
          'p_recovery_code': cleanCode,
          'p_submitted_name': name,
          'p_new_device_id': deviceFingerprint,
          'p_fcm_token': fcmToken,
        },
      );

      if (response == null) {
        return {
          'success': false,
          'error': 'unknown',
          'message': 'هەڵەیەک ڕوویدا',
        };
      }

      final result = response as Map<String, dynamic>;
      
      // If successful, store pending request flag
      if (result['success'] == true) {
        await _secureStorage.write(key: _pendingRecoveryRequestKey, value: 'true');
        await _secureStorage.write(key: _pendingRecoveryCodeKey, value: cleanCode);
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'exception',
        'message': 'هەڵەیەک ڕوویدا، دووبارە هەوڵ بدەرەوە',
      };
    }
  }

  /// Check recovery request status
  Future<Map<String, dynamic>> checkRecoveryRequestStatus() async {
    try {
      // Get device fingerprint
      final deviceFingerprint = await getDeviceFingerprint();

      // Call database function to check status
      final response = await supabase.rpc(
        'check_recovery_request_status',
        params: {
          'p_new_device_id': deviceFingerprint,
        },
      );

      if (response == null) {
        return {
          'success': false,
          'error': 'no_request',
          'message': 'هیچ داواکارییەک نەدۆزرایەوە',
        };
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': 'exception',
        'message': 'هەڵەیەک ڕوویدا',
      };
    }
  }

  /// Handle approved recovery (update local storage)
  Future<void> handleApprovedRecovery(String userId, String recoveryCode) async {
    try {
      // Store the recovered user ID and code locally
      await _secureStorage.write(key: _userTokenKey, value: userId);
      await _secureStorage.write(key: _recoveryCodeKey, value: recoveryCode);
      
      // Clear pending recovery request flags
      await _secureStorage.delete(key: _pendingRecoveryRequestKey);
      await _secureStorage.delete(key: _pendingRecoveryCodeKey);
    } catch (e) {
      throw Exception('Failed to complete recovery: ${e.toString()}');
    }
  }

  /// Check if there's a pending recovery request
  Future<bool> hasPendingRecoveryRequest() async {
    final pending = await _secureStorage.read(key: _pendingRecoveryRequestKey);
    return pending == 'true';
  }

  /// Get pending recovery code
  Future<String?> getPendingRecoveryCode() async {
    return await _secureStorage.read(key: _pendingRecoveryCodeKey);
  }

  /// Clear pending recovery request
  Future<void> clearPendingRecoveryRequest() async {
    await _secureStorage.delete(key: _pendingRecoveryRequestKey);
    await _secureStorage.delete(key: _pendingRecoveryCodeKey);
  }

  /// Check if user has seen welcome screens
  Future<bool> hasSeenWelcome() async {
    final seen = await _secureStorage.read(key: _hasSeenWelcomeKey);
    return seen == 'true';
  }

  /// Mark welcome screens as seen
  Future<void> markWelcomeAsSeen() async {
    await _secureStorage.write(key: _hasSeenWelcomeKey, value: 'true');
  }

  /// Check if user has seen dialect selection sheet
  Future<bool> hasSeenDialectSheet() async {
    final seen = await _secureStorage.read(key: _hasSeenDialectSheetKey);
    return seen == 'true';
  }

  /// Mark dialect selection sheet as seen
  Future<void> markDialectSheetAsSeen() async {
    await _secureStorage.write(key: _hasSeenDialectSheetKey, value: 'true');
  }

  /// Get user ID by recovery code (for approved recovery)
  Future<String?> getUserIdByRecoveryCode(String code) async {
    try {
      final cleanCode = code.replaceAll('-', '');
      
      // Query user_profiles to find user by recovery code
      final response = await supabase
          .from('user_profiles')
          .select('id')
          .eq('recovery_code', cleanCode)
          .maybeSingle();
      
      if (response != null) {
        return response['id'] as String;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> scheduleRecoveryCodeNotification() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;
      await supabase.functions.invoke(
        'send-recovery-code-notification',
        body: {'user_id': userId},
      );
    } catch (_) {}
  }
}
