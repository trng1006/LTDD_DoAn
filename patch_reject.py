import os
import re

def update_manage_group(path):
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    old_func = """  Future<void> _rejectTopic(
    BuildContext context,
    String groupId,
    String lecturerId,
  ) async {
    final error = await context.read<GroupProvider>().rejectTopicRegistration(
      groupId,
      lecturerId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã từ chối đăng ký đề tài.'),
        backgroundColor: error == null ? Colors.orange : Colors.red,
      ),
    );
  }"""
    
    new_func = """  Future<void> _rejectTopic(
    BuildContext context,
    String groupId,
    String lecturerId,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập lý do từ chối'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Lý do từ chối...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    if (!context.mounted) return;
    final error = await context.read<GroupProvider>().rejectTopicRegistration(
      groupId,
      lecturerId,
      reason: reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã từ chối đăng ký đề tài.'),
        backgroundColor: error == null ? Colors.orange : Colors.red,
      ),
    );
  }"""
    
    content = content.replace(old_func, new_func)
    with open(path, 'w') as f:
        f.write(content)

update_manage_group('lib/screens/group/manage_group_screen.dart')
update_manage_group('lib/group/manage_group_screen.dart')
