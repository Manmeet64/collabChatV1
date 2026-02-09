import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(PlatformFile)? onFileSelected;
  final Function()? onTyping;
  final bool isLoading;

  const MessageInput({
    Key? key,
    required this.onSend,
    this.onFileSelected,
    this.onTyping,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(() {
      setState(() {
        if (_controller.text.isNotEmpty && !_isTyping) {
          _isTyping = true;
          widget.onTyping?.call();
        } else if (_controller.text.isEmpty && _isTyping) {
          _isTyping = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          // File picker button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () async {
              try {
                print('📎 Opening file picker...');
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  print('📎 File selected: ${file.name} (${file.size} bytes)');
                  widget.onFileSelected?.call(file);
                } else {
                  print('📎 File picker cancelled');
                }
              } catch (e) {
                print('❌ Error picking file: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Attach file',
            color: AppTheme.primaryColor,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _controller.text.isEmpty
                  ? AppTheme.borderColor
                  : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              color: Colors.white,
              onPressed: _controller.text.isEmpty || widget.isLoading
                  ? null
                  : () {
                      print('📤 Sending message: ${_controller.text}');
                      widget.onSend(_controller.text);
                      _controller.clear();
                      _isTyping = false;
                    },
            ),
          ),
        ],
      ),
    );
  }
}
