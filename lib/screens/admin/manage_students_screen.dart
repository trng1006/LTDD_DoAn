import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/user_model.dart';
=======
import '../../core/services/api_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_routes.dart';
>>>>>>> phuong

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final ApiService _apiService = ApiService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tải danh sách người dùng')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final userProvider = context.watch<UserProvider>();
    final courseProvider = context.watch<CourseProvider>();
    
    final students = userProvider.users.where((u) => u.role == 'student').toList();
    final lecturers = userProvider.users.where((u) => u.role == 'lecturer').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Người dùng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sinh viên'),
              Tab(text: 'Giảng viên'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(context, students, courseProvider, userProvider),
            _buildUserList(context, lecturers, courseProvider, userProvider),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.person_add),
        ),
=======
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Không có người dùng nào.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _userTile(user);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.register);
          _fetchUsers(); // Refresh after returning
        },
        child: const Icon(Icons.person_add),
>>>>>>> phuong
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildUserList(BuildContext context, List<UserModel> users, CourseProvider courseProvider, UserProvider userProvider) {
    if (users.isEmpty) return const Center(child: Text('Không có người dùng nào.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(user.name[0])),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: user.role == 'student' 
              ? IconButton(
                  icon: const Icon(Icons.book_rounded, color: Colors.blue),
                  onPressed: () => _showEnrollmentDialog(context, user, courseProvider, userProvider),
                )
              : null,
            onTap: () {
              // Edit user profile
            },
          ),
        );
      },
    );
  }

  void _showEnrollmentDialog(BuildContext context, UserModel student, CourseProvider courseProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final enrolledCourses = courseProvider.courses.where((c) => student.enrolledCourseIds.contains(c.id)).toList();
          final availableCourses = courseProvider.courses.where((c) => !student.enrolledCourseIds.contains(c.id)).toList();

          return AlertDialog(
            title: Text('Đăng ký môn học: ${student.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Môn đã đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (enrolledCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Chưa đăng ký môn nào.', style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    ...enrolledCourses.map((c) => ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.code),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          userProvider.unenrollUserFromCourse(student.id, c.id);
                          setStateDialog(() {});
                        },
                      ),
                    )),
                  const Divider(),
                  const Text('Môn có sẵn:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (availableCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Tất cả các môn đã được đăng ký.', style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    ...availableCourses.map((c) => ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.code),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () {
                          userProvider.enrollUserInCourse(student.id, c.id);
                          setStateDialog(() {});
                        },
                      ),
                    )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ],
          );
        },
=======
  Widget _userTile(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${user.identity} - ${user.role}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(user),
        ),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await _apiService.deleteUser(user.id);
              if (success && mounted) {
                _fetchUsers();
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Đã xóa người dùng')));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
>>>>>>> phuong
      ),
    );
  }
}
