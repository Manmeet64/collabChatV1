import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

// Messages Provider for a specific chat
final messagesProvider =
    StateNotifierProvider.family<
      MessagesNotifier,
      AsyncValue<List<Message>>,
      String
    >((ref, chatId) {
      return MessagesNotifier(ref, chatId);
    });

class MessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final StateNotifierProviderRef ref;
  final String chatId;
  bool _isPrivate = false;

  MessagesNotifier(this.ref, this.chatId) : super(const AsyncValue.data([])) {
    _loadMessages();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    print('🔧 Setting up socket listeners for chat: $chatId');

    // Delay to ensure socket is initialized
    Future.delayed(Duration(milliseconds: 100), () {
      final socketAsync = ref.read(socketServiceProvider);

      socketAsync.whenData((socket) {
        print('   ✅ Socket available in listener setup');
        if (socket != null) {
          print('   🎯 Registering onMessageReceived callback');
          socket.onMessageReceived((message) {
            print('📨 [EVENT] Socket message received on listener!');
            print('   Message ID: ${message.id}');
            print('   Sender ID: ${message.senderId}');
            print('   Chat ID: ${message.chatId}');
            print('   Other user ID (chatId param): $chatId');

            // Get current user at the time message arrives (not at setup time)
            final currentUserAsync = ref.read(currentUserProvider);

            currentUserAsync.whenData((currentUser) {
              print('   👤 Current user: ${currentUser?.id}');
              if (currentUser != null) {
                bool isRelevant = false;
                String reason = '';

                // Check if this is a private or group chat
                if (_isPrivate) {
                  // For private chats, check if message involves current user and the other user (chatId)
                  // The message is relevant if:
                  // 1. I sent it to the other user, OR
                  // 2. The other user sent it to me
                  final isFromMe = message.senderId == currentUser.id;
                  final isFromOtherUser = message.senderId == chatId;
                  final involvesOtherUser = isFromMe || isFromOtherUser;

                  if (involvesOtherUser) {
                    reason = isFromMe
                        ? 'From me in this chat'
                        : 'From other user in this chat';
                    isRelevant = true;
                  } else {
                    reason = 'Not in this private conversation';
                  }
                } else {
                  // For group chats, check if message belongs to this group
                  // The message is relevant if its chatId matches the group's chat ID
                  if (message.chatId == chatId) {
                    reason = 'Message belongs to this group';
                    isRelevant = true;
                  } else {
                    reason =
                        'Message from different group (${message.chatId} != $chatId)';
                  }
                }

                print('   Result: isRelevant=$isRelevant ($reason)');

                if (isRelevant) {
                  print('   🔄 Updating state...');
                  state.whenData((messages) {
                    final exists = messages.any((m) => m.id == message.id);
                    if (!exists) {
                      print('      ✅ Message added to list');
                      final updated = [
                        ...messages,
                        message,
                      ]; // Add to end (bottom)
                      state = AsyncValue.data(updated);
                      print('      📊 New message count: ${updated.length}');
                    } else {
                      print('      ⚠️ Duplicate message ignored');
                    }
                  });
                }
              } else {
                print('   ❌ No current user');
              }
            });
          });
        } else {
          print('   ❌ Socket is null');
        }
      });
    });
  }

  Future<void> _loadMessages({int limit = 20, int offset = 0}) async {
    print('📥 Loading messages for chatId: $chatId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      final currentUserAsync = ref.read(currentUserProvider);
      try {
        print('   🔗 Trying private chat endpoint...');
        // Try private chat first, if it fails try group
        try {
          // Get current user to pass both IDs to backend
          String? currentUserId;
          await currentUserAsync.whenData((user) {
            currentUserId = user?.id;
          });

          if (currentUserId != null) {
            print('      👤 Current user: $currentUserId');
            print('      🗣️ Other user: $chatId');
            final messages = await api.getPrivateChatMessages(
              currentUserId!,
              chatId,
              limit: limit,
              offset: offset,
            );
            print('   ✅ Loaded ${messages.length} messages from private chat');
            _isPrivate = true;
            return messages;
          } else {
            print('   ⚠️ Current user not available');
            return [];
          }
        } catch (e) {
          print('   ⚠️ Private chat failed: $e');
          print('   🔗 Trying group chat endpoint...');
          _isPrivate = false;
          final messages = await api.getGroupChatMessages(
            chatId,
            limit: limit,
            offset: offset,
          );
          print('   ✅ Loaded ${messages.length} messages from group chat');
          return messages;
        }
      } catch (e) {
        print('❌ Error loading messages: $e');
        return [];
      }
    });
  }

  Future<void> loadMoreMessages({int limit = 20}) async {
    await state.whenData((messages) async {
      final offset = messages.length;
      final api = ref.read(apiServiceProvider);
      final currentUserAsync = ref.read(currentUserProvider);
      try {
        if (_isPrivate) {
          String? currentUserId;
          await currentUserAsync.whenData((user) {
            currentUserId = user?.id;
          });

          if (currentUserId != null) {
            final newMessages = await api.getPrivateChatMessages(
              currentUserId!,
              chatId,
              limit: limit,
              offset: offset,
            );
            state = AsyncValue.data([...messages, ...newMessages]);
          }
        } else {
          final newMessages = await api.getGroupChatMessages(
            chatId,
            limit: limit,
            offset: offset,
          );
          state = AsyncValue.data([...messages, ...newMessages]);
        }
      } catch (e) {
        print('Error loading more messages: $e');
      }
    });
  }

  Future<void> refresh() async {
    await _loadMessages();
  }

  void addMessage(Message message) {
    state.whenData((messages) {
      final updated = [message, ...messages];
      state = AsyncValue.data(updated);
    });
  }
}

