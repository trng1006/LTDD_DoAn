import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/models/group_model.dart';
import 'package:ungdungdangkinhomvachondetai/models/topic_model.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/topic_provider.dart';
import 'package:ungdungdangkinhomvachondetai/screens/group/create_group_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/group/group_detail_screen.dart';

class ManageGroupScreen extends StatefulWidget {
  const ManageGroupScreen({super.key});

  @override
  State<ManageGroupScreen> createState() => _ManageGroupScreenState();
}

class _ManageGroupScreenState extends State<ManageGroupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (user.role == 'lecturer') {
      await context.read<TopicProvider>().fetchTopics(lecturerId: user.id);
      if (!mounted) return;
      await context.read<GroupProvider>().fetchGroups(lecturerId: user.id);
    } else {
      await context.read<GroupProvider>().fetchGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final groupProvider = context.watch<GroupProvider>();
    final topicProvider = context.watch<TopicProvider>();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.role == 'lecturer') {
      return _buildLecturerScreen(
        context,
        user.id,
        groupProvider,
        topicProvider,
      );
    }

    return _buildStudentScreen(context, user.id, groupProvider);
  }

  Widget _buildLecturerScreen(
    BuildContext context,
    String lecturerId,
    GroupProvider groupProvider,
    TopicProvider topicProvider,
  ) {
    final topicIds = topicProvider.topics
        .where((topic) => topic.lecturerId == lecturerId)
        .map((topic) => topic.id)
        .toSet();
    final groups =
        groupProvider.groups
            .where(
              (group) =>
                  group.topicId != null && topicIds.contains(group.topicId),
            )
            .toList()
          ..sort((a, b) {
            if (a.status == 'pending_approval' &&
                b.status != 'pending_approval') {
              return -1;
            }
            if (a.status != 'pending_approval' &&
                b.status == 'pending_approval') {
              return 1;
            }
            return a.name.compareTo(b.name);
          });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt nhóm đăng ký'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: groupProvider.isLoading && groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : groups.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text('Chưa có nhóm nào đăng ký đề tài của bạn.'),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final topic = _topicOf(topicProvider.topics, group.topicId);
                  return _lecturerGroupCard(context, group, topic, lecturerId);
                },
              ),
      ),
    );
  }

  Widget _lecturerGroupCard(
    BuildContext context,
    GroupModel group,
    TopicModel? topic,
    String lecturerId,
  ) {
    final style = _statusStyle(group.status);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: style.color.withValues(alpha: 0.12),
                child: Icon(style.icon, color: style.color),
              ),
              title: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic?.title ?? 'Không rõ đề tài'),
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberIds.length}/${group.maxMembers} thành viên - Trưởng nhóm: ${group.leaderId}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      style.label,
                      style: TextStyle(
                        color: style.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              ),
            ),
            if (group.status == 'pending_approval') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Duyệt'),
                      onPressed: () =>
                          _approveTopic(context, group.id, lecturerId),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Từ chối',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () =>
                          _rejectTopic(context, group.id, lecturerId),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentScreen(
    BuildContext context,
    String userId,
    GroupProvider groupProvider,
  ) {
    final myGroups = groupProvider.groups
        .where((group) => group.memberIds.contains(userId))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nhóm của tôi')),
      body: myGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa tham gia nhóm nào',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateGroupScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo nhóm mới'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myGroups.length,
              itemBuilder: (context, index) {
                final group = myGroups[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        group.name.isNotEmpty
                            ? group.name.substring(0, 1).toUpperCase()
                            : 'G',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(group.description),
                        const SizedBox(height: 4),
                        Text(
                          'Thành viên: ${group.memberIds.length}/${group.maxMembers}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: group.invitedMemberIds.contains(context.read<AuthProvider>().user?.id) 
                        ? const Text('Có lời mời', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                        : group.pendingMemberIds.contains(context.read<AuthProvider>().user?.id)
                            ? const Text('Đang chờ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(group: group),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: myGroups.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _approveTopic(
    BuildContext context,
    String groupId,
    String lecturerId,
  ) async {
    final error = await context.read<GroupProvider>().approveTopicRegistration(
      groupId,
      lecturerId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã duyệt đề tài cho nhóm.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _rejectTopic(
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
  }

  TopicModel? _topicOf(List<TopicModel> topics, String? topicId) {
    if (topicId == null) return null;
    try {
      return topics.firstWhere((topic) => topic.id == topicId);
    } catch (_) {
      return null;
    }
  }

  _GroupStatusStyle _statusStyle(String status) {
    switch (status) {
      case 'approved':
        return const _GroupStatusStyle(
          'Đã duyệt',
          Icons.check_circle_rounded,
          Colors.green,
        );
      case 'rejected':
        return const _GroupStatusStyle(
          'Đã từ chối',
          Icons.cancel_rounded,
          Colors.red,
        );
      case 'pending_approval':
        return const _GroupStatusStyle(
          'Chờ giảng viên duyệt',
          Icons.pending_actions_rounded,
          Colors.orange,
        );
      default:
        return const _GroupStatusStyle(
          'Đang tạo nhóm',
          Icons.groups_rounded,
          Colors.blue,
        );
    }
  }
}

class _GroupStatusStyle {
  final String label;
  final IconData icon;
  final Color color;

  const _GroupStatusStyle(this.label, this.icon, this.color);
}
