import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/message_model.dart';
import '../utils/extensions.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Widget? senderName;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.senderName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (senderName != null && !isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: senderName,
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display file if it's a file message with URL
                if (message.type == 'file' && message.fileUrl != null) ...[
                  _buildFileContent(context),
                  const SizedBox(height: 8),
                ] else
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  message.createdAt.toFormattedTime(),
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.7)
                        : AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    final fileType = message.fileType ?? '';
    final fileName = message.fileName ?? 'File';
    final fileSize = message.fileSize ?? 0;
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
    final caption = message.content;
    final hasCaption = caption.isNotEmpty && !caption.startsWith('File:');

    // Check if it's an image
    if (fileType.startsWith('image/')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.fileUrl!,
              fit: BoxFit.cover,
              width: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50),
                );
              },
            ),
          ),
          if (hasCaption) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            fileName,
            style: TextStyle(
              color: isCurrentUser ? Colors.white70 : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // For other files, show download button
    return InkWell(
      onTap: () {
        // Open file in browser
        // In production, you'd use url_launcher package
        print('Download file: ${message.fileUrl}');
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(fileType),
              color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
              size: 32,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$fileSizeKB KB',
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download,
              color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.startsWith('image/')) return Icons.image;
    if (fileType.startsWith('video/')) return Icons.video_file;
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('word') || fileType.contains('document')) {
      return Icons.description;
    }
    if (fileType.contains('text')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }
}