// Send Message Provider
final sendMessageProvider =
    FutureProvider.family<void, (String chatId, String message)>((ref, params) {
      return Future.value(); // Placeholder, actual send via socket in UI
    });

// Online Users Provider
final onlineUsersProvider =
    StateNotifierProvider<OnlineUsersNotifier, List<String>>((ref) {
      return OnlineUsersNotifier(ref);
    });

class OnlineUsersNotifier extends StateNotifier<List<String>> {
  final StateNotifierProviderRef ref;

  OnlineUsersNotifier(this.ref) : super([]) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketAsync = ref.read(socketServiceProvider);
    socketAsync.whenData((socket) {
      if (socket != null) {
        socket.onUsersOnline((userIds) {
          state = userIds;
        });
      }
    });
  }

  bool isUserOnline(String userId) {
    return state.contains(userId);
  }
}

// Typing Users Provider
final typingUsersProvider =
    StateNotifierProvider<TypingUsersNotifier, List<String>>((ref) {
      return TypingUsersNotifier(ref);
    });

class TypingUsersNotifier extends StateNotifier<List<String>> {
  final StateNotifierProviderRef ref;

  TypingUsersNotifier(this.ref) : super([]) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketAsync = ref.read(socketServiceProvider);
    socketAsync.whenData((socket) {
      if (socket != null) {
        socket.onUserTyping((userId) {
          if (!state.contains(userId)) {
            state = [...state, userId];

            // Remove after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              state = state.where((id) => id != userId).toList();
            });
          }
        });
      }
    });
  }
}

// Socket Connection Provider
final socketConnectionProvider =
    StateNotifierProvider<SocketConnectionNotifier, bool>((ref) {
      return SocketConnectionNotifier(ref);
    });

class SocketConnectionNotifier extends StateNotifier<bool> {
  final StateNotifierProviderRef ref;

  SocketConnectionNotifier(this.ref) : super(false) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketAsync = ref.read(socketServiceProvider);
    socketAsync.whenData((socket) {
      if (socket != null) {
        socket.onConnectionChanged((isConnected) {
          state = isConnected;
        });
      }
    });
  }
}
