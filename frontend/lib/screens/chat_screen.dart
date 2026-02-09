import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../constants/app_theme.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/extensions.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Join chat via socket and load messages
    Future.microtask(() {
      print('🎬 ChatScreen initialized for: ${widget.userId}');

      // Load messages from API
      print('📥 Loading chat history...');
      final currentUser = ref.read(currentUserProvider);
      currentUser.whenData((user) {
        if (user != null) {
          print('   👤 Current user: ${user.id}');
          print('   🗣️ Chat with: ${widget.userId}');
          // Fetch messages - the notifier will handle the API call
          ref.read(messagesProvider(widget.userId).notifier).refresh().then((
            _,
          ) {
            // Scroll to bottom after initial load
            _scrollToBottom();
          });
        }
      });

      // Join chat via socket with recipientId so backend can resolve chat room
      ref.read(socketServiceProvider).whenData((socket) {
        // For private chats, pass both chatId and recipientId
        // Backend will resolve to the actual chat room
        socket?.joinChat('temp', recipientId: widget.userId);
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when scrolling to top (not bottom anymore)
    if (_scrollController.position.pixels == 0) {
      if (!_isLoadingMore) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    setState(() => _isLoadingMore = true);
    await ref.read(messagesProvider(widget.userId).notifier).loadMoreMessages();
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.userId));
    final currentUser = ref.watch(currentUserProvider);
    final usersList = ref.watch(usersListProvider);
    final onlineUsers = ref.watch(onlineUsersProvider);

    // Auto-scroll when new messages arrive
    messages.whenData((messageList) {
      if (messageList.length != _previousMessageCount) {
        _previousMessageCount = messageList.length;
        _scrollToBottom();
      }
    });

    // Find the other user
    User? otherUser;
    usersList.whenData((users) {
      otherUser = users.cast<User>().firstWhere(
        (u) => u.id == widget.userId,
        orElse: () => User(id: widget.userId, username: 'User'),
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(otherUser?.username ?? 'Chat'),
            if (otherUser != null)
              Text(
                onlineUsers.contains(otherUser!.id) ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: onlineUsers.contains(otherUser!.id)
                      ? AppTheme.accentColor
                      : AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(messagesProvider(widget.userId).notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📥 Refreshing chat history...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (messageList) {
                if (messageList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.borderColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Start a conversation',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: messageList.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the top (index 0)
                    if (index == 0 && _isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // Adjust index for loading indicator at top
                    final messageIndex = _isLoadingMore ? index - 1 : index;
                    final message = messageList[messageIndex];
                    final isCurrentUser = currentUser.maybeWhen(
                      data: (user) => message.senderId == user?.id,
                      orElse: () => false,
                    );

                    return ChatBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              ),
              error: (error, st) =>
                  Center(child: Text('Error loading messages: $error')),
            ),
          ),
          MessageInput(
            onSend: (message) {
              print('💬 onSend called with message: $message');
              ref.read(socketServiceProvider).whenData((socket) {
                if (socket != null) {
                  print('🔌 Sending via socket...');
                  socket.sendMessage(
                    widget.userId,
                    message,
                    recipientId: widget.userId,
                  );
                } else {
                  print('📡 Socket unavailable, sending via API...');
                  _sendMessageViaAPI(message);
                }
              });
            },
            onFileSelected: (file) {
              print('📎 File selected: ${file.name}');
              _handleFileShare(file);
            },
            onTyping: () {
              ref.read(socketServiceProvider).whenData((socket) {
                socket?.notifyTyping(widget.userId);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessageViaAPI(String message) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.sendMessage(
        widget.userId,
        message,
        type: 'text',
        isGroupChat: false,
        recipientId: widget.userId,
      );
      print('✅ Message sent via API');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message sent'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send message: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleFileShare(PlatformFile file) {
    print('📎 Handling file share: ${file.name}');
    _showFilePreviewDialog(file);
  }

  Future<void> _showFilePreviewDialog(PlatformFile file) async {
    final captionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📎 Send File'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(file.extension ?? ''),
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Caption input (optional)
              TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  hintText: 'Add a caption (optional)...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendFileWithCaption(file, captionController.text.trim());
            },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _sendFileWithCaption(PlatformFile file, String caption) async {
    // Show uploading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('📎 Uploading File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(file.name),
              Text(
                '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Send file via API
    _shareFileViaAPI(file, caption);
  }

  Future<void> _shareFileViaAPI(PlatformFile file, String caption) async {
    try {
      final api = ref.read(apiServiceProvider);

      // Check if file has bytes (required for actual upload)
      if (file.bytes == null || file.bytes!.isEmpty) {
        print('❌ File has no bytes data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Cannot read file data'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create form data with ACTUAL file bytes for Cloudinary upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
        'recipientId': widget.userId, // for private chats
        if (caption.isNotEmpty) 'caption': caption, // Add caption if provided
      });

      print('☁️ Uploading file to Cloudinary: ${file.name}');
      print(
        '📁 File size: ${file.size} bytes (${(file.size / 1024).toStringAsFixed(2)} KB)',
      );
      print('🔗 Recipient: ${widget.userId}');

      final message = await api.uploadFileToCloudinary(widget.userId, formData);

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ File "${file.name}" shared successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      print('✅ File uploaded successfully');
    } catch (e) {
      print('❌ Error uploading file: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to upload file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
