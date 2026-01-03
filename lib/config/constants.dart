class AppConstants {
  // App Info
  static const String appName = 'HP House';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = 'https://advgtebnynginbfxhvdi.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_BpHeEa42a9jAixjKA4hjTA_h3JT7Nug';

  // Signaling Server
  static const String signalingServerUrl = 'http://localhost:3000';

  // WebRTC Configuration
  static const Map<String, dynamic> iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  // Room Settings
  static const int maxParticipants = 12;
  static const int maxSpeakers = 6;

  // Media Constraints
  static const Map<String, dynamic> audioConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
  };

  static const Map<String, dynamic> videoConstraints = {
    'video': {
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
      'frameRate': {'ideal': 30},
      'facingMode': 'user',
    },
  };

  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String roomCoversBucket = 'room-covers';
  static const String chatMediaBucket = 'chat-media';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Pagination
  static const int pageSize = 20;

  // Validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxBioLength = 150;
  static const int maxRoomTitleLength = 50;
  static const int maxRoomDescriptionLength = 200;
}

class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String roomsList = '/rooms';
  static const String createRoom = '/rooms/create';
  static const String room = '/rooms/room';
  static const String videoCall = '/video-call';
  static const String chatsList = '/chats';
  static const String chat = '/chat';
  static const String newChat = '/chat/new';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String userProfile = '/user';
  static const String followers = '/followers';
  static const String notifications = '/notifications';
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String theme = 'theme';
  static const String onboardingComplete = 'onboarding_complete';
}
