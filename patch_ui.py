import re

# 1. Update group_detail_screen.dart (Thêm thành viên -> inviteMember)
path_detail = "lib/screens/group/group_detail_screen.dart"
with open(path_detail, "r") as f:
    content = f.read()

content = content.replace(
    """                context.read<GroupProvider>().acceptMember(
                  group.id,
                  controller.text.trim(),
                );""",
    """                context.read<GroupProvider>().inviteMember(
                  group.id,
                  controller.text.trim(),
                );"""
)
content = content.replace(
    "'Đã thêm sinh viên ${controller.text} vào nhóm!'",
    "'Đã gửi lời mời tham gia nhóm đến sinh viên ${controller.text}!'"
)

# 2. Add Invitation Block for invited student
invitation_block = """
  Widget _buildInvitationSection(BuildContext context, GroupModel group) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lời mời tham gia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Text('Bạn đã được mời tham gia nhóm này. Bạn có muốn đồng ý không?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final reasonController = TextEditingController();
                    final reason = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Từ chối tham gia'),
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
                      final userId = context.read<AuthProvider>().user?.id;
                      if (userId != null) {
                        await context.read<GroupProvider>().rejectInvite(group.id, userId, reason);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final userId = context.read<AuthProvider>().user?.id;
                    if (userId != null) {
                      await context.read<GroupProvider>().acceptInvite(group.id, userId);
                    }
                  },
                  child: const Text('Đồng ý'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
"""

content = content.replace(
    "Widget _buildTopicSection",
    invitation_block + "\n  Widget _buildTopicSection"
)

build_body_logic = """    final isLeader = currentGroup.leaderId == user?.id;
    final isMember = currentGroup.memberIds.contains(user?.id);
    final isPending = currentGroup.pendingMemberIds.contains(user?.id);"""
new_build_body_logic = build_body_logic + "\n    final isInvited = currentGroup.invitedMemberIds.contains(user?.id);"
content = content.replace(build_body_logic, new_build_body_logic)

body_content = """        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopicSection"""
new_body_content = """        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isInvited) _buildInvitationSection(context, currentGroup),
            _buildTopicSection"""
content = content.replace(body_content, new_body_content)

with open(path_detail, "w") as f:
    f.write(content)

# Update the duplicate file as well
path_dup = "lib/group/group_detail_screen.dart"
with open(path_dup, "w") as f:
    f.write(content)

