class ApiConstants {
  // API Base Configuration
  static const String apiBaseUrl = 'http://localhost:3001/api/v1';
  static const String socketUrl = 'http://localhost:3001';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';

  // User Endpoints
  static const String userMe = '/users/me';
  static const String userList = '/users';

  // Chat Endpoints
  static const String chatsPrivate = '/chats/private';
  static const String chatsGroup = '/chats/group';
  static const String chatsSend = '/chats/send';

  // Group Endpoints
  static const String groupsCreate = '/groups';
  static const String groupsMy = '/groups/my';
  static const String groupsAdd = '/groups';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}

class SocketEvents {
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String join = 'join';
  static const String sendMessage = 'send_message';
  static const String receiveMessage = 'receive_message';
  static const String typing = 'typing';
  static const String onlineUsers = 'online_users';
  static const String userStatusChanged = 'user_status_changed';
}
