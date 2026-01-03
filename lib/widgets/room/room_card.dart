import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../models/room_model.dart';
import '../../providers/room_provider.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final int animationDelay;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.animationDelay = 0,
  });

  bool get isOwner => room.hostId == SupabaseConfig.currentUserId;

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this room? This cannot be undone.',
          style: TextStyle(color: AppTheme.grey600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.grey500, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await context.read<RoomProvider>().deleteRoom(room.id);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete room'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.primaryWhite, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: room.isLive ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryWhite,
          borderRadius: BorderRadius.circular(20),
          border: room.isLive
              ? Border.all(color: AppTheme.success.withAlpha(30), width: 1.5)
              : Border.all(color: AppTheme.grey200),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: room.isLive
                    ? LinearGradient(
                        colors: [AppTheme.success.withAlpha(8), AppTheme.primaryWhite],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Row
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: room.isLive ? AppTheme.liveGradient : null,
                          color: room.isLive ? null : AppTheme.grey100,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: room.isLive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.success.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: room.isLive ? AppTheme.primaryWhite : AppTheme.grey400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              room.isLive ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                color: room.isLive ? AppTheme.primaryWhite : AppTheme.grey500,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Room Type
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          room.isAudioRoom ? Icons.mic_rounded : Icons.videocam_rounded,
                          size: 16,
                          color: AppTheme.grey600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Participants
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt_rounded, size: 14, color: AppTheme.grey600),
                            const SizedBox(width: 6),
                            Text(
                              '${room.participantsCount}',
                              style: TextStyle(
                                color: AppTheme.grey700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    room.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grey900,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (room.description != null && room.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      room.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.grey100)),
              ),
              child: Row(
                children: [
                  // Host Avatar
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryWhite,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.grey200,
                        backgroundImage: room.hostAvatarUrl != null
                            ? NetworkImage(room.hostAvatarUrl!)
                            : null,
                        child: room.hostAvatarUrl == null
                            ? Text(
                                room.hostName?[0].toUpperCase() ?? 'H',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.grey600,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Host Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.hostName ?? 'Host',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey800,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: AppTheme.accentOrange),
                            const SizedBox(width: 4),
                            Text(
                              'Host',
                              style: TextStyle(fontSize: 11, color: AppTheme.grey500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Owner Controls
                  if (isOwner) ...[
                    // Toggle Button
                    GestureDetector(
                      onTap: () => context.read<RoomProvider>().toggleRoomStatus(room.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: room.isLive ? AppTheme.success.withAlpha(15) : AppTheme.grey100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: room.isLive ? AppTheme.success.withAlpha(30) : AppTheme.grey200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              room.isLive ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                              size: 14,
                              color: room.isLive ? AppTheme.success : AppTheme.grey500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room.isLive ? 'On' : 'Off',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: room.isLive ? AppTheme.success : AppTheme.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    GestureDetector(
                      onTap: () => _showDeleteDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_rounded, size: 18, color: AppTheme.error),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Join Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: room.isLive ? AppTheme.primaryGradient : null,
                      color: room.isLive ? null : AppTheme.grey200,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: room.isLive
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withAlpha(40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: room.isLive ? onTap : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            room.isLive ? 'Join' : 'Offline',
                            style: TextStyle(
                              color: room.isLive ? AppTheme.primaryWhite : AppTheme.grey500,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
