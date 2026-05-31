import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/models/group_model.dart';
import 'package:ungdungdangkinhomvachondetai/screens/topic/select_topic_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final currentGroup = groupProvider.groups.firstWhere(
      (g) => g.id == widget.group.id,
      orElse: () => widget.group,
    );

    final user = context.read<AuthProvider>().user;
    final isLeader = currentGroup.leaderId == user?.id;
    final bool isLocked = currentGroup.isLocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup.name),
        actions: [
          if (isLeader && !isLocked)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showSettings(context, currentGroup),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(currentGroup),
            const SizedBox(height: 16),
            _buildInfoSection(context, currentGroup),
            const SizedBox(height: 32),

            if (isLeader &&
                currentGroup.pendingMemberIds.isNotEmpty &&
                !isLocked) ...[
              _buildPendingRequestsSection(context, currentGroup),
              const SizedBox(height: 32),
            ],

            _buildMemberSection(context, currentGroup, isLeader, isLocked),
            const SizedBox(height: 32),

            if (isLeader && !isLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openSelectTopic(context, currentGroup),
                    icon: const Icon(Icons.assignment_turned_in_rounded),
                    label: Text(
                      currentGroup.topicId == null
                          ? 'Chọn đề tài'
                          : 'Đổi đề tài',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2F6BFF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),

            if (isLeader && !isLocked)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMemberDialog(context, currentGroup),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Thêm thành viên mới'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (!isLeader && !isLocked)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _showLeaveDialog(context),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Rời khỏi nhóm'),
                ),
              ),

            if (isLocked)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Nhóm đã chốt đề tài. Các tính năng chỉnh sửa đã bị khoá.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GroupModel group) {
    Color color = Colors.blue;
    String text = 'Đang tạo nhóm';
    if (group.status == 'pending_approval') {
      color = Colors.orange;
      text = 'Đang chờ duyệt đề tài';
    } else if (group.status == 'approved') {
      color = Colors.green;
      text = 'Đã chốt đề tài';
    } else if (group.status == 'rejected') {
      color = Colors.red;
      text = 'Đăng ký đề tài bị từ chối';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, GroupModel group) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin nhóm',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(group.description, style: const TextStyle(fontSize: 15)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sĩ số:'),
              Text(
                '${group.memberIds.length}/${group.maxMembers}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection(BuildContext context, GroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yêu cầu tham gia (Đang chờ)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 12),
        ...group.pendingMemberIds.map(
          (id) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_add)),
              title: Text('Sinh viên $id'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => context.read<GroupProvider>().acceptMember(
                      group.id,
                      id,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => context.read<GroupProvider>().rejectMember(
                      group.id,
                      id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSection(
    BuildContext context,
    GroupModel group,
    bool isLeader,
    bool isLocked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thành viên chính thức (${group.memberIds.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ...group.memberIds.map((id) {
          final isMe = context.read<AuthProvider>().user?.id == id;
          final isMemberLeader = id == group.leaderId;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isMemberLeader
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  isMemberLeader ? Icons.star_rounded : Icons.person_outline,
                  color: isMemberLeader ? Colors.orange : Colors.blue,
                ),
              ),
              title: Text('Sinh viên $id ${isMe ? '(Bạn)' : ''}'),
              subtitle: Text(isMemberLeader ? 'Trưởng nhóm' : 'Thành viên'),
              trailing: isLeader && !isMemberLeader && !isLocked
                  ? IconButton(
                      icon: const Icon(
                        Icons.person_remove_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmRemoveMember(context, group, id),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openSelectTopic(BuildContext context, GroupModel group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SelectTopicScreen(group: group)),
    );
    if (context.mounted) {
      context.read<GroupProvider>().fetchGroups();
    }
  }

  void _showSettings(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cài đặt nhóm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Thay đổi số lượng tối đa'),
              onTap: () {
                Navigator.pop(context);
                _showChangeSizeDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Giải tán nhóm',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteGroup(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeSizeDialog(BuildContext context, GroupModel group) {
    final controller = TextEditingController(text: group.maxMembers.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi số lượng'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số lượng tối đa'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSize = int.tryParse(controller.text) ?? group.maxMembers;
              context.read<GroupProvider>().updateGroupSize(group.id, newSize);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, GroupModel group) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Mã số sinh viên (MSSV)',
            hintText: 'Ví dụ: sv05',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<GroupProvider>().acceptMember(
                  group.id,
                  controller.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã thêm sinh viên ${controller.text} vào nhóm!',
                    ),
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá nhóm?'),
        content: const Text(
          'Hành động này không thể hoàn tác. Toàn bộ dữ liệu nhóm sẽ bị xoá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Xác nhận Xoá',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(
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
            child: const Text('Gỡ'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời nhóm'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn có chắc chắn muốn rời nhóm này?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lý do rời nhóm',
                  hintText: 'Vui lòng nhập lý do (Bắt buộc)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập lý do'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Xác nhận Rời',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
