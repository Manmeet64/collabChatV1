# CollabChat Flutter - Quick Start Guide

## ⚡ 5-Minute Setup

### Step 1: Prerequisites
Ensure you have:
- Flutter 3.10.8+ installed
- Dart 3.10.8+ installed
- VS Code or Android Studio
- An emulator or physical device

Check versions:
```bash
flutter --version
dart --version
```

### Step 2: Get Dependencies
```bash
cd /Users/s.d./Downloads/FlutterProject/frontend
flutter pub get
```

### Step 3: Generate Code Files
```bash
flutter pub run build_runner build
```
This generates:
- `*.freezed.dart` - Immutable model classes
- `*.g.dart` - JSON serialization code

### Step 4: Configure API Endpoint
Edit `lib/constants/api_constants.dart`:

**For Local Development:**
```dart
static const String apiBaseUrl = 'http://localhost:3001/api/v1';
static const String socketUrl = 'http://localhost:3001';
```

**For Production:**
```dart
static const String apiBaseUrl = 'https://api.example.com/api/v1';
static const String socketUrl = 'https://api.example.com';
```

### Step 5: Run the App

**On iOS Simulator:**
```bash
flutter run -d "iPhone 15"
```

**On Android Emulator:**
```bash
flutter run -d emulator
```

**On Physical Device:**
```bash
flutter run
```

**On Web (Chrome):**
```bash
flutter run -d chrome
```

## 🎯 First Test Run

1. **Login Screen Appears** ✓
2. **No Account? Tap "Sign up"** → Register Screen
3. **Create account** - username: `testuser`, password: `test123`
4. **Login with same credentials**
5. **Home screen shows** - Direct Messages & Groups tabs
6. **See other users** - Tap any user to start chatting
7. **Chat opens** - Ready for real-time messaging

## 🔧 Backend Requirements

Your backend must be running with:

```
GET  /api/v1/users           - List all users
GET  /api/v1/auth/login      - Login user
POST /api/v1/auth/register   - Register user
POST /api/v1/groups          - Create group
GET  /api/v1/groups/my       - Get user's groups
GET  /api/v1/chats/private/:userId   - Get DM history
GET  /api/v1/chats/group/:groupId    - Get group history

WebSocket Events:
- join
- send_message
- receive_message
- online_users
- typing
```

## 📱 Testing Features

### Test Direct Message
1. Create 2 accounts
2. Login to account 1
3. See account 2 in users list
4. Tap to open chat
5. Send message
6. Message appears in real-time

### Test Group Chat
1. Go to Groups tab
2. Tap floating action button
3. Enter group name
4. Select members
5. Create group
6. Messages in group visible to all members

### Test Online Status
- Online users show green dot
- Offline users show gray dot
- Status updates in real-time via socket

## 🐛 Troubleshooting

### "Module not found" Errors
**Solution:** Rebuild code generation
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### API Connection Failed
**Solution:** Check:
- Backend is running on correct port
- API URL in `api_constants.dart` is correct
- Firewall allows localhost connections
- On physical device: use actual IP (not localhost)

### WebSocket Connection Failed
**Solution:**
- Backend must support Socket.IO
- Ensure Socket.IO server is running
- Check firewall/network settings
- Verify authentication token is valid

### Hot Reload Not Working
**Solution:** Do full restart
```bash
# In terminal, press 'r' then 'R' for restart
```

## 📦 Build for Release

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk

# Or Android App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Output: build/ios/Release-iphoneos/
```

### Web
```bash
flutter build web
# Output: build/web/
```

## 🌐 Environment Configuration

Create `.env` file in project root (optional):
```
API_BASE_URL=http://localhost:3001
SOCKET_URL=http://localhost:3001
```

Then update `api_constants.dart` to read from `dotenv`.

## 📋 App Screens Checklist

- [x] Splash Screen - Auto-login check
- [x] Login Screen - Email/password auth
- [x] Register Screen - New account creation
- [x] Home Screen - DMs & Groups tabs
- [x] Chat Screen - 1-on-1 messaging
- [x] Group Chat Screen - Group messaging
- [x] Create Group Screen - New group creation
- [x] Profile Screen - User profile & logout

## 💾 Local Storage

The app stores:
- **Tokens** - In secure storage (`flutter_secure_storage`)
- **User ID** - In shared preferences
- **Username** - In shared preferences

Data is cleared on logout.

## 🔐 Default Test Credentials

After backend runs, create test accounts:
- **Account 1:** username: `alice`, password: `alice123`
- **Account 2:** username: `bob`, password: `bob123`

## 🚀 Performance Tips

1. **Use List Views** - Don't load all messages at once
2. **Pagination** - Load 20 messages, then more on scroll
3. **Hot Reload** - Fast iteration during development
4. **DevTools** - `flutter pub global activate devtools && devtools`

## 📞 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Provider not updating | Try `ref.refresh()` |
| Socket not connecting | Check backend WebSocket server |
| Messages not loading | Verify API endpoint URL |
| Login fails | Check backend auth service |
| Theme issues | Run `flutter pub get` again |

## 🎨 Customization

### Change Colors
Edit `lib/constants/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF6366F1); // Purple
static const Color accentColor = Color(0xFF10B981);  // Green
```

### Change App Name
Search & replace "CollabChat" with your app name in:
- `pubspec.yaml`
- `android/app/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## 📚 Next Steps

1. Connect your backend
2. Test all flows
3. Customize branding
4. Build for your platforms
5. Deploy!

---

**Happy Coding! 🚀**
