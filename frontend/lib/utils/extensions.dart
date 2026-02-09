import 'package:intl/intl.dart';

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String truncate(int length, {String suffix = '...'}) {
    if (this.length <= length) return this;
    return substring(0, length) + suffix;
  }
}

extension DateTimeExtensions on DateTime {
  String toFormattedTime() {
    return DateFormat('HH:mm').format(this);
  }

  String toFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  String toFormattedDateTime() {
    return DateFormat('MMM dd, yyyy HH:mm').format(this);
  }

  bool isToday() {
    final now = DateTime.now();
    return year == now.year &&
        month == now.month &&
        day == now.day;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (isToday()) {
      return toFormattedTime();
    } else if (isYesterday()) {
      return 'yesterday';
    } else {
      return toFormattedDate();
    }
  }
}
