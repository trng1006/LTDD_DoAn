import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/topic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../group/group_detail_screen.dart';
import '../../providers/course_provider.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  String _searchQuery = '';
  String _sortBy = 'Tiêu đề';
  String? _selectedCourseId;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadData();
      final sel = context.read<CourseProvider>().selectedCourseId;
      if (sel != null && sel.isNotEmpty) {
        setState(() => _selectedCourseId = sel);
      }
    });
  }

  Future<void> _reloadData() async {
    final user = context.read<AuthProvider>().user;
    await context.read<CourseProvider>().fetchAllData();
    if (!mounted) return;
    if (user?.role == 'lecturer') {
      await context.read<TopicProvider>().fetchTopics(lecturerId: user!.id);
      if (!mounted) return;
      await context.read<GroupProvider>().fetchGroups(lecturerId: user.id);
    } else {
      await context.read<TopicProvider>().fetchTopics();
      if (!mounted) return;
      await context.read<GroupProvider>().fetchGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicProvider = context.watch<TopicProvider>();
    final authProvider = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final user = authProvider.user;

    final bool isLecturer = user?.role == 'lecturer';
    final bool isAdmin = user?.role == 'admin';
    final bool isStudent = user?.role == 'student';

    List<TopicModel> displayTopics = topicProvider.topics.where((t) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);

      final hasCourseFilter =
          _selectedCourseId != null && _selectedCourseId != 'all';
      final matchesCourse = !hasCourseFilter || t.courseId == _selectedCourseId;

      if (isLecturer && user != null) {
        return matchesSearch && matchesCourse && t.lecturerId == user.id;
      }
      if (isStudent && user != null) {
        return matchesSearch &&
            matchesCourse &&
            user.enrolledCourseIds.contains(t.courseId);
      }

      return matchesSearch && matchesCourse;
    }).toList();

    if (_sortBy == 'Số lượng nhóm') {
      displayTopics.sort((a, b) => b.currentGroups.compareTo(a.currentGroups));
    } else {
      displayTopics.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLecturer
              ? 'Đề tài của tôi (${displayTopics.length})'
              : (isAdmin
                  ? 'Tất cả đề tài (${displayTopics.length})'
                  : 'Danh sách đề tài (${displayTopics.length})'),
        ),
        actions: [
          if (isLecturer || isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddEditTopic(context),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(courseProvider, user),
          Expanded(
            child: topicProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayTopics.isEmpty
                ? const Center(child: Text('Không tìm thấy đề tài nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayTopics.length,
                    itemBuilder: (context, index) {
                      final topic = displayTopics[index];
                      return _buildTopicCard(
                        context,
                        topic,
                        isLecturer,
                        isAdmin,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(CourseProvider courseProvider, UserModel? user) {
    final courses = courseProvider.courses;

    List<CourseModel> relevantCourses;
    if (user != null && user.role == 'student') {
      relevantCourses = courses
          .where((c) => user.enrolledCourseIds.contains(c.id))
          .toList();
    } else if (user != null && user.role == 'lecturer') {
      relevantCourses = courses
          .where((c) => user.taughtCourseIds.contains(c.id))
          .toList();
    } else {
      relevantCourses = courses;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm đề tài...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedCourseId ?? 'all',
                  decoration: const InputDecoration(
                    labelText: 'Môn học',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả môn học'),
                    ),
                    ...relevantCourses.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedCourseId = val),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: _sortBy,
                icon: const Icon(Icons.sort),
                onSelected: (val) => setState(() => _sortBy = val),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Tiêu đề',
                    child: Text('Sắp xếp theo Tiêu đề'),
                  ),
                  const PopupMenuItem(
                    value: 'Số lượng nhóm',
                    child: Text('Sắp xếp theo Số lượng nhóm'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    TopicModel topic,
    bool isLecturer,
    bool isAdmin,
  ) {
    final now = DateTime.now();
    final bool isStarted = now.isAfter(topic.startTime);
    final bool isEnded = now.isAfter(topic.endTime);
    final bool isFull = topic.currentGroups >= topic.maxGroups;

    Color statusColor = Colors.green;
    String statusText = 'Đang mở';

    if (!isStarted) {
      statusColor = Colors.orange;
      statusText = 'Chưa bắt đầu';
    } else if (isEnded) {
      statusColor = Colors.red;
      statusText = 'Đã kết thúc';
    } else if (isFull) {
      statusColor = Colors.grey;
      statusText = 'Đã đầy';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTopicDetails(context, topic, isLecturer || isAdmin),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (isLecturer || isAdmin)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Chỉnh sửa'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xoá'),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showAddEditTopic(context, topic: topic);
                        }
                        if (val == 'delete') {
                          context.read<TopicProvider>().deleteTopic(topic.id);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                topic.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Hạn: ${DateFormat('dd/MM').format(topic.endTime)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 18,
                        color: isFull ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${topic.currentGroups}/${topic.maxGroups} nhóm',
                        style: TextStyle(
                          color: isFull ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    Text(
                      'GV: ${topic.lecturerId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopicDetails(
    BuildContext context,
    TopicModel topic,
    bool canManage,
  ) {
    final groupProvider = context.read<GroupProvider>();
    final user = context.read<AuthProvider>().user;
    final now = DateTime.now();

    final bool isStarted = now.isAfter(topic.startTime);
    final bool isEnded = now.isAfter(topic.endTime);
    final bool isOpen = isStarted && !isEnded;

    GroupModel? myGroup;
    try {
       myGroup = groupProvider.groups.firstWhere(
        (g) => g.leaderId == user?.id && g.courseId == topic.courseId,
      );
    } catch (_) {
       myGroup = null;
    }

    final bool canRegister = myGroup != null && !myGroup.isLocked;
    final int minMembers = myGroup?.minMembers ?? 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Giảng viên: ${topic.lecturerId}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _timeRow(
                      Icons.play_circle_outline,
                      'Bắt đầu:',
                      _dateFormat.format(topic.startTime),
                    ),
                    const SizedBox(height: 4),
                    _timeRow(
                      Icons.stop_circle,
                      'Kết thúc:',
                      _dateFormat.format(topic.endTime),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Mô tả chi tiết:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                topic.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),

              if (!canManage) ...[
                if (!isOpen)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isEnded
                          ? 'Thời gian đăng ký đã kết thúc.'
                          : 'Thời gian đăng ký chưa bắt đầu (Mở lúc ${_dateFormat.format(topic.startTime)}).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (canRegister) ...[
                  if (myGroup!.memberIds.length < minMembers)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cần tối thiểu $minMembers thành viên để đăng ký đề tài (Hiện có ${myGroup.memberIds.length}).',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: topic.currentGroups < topic.maxGroups
                            ? () async {
                                final error = await context
                                    .read<GroupProvider>()
                                    .registerTopic(
                                      myGroup!.id,
                                      topic.id,
                                      user?.id ?? '',
                                    );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error ??
                                          'Đã gửi yêu cầu đăng ký đề tài! Chờ giảng viên duyệt.',
                                    ),
                                    backgroundColor: error == null
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          topic.currentGroups < topic.maxGroups
                              ? 'Đăng ký đề tài này'
                              : 'Đã đủ số lượng nhóm',
                        ),
                      ),
                    ),
                ] else
                  Center(
                    child: Text(
                      myGroup != null && myGroup.isLocked 
                        ? 'Nhóm đã chốt đề tài, không thể thay đổi.' 
                        : 'Bạn phải là trưởng nhóm để đăng ký đề tài.',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],

              if (canManage) ...[
                const Text(
                  'Danh sách nhóm đăng ký:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ...groupProvider.groups
                    .where((g) => g.topicId == topic.id)
                    .map((g) => _buildGroupActionItem(context, g, topic.id)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeRow(IconData icon, String label, String time) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(time, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGroupActionItem(
    BuildContext context,
    GroupModel group,
    String topicId,
  ) {
    final lecturerId = context.read<AuthProvider>().user?.id ?? '';
    final statusText = switch (group.status) {
      'approved' => 'Đã duyệt',
      'rejected' => 'Đã từ chối',
      'pending_approval' => 'Chờ duyệt',
      _ => 'Đang tạo nhóm',
    };
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.groups)),
      title: Text(group.name),
      subtitle: Text(statusText),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(group: group),
          ),
        );
      },
      trailing: group.status == 'pending_approval'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final error = await context
                        .read<GroupProvider>()
                        .approveTopicRegistration(group.id, lecturerId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Đã duyệt đề tài cho nhóm!'),
                        backgroundColor: error == null
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  },
                  child: const Text('Duyệt'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final error = await context
                        .read<GroupProvider>()
                        .rejectTopicRegistration(group.id, lecturerId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Đã từ chối đăng ký.'),
                        backgroundColor: error == null
                            ? Colors.orange
                            : Colors.red,
                      ),
                    );
                  },
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          : Icon(
              group.status == 'rejected' ? Icons.cancel : Icons.check_circle,
              color: group.status == 'rejected' ? Colors.red : Colors.green,
            ),
    );
  }

  void _showAddEditTopic(BuildContext context, {TopicModel? topic}) {
    final titleController = TextEditingController(text: topic?.title);
    final descController = TextEditingController(text: topic?.description);
    final maxController = TextEditingController(
      text: topic?.maxGroups.toString() ?? '3',
    );
    String? dialogSelectedCourseId = topic?.courseId;

    DateTime startTime = topic?.startTime ?? DateTime.now();
    DateTime endTime =
        topic?.endTime ?? DateTime.now().add(const Duration(days: 30));

    final currentUser = context.read<AuthProvider>().user;
    final allCourses = context.read<CourseProvider>().courses;
    final courses = currentUser?.role == 'lecturer'
        ? allCourses
              .where(
                (course) => currentUser!.taughtCourseIds.contains(course.id),
              )
              .toList()
        : allCourses;
    if (dialogSelectedCourseId == null && courses.length == 1) {
      dialogSelectedCourseId = courses.first.id;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(topic == null ? 'Thêm đề tài mới' : 'Chỉnh sửa đề tài'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (courses.isEmpty)
                    const Text(
                      'Tài khoản này chưa được phân công môn học.',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          courses.any((c) => c.id == dialogSelectedCourseId)
                          ? dialogSelectedCourseId
                          : null,
                      decoration: const InputDecoration(labelText: 'Môn học'),
                      items: courses
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setStateDialog(() => dialogSelectedCourseId = val),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tên đề tài'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số nhóm tối đa',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lịch đăng ký:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _datePickerTile(
                    context,
                    'Bắt đầu',
                    startTime,
                    (date) => setStateDialog(() => startTime = date),
                  ),
                  _datePickerTile(
                    context,
                    'Kết thúc',
                    endTime,
                    (date) => setStateDialog(() => endTime = date),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dialogSelectedCourseId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn môn học')),
                  );
                  return;
                }
                final title = titleController.text.trim();
                final maxGroups = int.tryParse(maxController.text.trim());
                if (title.isEmpty || maxGroups == null || maxGroups < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vui lòng nhập tên đề tài và số nhóm hợp lệ',
                      ),
                    ),
                  );
                  return;
                }
                final newTopic = TopicModel(
                  id: topic?.id ?? 't${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  description: descController.text.trim(),
                  courseId: dialogSelectedCourseId!,
                  maxGroups: maxGroups,
                  lecturerId: topic?.lecturerId ?? currentUser?.id ?? 'admin',
                  startTime: startTime,
                  endTime: endTime,
                  currentGroups: topic?.currentGroups ?? 0,
                );

                final topicProvider = context.read<TopicProvider>();
                final lecturerFilter = currentUser?.role == 'lecturer'
                    ? currentUser?.id
                    : null;
                final success = topic == null
                    ? await topicProvider.addTopic(
                        newTopic,
                        lecturerId: lecturerFilter,
                      )
                    : await topicProvider.updateTopic(
                        newTopic,
                        lecturerId: lecturerFilter,
                      );
                if (!context.mounted) return;
                if (topic == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Đã thêm đề tài.' : 'Không lưu được đề tài.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Đã cập nhật đề tài.'
                            : 'Không lưu được đề tài.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
                if (success) Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerTile(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onPicked,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '$label: ${_dateFormat.format(date)}',
        style: const TextStyle(fontSize: 13),
      ),
      trailing: const Icon(Icons.calendar_today, size: 18),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null) {
          if (!context.mounted) return;
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
          );
          if (pickedTime != null) {
            onPicked(
              DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              ),
            );
          }
        }
      },
    );
  }
}
