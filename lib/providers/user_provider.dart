import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../config/supabase_config.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<UserModel> _searchResults = [];
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get followers => _followers;
  List<UserModel> get following => _following;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get currentUserId => SupabaseConfig.currentUserId;

  // Search users
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _searchResults = await _db.searchUsers(query);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to search users';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user profile
  Future<UserModel?> getUser(String odiumId) async {
    try {
      return await _db.getUser(odiumId);
    } catch (e) {
      _error = 'Failed to get user profile';
      notifyListeners();
      return null;
    }
  }

  // Load followers
  Future<void> loadFollowers(String odiumId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _followers = await _db.getFollowers(odiumId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load followers';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load following
  Future<void> loadFollowing(String odiumId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _following = await _db.getFollowing(odiumId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load following';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Follow user
  Future<bool> followUser(String targetUserId) async {
    try {
      final currentId = currentUserId;
      if (currentId == null) return false;

      await _db.followUser(currentId, targetUserId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to follow user';
      notifyListeners();
      return false;
    }
  }

  // Unfollow user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentId = currentUserId;
      if (currentId == null) return false;

      await _db.unfollowUser(currentId, targetUserId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to unfollow user';
      notifyListeners();
      return false;
    }
  }

  // Check if following
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentId = currentUserId;
      if (currentId == null) return false;

      return await _db.isFollowing(currentId, targetUserId);
    } catch (e) {
      return false;
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
