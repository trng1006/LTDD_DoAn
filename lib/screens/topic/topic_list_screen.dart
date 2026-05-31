import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  // Bảng màu + icon Lucide gán luân phiên cho từng đề tài để giống mẫu.
  static const List<IconData> _topicIcons = [
    LucideIcons.shoppingCart,
    LucideIcons.graduationCap,
    LucideIcons.clipboardList,
    LucideIcons.house,
    LucideIcons.plane,
    LucideIcons.chartColumnBig,
  ];

  @override
  void initState() {
    super.initState();
    // Tự động focus theo lớp đang được chọn bên ngoài (CourseProvider).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sel = context.read<CourseProvider>().selectedCourseId;
      if (sel != null && sel.isNotEmpty) {
        setState(() => _selectedCourseId = sel);
      }
    });
  }

  /// Đề tài "khả dụng": đang trong thời gian đăng ký và còn chỗ cho nhóm.
  bool _isAvailable(TopicModel t) {
    final now = DateTime.now();
    final bool open = now.isAfter(t.startTime) && now.isBefore(t.endTime);
    return open && t.currentGroups < t.maxGroups;
  }

  @override
  Widget build(BuildContext context) {
    final topicProvider = context.watch<TopicProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final bool isLecturer = user?.role == 'lecturer';
    final bool isAdmin = user?.role == 'admin';
    final bool isStudent = user?.role == 'student';

    // Lọc theo môn học + quyền xem (bỏ qua từ khoá tìm kiếm) -> dùng cho badge đếm.
    bool inScope(TopicModel t) {
      if (_selectedCourseId != null && _selectedCourseId != 'all') {
        return t.courseId == _selectedCourseId;
      }
      if (isStudent && user != null) {
        return user.enrolledCourseIds.contains(t.courseId);
      }
      if (isLecturer && user != null) {
        return user.taughtCourseIds.contains(t.courseId) || t.lecturerId == user.id;
      }
      return true; // admin: tất cả
    }

    final List<TopicModel> courseScoped =
        topicProvider.topics.where(inScope).toList();

    // Danh sách hiển thị = courseScoped + lọc theo từ khoá + sắp xếp.
    final String q = _searchQuery.toLowerCase();
    List<TopicModel> displayTopics = courseScoped
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();

    if (_sortBy == 'Số lượng nhóm') {
      displayTopics.sort((a, b) => b.currentGroups.compareTo(a.currentGroups));
    } else {
      displayTopics.sort((a, b) => a.title.compareTo(b.title));
    }

    final int totalCount = courseScoped.length;
    final int availableCount = courseScoped.where(_isAvailable).length;

    final String title =
        isLecturer ? 'Đề tài của tôi' : (isAdmin ? 'Tất cả đề tài' : 'Danh sách đề tài');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(context, title, isLecturer || isAdmin),
          Expanded(
            child: topicProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      _buildCourseCard(context, user),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildSectionTitle(availableCount, totalCount),
                      const SizedBox(height: 12),
                      if (displayTopics.isEmpty)
                        _buildEmptyState()
                      else
                        ...List.generate(displayTopics.length, (index) {
                          final topic = displayTopics[index];
                          return _buildTopicCard(
                              context, topic, index, isLecturer, isAdmin);
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Tên môn đang chọn để hiển thị trên thẻ "Môn học hiện tại".
  String _currentCourseName(BuildContext context) {
    if (_selectedCourseId == null || _selectedCourseId == 'all') {
      return 'Tất cả môn học';
    }
    return context.read<CourseProvider>().getCourseById(_selectedCourseId!)?.name ??
        'Chưa rõ môn học';
  }

  /// Thẻ "Môn học hiện tại" + nút "Đổi môn" như mẫu.
  Widget _buildCourseCard(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.bookMarked, color: Color(0xFF2F6BFF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Môn học hiện tại',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  _currentCourseName(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _changeCourse(context, user),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Đổi môn',
                      style: TextStyle(
                          color: Color(0xFF2F6BFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, color: Color(0xFF2F6BFF), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet chọn môn học giống mẫu.
  Future<void> _changeCourse(BuildContext context, UserModel? user) async {
    final courseProvider = context.read<CourseProvider>();
    List<CourseModel> courses;
    if (user != null && user.role == 'student') {
      courses = courseProvider.courses
          .where((c) => user.enrolledCourseIds.contains(c.id))
          .toList();
    } else if (user != null && user.role == 'lecturer') {
      courses = courseProvider.courses
          .where((c) => user.taughtCourseIds.contains(c.id))
          .toList();
    } else {
      courses = courseProvider.courses;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Chọn môn học',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(
                      (_selectedCourseId == null || _selectedCourseId == 'all')
                          ? LucideIcons.checkCheck
                          : LucideIcons.layers,
                      color: const Color(0xFF2F6BFF),
                    ),
                    title: const Text('Tất cả môn học'),
                    trailing: (_selectedCourseId == null || _selectedCourseId == 'all')
                        ? const Icon(LucideIcons.check, color: Color(0xFF22A65A))
                        : null,
                    onTap: () => Navigator.pop(sheetContext, 'all'),
                  ),
                  ...courses.map((c) {
                    final bool isCurrent = c.id == _selectedCourseId;
                    return ListTile(
                      leading: Icon(
                        isCurrent ? LucideIcons.checkCheck : LucideIcons.bookMarked,
                        color: const Color(0xFF2F6BFF),
                      ),
                      title: Text(c.name),
                      subtitle: Text('Mã môn: ${c.code}'),
                      trailing: isCurrent
                          ? const Icon(LucideIcons.check, color: Color(0xFF22A65A))
                          : null,
                      onTap: () => Navigator.pop(sheetContext, c.id),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedCourseId = picked);
      // Đồng bộ ra ngoài để các màn khác cùng focus theo (trừ lựa chọn "Tất cả").
      if (picked != 'all') courseProvider.selectCourse(picked);
    }
  }

  /// Thanh tìm kiếm + nút sắp xếp.
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm đề tài...',
                prefixIcon: Icon(LucideIcons.search, size: 20, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _sortBy,
            icon: const Icon(LucideIcons.arrowUpDown, color: Color(0xFF2F6BFF)),
            tooltip: 'Sắp xếp',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Tiêu đề', child: Text('Sắp xếp theo Tiêu đề')),
              const PopupMenuItem(
                  value: 'Số lượng nhóm', child: Text('Sắp xếp theo Số lượng nhóm')),
            ],
          ),
        ),
      ],
    );
  }

  /// Tiêu đề "Đề tài" + badge "khả dụng / tổng số".
  Widget _buildSectionTitle(int available, int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Danh sách đề tài',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        if (total > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.listChecks, size: 15, color: Color(0xFF2F6BFF)),
                const SizedBox(width: 6),
                Text(
                  '$available/$total khả dụng',
                  style: const TextStyle(
                    color: Color(0xFF2F6BFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String title, bool canManage) {
    final double topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, (topPad > 0 ? topPad : 16) + 10, 12, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D6BF3), Color(0xFF2F8BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (canManage)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.plus, color: Colors.white),
                tooltip: 'Thêm đề tài',
                onPressed: () => _showAddEditTopic(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileSearch, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy đề tài nào',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
      BuildContext context, TopicModel topic, int index, bool isLecturer, bool isAdmin) {
    final now = DateTime.now();
    final bool isStarted = now.isAfter(topic.startTime);
    final bool isEnded = now.isAfter(topic.endTime);
    final bool isFull = topic.currentGroups >= topic.maxGroups;

    Color statusColor = const Color(0xFF22A65A);
    String statusText = 'Đang mở';
    IconData statusIcon = LucideIcons.clock;

    if (!isStarted) {
      statusColor = const Color(0xFFEA580C);
      statusText = 'Chưa bắt đầu';
    } else if (isEnded) {
      statusColor = const Color(0xFFE5484D);
      statusText = 'Đã kết thúc';
    } else if (isFull) {
      statusColor = const Color(0xFF94A3B8);
      statusText = 'Đã đầy';
    }

    final IconData icon = _topicIcons[index % _topicIcons.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTopicDetails(context, topic, isLecturer || isAdmin),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: const Color(0xFF2F6BFF), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topic.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isLecturer || isAdmin)
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.ellipsisVertical,
                            size: 18, color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(LucideIcons.pencil, size: 16, color: Color(0xFF2F6BFF)),
                                SizedBox(width: 8),
                                Text('Chỉnh sửa'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(LucideIcons.trash2, size: 16, color: Color(0xFFE5484D)),
                                SizedBox(width: 8),
                                Text('Xoá'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (val) {
                          if (val == 'edit') _showAddEditTopic(context, topic: topic);
                          if (val == 'delete') context.read<TopicProvider>().deleteTopic(topic.id);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _pill(statusIcon, statusText, statusColor),
                    const Spacer(),
                    Icon(LucideIcons.calendar, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Hạn: ${DateFormat('dd/MM').format(topic.endTime)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Divider(height: 22, color: Colors.grey.shade200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.users,
                            size: 16, color: isFull ? const Color(0xFFE5484D) : const Color(0xFF22A65A)),
                        const SizedBox(width: 6),
                        Text(
                          '${topic.currentGroups}/${topic.maxGroups} nhóm',
                          style: TextStyle(
                            color: isFull ? const Color(0xFFE5484D) : const Color(0xFF22A65A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (isAdmin)
                      Text(
                        'GV: ${topic.lecturerId}',
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
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
      (g) => g.leaderId == user?.id && g.courseId == topic.courseId,
      orElse: () => GroupModel(
          id: '',
          name: '',
          description: '',
          courseId: '',
          maxMembers: 0,
          memberIds: [],
          pendingMemberIds: [],
          leaderId: ''),
    );

    final bool canRegister = myGroup.id.isNotEmpty && !myGroup.isLocked;
    const int minMembers = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(topic.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.userRound, size: 15, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text('Giảng viên: ${topic.lecturerId}',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _timeRow(LucideIcons.play, 'Bắt đầu:', _dateFormat.format(topic.startTime)),
                    const SizedBox(height: 8),
                    _timeRow(LucideIcons.flag, 'Kết thúc:', _dateFormat.format(topic.endTime)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Mô tả chi tiết',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text(topic.description, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              if (!canManage) ...[
                if (!isOpen)
                  _noticeBox(
                    isEnded
                        ? 'Thời gian đăng ký đã kết thúc.'
                        : 'Thời gian đăng ký chưa bắt đầu (Mở lúc ${_dateFormat.format(topic.startTime)}).',
                  )
                else if (canRegister) ...[
                  if (myGroup.memberIds.length < minMembers)
                    _noticeBox(
                      'Cần tối thiểu $minMembers thành viên để đăng ký đề tài (Hiện có ${myGroup.memberIds.length}).',
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6BFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: topic.currentGroups < topic.maxGroups
                            ? () {
                                context
                                    .read<GroupProvider>()
                                    .updateGroupStatus(myGroup.id, 'pending_approval');
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text(
                                        'Đã gửi yêu cầu đăng ký đề tài! Chờ giảng viên duyệt.')));
                              }
                            : null,
                        icon: const Icon(LucideIcons.circleCheckBig, size: 18),
                        label: Text(topic.currentGroups < topic.maxGroups
                            ? 'Đăng ký đề tài này'
                            : 'Đã đủ số lượng nhóm'),
                      ),
                    ),
                ] else
                  Center(
                    child: Text('Bạn phải là trưởng nhóm để đăng ký đề tài.',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                  ),
              ],
              if (canManage) ...[
                const Text('Danh sách nhóm đăng ký',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                ...groupProvider.groups
                    .where((g) =>
                        g.topicId == topic.id ||
                        (topic.id == 't1' && g.id == 'g1') ||
                        (topic.id == 't2' && g.id == 'g2'))
                    .map((g) => _buildGroupActionItem(context, g, topic.id)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _noticeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, size: 18, color: Color(0xFFE5484D)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Color(0xFFE5484D), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(IconData icon, String label, String time) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF2F6BFF)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(time, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildGroupActionItem(BuildContext context, GroupModel group, String topicId) {
    final bool pending = group.status == 'pending_approval';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF1FF),
          child: const Icon(LucideIcons.users, color: Color(0xFF2F6BFF), size: 20),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(group.status == 'approved' ? 'Đã duyệt' : 'Chờ duyệt'),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)));
        },
        trailing: pending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.circleCheck, color: Color(0xFF22A65A)),
                    tooltip: 'Duyệt',
                    onPressed: () {
                      context
                          .read<GroupProvider>()
                          .updateGroupStatus(group.id, 'approved', isLocked: true);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã duyệt đề tài cho nhóm!')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.circleX, color: Color(0xFFE5484D)),
                    tooltip: 'Từ chối',
                    onPressed: () {
                      context.read<GroupProvider>().updateGroupStatus(group.id, 'creating');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Đã từ chối đăng ký.')));
                    },
                  ),
                ],
              )
            : const Icon(LucideIcons.circleCheck, color: Color(0xFF22A65A)),
      ),
    );
  }

  void _showAddEditTopic(BuildContext context, {TopicModel? topic}) {
    final titleController = TextEditingController(text: topic?.title);
    final descController = TextEditingController(text: topic?.description);
    final maxController = TextEditingController(text: topic?.maxGroups.toString() ?? '3');
    String? dialogSelectedCourseId = topic?.courseId;

    DateTime startTime = topic?.startTime ?? DateTime.now();
    DateTime endTime = topic?.endTime ?? DateTime.now().add(const Duration(days: 30));

    final courses = context.read<CourseProvider>().courses;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(topic == null ? LucideIcons.plus : LucideIcons.pencil,
                  color: const Color(0xFF2F6BFF), size: 20),
              const SizedBox(width: 8),
              Text(topic == null ? 'Thêm đề tài mới' : 'Chỉnh sửa đề tài',
                  style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: dialogSelectedCourseId,
                  decoration: const InputDecoration(
                      labelText: 'Môn học', border: OutlineInputBorder()),
                  items: courses
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => dialogSelectedCourseId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                        labelText: 'Tên đề tài', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Mô tả', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Số nhóm tối đa', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                const Text('Lịch đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _datePickerTile(context, 'Bắt đầu', startTime,
                    (date) => setStateDialog(() => startTime = date)),
                _datePickerTile(context, 'Kết thúc', endTime,
                    (date) => setStateDialog(() => endTime = date)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (dialogSelectedCourseId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn môn học')));
                  return;
                }
                final newTopic = TopicModel(
                  id: topic?.id ?? 't${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text,
                  description: descController.text,
                  courseId: dialogSelectedCourseId!,
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
              child: const Text('Lưu'),
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
      trailing: const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF2F6BFF)),
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
