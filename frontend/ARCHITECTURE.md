# CollabChat Flutter App - Architecture & Setup Guide

## 🏗️ Architecture Overview

This application uses **Clean Architecture** with **Riverpod** for state management:

```
Presentation Layer (UI)
    ↓ (Reads/Watches)
State Management (Riverpod Providers)
    ↓ (Calls)
Services Layer (API, Socket, Storage)
    ↓ (HTTP/WebSocket)
Backend Server
```

## 📦 Layer Breakdown

### 1. **Presentation Layer (Screens & Widgets)**

**Responsibility:** Display UI and handle user interactions

**Files:**
- `screens/` - Complete screens
- `widgets/` - Reusable UI components

**Pattern:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(someProvider);
  
  return Scaffold(
    body: state.when(
      data: (data) => YourWidget(data),
      loading: () => LoadingWidget(),
      error: (error, st) => ErrorWidget(error),
    ),
  );
}
```

### 2. **State Management Layer (Providers)**

**Responsibility:** Manage application state and business logic

**Types of Providers:**

```dart
// Simple provider - immutable value
final simpleProvider = Provider((ref) {
  return "static value";
});

// State Notifier - mutable state with methods
final mutableProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref);
});

// Future Provider - async data
final futureProvider = FutureProvider((ref) {
  return fetchDataFromAPI();
});

// Family - parametrized providers
final parametrizedProvider = FutureProvider.family<String, String>((ref, param) {
  return fetchData(param);
});
```

### 3. **Services Layer**

**Responsibility:** Handle HTTP, WebSocket, and storage operations

#### API Service (Dio)
```dart
final apiServiceProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage);
});
```

**Features:**
- Automatic token injection via interceptor
- Error handling
- Request/response logging
- Timeout management

#### Socket Service (Socket.IO)
```dart
final socketServiceProvider = StateNotifierProvider((ref) {
  return SocketServiceNotifier(ref);
});
```

**Features:**
- Connection management
- Event listeners
- Automatic reconnection
- Type-safe event handling

#### Storage Service (SharedPreferences + Secure Storage)
```dart
final storageServiceProvider = Provider((ref) {
  return StorageService();
});
```

**Features:**
- Secure token storage
- User preference persistence
- Migration helpers

## 🔄 Data Flow Example: Login

```
1. User fills form and taps "Login"
         ↓
2. LoginScreen calls:
   ref.read(currentUserProvider.notifier).login(username, password)
         ↓
3. CurrentUserNotifier.login() executes:
   - Validates input
   - Calls apiService.login()
   - Saves token to storage
   - Connects socket
   - Updates state
         ↓
4. State changes to AsyncValue.data(user)
         ↓
5. LoginScreen watches state and rebuilds
         ↓
6. User is automatically redirected to home screen
```

## 🗂️ Folder Organization

### Constants
```
lib/constants/
├── api_constants.dart    # API URLs, endpoints, socket events
└── app_theme.dart        # Colors, fonts, theme
```

### Models
```
lib/models/
├── user_model.dart       # @freezed User class
├── message_model.dart    # @freezed Message class
├── chat_model.dart       # @freezed Chat class
└── group_model.dart      # @freezed Group class
```

**Why Freezed?**
- Immutable data classes
- Automatic equality & hashCode
- Copy-with helpers
- JSON serialization

### Services
```
lib/services/
├── api_service.dart      # Dio HTTP client with auth
├── socket_service.dart   # Socket.IO WebSocket client
└── storage_service.dart  # Secure & shared preferences
```

### Providers
```
lib/providers/
├── auth_provider.dart    # Auth state & logic
├── chat_provider.dart    # Messages & chat state
└── user_provider.dart    # Users & groups state
```

**Provider Hierarchy:**
```
storageServiceProvider (base)
    ↓
apiServiceProvider (depends on storage)
    ↓
socketServiceProvider (independent)

        ↓
currentUserProvider (depends on api, socket, storage)
    ↓
authProvider (depends on currentUser)

        ↓
usersListProvider (depends on api)
myGroupsProvider (depends on api)

        ↓
