import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';
import '../../core/widgets/app_dialog.dart';
import '../../providers/course_provider.dart';
import '../../models/group_model.dart';
import '../group/create_group_screen.dart';
import '../group/join_group_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final user = authProvider.user;
    if (user == null) return const Scaffold();

    final bool isStudent = user.role == 'student';
    final bool isLecturer = user.role == 'lecturer';
    final bool isAdmin = user.role == 'admin';
    
    final List<GroupModel> myGroups = groupProvider.groups.where(
      (g) => g.memberIds.contains(user.id)
    ).toList();
    final bool hasGroup = myGroups.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống Đăng ký Đề tài'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context, 
              user, 
              semesterName: user.currentSemesterId != null 
                ? courseProvider.getSemesterById(user.currentSemesterId!)?.name 
                : null
            ),
            const SizedBox(height: 32),
            
            if (isStudent || isLecturer) ...[
              _buildSubjectSelector(context, user),
              const SizedBox(height: 24),
            ],

            Text(
              'Chức năng chính',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (isStudent) ...[
              _buildActionCard(
                context,
                'Tạo nhóm mới',
                'Đăng ký làm Trưởng nhóm cho môn học',
                Icons.group_add_rounded,
                Colors.blue,
                () {
                  final courseId = courseProvider.selectedCourseId;
                  if (courseId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn môn học trước.')),
                    );
                    return;
                  }
                  if (groupProvider.groupOfUserInCourse(user.id, courseId) != null) {
                    showAlreadyInGroupDialog(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGroupScreen(initialCourseId: courseId),
                      ),
                    );
                  }
                },
              ),
              _buildActionCard(
                context,
                'Tham gia nhóm mới',
                'Tìm và gửi yêu cầu gia nhập nhóm',
                Icons.person_add_alt_1_rounded,
                Colors.green,
                () {
                  final courseId = courseProvider.selectedCourseId;
                  if (courseId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn môn học trước.')),
                    );
                    return;
                  }
                  if (groupProvider.groupOfUserInCourse(user.id, courseId) != null) {
                    showAlreadyInGroupDialog(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JoinGroupScreen(initialCourseId: courseId),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              
              if (hasGroup) ...[
                Text(
                  'Nhóm của tôi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...myGroups.map((group) {
                  final bool isLeader = group.leaderId == user.id;
                  final courseName =
                      courseProvider.getCourseById(group.courseId)?.name ?? 'Chưa rõ môn';
                  return _buildActionCard(
                    context,
                    group.name,
                    'Lớp: $courseName\nQuản lý thành viên (${group.memberIds.length} TV)${isLeader ? ' - Trưởng nhóm' : ''}',
                    Icons.groups_rounded,
                    Colors.indigo,
                    () => Navigator.pushNamed(context, AppRoutes.manageGroup), // Should probably pass group to detail screen
                  );
                }),
                const SizedBox(height: 16),
              ],

              if (!hasGroup) ...[
                Text(
                  'Gia nhập nhóm sẵn có',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAvailableGroups(context, groupProvider, user.id),
              ],

              _buildActionCard(
                context,
                'Danh sách đề tài',
                'Xem các đề tài theo môn học',
                Icons.assignment_rounded,
                Colors.orange,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
            ],
            
            if (isLecturer) ...[
              _buildActionCard(
                context,
                'Quản lý đề tài',
                'Thêm mới và chỉnh sửa đề tài của bạn',
                Icons.book_rounded,
                Colors.teal,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Nhóm đăng ký',
                'Xem và phê duyệt các nhóm đã chọn đề tài',
                Icons.how_to_reg_rounded,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Tổng quan môn học',
                'Xem thống kê các nhóm và đề tài',
                Icons.analytics_rounded,
                Colors.blueGrey,
                () => Navigator.pushNamed(context, AppRoutes.statistics),
              ),
            ],
            
            if (isAdmin) ...[
              _buildActionCard(
                context,
                'Toàn bộ đề tài',
                'Quản lý tất cả đề tài trong hệ thống',
                Icons.admin_panel_settings_rounded,
                Colors.redAccent,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Quản lý người dùng',
                'Danh sách sinh viên, giảng viên & admin',
                Icons.people_alt_rounded,
                Colors.blueAccent,
                () => Navigator.pushNamed(context, AppRoutes.manageUsers),
              ),
              _buildActionCard(
                context,
                'Cấu hình hệ thống',
                'Thiết lập thời gian và quy định chung',
                Icons.settings_suggest_rounded,
                Colors.grey,
                () => Navigator.pushNamed(context, AppRoutes.systemSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(BuildContext context, dynamic user) {
    final courseProvider = context.watch<CourseProvider>();
    // Đảm bảo có lớp mặc định (lớp đầu tiên SV đang học).
    final enrolledIds = (user?.enrolledCourseIds as List<String>?) ?? const [];
    courseProvider.ensureDefaultCourse(enrolledIds);

    final selected = courseProvider.selectedCourse;
    final bool canChange = enrolledIds.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.book_outlined, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Môn học hiện tại:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  selected?.name ?? 'Chưa chọn môn',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
          if (canChange)
            TextButton(
              onPressed: () => _showCoursePicker(context, enrolledIds),
              child: const Text('Đổi môn'),
            ),
        ],
      ),
    );
  }

  void _showCoursePicker(BuildContext context, List<String> enrolledIds) {
    final courseProvider = context.read<CourseProvider>();
    final myCourses =
        courseProvider.courses.where((c) => enrolledIds.contains(c.id)).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Chọn môn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...myCourses.map((c) {
              final bool isCurrent = c.id == courseProvider.selectedCourseId;
              return ListTile(
                leading: Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isCurrent ? Colors.blue : Colors.grey,
                ),
                title: Text(c.name),
                subtitle: Text('Mã môn: ${c.code}'),
                onTap: () {
                  courseProvider.selectCourse(c.id);
                  Navigator.pop(sheetContext);
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableGroups(BuildContext context, GroupProvider provider, String userId) {
    final availableGroups = provider.groups.where((g) => !g.memberIds.contains(userId) && g.memberIds.length < g.maxMembers).toList();
    
    if (availableGroups.isEmpty) return const Text('Không có nhóm nào đang tuyển.');

    return Column(
      children: availableGroups.map((group) {
        final bool isPending = group.pendingMemberIds.contains(userId);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(group.name),
            subtitle: Text('${group.memberIds.length}/${group.maxMembers} TV - Trưởng: ${group.leaderId}'),
            trailing: isPending 
              ? const Text('Đang chờ...', style: TextStyle(color: Colors.orange))
              : ElevatedButton(
                  onPressed: () async {
                    if (provider.isInAnyGroup(userId)) {
                      showAlreadyInGroupDialog(context);
                      return;
                    }
                    final error = await provider.requestToJoin(group.id, userId);
                    if (!context.mounted) return;
                    if (error != null && (error.contains('nhóm khác') || error.contains('1 nhóm'))) {
                      showAlreadyInGroupDialog(context, message: error);
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Đã gửi yêu cầu gia nhập!'),
                        backgroundColor: error == null ? Colors.green : Colors.red,
                      ),
                    );
                  }, 
                  child: const Text('Gia nhập')
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, {String? semesterName}) {
    return Container(
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
              user.name[0],
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chào mừng,', style: Theme.of(context).textTheme.bodyMedium),
                Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('@${user.username}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text(user.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    if (semesterName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(10)),
                        child: Text(semesterName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
}
