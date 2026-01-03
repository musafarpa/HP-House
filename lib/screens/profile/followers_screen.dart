import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final bool showFollowers; // true = followers, false = following

  const FollowersScreen({
    super.key,
    required this.userId,
    this.showFollowers = true,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();

  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  final Set<String> _followingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showFollowers ? 0 : 1,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
      _loadCurrentUserFollowing(),
    ]);
  }

  Future<void> _loadFollowers() async {
    try {
      final followers = await _db.getFollowers(widget.userId);
      setState(() {
        _followers = followers;
        _isLoadingFollowers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFollowers = false;
      });
      debugPrint('Error loading followers: $e');
    }
  }

  Future<void> _loadFollowing() async {
    try {
      final following = await _db.getFollowing(widget.userId);
      setState(() {
        _following = following;
        _isLoadingFollowing = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFollowing = false;
      });
      debugPrint('Error loading following: $e');
    }
  }

  Future<void> _loadCurrentUserFollowing() async {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) return;

    try {
      final following = await _db.getFollowing(currentUserId);
      setState(() {
        _followingIds.clear();
        _followingIds.addAll(following.map((u) => u.id));
      });
    } catch (e) {
      debugPrint('Error loading current user following: $e');
    }
  }

  Future<void> _toggleFollow(String userId) async {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) return;

    final isFollowing = _followingIds.contains(userId);

    try {
      if (isFollowing) {
        await _db.unfollowUser(currentUserId, userId);
        setState(() {
          _followingIds.remove(userId);
        });
      } else {
        await _db.followUser(currentUserId, userId);
        setState(() {
          _followingIds.add(userId);
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Connections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Followers (${_followers.length})'),
            Tab(text: 'Following (${_following.length})'),
          ],
          labelColor: AppTheme.primaryBlack,
          unselectedLabelColor: AppTheme.grey600,
          indicatorColor: AppTheme.primaryBlack,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(
            users: _followers,
            isLoading: _isLoadingFollowers,
            emptyMessage: 'No followers yet',
            emptySubtext: 'When someone follows you, they\'ll appear here',
          ),
          _buildUserList(
            users: _following,
            isLoading: _isLoadingFollowing,
            emptyMessage: 'Not following anyone',
            emptySubtext: 'Find people to follow',
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({
    required List<UserModel> users,
    required bool isLoading,
    required String emptyMessage,
    required String emptySubtext,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.grey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: AppTheme.grey500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtext,
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final currentUserId = SupabaseConfig.currentUserId;
    final isCurrentUser = user.id == currentUserId;
    final isFollowing = _followingIds.contains(user.id);

    return ListTile(
      onTap: () {
        // Navigate to user profile
        // Navigator.pushNamed(context, RouteNames.userProfile, arguments: {'userId': user.id});
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.grey300,
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                user.displayNameOrUsername[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.grey700,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayNameOrUsername,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(
          color: AppTheme.grey600,
          fontSize: 14,
        ),
      ),
      trailing: isCurrentUser
          ? null
          : SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: () => _toggleFollow(user.id),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? AppTheme.primaryWhite
                      : AppTheme.primaryBlack,
                  foregroundColor: isFollowing
                      ? AppTheme.primaryBlack
                      : AppTheme.primaryWhite,
                  side: const BorderSide(color: AppTheme.primaryBlack),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
