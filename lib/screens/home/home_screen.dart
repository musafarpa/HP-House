import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../rooms/rooms_list_screen.dart';
import '../chat/chats_list_screen.dart';
import '../profile/profile_screen.dart';

// Black & White Theme Colors
class AppColors {
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabController;
  late AnimationController _navController;
  late Animation<double> _fabScale;
  late Animation<double> _navSlide;

  final List<Widget> _screens = [
    const _HomeTab(),
    const RoomsListScreen(),
    const SizedBox(),
    const ChatsListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _navController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    _navSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic),
    );

    _navController.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _navSlide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _navSlide.value),
                  child: _buildBottomNav(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 10,
            top: 12,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(220),
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.explore_rounded, 'Rooms'),
              _buildFAB(),
              _buildNavItem(3, Icons.chat_bubble_rounded, 'Chats'),
              _buildNavItem(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
        _pageController.jumpToPage(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? AppColors.white : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTapDown: (_) => _fabController.forward(),
      onTapUp: (_) {
        _fabController.reverse();
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, RouteNames.createRoom);
      },
      onTapCancel: () => _fabController.reverse(),
      child: AnimatedBuilder(
        animation: _fabScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScale.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.white.withAlpha(30),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.black,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late Animation<double> _headerAnim;
  late Animation<double> _quickActionsAnim;
  late Animation<double> _liveRoomsAnim;
  late Animation<double> _myRoomsAnim;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
      ),
    );

    _quickActionsAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _liveRoomsAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _myRoomsAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _staggerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadLiveRooms();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _headerAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _headerAnim.value)),
                  child: Opacity(
                    opacity: _headerAnim.value,
                    child: _buildHeader(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _quickActionsAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _quickActionsAnim.value)),
                  child: Opacity(
                    opacity: _quickActionsAnim.value,
                    child: _buildQuickActions(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _liveRoomsAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _liveRoomsAnim.value)),
                  child: Opacity(
                    opacity: _liveRoomsAnim.value,
                    child: _buildLiveRooms(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _myRoomsAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _myRoomsAnim.value)),
                  child: Opacity(
                    opacity: _myRoomsAnim.value,
                    child: _buildMyRooms(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayNameOrUsername ?? 'User',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _AnimatedNotificationButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, RouteNames.notifications);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedQuickActionCard(
              icon: Icons.mic_rounded,
              label: 'Start Audio',
              delay: 0,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, RouteNames.createRoom);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnimatedQuickActionCard(
              icon: Icons.videocam_rounded,
              label: 'Start Video',
              delay: 100,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, RouteNames.createRoom);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnimatedQuickActionCard(
              icon: Icons.schedule_rounded,
              label: 'Schedule',
              delay: 200,
              isOutlined: true,
              onTap: () {
                HapticFeedback.mediumImpact();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRooms() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        final liveRooms = roomProvider.liveRooms;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _PulsingLiveBadge(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${liveRooms.length} active rooms',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Text(
                      'See All',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (roomProvider.isLoading && liveRooms.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
              )
            else if (liveRooms.isEmpty)
              _buildEmptyLiveRooms()
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: liveRooms.length,
                  itemBuilder: (context, index) {
                    return _AnimatedLiveRoomCard(
                      room: liveRooms[index],
                      index: index,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyLiveRooms() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Live Rooms',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start a room!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRooms() {
    return Consumer2<RoomProvider, AuthProvider>(
      builder: (context, roomProvider, authProvider, _) {
        final currentUserId = authProvider.user?.id;
        final myRooms = roomProvider.allRooms
            .where((r) => r.hostId == currentUserId)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_work_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'My Rooms',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _AnimatedCreateButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, RouteNames.createRoom);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (myRooms.isEmpty)
              _buildEmptyMyRooms()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: myRooms.length > 3 ? 3 : myRooms.length,
                itemBuilder: (context, index) {
                  return _AnimatedMyRoomCard(
                    room: myRooms[index],
                    index: index,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMyRooms() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_home_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create your first room',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start hosting audio or video rooms',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// Animated Notification Button with bounce effect
class _AnimatedNotificationButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedNotificationButton({required this.onTap});

  @override
  State<_AnimatedNotificationButton> createState() => _AnimatedNotificationButtonState();
}

class _AnimatedNotificationButtonState extends State<_AnimatedNotificationButton>
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _PulsingDot(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Pulsing dot for notifications
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
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
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.live,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Pulsing LIVE badge
class _PulsingLiveBadge extends StatefulWidget {
  @override
  State<_PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<_PulsingLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 0.6).animate(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.live,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Opacity(
                opacity: _pulse.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE NOW',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
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

// Animated Quick Action Card with scale and press effects
class _AnimatedQuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isOutlined;
  final int delay;

  const _AnimatedQuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isOutlined = false,
    this.delay = 0,
  });

  @override
  State<_AnimatedQuickActionCard> createState() => _AnimatedQuickActionCardState();
}

class _AnimatedQuickActionCardState extends State<_AnimatedQuickActionCard>
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isOutlined ? Colors.transparent : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: widget.isOutlined
                    ? Border.all(color: AppColors.border, width: 1.5)
                    : null,
                boxShadow: widget.isOutlined
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.white.withAlpha(15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isOutlined ? AppColors.white : AppColors.black,
                    size: 26,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      color: widget.isOutlined ? AppColors.white : AppColors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Create Button
class _AnimatedCreateButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedCreateButton({required this.onTap});

  @override
  State<_AnimatedCreateButton> createState() => _AnimatedCreateButtonState();
}

class _AnimatedCreateButtonState extends State<_AnimatedCreateButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: AppColors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Create',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Live Room Card with hover effect
class _AnimatedLiveRoomCard extends StatefulWidget {
  final dynamic room;
  final int index;

  const _AnimatedLiveRoomCard({required this.room, required this.index});

  @override
  State<_AnimatedLiveRoomCard> createState() => _AnimatedLiveRoomCardState();
}

class _AnimatedLiveRoomCardState extends State<_AnimatedLiveRoomCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
        HapticFeedback.lightImpact();
        Navigator.pushNamed(
          context,
          RouteNames.room,
          arguments: {'roomId': widget.room.id},
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.live,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LIVE',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        widget.room.isAudioRoom
                            ? Icons.mic_rounded
                            : Icons.videocam_rounded,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.room.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.surfaceLight,
                        backgroundImage: widget.room.hostAvatarUrl != null
                            ? NetworkImage(widget.room.hostAvatarUrl!)
                            : null,
                        child: widget.room.hostAvatarUrl == null
                            ? Text(
                                widget.room.hostName?[0].toUpperCase() ?? 'H',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.room.hostName ?? 'Host',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.room.participantsCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated My Room Card
class _AnimatedMyRoomCard extends StatefulWidget {
  final dynamic room;
  final int index;

  const _AnimatedMyRoomCard({required this.room, required this.index});

  @override
  State<_AnimatedMyRoomCard> createState() => _AnimatedMyRoomCardState();
}

class _AnimatedMyRoomCardState extends State<_AnimatedMyRoomCard>
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
    return GestureDetector(
      onTapDown: widget.room.isLive ? (_) => _controller.forward() : null,
      onTapUp: widget.room.isLive
          ? (_) {
              _controller.reverse();
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                RouteNames.room,
                arguments: {'roomId': widget.room.id},
              );
            }
          : null,
      onTapCancel: widget.room.isLive ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.room.isLive
                      ? AppColors.success.withAlpha(80)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.room.isLive
                          ? AppColors.success.withAlpha(30)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.room.isAudioRoom
                          ? Icons.mic_rounded
                          : Icons.videocam_rounded,
                      color: widget.room.isLive
                          ? AppColors.success
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.room.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.room.isLive
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.room.isLive ? 'Live' : 'Offline',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: widget.room.isLive
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.people_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.room.participantsCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _AnimatedToggleButton(
                    isLive: widget.room.isLive,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<RoomProvider>().toggleRoomStatus(widget.room.id);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Toggle Button
class _AnimatedToggleButton extends StatefulWidget {
  final bool isLive;
  final VoidCallback onTap;

  const _AnimatedToggleButton({required this.isLive, required this.onTap});

  @override
  State<_AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<_AnimatedToggleButton>
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isLive
                    ? AppColors.success.withAlpha(30)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.isLive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: widget.isLive ? AppColors.success : AppColors.textMuted,
                size: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}
