import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/supabase_config.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUserId = SupabaseConfig.currentUserId;
      final results = await _db.searchUsers(query, excludeUserId: currentUserId);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search users';
        _isLoading = false;
      });
      debugPrint('Error searching users: $e');
    }
  }

  Future<void> _startConversation(UserModel user) async {
    final chatProvider = context.read<ChatProvider>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final conversation = await chatProvider.startDirectConversation(user.id);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (conversation != null) {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.chat,
        arguments: {'conversationId': conversation.id},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start conversation'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryWhite,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: AppTheme.grey500),
                prefixIcon: Icon(Icons.search, color: AppTheme.grey500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.grey500),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.grey100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          // Results
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
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
                Icons.person_search,
                size: 40,
                color: AppTheme.grey500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search for users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Find someone to chat with',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: AppTheme.grey500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          onTap: () => _startConversation(user),
          onLongPress: () => _showUserOptions(user),
          leading: GestureDetector(
            onTap: () => _viewUserProfile(user),
            child: CircleAvatar(
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
          trailing: Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.grey500,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        );
      },
    );
  }

  void _viewUserProfile(UserModel user) {
    Navigator.pushNamed(
      context,
      RouteNames.userProfile,
      arguments: {'userId': user.id},
    );
  }

  void _showUserOptions(UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('@${user.username}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                _viewUserProfile(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _startConversation(user);
              },
            ),
          ],
        ),
      ),
    );
  }
}
