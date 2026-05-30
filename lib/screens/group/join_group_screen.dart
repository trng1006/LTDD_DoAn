import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_dialog.dart';
import '../../models/course_model.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/group_provider.dart';

class JoinGroupScreen extends StatefulWidget {
  final String? initialCourseId;
  const JoinGroupScreen({super.key, this.initialCourseId});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _searchController = TextEditingController();
  String? _selectedCourseId;
  List<GroupModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  final Set<String> _pendingRequests = {};

  @override
  void initState() {
    super.initState();
    // Ưu tiên lớp được truyền sang; nếu không thì chọn lớp đầu tiên SV đang học.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final initial = widget.initialCourseId ??
          (user != null && user.enrolledCourseIds.isNotEmpty
              ? user.enrolledCourseIds.first
              : null);
      if (initial != null) {
        setState(() => _selectedCourseId = initial);
        _loadGroups();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    final groups = await context.read<GroupProvider>().searchGroups(
          courseId: _selectedCourseId,
          search: _searchController.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _results = groups;
      _isLoading = false;
    });
  }

  Future<void> _join(GroupModel group) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Chặn sớm ở client: nếu đã ở nhóm nào trong môn đang xem thì hiện popup.
    final provider = context.read<GroupProvider>();
    if (_selectedCourseId != null &&
        provider.groupOfUserInCourse(user.id, _selectedCourseId!) != null) {
      showAlreadyInGroupDialog(context);
      return;
    }

    setState(() => _pendingRequests.add(group.id));

    final error = await provider.requestToJoin(group.id, user.id);
    if (!mounted) return;
    setState(() => _pendingRequests.remove(group.id));

    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu gia nhập!'), backgroundColor: Colors.green),
      );
      _loadGroups(); // làm mới để hiển thị trạng thái "Đang chờ"
    } else if (error.contains('nhóm khác') || error.contains('1 nhóm')) {
      // Lỗi vi phạm ràng buộc "mỗi SV 1 nhóm" -> hiện popup nổi bật.
      showAlreadyInGroupDialog(context, message: error);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final allCourses = context.watch<CourseProvider>().courses;
    final enrolledCourses =
        allCourses.where((c) => user?.enrolledCourseIds.contains(c.id) ?? false).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tham gia nhóm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Môn học',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  items: enrolledCourses
                      .map((CourseModel c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCourseId = value);
                    _loadGroups();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm theo tên nhóm',
                    hintText: 'Nhập tên nhóm...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _loadGroups,
                    ),
                  ),
                  onSubmitted: (_) => _loadGroups(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults(user?.id ?? '')),
        ],
      ),
    );
  }

  Widget _buildResults(String userId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return const Center(child: Text('Chọn môn học để xem các nhóm.'));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('Không tìm thấy nhóm nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final group = _results[index];
        final bool isMember = group.memberIds.contains(userId);
        final bool isPending =
            group.pendingMemberIds.contains(userId) || _pendingRequests.contains(group.id);
        final bool isFull = group.memberIds.length >= group.maxMembers;
        final bool isProcessing = _pendingRequests.contains(group.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.groups_rounded, color: Colors.blue),
            ),
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${group.memberIds.length}/${group.maxMembers} thành viên • Trưởng: ${group.leaderId}',
            ),
            trailing: _buildTrailing(
              group: group,
              isMember: isMember,
              isPending: isPending,
              isFull: isFull,
              isProcessing: isProcessing,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrailing({
    required GroupModel group,
    required bool isMember,
    required bool isPending,
    required bool isFull,
    required bool isProcessing,
  }) {
    if (isProcessing) {
      return const SizedBox(
        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (isMember) {
      return const Text('Đã ở trong nhóm', style: TextStyle(color: Colors.green));
    }
    if (isPending) {
      return const Text('Đang chờ duyệt', style: TextStyle(color: Colors.orange));
    }
    if (isFull) {
      return const Text('Đã đầy', style: TextStyle(color: Colors.grey));
    }
    return ElevatedButton(
      onPressed: () => _join(group),
      child: const Text('Gia nhập'),
    );
  }
}
