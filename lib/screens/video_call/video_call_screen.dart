import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/call_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;

  const VideoCallScreen({super.key, required this.roomId});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallProvider>().initializeCall(
            roomId: widget.roomId,
            video: true,
            audio: true,
          );
    });
  }

  Future<void> _endCall() async {
    await context.read<CallProvider>().endCall();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: SafeArea(
          child: Consumer<CallProvider>(
            builder: (context, callProvider, _) {
              if (callProvider.state == CallState.connecting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryWhite,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: AppTheme.primaryWhite,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  // Video grid
                  _buildVideoGrid(callProvider),
                  // Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color.fromRGBO(0, 0, 0, 0.8),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Switch camera
                          _buildControlButton(
                            icon: Icons.cameraswitch,
                            onTap: () => callProvider.switchCamera(),
                          ),
                          // Toggle video
                          _buildControlButton(
                            icon: callProvider.isVideoEnabled
                                ? Icons.videocam
                                : Icons.videocam_off,
                            isActive: callProvider.isVideoEnabled,
                            onTap: () => callProvider.toggleVideo(),
                          ),
                          // End call
                          _buildControlButton(
                            icon: Icons.call_end,
                            color: AppTheme.error,
                            onTap: _endCall,
                          ),
                          // Toggle audio
                          _buildControlButton(
                            icon: callProvider.isAudioEnabled
                                ? Icons.mic
                                : Icons.mic_off,
                            isActive: callProvider.isAudioEnabled,
                            onTap: () => callProvider.toggleAudio(),
                          ),
                          // More options
                          _buildControlButton(
                            icon: Icons.more_horiz,
                            onTap: () {
                              // TODO: Show more options
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(CallProvider callProvider) {
    final localRenderer = callProvider.localRenderer;
    final remoteRenderers = callProvider.remoteRenderers;
    final totalParticipants = remoteRenderers.length + 1;

    if (totalParticipants == 1) {
      // Only local video - show full screen
      return localRenderer != null
          ? RTCVideoView(
              localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: true,
            )
          : const Center(
              child: Icon(
                Icons.videocam_off,
                color: AppTheme.grey600,
                size: 64,
              ),
            );
    }

    // Calculate grid layout based on participant count
    int crossAxisCount = 2;
    if (totalParticipants > 4) crossAxisCount = 3;
    if (totalParticipants > 9) crossAxisCount = 4;

    final allRenderers = <Widget>[
      // Local video
      _buildVideoTile(
        renderer: localRenderer,
        isMirror: true,
        label: 'You',
      ),
      // Remote videos
      ...remoteRenderers.entries.map((entry) {
        return _buildVideoTile(
          renderer: entry.value,
          label: entry.key.substring(0, 4),
        );
      }),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemCount: allRenderers.length,
      itemBuilder: (context, index) => allRenderers[index],
    );
  }

  Widget _buildVideoTile({
    RTCVideoRenderer? renderer,
    bool isMirror = false,
    String? label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (renderer != null)
            RTCVideoView(
              renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: isMirror,
            )
          else
            const Center(
              child: Icon(
                Icons.person,
                color: AppTheme.grey600,
                size: 48,
              ),
            ),
          if (label != null)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.primaryWhite,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = true,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color ?? (isActive ? AppTheme.grey800 : AppTheme.grey600),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryWhite,
          size: 24,
        ),
      ),
    );
  }
}
