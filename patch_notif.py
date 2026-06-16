import re

path = "lib/screens/notification/notification_screen.dart"
with open(path, "r") as f:
    content = f.read()

# Add import for GroupProvider
content = content.replace(
    "import '../../providers/notification_provider.dart';",
    "import '../../providers/notification_provider.dart';\nimport '../../providers/group_provider.dart';"
)

old_subtitle = """            Text(
              _dateFormat.format(notification.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),"""

new_subtitle = """            Text(
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
            ],"""

content = content.replace(old_subtitle, new_subtitle)

with open(path, "w") as f:
    f.write(content)
