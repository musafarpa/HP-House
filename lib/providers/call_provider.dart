import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../services/signaling_service.dart';
import '../config/supabase_config.dart';

enum CallState { idle, connecting, connected, disconnected }

class CallProvider with ChangeNotifier {
  final WebRTCService _webrtc = WebRTCService();
  final SignalingService _signaling = SignalingService();

  CallState _state = CallState.idle;
  String? _currentRoomId;
  bool _isAudioEnabled = true;
  bool _isVideoEnabled = true;
  String? _error;

  CallState get state => _state;
  String? get currentRoomId => _currentRoomId;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isVideoEnabled => _isVideoEnabled;
  String? get error => _error;

  RTCVideoRenderer? get localRenderer => _webrtc.localRenderer;
  Map<String, RTCVideoRenderer> get remoteRenderers => _webrtc.remoteRenderers;

  String? get currentUserId => SupabaseConfig.currentUserId;

  // Initialize video call
  Future<bool> initializeCall({
    required String roomId,
    bool video = true,
    bool audio = true,
  }) async {
    try {
      _state = CallState.connecting;
      _currentRoomId = roomId;
      _error = null;
      notifyListeners();

      // Initialize media
      await _webrtc.initializeMedia(video: video, audio: audio);
      _isAudioEnabled = audio;
      _isVideoEnabled = video;

      // Connect to signaling server
      final userId = currentUserId;
      if (userId == null) {
        _error = 'User not authenticated';
        _state = CallState.idle;
        notifyListeners();
        return false;
      }

      await _signaling.connect(userId, '');

      // Set up signaling callbacks
      _setupSignalingCallbacks();

      // Set up WebRTC callbacks
      _setupWebRTCCallbacks();

      // Join room
      _signaling.joinRoom(roomId, {
        'userId': userId,
        'hasVideo': video,
        'hasAudio': audio,
      });

      _state = CallState.connected;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to initialize call: $e';
      _state = CallState.idle;
      notifyListeners();
      return false;
    }
  }

  void _setupSignalingCallbacks() {
    _signaling.onUserJoined = (data) {
      final odiumId = data['userId'] as String?;
      if (odiumId != null && odiumId != currentUserId) {
        // Create offer for new user
        _webrtc.createOffer(odiumId);
      }
    };

    _signaling.onUserLeft = (data) {
      final odiumId = data['userId'] as String?;
      if (odiumId != null) {
        _webrtc.removePeer(odiumId);
        notifyListeners();
      }
    };

    _signaling.onOffer = (data) async {
      final senderId = data['senderId'] as String?;
      final offer = data['offer'] as Map<String, dynamic>?;
      if (senderId != null && offer != null) {
        await _webrtc.handleOffer(senderId, offer);
      }
    };

    _signaling.onAnswer = (data) async {
      final senderId = data['senderId'] as String?;
      final answer = data['answer'] as Map<String, dynamic>?;
      if (senderId != null && answer != null) {
        await _webrtc.handleAnswer(senderId, answer);
      }
    };

    _signaling.onIceCandidate = (data) async {
      final senderId = data['senderId'] as String?;
      final candidate = data['candidate'] as Map<String, dynamic>?;
      if (senderId != null && candidate != null) {
        await _webrtc.handleIceCandidate(senderId, candidate);
      }
    };

    _signaling.onUserToggledVideo = (data) {
      notifyListeners();
    };

    _signaling.onUserToggledAudio = (data) {
      notifyListeners();
    };
  }

  void _setupWebRTCCallbacks() {
    _webrtc.onLocalOffer = (targetId, sdp) {
      _signaling.sendOffer(targetId, {
        'sdp': sdp.sdp,
        'type': sdp.type,
      });
    };

    _webrtc.onLocalAnswer = (targetId, sdp) {
      _signaling.sendAnswer(targetId, {
        'sdp': sdp.sdp,
        'type': sdp.type,
      });
    };

    _webrtc.onIceCandidate = (targetId, candidate) {
      _signaling.sendIceCandidate(targetId, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _webrtc.onRemoteStream = (odiumId, stream) {
      notifyListeners();
    };

    _webrtc.onRemoteStreamRemoved = (odiumId) {
      notifyListeners();
    };
  }

  // Toggle audio
  Future<void> toggleAudio() async {
    await _webrtc.toggleAudio();
    _isAudioEnabled = _webrtc.isAudioEnabled;
    notifyListeners();

    if (_currentRoomId != null) {
      _signaling.toggleAudio(_currentRoomId!, !_isAudioEnabled);
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    await _webrtc.toggleVideo();
    _isVideoEnabled = _webrtc.isVideoEnabled;
    notifyListeners();

    if (_currentRoomId != null) {
      _signaling.toggleVideo(_currentRoomId!, _isVideoEnabled);
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    await _webrtc.switchCamera();
  }

  // End call
  Future<void> endCall() async {
    if (_currentRoomId != null) {
      _signaling.leaveRoom(_currentRoomId!);
    }

    _signaling.disconnect();
    await _webrtc.dispose();

    _state = CallState.disconnected;
    _currentRoomId = null;
    notifyListeners();

    // Reset state after a delay
    await Future.delayed(const Duration(milliseconds: 500));
    _state = CallState.idle;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    endCall();
    super.dispose();
  }
}
