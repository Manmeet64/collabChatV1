import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _hasNavigated) return;
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted || _hasNavigated) return;

    try {
      print('🔍 Checking auth status...');
      final isLoggedIn = await ref
          .read(currentUserProvider.notifier)
          .checkLoggedIn();

      if (!mounted || _hasNavigated) return;

      print('Auth status: ${isLoggedIn ? "logged in" : "not logged in"}');
      _hasNavigated = true;

      // Navigate based on auth status
      if (isLoggedIn) {
        print('✅ Navigating to /home');
        context.go('/home');
      } else {
        print('➡️ Navigating to /login');
        context.go('/login');
      }
    } catch (e) {
      print('❌ Auth check error: $e');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentUserProvider);

    // Watch for user login and navigate immediately
    if (authState.hasValue && authState.value != null && !_hasNavigated) {
      print('👤 User detected in splash screen, navigating to /home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasNavigated = true;
        context.go('/home');
      });
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo/App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'CollabChat',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            const Text(
              'Real-time Communication',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
