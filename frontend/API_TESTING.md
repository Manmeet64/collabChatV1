# API Integration Testing Guide

## 🧪 Testing the CollabChat API Integration

This guide helps you test all endpoints with the Flutter app.

## 📝 Prerequisites

- Backend running on `http://localhost:3001`
- Postman or Thunder Client installed (optional, for API testing)
- Flutter app running on emulator or device

## 🔑 Authentication Flow

### Step 1: Register a User

**Endpoint:** `POST /api/v1/auth/register`

**Request:**
```json
{
  "username": "testuser",
  "password": "test123"
}
```

**Expected Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "username": "testuser"
  }
}
```

**Test in Flutter:**
1. Open Register Screen
2. Enter username: `testuser`
3. Enter password: `test123`
4. Confirm password: `test123`
5. Tap "Create Account"
6. ✓ Should navigate to Home Screen

### Step 2: Login with Credentials

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "username": "testuser",
  "password": "test123"
}
```

**Expected Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "username": "testuser"
  }
}
```

**Test in Flutter:**
1. Open Login Screen
2. Enter username: `testuser`
3. Enter password: `test123`
4. Tap "Sign In"
5. ✓ Should navigate to Home Screen
6. Token stored in secure storage

## 👥 User Endpoints

### Get Current User

**Endpoint:** `GET /api/v1/users/me`

**Headers:**
```
Authorization: Bearer {token}
```

**Expected Response (200):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "username": "testuser",
  "isOnline": true,
  "lastSeen": "2026-02-07T10:00:00Z"
}
```

**Test in Flutter:**
- On login, this endpoint is called automatically
- User info displayed in Profile Screen

### Get All Users

**Endpoint:** `GET /api/v1/users`

**Headers:**
```
Authorization: Bearer {token}
```

**Expected Response (200):**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "username": "alice",
    "isOnline": true,
    "lastSeen": "2026-02-07T10:00:00Z"
  },
  {
    "id": "507f1f77bcf86cd799439012",
    "username": "bob",
    "isOnline": false,
    "lastSeen": "2026-02-07T09:30:00Z"
  }
]
```

**Test in Flutter:**
1. From Home Screen, see users list
2. Online users have green dot
3. Tap a user to open chat

## 💬 Chat Endpoints

### Get Private Chat Messages

**Endpoint:** `GET /api/v1/chats/private/{userId}?limit=20&offset=0`

**Headers:**
```
Authorization: Bearer {token}
```

**Expected Response (200):**
```json
[
  {
    "id": "msg1",
    "senderId": "507f1f77bcf86cd799439011",
    "chatId": "chat1",
    "content": "Hello there!",
    "type": "text",
    "createdAt": "2026-02-07T10:00:00Z",
    "sender": {
      "id": "507f1f77bcf86cd799439011",
      "username": "alice"
    }
  }
]
```

**Test in Flutter:**
1. Tap user from Home Screen
2. Chat Screen loads
3. Messages appear in list
4. Scroll to load more messages

## 📋 Group Endpoints

### Create Group

**Endpoint:** `POST /api/v1/groups`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Frontend Team",
  "members": ["507f1f77bcf86cd799439012", "507f1f77bcf86cd799439013"]
}
```

**Expected Response (201):**
```json
{
  "id": "507f1f77bcf86cd799439020",
  "name": "Frontend Team",
  "members": ["507f1f77bcf86cd799439011", "507f1f77bcf86cd799439012", "507f1f77bcf86cd799439013"],
  "adminId": "507f1f77bcf86cd799439011",
  "createdAt": "2026-02-07T10:00:00Z"
}
```

**Test in Flutter:**
1. From Home Screen → Groups tab
2. Tap floating action button
3. Enter group name: "Test Group"
4. Select 2+ members
5. Tap "Create Group"
6. ✓ Group appears in Groups list

### Get My Groups

**Endpoint:** `GET /api/v1/groups/my`

**Headers:**
```
Authorization: Bearer {token}
```

**Expected Response (200):**
```json
[
  {
    "id": "507f1f77bcf86cd799439020",
    "name": "Frontend Team",
    "members": ["507f1f77bcf86cd799439011", "507f1f77bcf86cd799439012"],
    "adminId": "507f1f77bcf86cd799439011",
    "createdAt": "2026-02-07T10:00:00Z"
  }
]
```

**Test in Flutter:**
- Home Screen → Groups tab
- Lists all user's groups
- Click to open group chat

### Get Group Chat Messages

**Endpoint:** `GET /api/v1/chats/group/{groupId}?limit=20&offset=0`

**Headers:**
```
Authorization: Bearer {token}
```

