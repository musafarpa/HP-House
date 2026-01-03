import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Set<String> _pendingOfferReceivedFrom = {}; // Track users who sent us offers

  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  String? _currentUserId; // Our user ID for deterministic offer creation

  bool _isAudioEnabled = true;
  bool _isVideoEnabled = true;
  bool _isDisposed = false;
  bool _isSpeakerOn = true; // Default to speaker phone

  // Callbacks
  Function(String odiumId, MediaStream stream)? onRemoteStream;
  Function(String odiumId)? onRemoteStreamRemoved;
  Function(String targetId, RTCSessionDescription sdp)? onLocalOffer;
  Function(String targetId, RTCSessionDescription sdp)? onLocalAnswer;
  Function(String targetId, RTCIceCandidate candidate)? onIceCandidate;
  Function(String odiumId)? onConnectionFailed; // Called when ICE connection fails
  Function(String odiumId)? onConnectionConnected; // Called when ICE connection succeeds
  Function(String odiumId)? onConnectionConnecting; // Called when ICE is connecting

  MediaStream? get localStream => _localStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  Map<String, RTCVideoRenderer> get remoteRenderers => _remoteRenderers;

  // ICE Server configuration with STUN and TURN servers
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      // Google STUN servers
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      // Metered TURN servers (more reliable)
      {
        'urls': 'turn:a.relay.metered.ca:80',
        'username': 'e8dd65f92cdd9f4cfe4ce383',
        'credential': 'Zp+SZP9BLy3rpBqT',
      },
      {
        'urls': 'turn:a.relay.metered.ca:80?transport=tcp',
        'username': 'e8dd65f92cdd9f4cfe4ce383',
        'credential': 'Zp+SZP9BLy3rpBqT',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443',
        'username': 'e8dd65f92cdd9f4cfe4ce383',
        'credential': 'Zp+SZP9BLy3rpBqT',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443?transport=tcp',
        'username': 'e8dd65f92cdd9f4cfe4ce383',
        'credential': 'Zp+SZP9BLy3rpBqT',
      },
      // OpenRelay TURN servers (backup)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'iceCandidatePoolSize': 10,
  };

  // Set the current user ID (needed for deterministic offer creation)
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    print('WebRTCService: Set current user ID to $userId');
  }

  // Reset the service for reuse (call before rejoining a room)
  void reset() {
    _isDisposed = false;
    _isAudioEnabled = true;
    _isVideoEnabled = true;
    _isSpeakerOn = true;
    _localStream = null;
    _localRenderer = null;
    _currentUserId = null;
    _peerConnections.clear();
    _remoteRenderers.clear();
    _pendingOfferReceivedFrom.clear();
    onRemoteStream = null;
    onRemoteStreamRemoved = null;
    onLocalOffer = null;
    onLocalAnswer = null;
    onIceCandidate = null;
    onConnectionFailed = null;
    onConnectionConnected = null;
    onConnectionConnecting = null;
    print('WebRTCService: Reset complete');
  }

  // Check if we already have a connection with this peer
  bool hasPeerConnection(String odiumId) {
    return _peerConnections.containsKey(odiumId);
  }

  // Check if we received an offer from this peer (to avoid glare)
  bool hasReceivedOfferFrom(String odiumId) {
    return _pendingOfferReceivedFrom.contains(odiumId);
  }

  // Initialize local media
  Future<bool> initializeMedia({bool video = true, bool audio = true}) async {
    // Reset disposed flag when initializing
    if (_isDisposed) {
      print('WebRTCService.initializeMedia: Service was disposed, resetting...');
      reset();
    }
    try {
      final constraints = <String, dynamic>{
        'audio': audio
            ? {
                'echoCancellation': true,
                'noiseSuppression': true,
                'autoGainControl': true,
              }
            : false,
        'video': video
            ? {
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
                'frameRate': {'ideal': 30},
                'facingMode': 'user',
              }
            : false,
      };

      print('WebRTCService.initializeMedia: Getting user media with constraints: $constraints');
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      print('WebRTCService.initializeMedia: Got local stream: $_localStream');

      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        final videoTracks = _localStream!.getVideoTracks();
        print('WebRTCService.initializeMedia: Audio tracks: ${audioTracks.length}, Video tracks: ${videoTracks.length}');
      }

      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
      _localRenderer!.srcObject = _localStream;

      _isAudioEnabled = audio;
      _isVideoEnabled = video;

      // Enable speaker phone by default for better audio experience
      await _enableSpeakerPhone(true);

      print('WebRTCService.initializeMedia: Success - isAudioEnabled=$_isAudioEnabled, isVideoEnabled=$_isVideoEnabled, speakerOn=$_isSpeakerOn');
      return true;
    } catch (e) {
      print('WebRTCService.initializeMedia: Error - $e');
      _isAudioEnabled = false;
      _isVideoEnabled = false;
      return false;
    }
  }

  // Enable/disable speaker phone
  Future<void> _enableSpeakerPhone(bool enable) async {
    try {
      await Helper.setSpeakerphoneOn(enable);
      _isSpeakerOn = enable;
      print('WebRTCService: Speaker phone ${enable ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('WebRTCService: Error setting speaker phone: $e');
    }
  }

  // Toggle speaker phone (works even when disposed - it's just audio routing)
  Future<bool> toggleSpeaker() async {
    print('WebRTCService.toggleSpeaker: Called, isDisposed=$_isDisposed, current isSpeakerOn=$_isSpeakerOn');
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
      print('WebRTCService.toggleSpeaker: Speaker is now ${_isSpeakerOn ? 'ON' : 'OFF'}');
      return true;
    } catch (e) {
      print('WebRTCService.toggleSpeaker: Error - $e');
      // Revert state on error
      _isSpeakerOn = !_isSpeakerOn;
      return false;
    }
  }

  // Set speaker state directly
  Future<bool> setSpeaker(bool enabled) async {
    print('WebRTCService.setSpeaker: Setting to $enabled');
    try {
      await Helper.setSpeakerphoneOn(enabled);
      _isSpeakerOn = enabled;
      print('WebRTCService.setSpeaker: Speaker is now ${_isSpeakerOn ? 'ON' : 'OFF'}');
      return true;
    } catch (e) {
      print('WebRTCService.setSpeaker: Error - $e');
      return false;
    }
  }

  // Create peer connection for a specific user
  Future<RTCPeerConnection?> _createNewPeerConnection(String odiumId) async {
    if (_isDisposed) return null;
    try {
      print('WebRTCService: Creating peer connection for $odiumId');
      final pc = await createPeerConnection(_configuration);
      _peerConnections[odiumId] = pc;

      // Add local stream tracks
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await pc.addTrack(track, _localStream!);
        }
      }

      // Handle remote stream
      pc.onTrack = (RTCTrackEvent event) async {
        if (_isDisposed) return;
        try {
          if (event.streams.isNotEmpty) {
            final stream = event.streams[0];

            if (!_remoteRenderers.containsKey(odiumId)) {
              final renderer = RTCVideoRenderer();
              await renderer.initialize();
              if (_isDisposed) {
                renderer.dispose();
                return;
              }
              renderer.srcObject = stream;
              _remoteRenderers[odiumId] = renderer;
            }

            onRemoteStream?.call(odiumId, stream);
          }
        } catch (e) {
          print('WebRTCService: Error handling remote track: $e');
        }
      };

      // Handle ICE candidates
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        if (_isDisposed) return;
        onIceCandidate?.call(odiumId, candidate);
      };

      pc.onIceConnectionState = (RTCIceConnectionState state) {
        if (_isDisposed) return;
        print('WebRTCService: ICE state for $odiumId: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          print('WebRTCService: Connection CONNECTED with $odiumId');
          onConnectionConnected?.call(odiumId);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
          print('WebRTCService: Connection CONNECTING with $odiumId');
          onConnectionConnecting?.call(odiumId);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          print('WebRTCService: Connection FAILED with $odiumId - will retry');
          // Remove the failed peer and notify for retry
          _pendingOfferReceivedFrom.remove(odiumId); // Allow new offers
          _removePeer(odiumId);
          onConnectionFailed?.call(odiumId);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          print('WebRTCService: Connection DISCONNECTED with $odiumId');
          // For disconnect, just remove the peer (they may have left)
          _removePeer(odiumId);
        }
      };

      print('WebRTCService: Peer connection created for $odiumId');
      return pc;
    } catch (e) {
      print('WebRTCService: Error creating peer connection: $e');
      return null;
    }
  }

  // Create and send offer
  Future<void> createOffer(String targetId) async {
    if (_isDisposed) return;

    // Skip if we already received an offer from this user (avoid glare - they initiated first)
    if (_pendingOfferReceivedFrom.contains(targetId)) {
      print('WebRTCService.createOffer: Skipping - already received offer from $targetId');
      return;
    }

    // Skip if we already have an active connection with this peer
    if (_peerConnections.containsKey(targetId)) {
      final existingPc = _peerConnections[targetId];
      if (existingPc != null) {
        final state = existingPc.connectionState;
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          print('WebRTCService.createOffer: Skipping - already connected/connecting to $targetId');
          return;
        }
        // If connection is in a bad state, clean it up first
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          print('WebRTCService.createOffer: Cleaning up failed connection to $targetId');
          await existingPc.close();
          _peerConnections.remove(targetId);
          _remoteRenderers[targetId]?.dispose();
          _remoteRenderers.remove(targetId);
        }
      }
    }

    try {
      print('WebRTCService.createOffer: Creating offer to $targetId (myId: $_currentUserId)');
      RTCPeerConnection? pc = await _createNewPeerConnection(targetId);

      if (pc == null) {
        print('WebRTCService.createOffer: Failed to create peer connection');
        return;
      }

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      onLocalOffer?.call(targetId, offer);
      print('WebRTCService.createOffer: Offer sent to $targetId');
    } catch (e) {
      print('WebRTCService.createOffer: Error - $e');
    }
  }

  // Handle received offer
  Future<void> handleOffer(String senderId, Map<String, dynamic> offerData) async {
    if (_isDisposed) return;
    try {
      // Track that we received an offer from this user (to avoid glare condition)
      _pendingOfferReceivedFrom.add(senderId);
      print('WebRTCService.handleOffer: Received offer from $senderId (myId: $_currentUserId)');

      RTCPeerConnection? pc;

      // Check if we have an existing connection
      if (_peerConnections.containsKey(senderId)) {
        final existingPc = _peerConnections[senderId]!;
        final state = existingPc.connectionState;

        // If existing connection is good, use it
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          print('WebRTCService.handleOffer: Already have active connection to $senderId, using existing');
          pc = existingPc;
        } else {
          // Clean up bad connection and create new one
          print('WebRTCService.handleOffer: Cleaning up old connection to $senderId (state: $state)');
          await existingPc.close();
          _peerConnections.remove(senderId);
          _remoteRenderers[senderId]?.dispose();
          _remoteRenderers.remove(senderId);
          pc = await _createNewPeerConnection(senderId);
        }
      } else {
        pc = await _createNewPeerConnection(senderId);
      }

      if (pc == null) {
        print('WebRTCService.handleOffer: Failed to create peer connection');
        return;
      }

      final offer = RTCSessionDescription(
        offerData['sdp'] as String,
        offerData['type'] as String,
      );

      await pc.setRemoteDescription(offer);

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      onLocalAnswer?.call(senderId, answer);
      print('WebRTCService.handleOffer: Answer sent to $senderId');
    } catch (e) {
      print('WebRTCService.handleOffer: Error - $e');
    }
  }

  // Handle received answer
  Future<void> handleAnswer(String senderId, Map<String, dynamic> answerData) async {
    if (_isDisposed) return;
    final pc = _peerConnections[senderId];
    if (pc == null) return;

    final answer = RTCSessionDescription(
      answerData['sdp'] as String,
      answerData['type'] as String,
    );

    await pc.setRemoteDescription(answer);
  }

  // Handle received ICE candidate
  Future<void> handleIceCandidate(String senderId, Map<String, dynamic> candidateData) async {
    if (_isDisposed) return;
    try {
      final pc = _peerConnections[senderId];
      if (pc == null) return;

      final candidateStr = candidateData['candidate'];
      if (candidateStr == null) return;

      final candidate = RTCIceCandidate(
        candidateStr as String,
        candidateData['sdpMid'] as String?,
        candidateData['sdpMLineIndex'] as int?,
      );

      await pc.addCandidate(candidate);
    } catch (e) {
      print('WebRTCService.handleIceCandidate: Error - $e');
    }
  }

  // Toggle audio - improved reliability
  Future<bool> toggleAudio() async {
    if (_isDisposed) return false;
    print('WebRTCService.toggleAudio: localStream=$_localStream, isAudioEnabled=$_isAudioEnabled');

    if (_localStream == null) {
      print('WebRTCService.toggleAudio: No local stream, cannot toggle');
      // Still toggle the state flag so UI updates
      _isAudioEnabled = !_isAudioEnabled;
      return false;
    }

    final audioTracks = _localStream!.getAudioTracks();
    print('WebRTCService.toggleAudio: Found ${audioTracks.length} audio tracks');

    if (audioTracks.isEmpty) {
      print('WebRTCService.toggleAudio: No audio tracks found');
      _isAudioEnabled = !_isAudioEnabled;
      return false;
    }

    // Calculate new state first
    final newEnabledState = !_isAudioEnabled;

    try {
      for (final track in audioTracks) {
        track.enabled = newEnabledState;
        print('WebRTCService.toggleAudio: Track ${track.id} set to enabled=$newEnabledState');
      }
      _isAudioEnabled = newEnabledState;
      print('WebRTCService.toggleAudio: Success - isAudioEnabled=$_isAudioEnabled');

      // Re-enable speaker after audio toggle to prevent routing issues
      if (_isSpeakerOn) {
        await Helper.setSpeakerphoneOn(true);
      }

      return true;
    } catch (e) {
      print('WebRTCService.toggleAudio: Error toggling track - $e');
      return false;
    }
  }

  // Set audio enabled state directly (more reliable than toggle)
  Future<bool> setAudioEnabled(bool enabled) async {
    if (_isDisposed) return false;
    print('WebRTCService.setAudioEnabled: Setting to $enabled');

    if (_localStream == null) {
      print('WebRTCService.setAudioEnabled: No local stream');
      _isAudioEnabled = enabled;
      return false;
    }

    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isEmpty) {
      print('WebRTCService.setAudioEnabled: No audio tracks');
      _isAudioEnabled = enabled;
      return false;
    }

    try {
      for (final track in audioTracks) {
        track.enabled = enabled;
        print('WebRTCService.setAudioEnabled: Track ${track.id} set to enabled=$enabled');
      }
      _isAudioEnabled = enabled;

      // Ensure speaker is set correctly after changing audio state
      if (_isSpeakerOn) {
        await Helper.setSpeakerphoneOn(true);
      }

      return true;
    } catch (e) {
      print('WebRTCService.setAudioEnabled: Error - $e');
      return false;
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    if (_isDisposed) return;
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = !track.enabled;
      _isVideoEnabled = track.enabled;
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_isDisposed) return;
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks[0]);
    }
  }

  // Get remote renderer
  RTCVideoRenderer? getRemoteRenderer(String odiumId) {
    return _remoteRenderers[odiumId];
  }

  // Remove peer connection
  void _removePeer(String odiumId) {
    if (_isDisposed) return;
    try {
      _peerConnections[odiumId]?.close();
      _peerConnections.remove(odiumId);

      _remoteRenderers[odiumId]?.dispose();
      _remoteRenderers.remove(odiumId);

      onRemoteStreamRemoved?.call(odiumId);
    } catch (e) {
      print('WebRTCService._removePeer: Error - $e');
    }
  }

  // Remove specific peer
  void removePeer(String odiumId) {
    if (_isDisposed) return;
    _removePeer(odiumId);
  }

  // Dispose all resources
  Future<void> dispose() async {
    _isDisposed = true;

    // Clear callbacks to prevent calling disposed widgets
    onRemoteStream = null;
    onRemoteStreamRemoved = null;
    onLocalOffer = null;
    onLocalAnswer = null;
    onIceCandidate = null;
    onConnectionFailed = null;
    onConnectionConnected = null;
    onConnectionConnecting = null;

    // Close all peer connections
    try {
      for (final pc in _peerConnections.values) {
        await pc.close();
      }
      _peerConnections.clear();
    } catch (e) {
      print('WebRTCService.dispose: Error closing peer connections: $e');
    }

    // Dispose all remote renderers
    try {
      for (final renderer in _remoteRenderers.values) {
        await renderer.dispose();
      }
      _remoteRenderers.clear();
    } catch (e) {
      print('WebRTCService.dispose: Error disposing renderers: $e');
    }

    // Stop local stream
    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }
    } catch (e) {
      print('WebRTCService.dispose: Error disposing local stream: $e');
    }

    // Dispose local renderer
    try {
      await _localRenderer?.dispose();
      _localRenderer = null;
    } catch (e) {
      print('WebRTCService.dispose: Error disposing local renderer: $e');
    }
  }
}
