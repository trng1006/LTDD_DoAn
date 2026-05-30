import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/user_model.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động gọi API đồng bộ danh sách người dùng từ MySQL ngay khi mở trang quản lý
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final courseProvider = context.watch<CourseProvider>();
    
    // Phân loại danh sách sau khi đã đồng bộ dữ liệu từ database
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
        // Sử dụng cờisLoading để tạo trải nghiệm người dùng mượt mà khi đợi phản hồi mạng
        body: userProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUserList(context, students, courseProvider, userProvider),
                  _buildUserList(context, lecturers, courseProvider, userProvider),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context, userProvider),
          child: const Icon(Icons.person_add),
        ),
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
        content: Text('Bạn có chắc chắn muốn xóa thành viên "${user.name}" ra khỏi hệ thống? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await userProvider.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa người dùng thành công!' : 'Xóa thất bại, vui lòng kiểm tra lại ràng buộc dữ liệu.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Đồng ý xóa', style: TextStyle(color: Colors.white)),
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
          title: const Text('Thêm thành viên mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Vai trò thành viên'),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                        DropdownMenuItem(value: 'lecturer', child: Text('Giảng viên')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'Mã ID hệ thống (Ví dụ: sv06, gv03)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập ID' : null,
                    ),
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Tên đăng nhập (Username)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                    ),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên đầy đủ' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                    ),
                    TextFormField(
                      controller: identityController,
                      decoration: InputDecoration(
                        labelText: selectedRole == 'student' ? 'Mã số sinh viên (MSSV)' : 'Mã số giảng viên (MSGV)'
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng điền mã số định danh' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Mật khẩu khởi tạo (Mặc định: 123)'),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final errorMsg = await userProvider.addUser(
                    id: idController.text.trim(),
                    username: usernameController.text.trim(),
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: selectedRole,
                    identity: identityController.text.trim(),
                  );

                  if (context.mounted) {
                    if (errorMsg == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tạo tài khoản thành công!'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu thông tin'),
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
            title: Text('Đăng ký môn học: ${student.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
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
                          onPressed: () async {
                            bool success = await userProvider.unenrollUserFromCourse(student.id, c.id);
                            if (success) {
                              setStateDialog(() {});
                            } else {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hủy thất bại!')));
                            }
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
                          onPressed: () async {
                            bool success = await userProvider.enrollUserInCourse(student.id, c.id);
                            if (success) {
                              setStateDialog(() {});
                            } else {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thất bại!')));
                            }
                          },
                        ),
                      )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ],
          );
        },
      ),
    );
  }
}