import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;

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
      // OpenRelay TURN servers (free, for testing)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ]
  };

  // Reset the service for reuse (call before rejoining a room)
  void reset() {
    _isDisposed = false;
    _isAudioEnabled = true;
    _isVideoEnabled = true;
    _isSpeakerOn = true;
    _localStream = null;
    _localRenderer = null;
    _peerConnections.clear();
    _remoteRenderers.clear();
    onRemoteStream = null;
    onRemoteStreamRemoved = null;
    onLocalOffer = null;
    onLocalAnswer = null;
    onIceCandidate = null;
    print('WebRTCService: Reset complete');
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
        if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
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
    try {
      RTCPeerConnection? pc;

      if (_peerConnections.containsKey(targetId)) {
        pc = _peerConnections[targetId];
      } else {
        pc = await _createNewPeerConnection(targetId);
      }

      if (pc == null) {
        print('WebRTCService.createOffer: Failed to create peer connection');
        return;
      }

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      onLocalOffer?.call(targetId, offer);
    } catch (e) {
      print('WebRTCService.createOffer: Error - $e');
    }
  }

  // Handle received offer
  Future<void> handleOffer(String senderId, Map<String, dynamic> offerData) async {
    if (_isDisposed) return;
    try {
      RTCPeerConnection? pc;

      if (_peerConnections.containsKey(senderId)) {
        pc = _peerConnections[senderId];
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
