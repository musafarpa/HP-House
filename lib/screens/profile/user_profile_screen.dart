import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/supabase_config.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final DatabaseService _db = DatabaseService();

  UserModel? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _db.getUser(widget.userId);
      final currentUserId = SupabaseConfig.currentUserId;

      bool isFollowing = false;
      if (currentUserId != null && currentUserId != widget.userId) {
        isFollowing = await _db.isFollowing(currentUserId, widget.userId);
      }

      // Get followers/following counts
      final followers = await _db.getFollowers(widget.userId);
      final following = await _db.getFollowing(widget.userId);

      setState(() {
        _user = user;
        _isFollowing = isFollowing;
        _followersCount = followers.length;
        _followingCount = following.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await _db.unfollowUser(currentUserId, widget.userId);
        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
      } else {
        await _db.followUser(currentUserId, widget.userId);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseConfig.currentUserId;
    final isCurrentUser = currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: Text(_user?.username ?? 'Profile'),
        actions: [
          if (!isCurrentUser)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show more options
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppTheme.grey400),
                      const SizedBox(height: 16),
                      Text(
                        'User not found',
                        style: TextStyle(color: AppTheme.grey600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile header
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: AppTheme.primaryWhite,
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.grey300,
                              backgroundImage: _user!.avatarUrl != null
                                  ? NetworkImage(_user!.avatarUrl!)
                                  : null,
                              child: _user!.avatarUrl == null
                                  ? Text(
                                      _user!.displayNameOrUsername[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.grey700,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              _user!.displayNameOrUsername,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${_user!.username}',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.grey600,
                              ),
                            ),
                            if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                _user!.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.grey700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStat(
                                  'Followers',
                                  _followersCount,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.followers,
                                      arguments: {
                                        'userId': widget.userId,
                                        'showFollowers': true,
                                      },
                                    );
                                  },
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppTheme.grey300,
                                ),
                                _buildStat(
                                  'Following',
                                  _followingCount,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.followers,
                                      arguments: {
                                        'userId': widget.userId,
                                        'showFollowers': false,
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Action buttons
                            if (!isCurrentUser)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isFollowLoading ? null : _toggleFollow,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isFollowing
                                            ? AppTheme.primaryWhite
                                            : AppTheme.primaryBlack,
                                        foregroundColor: _isFollowing
                                            ? AppTheme.primaryBlack
                                            : AppTheme.primaryWhite,
                                        side: BorderSide(
                                          color: AppTheme.primaryBlack,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: _isFollowLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(
                                              _isFollowing ? 'Following' : 'Follow',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.newChat,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.all(12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      side: BorderSide(color: AppTheme.grey400),
                                    ),
                                    child: const Icon(Icons.chat_bubble_outline),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStat(String label, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
