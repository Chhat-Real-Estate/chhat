import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  // NAYA: notification ke 'type' ke hisaab se sahi jagah navigate karo —
  // role SharedPreferences se pata karte hain (cached hai login ke waqt se).
  Future<void> _handleTap(BuildContext context, NotificationModel n,
      NotificationRepository repo) async {
    if (!n.read && n.id != null) {
      repo.markAsRead(n.id!, userId);
    }
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'tenant';
    if (!context.mounted) return;

    final isRequestRelated =
        n.type == 'new_request' || n.type.startsWith('request_');
    if (isRequestRelated) {
      // Requests tab dono home screens me index 2 pe hai.
      context.go('/$role-home', extra: 2);
    }
    // broadcast type ke liye kahin specific navigate nahi karna — yahin
    // rehte hain, notification already khuli hui hai.
  }

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
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Notifications load nahi ho payi.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () => (context as Element).markNeedsBuild(),
                      child: const Text('Retry')),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Koi notification nahi hai.'));
          }
          // NAYA: Organize — unread pehle, phir read (dono ke andar
          // naye-se-purane order preserve rehta hai).
          final sorted = [...items]..sort((a, b) {
              if (a.read == b.read) return 0;
              return a.read ? 1 : -1;
            });
          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = sorted[index];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  if (n.id != null) repo.deleteNotification(n.id!, userId);
                },
                child: ListTile(
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
                  onTap: () => _handleTap(context, n, repo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