**Expected Response (200):**
```json
[
  {
    "id": "msg1",
    "senderId": "507f1f77bcf86cd799439011",
    "chatId": "507f1f77bcf86cd799439020",
    "content": "Hello team!",
    "type": "text",
    "createdAt": "2026-02-07T10:00:00Z",
    "sender": {
      "id": "507f1f77bcf86cd799439011",
      "username": "alice"
    }
  }
]
```

**Test in Flutter:**
1. Home Screen → Groups tab
2. Tap a group
3. Group Chat Screen loads
4. Messages display with sender names

### Add Group Member

**Endpoint:** `POST /api/v1/groups/{groupId}/add`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "userId": "507f1f77bcf86cd799439014"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "message": "User added to group"
}
```

## 🔌 WebSocket (Socket.IO) Events

### Connection

**Event:** `connect`

**Expected on client:**
```
Connected to WebSocket server
Socket ID: /api#abc123def456
```

**Test:**
1. Login to app
2. Check console for "Connected" message
3. Profile Screen should show "Connected" status

### Join Chat

**Emit:**
```json
{
  "event": "join",
  "data": {
    "chatId": "507f1f77bcf86cd799439011"
  }
}
```

**Test:**
1. Open a chat screen
2. Automatically joins the chat
3. Ready to receive messages

### Send Message

**Emit:**
```json
{
  "event": "send_message",
  "data": {
    "chatId": "507f1f77bcf86cd799439011",
    "message": "Hello!",
    "type": "text"
  }
}
```

**Receive:**
```json
{
  "event": "receive_message",
  "data": {
    "id": "msg123",
    "senderId": "507f1f77bcf86cd799439012",
    "chatId": "507f1f77bcf86cd799439011",
    "content": "Hello!",
    "type": "text",
    "createdAt": "2026-02-07T10:00:00Z"
  }
}
```

**Test:**
1. Two users open same chat
2. User 1 sends message
3. User 2 sees message in real-time
4. ✓ No page refresh needed

### Typing Indicator

**Emit:**
```json
{
  "event": "typing",
  "data": {
    "chatId": "507f1f77bcf86cd799439011"
  }
}
```

**Receive:**
```json
{
  "event": "typing",
  "data": "507f1f77bcf86cd799439012"
}
```

**Test:**
1. User 1 starts typing
2. User 2 sees "User1 is typing..." at bottom
3. ✓ Typing status disappears after 3 seconds

### Online Users

**Receive:**
```json
{
  "event": "online_users",
  "data": ["507f1f77bcf86cd799439011", "507f1f77bcf86cd799439012"]
}
```

**Test:**
1. Multiple users logged in
2. Green dot shows next to online users
3. Updates in real-time

## 🧪 Postman Collection

### Export & Import

If you have Postman, create collection with these endpoints:

```json
{
  "info": {
    "name": "CollabChat API",
    "version": "1.0"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/auth/register"
          }
        },
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/auth/login"
          }
        }
      ]
    }
  ]
}
```

## ❌ Error Handling

### Common Error Responses

**400 - Bad Request**
```json
{
  "error": "Username is required"
}
```
Test: Leave username empty in Register

**401 - Unauthorized**
```json
{
  "error": "Invalid token"
}
```
Test: Send request without Authorization header

**404 - Not Found**
```json
{
  "error": "User not found"
}
```
Test: Chat with non-existent user ID

**500 - Server Error**
```json
{
  "error": "Internal server error"
}
```
Test: Backend crash scenario

**Test in Flutter:**
- All errors trigger SnackBar notifications
- Error text displayed to user
- No crash on error

## ✅ Integration Checklist

- [ ] Register endpoint working
- [ ] Login endpoint working
- [ ] Get users endpoint returns list
- [ ] Create group endpoint works
- [ ] Get my groups returns user's groups
- [ ] Private chat messages load
- [ ] Group chat messages load
- [ ] WebSocket connects on login
- [ ] Messages send via socket
- [ ] Messages receive in real-time
- [ ] Typing indicator works
- [ ] Online users list updates
- [ ] Logout clears data
- [ ] Error handling works

## 🚀 Performance Testing

### Test Load

1. **10 messages:**
   - Load messages endpoint
   - ✓ Should load in <200ms

2. **100 messages:**
   - Load with pagination
   - ✓ Should load in <500ms

3. **Concurrent users:**
   - Multiple users in same chat
   - ✓ Messages sync in real-time

## 📊 Debugging

Enable logging in `services/api_service.dart`:

```dart
_dio.interceptors.add(LoggingInterceptor());
```

Check socket events in `services/socket_service.dart`:

```dart
socket.on('receive_message', (data) {
  print('Message received: $data');
});
```

## 📞 Support

If endpoints aren't working:
1. Check backend is running
2. Verify API URLs in `api_constants.dart`
3. Check backend logs for errors
4. Ensure WebSocket server is enabled

---

**Happy Testing! 🎉**
