import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';
import '../screens/call_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/new_chat_screen.dart';
import '../services/matrix_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final loginState = ref.watch(loginStateProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (loginState == LoginState.loading) return '/splash';
      if (loginState == LoginState.loggedOut && state.uri.path != '/login') return '/login';
      if (loginState == LoginState.loggedIn && (state.uri.path == '/login' || state.uri.path == '/splash')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/chat/:roomId',
        builder: (_, state) => ChatScreen(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(
        path: '/call/audio/:roomId',
        builder: (_, state) => AudioCallScreen(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(
        path: '/call/video/:roomId',
        builder: (_, state) => VideoCallScreen(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(path: '/calls', builder: (_, __) => const CallHistoryScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/new-chat', builder: (_, __) => const NewChatScreen()),
    ],
  );
});
