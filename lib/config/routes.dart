import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/rooms/rooms_list_screen.dart';
import '../screens/rooms/create_room_screen.dart';
import '../screens/rooms/room_screen.dart';
import '../screens/video_call/video_call_screen.dart';
import '../screens/chat/chats_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/new_chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/followers_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import 'constants.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _buildRoute(const SplashScreen(), settings);

      case RouteNames.login:
        return _buildRoute(const LoginScreen(), settings);

      case RouteNames.signup:
        return _buildRoute(const SignupScreen(), settings);

      case RouteNames.home:
        return _buildRoute(const HomeScreen(), settings);

      case RouteNames.roomsList:
        return _buildRoute(const RoomsListScreen(), settings);

      case RouteNames.createRoom:
        return _buildRoute(const CreateRoomScreen(), settings);

      case RouteNames.room:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          RoomScreen(roomId: args?['roomId'] ?? ''),
          settings,
        );

      case RouteNames.videoCall:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          VideoCallScreen(roomId: args?['roomId'] ?? ''),
          settings,
        );

      case RouteNames.chatsList:
        return _buildRoute(const ChatsListScreen(), settings);

      case RouteNames.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ChatScreen(conversationId: args?['conversationId'] ?? ''),
          settings,
        );

      case RouteNames.profile:
        return _buildRoute(const ProfileScreen(), settings);

      case RouteNames.followers:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          FollowersScreen(
            userId: args?['userId'] ?? '',
            showFollowers: args?['showFollowers'] ?? true,
          ),
          settings,
        );

      case RouteNames.notifications:
        return _buildRoute(const NotificationsScreen(), settings);

      case RouteNames.newChat:
        return _buildRoute(const NewChatScreen(), settings);

      case RouteNames.userProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          UserProfileScreen(userId: args?['userId'] ?? ''),
          settings,
        );

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
