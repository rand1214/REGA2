import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Helper methods for secure operations
  static Future<bool> isAuthenticated() async {
    return client.auth.currentSession != null;
  }
  
  static String? getCurrentUserId() {
    return client.auth.currentUser?.id;
  }
}
