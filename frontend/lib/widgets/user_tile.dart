import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/user_model.dart';

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showOnlineStatus;

  const UserTile({
    Key? key,
    required this.user,
    required this.onTap,
    this.isSelected = false,
    this.showOnlineStatus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.backgroundColor : AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 0.5),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (showOnlineStatus)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: user.isOnline ? AppTheme.accentColor : AppTheme.dividerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.username,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: showOnlineStatus
            ? Text(
                user.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: user.isOnline ? AppTheme.accentColor : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppTheme.accentColor)
            : null,
      ),
    );
  }
}
