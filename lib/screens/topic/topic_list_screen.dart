import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/topic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';
import '../group/group_detail_screen.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  String _searchQuery = '';
  String _sortBy = 'Tiêu đề';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final topicProvider = context.watch<TopicProvider>();
    final user = context.read<AuthProvider>().user;
    
    final bool isLecturer = user?.role == 'lecturer';
    final bool isAdmin = user?.role == 'admin';

    List<TopicModel> displayTopics = topicProvider.topics.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                          t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      if (isLecturer) return matchesSearch && t.lecturerId == user?.id;
      return matchesSearch;
    }).toList();

    if (_sortBy == 'Số lượng nhóm') {
      displayTopics.sort((a, b) => b.currentGroups.compareTo(a.currentGroups));
    } else {
      displayTopics.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isLecturer ? 'Đề tài của tôi' : (isAdmin ? 'Tất cả đề tài' : 'Danh sách đề tài')),
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
          _buildSearchAndFilter(),
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
                          return _buildTopicCard(context, topic, isLecturer, isAdmin);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm đề tài...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sắp xếp theo: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Tiêu đề'),
                selected: _sortBy == 'Tiêu đề',
                onSelected: (val) => setState(() => _sortBy = 'Tiêu đề'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Số lượng nhóm'),
                selected: _sortBy == 'Số lượng nhóm',
                onSelected: (val) => setState(() => _sortBy = 'Số lượng nhóm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, TopicModel topic, bool isLecturer, bool isAdmin) {
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  if (isLecturer || isAdmin)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                        const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') _showAddEditTopic(context, topic: topic);
                        if (val == 'delete') context.read<TopicProvider>().deleteTopic(topic.id);
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
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
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
                      Icon(Icons.people_outline, size: 18, color: isFull ? Colors.red : Colors.green),
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
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopicDetails(BuildContext context, TopicModel topic, bool canManage) {
    final groupProvider = context.read<GroupProvider>();
    final user = context.read<AuthProvider>().user;
    final now = DateTime.now();
    
    final bool isStarted = now.isAfter(topic.startTime);
    final bool isEnded = now.isAfter(topic.endTime);
    final bool isOpen = isStarted && !isEnded;

    final myGroup = groupProvider.groups.firstWhere(
      (g) => g.leaderId == user?.id, 
      orElse: () => GroupModel(id: '', name: '', description: '', maxMembers: 0, memberIds: [], pendingMemberIds: [], leaderId: '')
    );

    final bool canRegister = myGroup.id.isNotEmpty && !myGroup.isLocked;
    const int minMembers = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 8),
              Text('Giảng viên: ${topic.lecturerId}', style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    _timeRow(Icons.play_circle_outline, 'Bắt đầu:', _dateFormat.format(topic.startTime)),
                    const SizedBox(height: 4),
                    _timeRow(Icons.stop_circle, 'Kết thúc:', _dateFormat.format(topic.endTime)),
                  ],
                ),
              ),
              const Divider(height: 32),
              const Text('Mô tả chi tiết:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(topic.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 32),
              
              if (!canManage) ...[
                if (!isOpen)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      isEnded ? 'Thời gian đăng ký đã kết thúc.' : 'Thời gian đăng ký chưa bắt đầu (Mở lúc ${_dateFormat.format(topic.startTime)}).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (canRegister) ...[
                  if (myGroup.memberIds.length < minMembers)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'Cần tối thiểu $minMembers thành viên để đăng ký đề tài (Hiện có ${myGroup.memberIds.length}).',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: topic.currentGroups < topic.maxGroups ? () {
                          context.read<GroupProvider>().updateGroupStatus(myGroup.id, 'pending_approval');
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu đăng ký đề tài! Chờ giảng viên duyệt.')));
                        } : null,
                        child: Text(topic.currentGroups < topic.maxGroups ? 'Đăng ký đề tài này' : 'Đã đủ số lượng nhóm'),
                      ),
                    ),
                ] else
                  const Center(child: Text('Bạn phải là trưởng nhóm để đăng ký đề tài.', style: TextStyle(fontStyle: FontStyle.italic))),
              ],
              
              if (canManage) ...[
                const Text('Danh sách nhóm đăng ký:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                ...groupProvider.groups.where((g) => g.topicId == topic.id || (topic.id == 't1' && g.id == 'g1') || (topic.id == 't2' && g.id == 'g2')).map((g) => _buildGroupActionItem(context, g, topic.id)),
              ]
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(time, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGroupActionItem(BuildContext context, GroupModel group, String topicId) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.groups)),
      title: Text(group.name),
      subtitle: Text(group.status == 'approved' ? 'Đã duyệt' : 'Chờ duyệt'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)));
      },
      trailing: group.status == 'pending_approval' 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<GroupProvider>().updateGroupStatus(group.id, 'approved', isLocked: true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt đề tài cho nhóm!')));
                }, 
                child: const Text('Duyệt')
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  context.read<GroupProvider>().updateGroupStatus(group.id, 'creating');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối đăng ký.')));
                }, 
                child: const Text('Từ chối', style: TextStyle(color: Colors.red))
              ),
            ],
          )
        : const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  void _showAddEditTopic(BuildContext context, {TopicModel? topic}) {
    final titleController = TextEditingController(text: topic?.title);
    final descController = TextEditingController(text: topic?.description);
    final maxController = TextEditingController(text: topic?.maxGroups.toString() ?? '3');
    
    DateTime startTime = topic?.startTime ?? DateTime.now();
    DateTime endTime = topic?.endTime ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(topic == null ? 'Thêm đề tài mới' : 'Chỉnh sửa đề tài'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tên đề tài')),
                const SizedBox(height: 8),
                TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Mô tả')),
                const SizedBox(height: 8),
                TextField(controller: maxController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số nhóm tối đa')),
                const SizedBox(height: 16),
                const Text('Lịch đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _datePickerTile(context, 'Bắt đầu', startTime, (date) => setStateDialog(() => startTime = date)),
                _datePickerTile(context, 'Kết thúc', endTime, (date) => setStateDialog(() => endTime = date)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () {
                final newTopic = TopicModel(
                  id: topic?.id ?? 't${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text,
                  description: descController.text,
                  maxGroups: int.parse(maxController.text),
                  lecturerId: context.read<AuthProvider>().user?.id ?? 'admin',
                  startTime: startTime,
                  endTime: endTime,
                  currentGroups: topic?.currentGroups ?? 0,
                );
                
                if (topic == null) {
                  context.read<TopicProvider>().addTopic(newTopic);
                } else {
                  context.read<TopicProvider>().updateTopic(newTopic);
                }
                Navigator.pop(context);
              }, 
              child: const Text('Lưu')
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerTile(BuildContext context, String label, DateTime date, Function(DateTime) onPicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$label: ${_dateFormat.format(date)}', style: const TextStyle(fontSize: 13)),
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
            onPicked(DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ));
          }
        }
      },
    );
  }
}
