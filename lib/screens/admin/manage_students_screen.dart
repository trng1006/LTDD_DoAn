import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/course_provider.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
      context.read<CourseProvider>().fetchAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final courseProvider = context.watch<CourseProvider>();
    
    final students = userProvider.users.where((u) => u.role == 'student').toList();
    final lecturers = userProvider.users.where((u) => u.role == 'lecturer').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Sinh viên'),
            Tab(icon: Icon(Icons.person), text: 'Giảng viên'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => userProvider.fetchUsers(),
          ),
        ],
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(context, students, courseProvider, userProvider),
                _buildUserList(context, lecturers, courseProvider, userProvider),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context, userProvider),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<UserModel> users, CourseProvider courseProvider, UserProvider userProvider) {
    if (users.isEmpty) return const Center(child: Text('Không có người dùng nào.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user.role == 'student' ? Colors.blue.shade100 : Colors.orange.shade100,
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email}'),
                Text('Mã số: ${user.identity ?? "Chưa cập nhật"}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.role == 'student')
                  IconButton(
                    icon: const Icon(Icons.book_rounded, color: Colors.blue),
                    tooltip: 'Đăng ký môn học',
                    onPressed: () => _showEnrollmentDialog(context, user, courseProvider, userProvider),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                  tooltip: 'Xóa tài khoản',
                  onPressed: () => _showDeleteConfirmDialog(context, user, userProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa thành viên "${user.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await userProvider.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa thành công!' : 'Xóa thất bại.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UserProvider userProvider) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final identityController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Thêm thành viên mới'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Vai trò'),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                        DropdownMenuItem(value: 'lecturer', child: Text('Giảng viên')),
                      ],
                      onChanged: (val) => setStateDialog(() => selectedRole = val!),
                    ),
                    TextFormField(controller: idController, decoration: const InputDecoration(labelText: 'Mã ID (sv01, gv01)')),
                    TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                    TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
                    TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextFormField(controller: identityController, decoration: InputDecoration(labelText: selectedRole == 'student' ? 'MSSV' : 'MSGV')),
                    TextFormField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final error = await userProvider.addUser(
                    id: idController.text.trim(),
                    username: usernameController.text.trim(),
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: selectedRole,
                    identity: identityController.text.trim(),
                  );
                  if (context.mounted) {
                    if (error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thành công!'), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollmentDialog(BuildContext context, UserModel initialStudent, CourseProvider courseProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final student = userProvider.users.firstWhere((u) => u.id == initialStudent.id);
          final enrolledCourses = courseProvider.courses.where((c) => student.enrolledCourseIds.contains(c.id)).toList();
          final availableCourses = courseProvider.courses.where((c) => !student.enrolledCourseIds.contains(c.id)).toList();

          return AlertDialog(
            title: Text('Môn học: ${student.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Đã đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...enrolledCourses.map((c) => ListTile(
                      title: Text(c.name),
                      trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () async {
                        if (await userProvider.unenrollUserFromCourse(student.id, c.id)) setStateDialog(() {});
                      }),
                    )),
                    const Divider(),
                    const Text('Chưa đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...availableCourses.map((c) => ListTile(
                      title: Text(c.name),
                      trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () async {
                        if (await userProvider.enrollUserInCourse(student.id, c.id)) setStateDialog(() {});
                      }),
                    )),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
          );
        },
      ),
    );
  }
}