messagesProvider (depends on api, socket)
onlineUsersProvider (depends on socket)
typingUsersProvider (depends on socket)
```

### Screens
```
lib/screens/
├── splash_screen.dart        # Entry point, auth check
├── login_screen.dart         # Email/password login
├── register_screen.dart      # User registration
├── home_screen.dart          # Chat list & groups
├── chat_screen.dart          # 1-on-1 messaging
├── group_chat_screen.dart    # Group messaging
├── create_group_screen.dart  # New group creation
└── profile_screen.dart       # User profile & logout
```

### Widgets
```
lib/widgets/
├── chat_bubble.dart      # Message display
├── message_input.dart    # Message input field
└── user_tile.dart        # User list item
```

### Utils
```
lib/utils/
├── validators.dart       # Form validation logic
└── extensions.dart       # Dart extensions
```

## 🔌 WebSocket Events Reference

### Connection Flow
```
1. User logs in
2. Token received from backend
3. Socket.IO connection initiated with token
4. Backend verifies token
5. Connection established
6. Socket ready for events
```

### Message Flow
```
User A sends message
    ↓
socket.emit('send_message', {...})
    ↓
Backend receives event
    ↓
Backend broadcasts to recipients
    ↓
User B receives 'receive_message' event
    ↓
Message added to UI
```

### Event Handlers
```dart
socket.onMessageReceived((message) {
  // Add to messages provider
});

socket.onUsersOnline((userIds) {
  // Update online status
});

socket.onUserTyping((userId) {
  // Show typing indicator
});

socket.onConnectionChanged((isConnected) {
  // Update connection status
});
```

## 🎯 Development Workflow

### Creating a New Feature

1. **Define Model** (`models/feature_model.dart`)
```dart
@freezed
class Feature with _$Feature {
  const factory Feature({
    required String id,
    required String name,
  }) = _Feature;
  factory Feature.fromJson(Map<String, dynamic> json) => _$FeatureFromJson(json);
}
```

2. **Add API Endpoints** (`services/api_service.dart`)
```dart
Future<Feature> getFeature(String id) async {
  final response = await _dio.get('/features/$id');
  return Feature.fromJson(response.data);
}
```

3. **Create Provider** (`providers/feature_provider.dart`)
```dart
final featureProvider = FutureProvider.family<Feature, String>((ref, id) {
  final api = ref.watch(apiServiceProvider);
  return api.getFeature(id);
});
```

4. **Build Screen** (`screens/feature_screen.dart`)
```dart
class FeatureScreen extends ConsumerWidget {
  final String featureId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feature = ref.watch(featureProvider(featureId));
    
    return feature.when(
      data: (f) => FeatureWidget(f),
      loading: () => LoadingWidget(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

5. **Update Router** (`router.dart`)
```dart
GoRoute(
  path: '/feature/:id',
  builder: (context, state) => FeatureScreen(
    featureId: state.pathParameters['id']!,
  ),
)
```

## 🧪 Testing Approach

### Unit Tests
```dart
test('validator should reject empty username', () {
  final error = Validators.validateUsername('');
  expect(error, isNotNull);
});
```

### Integration Tests
```dart
testWidgets('login flow works', (WidgetTester tester) async {
  // Build app
  // Type credentials
  // Tap login
  // Verify navigation
});
```

## 📊 Performance Tips

1. **Use ListView.builder** instead of ListView for long lists
2. **Implement pagination** for message loading
3. **Avoid rebuilds** with `ref.watch` vs `ref.read`
4. **Cache data** in providers when appropriate
5. **Debounce** socket events during rapid changes

## 🔒 Security Practices

1. **Secure Token Storage**
   - Use `flutter_secure_storage` for tokens
   - Never store tokens in SharedPreferences

2. **HTTPS Only**
   - Use HTTPS URLs in production
   - Implement certificate pinning if needed

3. **Password Validation**
   - Minimum 6 characters
   - No special requirements (MVP scope)

4. **Input Validation**
   - Validate all user inputs before sending
   - Use validators from `utils/validators.dart`

## 🐛 Debugging Tips

### Check Provider State
```dart
ref.read(someProvider); // Get current value
ref.watch(someProvider); // Watch for changes
ref.refresh(someProvider); // Force refresh
```

### Enable Logging
```dart
// In api_service.dart
_dio.interceptors.add(LoggingInterceptor());

// In socket_service.dart
socket.onConnect((_) => print('Connected'));
```

### Hot Reload Issues
- Full hot restart if providers not updating: `r` in terminal

## 📚 Resources

- [Riverpod Documentation](https://riverpod.dev)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Socket.IO Client](https://pub.dev/packages/socket_io_client)

---

**Last Updated:** February 2026
