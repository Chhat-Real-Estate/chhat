import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final repo = NotificationRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => repo.markAllAsRead(userId),
            child: const Text('Sab read karo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: repo.watchNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Notifications load nahi ho payi.'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Koi notification nahi hai.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = items[index];
              return ListTile(
                tileColor: n.read ? null : Colors.green.withOpacity(0.06),
                leading: Icon(
                  n.read
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: n.read ? Colors.grey : Colors.green,
                ),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(
                    '${n.body}\n${DateFormat('dd MMM, hh:mm a').format(n.createdAt)}'),
                isThreeLine: true,
                onTap: () {
                  if (!n.read && n.id != null) {
                    repo.markAsRead(n.id!, userId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
