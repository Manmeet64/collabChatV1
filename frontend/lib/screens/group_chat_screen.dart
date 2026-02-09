import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../constants/app_theme.dart';
import '../models/group_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../utils/extensions.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _previousMessageCount = 0;
  String? _chatId; // Store the actual chat ID from the group

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load group data first to get chatId, then join chat
    Future.microtask(() async {
      // Wait for groups to load
      final groupsAsync = ref.read(myGroupsProvider);
      await groupsAsync.whenOrNull(
        data: (groups) async {
          try {
            final group = groups.firstWhere((g) => g.id == widget.groupId);
            _chatId = group.chatId; // Get the actual chat document ID

            print('📱 [GROUP CHAT] Group: ${widget.groupId}');
            print('💬 [GROUP CHAT] Chat ID: $_chatId');

            // Use chatId if available, fallback to groupId
            final chatIdToUse = _chatId ?? widget.groupId;

            // Join chat via socket
            ref
                .read(socketServiceProvider)
                .whenData((socket) => socket?.joinChat(chatIdToUse));

            // Load messages and scroll to bottom
            ref.read(messagesProvider(chatIdToUse).notifier).refresh().then((
              _,
            ) {
              _scrollToBottom();
            });
          } catch (e) {
            print('⚠️ [GROUP CHAT] Group not found, using groupId: $e');
            // Fallback to groupId if group not found
            ref
                .read(socketServiceProvider)
                .whenData((socket) => socket?.joinChat(widget.groupId));
            ref.read(messagesProvider(widget.groupId).notifier).refresh().then((
              _,
            ) {
              _scrollToBottom();
            });
          }
        },
      );
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
    final chatIdToUse = _chatId ?? widget.groupId;
    setState(() => _isLoadingMore = true);
    await ref.read(messagesProvider(chatIdToUse).notifier).loadMoreMessages();
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final chatIdToUse = _chatId ?? widget.groupId;
    final messages = ref.watch(messagesProvider(chatIdToUse));
    final currentUser = ref.watch(currentUserProvider);
    final myGroups = ref.watch(myGroupsProvider);
    final typingUsers = ref.watch(typingUsersProvider);

    // Auto-scroll when new messages arrive
    messages.whenData((messageList) {
      if (messageList.length != _previousMessageCount) {
        _previousMessageCount = messageList.length;
        _scrollToBottom();
      }
    });

    // Find the group
    Group? group;
    myGroups.whenData((groups) {
      try {
        group = groups.firstWhere((g) => g.id == widget.groupId);
      } catch (e) {
        group = Group(
          id: widget.groupId,
          name: 'Group',
          members: [],
          adminId: '',
          createdAt: DateTime.now(),
        );
      }
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
            Text(group?.name ?? 'Group Chat'),
            if (group != null)
              Text(
                '${group!.members.length} members',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showGroupInfo(context, group);
            },
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
                          'No messages yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
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
                          senderName: !isCurrentUser
                              ? Text(
                                  message.sender?.username ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    if (typingUsers.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: AppTheme.backgroundColor,
                          child: Text(
                            '${typingUsers.join(", ")} ${typingUsers.length == 1 ? "is" : "are"} typing...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
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
              final chatIdToUse = _chatId ?? widget.groupId;
              ref
                  .read(socketServiceProvider)
                  .whenData(
                    (socket) => socket?.sendMessage(chatIdToUse, message),
                  );
            },
            onFileSelected: (file) {
              print('📎 File selected in group: ${file.name}');
              _handleFileShare(file);
            },
            onTyping: () {
              final chatIdToUse = _chatId ?? widget.groupId;
              ref
                  .read(socketServiceProvider)
                  .whenData((socket) => socket?.notifyTyping(chatIdToUse));
            },
          ),
        ],
      ),
    );
  }

  void _handleFileShare(PlatformFile file) {
    print('📎 Handling file share in group: ${file.name}');
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
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Cannot read file data'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create form data with file bytes for Cloudinary upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
        'groupId': widget.groupId, // for group chats
        if (caption.isNotEmpty) 'caption': caption,
      });

      print('☁️ Uploading file to Cloudinary: ${file.name}');
      print(
        '📁 File size: ${file.size} bytes (${(file.size / 1024).toStringAsFixed(2)} KB)',
      );
      final chatIdToUse = _chatId ?? widget.groupId;
      print('🔗 Chat ID: $chatIdToUse');

      await api.uploadFileToCloudinary(chatIdToUse, formData);

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
            content: Text('❌ Error uploading file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showGroupInfo(BuildContext context, Group? group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${group?.name ?? "N/A"}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Members: ${group?.members.length ?? 0}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${group?.createdAt.toFormattedDate() ?? "N/A"}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (group != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/group-members/${group.id}');
                },
                child: const Text('View Members'),
              ),
          ],
        ),
      ),
    );
  }
}
