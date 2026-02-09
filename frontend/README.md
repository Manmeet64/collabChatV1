# CollabChat - Flutter Frontend

A modern, real-time chat and collaboration platform built with Flutter. Features one-to-one messaging, group chats, and real-time communication.

## 🚀 Features

- ✅ **User Authentication** - Username & password with JWT tokens
- ✅ **Real-Time Messaging** - WebSocket-based chat via Socket.IO
- ✅ **One-to-One Chat** - Direct messaging between users
- ✅ **Group Chats** - Create and manage group conversations
- ✅ **Online Status** - See who's online/offline
- ✅ **Typing Indicators** - Real-time typing notifications
- ✅ **Message History** - Persistent chat history with pagination
- ✅ **Responsive UI** - Works on mobile, tablet, and desktop

## 📋 Project Structure

```
lib/
├── constants/
│   ├── api_constants.dart      # API endpoints and configuration
│   └── app_theme.dart           # App styling and colors
├── models/
│   ├── user_model.dart          # User data model
│   ├── message_model.dart       # Message data model
│   ├── chat_model.dart          # Chat data model
│   └── group_model.dart         # Group data model
├── services/
│   ├── api_service.dart         # HTTP API client (Dio)
│   ├── socket_service.dart      # WebSocket client (Socket.IO)
│   └── storage_service.dart     # Local storage (SharedPreferences)
├── providers/
│   ├── auth_provider.dart       # Authentication state management
│   ├── chat_provider.dart       # Chat messages state management
│   └── user_provider.dart       # Users & groups state management
├── screens/
│   ├── splash_screen.dart       # Splash/loading screen
│   ├── login_screen.dart        # Login page
│   ├── register_screen.dart     # Registration page
│   ├── home_screen.dart         # Chat list & groups
│   ├── chat_screen.dart         # One-to-one chat
│   ├── group_chat_screen.dart   # Group chat
│   ├── create_group_screen.dart # Create new group
│   └── profile_screen.dart      # User profile & settings
├── widgets/
│   ├── chat_bubble.dart         # Message bubble widget
│   ├── message_input.dart       # Message input field
│   └── user_tile.dart           # User list item
├── utils/
│   ├── validators.dart          # Form validation helpers
│   └── extensions.dart          # Dart extensions (DateTime, String)
├── router.dart                  # GoRouter navigation configuration
└── main.dart                    # App entry point
```

## 🔧 Setup & Installation

### Prerequisites

- Flutter 3.10.8 or higher
- Dart 3.10.8 or higher
- Node.js backend running on `http://localhost:3001`

### Installation Steps

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```
2. **Generate code files:**

   ```bash
   flutter pub run build_runner build
   ```
3. **Run the app:**

   ```bash
   # On device/emulator
   flutter run

   # On web
   flutter run -d chrome
   ```

## 🛠 Dependencies

### State Management

- **riverpod** - Reactive state management
- **flutter_riverpod** - Flutter integration for Riverpod

### Networking

- **dio** - HTTP client with interceptors
- **socket_io_client** - WebSocket client for real-time messaging

### Navigation

- **go_router** - Modern routing and navigation

### Storage

- **shared_preferences** - Local storage for non-sensitive data
- **flutter_secure_storage** - Secure storage for authentication tokens

### Data Models

- **freezed_annotation** - Code generation for immutable classes
- **json_annotation** - JSON serialization

### Utilities

- **intl** - Internationalization and date formatting

## 🔐 Authentication

### Login Flow

1. User enters username and password
2. Credentials sent to backend via HTTP POST
3. Backend returns JWT token
4. Token stored securely in `flutter_secure_storage`
5. Socket connection established with token
6. User redirected to home screen

### Token Management

- Tokens are automatically included in API requests via Dio interceptor
- Tokens are passed to Socket.IO during connection
- Logout clears all tokens and local data

## 💬 Real-Time Chat

### WebSocket Events

**Outgoing Events:**

- `join` - Join a chat room
- `send_message` - Send a message
- `typing` - Notify others of typing

**Incoming Events:**

- `receive_message` - New message received
- `online_users` - List of online user IDs
- `typing` - User is typing notification

### Message Flow

1. User types message in input field
2. Message sent via `send_message` socket event
3. Backend broadcasts to other users in chat
4. `receive_message` event received and added to messages list
5. UI updates via Riverpod state management

## 📱 Screens

### Splash Screen

- Shows app logo on launch
- Checks if user is already logged in
- Redirects to home if authenticated, login otherwise

### Login Screen

- Username and password fields
- Form validation
- Error handling
- Link to register page

### Register Screen

- Username and password fields
- Password confirmation field
- Form validation
- Link to login page

### Home Screen

- Two tabs: "Direct Messages" and "Groups"
- Lists available users for DMs
- Lists user's groups
- Floating action button to start new chat or create group

### Chat Screen

- One-to-one messaging
- Online status indicator
- Message history with pagination
- Typing indicator (received)
- Message input field

### Group Chat Screen

- Group messaging
- Member list
- Typing indicators (multiple users)
- Message history
- Group info button

### Create Group Screen

- Group name input
- User selection (multi-select)
- Create button

### Profile Screen

- User avatar
- Username display
- Connection status
- Logout button

## 🎨 UI/UX Highlights

- **Modern Design** - Clean, minimal interface
- **Color Scheme** - Purple (#6366F1) primary, green (#10B981) accent
- **Responsive** - Works on all screen sizes
- **Dark Mode Ready** - Theme infrastructure supports light/dark modes
- **Accessibility** - Proper semantic widgets and contrast ratios

## ⚙️ Configuration

### API Configuration

Update `ApiConstants` in `constants/api_constants.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:3001/api/v1';
static const String socketUrl = 'http://localhost:3001';
```

For production:

```dart
static const String apiBaseUrl = 'https://api.collabchat.com/api/v1';
static const String socketUrl = 'https://api.collabchat.com';
```

## 🔄 State Management Flow

```
User Action (Tap Button)
    ↓
Screen calls Provider notifier method
    ↓
Provider makes API/Socket call
    ↓
Result stored in Provider state
    ↓
Screen watches Provider and rebuilds
    ↓
UI updates with new data
```

## 🐛 Error Handling

- Network errors shown via SnackBar
- Form validation prevents invalid submissions
- Graceful socket connection recovery
- Error states in AsyncValue

## 🚀 Performance Optimizations

- Lazy loading of messages (pagination)
- Efficient list rendering with ListView.builder
- Firebase-style caching strategies
- Minimal rebuilds with Riverpod

## 📝 Future Enhancements

- [ ] File sharing/upload
- [ ] Read receipts
- [ ] Message reactions
- [ ] Voice/video calls
- [ ] End-to-end encryption
- [ ] Dark mode
- [ ] Push notifications
- [ ] Admin dashboard
- [ ] Message search
- [ ] User profiles & bios

## 🔗 Backend Integration

This app requires a backend API. Key endpoints:

**Auth:**

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user

**Users:**

- `GET /api/v1/users/me` - Get current user
- `GET /api/v1/users` - List all users

**Chats:**

- `GET /api/v1/chats/private/:userId` - Get DM history
- `GET /api/v1/chats/group/:groupId` - Get group history

**Groups:**

- `POST /api/v1/groups` - Create group
- `GET /api/v1/groups/my` - Get user's groups
- `POST /api/v1/groups/:id/add` - Add member to group

## 📞 Support

For issues or questions, refer to the PRD document or check Flutter documentation.

---

**Built with ❤️ using Flutter & Dart**
