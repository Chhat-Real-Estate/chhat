import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/notification_repository.dart';

/// Reusable bell icon with unread-count badge. Kisi bhi AppBar ke
/// `actions:` list mein daal do — [userId] pass karna zaroori hai.
class NotificationBellIcon extends StatelessWidget {
  final String userId;
  const NotificationBellIcon({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationRepository().watchUnreadCount(userId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return IconButton(
          icon: Badge(
            label: Text('$unread'),
            isLabelVisible: unread > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => context.push('/notifications', extra: userId),
        );
      },
    );
  }
}
