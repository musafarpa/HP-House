import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late Animation<double> _headerAnim;
  late Animation<double> _profileCardAnim;
  late Animation<double> _menuAnim;
  late Animation<double> _logoutAnim;

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

    _profileCardAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _menuAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _logoutAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;

            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _AppColors.white,
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _headerAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _headerAnim.value)),
                        child: Opacity(
                          opacity: _headerAnim.value,
                          child: _buildHeader(context),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _profileCardAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _profileCardAnim.value)),
                        child: Opacity(
                          opacity: _profileCardAnim.value,
                          child: _buildProfileCard(context, user),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _menuAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _menuAnim.value)),
                        child: Opacity(
                          opacity: _menuAnim.value,
                          child: _buildMenuSection(context),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _logoutAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _logoutAnim.value)),
                        child: Opacity(
                          opacity: _logoutAnim.value,
                          child: Column(
                            children: [
                              _buildLogoutButton(context),
                              const SizedBox(height: 24),
                              Text(
                                'Version ${AppConstants.appVersion}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: _AppColors.textMuted,
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
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Profile',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        _AnimatedIconButton(
          icon: Icons.settings_outlined,
          onTap: () {
            HapticFeedback.lightImpact();
            _showSettings(context);
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        children: [
          // Avatar with animation
          _AnimatedAvatar(user: user),
          const SizedBox(height: 20),
          // Name
          Text(
            user.displayNameOrUsername,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '@${user.username}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: _AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 28),
          // Stats
          Row(
            children: [
              Expanded(
                child: _AnimatedStat(
                  label: 'Followers',
                  count: user.followersCount,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      RouteNames.followers,
                      arguments: {'userId': user.id, 'showFollowers': true},
                    );
                  },
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: _AppColors.border,
              ),
              Expanded(
                child: _AnimatedStat(
                  label: 'Following',
                  count: user.followingCount,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      RouteNames.followers,
                      arguments: {'userId': user.id, 'showFollowers': false},
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Edit profile button
          _AnimatedButton(
            label: 'Edit Profile',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, RouteNames.editProfile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        children: [
          _AnimatedMenuItem(
            icon: Icons.history_rounded,
            title: 'Room History',
            index: 0,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _buildDivider(),
          _AnimatedMenuItem(
            icon: Icons.bookmark_outline_rounded,
            title: 'Saved Rooms',
            index: 1,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _buildDivider(),
          _AnimatedMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            index: 2,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, RouteNames.notifications);
            },
          ),
          _buildDivider(),
          _AnimatedMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            index: 3,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _buildDivider(),
          _AnimatedMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            index: 4,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: _AppColors.border,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.error.withAlpha(40)),
      ),
      child: _AnimatedMenuItem(
        icon: Icons.logout_rounded,
        title: 'Log Out',
        index: 0,
        textColor: _AppColors.error,
        iconColor: _AppColors.error,
        onTap: () {
          HapticFeedback.mediumImpact();
          _showLogoutDialog(context);
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildSettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: _AppColors.white,
                  activeTrackColor: _AppColors.white.withAlpha(60),
                  inactiveTrackColor: _AppColors.surfaceLight,
                  inactiveThumbColor: _AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'About',
                onTap: () {},
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _AppColors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _AppColors.textPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: _AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: _AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: _AppColors.textMuted,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: _AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log Out',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.plusJakartaSans(
              color: _AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _performLogout(dialogContext),
              child: Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  color: _AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogout(BuildContext dialogContext) async {
    // Close dialog first
    Navigator.pop(dialogContext);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(
            color: _AppColors.white,
            strokeWidth: 2,
          ),
        ),
      );

      // Perform sign out
      await context.read<AuthProvider>().signOut();

      // Navigate to login and clear all routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.login,
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: _AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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

// Animated Avatar with camera button
class _AnimatedAvatar extends StatefulWidget {
  final dynamic user;

  const _AnimatedAvatar({required this.user});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: _AppColors.surfaceLight,
            backgroundImage: widget.user.avatarUrl != null
                ? NetworkImage(widget.user.avatarUrl!)
                : null,
            child: widget.user.avatarUrl == null
                ? Text(
                    widget.user.displayNameOrUsername[0].toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.textSecondary,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) {
                _controller.reverse();
                HapticFeedback.lightImpact();
              },
              onTapCancel: () => _controller.reverse(),
              child: AnimatedBuilder(
                animation: _scale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _AppColors.surface,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: _AppColors.black,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Stat
class _AnimatedStat extends StatefulWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _AnimatedStat({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  State<_AnimatedStat> createState() => _AnimatedStatState();
}

class _AnimatedStatState extends State<_AnimatedStat>
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
            child: Column(
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: widget.count),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _AppColors.textPrimary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: _AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _AppColors.white.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    color: _AppColors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Menu Item
class _AnimatedMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final int index;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _AnimatedMenuItem({
    required this.icon,
    required this.title,
    required this.index,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  State<_AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<_AnimatedMenuItem>
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? _AppColors.white)
                          .withAlpha(widget.iconColor != null ? 20 : 10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor ?? _AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: widget.textColor ?? _AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _AppColors.textMuted,
                    size: 22,
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
