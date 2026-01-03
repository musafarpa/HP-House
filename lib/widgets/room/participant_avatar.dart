import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/participant_model.dart';

class ParticipantAvatar extends StatefulWidget {
  final ParticipantModel participant;
  final bool isSmall;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const ParticipantAvatar({
    super.key,
    required this.participant,
    this.isSmall = false,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  State<ParticipantAvatar> createState() => _ParticipantAvatarState();
}

class _ParticipantAvatarState extends State<ParticipantAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Only pulse if not muted (speaking indicator)
    if (!widget.participant.isMuted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ParticipantAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.participant.isMuted != oldWidget.participant.isMuted) {
      if (widget.participant.isMuted) {
        _pulseController.stop();
        _pulseController.reset();
      } else {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSmall ? 56.0 : 72.0;
    final fontSize = widget.isSmall ? 12.0 : 14.0;
    final avatarSize = widget.isSmall ? 44.0 : 56.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar with animated border
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue =
                      widget.participant.isMuted ? 0.0 : _pulseController.value;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.participant.isMuted
                          ? null
                          : LinearGradient(
                              colors: [
                                AppTheme.success,
                                AppTheme.success.withAlpha(200),
                              ],
                            ),
                      border: widget.participant.isMuted
                          ? Border.all(
                              color: AppTheme.grey300,
                              width: 2,
                            )
                          : null,
                      boxShadow: widget.participant.isMuted
                          ? null
                          : [
                              BoxShadow(
                                color: AppTheme.success.withAlpha(
                                    (30 + (pulseValue * 40)).toInt()),
                                blurRadius: 8 + (pulseValue * 8),
                                spreadRadius: pulseValue * 3,
                              ),
                            ],
                    ),
                    padding: EdgeInsets.all(widget.participant.isMuted ? 0 : 3),
                    child: child,
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryWhite,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: AppTheme.grey200,
                    backgroundImage: widget.participant.avatarUrl != null
                        ? NetworkImage(widget.participant.avatarUrl!)
                        : null,
                    child: widget.participant.avatarUrl == null
                        ? Text(
                            widget.participant.odiumName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: widget.isSmall ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.grey600,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Mute indicator
              if (widget.participant.isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.grey200,
                          AppTheme.grey100,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryWhite,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic_off_rounded,
                      size: widget.isSmall ? 10 : 12,
                      color: AppTheme.grey600,
                    ),
                  ),
                ),
              // Host badge
              if (widget.participant.isHost)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunsetGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryWhite,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentOrange.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: widget.isSmall ? 10 : 12,
                      color: AppTheme.primaryWhite,
                    ),
                  ),
                ),
              // Raised hand indicator
              if (widget.participant.hasRaisedHand)
                Positioned(
                  top: -4,
                  left: -4,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.warning,
                            AppTheme.accentOrange,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryWhite,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warning.withAlpha(80),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.front_hand_rounded,
                        size: widget.isSmall ? 10 : 12,
                        color: AppTheme.primaryWhite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: widget.isCurrentUser
                ? BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
            child: Text(
              widget.isCurrentUser ? 'You' : widget.participant.odiumName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight:
                    widget.isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                color: widget.isCurrentUser
                    ? AppTheme.primaryWhite
                    : const Color(0xFFAAAAAA),  // Light gray for dark theme
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
