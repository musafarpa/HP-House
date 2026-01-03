import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/participant_model.dart';
import '../../widgets/room/participant_avatar.dart';

// Clean Modern Theme
class _Theme {
  // Core colors
  static const Color background = Color(0xFF000000);
  static const Color card = Color(0xFF121212);
  static const Color cardElevated = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2D2D2D);

  // Text colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGray = Color(0xFFAAAAAA);
  static const Color textDark = Color(0xFF777777);

  // Accent colors
  static const Color primary = Color(0xFF00D26A);  // Bright green
  static const Color green = Color(0xFF00D26A);  // Same as primary
  static const Color red = Color(0xFFFF5252);
  static const Color orange = Color(0xFFFFAB40);
}

class RoomScreen extends StatefulWidget {
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  late AnimationController _enterController;
  late AnimationController _pulseController;
  StreamSubscription? _participantsSubscription;
  List<ParticipantModel> _participants = [];
  RoomProvider? _roomProvider;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDisposed || !mounted) return;
      try {
        _roomProvider = context.read<RoomProvider>();
        _roomProvider?.addListener(_onProviderChange);

        // Join the room
        final success = await _roomProvider?.joinRoom(widget.roomId) ?? false;
        debugPrint('RoomScreen: joinRoom returned $success');

        if (_isDisposed || !mounted) return;

        // Update local participants immediately after join
        if (_roomProvider != null) {
          setState(() {
            _participants = List.from(_roomProvider?.participants ?? []);
            debugPrint('RoomScreen: Initial participants count: ${_participants.length}');
          });

          // If still no participants after join, retry with increasing delays
          if (_participants.isEmpty) {
            debugPrint('RoomScreen: No participants after join, starting retry loop');
            for (int i = 0; i < 5; i++) {
              await Future.delayed(Duration(milliseconds: 500 + (i * 300)));
              if (_isDisposed || !mounted) break;

              await _roomProvider?.forceReloadParticipants();
              if (_isDisposed || !mounted) break;

              final newParticipants = _roomProvider?.participants ?? [];
              debugPrint('RoomScreen: Retry $i - got ${newParticipants.length} participants');

              if (newParticipants.isNotEmpty) {
                setState(() {
                  _participants = List.from(newParticipants);
                });
                break;
              }
            }
          }
        }

        if (_isDisposed || !mounted) return;
        _setupParticipantsStream();
      } catch (e) {
        debugPrint('RoomScreen: Error in initState callback: $e');
      }
    });
  }

  void _onProviderChange() {
    if (_isDisposed || !mounted) return;
    if (_roomProvider != null) {
      final newParticipants = List<ParticipantModel>.from(_roomProvider!.participants);
      debugPrint('RoomScreen: Provider changed, participants: ${newParticipants.length}');
      setState(() {
        _participants = newParticipants;
      });
    }
  }

  void _setupParticipantsStream() {
    if (_isDisposed || !mounted) return;
    try {
      final roomProvider = context.read<RoomProvider>();
      final stream = roomProvider.getParticipantsStream(widget.roomId);

      if (stream != null) {
        _participantsSubscription?.cancel();
        _participantsSubscription = stream.listen((_) async {
          if (_isDisposed || !mounted) return;
          // Stream emits on any change - wait a bit for provider to update then refresh UI
          await Future.delayed(const Duration(milliseconds: 300));
          if (_isDisposed || !mounted) return;
          try {
            final provider = context.read<RoomProvider>();
            debugPrint('RoomScreen: Stream update, participants: ${provider.participants.length}');
            setState(() {
              _participants = List.from(provider.participants);
            });
          } catch (e) {
            debugPrint('RoomScreen: Error updating participants: $e');
          }
        }, onError: (e) {
          debugPrint('RoomScreen: Stream error: $e');
        });
      }

      // Initialize with current participants from provider
      debugPrint('RoomScreen: setupParticipantsStream - provider has ${roomProvider.participants.length} participants');
      if (roomProvider.participants.isNotEmpty && !_isDisposed && mounted) {
        setState(() {
          _participants = List.from(roomProvider.participants);
        });
      }
    } catch (e) {
      debugPrint('RoomScreen: Error setting up participants stream: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _roomProvider?.removeListener(_onProviderChange);
    _participantsSubscription?.cancel();
    _participantsSubscription = null;
    _enterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _leaveRoom() async {
    HapticFeedback.mediumImpact();
    await context.read<RoomProvider>().leaveRoom();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _endRoom() async {
    HapticFeedback.heavyImpact();
    await context.read<RoomProvider>().endCurrentRoom();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _leaveRoom();
      },
      child: Scaffold(
        backgroundColor: _Theme.background,
        body: Consumer<RoomProvider>(
          builder: (context, roomProvider, _) {
            final room = roomProvider.currentRoom;
            final currentUserId = context.read<AuthProvider>().user?.id;
            final isHost = room?.hostId == currentUserId;

            if (room == null) return _buildLoading();

            return Column(
              children: [
                _buildTopBar(room, roomProvider, isHost),
                Expanded(
                  child: _buildContent(roomProvider, currentUserId, isHost),
                ),
                _buildControls(roomProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _Theme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'Connecting...',
            style: GoogleFonts.plusJakartaSans(color: _Theme.textGray, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(dynamic room, RoomProvider provider, bool isHost) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: BoxDecoration(
        color: _Theme.card,
        border: Border(bottom: BorderSide(color: _Theme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              _IconBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: _leaveRoom,
              ),
              const SizedBox(width: 12),
              // Live badge
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _Theme.red,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: _Theme.red.withAlpha((30 + _pulseController.value * 30).toInt()),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              // Participant count - use local _participants for real-time updates
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _Theme.cardElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded, size: 14, color: _Theme.textGray),
                    const SizedBox(width: 5),
                    Text(
                      '${_participants.isNotEmpty ? _participants.length : provider.participants.length}',
                      style: GoogleFonts.plusJakartaSans(
                        color: _Theme.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isHost)
                _IconBtn(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showOptions(context),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            room.title,
            style: GoogleFonts.spaceGrotesk(
              color: _Theme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (room.description != null && room.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              room.description!,
              style: GoogleFonts.plusJakartaSans(color: _Theme.textGray, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // Get speakers from local participants list
  List<ParticipantModel> get _speakers =>
      _participants.where((p) => p.isSpeaker).toList();

  // Get listeners from local participants list
  List<ParticipantModel> get _listeners =>
      _participants.where((p) => p.isListener).toList();

  Widget _buildContent(RoomProvider provider, String? userId, bool isHost) {
    // Use local _participants for real-time updates, fallback to provider if empty
    final speakers = _participants.isNotEmpty ? _speakers : provider.speakers;
    final listeners = _participants.isNotEmpty ? _listeners : provider.listeners;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speakers
          _Section(
            icon: Icons.mic_rounded,
            title: 'Speakers',
            count: speakers.length,
            color: _Theme.primary,
          ),
          const SizedBox(height: 16),
          speakers.isEmpty
              ? _EmptyBox(text: 'No speakers yet', icon: Icons.mic_off_rounded)
              : _buildSpeakersGrid(speakers, userId, isHost),
          const SizedBox(height: 28),
          // Listeners
          _Section(
            icon: Icons.headphones_rounded,
            title: 'Listeners',
            count: listeners.length,
            color: _Theme.green,
          ),
          const SizedBox(height: 16),
          listeners.isEmpty
              ? _EmptyBox(text: 'No listeners yet', icon: Icons.people_outline_rounded)
              : _buildListenersGrid(listeners, userId, isHost),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSpeakersGrid(List<ParticipantModel> speakers, String? userId, bool isHost) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: speakers.length,
      itemBuilder: (context, index) {
        final speaker = speakers[index];
        final isMe = speaker.odiumId == userId;
        return _SpeakerCard(
          name: isMe ? 'You' : speaker.odiumName,
          isMuted: speaker.isMuted,
          isMe: isMe,
          pulseController: _pulseController,
          onTap: isHost && !isMe
              ? () => _showUserOptions(context, speaker.odiumId, speaker.odiumName, true)
              : null,
        );
      },
    );
  }

  Widget _buildListenersGrid(List<ParticipantModel> listeners, String? userId, bool isHost) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: listeners.length,
      itemBuilder: (context, index) {
        final listener = listeners[index];
        return ParticipantAvatar(
          participant: listener,
          isSmall: true,
          isCurrentUser: listener.odiumId == userId,
          onTap: isHost
              ? () => _showUserOptions(context, listener.odiumId, listener.odiumName, false)
              : null,
        );
      },
    );
  }

  Widget _buildControls(RoomProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _Theme.card,
        border: Border(top: BorderSide(color: _Theme.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ControlBtn(
            icon: Icons.call_end_rounded,
            label: 'Leave',
            color: _Theme.red,
            filled: true,
            onTap: _leaveRoom,
          ),
          _ControlBtn(
            icon: provider.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: provider.isMuted ? 'Unmute' : 'Mute',
            color: _Theme.textWhite,
            filled: !provider.isMuted,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleMute();
            },
          ),
          _ControlBtn(
            icon: provider.isSpeakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
            label: provider.isSpeakerOn ? 'Speaker' : 'Earpiece',
            color: provider.isSpeakerOn ? _Theme.green : _Theme.textGray,
            filled: provider.isSpeakerOn,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleSpeaker();
            },
          ),
          _ControlBtn(
            icon: Icons.front_hand_rounded,
            label: provider.hasRaisedHand ? 'Lower' : 'Raise',
            color: provider.hasRaisedHand ? _Theme.orange : _Theme.textGray,
            filled: provider.hasRaisedHand,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.raiseHand();
            },
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheet(
        title: 'Room Options',
        children: [
          _SheetOption(
            icon: Icons.stop_circle_rounded,
            title: 'End Room',
            subtitle: 'Close for everyone',
            color: _Theme.red,
            onTap: () {
              Navigator.pop(context);
              _endRoom();
            },
          ),
        ],
      ),
    );
  }

  void _showUserOptions(BuildContext ctx, String odiumId, String name, bool isSpeaker) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheet(
        title: name,
        children: [
          _SheetOption(
            icon: isSpeaker ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            title: isSpeaker ? 'Move to Listeners' : 'Make Speaker',
            subtitle: isSpeaker ? 'Remove from stage' : 'Invite to speak',
            color: isSpeaker ? _Theme.textGray : _Theme.green,
            onTap: () {
              HapticFeedback.mediumImpact();
              if (isSpeaker) {
                context.read<RoomProvider>().demoteToListener(odiumId);
              } else {
                context.read<RoomProvider>().promoteToSpeaker(odiumId);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _Theme.cardElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _Theme.textLight, size: 22),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _Section({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: _Theme.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _EmptyBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _Theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _Theme.textDark),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(color: _Theme.textDark, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SpeakerCard extends StatelessWidget {
  final String name;
  final bool isMuted;
  final bool isMe;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  const _SpeakerCard({
    required this.name,
    required this.isMuted,
    required this.isMe,
    required this.pulseController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              // Speaking ring
              if (!isMuted)
                AnimatedBuilder(
                  animation: pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 68 + (pulseController.value * 6),
                      height: 68 + (pulseController.value * 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _Theme.primary.withAlpha((80 + pulseController.value * 60).toInt()),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isMe ? _Theme.primary : _Theme.cardElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe ? _Theme.primary : _Theme.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isMe ? Colors.white : _Theme.textLight,
                    ),
                  ),
                ),
              ),
              // Muted badge
              if (isMuted)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _Theme.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: _Theme.background, width: 2),
                    ),
                    child: const Icon(Icons.mic_off_rounded, size: 11, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              color: isMe ? _Theme.primary : _Theme.textLight,
              fontSize: 13,
              fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.filled ? widget.color : _Theme.cardElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.filled ? widget.color : _Theme.border,
                  width: 2,
                ),
              ),
              child: Icon(
                widget.icon,
                color: widget.filled ? _Theme.background : _Theme.textLight,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                color: widget.filled ? widget.color : _Theme.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BottomSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: _Theme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _Theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: _Theme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: _Theme.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(color: _Theme.textDark, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withAlpha(120), size: 20),
          ],
        ),
      ),
    );
  }
}
