import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/supabase_config.dart';
import '../../providers/chat_provider.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

// Black & White Theme Colors
class _AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textMuted = Color(0xFF737373);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color border = Color(0xFF2E2E2E);
}

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<double> _headerAnim;
  late Animation<double> _tabAnim;

  final DatabaseService _db = DatabaseService();
  List<UserModel> _allUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _tabAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _headerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
      _loadAllUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final currentUserId = SupabaseConfig.currentUserId;
      final users = await _db.getAllUsers(excludeUserId: currentUserId);
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _startConversation(UserModel user) async {
    final chatProvider = context.read<ChatProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _AppColors.white,
          ),
        ),
      ),
    );

    final conversation = await chatProvider.startDirectConversation(user.id);

    if (!mounted) return;
    Navigator.pop(context);

    if (conversation != null) {
      Navigator.pushNamed(
        context,
        RouteNames.chat,
        arguments: {'conversationId': conversation.id},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _headerAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _headerAnim.value)),
                  child: Opacity(
                    opacity: _headerAnim.value,
                    child: _buildHeader(),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _tabAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _tabAnim.value)),
                  child: Opacity(
                    opacity: _tabAnim.value,
                    child: _buildTabBar(),
                  ),
                );
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatsList(),
                  _buildMembersList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    final unread = provider.conversations
                        .where((c) => c.unreadCount > 0)
                        .length;
                    return Text(
                      unread > 0
                          ? '$unread unread messages'
                          : 'All caught up!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: unread > 0
                            ? _AppColors.white
                            : _AppColors.textSecondary,
                        fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _AnimatedIconButton(
            icon: Icons.edit_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _AppColors.black,
        unselectedLabelColor: _AppColors.textMuted,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          color: _AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(10),
        tabs: const [
          Tab(text: 'Chats'),
          Tab(text: 'Members'),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _AppColors.white,
            ),
          );
        }

        if (chatProvider.conversations.isEmpty) {
          return _buildEmptyChats();
        }

        return RefreshIndicator(
          onRefresh: () => chatProvider.loadConversations(),
          color: _AppColors.white,
          backgroundColor: _AppColors.surface,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              return _AnimatedChatCard(
                conversation: conversation,
                index: index,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(
                    context,
                    RouteNames.chat,
                    arguments: {'conversationId': conversation.id},
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyChats() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: _AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 36,
                    color: _AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    children: [
                      Text(
                        'No Messages Yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation with someone',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _AnimatedButton(
            label: 'Find Members',
            onTap: () {
              HapticFeedback.mediumImpact();
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _AppColors.white,
        ),
      );
    }

    if (_allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: _AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      size: 36,
                      color: _AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Column(
                      children: [
                        Text(
                          'No Members Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invite friends to join',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: _AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      color: _AppColors.white,
      backgroundColor: _AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          return _AnimatedMemberCard(
            user: user,
            index: index,
            onTap: () {
              HapticFeedback.lightImpact();
              _startConversation(user);
            },
          );
        },
      ),
    );
  }
}

// Animated Icon Button
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedIconButton({required this.icon, required this.onTap});

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _AppColors.border),
              ),
              child: Icon(
                widget.icon,
                color: _AppColors.textPrimary,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Button
class _AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedButton({required this.label, required this.onTap});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _AppColors.white.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Chat Card
class _AnimatedChatCard extends StatefulWidget {
  final dynamic conversation;
  final int index;
  final VoidCallback onTap;

  const _AnimatedChatCard({
    required this.conversation,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedChatCard> createState() => _AnimatedChatCardState();
}

class _AnimatedChatCardState extends State<_AnimatedChatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.conversation.unreadCount > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 50).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasUnread
                        ? _AppColors.white.withAlpha(30)
                        : _AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: _AppColors.surfaceLight,
                          backgroundImage: widget.conversation.otherUserAvatar != null
                              ? NetworkImage(widget.conversation.otherUserAvatar!)
                              : null,
                          child: widget.conversation.otherUserAvatar == null
                              ? Text(
                                  widget.conversation.otherUserName?[0].toUpperCase() ?? '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _AppColors.textSecondary,
                                  ),
                                )
                              : null,
                        ),
                        if (hasUnread)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _PulsingBadge(count: widget.conversation.unreadCount),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.conversation.otherUserName ?? 'Unknown',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: _AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.conversation.lastMessage ?? 'No messages yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: hasUnread
                                  ? _AppColors.textPrimary
                                  : _AppColors.textSecondary,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(widget.conversation.lastMessageTime),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: hasUnread ? _AppColors.white : _AppColors.textMuted,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _AppColors.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}';
  }
}

// Pulsing Badge for unread count
class _PulsingBadge extends StatefulWidget {
  final int count;

  const _PulsingBadge({required this.count});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _AppColors.surface,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${widget.count}',
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Member Card
class _AnimatedMemberCard extends StatefulWidget {
  final UserModel user;
  final int index;
  final VoidCallback onTap;

  const _AnimatedMemberCard({
    required this.user,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedMemberCard> createState() => _AnimatedMemberCardState();
}

class _AnimatedMemberCardState extends State<_AnimatedMemberCard> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 50).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _AppColors.surfaceLight,
              backgroundImage:
                  widget.user.avatarUrl != null ? NetworkImage(widget.user.avatarUrl!) : null,
              child: widget.user.avatarUrl == null
                  ? Text(
                      widget.user.displayNameOrUsername[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayNameOrUsername,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.user.username}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _AnimatedChatButton(onTap: widget.onTap),
          ],
        ),
      ),
    );
  }
}

// Animated Chat Button
class _AnimatedChatButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedChatButton({required this.onTap});

  @override
  State<_AnimatedChatButton> createState() => _AnimatedChatButtonState();
}

class _AnimatedChatButtonState extends State<_AnimatedChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Chat',
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
