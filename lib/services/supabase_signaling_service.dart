import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

typedef SignalingCallback = void Function(Map<String, dynamic> data);

class SupabaseSignalingService {
  RealtimeChannel? _channel;
  String? _currentRoomId;
  String? _currentUserId;
  bool _isConnected = false;
  bool _isDisposed = false;

  // Callbacks
  SignalingCallback? onUserJoined;
  SignalingCallback? onUserLeft;
  SignalingCallback? onOffer;
  SignalingCallback? onAnswer;
  SignalingCallback? onIceCandidate;
  SignalingCallback? onUserToggledAudio;
  SignalingCallback? onUserToggledVideo;
  SignalingCallback? onHandRaised;

  bool get isConnected => _isConnected;

  // Reset the service for reuse (call before rejoining a room)
  void reset() {
    _isDisposed = false;
    _isConnected = false;
    _channel = null;
    _currentRoomId = null;
    _currentUserId = null;
    onUserJoined = null;
    onUserLeft = null;
    onOffer = null;
    onAnswer = null;
    onIceCandidate = null;
    onUserToggledAudio = null;
    onUserToggledVideo = null;
    onHandRaised = null;
    print('SupabaseSignaling: Reset complete');
  }

  // Connect to room channel
  Future<void> connect(String userId, String token) async {
    // Reset if previously disposed
    if (_isDisposed) {
      print('SupabaseSignaling: Service was disposed, resetting...');
      reset();
    }
    _currentUserId = userId;
    print('SupabaseSignaling: Initialized with userId: $userId');
  }

  // Join room - subscribe to room channel
  void joinRoom(String roomId, Map<String, dynamic> userInfo) {
    try {
      _currentRoomId = roomId;

      // Unsubscribe from previous channel if any
      _channel?.unsubscribe();

      // Create a new channel for this room
      _channel = SupabaseConfig.client.channel(
        'room:$roomId',
        opts: const RealtimeChannelConfig(self: true),
      );
    } catch (e) {
      print('SupabaseSignaling: Error creating channel: $e');
      return;
    }

    if (_channel == null) {
      print('SupabaseSignaling: Channel is null, cannot join room');
      return;
    }

    // Listen for broadcasts
    _channel!
      .onBroadcast(
        event: 'user-joined',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: user-joined: $payload');
            if (payload['userId'] != _currentUserId) {
              onUserJoined?.call(Map<String, dynamic>.from(payload));
            }
          } catch (e) {
            print('SupabaseSignaling: Error in user-joined callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'user-left',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: user-left: $payload');
            onUserLeft?.call(Map<String, dynamic>.from(payload));
          } catch (e) {
            print('SupabaseSignaling: Error in user-left callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'offer',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: offer received: $payload');
            // Only process if this offer is for us
            if (payload['targetId'] == _currentUserId) {
              onOffer?.call(Map<String, dynamic>.from(payload));
            }
          } catch (e) {
            print('SupabaseSignaling: Error in offer callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'answer',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: answer received: $payload');
            // Only process if this answer is for us
            if (payload['targetId'] == _currentUserId) {
              onAnswer?.call(Map<String, dynamic>.from(payload));
            }
          } catch (e) {
            print('SupabaseSignaling: Error in answer callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'ice-candidate',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: ice-candidate received: $payload');
            // Only process if this candidate is for us
            if (payload['targetId'] == _currentUserId) {
              onIceCandidate?.call(Map<String, dynamic>.from(payload));
            }
          } catch (e) {
            print('SupabaseSignaling: Error in ice-candidate callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'toggle-audio',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: toggle-audio: $payload');
            onUserToggledAudio?.call(Map<String, dynamic>.from(payload));
          } catch (e) {
            print('SupabaseSignaling: Error in toggle-audio callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'toggle-video',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: toggle-video: $payload');
            onUserToggledVideo?.call(Map<String, dynamic>.from(payload));
          } catch (e) {
            print('SupabaseSignaling: Error in toggle-video callback: $e');
          }
        },
      )
      .onBroadcast(
        event: 'raise-hand',
        callback: (payload) {
          if (_isDisposed) return;
          try {
            print('SupabaseSignaling: raise-hand: $payload');
            onHandRaised?.call(Map<String, dynamic>.from(payload));
          } catch (e) {
            print('SupabaseSignaling: Error in raise-hand callback: $e');
          }
        },
      )
      .subscribe((status, error) {
        if (_isDisposed) return;
        print('SupabaseSignaling: Channel status: $status, error: $error');
        if (status == RealtimeSubscribeStatus.subscribed) {
          _isConnected = true;
          // Broadcast that we joined
          _broadcast('user-joined', {
            'userId': _currentUserId,
            'roomId': roomId,
            ...userInfo,
          });
        }
      });
  }

  // Broadcast a message to the room
  void _broadcast(String event, Map<String, dynamic> payload) {
    if (_channel == null) {
      print('SupabaseSignaling: Cannot broadcast, channel is null');
      return;
    }

    _channel!.sendBroadcastMessage(
      event: event,
      payload: payload,
    );
    print('SupabaseSignaling: Broadcast $event: $payload');
  }

  // Leave room
  void leaveRoom(String roomId) {
    _broadcast('user-left', {
      'userId': _currentUserId,
      'roomId': roomId,
    });
    _channel?.unsubscribe();
    _channel = null;
    _currentRoomId = null;
    _isConnected = false;
  }

  // Send WebRTC offer
  void sendOffer(String targetId, Map<String, dynamic> offer) {
    _broadcast('offer', {
      'senderId': _currentUserId,
      'targetId': targetId,
      'offer': offer,
    });
  }

  // Send WebRTC answer
  void sendAnswer(String targetId, Map<String, dynamic> answer) {
    _broadcast('answer', {
      'senderId': _currentUserId,
      'targetId': targetId,
      'answer': answer,
    });
  }

  // Send ICE candidate
  void sendIceCandidate(String targetId, Map<String, dynamic> candidate) {
    _broadcast('ice-candidate', {
      'senderId': _currentUserId,
      'targetId': targetId,
      'candidate': candidate,
    });
  }

  // Toggle audio
  void toggleAudio(String roomId, bool isMuted) {
    _broadcast('toggle-audio', {
      'userId': _currentUserId,
      'roomId': roomId,
      'isMuted': isMuted,
    });
  }

  // Toggle video
  void toggleVideo(String roomId, bool isEnabled) {
    _broadcast('toggle-video', {
      'userId': _currentUserId,
      'roomId': roomId,
      'isEnabled': isEnabled,
    });
  }

  // Raise hand
  void raiseHand(String roomId) {
    _broadcast('raise-hand', {
      'userId': _currentUserId,
      'roomId': roomId,
    });
  }

  // Disconnect
  void disconnect() {
    _isDisposed = true;

    // Clear all callbacks
    onUserJoined = null;
    onUserLeft = null;
    onOffer = null;
    onAnswer = null;
    onIceCandidate = null;
    onUserToggledAudio = null;
    onUserToggledVideo = null;
    onHandRaised = null;

    try {
      _channel?.unsubscribe();
    } catch (e) {
      print('SupabaseSignaling: Error unsubscribing: $e');
    }
    _channel = null;
    _currentRoomId = null;
    _isConnected = false;
  }
}
