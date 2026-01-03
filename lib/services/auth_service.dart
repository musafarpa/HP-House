import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _db = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    // Sign up with user metadata (trigger will create profile automatically)
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName ?? username,
      },
    );

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.hphouse://login-callback/',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Get user profile with followers/following counts
  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _db
        .from('profiles')
        .select('''
          *,
          followers_count:followers!following_id(count),
          following_count:followers!follower_id(count)
        ''')
        .eq('id', userId)
        .single();

    final profile = Map<String, dynamic>.from(response);
    profile['followers_count'] = response['followers_count']?[0]?['count'] ?? 0;
    profile['following_count'] = response['following_count']?[0]?['count'] ?? 0;

    return UserModel.fromJson(profile);
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (username != null) updates['username'] = username;
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _db.from('profiles').update(updates).eq('id', userId);
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _db
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }
}
