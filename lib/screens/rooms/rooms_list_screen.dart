import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/room_provider.dart';
import '../../config/supabase_config.dart';

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
  static const Color live = Color(0xFFEF4444);
  static const Color border = Color(0xFF2E2E2E);
}

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<double> _headerAnim;
  late Animation<double> _tabAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
      context.read<RoomProvider>().loadLiveRooms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
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
                  _buildRoomsList(filter: 'all'),
                  _buildRoomsList(filter: 'live'),
                  _buildRoomsList(filter: 'my'),
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
                  'Discover Rooms',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<RoomProvider>(
                  builder: (context, provider, _) => Text(
                    '${provider.allRooms.length} rooms available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: _AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _AnimatedIconButton(
            icon: Icons.search_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(width: 8),
          _AnimatedIconButton(
            icon: Icons.tune_rounded,
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
          Tab(text: 'All'),
          Tab(text: 'Live'),
          Tab(text: 'My Rooms'),
        ],
      ),
    );
  }

  Widget _buildRoomsList({required String filter}) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        List rooms;
        if (filter == 'all') {
          rooms = roomProvider.allRooms;
        } else if (filter == 'live') {
          rooms = roomProvider.liveRooms;
        } else {
          rooms = roomProvider.allRooms
              .where((r) => r.hostId == SupabaseConfig.currentUserId)
              .toList();
        }

        if (roomProvider.isLoading && rooms.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _AppColors.white,
            ),
          );
        }

        if (rooms.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () => roomProvider.loadLiveRooms(),
          color: _AppColors.white,
          backgroundColor: _AppColors.surface,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _AnimatedRoomCard(
                room: room,
                index: index,
                onTap: room.isLive
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(
                          context,
                          RouteNames.room,
                          arguments: {'roomId': room.id},
                        );
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case 'live':
        title = 'No Live Rooms';
        subtitle = 'Start a room or wait for others';
        icon = Icons.wifi_off_rounded;
        break;
      case 'my':
        title = 'No Rooms Yet';
        subtitle = 'Create your first room';
        icon = Icons.add_home_rounded;
        break;
      default:
        title = 'No Rooms Found';
        subtitle = 'Be the first to start!';
        icon = Icons.home_work_rounded;
    }

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
                  child: Icon(icon, size: 36, color: _AppColors.textMuted),
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
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
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
            label: 'Create Room',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, RouteNames.createRoom);
            },
          ),
        ],
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

// Animated Room Card with stagger effect
class _AnimatedRoomCard extends StatefulWidget {
  final dynamic room;
  final int index;
  final VoidCallback? onTap;

  const _AnimatedRoomCard({
    required this.room,
    required this.index,
    this.onTap,
  });

  @override
  State<_AnimatedRoomCard> createState() => _AnimatedRoomCardState();
}

class _AnimatedRoomCardState extends State<_AnimatedRoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool get isOwner => widget.room.hostId == SupabaseConfig.currentUserId;

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
        onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _controller.reverse();
                widget.onTap!();
              }
            : null,
        onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.room.isLive
                        ? _AppColors.live.withAlpha(40)
                        : _AppColors.border,
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle glow for live rooms
                    if (widget.room.isLive)
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _AppColors.live.withAlpha(20),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              // Status badge with pulse
                              _PulsingStatusBadge(isLive: widget.room.isLive),
                              const Spacer(),
                              // Room type
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.room.isAudioRoom
                                      ? Icons.mic_rounded
                                      : Icons.videocam_rounded,
                                  size: 16,
                                  color: _AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Participants
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_rounded,
                                      size: 14,
                                      color: _AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.room.participantsCount}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            widget.room.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.room.description != null &&
                              widget.room.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.room.description!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: _AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Footer
                          Row(
                            children: [
                              // Host avatar
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: _AppColors.border,
                                backgroundImage: widget.room.hostAvatarUrl !=
                                        null
                                    ? NetworkImage(widget.room.hostAvatarUrl!)
                                    : null,
                                child: widget.room.hostAvatarUrl == null
                                    ? Text(
                                        widget.room.hostName?[0].toUpperCase() ??
                                            'H',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _AppColors.textSecondary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.room.hostName ?? 'Host',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Owner controls
                              if (isOwner) ...[
                                _AnimatedControlButton(
                                  icon: widget.room.isLive
                                      ? Icons.wifi_rounded
                                      : Icons.wifi_off_rounded,
                                  color: widget.room.isLive
                                      ? _AppColors.success
                                      : _AppColors.textMuted,
                                  bgColor: widget.room.isLive
                                      ? _AppColors.success.withAlpha(20)
                                      : _AppColors.surfaceLight,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context
                                        .read<RoomProvider>()
                                        .toggleRoomStatus(widget.room.id);
                                  },
                                ),
                                const SizedBox(width: 8),
                                _AnimatedControlButton(
                                  icon: Icons.delete_outline_rounded,
                                  color: _AppColors.error,
                                  bgColor: _AppColors.error.withAlpha(20),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showDeleteDialog(context);
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Join button
                              _AnimatedJoinButton(isLive: widget.room.isLive),
                            ],
                          ),
                        ],
                      ),
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: _AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Room',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this room?',
            style: GoogleFonts.plusJakartaSans(
              color: _AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<RoomProvider>().deleteRoom(widget.room.id);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pulsing Status Badge
class _PulsingStatusBadge extends StatefulWidget {
  final bool isLive;

  const _PulsingStatusBadge({required this.isLive});

  @override
  State<_PulsingStatusBadge> createState() => _PulsingStatusBadgeState();
}

class _PulsingStatusBadgeState extends State<_PulsingStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulse = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isLive ? _AppColors.live : _AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Opacity(
                opacity: widget.isLive ? _pulse.value : 1.0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isLive
                        ? _AppColors.white
                        : _AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.isLive ? 'LIVE' : 'OFFLINE',
            style: GoogleFonts.plusJakartaSans(
              color: widget.isLive ? _AppColors.white : _AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Control Button
class _AnimatedControlButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _AnimatedControlButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_AnimatedControlButton> createState() => _AnimatedControlButtonState();
}

class _AnimatedControlButtonState extends State<_AnimatedControlButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.color,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Join Button
class _AnimatedJoinButton extends StatefulWidget {
  final bool isLive;

  const _AnimatedJoinButton({required this.isLive});

  @override
  State<_AnimatedJoinButton> createState() => _AnimatedJoinButtonState();
}

class _AnimatedJoinButtonState extends State<_AnimatedJoinButton>
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
      onTapDown: widget.isLive ? (_) => _controller.forward() : null,
      onTapUp: widget.isLive ? (_) => _controller.reverse() : null,
      onTapCancel: widget.isLive ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color:
                    widget.isLive ? _AppColors.white : _AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isLive ? 'Join' : 'Offline',
                style: GoogleFonts.plusJakartaSans(
                  color:
                      widget.isLive ? _AppColors.black : _AppColors.textMuted,
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
