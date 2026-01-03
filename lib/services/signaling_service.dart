import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/constants.dart';

typedef SignalingCallback = void Function(Map<String, dynamic> data);

class SignalingService {
  io.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  SignalingCallback? onUserJoined;
  SignalingCallback? onUserLeft;
  SignalingCallback? onOffer;
  SignalingCallback? onAnswer;
  SignalingCallback? onIceCandidate;
  SignalingCallback? onUserToggledAudio;
  SignalingCallback? onUserToggledVideo;
  SignalingCallback? onHandRaised;
  SignalingCallback? onNewMessage;
  SignalingCallback? onRoomUpdated;

  bool get isConnected => _isConnected;

  // Connect to signaling server
  Future<void> connect(String odiumId, String token) async {
    _socket = io.io(
      AppConstants.signalingServerUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': odiumId, 'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('Connected to signaling server');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('Disconnected from signaling server');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });

    // Set up event listeners
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _socket?.on('user-joined', (data) {
      onUserJoined?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('user-left', (data) {
      onUserLeft?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('offer', (data) {
      onOffer?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('answer', (data) {
      onAnswer?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('ice-candidate', (data) {
      onIceCandidate?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('user-toggled-audio', (data) {
      onUserToggledAudio?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('user-toggled-video', (data) {
      onUserToggledVideo?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('hand-raised', (data) {
      onHandRaised?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('new-message', (data) {
      onNewMessage?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('room-updated', (data) {
      onRoomUpdated?.call(Map<String, dynamic>.from(data));
    });
  }

  // Join room
  void joinRoom(String roomId, Map<String, dynamic> userInfo) {
    _socket?.emit('join-room', {
      'roomId': roomId,
      ...userInfo,
    });
  }

  // Leave room
  void leaveRoom(String roomId) {
    _socket?.emit('leave-room', {'roomId': roomId});
  }

  // Send WebRTC offer
  void sendOffer(String targetId, Map<String, dynamic> offer) {
    _socket?.emit('offer', {
      'targetId': targetId,
      'offer': offer,
    });
  }

  // Send WebRTC answer
  void sendAnswer(String targetId, Map<String, dynamic> answer) {
    _socket?.emit('answer', {
      'targetId': targetId,
      'answer': answer,
    });
  }

  // Send ICE candidate
  void sendIceCandidate(String targetId, Map<String, dynamic> candidate) {
    _socket?.emit('ice-candidate', {
      'targetId': targetId,
      'candidate': candidate,
    });
  }

  // Toggle audio
  void toggleAudio(String roomId, bool isMuted) {
    _socket?.emit('toggle-audio', {
      'roomId': roomId,
      'isMuted': isMuted,
    });
  }

  // Toggle video
  void toggleVideo(String roomId, bool isEnabled) {
    _socket?.emit('toggle-video', {
      'roomId': roomId,
      'isEnabled': isEnabled,
    });
  }

  // Raise hand
  void raiseHand(String roomId) {
    _socket?.emit('raise-hand', {'roomId': roomId});
  }

  // Send chat message
  void sendChatMessage(String roomId, String message) {
    _socket?.emit('chat-message', {
      'roomId': roomId,
      'message': message,
    });
  }

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
