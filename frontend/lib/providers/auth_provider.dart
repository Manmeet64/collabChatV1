import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import 'user_provider.dart';

// Storage Service Provider
final storageServiceProvider = Provider((ref) {
  final storage = StorageService();
  // Note: This needs to be initialized in main()
  return storage;
});

// API Service Provider
final apiServiceProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage);
});

// Socket Service Provider
final socketServiceProvider =
    StateNotifierProvider<SocketServiceNotifier, AsyncValue<SocketService?>>((
      ref,
    ) {
      return SocketServiceNotifier(ref);
    });

class SocketServiceNotifier extends StateNotifier<AsyncValue<SocketService?>> {
  final StateNotifierProviderRef ref;

  SocketServiceNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> connect(String token) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final socketService = SocketService(token);
      await socketService.connect();
      return socketService;
    });
  }

  void disconnect() {
    state.whenData((socket) {
      socket?.disconnect();
    });
    state = const AsyncValue.data(null);
  }
}

// Current User Provider
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<User?>>((ref) {
      return CurrentUserNotifier(ref);
    });

class CurrentUserNotifier extends StateNotifier<AsyncValue<User?>> {
  final StateNotifierProviderRef ref;

  CurrentUserNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final api = ref.read(apiServiceProvider);
        final storage = ref.read(storageServiceProvider);

        print('🔐 Attempting login for username: $username');
        final response = await api.login(username, password);
        print('✅ Login response received: ${response.user.username}');

        await storage.saveToken(response.token);
        await storage.saveUserId(response.user.id);
        await storage.saveUsername(response.user.username);
        print('💾 User data saved to storage');

        // Connect socket after login
        try {
          await ref
              .read(socketServiceProvider.notifier)
              .connect(response.token);
          print('🔌 Socket connected successfully');
        } catch (e) {
          print('⚠️ Socket connection failed: $e');
        }

        // Refresh users list to fetch fresh data (excluding current user)
        try {
          ref.invalidate(usersListProvider);
          await ref.read(usersListProvider.future);
          print('🔄 Users list refreshed with current user excluded');
        } catch (e) {
          print('⚠️ Failed to refresh users list: $e');
        }

        return response.user;
      } catch (e) {
        print('❌ Login error: $e');
        rethrow;
      }
    });
  }

  Future<void> register(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final api = ref.read(apiServiceProvider);
        final storage = ref.read(storageServiceProvider);

        print('📝 Attempting registration for username: $username');
        final response = await api.register(username, password);
        print('✅ Registration response received: ${response.user.username}');

        await storage.saveToken(response.token);
        await storage.saveUserId(response.user.id);
        await storage.saveUsername(response.user.username);
        print('💾 User data saved to storage');

        // Connect socket after registration
        try {
          await ref
              .read(socketServiceProvider.notifier)
              .connect(response.token);
          print('🔌 Socket connected successfully');
        } catch (e) {
          print('⚠️ Socket connection failed: $e');
        }

        // Refresh users list to fetch fresh data (excluding current user)
        try {
          ref.invalidate(usersListProvider);
          await ref.read(usersListProvider.future);
          print('🔄 Users list refreshed with current user excluded');
        } catch (e) {
          print('⚠️ Failed to refresh users list: $e');
        }

        return response.user;
      } catch (e) {
        print('❌ Registration error: $e');
        rethrow;
      }
    });
  }

  Future<void> logout() async {
    final storage = ref.read(storageServiceProvider);
    ref.read(socketServiceProvider.notifier).disconnect();
    await storage.clearAll();
    state = const AsyncValue.data(null);
  }

  Future<bool> checkLoggedIn() async {
    final storage = ref.read(storageServiceProvider);
    try {
      final isLoggedIn = await storage.isLoggedIn();
      if (!isLoggedIn) {
        state = const AsyncValue.data(null);
        return false;
      }

      // New login - fetch current data
      final token = await storage.getToken();
      if (token != null) {
        try {
          // Connect socket in background (don't wait for it)
          ref.read(socketServiceProvider.notifier).connect(token).catchError((
            e,
          ) {
            print('⚠️ Background socket connection failed: $e');
          });

          final api = ref.read(apiServiceProvider);
          final user = await api.getCurrentUser();
          state = AsyncValue.data(user);
          return true;
        } catch (e) {
          // API call failed, stil consider as logged in if token exists
          state = const AsyncValue.data(null);
          return true;
        }
      }

      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// Auth State Provider
final authProvider = Provider((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final storage = ref.watch(storageServiceProvider);
  return (currentUser: currentUser, storage: storage);
});
