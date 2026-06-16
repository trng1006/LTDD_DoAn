import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/group_provider.dart';

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
      if (user == null) return;
      final provider = context.read<NotificationProvider>();
      provider.startPolling(user.id);
      provider.fetchNotifications(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<NotificationProvider>();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo (${provider.unreadCount})'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(user.id),
              child: const Text('Đã đọc hết'),
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
                  SizedBox(height: 220),
                  Center(child: Text('Chưa có thông báo nào.')),
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
    final color = _iconColor(notification.title);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? null : color.withValues(alpha: 0.06),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_iconFor(notification.title), color: color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
          ),
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
            if (notification.type == 'group_invite' && notification.data != null && notification.data!['groupId'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () async {
                      final groupId = notification.data!['groupId'].toString();
                      final userId = context.read<AuthProvider>().user?.id;
                      if (userId != null) {
                        await context.read<GroupProvider>().acceptInvite(groupId, userId);
                        provider.markAsRead(notification);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đồng ý tham gia nhóm')));
                        }
                      }
                    },
                    child: const Text('Đồng ý'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () async {
                      final reasonController = TextEditingController();
                      final reason = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Từ chối lời mời'),
                          content: TextField(
                            controller: reasonController,
                            decoration: const InputDecoration(hintText: 'Nhập lý do từ chối...'),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                            ElevatedButton(
                              onPressed: () {
                                if (reasonController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do')));
                                  return;
                                }
                                Navigator.pop(ctx, reasonController.text.trim());
                              },
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      );
                      if (reason != null && context.mounted) {
                        final groupId = notification.data!['groupId'].toString();
                        final userId = context.read<AuthProvider>().user?.id;
                        if (userId != null) {
                          await context.read<GroupProvider>().rejectInvite(groupId, userId, reason);
                          provider.markAsRead(notification);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối lời mời')));
                          }
                        }
                      }
                    },
                    child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 10, color: Colors.blue),
        onTap: () => provider.markAsRead(notification),
      ),
    );
  }

  IconData _iconFor(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('tham gia')) return Icons.person_add_alt_1;
    if (normalized.contains('duyệt')) return Icons.check_circle_outline;
    if (normalized.contains('từ chối')) return Icons.cancel_outlined;
    if (normalized.contains('đề tài')) return Icons.assignment_outlined;
    return Icons.notifications_none_rounded;
  }

  Color _iconColor(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('từ chối')) return Colors.red;
    if (normalized.contains('duyệt')) return Colors.green;
    if (normalized.contains('tham gia')) return Colors.orange;
    if (normalized.contains('đề tài')) return Colors.blue;
    return Colors.purple;
  }
}
