import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((event) async {
      if (event.session != null) {
        await _loadUserProfile();
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      _user = await _authService.getUserProfile(userId);
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      // Check username availability
      final isAvailable = await _authService.isUsernameAvailable(username);
      if (!isAvailable) {
        _error = 'Username is already taken';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      await _authService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signInWithGoogle();
      return true;
    } catch (e) {
      _error = 'Google sign in failed. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Remove user from all rooms before signing out
    final userId = _authService.currentUserId;
    if (userId != null) {
      await _dbService.leaveAllRooms(userId);
    }

    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _error = null;
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = 'Failed to send reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      _error = null;
      final userId = _authService.currentUserId;
      if (userId == null) return false;

      await _authService.updateUserProfile(
        userId: userId,
        username: username,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      await _loadUserProfile();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
