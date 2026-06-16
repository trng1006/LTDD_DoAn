import os
import re

def update_group_detail(path):
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    old_func = """                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => context.read<GroupProvider>().rejectMember(
                      group.id,
                      id,
                    ),
                  ),"""
    
    new_func = """                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () async {
                      final reasonController = TextEditingController();
                      final reason = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Nhập lý do từ chối'),
                          content: TextField(
                            controller: reasonController,
                            decoration: const InputDecoration(hintText: 'Lý do từ chối...'),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (reasonController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng nhập lý do')),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx, reasonController.text.trim());
                              },
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      );

                      if (reason == null) return;
                      if (!context.mounted) return;

                      await context.read<GroupProvider>().rejectMember(
                        group.id,
                        id,
                        reason: reason,
                      );
                    },
                  ),"""
    
    content = content.replace(old_func, new_func)
    with open(path, 'w') as f:
        f.write(content)

update_group_detail('lib/screens/group/group_detail_screen.dart')
update_group_detail('lib/group/group_detail_screen.dart')
