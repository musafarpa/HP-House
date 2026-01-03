import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/room_model.dart';
import '../models/participant_model.dart';
import '../services/database_service.dart';
import '../services/supabase_signaling_service.dart';
import '../services/webrtc_service.dart';
import '../config/supabase_config.dart';

class RoomProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SupabaseSignalingService _signaling = SupabaseSignalingService();
  final WebRTCService _webrtc = WebRTCService();

  List<RoomModel> _allRooms = [];
  RoomModel? _currentRoom;
  List<ParticipantModel> _participants = [];
  bool _isLoading = false;
  String? _error;
  bool _isMuted = true;
  bool _hasRaisedHand = false;
  bool _isDisposed = false;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _participantsSubscription;
  Timer? _participantsRefreshTimer;

  List<RoomModel> get allRooms => _allRooms;
  List<RoomModel> get liveRooms => _allRooms.where((r) => r.isLive).toList();
  RoomModel? get currentRoom => _currentRoom;
  List<ParticipantModel> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMuted => _isMuted;
  bool get hasRaisedHand => _hasRaisedHand;
  bool get isSpeakerOn => _webrtc.isSpeakerOn;

  List<ParticipantModel> get speakers =>
      _participants.where((p) => p.isSpeaker).toList();
  List<ParticipantModel> get listeners =>
      _participants.where((p) => p.isListener).toList();

  String? get currentUserId => SupabaseConfig.currentUserId;

  // Safe notify that checks if disposed
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Request microphone permission for audio calls
  Future<bool> _requestAudioPermissions() async {
    try {
      debugPrint('RoomProvider: Requesting audio permissions');

      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('RoomProvider: Microphone permission status: $micStatus');

      if (micStatus.isGranted) {
        return true;
      } else if (micStatus.isPermanentlyDenied) {
        debugPrint('RoomProvider: Microphone permission permanently denied');
        // User needs to manually enable in settings
        return false;
      } else {
        debugPrint('RoomProvider: Microphone permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('RoomProvider: Error requesting permissions: $e');
      return false;
    }
  }

  // Stream for real-time participant updates
  Stream<List<Map<String, dynamic>>>? getParticipantsStream(String roomId) {
    return _db.watchRoomParticipants(roomId);
  }

  // Load all rooms and subscribe to realtime updates
  Future<void> loadLiveRooms() async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      _allRooms = await _db.getAllRooms();

      // Subscribe to realtime room updates
      _subscribeToRooms();

      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _error = 'Failed to load rooms';
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Subscribe to realtime room changes
  void _subscribeToRooms() {
    _roomsSubscription?.cancel();
    _roomsSubscription = SupabaseConfig.client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .listen((data) async {
      if (_isDisposed) return;
      // Reload rooms when changes occur
      try {
        _allRooms = await _db.getAllRooms();
        _safeNotifyListeners();
      } catch (e) {
        debugPrint('Error refreshing rooms: $e');
      }
    });
  }

  // Create room
  Future<RoomModel?> createRoom({
    required String title,
    String? description,
    RoomType type = RoomType.audio,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      final userId = currentUserId;
      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        _safeNotifyListeners();
        return null;
      }

      final room = await _db.createRoom(
        title: title,
        description: description,
        hostId: userId,
        type: type,
      );

      _currentRoom = room;

      // Add to all rooms list immediately
      _allRooms.insert(0, room);

      _isLoading = false;
      _safeNotifyListeners();

      return room;
    } catch (e) {
      _error = 'Failed to create room';
      _isLoading = false;
      _safeNotifyListeners();
      return null;
    }
  }

  // Join room
  Future<bool> joinRoom(String roomId) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      final userId = currentUserId;
      debugPrint('RoomProvider.joinRoom: userId = $userId');
      if (userId == null) {
        _error = 'User not authenticated';
        debugPrint('RoomProvider.joinRoom: User not authenticated');
        _isLoading = false;
        _safeNotifyListeners();
        return false;
      }

      // Get room details
      debugPrint('RoomProvider.joinRoom: Getting room details for $roomId');
      _currentRoom = await _db.getRoom(roomId);
      if (_currentRoom == null) {
        _error = 'Room not found';
        debugPrint('RoomProvider.joinRoom: Room not found');
        _isLoading = false;
        _safeNotifyListeners();
        return false;
      }
      debugPrint('RoomProvider.joinRoom: Room found - ${_currentRoom!.title}, hostId = ${_currentRoom!.hostId}');

      // Join room in database - host joins as host, others as listener
      final isHost = _currentRoom!.hostId == userId;
      debugPrint('RoomProvider.joinRoom: isHost = $isHost, joining with role ${isHost ? 'host' : 'listener'}');

      try {
        await _db.joinRoom(roomId, userId, role: isHost ? 'host' : 'listener');
        debugPrint('RoomProvider.joinRoom: Successfully joined room in database');
        // Give database time to propagate the insert
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('RoomProvider.joinRoom: Error joining room in database: $e');
        // Continue anyway to try to load participants
      }

      // Request audio permissions before initializing WebRTC
      final hasPermission = await _requestAudioPermissions();
      debugPrint('RoomProvider.joinRoom: Audio permission granted=$hasPermission');

      // Reset services before initializing (in case they were previously disposed)
      _webrtc.reset();
      _signaling.reset();
      debugPrint('RoomProvider.joinRoom: Services reset');

      // Initialize WebRTC for audio only - wrap in try-catch
      bool webrtcInitialized = false;
      if (hasPermission) {
        try {
          webrtcInitialized = await _webrtc.initializeMedia(video: false, audio: true);
          debugPrint('RoomProvider.joinRoom: WebRTC initialized=$webrtcInitialized');

          // Start muted by default - use setAudioEnabled for reliability
          if (webrtcInitialized) {
            await _webrtc.setAudioEnabled(false);
            debugPrint('RoomProvider.joinRoom: Audio muted, speaker=${_webrtc.isSpeakerOn}');
          }
        } catch (e) {
          debugPrint('RoomProvider.joinRoom: WebRTC init error: $e');
          // Continue without WebRTC - room will work but no voice
        }
      } else {
        debugPrint('RoomProvider.joinRoom: Skipping WebRTC init - no permission');
      }
      _isMuted = true;

      // Connect to signaling server - wrap in try-catch
      try {
        await _signaling.connect(userId, '');
        _signaling.joinRoom(roomId, {
          'userId': userId,
        });
      } catch (e) {
        debugPrint('RoomProvider.joinRoom: Signaling error: $e');
        // Continue without signaling
      }

      // Set up signaling callbacks
      _setupSignalingCallbacks();

      // Set up WebRTC callbacks
      _setupWebRTCCallbacks();

      // Load initial participants with retry
      debugPrint('RoomProvider.joinRoom: Loading initial participants');
      await _loadParticipants(roomId);

      // If no participants loaded, retry a few times
      int retries = 0;
      while (_participants.isEmpty && retries < 3) {
        retries++;
        debugPrint('RoomProvider.joinRoom: No participants found, retry $retries');
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadParticipants(roomId);
      }

      debugPrint('RoomProvider.joinRoom: Final participant count: ${_participants.length}');

      // Create offers to all existing participants (except self)
      // Only if WebRTC was initialized successfully
      if (webrtcInitialized) {
        try {
          for (final participant in _participants) {
            if (participant.odiumId != userId) {
              debugPrint('RoomProvider.joinRoom: Creating offer to existing participant: ${participant.odiumId}');
              await _webrtc.createOffer(participant.odiumId);
            }
          }
        } catch (e) {
          debugPrint('RoomProvider.joinRoom: Error creating offers: $e');
          // Continue anyway - voice may not work but app won't crash
        }
      } else {
        debugPrint('RoomProvider.joinRoom: Skipping offers - WebRTC not initialized');
      }

      // Cancel any existing subscription and watch for participant changes
      _participantsSubscription?.cancel();
      _participantsSubscription = _db.watchRoomParticipants(roomId).listen((data) async {
        if (_isDisposed) return;
        // Small delay to ensure database is updated before fetching
        await Future.delayed(const Duration(milliseconds: 200));
        if (_isDisposed) return;
        await _loadParticipants(roomId);
      });

      // Also start a periodic refresh as fallback (every 2 seconds)
      _participantsRefreshTimer?.cancel();
      _participantsRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (_isDisposed) return;
        if (_currentRoom != null) {
          await _loadParticipants(roomId);
        }
      });

      // _isMuted is already set after WebRTC init
      _hasRaisedHand = false;
      _isLoading = false;
      _safeNotifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to join room';
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  // Leave room (does NOT end the room - host can rejoin)
  Future<void> leaveRoom({bool endRoom = false}) async {
    try {
      final roomId = _currentRoom?.id;
      final userId = currentUserId;
      final isHost = _currentRoom?.hostId == userId;

      if (roomId != null && userId != null) {
        await _db.leaveRoom(roomId, userId);
        _signaling.leaveRoom(roomId);

        // Only end room if explicitly requested by host
        if (isHost && endRoom) {
          await _db.endRoom(roomId);
          // Remove from all rooms list
          _allRooms.removeWhere((r) => r.id == roomId);
        }
      }

      // Cancel participants subscription and timer
      _participantsSubscription?.cancel();
      _participantsSubscription = null;
      _participantsRefreshTimer?.cancel();
      _participantsRefreshTimer = null;

      // Cleanup WebRTC
      await _webrtc.dispose();

      _signaling.disconnect();
      _currentRoom = null;
      _participants = [];
      _isMuted = true;
      _hasRaisedHand = false;
      _safeNotifyListeners();

      // Refresh live rooms
      loadLiveRooms();
    } catch (e) {
      _error = 'Failed to leave room';
      _safeNotifyListeners();
    }
  }

  // End room (only host can do this)
  Future<void> endCurrentRoom() async {
    final isHost = _currentRoom?.hostId == currentUserId;
    if (isHost) {
      await leaveRoom(endRoom: true);
    } else {
      await leaveRoom();
    }
  }

  // Delete room (only for host/creator)
  Future<bool> deleteRoom(String roomId) async {
    try {
      final userId = currentUserId;
      final room = _allRooms.firstWhere((r) => r.id == roomId, orElse: () => throw Exception('Room not found'));

      // Only the host can delete the room
      if (room.hostId != userId) {
        _error = 'Only the host can delete the room';
        _safeNotifyListeners();
        return false;
      }

      await _db.deleteRoom(roomId);
      _allRooms.removeWhere((r) => r.id == roomId);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete room';
      _safeNotifyListeners();
      return false;
    }
  }

  // Toggle room online/offline status (only for host/creator)
  Future<bool> toggleRoomStatus(String roomId) async {
    try {
      final userId = currentUserId;
      final roomIndex = _allRooms.indexWhere((r) => r.id == roomId);

      if (roomIndex == -1) {
        _error = 'Room not found';
        _safeNotifyListeners();
        return false;
      }

      final room = _allRooms[roomIndex];

      // Only the host can toggle room status
      if (room.hostId != userId) {
        _error = 'Only the host can change room status';
        _safeNotifyListeners();
        return false;
      }

      final newStatus = !room.isLive;
      await _db.toggleRoomStatus(roomId, newStatus);

      // Update local room
      _allRooms[roomIndex] = room.copyWith(isLive: newStatus);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle room status';
      _safeNotifyListeners();
      return false;
    }
  }

  // Toggle mute - improved reliability
  Future<void> toggleMute() async {
    if (_isDisposed) return;
    debugPrint('RoomProvider.toggleMute: Current isMuted=$_isMuted, webrtc.isAudioEnabled=${_webrtc.isAudioEnabled}');

    // Calculate the new desired state
    final newMutedState = !_isMuted;

    // Set the audio state directly (more reliable than toggle)
    final success = await _webrtc.setAudioEnabled(!newMutedState);
    debugPrint('RoomProvider.toggleMute: WebRTC setAudioEnabled success=$success');

    // Update mute state
    _isMuted = newMutedState;

    debugPrint('RoomProvider.toggleMute: After toggle isMuted=$_isMuted, webrtc.isAudioEnabled=${_webrtc.isAudioEnabled}');
    _safeNotifyListeners();

    final roomId = _currentRoom?.id;
    final userId = currentUserId;

    if (roomId != null && userId != null) {
      try {
        await _db.updateParticipant(roomId, userId, {'is_muted': _isMuted});
        _signaling.toggleAudio(roomId, _isMuted);
        debugPrint('RoomProvider.toggleMute: Updated participant in database');
      } catch (e) {
        debugPrint('RoomProvider.toggleMute: Error updating participant: $e');
      }
    }
  }

  // Toggle speaker phone
  Future<void> toggleSpeaker() async {
    debugPrint('RoomProvider.toggleSpeaker: Called, isDisposed=$_isDisposed, current isSpeakerOn=${_webrtc.isSpeakerOn}');

    final success = await _webrtc.toggleSpeaker();
    debugPrint('RoomProvider.toggleSpeaker: Toggle success=$success, now isSpeakerOn=${_webrtc.isSpeakerOn}');

    _safeNotifyListeners();
  }

  // Raise hand
  Future<void> raiseHand() async {
    if (_isDisposed) return;
    _hasRaisedHand = !_hasRaisedHand;
    _safeNotifyListeners();

    final roomId = _currentRoom?.id;
    if (roomId != null) {
      _signaling.raiseHand(roomId);
    }
  }

  // Promote to speaker (host only)
  Future<void> promoteToSpeaker(String odiumId) async {
    final roomId = _currentRoom?.id;
    if (roomId == null) return;

    await _db.updateParticipant(roomId, odiumId, {'role': 'speaker'});
  }

  // Demote to listener (host only)
  Future<void> demoteToListener(String odiumId) async {
    final roomId = _currentRoom?.id;
    if (roomId == null) return;

    await _db.updateParticipant(roomId, odiumId, {'role': 'listener'});
  }

  void _setupSignalingCallbacks() {
    _signaling.onUserJoined = (data) {
      if (_isDisposed) return;
      // Handle user joined - create offer to new user
      final odiumId = data['userId'] as String?;
      debugPrint('RoomProvider: User joined: $odiumId');
      if (odiumId != null && odiumId != currentUserId) {
        debugPrint('RoomProvider: Creating offer for $odiumId');
        _webrtc.createOffer(odiumId);
      }
      // Reload participants
      if (_currentRoom != null) {
        _loadParticipants(_currentRoom!.id);
      }
      _safeNotifyListeners();
    };

    _signaling.onUserLeft = (data) {
      if (_isDisposed) return;
      // Handle user left - remove peer connection
      final odiumId = data['userId'] as String?;
      debugPrint('RoomProvider: User left: $odiumId');
      if (odiumId != null) {
        _webrtc.removePeer(odiumId);
      }
      // Reload participants
      if (_currentRoom != null) {
        _loadParticipants(_currentRoom!.id);
      }
      _safeNotifyListeners();
    };

    _signaling.onOffer = (data) {
      if (_isDisposed) return;
      // Handle received offer
      final senderId = data['senderId'] as String?;
      final offer = data['offer'] as Map<String, dynamic>?;
      if (senderId != null && offer != null) {
        _webrtc.handleOffer(senderId, offer);
      }
    };

    _signaling.onAnswer = (data) {
      if (_isDisposed) return;
      // Handle received answer
      final senderId = data['senderId'] as String?;
      final answer = data['answer'] as Map<String, dynamic>?;
      if (senderId != null && answer != null) {
        _webrtc.handleAnswer(senderId, answer);
      }
    };

    _signaling.onIceCandidate = (data) {
      if (_isDisposed) return;
      // Handle received ICE candidate
      final senderId = data['senderId'] as String?;
      final candidate = data['candidate'] as Map<String, dynamic>?;
      if (senderId != null && candidate != null) {
        _webrtc.handleIceCandidate(senderId, candidate);
      }
    };

    _signaling.onUserToggledAudio = (data) {
      if (_isDisposed) return;
      // Handle audio toggle
      _safeNotifyListeners();
    };

    _signaling.onHandRaised = (data) {
      if (_isDisposed) return;
      // Handle hand raised
      _safeNotifyListeners();
    };

  }

  void _setupWebRTCCallbacks() {
    _webrtc.onLocalOffer = (targetId, sdp) {
      if (_isDisposed) return;
      _signaling.sendOffer(targetId, {
        'sdp': sdp.sdp,
        'type': sdp.type,
      });
    };

    _webrtc.onLocalAnswer = (targetId, sdp) {
      if (_isDisposed) return;
      _signaling.sendAnswer(targetId, {
        'sdp': sdp.sdp,
        'type': sdp.type,
      });
    };

    _webrtc.onIceCandidate = (targetId, candidate) {
      if (_isDisposed) return;
      _signaling.sendIceCandidate(targetId, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _webrtc.onRemoteStream = (odiumId, stream) {
      if (_isDisposed) return;
      debugPrint('Remote stream received from $odiumId');
      _safeNotifyListeners();
    };

    _webrtc.onRemoteStreamRemoved = (odiumId) {
      if (_isDisposed) return;
      debugPrint('Remote stream removed from $odiumId');
      _safeNotifyListeners();
    };
  }

  // Load participants with user details
  Future<void> _loadParticipants(String roomId) async {
    if (_isDisposed) return;
    try {
      debugPrint('Loading participants for room: $roomId');
      final data = await _db.getRoomParticipants(roomId);
      if (_isDisposed) return;
      debugPrint('Got ${data.length} participants from database');
      for (var p in data) {
        debugPrint('Participant data: $p');
      }

      final newParticipants = data.map((e) {
        try {
          return ParticipantModel.fromJson(e);
        } catch (parseError) {
          debugPrint('Error parsing participant: $parseError, data: $e');
          rethrow;
        }
      }).toList();

      // Only update if we actually got participants or if we had none before
      if (newParticipants.isNotEmpty || _participants.isEmpty) {
        _participants = newParticipants;
        debugPrint('Parsed ${_participants.length} participants');
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  // Public method to force reload participants (for debugging/retry)
  Future<void> forceReloadParticipants() async {
    if (_currentRoom != null) {
      debugPrint('Force reloading participants for room: ${_currentRoom!.id}');
      await _loadParticipants(_currentRoom!.id);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel all subscriptions and timers first
    _roomsSubscription?.cancel();
    _roomsSubscription = null;
    _participantsSubscription?.cancel();
    _participantsSubscription = null;
    _participantsRefreshTimer?.cancel();
    _participantsRefreshTimer = null;

    // Clear all callbacks to prevent post-dispose calls
    _signaling.onUserJoined = null;
    _signaling.onUserLeft = null;
    _signaling.onOffer = null;
    _signaling.onAnswer = null;
    _signaling.onIceCandidate = null;
    _signaling.onUserToggledAudio = null;
    _signaling.onHandRaised = null;

    _webrtc.onLocalOffer = null;
    _webrtc.onLocalAnswer = null;
    _webrtc.onIceCandidate = null;
    _webrtc.onRemoteStream = null;
    _webrtc.onRemoteStreamRemoved = null;

    // Disconnect signaling
    _signaling.disconnect();

    // Dispose WebRTC - don't await in dispose
    _webrtc.dispose();

    super.dispose();
  }
}
