import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/notification_provider.dart';
import 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';
import '../../core/widgets/app_dialog.dart';
import '../../providers/course_provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../group/create_group_screen.dart';
import '../group/join_group_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Role-based UI
    if (user.role == 'admin') {
      return _buildAdminHome(context, user);
    } else if (user.role == 'lecturer') {
      return _buildLecturerHome(context, user, unreadCount);
    } else {
      return _buildStudentHome(
        context,
        user,
        groupProvider,
        courseProvider,
        unreadCount,
      );
    }
  }

  Widget _buildStudentHome(
    BuildContext context,
    UserModel user,
    GroupProvider groupProvider,
    CourseProvider courseProvider,
    int unreadCount,
  ) {
    // SV luôn có lớp mặc định. Dùng microtask để tránh lỗi "setState() called during build"
    Future.microtask(
      () => courseProvider.ensureDefaultCourse(user.enrolledCourseIds),
    );

    final selectedCourse = courseProvider.selectedCourse;
    final semesterName = courseProvider.getSemesterName(
      selectedCourse?.semesterId,
    );

    // Lọc nhóm của SV trong môn đang chọn
    final myGroup = selectedCourse != null
        ? groupProvider.groupOfUserInCourse(user.id, selectedCourse.id)
        : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, user, semesterName: semesterName),
              const SizedBox(height: 24),
              _buildCourseSelector(context, user, courseProvider),
              const SizedBox(height: 24),

              if (myGroup != null) ...[
                _buildMyGroupCard(context, myGroup),
                const SizedBox(height: 32),
              ],

              const Text(
                'Chức năng chính',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildActionCard(
                context,
                'Tham gia nhóm',
                'Tìm kiếm và gửi yêu cầu vào nhóm mới',
                Icons.group_add_outlined,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JoinGroupScreen(initialCourseId: selectedCourse?.id),
                  ),
                ),
              ),
              _buildActionCard(
                context,
                'Tạo nhóm mới',
                'Tự tạo nhóm và mời các thành viên khác',
                Icons.create_new_folder_outlined,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateGroupScreen(initialCourseId: selectedCourse?.id),
                  ),
                ),
              ),
              _buildActionCard(
                context,
                'Danh sách đề tài',
                'Xem các đề tài nghiên cứu khả dụng',
                Icons.topic_outlined,
                Colors.orange,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Thông báo',
                'Cập nhật tin tức mới nhất từ giảng viên',
                Icons.notifications_none_rounded,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.notifications),
                badgeCount: unreadCount,
              ),

              const SizedBox(height: 24),
              const Text(
                'Nhóm gợi ý',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSuggestedGroups(
                context,
                groupProvider,
                user.id,
                selectedCourse?.id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLecturerHome(
    BuildContext context,
    UserModel user,
    int unreadCount,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giảng viên')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context, user),
          const SizedBox(height: 24),
          _buildActionCard(
            context,
            'Quản lý Đề tài',
            'Đăng và chỉnh sửa đề tài của bạn',
            Icons.assignment_outlined,
            Colors.orange,
            () => Navigator.pushNamed(context, AppRoutes.topicList),
          ),
          _buildActionCard(
            context,
            'Duyệt Nhóm',
            'Xem và phê duyệt các nhóm đăng ký',
            Icons.verified_user_outlined,
            Colors.green,
            () => Navigator.pushNamed(context, AppRoutes.manageGroup),
          ),
          _buildActionCard(
            context,
            'Thông báo',
            'Xem các cập nhật mới nhất',
            Icons.notifications_none_rounded,
            Colors.purple,
            () => Navigator.pushNamed(context, AppRoutes.notifications),
            badgeCount: unreadCount,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHome(BuildContext context, UserModel user) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị viên')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context, user),
          const SizedBox(height: 24),
          _buildActionCard(
            context,
            'Hệ thống',
            'Cấu hình thời gian, tham số hệ thống',
            Icons.settings_applications_outlined,
            Colors.grey,
            () => Navigator.pushNamed(context, AppRoutes.systemSettings),
          ),
          _buildActionCard(
            context,
            'Người dùng',
            'Quản lý Sinh viên và Giảng viên',
            Icons.people_alt_outlined,
            Colors.blue,
            () => Navigator.pushNamed(context, AppRoutes.manageUsers),
          ),
          _buildActionCard(
            context,
            'Thống kê',
            'Báo cáo số lượng nhóm, đề tài',
            Icons.bar_chart_rounded,
            Colors.teal,
            () => Navigator.pushNamed(context, AppRoutes.statistics),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserModel user, {
    String? semesterName,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.name.isNotEmpty ? user.name[0] : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào mừng,',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (semesterName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            semesterName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSelector(
    BuildContext context,
    UserModel user,
    CourseProvider provider,
  ) {
    final enrolledCourses = provider.courses
        .where((c) => user.enrolledCourseIds.contains(c.id))
        .toList();
    final selected = provider.selectedCourse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lớp học đang chọn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCoursePicker(context, enrolledCourses, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.book_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected?.name ?? 'Chưa chọn lớp',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCoursePicker(
    BuildContext context,
    List<CourseModel> courses,
    CourseProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn lớp học',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...courses.map(
              (c) => ListTile(
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: provider.selectedCourseId == c.id
                      ? Colors.blue
                      : Colors.transparent,
                ),
                title: Text(
                  c.name,
                  style: TextStyle(
                    fontWeight: provider.selectedCourseId == c.id
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(c.code),
                onTap: () {
                  provider.selectCourse(c.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupCard(BuildContext context, GroupModel group) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhóm của bạn',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group.status == 'approved' ? 'Đã chốt' : 'Đang tạo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            group.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.people_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                '${group.memberIds.length}/${group.maxMembers} thành viên',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.manageGroup),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white10,
                ),
                child: const Text('Chi tiết'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: _buildUnreadBadge(badgeCount),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadBadge(int count) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSuggestedGroups(
    BuildContext context,
    GroupProvider provider,
    String userId,
    String? courseId,
  ) {
    if (courseId == null) {
      return const Text('Vui lòng chọn môn học để xem nhóm.');
    }
    final availableGroups = provider.groups
        .where(
          (g) =>
              g.courseId == courseId &&
              !g.memberIds.contains(userId) &&
              g.memberIds.length < g.maxMembers,
        )
        .take(3)
        .toList();

    if (availableGroups.isEmpty) {
      return const Text('Chưa có nhóm nào khả dụng.');
    }

    return Column(
      children: availableGroups.map((group) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(group.name),
            subtitle: Text(
              '${group.memberIds.length}/${group.maxMembers} TV - Trưởng: ${group.leaderId}',
            ),
            trailing: ElevatedButton(
              onPressed: () async {
                if (provider.isInAnyGroup(userId)) {
                  showAlreadyInGroupDialog(context);
                  return;
                }
                final error = await provider.requestToJoin(group.id, userId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Đã gửi yêu cầu gia nhập!'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Gia nhập'),
            ),
          ),
        );
      }).toList(),
    );
  }
}
