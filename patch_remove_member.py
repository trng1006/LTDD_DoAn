import os

def patch_file(path):
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    old_code = """  void _confirmRemoveMember(
    BuildContext context,
    GroupModel group,
    String memberId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ thành viên?'),
        content: Text(
          'Bạn có chắc chắn muốn gỡ Sinh viên $memberId khỏi nhóm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GroupProvider>().removeMember(group.id, memberId);
              Navigator.pop(context);
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }"""

    new_code = """  void _confirmRemoveMember(
    BuildContext context,
    GroupModel group,
    String memberId,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ thành viên?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn gỡ Sinh viên $memberId khỏi nhóm?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Nhập lý do...'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              context.read<GroupProvider>().removeMember(group.id, memberId, reason: reasonController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }"""

    content = content.replace(old_code, new_code)
    with open(path, 'w') as f:
        f.write(content)

patch_file('lib/screens/group/group_detail_screen.dart')
patch_file('lib/group/group_detail_screen.dart')
