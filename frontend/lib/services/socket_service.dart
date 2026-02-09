import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../constants/api_constants.dart';
import '../models/message_model.dart';

typedef OnMessageReceived = void Function(Message message);
typedef OnUsersOnline = void Function(List<String> userIds);
typedef OnUserTyping = void Function(String userId);
typedef OnConnectionChanged = void Function(bool isConnected);
typedef OnChatJoined = void Function(String chatId, String? recipientId);

class SocketService {
  late IO.Socket _socket;
  bool _isConnected = false;
  final String _token;
  late Completer<void> _connectCompleter;

  final List<OnMessageReceived> _messageListeners = [];
  final List<OnUsersOnline> _usersOnlineListeners = [];
  final List<OnUserTyping> _typingListeners = [];
  final List<OnConnectionChanged> _connectionListeners = [];
  OnChatJoined? _onChatJoined;

  SocketService(this._token);

  Future<void> connect() async {
    try {
      _connectCompleter = Completer<void>();
      print('🔗 Socket connecting...');
      _socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder().setTransports(['websocket']).setAuth({
          'token': _token,
        }).build(),
      );

      _socket.on('connect', (_) {
        print('✅ Socket connected!');
        _isConnected = true;
        _notifyConnectionChanged(true);
        if (!_connectCompleter.isCompleted) {
          _connectCompleter.complete();
        }
      });

      _socket.on('disconnect', (_) {
        print('❌ Socket disconnected!');
        _isConnected = false;
        _notifyConnectionChanged(false);
      });

      _socket.on(SocketEvents.receiveMessage, (data) {
        try {
          print('📨 Message received from socket: $data');
          final message = Message.fromJson(data as Map<String, dynamic>);
          _notifyMessageReceived(message);
        } catch (e) {
          print('Error parsing message: $e');
        }
      });

      _socket.on(SocketEvents.onlineUsers, (data) {
        try {
          final userIds = List<String>.from(data as List);
          _notifyUsersOnline(userIds);
        } catch (e) {
          print('Error parsing online users: $e');
        }
      });

      _socket.on(SocketEvents.typing, (data) {
        try {
          final userId = data as String;
          _notifyTyping(userId);
        } catch (e) {
          print('Error parsing typing event: $e');
        }
      });

      _socket.on('error', (error) {
        print('🛑 Socket error: $error');
        if (!_connectCompleter.isCompleted) {
          _connectCompleter.completeError(error);
        }
      });

      // Listen for joined_chat event
      _socket.on('joined_chat', (data) {
        print('✅ Joined chat confirmed: $data');
        if (_onChatJoined != null) {
          _onChatJoined!(data['chatId'], data['recipientId']);
        }
      });

      // Wait for connection to actually establish with 10 second timeout
      await _connectCompleter.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Socket connection timeout');
          throw TimeoutException('Socket connection timeout');
        },
      );
    } catch (e) {
      print('❌ Failed to connect socket: $e');
      rethrow;
    }
  }

  // Join a chat
  void joinChat(String chatId, {String? recipientId}) {
    print('📍 joinChat called for: $chatId');
    if (_isConnected) {
      final data = {'chatId': chatId};
      if (recipientId != null) {
        data['recipientId'] = recipientId;
        print('   🎯 Including recipientId: $recipientId');
      }
      _socket.emit(SocketEvents.join, data);
      print('   ✅ Join event emitted');
    } else {
      print('   ❌ Socket not connected, cannot join chat');
    }
  }

  // Send message via socket (will try API if socket fails)
  Future<void> sendMessage(
    String chatId,
    String message, {
    String type = 'text',
    String? recipientId,
  }) async {
    print('🔊 sendMessage called:');
    print('   - Connected: $_isConnected');
    print('   - ChatID: $chatId');
    print('   - RecipientID: $recipientId');
    print('   - Message: $message');

    if (_isConnected) {
      try {
        final data = {'chatId': chatId, 'message': message, 'type': type};
        if (recipientId != null) {
          data['recipientId'] = recipientId;
        }
        _socket.emit(SocketEvents.sendMessage, data);
        print('   ✅ Message emitted to socket');
      } catch (e) {
        print('   ❌ Error emitting via socket: $e, will retry via API');
        // Will be retried via API in chat_screen
      }
    } else {
      print('   ⚠️ Socket NOT connected, messages will be sent via API');
    }
  }

  // Notify typing
  void notifyTyping(String chatId) {
    if (_isConnected) {
      _socket.emit(SocketEvents.typing, {'chatId': chatId});
    }
  }

  // Listeners Management
  void onMessageReceived(OnMessageReceived callback) {
    _messageListeners.add(callback);
  }

  void onUsersOnline(OnUsersOnline callback) {
    _usersOnlineListeners.add(callback);
  }

  void onUserTyping(OnUserTyping callback) {
    _typingListeners.add(callback);
  }

  void onConnectionChanged(OnConnectionChanged callback) {
    _connectionListeners.add(callback);
  }

  void onChatJoined(OnChatJoined callback) {
    _onChatJoined = callback;
  }

  void removeMessageListener(OnMessageReceived callback) {
    _messageListeners.remove(callback);
  }

  void removeUsersOnlineListener(OnUsersOnline callback) {
    _usersOnlineListeners.remove(callback);
  }

  void removeTypingListener(OnUserTyping callback) {
    _typingListeners.remove(callback);
  }

  void removeConnectionListener(OnConnectionChanged callback) {
    _connectionListeners.remove(callback);
  }

  // Notifiers
  void _notifyMessageReceived(Message message) {
    for (var listener in _messageListeners) {
      listener(message);
    }
  }

  void _notifyUsersOnline(List<String> userIds) {
    for (var listener in _usersOnlineListeners) {
      listener(userIds);
    }
  }

  void _notifyTyping(String userId) {
    for (var listener in _typingListeners) {
      listener(userId);
    }
  }

  void _notifyConnectionChanged(bool isConnected) {
    for (var listener in _connectionListeners) {
      listener(isConnected);
    }
  }

  // Getters
  bool get isConnected => _isConnected;

  // Disconnect
  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
    }
  }

  // Reconnect
  void reconnect() {
    if (!_isConnected) {
      _socket.connect();
    }
  }
}
