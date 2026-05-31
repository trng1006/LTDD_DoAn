import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().startPolling(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<NotificationProvider>();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Chưa đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.unreadCount > 0
              ? 'Thông báo (${provider.unreadCount})'
              : 'Thông báo',
        ),
        actions: [
          if (provider.unreadCount > 0)
            IconButton(
              tooltip: 'Đánh dấu đã đọc',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: () => provider.markAllAsRead(user.id),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchNotifications(user.id),
        child: provider.isLoading && provider.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(child: Text('Chưa có thông báo nào')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return _notificationTile(context, provider, notification);
                },
              ),
      ),
    );
  }

  Widget _notificationTile(
    BuildContext context,
    NotificationProvider provider,
    NotificationModel notification,
  ) {
    final style = _styleFor(notification);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        onTap: () => provider.markAsRead(notification),
        leading: CircleAvatar(
          backgroundColor: style.color.withValues(alpha: 0.12),
          child: Icon(style.icon, color: style.color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 6),
            Text(
              _dateFormat.format(notification.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  _NotificationStyle _styleFor(NotificationModel notification) {
    switch (notification.type) {
      case 'join_request':
        return const _NotificationStyle(
          Icons.person_add_alt_1_rounded,
          Colors.orange,
        );
      case 'join_approved':
      case 'topic_approved':
        return const _NotificationStyle(
          Icons.check_circle_rounded,
          Colors.green,
        );
      case 'join_rejected':
      case 'topic_rejected':
        return const _NotificationStyle(Icons.cancel_rounded, Colors.red);
      case 'topic_registration':
        return const _NotificationStyle(
          Icons.assignment_turned_in_rounded,
          Colors.blue,
        );
      default:
        return const _NotificationStyle(
          Icons.notifications_rounded,
          Colors.purple,
        );
    }
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color color;

  const _NotificationStyle(this.icon, this.color);
}
