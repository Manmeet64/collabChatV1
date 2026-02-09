import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/profile_screen.dart';

final routerProvider = Provider((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Always allow navigation to splash, login, and register
      if (state.fullPath == '/splash' ||
          state.fullPath == '/login' ||
          state.fullPath == '/register') {
        return null;
      }

      // Check if user is authenticated for protected routes
      final isAuthenticated = authState.whenData((user) => user != null).value ?? false;
      
      if (!isAuthenticated) {
        // Redirect to splash on first unauthenticated access to protected route
        return '/splash';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main Routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Chat Routes
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'];
          return ChatScreen(userId: userId ?? '');
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          // Redirect to user selection or fallback
          return const HomeScreen();
        },
      ),

      // Group Chat Routes
      GoRoute(
        path: '/group-chat/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'];
          return GroupChatScreen(groupId: groupId ?? '');
        },
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});
