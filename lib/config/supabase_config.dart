import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

class SupabaseConfig {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _client!;
  }

  static GoTrueClient get auth => client.auth;

  static SupabaseStorageClient get storage => client.storage;

  static RealtimeClient get realtime => client.realtime;

  // Current user
  static User? get currentUser => auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  // Auth state stream
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}
