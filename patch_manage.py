import re

path = "lib/screens/group/manage_group_screen.dart"
with open(path, "r") as f:
    content = f.read()

trailing_logic = """                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),"""
new_trailing_logic = """                    trailing: group.invitedMemberIds.contains(context.read<AuthProvider>().user?.id) 
                        ? const Text('Có lời mời', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                        : group.pendingMemberIds.contains(context.read<AuthProvider>().user?.id)
                            ? const Text('Đang chờ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                            : const Icon(Icons.arrow_forward_ios, size: 16),"""

content = content.replace(trailing_logic, new_trailing_logic)

with open(path, "w") as f:
    f.write(content)

path_dup = "lib/group/manage_group_screen.dart"
with open(path_dup, "w") as f:
    f.write(content)
